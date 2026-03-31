`timescale 1ns / 1ps

// ───────────────────────────────────────────────
//   UVM imports and macros — MUST come first!
// ───────────────────────────────────────────────
import uvm_pkg::*;
`include "uvm_macros.svh"
`include "bisr_if.sv"
`include "bisr_seq_item.sv"
`include "bisr_base_sequence.sv"
`include "bisr_driver.sv"
`include "bisr_sequencer.sv"
`include "bisr_monitor.sv"
`include "bisr_coverage.sv"
`include "bisr_agent.sv"
`include "bisr_scoreboard.sv"
`include "bisr_env.sv"
`include "bisr_base_test.sv"



// ───────────────────────────────────────────────
//   TOP MODULE
// ───────────────────────────────────────────────
module bisr_tb_top;


    logic TCK = 0;
    logic TRST = 0;


    always #5 TCK = ~TCK;

  bisr_if bisr_if_inst (.TCK(TCK), .TRST(TRST));

chip_top dut (
  .TCK  (TCK),
  .TRST (TRST),
  .TMS  (bisr_if_inst.TMS),
  .TDI  (bisr_if_inst.TDI),
  .TDO  (bisr_if_inst.TDO)
);

    // Reset generation
    initial begin
        TRST = 1;
        #20;
        TRST = 0;
    end

    // UVM + waveform dump
    initial begin
        // Set interface for driver
      uvm_config_db #(virtual bisr_if.DRIVER)::set(
            null,
            "uvm_test_top.env.agent.drv",
            "vif",
            bisr_if_inst
        );
      uvm_config_db #(virtual bisr_if.MONITOR)::set(
            null,
            "uvm_test_top.env.agent.mon",
            "vif",
            bisr_if_inst
        );

      // set interface for scoreboard
      uvm_config_db #(virtual bisr_if)::set(
            null,
            "uvm_test_top.env.scoreboard",
            "vif",
            bisr_if_inst
        );

      run_test("bisr_base_test");
    end

    // Use WLF format (recommended for Questa/ModelSim)
    initial begin
      $wlfdumpvars(0, bisr_tb_top);   // dumps everything
        // If you prefer VCD:
      $dumpfile("bisr_uvm.vcd");
      $dumpvars(0, bisr_tb_top);
    end

endmodule
