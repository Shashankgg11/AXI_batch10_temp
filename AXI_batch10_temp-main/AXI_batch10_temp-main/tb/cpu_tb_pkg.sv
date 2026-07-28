//--------------------------------------------------------------------------------------------
// Package: cpu_tb_pkg
// NEW FILE. Bundles every tb/ class into one package, in dependency order,
// matching the vendor's own axi4_master_pkg.sv / axi4_slave_pkg.sv convention.
// Needs axi4_globals_pkg and axi4_slave_pkg compiled/imported before this.
//--------------------------------------------------------------------------------------------
package cpu_tb_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import axi4_globals_pkg::*;
  import axi4_slave_pkg::*;

  `include "cpu_agent/cpu_tx.sv"
  `include "cpu_agent/cpu_sequencer.sv"
  `include "cpu_agent/cpu_driver.sv"
  `include "cpu_agent/cpu_monitor.sv"
  `include "cpu_agent/cpu_agent.sv"
  `include "cpu_agent/cpu_write_seq.sv"

  `include "env/cpu_scoreboard.sv"
  `include "env/cpu_env.sv"
  `include "env/axi_vip_env.sv"

  `include "vseq/top_vseq.sv"

  `include "env/top_env.sv"
  `include "test/base_test.sv"
  `include "test/single_seq_test.sv"

endpackage : cpu_tb_pkg
