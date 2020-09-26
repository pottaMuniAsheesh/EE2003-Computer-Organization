`timescale 1ns/1ns 

// This test bench will run for a fixed 1000 clock cycles and then dump out the memory
// Test cases are such that they should finish within this time
// If the CPU continues after this point, it should not result in changes in data
// Safe to assume that imem contains only 0 after the last instruction
module cpu_tb ();
    
    reg  clk, reset;
    wire [31:0] iaddr, idata, daddr, drdata, dwdata;
    wire [3:0] dwe;
    integer i, fail, log_file;

    // Instantiate the CPU
    cpu u1(
        .clk(clk),
        .reset(reset),
        .iaddr(iaddr),
        .idata(idata),
        .daddr(daddr),
        .drdata(drdata),
        .dwdata(dwdata),
        .dwe(dwe)
    );

    imem u2(
        .iaddr(iaddr),
        .idata(idata)
    );

    dmem u3(
        .clk(clk),
        .daddr(daddr),
        .drdata(drdata),
        .dwdata(dwdata),
        .dwe(dwe)
    );

    // Set up clock
    always #5 clk=~clk;

    initial begin
	// Uncomment below to dump out VCD file for gtkwave
	// NOTE: This will NOT work on the jupyter terminal
	// $dumpfile("cpu_tb.vcd");
	// $dumpvars(0, "cpu_tb");
        clk = 1;
        reset = 1;   // This is active high reset
        #100         // At least 100 because Xilinx assumes 100ns reset in post-syn sim
        reset = 0;   // Reset removed - normal functioning resumes
        log_file = $fopen("cpu_tb.log", "a");
        @(posedge clk);
        for (i=0; i<1000; i=i+1) begin
            @(posedge clk);
        end
        
        fail = 0;
        // Dump top dmem
        for (i=0; i<32; i=i+1) begin
            $display("%02x%02x%02x%02x", u3.mem3[i], u3.mem2[i], u3.mem1[i], u3.mem0[i]);
            // if(exp_reg != rv1) begin
            //     $display("FAIL: Expected Reg[%d] = %x vs. Got Reg[%d] = %x", i, $signed(exp_reg), i, rv1);
            //     fail = fail + 1;
            // end 
        end
        if(fail != 0) begin
            $display("FAILED. %d registers do not match.\n", fail);
            $fwrite(log_file, "FAIL\n");
        end else begin
            $fwrite(log_file, "PASS\n");
        end
        $finish;
    end

endmodule
