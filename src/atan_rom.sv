`timescale 1ns/1ps

module atan_rom
(
    input  logic [3:0] addr,
    output cordic_pkg::fixed_t atan_value
);

    import cordic_pkg::*;

    assign atan_value = (addr < ITERATIONS) ? ATAN_TABLE[addr] : ZERO;

endmodule
