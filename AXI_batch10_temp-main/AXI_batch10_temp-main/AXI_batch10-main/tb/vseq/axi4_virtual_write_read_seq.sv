class axi4_virtual_write_read_seq extends uvm_sequence;
  `uvm_object_utils(axi4_virtual_write_read_seq)
  `uvm_declare_p_sequencer(top_vseqr)

  function new(string name = "axi4_virtual_write_read_seq");
    super.new(name);
  endfunction

  task body();
    cpu_write_seq        cpu_wr_seq;
    axi4_slave_write_seq slv_wr_seq;
    cpu_read_seq        cpu_rd_seq;
    axi4_slave_read_seq slv_rd_seq;


fork
  begin
      slv_wr_seq = axi4_slave_write_seq::type_id::create("slv_wr_seq");
      slv_wr_seq.start(p_sequencer.slave_write_sqr_h);
  end
join_none

begin
  cpu_wr_seq = cpu_write_seq::type_id::create("cpu_wr_seq");
  cpu_wr_seq.start(p_sequencer.cpu_sqr_h);
end
disable fork;

fork
  begin
      slv_rd_seq = axi4_slave_read_seq::type_id::create("slv_rd_seq");
      slv_rd_seq.start(p_sequencer.slave_read_sqr_h);
  end
join_none

begin
  cpu_rd_seq = cpu_read_seq::type_id::create("cpu_rd_seq");
  cpu_rd_seq.start(p_sequencer.cpu_sqr_h);
end
disable fork;

  endtask
endclass
