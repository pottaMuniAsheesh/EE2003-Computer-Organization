module cpu (
    input clk, 
    input reset,
    output [31:0] iaddr,
    input [31:0] idata,
    output [31:0] daddr,
    input [31:0] drdata,
    output [31:0] dwdata,
    output [3:0] dwe
);
    reg [31:0] iaddr;
    reg [31:0] daddr;
    reg [31:0] dwdata;
    reg [3:0]  dwe;

    always @(posedge clk) begin
        if (reset) begin
            iaddr <= 0;
            daddr <= 0;
            dwdata <= 0;
            dwe <= 0;
        end else begin 
            iaddr <= next_iaddr; // next iaddr selected from next_iaddr_mux.
        end
    end

    wire [31:0] rs1data;
    wire [31:0] rs2data;
    wire [10:0] ctrl_sigs;
    wire [31:0] regfile_wdata;
    wire [3:0] alu_func;
    wire [31:0] alu_res;
    wire [31:0] imm_value;
    wire [31:0] regfile_wdata_memintf;
    wire [31:0] alu_in2;
    wire [3:0] alu_ctrl_inst_seg;
    wire [31:0] dmem_wdata;
    wire [3:0] dmem_we;
    wire zero;
    wire [31:0] rel_jump_iaddr;
    wire [31:0] abs_jump_iaddr;
    wire [31:0] norm_iaddr;
    wire branch_cond_satisfied;
    wire [31:0] next_iaddr;
    wire [2:0] wdata_select;

    // assign regfile_wdata = (ctrl_sigs[5]) ? regfile_wdata_memintf : alu_res; // Not needed. wdata_mux does this job.
    assign alu_in2 = (ctrl_sigs[4]) ? imm_value : rs2data;
    assign alu_ctrl_inst_seg = {idata[30], idata[14:12]};
    assign norm_iaddr = iaddr + 4;                            // PC + 4
    assign rel_jump_iaddr = iaddr + imm_value;                // PC + Imm. For conditonal and JAL.
    assign abs_jump_iaddr = (alu_res) & ({{31{1'b1}}, 1'b0}); // (rs1 + Imm) => alu result, with least significant bit set to zero.
    assign wdata_select = {ctrl_sigs[8:7], ctrl_sigs[5]};

    always @(*) begin
        if(!reset) begin
            dwdata = dmem_wdata;
            dwe = dmem_we;
            daddr = alu_res;
        end
    end

    regfile rf(
        .clk(clk),
        .reset(reset),
        .rs1addr(idata[19:15]),
        .rs2addr(idata[24:20]),
        .rdaddr(idata[11:7]),
        .writedata(regfile_wdata),
        .regwrite(ctrl_sigs[6]),
        .rs1data(rs1data),
        .rs2data(rs2data)
    );

    mem_interface i0(
        .inst_seg(idata[14:12]),
        .offset(alu_res[1:0]),
        .dmem_rdata(drdata),
        .regfile_rdata(rs2data),
        .load(ctrl_sigs[0]),
        .store(ctrl_sigs[1]),
        .regfile_wdata(regfile_wdata_memintf),
        .dmem_wdata(dmem_wdata),
        .dmem_we(dmem_we)
    );

    alu_control i1(
        .ALUOp(ctrl_sigs[3:2]),
        .inst_seg(alu_ctrl_inst_seg),
        .alu_func_code(alu_func)
    );

    alu i2(
        .func_code(alu_func),
        .in1(rs1data),
        .in2(alu_in2),
        .result(alu_res),
        .zero(zero)
    );

    imm_gen i3(
        .inst(idata),
        .imm_value(imm_value)
    );

    control i4(
        .opcode(idata[6:0]),
        .ctrl_sigs(ctrl_sigs)
    );

    branch_cond_check i5(
        .branch_type(ctrl_sigs[10:9]),
        .inst_seg(idata[14:12]),
        .zero(zero),
        .cond_satisfied(branch_cond_satisfied)
    );

    next_iaddr_mux i6(
        .branch_type(ctrl_sigs[10:9]),
        .cond_satisfied(branch_cond_satisfied),
        .norm_iaddr(norm_iaddr),
        .rel_jump_iaddr(rel_jump_iaddr),
        .abs_jump_iaddr(abs_jump_iaddr),
        .next_iaddr(next_iaddr)
    );

    wdata_mux i7(
        .select(wdata_select),
        .alu_res(alu_res),
        .mem_int_out(regfile_wdata_memintf),
        .imm_value(imm_value),
        .rel_jump_iaddr(rel_jump_iaddr),
        .norm_iaddr(norm_iaddr),
        .regfile_wdata(regfile_wdata)
    );

endmodule

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
            default: ctrl_sigs = 11'b0;
        endcase

    end

endmodule

module regfile(
    input clk,
    input reset,
    input [4:0] rs1addr,
    input [4:0] rs2addr,
    input [4:0] rdaddr,
    input [31:0] writedata,
    input regwrite,
    output [31:0] rs1data,
    output [31:0] rs2data
);

    reg [31:0] registers [31:0];
    integer i;

    always @(posedge clk) begin
        if(reset) begin
            for(i = 0; i<32; i = i+1) begin
                registers[i] <= 0;
            end
        end
        if(regwrite && !reset) begin
            registers[rdaddr] <= (rdaddr == 5'b0) ? 32'b0 : writedata;
        end
    end

    assign rs1data = registers[rs1addr];
    assign rs2data = registers[rs2addr];

endmodule

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

module mem_interface (
    input [2:0] inst_seg,
    input [1:0] offset,
    input [31:0] dmem_rdata,
    input [31:0] regfile_rdata,
    input load,
    input store,
    output [31:0] regfile_wdata,
    output [31:0] dmem_wdata,
    output [3:0] dmem_we
);

    reg [31:0] regfile_wdata;
    reg [31:0] dmem_wdata;
    reg [3:0] dmem_we;

    always @(*) begin
        if(store) begin
            
            dmem_wdata = regfile_rdata << 8*offset;

            case (inst_seg)
                3'b000: dmem_we = {offset[1]&offset[0], offset[1]&(~offset[0]), (~offset[1])&offset[0], (~offset[1])&(~offset[0])};
                3'b001: dmem_we = {{2{offset[1]}}, {2{~offset[1]}}};
                3'b010: dmem_we = 4'b1111;
                default: dmem_we = 4'b0000;
            endcase

        end
        else begin
            dmem_we = 4'b0000;
        end
    end

    always @(*) begin
        if(load) begin

            case (inst_seg)
                3'b000: regfile_wdata = {{24{dmem_rdata[8*offset+7 +: 1]}}, dmem_rdata[8*offset +: 8]};
                3'b001: regfile_wdata = {{16{dmem_rdata[8*offset+15 +: 1]}}, dmem_rdata[8*offset +: 16]};
                3'b010: regfile_wdata = dmem_rdata;
                3'b100: regfile_wdata = {{24{1'b0}}, dmem_rdata[8*offset +: 8]};
                3'b101: regfile_wdata = {{16{1'b0}}, dmem_rdata[8*offset +: 16]};
                default: regfile_wdata = dmem_rdata;
            endcase

        end
    end
    
endmodule

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