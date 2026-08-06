//--------------------------------------------------------------------------------------------
// Class: cpu_env
// FIXED vs original "env" class:
//   - renamed env -> cpu_env (avoid an overly generic class name)
//   - removed cpu_sub_h reference (subscriber was commented out but connect_phase
//     still referenced it - would not compile)
//   - removed the redundant/misnamed extra "seqr_h" (wrong type name "sequencer",
//     and cpu_agent already owns its own sequencer - this was unused duplication)
//   - fixed scoreboard class name: "scoreboard" -> "cpu_scoreboard"
//   - connect_phase now actually wires cpu_monitor's wr_ap/rd_ap to the
//     scoreboard's write/read imps (this connection didn't exist before)
//--------------------------------------------------------------------------------------------
class cpu_env extends uvm_env;

  `uvm_component_utils(cpu_env)

  cpu_agent      cpu_agt_h;
  cpu_scoreboard sb_h;

  function new(string name = "cpu_env", uvm_component parent = null);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cpu_agt_h = cpu_agent::type_id::create("cpu_agt_h", this);
    sb_h      = cpu_scoreboard::type_id::create("sb_h", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    cpu_agt_h.cpu_mon_h.wr_ap.connect(sb_h.write);
    cpu_agt_h.cpu_mon_h.rd_ap.connect(sb_h.read);
  endfunction

endclass
