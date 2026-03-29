// ───────────────────────────────────────────────
//   INTERFACE
// ───────────────────────────────────────────────
interface bisr_if #(
    parameter int DEPTH = 16,
    parameter int WIDTH = 8
) (
    input logic clk,
    input logic rst_n
);

    logic              wr_en;
    logic [WIDTH-1:0]  wr_data;
    logic              rd_en;
    logic [WIDTH-1:0]  rd_data;
    logic              full;
    logic              empty;

    clocking cb_drv @(posedge clk);
        output wr_en, wr_data;
        output rd_en;
        input  rd_data, full, empty;
    endclocking

    clocking cb_mon @(posedge clk);
        input wr_en, wr_data;
        input rd_en, rd_data;
        input full, empty;
    endclocking

    modport DUT (
        input  clk, rst_n,
        input  wr_en, wr_data,
        input  rd_en,
        output rd_data, full, empty
    );

    modport DRIVER (
        clocking cb_drv,
        input rst_n
    );

    modport MONITOR (
        clocking cb_mon,
        input rst_n
    );

endinterface
