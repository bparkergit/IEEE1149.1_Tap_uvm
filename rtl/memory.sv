module memory #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 256
)(
    input  logic                     clk,
    input  logic                     write_en,
    input  logic [$clog2(DEPTH)-1:0] addr,
    input  logic [DATA_WIDTH-1:0]    data_in,
    output logic [DATA_WIDTH-1:0]    data_out
);

    logic [DATA_WIDTH-1:0] mem_array [0:DEPTH-1];

    // Write on rising clock edge when enabled
    always_ff @(posedge clk) begin
        if (write_en)
            mem_array[addr] <= data_in;
    end

    // Read asynchronously
    assign data_out = mem_array[addr];

endmodule
