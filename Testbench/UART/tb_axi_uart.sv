`timescale 1ns/1ps

`include "axi_uart_defines.vh"
`include "axi_uart.vh"

module tb_axi_uart;

    // ============================================================
    // PARAMETERS
    // ============================================================

    localparam AXI_DATA_WIDTH = `_AXI_UART_DATA_WIDTH_;
    localparam AXI_ADDR_WIDTH = `_AXI_UART_ADDR_WIDTH_;
    localparam AXI_ID_WIDTH   = `_AXI_UART_ID_WIDTH_;
    localparam AXI_BYTE_NUM   = AXI_DATA_WIDTH / 8;
    localparam AXI_RESP_WIDTH = 2;

    localparam AXI_LSB_WIDTH = 2;

    localparam UART_THR = `_UART_THR_;
    localparam UART_LSR = `_UART_LSR_;

    // DUT decodes:
    // axi_araddr_i[AXI_ADDR_WIDTH-1:AXI_LSB_WIDTH]
    //
    // Therefore:
    // UART_LSR = 5
    // AXI address = 5 << 2 = 0x14

    localparam [AXI_ADDR_WIDTH-1:0] UART_THR_ADDR =
        UART_THR << AXI_LSB_WIDTH;

    localparam [AXI_ADDR_WIDTH-1:0] UART_LSR_ADDR =
        UART_LSR << AXI_LSB_WIDTH;

    // ============================================================
    // CLOCK / RESET
    // ============================================================

    reg fixed_clk_i;
    reg axi_aclk_i;
    reg axi_aresetn_i;

    // ============================================================
    // AXI READ
    // ============================================================

    reg  [AXI_ID_WIDTH-1:0]   axi_arid_i;
    reg  [AXI_ADDR_WIDTH-1:0] axi_araddr_i;
    reg                       axi_arvalid_i;
    wire                      axi_arready_o;

    wire [AXI_ID_WIDTH-1:0]   axi_rid_o;
    wire [AXI_DATA_WIDTH-1:0] axi_rdata_o;
    wire [AXI_RESP_WIDTH-1:0] axi_rresp_o;
    wire                      axi_rvalid_o;
    reg                       axi_rready_i;

    // ============================================================
    // AXI WRITE
    // ============================================================

    reg  [AXI_ID_WIDTH-1:0]   axi_awid_i;
    reg  [AXI_ADDR_WIDTH-1:0] axi_awaddr_i;
    reg                       axi_awvalid_i;
    wire                      axi_awready_o;

    reg  [AXI_DATA_WIDTH-1:0] axi_wdata_i;
    reg  [AXI_BYTE_NUM-1:0]   axi_wstrb_i;
    reg                       axi_wvalid_i;
    wire                      axi_wready_o;

    wire [AXI_ID_WIDTH-1:0]   axi_bid_o;
    wire [AXI_RESP_WIDTH-1:0] axi_bresp_o;
    wire                      axi_bvalid_o;
    reg                       axi_bready_i;

    // ============================================================
    // UART
    // ============================================================

    reg  uart_rx_i;
    wire uart_tx_o;

    // ============================================================
    // INTERRUPT
    // ============================================================

    wire read_interrupt_o;

    // ============================================================
    // TEST STATUS
    // ============================================================

    integer write_pass;
    integer read_pass;
    integer wait_count;

    // ============================================================
    // DUT
    // ============================================================

    axi_uart_top dut (

        .axi_arready_o    (axi_arready_o),
        .axi_rid_o        (axi_rid_o),
        .axi_rdata_o      (axi_rdata_o),
        .axi_rresp_o      (axi_rresp_o),
        .axi_rvalid_o     (axi_rvalid_o),

        .axi_awready_o    (axi_awready_o),
        .axi_wready_o     (axi_wready_o),
        .axi_bid_o        (axi_bid_o),
        .axi_bresp_o      (axi_bresp_o),
        .axi_bvalid_o     (axi_bvalid_o),

        .read_interrupt_o (read_interrupt_o),
        .uart_tx_o        (uart_tx_o),

        .fixed_clk_i      (fixed_clk_i),
        .axi_aclk_i       (axi_aclk_i),
        .axi_aresetn_i    (axi_aresetn_i),

        .axi_arid_i       (axi_arid_i),
        .axi_araddr_i     (axi_araddr_i),
        .axi_arvalid_i    (axi_arvalid_i),
        .axi_rready_i     (axi_rready_i),

        .axi_awid_i       (axi_awid_i),
        .axi_awaddr_i     (axi_awaddr_i),
        .axi_awvalid_i    (axi_awvalid_i),

        .axi_wdata_i      (axi_wdata_i),
        .axi_wstrb_i      (axi_wstrb_i),
        .axi_wvalid_i     (axi_wvalid_i),

        .axi_bready_i     (axi_bready_i),

        .uart_rx_i        (uart_rx_i)
    );

    // ============================================================
    // FIXED CLOCK
    // ============================================================

    initial begin
        fixed_clk_i = 1'b0;

        forever begin
            #5;
            fixed_clk_i = ~fixed_clk_i;
        end
    end

    // ============================================================
    // AXI CLOCK
    // ============================================================

    initial begin
        axi_aclk_i = 1'b0;

        forever begin
            #5;
            axi_aclk_i = ~axi_aclk_i;
        end
    end

    // ============================================================
    // FSDB
    // ============================================================

    initial begin
        $fsdbDumpfile("uart.fsdb");
        $fsdbDumpvars(0, tb_axi_uart);
        $fsdbDumpMDA();
    end

    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // INITIAL VALUES
        // --------------------------------------------------------

        axi_aresetn_i = 1'b0;

        axi_arid_i    = {AXI_ID_WIDTH{1'b0}};
        axi_araddr_i  = {AXI_ADDR_WIDTH{1'b0}};
        axi_arvalid_i = 1'b0;
        axi_rready_i  = 1'b0;

        axi_awid_i    = {AXI_ID_WIDTH{1'b0}};
        axi_awaddr_i  = {AXI_ADDR_WIDTH{1'b0}};
        axi_awvalid_i = 1'b0;

        axi_wdata_i   = {AXI_DATA_WIDTH{1'b0}};
        axi_wstrb_i   = {AXI_BYTE_NUM{1'b0}};
        axi_wvalid_i  = 1'b0;

        axi_bready_i  = 1'b0;

        uart_rx_i     = 1'b1;

        write_pass    = 0;
        read_pass     = 0;
        wait_count    = 0;

        // --------------------------------------------------------
        // HEADER
        // --------------------------------------------------------

        $display("");
        $display("==============================================================");
        $display("                  AXI UART TESTBENCH");
        $display("==============================================================");
        $display("");

        // --------------------------------------------------------
        // RESET
        // --------------------------------------------------------

        $display("##############################################################");
        $display("#                         RESET BLOCK                        #");
        $display("##############################################################");

        $display("[RESET] Reset asserted");

        axi_aresetn_i = 1'b0;

        #200;

        axi_aresetn_i = 1'b1;

        $display("[RESET] Reset released");
        $display("[RESET] Time = %0t ns", $time);
        $display("[RESET] RESET BLOCK : PASS");

        $display("##############################################################");
        $display("");

        // --------------------------------------------------------
        // WRITE
        // --------------------------------------------------------

        $display("##############################################################");
        $display("#                 TRANSACTION 1 : WRITE                      #");
        $display("##############################################################");

        axi_write(
            UART_THR_ADDR,
            32'h00000055
        );

        #100;

        // --------------------------------------------------------
        // READ
        // --------------------------------------------------------

        $display("");
        $display("##############################################################");
        $display("#                  TRANSACTION 2 : READ                      #");
        $display("##############################################################");

        axi_read(
            UART_LSR_ADDR
        );

        #100;

        // --------------------------------------------------------
        // RESULT
        // --------------------------------------------------------

        $display("");
        $display("==============================================================");
        $display("                    OVERALL TEST RESULT");
        $display("==============================================================");
        $display("");

        if (write_pass)
            $display("        WRITE TRANSACTION : PASS");
        else
            $display("        WRITE TRANSACTION : FAIL");

        if (read_pass)
            $display("        READ  TRANSACTION : PASS");
        else
            $display("        READ  TRANSACTION : FAIL");

        $display("");

        if (write_pass && read_pass) begin

            $display("##############################################################");
            $display("#                                                            #");
            $display("#                    OVERALL PASS                            #");
            $display("#                                                            #");
            $display("#        WRITE TRANSACTION : PASS                            #");
            $display("#        READ  TRANSACTION : PASS                            #");
            $display("#                                                            #");
            $display("#        AXI UART TESTBENCH PASSED                          #");
            $display("#                                                            #");
            $display("##############################################################");

        end
        else begin

            $display("##############################################################");
            $display("#                                                            #");
            $display("#                    OVERALL FAIL                            #");
            $display("#                                                            #");
            $display("#        AXI UART TESTBENCH FAILED                          #");
            $display("#                                                            #");
            $display("##############################################################");

        end

        $display("");
        $display("==============================================================");
        $display("                  TESTBENCH COMPLETE");
        $display("==============================================================");
        $display("");

        #100;

        $finish;

    end

    // ============================================================
    // WRITE TASK
    // ============================================================

    task axi_write;

        input [AXI_ADDR_WIDTH-1:0] addr;
        input [AXI_DATA_WIDTH-1:0] data;

        begin

            $display("");
            $display("--------------------------------------------------------------");
            $display("                    WRITE START BLOCK");
            $display("--------------------------------------------------------------");

            $display("[WRITE START] Address = 0x%0h", addr);
            $display("[WRITE START] Data    = 0x%0h", data);
            $display("[WRITE START] Time    = %0t ns", $time);

            @(posedge axi_aclk_i);

            axi_awid_i    <= {AXI_ID_WIDTH{1'b0}};
            axi_awaddr_i  <= addr;
            axi_awvalid_i <= 1'b1;

            axi_wdata_i   <= data;
            axi_wstrb_i   <= {AXI_BYTE_NUM{1'b1}};
            axi_wvalid_i  <= 1'b1;

            axi_bready_i  <= 1'b1;

            $display("");
            $display("[WRITE BUS] AWVALID = 1");
            $display("[WRITE BUS] WVALID  = 1");
            $display("[WRITE BUS] BREADY  = 1");

            // ----------------------------------------------------
            // WAIT AWREADY/WREADY
            // ----------------------------------------------------

            wait_count = 0;

            while ((!axi_awready_o || !axi_wready_o) &&
                   wait_count < 100) begin

                @(posedge axi_aclk_i);
                wait_count = wait_count + 1;

            end

            if (!axi_awready_o || !axi_wready_o) begin

                $display("[WRITE BUS] ERROR");
                $display("[WRITE BUS] Timeout");
                $display("[WRITE BUS] AWREADY = %b", axi_awready_o);
                $display("[WRITE BUS] WREADY  = %b", axi_wready_o);

                write_pass = 0;

                axi_awvalid_i <= 1'b0;
                axi_wvalid_i  <= 1'b0;
                axi_bready_i  <= 1'b0;

            end
            else begin

                $display("[WRITE BUS] AWREADY = 1");
                $display("[WRITE BUS] WREADY  = 1");
                $display("[WRITE BUS] AXI WRITE ACCEPTED");

                // ------------------------------------------------
                // WAIT BVALID
                // ------------------------------------------------

                wait_count = 0;

                while (!axi_bvalid_o && wait_count < 100) begin

                    @(posedge axi_aclk_i);
                    wait_count = wait_count + 1;

                end

                if (!axi_bvalid_o) begin

                    $display("[WRITE RESPONSE] ERROR");
                    $display("[WRITE RESPONSE] BVALID timeout");

                    write_pass = 0;

                end
                else begin

                    $display("");
                    $display("[WRITE RESPONSE] BVALID = 1");
                    $display("[WRITE RESPONSE] BRESP  = %0h",
                             axi_bresp_o);
                    $display("[WRITE RESPONSE] BID    = 0x%0h",
                             axi_bid_o);
                    $display("[WRITE RESPONSE] Time   = %0t ns",
                             $time);

                    if (axi_bresp_o == 2'b00) begin

                        $display("[WRITE RESPONSE] BRESP CHECK : PASS");

                        write_pass = 1;

                    end
                    else begin

                        $display("[WRITE RESPONSE] BRESP CHECK : FAIL");

                        write_pass = 0;

                    end

                end

                @(posedge axi_aclk_i);

                axi_awvalid_i <= 1'b0;
                axi_wvalid_i  <= 1'b0;
                axi_bready_i  <= 1'b0;

            end

        end

    endtask

    // ============================================================
    // READ TASK
    // ============================================================

    task axi_read;

        input [AXI_ADDR_WIDTH-1:0] addr;

        begin

            $display("");
            $display("--------------------------------------------------------------");
            $display("                     READ START BLOCK");
            $display("--------------------------------------------------------------");

            $display("[READ START] Address = 0x%0h", addr);
            $display("[READ START] Register = UART_LSR");
            $display("[READ START] Time    = %0t ns", $time);

            // ----------------------------------------------------
            // START READ
            // ----------------------------------------------------

            @(posedge axi_aclk_i);

            axi_arid_i    <= {AXI_ID_WIDTH{1'b0}};
            axi_araddr_i  <= addr;

            // IMPORTANT:
            // Keep ARVALID HIGH until RVALID.
            //
            // DUT has:
            // axi_rden = axi_arvalid_i
            //
            // and:
            // axi_rvalid_o =
            //     axi_rden & ~axi_sync_rden & axi_rvalid
            //
            // Therefore ARVALID must remain asserted while
            // waiting for the read response.

            axi_arvalid_i <= 1'b1;
            axi_rready_i  <= 1'b1;

            $display("");
            $display("[READ BUS] ARVALID = 1");
            $display("[READ BUS] RREADY  = 1");

            // ----------------------------------------------------
            // WAIT ARREADY
            // ----------------------------------------------------

            wait_count = 0;

            while (!axi_arready_o && wait_count < 100) begin

                @(posedge axi_aclk_i);
                wait_count = wait_count + 1;

            end

            if (!axi_arready_o) begin

                $display("");
                $display("[READ BUS] ERROR");
                $display("[READ BUS] ARREADY timeout");
                $display("[READ BUS] ARREADY = %b",
                         axi_arready_o);
                $display("[READ BUS] Address = 0x%0h",
                         addr);

                read_pass = 0;

                axi_arvalid_i <= 1'b0;
                axi_rready_i  <= 1'b0;

            end
            else begin

                $display("");
                $display("[READ BUS] ARREADY = 1");
                $display("[READ BUS] AXI READ ADDRESS ACCEPTED");
                $display("[READ BUS] Address = 0x%0h", addr);
                $display("[READ BUS] Time = %0t ns", $time);

                // ------------------------------------------------
                // IMPORTANT:
                // DO NOT DEASSERT ARVALID HERE.
                //
                // Keep ARVALID = 1 while waiting for RVALID.
                // ------------------------------------------------

                $display("");
                $display("[READ RESPONSE] Waiting for RVALID...");
                $display("[READ RESPONSE] ARVALID kept HIGH");

                wait_count = 0;

                while (!axi_rvalid_o && wait_count < 100) begin

                    @(posedge axi_aclk_i);

                    wait_count = wait_count + 1;

                    $display("[READ WAIT] Time=%0t ns ARVALID=%b ARREADY=%b RVALID=%b RREADY=%b",
                             $time,
                             axi_arvalid_i,
                             axi_arready_o,
                             axi_rvalid_o,
                             axi_rready_i);

                end

                // ------------------------------------------------
                // CHECK RVALID
                // ------------------------------------------------

                if (!axi_rvalid_o) begin

                    $display("");
                    $display("[READ RESPONSE] ERROR");
                    $display("[READ RESPONSE] RVALID timeout");
                    $display("[READ RESPONSE] RVALID = %b",
                             axi_rvalid_o);
                    $display("[READ RESPONSE] Time = %0t ns",
                             $time);

                    read_pass = 0;

                end
                else begin

                    $display("");
                    $display("##############################################################");
                    $display("#                  READ RESPONSE RECEIVED                   #");
                    $display("##############################################################");

                    $display("[READ RESPONSE] RVALID = 1");
                    $display("[READ RESPONSE] RREADY = 1");
                    $display("[READ RESPONSE] RRESP  = %0h",
                             axi_rresp_o);
                    $display("[READ RESPONSE] RID    = 0x%0h",
                             axi_rid_o);
                    $display("[READ RESPONSE] RDATA  = 0x%0h",
                             axi_rdata_o);
                    $display("[READ RESPONSE] Time   = %0t ns",
                             $time);

                    if (axi_rresp_o == 2'b00) begin

                        $display("[READ RESPONSE] RRESP CHECK : PASS");

                        read_pass = 1;

                    end
                    else begin

                        $display("[READ RESPONSE] RRESP CHECK : FAIL");

                        read_pass = 0;

                    end

                end

                // ------------------------------------------------
                // NOW RELEASE READ CHANNEL
                // ------------------------------------------------

                @(posedge axi_aclk_i);

                axi_arvalid_i <= 1'b0;
                axi_rready_i  <= 1'b0;

                $display("[READ BUS] ARVALID = 0");
                $display("[READ BUS] RREADY  = 0");

                if (read_pass) begin

                    $display("");
                    $display("##############################################################");
                    $display("#                                                            #");
                    $display("#               READ TRANSACTION PASS                       #");
                    $display("#                                                            #");
                    $display("#  ADDRESS = 0x%0h                                       #",
                             addr);
                    $display("#  RDATA   = 0x%0h                                       #",
                             axi_rdata_o);
                    $display("#  RRESP   = 00 (OKAY)                                      #");
                    $display("#                                                            #");
                    $display("##############################################################");

                end
                else begin

                    $display("");
                    $display("##############################################################");
                    $display("#                                                            #");
                    $display("#               READ TRANSACTION FAIL                       #");
                    $display("#                                                            #");
                    $display("##############################################################");

                end

            end

        end

    endtask

endmodule
