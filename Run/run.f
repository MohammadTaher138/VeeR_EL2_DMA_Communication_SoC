// ==============================================================================
// Simulation Filelist for VeeR EL2 Communication SoC
// Run directory: /home/student/Documents/Taher,152/Soc_Project/Run
// ==============================================================================

// Include Directories
+incdir+../RTL/Cores-VeeR-EL2-main/design/include
+incdir+../RTL/DMA/inc
+incdir+../RTL/DMA
+incdir+../RTL/I2C
+incdir+../RTL/SPI
+incdir+../RTL/UART

// VeeR-EL2 RISC-V Core RTL Sources
../RTL/Cores-VeeR-EL2-main/design/lib/el2_assert.sv
../RTL/Cores-VeeR-EL2-main/design/el2_mubi_pkg.sv
../RTL/Cores-VeeR-EL2-main/design/include/el2_def.sv
../RTL/Cores-VeeR-EL2-main/design/el2_veer_wrapper.sv
../RTL/Cores-VeeR-EL2-main/design/el2_lockstep_pkg.sv
../RTL/Cores-VeeR-EL2-main/design/el2_veer_lockstep.sv
../RTL/Cores-VeeR-EL2-main/design/el2_mem.sv
../RTL/Cores-VeeR-EL2-main/design/el2_pic_ctrl.sv
../RTL/Cores-VeeR-EL2-main/design/el2_veer.sv
../RTL/Cores-VeeR-EL2-main/design/el2_dma_ctrl.sv
../RTL/Cores-VeeR-EL2-main/design/el2_pmp.sv
../RTL/Cores-VeeR-EL2-main/design/ifu/el2_ifu_aln_ctl.sv
../RTL/Cores-VeeR-EL2-main/design/ifu/el2_ifu_compress_ctl.sv
../RTL/Cores-VeeR-EL2-main/design/ifu/el2_ifu_ifc_ctl.sv
../RTL/Cores-VeeR-EL2-main/design/ifu/el2_ifu_bp_ctl.sv
../RTL/Cores-VeeR-EL2-main/design/ifu/el2_ifu_ic_mem.sv
../RTL/Cores-VeeR-EL2-main/design/ifu/el2_ifu_mem_ctl.sv
../RTL/Cores-VeeR-EL2-main/design/ifu/el2_ifu_iccm_mem.sv
../RTL/Cores-VeeR-EL2-main/design/ifu/el2_ifu.sv
../RTL/Cores-VeeR-EL2-main/design/dec/el2_dec_decode_ctl.sv
../RTL/Cores-VeeR-EL2-main/design/dec/el2_dec_gpr_ctl.sv
../RTL/Cores-VeeR-EL2-main/design/dec/el2_dec_ib_ctl.sv
../RTL/Cores-VeeR-EL2-main/design/dec/el2_dec_pmp_ctl.sv
../RTL/Cores-VeeR-EL2-main/design/dec/el2_dec_tlu_ctl.sv
../RTL/Cores-VeeR-EL2-main/design/dec/el2_dec_trigger.sv
../RTL/Cores-VeeR-EL2-main/design/dec/el2_dec.sv
../RTL/Cores-VeeR-EL2-main/design/exu/el2_exu_alu_ctl.sv
../RTL/Cores-VeeR-EL2-main/design/exu/el2_exu_mul_ctl.sv
../RTL/Cores-VeeR-EL2-main/design/exu/el2_exu_div_ctl.sv
../RTL/Cores-VeeR-EL2-main/design/exu/el2_exu.sv
../RTL/Cores-VeeR-EL2-main/design/lsu/el2_lsu.sv
../RTL/Cores-VeeR-EL2-main/design/lsu/el2_lsu_clkdomain.sv
../RTL/Cores-VeeR-EL2-main/design/lsu/el2_lsu_addrcheck.sv
../RTL/Cores-VeeR-EL2-main/design/lsu/el2_lsu_lsc_ctl.sv
../RTL/Cores-VeeR-EL2-main/design/lsu/el2_lsu_stbuf.sv
../RTL/Cores-VeeR-EL2-main/design/lsu/el2_lsu_bus_buffer.sv
../RTL/Cores-VeeR-EL2-main/design/lsu/el2_lsu_bus_intf.sv
../RTL/Cores-VeeR-EL2-main/design/lsu/el2_lsu_ecc.sv
../RTL/Cores-VeeR-EL2-main/design/lsu/el2_lsu_dccm_mem.sv
../RTL/Cores-VeeR-EL2-main/design/lsu/el2_lsu_dccm_ctl.sv
../RTL/Cores-VeeR-EL2-main/design/lsu/el2_lsu_trigger.sv
../RTL/Cores-VeeR-EL2-main/design/dbg/el2_dbg.sv
../RTL/Cores-VeeR-EL2-main/design/dmi/dmi_mux.v
../RTL/Cores-VeeR-EL2-main/design/dmi/dmi_wrapper.v
../RTL/Cores-VeeR-EL2-main/design/dmi/dmi_jtag_to_core_sync.v
../RTL/Cores-VeeR-EL2-main/design/dmi/rvjtag_tap.v
../RTL/Cores-VeeR-EL2-main/design/lib/el2_lib.sv
../RTL/Cores-VeeR-EL2-main/design/lib/el2_mem_if.sv
../RTL/Cores-VeeR-EL2-main/design/lib/el2_prim_generic_buf.sv
../RTL/Cores-VeeR-EL2-main/design/lib/el2_prim_buf.sv
../RTL/Cores-VeeR-EL2-main/design/lib/beh_lib.sv
../RTL/Cores-VeeR-EL2-main/design/lib/mem_lib.sv
../RTL/Cores-VeeR-EL2-main/design/lib/ahb_to_axi4.sv
../RTL/Cores-VeeR-EL2-main/design/lib/axi4_to_ahb.sv

// Interconnect RTL Sources
../RTL/Interconnect/arbiter.v
../RTL/Interconnect/priority_encoder.v
../RTL/Interconnect/axi_interconnect.v
../RTL/Interconnect/axi_interconnect_wrap_2x6.v

// Peripheral IP RTL: SPI Controller
../RTL/SPI/ratio_clk.v
../RTL/SPI/spi_clk_gen.v
../RTL/SPI/spi_ctrl.v
../RTL/SPI/spi_exch_byte.v
../RTL/SPI/spi_fifo.v
../RTL/SPI/spi_valid_logic.v
../RTL/SPI/axi_spi_ctrl.v
../RTL/SPI/axi_spi_top.v

// Peripheral IP RTL: UART Controller
../RTL/UART/axi_internal_fifo.v
../RTL/UART/uart_controller.v
../RTL/UART/uart_parity_bit_compute.v
../RTL/UART/uart_receiver.v
../RTL/UART/uart_transmitter.v
../RTL/UART/axi_uart_top.v

// Peripheral IP RTL: I2C Master Controller
../RTL/I2C/i2c_master_defines.v
../RTL/I2C/i2c_master_bit_ctrl.v
../RTL/I2C/i2c_master_byte_ctrl.v
../RTL/I2C/i2c_master_top.v

// Peripheral IP RTL: AXI DMA Controller
../RTL/DMA/inc/amba_axi_pkg.sv
../RTL/DMA/inc/dma_utils_pkg.sv
../RTL/DMA/rggen_adapter_common.v
../RTL/DMA/rggen_address_decoder.v
../RTL/DMA/rggen_axi4lite_adapter.v
../RTL/DMA/rggen_axi4lite_bridge.v
../RTL/DMA/rggen_axi4lite_skid_buffer.v
../RTL/DMA/rggen_bit_field.v
../RTL/DMA/rggen_bit_field_w01trg.v
../RTL/DMA/rggen_default_register.v
../RTL/DMA/rggen_mux.v
../RTL/DMA/rggen_or_reducer.v
../RTL/DMA/rggen_register_common.v
../RTL/DMA/csr_dma.v
../RTL/DMA/dma_fifo.sv
../RTL/DMA/dma_fsm.sv
../RTL/DMA/dma_streamer.sv
../RTL/DMA/dma_axi_if.sv
../RTL/DMA/dma_func_wrapper.sv
../RTL/DMA/dma_axi_wrapper.sv

// Main SoC Top Module
../RTL/top_veer_soc.sv

// Main SoC Top Testbench
../Testbench/tb_top_veer_soc.sv
