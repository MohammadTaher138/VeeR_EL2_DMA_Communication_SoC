//==========================================================================
//  soc_virtual_sequence.sv – Coordinated Multi-VIP Stimulus Sequences
//==========================================================================
//  Coordinates existing SPI, I2C, and UART sequences through their respective
//  sequencers, providing both independent and concurrent multi-protocol operations.
//==========================================================================

`ifndef SOC_VIRTUAL_SEQUENCE_SV
`define SOC_VIRTUAL_SEQUENCE_SV

// --------------------------------------------------------------------------
//  1. Sequential Independent Peripheral Traffic Sequence
// --------------------------------------------------------------------------
class soc_independent_traffic_seq extends soc_base_sequence;
  `uvm_object_utils(soc_independent_traffic_seq)

  spi_random_seq  spi_seq;
  i2c_random_seq  i2c_seq;
  uart_random_seq uart_seq;

  function new(string name = "soc_independent_traffic_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    `uvm_info(get_type_name(), "=== Phase 1: Sequential Independent Peripheral Traffic Test   ===", UVM_LOW)
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)

    // A. SPI Independent Operation
    if (p_sequencer.spi_seqr != null) begin
      `uvm_info(get_type_name(), ">>> Running Independent SPI Sequence <<<", UVM_MEDIUM)
      spi_seq = spi_random_seq::type_id::create("spi_seq");
      void'(spi_seq.randomize());
      spi_seq.start(p_sequencer.spi_seqr);
    end

    #100;

    // B. I2C Independent Operation
    if (p_sequencer.i2c_seqr != null) begin
      `uvm_info(get_type_name(), ">>> Running Independent I2C Sequence <<<", UVM_MEDIUM)
      i2c_seq = i2c_random_seq::type_id::create("i2c_seq");
      void'(i2c_seq.randomize());
      i2c_seq.start(p_sequencer.i2c_seqr);
    end

    #100;

    // C. UART Independent Operation
    if (p_sequencer.uart_seqr != null) begin
      `uvm_info(get_type_name(), ">>> Running Independent UART Sequence <<<", UVM_MEDIUM)
      uart_seq = uart_random_seq::type_id::create("uart_seq");
      void'(uart_seq.randomize());
      uart_seq.start(p_sequencer.uart_seqr);
    end

    `uvm_info(get_type_name(), "=== Completed Sequential Independent Traffic Test ===", UVM_LOW)
  endtask
endclass

// --------------------------------------------------------------------------
//  2. Concurrent Simultaneous Multi-Peripheral Traffic Sequence
// --------------------------------------------------------------------------
class soc_concurrent_traffic_seq extends soc_base_sequence;
  `uvm_object_utils(soc_concurrent_traffic_seq)

  spi_random_seq  spi_seq;
  i2c_random_seq  i2c_seq;
  uart_random_seq uart_seq;

  function new(string name = "soc_concurrent_traffic_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    `uvm_info(get_type_name(), "=== Phase 2: Simultaneous Concurrent Multi-Peripheral Traffic ===", UVM_LOW)
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)

    fork
      begin : spi_branch
        if (p_sequencer.spi_seqr != null) begin
          spi_seq = spi_random_seq::type_id::create("spi_seq");
          void'(spi_seq.randomize());
          spi_seq.start(p_sequencer.spi_seqr);
        end
      end

      begin : i2c_branch
        if (p_sequencer.i2c_seqr != null) begin
          i2c_seq = i2c_random_seq::type_id::create("i2c_seq");
          void'(i2c_seq.randomize());
          i2c_seq.start(p_sequencer.i2c_seqr);
        end
      end

      begin : uart_branch
        if (p_sequencer.uart_seqr != null) begin
          uart_seq = uart_random_seq::type_id::create("uart_seq");
          void'(uart_seq.randomize());
          uart_seq.start(p_sequencer.uart_seqr);
        end
      end
    join

    `uvm_info(get_type_name(), "=== Completed Simultaneous Concurrent Multi-Peripheral Traffic ===", UVM_LOW)
  endtask
endclass

// --------------------------------------------------------------------------
//  3. Full SoC Integration Virtual Sequence (Combines Both Phases)
// --------------------------------------------------------------------------
class soc_full_integration_seq extends soc_base_sequence;
  `uvm_object_utils(soc_full_integration_seq)

  soc_independent_traffic_seq indep_seq;
  soc_concurrent_traffic_seq  concur_seq;

  function new(string name = "soc_full_integration_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    `uvm_info(get_type_name(), "=== Starting Full SoC Integrated Verification Sequence        ===", UVM_LOW)
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)

    // Execute independent verification
    indep_seq = soc_independent_traffic_seq::type_id::create("indep_seq");
    indep_seq.start(p_sequencer);

    #200;

    // Execute concurrent verification
    concur_seq = soc_concurrent_traffic_seq::type_id::create("concur_seq");
    concur_seq.start(p_sequencer);

    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    `uvm_info(get_type_name(), "=== Completed Full SoC Integrated Verification Sequence        ===", UVM_LOW)
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
  endtask
endclass

`endif
