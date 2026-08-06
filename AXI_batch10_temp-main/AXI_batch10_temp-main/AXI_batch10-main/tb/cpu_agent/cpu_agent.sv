class cpu_agent extends uvm_agent;

  `uvm_component_utils(cpu_agent)

  cpu_sequencer cpu_seqr_h;
  cpu_driver cpu_drv_h;
  cpu_monitor cpu_mon_h;

  function new(string name = "cpu_agent",
               uvm_component parent = null);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if(get_is_active() == UVM_ACTIVE) begin

      cpu_seqr_h = cpu_sequencer::type_id::create("cpu_seqr_h",this);

      cpu_drv_h = cpu_driver::type_id::create("cpu_drv_h",this);

    end

    cpu_mon_h = cpu_monitor::type_id::create("cpu_mon_h",this);

  endfunction

  function void connect_phase(uvm_phase phase);

    super.connect_phase(phase);

    if(get_is_active() == UVM_ACTIVE) begin

      cpu_drv_h.seq_item_port.connect(cpu_seqr_h.seq_item_export);

    end

  endfunction

endclass

