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
            iaddr <= iaddr + 4;
        end
    end

    wire [31:0] rs1data;
    wire [31:0] rs2data;
    wire [6:0] ctrl_sigs;
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

    assign regfile_wdata = (ctrl_sigs[5]) ? regfile_wdata_memintf : alu_res;
    assign alu_in2 = (ctrl_sigs[4]) ? imm_value : rs2data;
    assign alu_ctrl_inst_seg = {idata[30], idata[14:12]};

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

endmodule

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