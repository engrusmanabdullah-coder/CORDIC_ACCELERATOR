`timescale 1ns/1ps
import cordic_pkg::*;

module cordic_datapath
(
    input  logic clk,
    input  logic rst,
    input  logic load,
    input  logic iterate,
    input  fixed_t angle_in,
    output logic z_sign,
    output logic iter_done,
    output fixed_t cos_out,
    output fixed_t sin_out
);
    //----------------------------------------------------------
    // Internal Registers (extended width, e.g. 18-bit)
    //----------------------------------------------------------
    internal_t x_reg, y_reg, z_reg;
    internal_t x_next, y_next, z_next;
    internal_t x_shift, y_shift;

    localparam ITER_W = $clog2(ITERATIONS);
    logic [ITER_W-1:0] iteration;

    // True once the pipeline has produced a valid, converged result
    // and should stop mutating x_reg/y_reg/z_reg.
    logic done_q;

    //----------------------------------------------------------
    // ROM
    //----------------------------------------------------------
    fixed_t     atan_small;
    internal_t  atan_angle;

    atan_rom ROM
    (
        .addr(iteration),
        .atan_value(atan_small)
    );

    assign atan_angle =
        {{(INTERNAL_WIDTH-DATA_WIDTH){atan_small[DATA_WIDTH-1]}}, atan_small};

    //----------------------------------------------------------
    // Status
    //----------------------------------------------------------
    logic z_is_neg;
    assign z_is_neg = z_reg[INTERNAL_WIDTH-1];
    assign z_sign   = ~z_is_neg;

    assign x_shift = x_reg >>> iteration;
    assign y_shift = y_reg >>> iteration;

    // Only actually advance the math while we're iterating AND not
    // already done -- prevents a lingering/late `iterate` pulse from
    // re-applying the last ROM entry over and over and corrupting the
    // converged x/y/z after iter_done has already fired.
    logic run_iter;
    assign run_iter = iterate && !done_q;

    //----------------------------------------------------------
    // Next State Logic
    //----------------------------------------------------------
    always_comb
    begin
        x_next = x_reg;
        y_next = y_reg;
        z_next = z_reg;
        if (run_iter)
        begin
            if (!z_is_neg)
            begin
                x_next = x_reg - y_shift;
                y_next = y_reg + x_shift;
                z_next = z_reg - atan_angle;
            end
            else
            begin
                x_next = x_reg + y_shift;
                y_next = y_reg - x_shift;
                z_next = z_reg + atan_angle;
            end
        end
    end

    //----------------------------------------------------------
    // Sequential Logic
    //----------------------------------------------------------
    always_ff @(posedge clk)
    begin
        if (rst)
        begin
            x_reg     <= '0;
            y_reg     <= '0;
            z_reg     <= '0;
            iteration <= '0;
            iter_done <= 1'b0;
            done_q    <= 1'b0;
        end
        else if (load)
        begin
            x_reg     <= {{(INTERNAL_WIDTH-DATA_WIDTH){CORDIC_K[DATA_WIDTH-1]}}, CORDIC_K};
            y_reg     <= '0;
            z_reg     <= {{(INTERNAL_WIDTH-DATA_WIDTH){angle_in[DATA_WIDTH-1]}}, angle_in};
            iteration <= '0;
            iter_done <= 1'b0;
            done_q    <= 1'b0;
        end
        else if (run_iter)
        begin
            x_reg <= x_next;
            y_reg <= y_next;
            z_reg <= z_next;

            if (iteration == ITERATIONS-1)
            begin
                iter_done <= 1'b1;
                done_q    <= 1'b1;   // latch: stop further updates
            end
            else
            begin
                iteration <= iteration + 1'b1;
                iter_done <= 1'b0;
            end
        end
        else
        begin
            // Not iterating (or already done): iter_done stays low
            // one cycle after it pulsed once, unless you want it to
            // stay high -- see note below.
            iter_done <= 1'b0;
        end
    end

    //----------------------------------------------------------
    // Saturating narrow of internal_t -> fixed_t on output
    //----------------------------------------------------------
    function automatic fixed_t saturate(internal_t val);
        localparam internal_t POS_MAX =
            {{(INTERNAL_WIDTH-DATA_WIDTH){1'b0}}, 1'b0, {(DATA_WIDTH-1){1'b1}}};
        localparam internal_t NEG_MIN =
            {{(INTERNAL_WIDTH-DATA_WIDTH){1'b1}}, 1'b1, {(DATA_WIDTH-1){1'b0}}};
        if (val > POS_MAX)
            saturate = {1'b0, {(DATA_WIDTH-1){1'b1}}};       // +max representable
        else if (val < NEG_MIN)
            saturate = {1'b1, {(DATA_WIDTH-1){1'b0}}};       // -max representable
        else
            saturate = val[DATA_WIDTH-1:0];
    endfunction

    assign cos_out = saturate(x_reg);
    assign sin_out = saturate(y_reg);

endmodule
