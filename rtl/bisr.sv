module bisr #(
    parameter DATA_WIDTH = 8
)(
    input  logic tck,
    input  logic trst_n,
    input  logic tdi,
    output logic tdo,
    input  logic [3:0] ir,
    input  logic [DATA_WIDTH-1:0] user_dr_shift
);

    logic [DATA_WIDTH-1:0] data_reg;

    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            data_reg <= '0;
            tdo      <= 0;
        end else if (ir == 4'b0010) begin // USER_DR
            data_reg <= user_dr_shift;
            tdo      <= data_reg[DATA_WIDTH-1];
        end else begin
            tdo <= tdi; // bypass
        end
    end

endmodule
