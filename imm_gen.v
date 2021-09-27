module imm_gen (
    input [31:0] inst,
    output [31:0] imm_value
);
    
    reg [31:0] imm_value;

    always @(*) begin
        case (inst[6:0])
            7'b0000011: imm_value = {{20{inst[31]}}, inst[31:20]};
            7'b0010011: imm_value = {{20{inst[31]}}, inst[31:20]};
            7'b0100011: imm_value = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            7'b1100011: imm_value = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0}; // B-type immediate value.
            7'b1100111: imm_value = {{20{inst[31]}}, inst[31:20]}; // Immediate value for JALR is I-type.
            7'b1101111: imm_value = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0}; // J-type immediate value.
            7'b0110111: imm_value = {inst[31:12], {12{1'b0}}}; // U-type immediate for LUI.
            7'b0010111: imm_value = {inst[31:12], {12{1'b0}}}; // U-type immediate for AUIPC.
            default: imm_value = 32'b0;
        endcase
    end

endmodule