# AXI4 Memory Interface UVM Verification Environment

[![Language](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)](https://en.wikipedia.org/wiki/SystemVerilog)
[![Methodology](https://img.shields.io/badge/Methodology-UVM--1.2-green.svg)](https://www.accellera.org/)
[![Tool](https://img.shields.io/badge/Simulator-QuestaSim-red.svg)](https://sw.siemens.com/)

A robust, object-oriented UVM 1.2 verification testbench designed to validate an AXI4 memory controller interface. The testbench implements a constrained-random test generation strategy, self-checking scoreboard architecture, SVA assertions, and coverage-driven verification reaching **~98% functional cross-coverage**.

---

## Architecture Overview

```text
                               +-------------------------------------------------------+
                               |                 UVM Testbench Top                     |
                               |                   (axi_tb_top)                        |
                               +-------------------------------------------------------+
                                                           |
                                                           v
                               +-------------------------------------------------------+
                               |                      UVM Test                         |
                               |                   (random_test)                       |
                               +-------------------------------------------------------+
                                                           |
                                                           v
                               +-------------------------------------------------------+
                               |                    UVM Environment                    |
                               |                       (axi_env)                       |
                               +-------------------------------------------------------+
                                   |                       |                       |
            +----------------------+                       |                       +----------------------+
            |                                              v                                              |
            v                               +------------------------------+                              v
+-----------------------+                   |        UVM Scoreboard        |                   +-----------------------+
|   Master UVM Agent    |                   |       (axi_scoreboard)       |                   |    Slave UVM Agent    |
|    (master_agent)     |                   +------------------------------+                   |     (slave_agent)     |
+-----------------------+                            ^          ^                              +-----------------------+
| - Sequencer (seqr)    |                            |          |                              | - Driver (slave_drv)  |
| - Driver (master_drv) |                            |          |                              | - Monitor (slave_mon) |
| - Monitor (master_mon)|----+                       |          |                       +------| - Config (slave_cfg)  |
| - Config (master_cfg) |    |                       |          |                       |      +-----------------------+
+-----------------------+    |                       |          |                       |
                             |                       |          |                       |
                             v                       |          |                       v
                +------------------------+           |          |           +------------------------+
                | Master Analysis Port   |-----------+          +-----------|  Slave Analysis Port   |
                +------------------------+                                  +------------------------+
                             |                                                          |
                             +---------------------------+  +---------------------------+
                                                         |  |
                                                         v  v
                                            +----------------------------+
                                            |   Coverage Collector       |
                                            |  (read_cg & write_cg)      |
                                            +----------------------------+
                                                         |
                                                         v
                                            +----------------------------+
                                            |    AXI SystemVerilog       |
                                            |   Virtual Interface (vif)  |
                                            +----------------------------+
                                                         |
                                                         v
                                            +----------------------------+
                                            |      AXI Memory DUT        |
                                            +----------------------------+
