class cpu_driver extends uvm_driver #(cpu_tx);
  `uvm_component_utils(cpu_driver)
  
  virtual cpu_if vif;
  cpu_tx req;

  function new(string name = "cpu_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    if(!uvm_config_db#(virtual cpu_if)::get(this, "", "cpu_vif", vif))
      `uvm_fatal("DRV", "No cpu_if set in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    vif.wr_en   <= 1'b0;
    vif.wr_data <= '0;
    vif.rd_en   <= 1'b0;
    #1000;
    forever begin
      seq_item_port.get_next_item(req);
      
      fork
        write(req);
        read(req);
      join

      seq_item_port.item_done();
    end
  endtask

  task write(cpu_tx req);
    bit[127:0] fifo_words[$];
    bit was_full;

    if(!req.wr_en) return;

    create_pkt(req, fifo_words);

    foreach (fifo_words[i]) begin
      do begin
        was_full    = vif.full;      // sample BEFORE the edge, at assertion time
        vif.wr_en   <= 1'b1;
        vif.wr_data <= fifo_words[i];
        $display($time,"my cpu driver wr_data = 0x%032h", fifo_words[i]);
        @(posedge vif.clk);
      end while (was_full);           // retry THIS beat if it was rejected - don't
                                       // silently move on and corrupt the packet
    end
    vif.wr_en   <= 1'b0;
    vif.wr_data <= '0;
  endtask


  task read(cpu_tx req);
    bit was_empty;

    if (!req.rd_en) return;

    do begin
      was_empty = vif.empty;
      vif.rd_en <= 1'b1;
      @(posedge vif.clk);
    end while (was_empty);

    vif.rd_en <= 1'b0;
  endtask

  // Serialize tx into a queue of 128-bit FIFO words, MSB-first,
  // zero-padded at the LSB end of the final word. Same convention
  // as before - header(60) + strobe + data + eop, no pkt_flag bit.
  task create_pkt(cpu_tx tx, ref bit [127:0] fifo_words[$]);
    bit packet_bits[$];
    bit [127:0] temp;
    int idx;

    packet_bits = {};

    for (int i = 7; i >= 0; i--)  packet_bits.push_back(tx.sop[i]);
    for (int i = 3; i >= 0; i--)  packet_bits.push_back(tx.txn_id[i]);
    for (int i = 31; i >= 0; i--) packet_bits.push_back(tx.addr[i]);
    for (int i = 3; i >= 0; i--)  packet_bits.push_back(tx.len[i]);
    for (int i = 2; i >= 0; i--)  packet_bits.push_back(tx.size[i]);
    for (int i = 1; i >= 0; i--)  packet_bits.push_back(tx.burst[i]);
    for (int i = 1; i >= 0; i--)  packet_bits.push_back(tx.lock[i]);
    for (int i = 1; i >= 0; i--)  packet_bits.push_back(tx.cache[i]);
    for (int i = 2; i >= 0; i--)  packet_bits.push_back(tx.prot[i]);

    foreach (tx.strobe[i])
      packet_bits.push_back(tx.strobe[i]);

    foreach (tx.data[i])
      for (int j = 7; j >= 0; j--)
        packet_bits.push_back(tx.data[i][j]);

    for (int i = 7; i >= 0; i--)
      packet_bits.push_back(tx.eop[i]);

    idx = 0;
    while (idx < packet_bits.size()) begin
      temp = '0;

      for (int i = 127; i >= 0; i--) begin
        if (idx < packet_bits.size())
          temp[i] = packet_bits[idx++];
      end

      fifo_words.push_back(temp);
    end
  endtask

endclass : cpu_driver
