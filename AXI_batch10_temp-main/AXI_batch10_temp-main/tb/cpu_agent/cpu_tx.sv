typedef enum {WRITE_PKT, READ_PKT} pkt_type_e;

class cpu_tx extends uvm_sequence_item;

  `uvm_object_utils(cpu_tx)

  rand pkt_type_e pkt_type;

  rand bit [7:0] sop;
  rand bit [3:0] txn_id;
  rand bit [31:0] addr;
  rand bit [3:0] len;
  rand bit [2:0] size;
  rand bit [1:0] burst;
  rand bit [1:0] lock;
  rand bit [1:0] cache;
  rand bit [2:0] prot;

  rand bit strobe[];

  rand bit [7:0] data[];

  rand bit [7:0] eop;

  rand bit wr_en;
  rand bit rd_en;

  bit full;
  bit empty;

  bit[127:0] wr_data;
  bit[127:0] rd_data;


  constraint sop_c{sop == 8'hAA;}
  constraint eop_c{eop == 8'h53;}

  constraint burst_c{burst inside {0,1,2};}

  constraint size_c{size inside {[0:4]};}

  constraint len_c{len inside {[0:15]};}

  constraint data_size_c
  {
    if(pkt_type == WRITE_PKT)
      data.size() == ((len+1)*(1<<size));

    if(pkt_type == READ_PKT)
      data.size() == 1;
  }

  constraint strobe_size_c
  {
    strobe.size() == data.size();
  }

  constraint read_pkt_c
  {
    if(pkt_type == READ_PKT)
    {
      data[0] == 8'h00;

      foreach(strobe[i])
        strobe[i] == 0;
    }
  }

  constraint write_pkt_c
  {
    if(pkt_type == WRITE_PKT)
    {
      foreach(strobe[i])
        strobe[i] inside {0,1};
    }
  }

  function new(string name="cpu_tx");
    super.new(name);
  endfunction

endclass
