class cpu_write_seq extends uvm_sequence #(cpu_tx);

  `uvm_object_utils(cpu_write_seq)

  cpu_tx req;

  function new(string name="cpu_write_seq");
    super.new(name);
  endfunction

  task body();

    req = cpu_tx::type_id::create("req");

    start_item(req);

    assert(req.randomize() with {
      pkt_type == WRITE_PKT;
      wr_en == 1;
      rd_en == 0;
      size == 2;
      len == 0;
      lock == 0;
      cache == 0;
      prot == 0;
      burst == 1;
      addr == 100;
      foreach (strobe[i]) strobe[i] == 1;
    });
    $display("pkt_type=%s sop=0x%0h txn_id=0x%0h addr=0x%08h len=%0d size=%0d burst=%0d lock=%0d cache=%0d prot=%0d wr_en=%0b rd_en=%0b full=%0b empty=%0b wr_data=0x%032h rd_data=0x%032h eop=0x%0h data=%p strobe=%p",
         (req.pkt_type==WRITE_PKT)?"WRITE_PKT":"READ_PKT",
         req.sop,
         req.txn_id,
         req.addr,
         req.len,
         req.size,
         req.burst,
         req.lock,
         req.cache,
         req.prot,
         req.wr_en,
         req.rd_en,
         req.full,
         req.empty,
         req.wr_data,
         req.rd_data,
         req.eop,
         req.data,
         req.strobe);
    finish_item(req);

  endtask

endclass
