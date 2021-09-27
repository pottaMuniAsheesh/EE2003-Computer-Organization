module alu(
    input [3:0] func_code,
    input [31:0] in1,
    input [31:0] in2,
    output [31:0] result,
    output zero
);

    reg [31:0] result;
    assign zero = result == 32'b0 ? 1'b1 : 1'b0;

    always @(*) begin
        case(func_code)

            4'b0000: result = in1 + in2;
            4'b1000: result = in1 - in2;
            4'b0001: result = in1 << in2[4:0];
            4'b0010: result = ($signed(in1) < $signed(in2)) ? 32'b1 : 32'b0;
            4'b0011: result = (in1 < in2) ? 32'b1: 32'b0;
            4'b0100: result = in1 ^ in2;
            4'b0101: result = in1 >> in2[4:0];
            4'b1101: result = $signed(in1) >>> in2[4:0];
            4'b0110: result = in1 | in2;
            4'b0111: result = in1 & in2;

        endcase
    end

endmodule