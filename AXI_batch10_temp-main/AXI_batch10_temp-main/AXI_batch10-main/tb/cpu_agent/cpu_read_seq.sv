//--------------------------------------------------------------------------------------------
// Class: cpu_read_seq
// NEW FILE. Sibling of cpu_write_seq - the project only had a write sequence,
// there was no way to drive a CPU-side read at all. Same style/structure as
// cpu_write_seq: one cpu_tx item per body(), only the packet type + wr_en/rd_en
// polarity differ (READ_PKT, rd_en=1, wr_en=0). strobe/data are left to the
// cpu_tx read_pkt_c constraint (forces data[0]==0, strobe all 0 for a read).
//--------------------------------------------------------------------------------------------
class cpu_read_seq extends uvm_sequence #(cpu_tx);

  `uvm_object_utils(cpu_read_seq)

  cpu_tx req;

  function new(string name = "cpu_read_seq");
    super.new(name);
  endfunction

  task body();

    req = cpu_tx::type_id::create("req");

    start_item(req);

    assert(req.randomize() with {
      pkt_type == READ_PKT;
      wr_en    == 0;
      rd_en    == 1;
      size == 2;
      len == 0;
      lock == 0;
      cache == 0;
      prot == 0;
      burst == 1;
      addr == 100;

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
