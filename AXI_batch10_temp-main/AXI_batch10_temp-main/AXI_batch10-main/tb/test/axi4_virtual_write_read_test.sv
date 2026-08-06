class axi4_virtual_write_read_test extends base_test;

  `uvm_component_utils(axi4_virtual_write_read_test)

  function new(string name = "axi4_virtual_write_read_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_virtual_write_read_seq seq;
    phase.raise_objection(this);

    seq = axi4_virtual_write_read_seq::type_id::create("seq");
    seq.start(env_h.vseqr_h);
    #1000;
    phase.drop_objection(this);
  endtask

endclass
