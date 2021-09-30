module control (
    input [6:0] opcode,
    output [10:0] ctrl_sigs
);
    
    reg [10:0] ctrl_sigs;

    always @(*) begin
        
        case (opcode)
            7'b0000011: ctrl_sigs = 11'b00001110001; // control for load operation.
            7'b0100011: ctrl_sigs = 11'b00000010010; // control for store operation.
            7'b0010011: ctrl_sigs = 11'b00001011000; // control for reg-immediate alu operations.
            7'b0110011: ctrl_sigs = 11'b00001000100; // control for r-type alu operations.
            7'b1100011: ctrl_sigs = 11'b01000001100; // control for conditional branch operations.
            7'b1100111: ctrl_sigs = 11'b11101010000; // control for JALR.
            7'b1101111: ctrl_sigs = 11'b10101000000; // control for JAL.
            7'b0110111: ctrl_sigs = 11'b00011000000; // control for LUI.
            7'b0010111: ctrl_sigs = 11'b00011100000; // control for AUIPC.
            default; ctrl_sigs = 11'b0;
        endcase

    end

endmodule