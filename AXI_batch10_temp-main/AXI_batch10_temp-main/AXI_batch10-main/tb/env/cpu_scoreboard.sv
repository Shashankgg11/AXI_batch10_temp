`uvm_analysis_imp_decl(_write)
`uvm_analysis_imp_decl(_read)
`uvm_analysis_imp_decl(_axi_wr)

class cpu_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(cpu_scoreboard)

  uvm_analysis_imp_write  #(cpu_tx, cpu_scoreboard)      write;
  uvm_analysis_imp_read   #(cpu_tx, cpu_scoreboard)      read;
  uvm_analysis_imp_axi_wr #(axi4_slave_tx, cpu_scoreboard) axi_wr;   // NEW - from slave VIP monitor

  cpu_tx tx_h;

  bit [127:0] write_fifo[$:4096];  
  bit [127:0] read_fifo[$:4096]; 
                                     
  bit [31:0]wdata[bit [31:0]];
  bit [31:0]length[bit [31:0]];

  bit [127:0] p1, p2, p3;

  int wr_fifo_depth = 4096;  

  function new(string name = "cpu_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    write  = new("write", this);
    read   = new("read", this);
    axi_wr = new("axi_wr", this);
  endfunction

  //-----------------------------------------------------------
  // write_axi_wr(): NEW - called once per COMPLETE write burst
  // observed on the AXI bus by the slave VIP's monitor
  // (axi4_slave_mon_proxy_h.axi4_slave_write_data_analysis_port).
  //
  // This is the check that actually catches the beat_cnt/WVALID
  // bug in AXI_MASTER_WRITE_CONTROL.v: if the master's write-data
  // FSM undercounts beats (per-cycle beat_cnt decrementing on
  // WREADY alone instead of WREADY && WVALID), the slave will have
  // received fewer W beats than AWLEN+1 promised - t.wdata.size()
  // will be short. That's directly checkable here without needing
  // to look at internal RTL signals at all - purely from the bus.
  //-----------------------------------------------------------
  function void write_axi_wr(axi4_slave_tx t);
    int expected_beats;
    expected_beats = t.awlen + 1;

    if (t.wdata.size() != expected_beats) begin
      `uvm_error(get_type_name(),
                 $sformatf("AXI W-CHANNEL BEAT COUNT MISMATCH: awaddr=0x%0h awid=%s awlen=%0d -> expected %0d W beats, slave received %0d (likely the beat_cnt/WVALID FSM bug in AXI_MASTER_WRITE_CONTROL.v)",
                           t.awaddr, t.awid.name(), t.awlen, expected_beats, t.wdata.size()))
    end else begin
      `uvm_info(get_type_name(),
                $sformatf("AXI W-CHANNEL beat count MATCH: awaddr=0x%0h awlen=%0d beats=%0d",
                          t.awaddr, t.awlen, t.wdata.size()),
                UVM_LOW)
    end

    if (t.wstrb.size() != expected_beats) begin
      `uvm_error(get_type_name(),
                 $sformatf("AXI W-CHANNEL WSTRB COUNT MISMATCH: awaddr=0x%0h expected %0d, got %0d",
                           t.awaddr, expected_beats, t.wstrb.size()))
    end
  endfunction

  function void write_write(cpu_tx t1);
    $display("cpu scoreboard request received full=%0b wr_data=0x%032h fifo_size=%0d",t1.full, t1.wr_data, write_fifo.size());
    if(t1.full == 1) begin
      if(write_fifo.size() >= wr_fifo_depth)
        `uvm_info(get_type_name(), "full check MATCH", UVM_LOW)
        else `uvm_info(get_type_name(), $sformatf("full check MISMATCH full asserted but fifo size = %0d",write_fifo.size()), UVM_LOW)
    end else begin
      write_fifo.push_back(t1.wr_data);
    end
  endfunction


  function void write_read(cpu_tx t2);
    if(t2.empty == 1)begin      
      if(read_fifo.size() == 0) `uvm_info(get_type_name(), "empty check MATCH: fifo also empty", UVM_LOW)
      else `uvm_info(get_type_name(), $sformatf("empty check MISMATCH: empty asserted but fifo size = %0d",read_fifo.size()),UVM_LOW)
    end 
        
    else begin
      if(read_fifo.size() == 0) `uvm_info(get_type_name(), "DUT expecting data but fifo is empty",UVM_LOW)
      else begin
        bit[127:0] expected;
        expected = read_fifo.pop_front();
        if(expected !== t2.rd_data) `uvm_info(get_type_name(), $sformatf("DATA MISMATCH: expected=0x%032h got=0x%032h", expected, t2.rd_data),UVM_LOW)
        else `uvm_info(get_type_name(), "response data MATCH", UVM_LOW)
      end
    end
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      process_packet();
    end
  endtask

  task process_packet();
    bit [3:0]   txn_id;
    bit [31:0]  addr;
    bit [3:0]   len;
    bit [2:0]   size;
    int candidate_bytes;
    bit [7:0]   sop_c;
    bit [7:0]   eop_c;
   
    sop_c = 8'hAA;
    eop_c = 8'h53;

    wait(write_fifo.size() > 0);
    p1 = write_fifo.pop_front();
    $display("popped request = 0x%032h", p1);
    txn_id = p1[12:9];
    addr = p1[44:13];
    len = p1[48:45];
    size = p1[51:49];

    candidate_bytes = (len + 1)*(1 << size);
    
    if(candidate_bytes == 1 && p1[71:64] == 8'd0)begin
      p2 = {sop_c, txn_id, wdata[addr], 4'b0001, eop_c};
      $display("pushing read response = 0x%032h", p2);
      read_fifo.push_back(p2);
    end 
    else begin
      wdata[addr] = p1[95:64];
      length[addr] = candidate_bytes;
      p3 = {sop_c, txn_id, 4'b0001, eop_c};
      $display("pushing write response = 0x%032h", p3);
      read_fifo.push_back(p3);
    end
  endtask
endclass
