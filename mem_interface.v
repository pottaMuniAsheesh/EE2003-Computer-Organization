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