module branch_cond_check (
    input [1:0] branch_type,
    input [2:0] inst_seg,
    input zero,
    output cond_satisfied
);

    reg cond_satisfied;

    always @(*) begin
        if(branch_type == 2'b01) begin
            cond_satisfied = inst_seg[2] ^ inst_seg[0] ^ zero; // for conditional-branch instructions.
        end
        else begin
            cond_satisfied = 1'b0; // deasserting for non conditional-branch instructions.
        end
    end
    
endmodule