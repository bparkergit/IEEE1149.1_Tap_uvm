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

    logic clk = 0;
    logic rst_n = 0;

    always #5 clk = ~clk;

    bisr_if bisr_if_inst (.clk(clk), .rst_n(rst_n));

    sync_fifo #(
        .DEPTH(DEPTH),
        .WIDTH(WIDTH)
    ) dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .wr_en   (fifo_if_inst.wr_en),
        .wr_data (fifo_if_inst.wr_data),
        .rd_en   (fifo_if_inst.rd_en),
        .rd_data (fifo_if_inst.rd_data),
        .full    (fifo_if_inst.full),
        .empty   (fifo_if_inst.empty)
    );

    // Reset generation
    initial begin
        rst_n = 0;
        #10;
        rst_n = 1;
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
