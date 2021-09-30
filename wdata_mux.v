module wdata_mux (
    input [2:0] select,
    input [31:0] alu_res,
    input [31:0] mem_int_out,
    input [31:0] imm_value,
    input [31:0] rel_jump_iaddr,
    input [31:0] norm_iaddr,
    output [31:0] regfile_wdata
);

    reg [31:0] regfile_wdata;

    always @(*) begin
        
        case (select)
            3'b000: regfile_wdata = alu_res;
            3'b001: regfile_wdata = mem_int_out;
            3'b010: regfile_wdata = imm_value;
            3'b011: regfile_wdata = rel_jump_iaddr;
            3'b100: regfile_wdata = norm_iaddr;
            default: regfile_wdata = 32'b0;
        endcase

    end
    
endmodule