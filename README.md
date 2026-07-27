# CORDIC Accelerator

> **MEDS Lab – Project**
>
> **Language:** SystemVerilog
>
> **Algorithm:** Iterative CORDIC (Coordinate Rotation Digital Computer)

---

# Overview

This project implements a **16-bit fixed-point CORDIC (Coordinate Rotation Digital Computer) Accelerator** capable of computing **sine** and **cosine** using only:

- Addition
- Subtraction
- Arithmetic shifts
- Lookup table (ROM)

No hardware multipliers or floating-point arithmetic are used, making the design suitable for FPGA and ASIC implementations.

The accelerator is implemented using an **iterative architecture** controlled by a finite state machine (FSM).

---

# Features

- 16-bit Fixed Point (Q1.15)
- Iterative CORDIC Algorithm
- Rotation Mode
- FSM-Based Controller
- Separate Datapath and Controller
- atan Lookup ROM
- Self-checking Verification Environment
- Randomized Test Cases
- Clean Modular Design
- Synthesizable SystemVerilog

---

# CORDIC Algorithm

CORDIC computes trigonometric functions using iterative vector rotations.

For each iteration:

```
if z >= 0

x(i+1) = x(i) - (y(i) >> i)

y(i+1) = y(i) + (x(i) >> i)

z(i+1) = z(i) - atan(2^-i)

else

x(i+1) = x(i) + (y(i) >> i)

y(i+1) = y(i) - (x(i) >> i)

z(i+1) = z(i) + atan(2^-i)
```

After all iterations:

```
x ≈ cos(θ)

y ≈ sin(θ)
```

---

# Architecture

```
                +----------------+
 Angle -------->| Controller FSM |
                +-------+--------+
                        |
              load / iterate
                        |
                        v
                +----------------+
                |   Datapath     |
                |                |
                | X Register     |
                | Y Register     |
                | Z Register     |
                | Shift Logic    |
                | Add/Sub Unit   |
                +-------+--------+
                        |
                  atan ROM
                        |
                        v
              +----------------+
              | atan Lookup    |
              +----------------+

                        |
                        v

              Cosine / Sine Output
```

---

# FSM

```
          +------+
          | IDLE |
          +------+
             |
          start
             |
             v
          +------+
          | LOAD |
          +------+
             |
             v
       +------------+
       | ITERATION  |
       +------------+
             |
     iter_done ?
       /        \
      No        Yes
      |          |
      |          v
      |      +------+
      +------| DONE |
             +------+
                 |
                 v
               IDLE
```

---

# Fixed-Point Format

The design uses **Q1.15** signed fixed-point representation.

```
Width = 16 bits

1 Sign Bit
15 Fractional Bits
```

Examples:

| Decimal | Q1.15 |
|----------|-------|
| 0.0 | 0 |
| 0.5 | 16384 |
| 1.0 | 32767 |
| -1.0 | -32768 |

---

# Project Structure

```
CORDIC_ACCELERATOR/

│
├── design/
│
├── src/
│   ├── cordic_pkg.sv
│   ├── atan_rom.sv
│   ├── cordic_datapath.sv
│   ├── cordic_controller.sv
│   └── cordic_top.sv
│
├── testbench/
│   └── tb_cordic.sv
│
├── driver_code/
│
├── README.md
│
└── Makefile
```

---

# Source Files

## cordic_pkg.sv

Contains

- Global parameters
- Fixed-point typedefs
- atan lookup table
- CORDIC gain constant

---

## atan_rom.sv

Implements the lookup ROM.

Returns

```
atan(2^-iteration)
```

for every iteration.

---

## cordic_datapath.sv

Implements

- X register
- Y register
- Z register
- Shift operations
- Add/Subtract logic
- Iteration counter

---

## cordic_controller.sv

Finite State Machine

States:

- IDLE
- LOAD
- ITERATE
- DONE

Generates:

- load
- iterate
- done

---

## cordic_top.sv

Top-level integration of

- Controller
- Datapath
- ROM

---

# Verification

A professional self-checking testbench was developed.

The testbench performs

- Reset verification
- FSM verification
- Directed testing
- Boundary testing
- Small-angle testing
- Random testing
- Automatic PASS/FAIL reporting

---

# Test Cases

Directed Tests

- 0°
- ±30°
- ±45°
- ±60°
- ±90°
- ±180°

Small Angles

- ±0.1°
- ±0.5°
- ±1°
- ±2.5°

Random Tests

100 random angles across the supported input range.

---

# Simulation Results

```
==========================================
CORDIC Verification Summary
==========================================

Total Tests       : 118

Passed            : 118

Failed            : 0

Maximum Cos Error : 28 LSB

Maximum Sin Error : 28 LSB

Allowed Tolerance : 30 LSB

STATUS: SUCCESS
==========================================
```

---

# Accuracy

The design achieves

- Maximum Cosine Error = 28 LSB
- Maximum Sine Error = 28 LSB

within an allowable tolerance of

```
±30 LSB
```

which is acceptable for a 16-bit iterative CORDIC implementation.

---

# How to Compile

Example using Vivado XSim:

```
xvlog src/*.sv testbench/tb_cordic.sv

xelab tb_cordic -debug typical

xsim tb_cordic -runall
```

---

# Expected Output

```
PASS Angle = 0°

PASS Angle = 30°

PASS Angle = 45°

PASS Angle = 90°

PASS Angle = 180°

...

STATUS: SUCCESS
```

---

# Future Improvements

Possible enhancements include

- Pipelined CORDIC Architecture
- Configurable Iteration Count
- Vectoring Mode
- Hyperbolic CORDIC
- Floating Point Support
- Higher Internal Precision
- AXI4 Interface
- FPGA Implementation
- Synthesis & Timing Analysis

---

# References

1. Ray Andraka, *A Survey of CORDIC Algorithms for FPGA-Based Computers*

2. ZipCPU CORDIC Guide

3. EE Times FPGA CORDIC Tutorial

---

# Author

**Usman Abdullah**

MEDS Lab – Maktab-e-Digital Systems

SystemVerilog | FPGA | Digital Design | Computer Architecture
