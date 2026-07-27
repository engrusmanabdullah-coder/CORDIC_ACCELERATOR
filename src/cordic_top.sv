`timescale 1ns/1ps

import cordic_pkg::*;

module cordic_top
(
    input  logic   clk,
    input  logic   rst,

    input  logic   start,
    input  fixed_t angle_in,

    output fixed_t cos_out,
    output fixed_t sin_out,
    output logic   done
);

    //----------------------------------------------------------
    // Internal Signals
    //----------------------------------------------------------

    logic load;
    logic iterate;

    logic z_sign;
    logic iter_done;

    fixed_t angle_mapped;
    fixed_t raw_cos, raw_sin;
    logic   negate_output;

    //----------------------------------------------------------
    // 1. Pre-Processing: Quadrant Mapping (Combinational)
    // Maps angles outside [-90°, +90°] into Quadrants I & IV
    // Toggling MSB (^ 16'h8000) adds/subtracts 180° in Q1.15
    //----------------------------------------------------------
    always_comb begin
        if (angle_in > ANGLE_90 || angle_in < -ANGLE_90) begin
            angle_mapped = angle_in ^ 16'h8000; // Shift by 180°
        end else begin
            angle_mapped = angle_in;            // Keep as-is
        end
    end

    //----------------------------------------------------------
    // 2. Register: Remember if output signs need inversion
    //----------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            negate_output <= 1'b0;
        end else if (start) begin
            negate_output <= (angle_in > ANGLE_90) || (angle_in < -ANGLE_90);
        end
    end

    //----------------------------------------------------------
    // Controller
    //----------------------------------------------------------

    cordic_controller u_controller
    (
        .clk        (clk),
        .rst        (rst),

        .start      (start),
        .iter_done  (iter_done),

        .load       (load),
        .iterate    (iterate),
        .done       (done)
    );

    //----------------------------------------------------------
    // Datapath
    //----------------------------------------------------------

    cordic_datapath u_datapath
    (
        .clk        (clk),
        .rst        (rst),

        .load       (load),
        .iterate    (iterate),

        .angle_in   (angle_mapped),

        .z_sign     (z_sign),
        .iter_done  (iter_done),

        .cos_out    (raw_cos),
        .sin_out    (raw_sin)
    );

    //----------------------------------------------------------
    // 3. Post-Processing: Sign Correction
    //----------------------------------------------------------
    always_comb begin
        if (negate_output) begin
            cos_out = -raw_cos;
            sin_out = -raw_sin;
        end else begin
            cos_out = raw_cos;
            sin_out = raw_sin;
        end
    end

endmodule
