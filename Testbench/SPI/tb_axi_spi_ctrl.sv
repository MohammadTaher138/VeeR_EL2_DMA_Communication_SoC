`timescale 1ns/1ps
`default_nettype none

module tb_axi_spi_ctrl;

    // ============================================================
    // Parameters
    // ============================================================
    parameter DATA_WIDTH = 8;
    parameter REG_WIDTH  = 32;
    parameter FIFO_DEPTH = 64;
    parameter FIFO_ADDR  = 6;
    parameter SPI_RATIO_GRADE = 2;

    // ============================================================
    // Clock / Reset
    // ============================================================
    reg clk_i;
    reg arst_n_i;
    reg soft_rst_i;

    // ============================================================
    // Control signals
    // ============================================================
    reg slave_select_i;
    reg control_lsb_i;
    reg control_rx_fifo_reset_i;
    reg control_tx_fifo_reset_i;
    reg control_cpha_i;
    reg control_cpol_i;
    reg control_master_i;
    reg control_spi_enable_i;

    reg [SPI_RATIO_GRADE-1:0] spi_ratio_i;

    // ============================================================
    // Status
    // ============================================================
    wire [REG_WIDTH-1:0] status_o;

    // ============================================================
    // TX interface
    // ============================================================
    reg                  tx_req_i;
    reg [DATA_WIDTH-1:0] tx_data_i;
    wire                 tx_ack_o;
    wire [REG_WIDTH-1:0] tx_occupancy_o;

    // ============================================================
    // RX interface
    // ============================================================
    reg                  rx_req_i;
    wire [DATA_WIDTH-1:0] rx_data_o;
    wire                  rx_resp_o;
    reg                  rx_ack_i;
    wire [REG_WIDTH-1:0] rx_occupancy_o;

    // ============================================================
    // SPI pins
    // ============================================================
    wire spi_clk_o;
    wire spi_cs_n_o;
    wire spi_mosi_o;
    wire spi_miso_i;

    // ============================================================
    // Test variables
    // ============================================================
    integer errors;

    reg [DATA_WIDTH-1:0] tx_test_data;
    reg [DATA_WIDTH-1:0] rx_test_data;

    // ============================================================
    // SPI LOOPBACK
    //
    // MOSI is directly connected to MISO.
    //
    // This creates a simple SPI loopback:
    //
    //       DUT MOSI ----------+
    //                          |
    //                          +----> DUT MISO
    //
    // ============================================================
    assign spi_miso_i = spi_mosi_o;

    // ============================================================
    // DUT
    // ============================================================
    axi_spi_ctrl #(
        .SPI_RATIO_GRADE (SPI_RATIO_GRADE),
        .DATA_WIDTH      (DATA_WIDTH),
        .REG_WIDTH       (REG_WIDTH),
        .FIFO_DEPTH      (FIFO_DEPTH),
        .FIFO_ADDR       (FIFO_ADDR)
    ) dut (

        .clk_i                     (clk_i),
        .arst_n_i                  (arst_n_i),
        .soft_rst_i                (soft_rst_i),

        .slave_select_i            (slave_select_i),
        .control_lsb_i             (control_lsb_i),
        .control_rx_fifo_reset_i   (control_rx_fifo_reset_i),
        .control_tx_fifo_reset_i   (control_tx_fifo_reset_i),
        .control_cpha_i            (control_cpha_i),
        .control_cpol_i            (control_cpol_i),
        .control_master_i          (control_master_i),
        .control_spi_enable_i      (control_spi_enable_i),
        .spi_ratio_i               (spi_ratio_i),

        .status_o                  (status_o),

        .tx_req_i                  (tx_req_i),
        .tx_data_i                 (tx_data_i),
        .tx_ack_o                 (tx_ack_o),
        .tx_occupancy_o            (tx_occupancy_o),

        .rx_req_i                  (rx_req_i),
        .rx_data_o                 (rx_data_o),
        .rx_resp_o                 (rx_resp_o),
        .rx_ack_i                  (rx_ack_i),
        .rx_occupancy_o            (rx_occupancy_o),

        .spi_clk_o                 (spi_clk_o),
        .spi_cs_n_o                (spi_cs_n_o),
        .spi_mosi_o                (spi_mosi_o),
        .spi_miso_i                (spi_miso_i)
    );

    // ============================================================
    // CLOCK
    // 100 MHz
    // ============================================================
    always #5 clk_i = ~clk_i;

    // ============================================================
    // MAIN TEST
    // ============================================================
    initial begin

        // --------------------------------------------------------
        // Initialize
        // --------------------------------------------------------
        clk_i = 1'b0;

        arst_n_i = 1'b0;
        soft_rst_i = 1'b0;

        slave_select_i = 1'b0;

        control_lsb_i = 1'b0;
        control_rx_fifo_reset_i = 1'b0;
        control_tx_fifo_reset_i = 1'b0;

        control_cpha_i = 1'b0;
        control_cpol_i = 1'b0;

        control_master_i = 1'b1;
        control_spi_enable_i = 1'b1;

        spi_ratio_i = 2'd2;

        tx_req_i = 1'b0;
        tx_data_i = 8'h00;

        rx_req_i = 1'b0;
        rx_ack_i = 1'b0;

        errors = 0;

        tx_test_data = 8'hA5;
        rx_test_data = 8'h00;

        // --------------------------------------------------------
        // Waveform
        // --------------------------------------------------------
       $fsdbDumpfile("axi_spi_ctrl_tb.fsdb");
       $fsdbDumpvars(0, tb_axi_spi_ctrl);
        // --------------------------------------------------------
        // Header
        // --------------------------------------------------------
        $display("");
        $display("==============================================");
        $display("        AXI SPI CONTROLLER TESTBENCH");
        $display("==============================================");

        // --------------------------------------------------------
        // RESET
        // --------------------------------------------------------
        $display("");
        $display("[TEST] Applying reset...");

        repeat (5)
            @(posedge clk_i);

        arst_n_i = 1'b1;

        repeat (2)
            @(posedge clk_i);

        $display("[TEST] Reset released");

        // --------------------------------------------------------
        // SPI ENABLE
        // --------------------------------------------------------
        slave_select_i = 1'b1;
        control_spi_enable_i = 1'b1;
        control_master_i = 1'b1;

        $display("[TEST] SPI enabled");

        // --------------------------------------------------------
        // SEND DATA
        // --------------------------------------------------------
        $display("");
        $display("[TEST] Sending data = 0x%02h",
                 tx_test_data);

        @(posedge clk_i);

        tx_data_i = tx_test_data;
        tx_req_i  = 1'b1;

        @(posedge clk_i);

        tx_req_i = 1'b0;

        // --------------------------------------------------------
        // WAIT FOR TX ACK
        // --------------------------------------------------------
        begin : TX_WAIT

            integer timeout;

            timeout = 0;

            while (!tx_ack_o && timeout < 1000) begin

                @(posedge clk_i);

                timeout = timeout + 1;

            end

            if (timeout >= 1000) begin

                $display("[FAIL] TX acknowledgement timeout");

                errors = errors + 1;

            end
            else begin

                $display("[PASS] TX FIFO accepted data");

            end

        end

        // --------------------------------------------------------
        // WAIT FOR SPI TRANSFER
        // --------------------------------------------------------
        $display("[TEST] Waiting for SPI transfer...");

        repeat (200)
            @(posedge clk_i);

        // --------------------------------------------------------
        // CHECK RX FIFO
        // --------------------------------------------------------
        $display("");
        $display("[TEST] Reading RX FIFO...");

        rx_req_i = 1'b1;

        begin : RX_WAIT

            integer timeout;

            timeout = 0;

            while (!rx_resp_o && timeout < 1000) begin

                @(posedge clk_i);

                timeout = timeout + 1;

            end

            if (timeout >= 1000) begin

                $display("[FAIL] RX response timeout");

                errors = errors + 1;

            end
            else begin

                rx_test_data = rx_data_o;

                $display("[TEST] RX data = 0x%02h",
                         rx_test_data);

                @(posedge clk_i);

                rx_ack_i = 1'b1;

                @(posedge clk_i);

                rx_ack_i = 1'b0;
                rx_req_i = 1'b0;

            end

        end

        // --------------------------------------------------------
        // COMPARE TX / RX
        // --------------------------------------------------------
        $display("");
        $display("----------------------------------------------");
        $display("             DATA COMPARISON");
        $display("----------------------------------------------");

        $display("TX DATA = 0x%02h", tx_test_data);
        $display("RX DATA = 0x%02h", rx_test_data);

        if (rx_test_data == tx_test_data) begin

            $display("[PASS] SPI LOOPBACK DATA MATCH");

        end
        else begin

            $display("[FAIL] SPI LOOPBACK DATA MISMATCH");

            errors = errors + 1;

        end

        // --------------------------------------------------------
        // STATUS
        // --------------------------------------------------------
        $display("");
        $display("----------------------------------------------");
        $display("             STATUS INFORMATION");
        $display("----------------------------------------------");

        $display("STATUS        = 0x%08h", status_o);
        $display("TX OCCUPANCY  = %0d", tx_occupancy_o);
        $display("RX OCCUPANCY  = %0d", rx_occupancy_o);

        // --------------------------------------------------------
        // FINAL RESULT
        // --------------------------------------------------------
        $display("");
        $display("==============================================");

        if (errors == 0) begin

            $display("              TEST PASSED");

        end
        else begin

            $display("              TEST FAILED");
            $display("              ERRORS = %0d",
                     errors);

        end

        $display("==============================================");
        $display("");

        #50;

        $finish;

    end

endmodule

`default_nettype wire
