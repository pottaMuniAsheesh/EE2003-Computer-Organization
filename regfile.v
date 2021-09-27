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