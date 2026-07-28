`ifndef CPU_IF_INCLUDED_
`define CPU_IF_INCLUDED_

//--------------------------------------------------------------------------------------------
// Interface : cpu_if
// CPU-facing FIFO pins on Top_Module_AXI4 (the write-fifo push side and
// the read-fifo pop side). NEW FILE - didn't exist before.
//--------------------------------------------------------------------------------------------
interface cpu_if(input bit clk, input bit rst);
  logic         wr_en;
  logic [127:0] wr_data;
  logic         full;

  logic         rd_en;
  logic [127:0] rd_data;
  logic         empty;
endinterface : cpu_if

`endif
