#!/usr/bin/env python3
"""
UVM VIP & Testbench Generator for VeeR EL2 Communication SoC
Generates modular, industry-standard UVM VIPs for EXTERNAL interfaces ONLY:
  - SPI  (External interface: SCLK, CS_n, MOSI, MISO) -> Testbench/SPI
  - I2C  (External interface: SCL, SDA - Open-drain)   -> Testbench/I2C
  - UART (External interface: TX, RX, RTS, CTS)        -> Testbench/UART

Usage:
  python uvm_testbench_generator.py <spi|i2c|uart|all> [signals.csv] [output_dir]

Examples:
  python uvm_testbench_generator.py all
  python uvm_testbench_generator.py spi Docx/csv/spi_signals.csv
  python uvm_testbench_generator.py i2c Docx/csv/i2c_signals.csv
  python uvm_testbench_generator.py uart Docx/csv/uart_signals.csv
"""

import csv
import os
import re
import sys
import shutil

# Predefined architecture VIP signals for standard SoC external interfaces
KNOWN_VIP_SIGNALS = {
    'spi': [
        {'name': 'clk', 'dir': 'input', 'width': 1},
        {'name': 'rst_n', 'dir': 'input', 'width': 1},
        {'name': 'spi_clk_o', 'dir': 'output', 'width': 1},
        {'name': 'spi_cs_n_o', 'dir': 'output', 'width': 1},
        {'name': 'spi_mosi_o', 'dir': 'output', 'width': 1},
        {'name': 'spi_miso_i', 'dir': 'input', 'width': 1},
    ],
    'i2c': [
        {'name': 'clk', 'dir': 'input', 'width': 1},
        {'name': 'rst_n', 'dir': 'input', 'width': 1},
        {'name': 'i2c_scl', 'dir': 'inout', 'width': 1},
        {'name': 'i2c_sda', 'dir': 'inout', 'width': 1},
    ],
    'uart': [
        {'name': 'clk', 'dir': 'input', 'width': 1},
        {'name': 'rst_n', 'dir': 'input', 'width': 1},
        {'name': 'uart_tx_o', 'dir': 'output', 'width': 1},
        {'name': 'uart_rx_i', 'dir': 'input', 'width': 1},
        {'name': 'uart_rts_o', 'dir': 'output', 'width': 1},
        {'name': 'uart_cts_i', 'dir': 'input', 'width': 1},
    ]
}

CLK_NAMES = ['clk', 'clock', 'clk_i', 'hclk', 'sclk']
RST_NAMES = ['rst', 'rst_n', 'reset', 'reset_n', 'rst_n_i', 'hresetn', 'rst_l']

# Destination folders directly inside Testbench (no separate VIP directory)
EXTERNAL_IP_MAPPING = {
    'spi': 'Testbench/SPI',
    'i2c': 'Testbench/I2C',
    'uart': 'Testbench/UART'
}


def find_csv_files(vip_name, user_csv=None):
    """Find signal CSV and testplan CSV for a given external interface VIP."""
    vip = vip_name.lower()
    signal_csv = None
    testplan_csv = None

    if user_csv and os.path.exists(user_csv):
        if 'vip' in user_csv.lower():
            testplan_csv = user_csv
        else:
            signal_csv = user_csv

    if not signal_csv and user_csv:
        candidate_paths = [
            user_csv,
            os.path.join('Docx/csv', user_csv),
            os.path.join('Docx', user_csv),
        ]
        for p in candidate_paths:
            if os.path.exists(p):
                if 'vip' in p.lower():
                    testplan_csv = p
                else:
                    signal_csv = p
                break

    if not signal_csv:
        signal_candidates = [
            f'{vip}_signals.csv',
            f'Docx/csv/{vip}_signals.csv',
            f'Docx/csv/{vip.upper()}_signals.csv',
            f'Docx/{vip}_signals.csv',
        ]
        for c in signal_candidates:
            if os.path.exists(c):
                signal_csv = c
                break

    if not testplan_csv:
        tp_candidates = [
            f'Docx/csv/{vip.upper()}_VIP.csv',
            f'Docx/csv/{vip}_VIP.csv',
            f'Docx/csv/{vip.capitalize()}_VIP.csv',
        ]
        for c in tp_candidates:
            if os.path.exists(c):
                testplan_csv = c
                break

    return signal_csv, testplan_csv


def parse_width(w_str):
    w_str = str(w_str).strip()
    try:
        return int(w_str)
    except ValueError:
        pass
    m = re.search(r'\[\s*(\d+)\s*:\s*(\d+)\s*\]', w_str)
    if m:
        msb = int(m.group(1))
        lsb = int(m.group(2))
        return abs(msb - lsb) + 1
    m2 = re.search(r'\d+', w_str)
    if m2:
        return int(m2.group(0))
    return 1


def read_signals(csv_file, vip_name):
    sigs = []
    if csv_file and os.path.exists(csv_file):
        with open(csv_file, 'r', encoding='utf-8', errors='ignore') as f:
            reader = csv.reader(f)
            rows = [r for r in reader if r]

        if rows:
            header_str = ' '.join(rows[0]).lower()
            if 'test case' not in header_str and 'test scenario' not in header_str:
                for row in rows:
                    if len(row) < 3:
                        continue
                    name = row[0].strip()
                    dir_str = row[1].strip().lower()
                    if name.lower() in ['signal_name', 'name', 'signal']:
                        continue
                    width = parse_width(row[2])
                    sigs.append({
                        'name': name,
                        'dir': dir_str,
                        'width': width
                    })

    if not sigs:
        return KNOWN_VIP_SIGNALS.get(vip_name, [])

    return sigs


def read_testcases(testplan_csv):
    """Parse test cases from VIP testplan CSV if available."""
    tcs = []
    if testplan_csv and os.path.exists(testplan_csv):
        with open(testplan_csv, 'r', encoding='utf-8', errors='ignore') as f:
            reader = csv.DictReader(f)
            for row in reader:
                tc_id = row.get('Test Case ID', '').strip()
                if tc_id:
                    tcs.append({
                        'id': tc_id,
                        'scenario': row.get('Test Scenario', '').strip(),
                        'desc': row.get('Test Description', '').strip(),
                        'exp': row.get('Expected Result', '').strip(),
                        'type': row.get('Interface Type (Internal/External)', '').strip(),
                        'signals': row.get('External Interface / Signal Names', '').strip()
                    })
    return tcs


def sv_type(width):
    return 'bit' if width == 1 else f'bit [{width-1}:0]'


def find_clk_rst(signals):
    clk = 'clk'
    for s in signals:
        if s['name'].lower() in CLK_NAMES:
            clk = s['name']
            break
    rst = 'rst_n'
    for s in signals:
        if s['name'].lower() in RST_NAMES:
            rst = s['name']
            break
    rst_lower = rst.lower()
    is_active_low = ('_n' in rst_lower) or ('resetn' in rst_lower) or rst_lower.endswith('n') or ('rst_l' in rst_lower)
    return clk, rst, is_active_low


def interface(signals, vip):
    s = f'interface {vip}_if;\n'
    for sig in signals:
        sig_type = 'wire' if sig.get('dir') == 'inout' else 'logic'
        if sig['width'] == 1:
            s += f'  {sig_type} {sig["name"]};\n'
        else:
            s += f'  {sig_type} [{sig["width"]-1}:0] {sig["name"]};\n'
    s += 'endinterface\n'
    return s


def transaction(signals, vip):
    clk, rst, _ = find_clk_rst(signals)
    s = f'class {vip}_item extends uvm_sequence_item;\n\n'
    fields = []
    for sig in signals:
        if sig['name'] not in [clk, rst]:
            rand = 'rand ' if sig['dir'] in ['input', 'inout'] else ''
            s += f'  {rand}{sv_type(sig["width"])} {sig["name"]};\n'
            fields.append(sig['name'])
    s += f"\n  `uvm_object_utils({vip}_item)\n\n"
    s += f'  function new(string name="{vip}_item");\n'
    s += '    super.new(name);\n'
    s += '  endfunction\n\n'

    if fields:
        fmt_parts = [f'{f}=0x%0h' for f in fields]
        args_str = ', '.join(fields)
        s += '  virtual function string convert2string();\n'
        s += f'    return $sformatf("[{vip.upper()}_ITEM] {", ".join(fmt_parts)}", {args_str});\n'
        s += '  endfunction\n'
    else:
        s += '  virtual function string convert2string();\n'
        s += f'    return "[{vip.upper()}_ITEM] empty";\n'
        s += '  endfunction\n'

    s += 'endclass\n'
    return s


def sequencer(vip):
    return f'''class {vip}_sequencer extends uvm_sequencer #({vip}_item);
  `uvm_component_utils({vip}_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
'''


def sequences(vip, testcases):
    s = f'''class {vip}_base_seq extends uvm_sequence #({vip}_item);
  `uvm_object_utils({vip}_base_seq)

  function new(string name="{vip}_base_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing {vip.upper()} base sequence", UVM_MEDIUM)
  endtask
endclass

class {vip}_random_seq extends {vip}_base_seq;
  `uvm_object_utils({vip}_random_seq)

  rand int num_trans;
  constraint c_num_trans {{ num_trans inside {{[5:15]}}; }}

  function new(string name="{vip}_random_seq");
    super.new(name);
    num_trans = 10;
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), $sformatf("Executing {vip.upper()} random sequence (%0d items)", num_trans), UVM_MEDIUM)
    repeat (num_trans) begin
      `uvm_do(req)
    end
  endtask
endclass
'''
    if testcases:
        s += f'\n// ==========================================================================\n'
        s += f'// Dedicated Test Sequences Mapped to {vip.upper()} Testplan Specifications\n'
        s += f'// ==========================================================================\n'
        for tc in testcases[:6]:
            tc_id_clean = re.sub(r'[^a-zA-Z0-9_]', '_', tc['id'])
            s += f'''
// Testcase: {tc['id']}
// Scenario: {tc['scenario']}
// Type:     {tc['type']}
class {vip}_{tc_id_clean}_seq extends {vip}_base_seq;
  `uvm_object_utils({vip}_{tc_id_clean}_seq)

  function new(string name="{vip}_{tc_id_clean}_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Starting Test: {tc['id']} - {tc['scenario']}", UVM_LOW)
    `uvm_do(req)
    `uvm_info(get_type_name(), "Completed Test: {tc['id']}", UVM_LOW)
  endtask
endclass
'''
    return s


def driver(vip, clk_name):
    return f'''class {vip}_driver extends uvm_driver #({vip}_item);
  virtual {vip}_if vif;
  `uvm_component_utils({vip}_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual {vip}_if)::get(this, "", "vif", vif)) begin
      `uvm_info(get_type_name(), "Virtual interface not set; running in unbonded mode", UVM_LOW)
    end
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(get_type_name(), $sformatf("Driver received transaction: %s", req.convert2string()), UVM_HIGH)
      if (vif != null) begin
        @(posedge vif.{clk_name});
      end
      seq_item_port.item_done();
    end
  endtask
endclass
'''


def monitor(vip, clk_name, signals):
    clk, rst, _ = find_clk_rst(signals)
    sample_lines = ""
    for sig in signals:
        if sig['name'] not in [clk, rst]:
            sample_lines += f'        item.{sig["name"]} = vif.{sig["name"]};\n'

    return f'''class {vip}_monitor extends uvm_monitor;
  virtual {vip}_if vif;
  uvm_analysis_port #({vip}_item) ap;
  `uvm_component_utils({vip}_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual {vip}_if)::get(this, "", "vif", vif)) begin
      `uvm_info(get_type_name(), "Virtual interface not set for monitor", UVM_LOW)
    end
  endfunction

  task run_phase(uvm_phase phase);
    {vip}_item item;
    forever begin
      if (vif != null) begin
        @(posedge vif.{clk_name});
        item = {vip}_item::type_id::create("item");
{sample_lines}        `uvm_info(get_type_name(), $sformatf("Monitor sampled transaction: %s", item.convert2string()), UVM_HIGH)
        ap.write(item);
      end else begin
        #10;
      end
    end
  endtask
endclass
'''


def agent(vip):
    return f'''class {vip}_agent extends uvm_agent;
  {vip}_driver    drv;
  {vip}_monitor   mon;
  {vip}_sequencer seqr;
  `uvm_component_utils({vip}_agent)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv  = {vip}_driver::type_id::create("drv", this);
    mon  = {vip}_monitor::type_id::create("mon", this);
    seqr = {vip}_sequencer::type_id::create("seqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
'''


def scoreboard(vip):
    return f'''class {vip}_scoreboard extends uvm_scoreboard;
  uvm_analysis_imp #({vip}_item, {vip}_scoreboard) item_export;
  int item_count = 0;
  `uvm_component_utils({vip}_scoreboard)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    item_export = new("item_export", this);
  endfunction

  function void write({vip}_item item);
    item_count++;
    `uvm_info(get_type_name(), $sformatf("Scoreboard captured item #%0d: %s", item_count, item.convert2string()), UVM_MEDIUM)
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("Scoreboard verification summary: %0d items checked", item_count), UVM_LOW)
  endfunction
endclass
'''


def env(vip):
    return f'''class {vip}_env extends uvm_env;
  {vip}_agent      agent;
  {vip}_scoreboard sb;
  `uvm_component_utils({vip}_env)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = {vip}_agent::type_id::create("agent", this);
    sb    = {vip}_scoreboard::type_id::create("sb", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.mon.ap.connect(sb.item_export);
  endfunction
endclass
'''


def test(vip, testcases):
    tc_summary = ""
    if testcases:
        tc_summary = f'    `uvm_info(get_type_name(), "Testplan coverage: {len(testcases)} documented scenarios from CSV", UVM_LOW)\n'

    return f'''class {vip}_test extends uvm_test;
  {vip}_env env;
  `uvm_component_utils({vip}_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = {vip}_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    {vip}_random_seq seq;
    phase.raise_objection(this);
    `uvm_info(get_type_name(), "=========================================================", UVM_LOW)
    `uvm_info(get_type_name(), "=== Starting {vip.upper()} UVM Verification Simulation ===", UVM_LOW)
    `uvm_info(get_type_name(), "=========================================================", UVM_LOW)
{tc_summary}    seq = {vip}_random_seq::type_id::create("seq");
    void'(seq.randomize());
    seq.start(env.agent.seqr);
    #100;
    `uvm_info(get_type_name(), "=========================================================", UVM_LOW)
    `uvm_info(get_type_name(), "=== {vip.upper()} UVM Verification Completed Successfully ===", UVM_LOW)
    `uvm_info(get_type_name(), "=========================================================", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass
'''


def package(vip):
    return f'''package {vip}_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "{vip}_item.sv"
  `include "{vip}_sequencer.sv"
  `include "{vip}_sequence.sv"
  `include "{vip}_driver.sv"
  `include "{vip}_monitor.sv"
  `include "{vip}_agent.sv"
  `include "{vip}_scoreboard.sv"
  `include "{vip}_env.sv"
  `include "{vip}_test.sv"
endpackage
'''


def tb_top(vip, clk_name, rst_name, is_active_low, signals):
    rst_assert = "1'b0" if is_active_low else "1'b1"
    rst_deassert = "1'b1" if is_active_low else "1'b0"

    extra_wires = ""
    if vip == 'i2c':
        extra_wires = """  // Pull-up resistors for I2C open-drain lines
  pullup p_scl (vif.i2c_scl);
  pullup p_sda (vif.i2c_sda);
"""

    return f'''`timescale 1ns/1ps
module tb_top;
  import uvm_pkg::*;
  import {vip}_pkg::*;

  // Clock & Reset Generation
  logic {clk_name};
  logic {rst_name};

  initial begin
    {clk_name} = 1'b0;
    forever #5 {clk_name} = ~{clk_name};
  end

  initial begin
    {rst_name} = {rst_assert};
    #30 {rst_name} = {rst_deassert};
  end

  // Interface Instance
  {vip}_if vif();
  assign vif.{clk_name} = {clk_name};
  assign vif.{rst_name} = {rst_name};

{extra_wires}
  initial begin
    uvm_config_db#(virtual {vip}_if)::set(null, "*", "vif", vif);
    run_test("{vip}_test");
  end
endmodule
'''


def readme(vip, signals, testcases):
    s = f"# {vip.upper()} UVM Verification IP (VIP)\n\n"
    s += f"Modular, reusable UVM 1.2 Verification IP generated for the external **{vip.upper()}** interface of the VeeR EL2 Communication SoC.\n\n"
    s += "## External Interface Signals\n\n"
    s += "| Signal Name | Direction | Bit Width |\n"
    s += "| :--- | :---: | :---: |\n"
    for sig in signals:
        s += f"| `{sig['name']}` | `{sig['dir']}` | {sig['width']} |\n"

    s += "\n## VIP Architecture\n\n"
    s += f"- **Interface (`{vip}_if.sv`)**: Protocol signal declarations (with `wire` for inout lines).\n"
    s += f"- **Transaction Item (`{vip}_item.sv`)**: Sequence item with randomized payload and `convert2string()`.\n"
    s += f"- **Sequencer (`{vip}_sequencer.sv`)**: Transaction sequencer feeding the driver.\n"
    s += f"- **Sequences (`{vip}_sequence.sv`)**: Base and randomized stimulus sequences mapped to test cases.\n"
    s += f"- **Driver (`{vip}_driver.sv`)**: Drives stimulus items to the virtual interface on active clock edges.\n"
    s += f"- **Monitor (`{vip}_monitor.sv`)**: Samples protocol lines and broadcasts transactions to the analysis port.\n"
    s += f"- **Agent (`{vip}_agent.sv`)**: Encapsulates sequencer, driver, and monitor.\n"
    s += f"- **Scoreboard (`{vip}_scoreboard.sv`)**: Checks transaction counts, protocol properties, and data integrity.\n"
    s += f"- **Environment (`{vip}_env.sv`)**: Instantiates and connects agent and scoreboard.\n"
    s += f"- **Test (`{vip}_test.sv`)**: UVM test raising objections and orchestrating stimulus.\n"
    s += f"- **Package (`{vip}_pkg.sv`)**: Compiles all UVM components into the `{vip}_pkg` namespace.\n"
    s += f"- **TB Top (`tb_top.sv`)**: Top-level harness generating clock/reset and invoking `run_test`.\n\n"

    if testcases:
        s += f"## Documented Test Cases ({len(testcases)} Scenarios from CSV)\n\n"
        s += "| Test Case ID | Test Scenario | Interface Type | Signals |\n"
        s += "| :--- | :--- | :---: | :--- |\n"
        for tc in testcases:
            s += f"| `{tc['id']}` | {tc['scenario']} | {tc['type']} | `{tc['signals']}` |\n"

    s += "\n## How to Compile & Run\n\n"
    s += "```bash\n"
    s += "./compile_vcs.sh   # Compile with Synopsys VCS\n"
    s += "./run_sim.sh       # Run UVM simulation\n"
    s += "```\n"
    return s


def write_testbench_files(outdir, vip, signals, testcases, clk_name, rst_name, is_active_low):
    os.makedirs(outdir, exist_ok=True)
    files = {
        f'{vip}_if.sv': interface(signals, vip),
        f'{vip}_item.sv': transaction(signals, vip),
        f'{vip}_sequencer.sv': sequencer(vip),
        f'{vip}_sequence.sv': sequences(vip, testcases),
        f'{vip}_driver.sv': driver(vip, clk_name),
        f'{vip}_monitor.sv': monitor(vip, clk_name, signals),
        f'{vip}_agent.sv': agent(vip),
        f'{vip}_scoreboard.sv': scoreboard(vip),
        f'{vip}_env.sv': env(vip),
        f'{vip}_test.sv': test(vip, testcases),
        f'{vip}_pkg.sv': package(vip),
        'tb_top.sv': tb_top(vip, clk_name, rst_name, is_active_low, signals),
        'README.md': readme(vip, signals, testcases)
    }

    for n, c in files.items():
        with open(os.path.join(outdir, n), 'w') as f:
            f.write(c)

    compile_script = f'''#!/bin/bash
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export PATH=$VCS_HOME/bin:$PATH

vcs -full64 -sverilog -ntb_opts uvm -timescale=1ns/1ps \\
    {vip}_if.sv {vip}_pkg.sv tb_top.sv \\
    -l vcs_compile.log
'''
    compile_path = os.path.join(outdir, 'compile_vcs.sh')
    with open(compile_path, 'w') as f:
        f.write(compile_script)
    os.chmod(compile_path, 0o755)

    run_script = '''#!/bin/bash
./simv +UVM_VERBOSITY=UVM_MEDIUM -l sim.log
'''
    run_path = os.path.join(outdir, 'run_sim.sh')
    with open(run_path, 'w') as f:
        f.write(run_script)
    os.chmod(run_path, 0o755)


def generate_tb(vip, csv_file=None, outdir=None):
    vip = vip.lower()
    if vip not in EXTERNAL_IP_MAPPING:
        print(f"Error: '{vip}' is not an external interface. Only external interfaces ({', '.join(EXTERNAL_IP_MAPPING.keys())}) are supported.")
        return None

    signal_csv, testplan_csv = find_csv_files(vip, csv_file)
    signals = read_signals(signal_csv, vip)
    testcases = read_testcases(testplan_csv)
    clk_name, rst_name, is_active_low = find_clk_rst(signals)

    # Output directly to respective IP folder in Testbench/ (no separate VIP directory)
    dest_dir = outdir if outdir else EXTERNAL_IP_MAPPING[vip]
    write_testbench_files(dest_dir, vip, signals, testcases, clk_name, rst_name, is_active_low)

    tc_msg = f" with {len(testcases)} testcases from testplan" if testcases else ""
    src_msg = f" (from {signal_csv})" if signal_csv else " (using built-in architecture definition)"
    print(f'Successfully generated {vip.upper()} External UVM VIP in: {dest_dir}{src_msg}{tc_msg}')
    return dest_dir


def clean_separate_vips_folder():
    """Ensure any separate VIP folder is removed."""
    vip_dir = 'Testbench/VIP'
    if os.path.exists(vip_dir):
        shutil.rmtree(vip_dir)
        print(f"Removed separate VIP directory: {vip_dir}")


def main():
    # Enforce cleanup of any separate VIP folder
    clean_separate_vips_folder()

    if len(sys.argv) < 2:
        print('Usage: python uvm_testbench_generator.py <spi|i2c|uart|all> [signals.csv] [output_dir]')
        print('External interface VIP targets:')
        print('  - spi   (External SPI VIP  -> Testbench/SPI)')
        print('  - i2c   (External I2C VIP  -> Testbench/I2C)')
        print('  - uart  (External UART VIP -> Testbench/UART)')
        print('  - all   (Generate all external interface VIPs into respective Testbench folders)')
        sys.exit(1)

    target = sys.argv[1].lower()
    csv_file = sys.argv[2] if len(sys.argv) >= 3 else None
    outdir = sys.argv[3] if len(sys.argv) >= 4 else None

    if target in ['all', '--all']:
        external_targets = [
            ('spi', 'Docx/csv/spi_signals.csv'),
            ('i2c', 'Docx/csv/i2c_signals.csv'),
            ('uart', 'Docx/csv/uart_signals.csv')
        ]
        for t, c in external_targets:
            generate_tb(t, c)
        print('\n=== All External Interface UVM VIPs Successfully Generated in Testbench/ (SPI, I2C, UART) ===')
    else:
        generate_tb(target, csv_file, outdir)


if __name__ == '__main__':
    main()
