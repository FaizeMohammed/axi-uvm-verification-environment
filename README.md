# AXI3 Verification IP (VIP) using SystemVerilog and UVM

[![Language](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)](https://en.wikipedia.org/wiki/SystemVerilog)
[![Methodology](https://img.shields.io/badge/Methodology-UVM--1.2-green.svg)](https://www.accellera.org/)
[![Simulator](https://img.shields.io/badge/Simulator-QuestaSim-red.svg)](https://eda.sw.siemens.com/)

A UVM 1.2-based AXI3 Verification IP project featuring active master and slave agents, directed and constrained-random burst sequences, transaction monitoring, a slave-side associative memory model, scoreboard comparison, and functional coverage.

This is a self-contained VIP testbench: the master VIP generates AXI transactions and the slave VIP responds using a behavioral memory model. **There is no separate RTL memory-controller DUT in this repository.**

---

## Project Overview

The objective is to develop and exercise reusable UVM components for AXI3-style memory-mapped read and write transactions.

### Implemented interface configuration

| Parameter | Implemented width / range |
|---|---:|
| Address | 32 bits |
| Data | 32 bits |
| Transaction ID | 4 bits |
| Burst length (`AWLEN`, `ARLEN`) | 4 bits; 1–16 transfers |
| Transfer size (`AWSIZE`, `ARSIZE`) | 3-bit fields; constrained to 0, 1 and 2 |
| Write strobe (`WSTRB`) | 4 bits |
| Burst types | FIXED, INCR and WRAP |

The interface includes the five AXI channels:

- **Write address:** AW
- **Write data:** W (including `WID`)
- **Write response:** B
- **Read address:** AR
- **Read data:** R

The presence of `WID` and the 4-bit burst-length fields reflects the AXI3 interface targeted by this project.

## UVM Architecture

```text
                         +----------------------+
                         |       UVM Test       |
                         | fixed / incr / wrap  |
                         |      / random        |
                         +----------+-----------+
                                    |
                         +----------v-----------+
                         |       axi_env        |
                         +----------+-----------+
                                    |
                +-------------------+-------------------+
                |                                       |
      +---------v----------+                 +----------v---------+
      |   Master VIP Agent |                 |   Slave VIP Agent   |
      |  Sequencer         |                 |  Sequencer          |
      |  Driver            |                 |  Driver             |
      |  Monitor           |                 |  Monitor            |
      +---------+----------+                 +----------+----------+
                |                                       |
                +-------------------+-------------------+
                                    |
                              +-----v-----+
                              |  axi_if   |
                              | AXI3 bus  |
                              +-----------+
                                    |
                         +----------v-----------+
                         | Slave driver memory  |
                         | associative model    |
                         +----------------------+

        Master monitor ------------------+
                                         |
                                         v
                                  +-------------+
        Slave monitor ---------> |  axi_sb     |
                                  | transaction |
                                  | comparison  |
                                  | & coverage  |
                                  +-------------+
```

### Main components

| Component | Responsibility |
|---|---|
| `master_agent_top` | Instantiates and configures the master agent |
| `master_agent` | Groups the master sequencer, driver and monitor |
| `master_driver` | Drives write/read address and data requests and handles response handshakes |
| `master_monitor` | Observes bus activity and publishes transactions through an analysis port |
| `slave_agent_top` | Instantiates and configures the slave agent |
| `slave_agent` | Groups the slave sequencer, driver and monitor |
| `slave_driver` | Responds to master requests and models memory behavior using an associative array |
| `slave_monitor` | Observes slave-side bus activity and publishes transactions |
| `axi_env` | Instantiates both agents and the scoreboard, and connects monitor analysis ports to scoreboard FIFOs |
| `axi_sb` | Receives monitored transactions, compares master-side and slave-side observations, and samples functional coverage |

## AXI3 Transaction Features

### Burst types

| Burst | Encoding | Description |
|---|---|---|
| FIXED | `2'b00` | Address remains fixed for each transfer |
| INCR | `2'b01` | Address increments between transfers |
| WRAP | `2'b10` | Address wraps within the configured wrap boundary |

### Constrained-random transaction fields

The transaction class (`axi_trans`) randomizes addresses, burst types, burst lengths, transfer sizes, IDs and data arrays. The current constraints include:

- Burst lengths from 1 to 16 transfers.
- WRAP burst lengths restricted to 2, 4, 8 or 16 transfers.
- Transfer sizes restricted to 1, 2 or 4 bytes (`SIZE` values 0, 1 and 2).
- Address values constrained to the 0–4095 range.
- Alignment constraints for FIXED and WRAP transfers with 2-byte and 4-byte transfer sizes.
- Burst types distributed across FIXED, INCR and WRAP.
- Write-data and read-data array sizes derived from the corresponding burst length.

The implementation is a project-specific AXI3 VIP subset; refer to the source constraints for the exact stimulus space exercised.

## Sequences and Test Scenarios

| UVM test | Sequence | Purpose |
|---|---|---|
| `fixed_test` | `fixed_burst_seq` | Generates FIXED burst transactions |
| `incr_test` | `increment_burst_seq` | Generates INCR burst transactions |
| `wrap_test` | `wrap_burst_seq` | Generates WRAP burst transactions |
| `random_test` | `master_seq_random` | Runs randomized transactions, burst-mode stress and selected short-burst/transfer-size cases |
| `test` | — | Base test / environment setup |

The directed sequences each generate five randomized transactions constrained to their respective burst type. The random sequence includes a 40-transaction unconstrained-random phase, burst-specific stress phases, and additional short-burst cases.

## Scoreboard and Memory Model

The slave driver contains an associative-array memory model used to provide memory-like write and read responses.

The scoreboard (`tb/axi_sb.sv`) receives transactions from the master and slave monitors through UVM analysis FIFOs. It compares the two observed transaction objects using the transaction class comparison method. Successful comparisons are reported, and the corresponding read/write coverage is sampled.

**Scope note:** the current scoreboard compares the two monitor observations; it is not an independent reference-model predictor that separately calculates expected read data. The associative memory behavior is implemented in the slave driver.

## Functional Coverage

Functional coverage is implemented in `axi_sb.sv` using read and write covergroups.

Coverage includes:

- Read and write burst type.
- Read and write transfer size.
- Read and write burst length.
- Read and write address ranges.
- Write response.
- Read response.
- Selected write-strobe patterns.
- Cross coverage of burst type × transfer size × burst length for read and write address transactions.

**Regression result:** approximately **98% aggregate functional coverage** was observed in the merged QuestaSim regression coverage report during project verification. Include the generated HTML report or a concise exported coverage summary in the repository so reviewers can inspect the result and uncovered bins.

Protocol SVA assertions are not included in the current checked-in revision; assertion development and validation are planned as the next extension.

## Simulation Results

The project regression includes the following tests:

| Test | Make target | UVM test |
|---|---|---|
| Base test | `make run_test0` | `test` |
| FIXED burst | `make run_test1` | `fixed_test` |
| INCR burst | `make run_test2` | `incr_test` |
| WRAP burst | `make run_test3` | `wrap_test` |
| Random | `make run_test4` | `random_test` |

The reported regression completed with the tests passing and approximately 98% aggregate functional coverage. Individual test logs and the merged coverage report are the recommended evidence for reproducing and reviewing these results.

## Repository Structure

```text
.
├── master_agent_top/
│   ├── axi_master_config.sv
│   ├── axi_trans.sv
│   ├── master_agent.sv
│   ├── master_agent_top.sv
│   ├── master_driver.sv
│   ├── master_monitor.sv
│   ├── master_sequence.sv
│   └── master_sequencer.sv
├── rtl/
│   └── axi_if.sv
├── sim/
│   └── makefile
├── slave_agent_top/
│   ├── axi_slave_config.sv
│   ├── slave_agent.sv
│   ├── slave_agent_top.sv
│   ├── slave_driver.sv
│   ├── slave_monitor.sv
│   ├── slave_sequence.sv
│   └── slave_sequencer.sv
├── tb/
│   ├── axi_env.sv
│   ├── axi_sb.sv
│   └── env_config.sv
├── test/
│   ├── axi_pkg.sv
│   ├── test.sv
│   └── top.sv
└── README.md
```

## Tools and Prerequisites

- Siemens QuestaSim (the Makefile is configured for Questa).
- SystemVerilog support.
- UVM 1.2 library available in the simulator installation.
- GNU Make.

The checked-in Makefile also contains VCS targets, but the documented and exercised flow for this project is QuestaSim.

## Running the Tests

Clone the repository and enter the simulation directory:

```bash
git clone https://github.com/FaizeMohammed/axi-uvm-verification-environment.git
cd axi-uvm-verification-environment/sim
```

Run an individual test:

```bash
make run_test1   # FIXED burst
make run_test2   # INCR burst
make run_test3   # WRAP burst
make run_test4   # Random test
```

Run the complete regression and generate the merged coverage report:

```bash
make regress
```

The regression target runs the base, FIXED, INCR, WRAP and random tests, merges their coverage databases, and generates an HTML report in:

```text
sim/covhtmlreport/index.html
```

To open the generated report using the Makefile target:

```bash
make cov
```

To generate the merged report separately after running the tests:

```bash
make report
```

---

Coverage Report
<img width="1917" height="505" alt="Screenshot 2026-11-12 135951" src="https://github.com/user-attachments/assets/f0e2c192-65f1-4fdf-914d-128c48acb9b5" />


