// SPI Slave Interface Testbench
`timescale 1ns/1ps
module tb_spi_slave_interface;
    logic clk, rst_n;
    logic spi_sclk, spi_mosi, spi_miso, spi_cs_n;
    logic [7:0] reg_addr;
    logic [31:0] reg_wdata, reg_rdata;
    logic reg_write, reg_read;

    spi_slave_interface dut (
        .clk, .rst_n, .spi_sclk, .spi_mosi, .spi_miso, .spi_cs_n,
        .reg_addr, .reg_wdata, .reg_rdata, .reg_write, .reg_read
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    logic [31:0] mem[256];
    assign reg_rdata = mem[reg_addr];

    integer i;
    initial begin
        $display("=== SPI Slave Interface Test Started ===");
        rst_n = 0; spi_cs_n = 1; spi_sclk = 0; spi_mosi = 0;
        for (i = 0; i < 256; i=i+1) mem[i] = i;
        #100; rst_n = 1; #100;

        $display("[TEST 1] Basic register write");
        spi_cs_n = 0;
        #100;
        // Send address (0x00)
        spi_mosi = 1'b0; #100; spi_sclk = 1; #100; spi_sclk = 0;
        spi_mosi = 1'b0; #100; spi_sclk = 1; #100; spi_sclk = 0;
        spi_mosi = 1'b0; #100; spi_sclk = 1; #100; spi_sclk = 0;
        spi_mosi = 1'b0; #100; spi_sclk = 1; #100; spi_sclk = 0;
        spi_mosi = 1'b0; #100; spi_sclk = 1; #100; spi_sclk = 0;
        spi_mosi = 1'b0; #100; spi_sclk = 1; #100; spi_sclk = 0;
        spi_mosi = 1'b0; #100; spi_sclk = 1; #100; spi_sclk = 0;
        spi_mosi = 1'b0; #100; spi_sclk = 1; #100; spi_sclk = 0;
        // Send data (0xDEADBEEF)
        spi_mosi = 1'b1; #100; spi_sclk = 1; #100; spi_sclk = 0;
        spi_mosi = 1'b1; #100; spi_sclk = 1; #100; spi_sclk = 0;
        spi_mosi = 1'b0; #100; spi_sclk = 1; #100; spi_sclk = 0;
        spi_mosi = 1'b1; #100; spi_sclk = 1; #100; spi_sclk = 0;
        spi_mosi = 1'b1; #100; spi_sclk = 1; #100; spi_sclk = 0;
        spi_mosi = 1'b0; #100; spi_sclk = 1; #100; spi_sclk = 0;
        spi_mosi = 1'b1; #100; spi_sclk = 1; #100; spi_sclk = 0;
        spi_mosi = 1'b1; #100; spi_sclk = 1; #100; spi_sclk = 0;
        #100; spi_cs_n = 1;
        #500;
        if (reg_addr == 8'h00 && reg_wdata == 32'hDEADBEEF && reg_write)
            $display("[PASS] Basic write test");
        else
            $display("[FAIL] Basic write test");

        #1000;
        $display("=== All Tests Completed ===");
        $finish;
    end

    initial begin #100000 $display("ERROR: Test timeout!"); $finish; end
endmodule
