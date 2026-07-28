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
    });

    finish_item(req);

  endtask

endclass
