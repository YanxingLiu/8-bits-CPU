`timescale 1ns/1ns

module core_tb();
reg clk;

initial 
    begin
        $dumpfile("test.vcd");
        $dumpvars(1,core1);
    end

initial 
    begin
        clk <= 1'b0;
        forever
       #1 clk<=~clk; 
    end
    core core1(.clk(clk));
endmodule