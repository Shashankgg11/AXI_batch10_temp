class cpu_monitor extends uvm_monitor;

  `uvm_component_utils(cpu_monitor)

  virtual cpu_if vif;

  uvm_analysis_port #(cpu_tx) wr_ap;
  uvm_analysis_port #(cpu_tx) rd_ap;

  function new(string name="cpu_monitor", uvm_component parent=null);
    super.new(name,parent);

    wr_ap = new("wr_ap",this);
    rd_ap = new("rd_ap",this);
  endfunction


  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(!uvm_config_db#(virtual cpu_if)::get(this,"","cpu_vif",vif))
      `uvm_fatal("CPU_MON","Virtual Interface not found")
  endfunction


  task run_phase(uvm_phase phase);

    cpu_tx tx;

    forever begin

      @(posedge vif.clk);

      if(vif.wr_en)begin
        tx = cpu_tx::type_id::create("wr_tx");

        tx.wr_en = vif.wr_en;
        tx.full = vif.full;
        tx.wr_data = vif.wr_data;

        wr_ap.write(tx);

        `uvm_info(get_type_name(), $sformatf("WRITE: wr_en=%0b full=%0b wr_data=%032h", tx.wr_en, tx.full, tx.wr_data), UVM_MEDIUM)

      end

      if(vif.rd_en)begin
        tx = cpu_tx::type_id::create("rd_tx");

        tx.rd_en = vif.rd_en;
        tx.empty = vif.empty;
        tx.rd_data = vif.rd_data;

        rd_ap.write(tx);

        `uvm_info(get_type_name(), $sformatf("READ: rd_en=%0b empty=%0b rd_data=%032h", tx.rd_en, tx.empty, tx.rd_data), UVM_MEDIUM)

      end
    end

  endtask
endclass
