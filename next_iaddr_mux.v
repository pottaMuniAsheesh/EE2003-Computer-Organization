module next_iaddr_mux (
    input [1:0] branch_type,
    input cond_satisfied,
    input [31:0] norm_iaddr,
    input [31:0] rel_jump_iaddr,
    input [31:0] abs_jump_iaddr,
    output [31:0] next_iaddr
);

    reg [31:0] next_iaddr;
    
    always @(*) begin
        
        case (branch_type)
            2'b00: next_iaddr = norm_iaddr;                                     // if non-branching instruction, then PC + 4.
            2'b01: next_iaddr = (cond_satisfied) ? rel_jump_iaddr : norm_iaddr; /* if conditional-branching, then choose between PC + Imm and PC + 4 based on whether condition is satified or not */
            2'b10: next_iaddr = rel_jump_iaddr;                                 // for JAL, choose PC + Imm.
            2'b11: next_iaddr = abs_jump_iaddr;                                 // for JALR.
        endcase

    end

endmodule