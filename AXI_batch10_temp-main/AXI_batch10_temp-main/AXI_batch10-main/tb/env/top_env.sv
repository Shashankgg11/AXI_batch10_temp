//--------------------------------------------------------------------------------------------
// Class: top_env
// NEW FILE. Combines cpu_env (your DUT-side driver/monitor/scoreboard) with
// axi_vip_env (slave VIP only) under one env, plus the virtual sequencer that
// ties cpu_write_seq (and future sequences) to a single run point.
//--------------------------------------------------------------------------------------------
class top_env extends uvm_env;

  `uvm_component_utils(top_env)

  cpu_env      cpu_env_h;
  axi_vip_env  axi_vip_env_h;
  top_vseqr    vseqr_h;

  function new(string name = "top_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cpu_env_h     = cpu_env::type_id::create("cpu_env_h", this);
    axi_vip_env_h = axi_vip_env::type_id::create("axi_vip_env_h", this);
    vseqr_h       = top_vseqr::type_id::create("vseqr_h", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    vseqr_h.cpu_sqr_h         = cpu_env_h.cpu_agt_h.cpu_seqr_h;
    // ADDED: give the virtual sequencer a handle to the slave VIP's own
    // write/read sequencers too, so axi4_virtual_write_seq / axi4_virtual_read_seq
    // can start a sequence on the slave side in parallel with the cpu side.
    vseqr_h.slave_write_sqr_h = axi_vip_env_h.slave_agt_h.axi4_slave_write_seqr_h;
    vseqr_h.slave_read_sqr_h  = axi_vip_env_h.slave_agt_h.axi4_slave_read_seqr_h;

    // NEW: connect the slave VIP's monitor (what actually happened on the
    // AXI bus) into the scoreboard, so it can catch bus-level protocol
    // issues like the write-data beat-count bug - cpu_scoreboard previously
    // only ever saw the CPU-side FIFO pins, never the AXI side.
    axi_vip_env_h.slave_agt_h.axi4_slave_mon_proxy_h.axi4_slave_write_data_analysis_port.connect(cpu_env_h.sb_h.axi_wr);
  endfunction

endclass
