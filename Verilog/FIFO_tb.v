`timescale 1ns/1ps

module FIFO_tb;

  // Parameters
  parameter DSIZE = 8;
  parameter ASIZE = 4;

  // Signals
  reg  [DSIZE-1:0] wdata;
  reg             winc, wclk, wrst_n;
  reg             rinc, rclk, rrst_n;
  wire [DSIZE-1:0] rdata;
  wire            wfull, rempty;

  // Instantiate DUT
  FIFO #(DSIZE, ASIZE) dut (
    .rdata(rdata),
    .wfull(wfull),
    .rempty(rempty),
    .wdata(wdata),
    .winc(winc),
    .wclk(wclk),
    .wrst_n(wrst_n),
    .rinc(rinc),
    .rclk(rclk),
    .rrst_n(rrst_n)
  );

  // Clock generators
  initial begin
    wclk = 0;
    forever #5 wclk = ~wclk;  // 100 MHz
  end

  initial begin
    rclk = 0;
    forever #7 rclk = ~rclk;  // ~71 MHz
  end

  // Write task
  task do_write(input [DSIZE-1:0] data);
    begin
      @(posedge wclk);
      if (!wfull) begin
        wdata <= data;
        winc <= 1;
        @(posedge wclk);
        winc <= 0;
      end else begin
        $display("Write %0d skipped: FIFO FULL", data);
      end
    end
  endtask

  // Read task
  task do_read;
    begin
      @(posedge rclk);
      if (!rempty) begin
        rinc <= 1;
        @(posedge rclk);
        $display("Read = %0d", rdata);
        rinc <= 0;
      end else begin
        $display("Read skipped: FIFO EMPTY");
      end
    end
  endtask

  // Main test
  initial begin
    // Dump signals to VCD file
    $dumpfile("fifo_dump.vcd");
    $dumpvars(0, FIFO_tb);
    $dumpvars(0, dut);

    // Init
    wdata = 0;
    winc = 0;
    rinc = 0;
    wrst_n = 0;
    rrst_n = 0;

    // Reset
    #10;
    wrst_n = 1;
    rrst_n = 1;

    // Write
    do_write(8'd11);
    do_write(8'd22);
    do_write(8'd33);
    do_write(8'd44);

    // Read after delay
    #30;
    do_read();
    do_read();
    do_read();
    do_read();
    do_read();  // One extra

    // Write more than capacity
    repeat (20) begin
      do_write($random % 256);
    end

    #100;
    $finish;
  end

endmodule
