module control (
    input [6:0] opcode,
    output [6:0] ctrl_sigs
);
    
    reg [6:0] ctrl_sigs;

    always @(*) begin
        
        case (opcode)
            7'b0000011: ctrl_sigs = 7'b1110001; // control for load operation.
            7'b0100011: ctrl_sigs = 7'b0010010; // control for store operation.
            7'b0010011: ctrl_sigs = 7'b1011000; // control for reg-immediate alu operations.
            7'b0110011: ctrl_sigs = 7'b1000100; // control for r-type alu operations.
        endcase

    end

endmodule