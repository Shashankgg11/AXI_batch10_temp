`uvm_analysis_imp_decl(_write)
`uvm_analysis_imp_decl(_read)
            
class cpu_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(cpu_scoreboard)

  uvm_analysis_imp_write #(cpu_tx, cpu_scoreboard) write;
  uvm_analysis_imp_read  #(cpu_tx, cpu_scoreboard) read;

  cpu_tx tx_h;

  bit [127:0] write_fifo[$:4096];   // actual accepted write-fifo beats
  bit [127:0] read_fifo[$:4096];    // EXPECTED response beats (reference model,
                                     
  bit [1023:0] wdata[bit [31:0]];
  bit [31:0]   length[bit [31:0]];   // valid bit-length stored at that address

  bit [127:0] p1, p2;

  int wr_fifo_depth = 4096;  

  function new(string name = "cpu_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    write = new("write", this);
    read  = new("read", this);
  endfunction

  function void write_write(cpu_tx t1);
    if (t1.full == 1) begin
      if (write_fifo.size() >= wr_fifo_depth)
        `uvm_info(get_type_name(), "full check MATCH: model also full", UVM_LOW)
      else
        `uvm_error(get_type_name(),
                   $sformatf("full check MISMATCH: full asserted but model has room (%0d/%0d)",
                             write_fifo.size(), wr_fifo_depth))
    end else begin
      write_fifo.push_back(t1.wr_data);
    end
  endfunction


  function void write_read(cpu_tx t2);
    if (t2.empty == 1) begin
      if (read_fifo.size() == 0)
        `uvm_info(get_type_name(), "empty check MATCH: model also empty", UVM_LOW)
      else
        `uvm_error(get_type_name(),
                   $sformatf("empty check MISMATCH: empty asserted but %0d expected word(s) still queued",
                             read_fifo.size()))
    end else begin
      if (read_fifo.size() == 0) begin
        `uvm_error(get_type_name(), "DUT returned data but no response was expected here")
      end else begin
        bit [127:0] expected;
        expected = read_fifo.pop_front();
        if (expected !== t2.rd_data)
          `uvm_error(get_type_name(),
                     $sformatf("DATA MISMATCH: expected=0x%032h got=0x%032h", expected, t2.rd_data))
        else
          `uvm_info(get_type_name(), "response data MATCH", UVM_LOW)
      end
    end
  endfunction


  task run_phase(uvm_phase phase);
    forever
      process_one_packet();
  endtask

  task process_one_packet();
    bit [3:0]   txn_id;
    bit [31:0]  addr;
    bit [3:0]   len;
    bit [2:0]   size;
    int         candidate_bytes;
    int         nbytes;
    bit         is_read;
    bit         strobe_peek;
    bit [7:0]   data_peek;
    bit [7:0]   sop_c;
    bit [7:0]   eop_c;
    bit [3:0]   rsp;
    bit         rsp_bits[$];
    bit         data_bits[$];
    int         idx;
    int         beats_needed;
    bit [127:0] beat_q[$];

    sop_c = 8'hAA;
    eop_c = 8'h53;

    wait (write_fifo.size() > 0);
    p1 = write_fifo.pop_front();
    beat_q.push_back(p1);

    txn_id = p1[119:116];
    addr   = p1[115:84];
    len    = p1[83:80];
    size   = p1[79:77];

    candidate_bytes = (len + 1) * (1 << size);

    if (candidate_bytes == 1) begin
      strobe_peek = p1[67];
      data_peek   = p1[66:59];
      is_read     = (strobe_peek == 0 && data_peek == 8'h00);
      nbytes      = 1;
    end else begin
      is_read = 0;
      nbytes  = candidate_bytes;
    end

    beats_needed = ((60 + nbytes + (nbytes * 8) + 8) + 127) / 128;

    for (int b = 1; b < beats_needed; b++) begin
      wait (write_fifo.size() > 0);
      p2 = write_fifo.pop_front();
      beat_q.push_back(p2);
    end

    idx = 60 + nbytes;   // skip header + strobe bits
    data_bits = {};
    for (int i = 0; i < nbytes; i++)
      for (int j = 7; j >= 0; j--) begin
        data_bits.push_back(get_beat_bit(beat_q, idx));
        idx++;
      end

    for (int k = 0; k < nbytes * 8; k++)
      wdata[addr][(nbytes*8 - 1) - k] = data_bits[k];
    length[addr] = nbytes * 8;

    rsp = 4'b0000;   // placeholder response code - set to your DUT's OKAY encoding

    rsp_bits = {};
    for (int i = 7; i >= 0; i--) rsp_bits.push_back(sop_c[i]);
    for (int i = 3; i >= 0; i--) rsp_bits.push_back(txn_id[i]);

    if (is_read) begin
      int rlen;
      if (length.exists(addr)) begin
        rlen = length[addr];
        for (int i = rlen - 1; i >= 0; i--)
          rsp_bits.push_back(wdata[addr][i]);
      end else begin
        `uvm_warning(get_type_name(),
                     $sformatf("read from addr=0x%0h never written - responding with 1 zero byte", addr))
        for (int i = 0; i < 8; i++) rsp_bits.push_back(1'b0);
      end
      for (int i = 3; i >= 0; i--) rsp_bits.push_back(rsp[i]);
      for (int i = 7; i >= 0; i--) rsp_bits.push_back(eop_c[i]);
    end else begin
      for (int i = 3; i >= 0; i--) rsp_bits.push_back(rsp[i]);
      for (int i = 7; i >= 0; i--) rsp_bits.push_back(eop_c[i]);
    end

    push_bits_as_beats(rsp_bits);
  endtask

  function automatic bit get_beat_bit(ref bit [127:0] q[$], input int global_idx);
    return q[global_idx/128][127 - (global_idx % 128)];
  endfunction

  function void push_bits_as_beats(bit rsp_bits[$]);
    int idx;
    bit [127:0] temp;
    idx = 0;
    while (idx < rsp_bits.size()) begin
      temp = '0;
      for (int i = 127; i >= 0; i--) begin
        if (idx < rsp_bits.size())
          temp[i] = rsp_bits[idx++];
      end
      read_fifo.push_back(temp);
    end
  endfunction

endclass

        
        




