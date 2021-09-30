module alu_control(
    input [1:0] ALUOp,
    input [3:0] inst_seg,
    output [3:0] alu_func_code
);

    reg [3:0] alu_func_code;

    always @(*) begin
        
        case (ALUOp)
            2'b00: alu_func_code = 4'b0;
            2'b01: alu_func_code = inst_seg;
            2'b10: alu_func_code = (inst_seg == 4'b1101) ? inst_seg : {1'b0, inst_seg[2:0]};
            2'b11: alu_func_code = (inst_seg[2:1] == 2'b00) ? 4'b1000 : {2'b00, inst_seg[2:1]}; // for conditional branch checking.
        endcase

    end

endmodule