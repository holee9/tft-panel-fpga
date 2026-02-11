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

    initial begin clk = 0; forever #5 clk = ~clk; end;

    logic [31:0] mem[256];
    assign reg_rdata = mem[reg_addr];

    task spi_cycle;
        input bit data_bit;
        begin
            spi_mosi = data_bit;
            #10;
            spi_sclk = 1;
            #30;
            spi_sclk = 0;
            #10;
        end
    endtask

    initial begin
        $display("=== SPI Slave Interface Test ===");

        rst_n = 0;
        spi_cs_n = 1;
        spi_sclk = 0;
        spi_mosi = 0;

        for (integer i = 0; i < 256; i=i+1) mem[i] = 32'hDEADBEEF + i;

        repeat (10) @(posedge clk);
        rst_n = 1;
        repeat (10) @(posedge clk);

        // Test 1: addr=0xAB, data=0x12345678
        $display("\n[TEST 1] addr=0xAB, data=0x12345678");
        spi_cs_n = 0;
        #20;

        // 8-bit address: 0xAB = 0b10101011, LSB-first: 1,1,0,1,0,1,0,1
        spi_cycle(1'b1); spi_cycle(1'b1); spi_cycle(1'b0); spi_cycle(1'b1);
        spi_cycle(1'b0); spi_cycle(1'b1); spi_cycle(1'b0); spi_cycle(1'b1);

        // 32-bit data: 0x12345678
        // Byte 0: 0x78 = 0b01111000, LSB-first: 0,0,0,1,1,1,1,0
        spi_cycle(1'b0); spi_cycle(1'b0); spi_cycle(1'b0); spi_cycle(1'b1);
        spi_cycle(1'b1); spi_cycle(1'b1); spi_cycle(1'b1); spi_cycle(1'b0);
        // Byte 1: 0x56 = 0b01010110, LSB-first: 0,1,1,0,1,0,1,0
        spi_cycle(1'b0); spi_cycle(1'b1); spi_cycle(1'b1); spi_cycle(1'b0);
        spi_cycle(1'b1); spi_cycle(1'b0); spi_cycle(1'b1); spi_cycle(1'b0);
        // Byte 2: 0x34 = 0b00110100, LSB-first: 0,0,1,0,1,1,0,0
        spi_cycle(1'b0); spi_cycle(1'b0); spi_cycle(1'b1); spi_cycle(1'b0);
        spi_cycle(1'b1); spi_cycle(1'b1); spi_cycle(1'b0); spi_cycle(1'b0);
        // Byte 3: 0x12 = 0b00010010, LSB-first: 0,1,0,0,1,0,0,0
        spi_cycle(1'b0); spi_cycle(1'b1); spi_cycle(1'b0); spi_cycle(1'b0);
        spi_cycle(1'b1); spi_cycle(1'b0); spi_cycle(1'b0); spi_cycle(1'b0);

        #20;
        spi_cs_n = 1;
        #100;

        $display("Result: addr=%h, data=%h, write=%b", reg_addr, reg_wdata, reg_write);

        if (reg_addr == 8'hAB && reg_wdata == 32'h12345678 && reg_write)
            $display("[PASS] Test 1");
        else
            $display("[FAIL] Test 1 - Expected addr=AB, data=12345678, write=1");

        $display("\n=== Test Complete ===");
        #1000;
        $finish;
    end

    initial begin #500000 $display("ERROR: Test timeout!"); $finish; end

endmodule
