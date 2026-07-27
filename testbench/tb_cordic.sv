// ============================================================================
// File Name   : tb_cordic.sv
// Organization: MEDS Lab
// Description : Comprehensive, self-checking testbench for standard 16-bit
//               fixed-point CORDIC (Sin/Cos mode).
// Features    : - Binary Angle Measurement (BAM/Q0.16) input angle encoding
//               - Golden reference model using SystemVerilog Math Functions
//               - Self-checking scoreboard with LSB error tracking
//               - Automated Directed (0, ±30, ±45, ±60, ±90, ±180, small) & 
//                 Randomized (100+ cases) test suites
//               - SystemVerilog Assertions (X/Z detection, completion timeouts)
// ============================================================================

`timescale 1ns/1ps
import cordic_pkg::*;

module tb_cordic;

  // ==========================================================================
  // Testbench Parameters
  // ==========================================================================
  localparam real    CLK_PERIOD     = 10.0;                       // Clock period in ns (100 MHz)
  localparam real    PI             = 3.14159265358979323846;     // Mathematical Constant PI
  localparam integer TIMEOUT_CYCLES = 100;                        // Watchdog timeout for 'done'
  
  // LSB Tolerance limit to accommodate truncation drift across iterations.
  // Standard 16-bit CORDIC typically stays within 10-25 LSB error margin.
  localparam integer TOLERANCE_LSB  = 30;

  // ==========================================================================
  // DUT Interface Signals
  // ==========================================================================
  logic   clk;
  logic   rst;
  logic   start;
  fixed_t angle_in;
  fixed_t cos_out;
  fixed_t sin_out;
  logic   done;

  // ==========================================================================
  // Scoreboard Variables
  // ==========================================================================
  integer total_tests  = 0;
  integer passed_tests = 0;
  integer failed_tests = 0;
  integer max_cos_err  = 0;
  integer max_sin_err  = 0;

  // ==========================================================================
  // DUT Instantiation
  // ==========================================================================
  cordic_top dut (
    .clk      (clk),
    .rst      (rst),
    .start    (start),
    .angle_in (angle_in),
    .cos_out  (cos_out),
    .sin_out  (sin_out),
    .done     (done)
  );

  // ==========================================================================
  // Clock Generation
  // ==========================================================================
  initial clk = 1'b0;
  always #(CLK_PERIOD / 2.0) clk = ~clk;

  // ==========================================================================
  // Mathematical Helper Functions
  // ==========================================================================

  // Converts degrees (-180.0 to +180.0) into Binary Angle Measurement (BAM/Q0.16)
  // Maps 180° -> 32768 (which fits signed 16-bit range as -32768 to +32767)
  function automatic fixed_t deg_to_q15(input real deg);
    integer tmp;
    begin
      tmp = $rtoi((deg / 180.0) * 32768.0);
      deg_to_q15 = fixed_t'(tmp);
    end
  endfunction

  // Calculates absolute difference between two integer values
  function automatic integer abs_diff(input integer a, input integer b);
    return (a > b) ? (a - b) : (b - a);
  endfunction

  // ==========================================================================
  // Reusable Verification Tasks
  // ==========================================================================

  // Task: Synchronous Reset Sequence
  task automatic apply_reset();
    begin
      rst      <= 1'b1;
      start    <= 1'b0;
      angle_in <= ZERO;
      repeat (3) @(posedge clk);
      rst      <= 1'b0;
      @(posedge clk);
    end
  endtask

  // Task: Single-cycle Start Pulse Generation
  task automatic pulse_start();
    begin
      @(posedge clk);
      start <= 1'b1;
      @(posedge clk);
      start <= 1'b0;
    end
  endtask

  // Task: Timeout Watchdog for Done Signal
  task automatic wait_done();
    integer cycles;
    begin
      cycles = 0;
      while (!done) begin
        @(posedge clk);
        cycles++;
        if (cycles > TIMEOUT_CYCLES) begin
          $fatal(1, "[ERROR] Timeout! DUT failed to assert 'done' within %0d clock cycles.", TIMEOUT_CYCLES);
        end
      end
    end
  endtask

  // Task: Main Verification Engine
  task automatic run_test(input real angle_deg);
    real    rad;
    integer exp_cos, exp_sin;
    integer err_cos, err_sin;
    begin
      total_tests++;
      
      // 1. Convert input degree to fixed-point format & drive DUT
      angle_in = deg_to_q15(angle_deg);
      pulse_start();
      wait_done();

      // 2. Reference Model Calculation (Q1.15 expected bounds: -32768 to 32767)
      rad     = angle_deg * PI / 180.0;
      exp_cos = $rtoi($cos(rad) * 32767.0);
      exp_sin = $rtoi($sin(rad) * 32767.0);

      // 3. Measure absolute errors in LSBs
      err_cos = abs_diff(integer'($signed(cos_out)), exp_cos);
      err_sin = abs_diff(integer'($signed(sin_out)), exp_sin);

      // 4. Track peak error metrics
      if (err_cos > max_cos_err) max_cos_err = err_cos;
      if (err_sin > max_sin_err) max_sin_err = err_sin;

      // 5. Scoreboard Check against Tolerance Limit
      if (err_cos <= TOLERANCE_LSB && err_sin <= TOLERANCE_LSB) begin
        passed_tests++;
        $display("[PASS] Angle=%6.2f° | Cos: Got=%6d Exp=%6d (Err=%2d LSB) | Sin: Got=%6d Exp=%6d (Err=%2d LSB)",
                 angle_deg, $signed(cos_out), exp_cos, err_cos, $signed(sin_out), exp_sin, err_sin);
      end else begin
        failed_tests++;
        $display("[FAIL] Angle=%6.2f° | Cos: Got=%6d Exp=%6d (Err=%2d LSB) | Sin: Got=%6d Exp=%6d (Err=%2d LSB)",
                 angle_deg, $signed(cos_out), exp_cos, err_cos, $signed(sin_out), exp_sin, err_sin);
      end
      
      repeat (2) @(posedge clk);
    end
  endtask

  // ==========================================================================
  // SystemVerilog Assertions & Checks
  // ==========================================================================

  // Check 1: Ensure no Unknown/High-Z states occur on output lines after reset
  always @(posedge clk) begin
    if (!rst) begin
      assert (!($isunknown(cos_out) || $isunknown(sin_out)))
        else $error("[ASSERTION FAILED] Unknown (X/Z) value detected on CORDIC outputs!");
    end
  end

  // ==========================================================================
  // Waveform Dumping Setup
  // ==========================================================================
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_cordic);
  end

  // ==========================================================================
  // Main Execution Block
  // ==========================================================================
  initial begin
    real rand_angle;

    // Display Header
    $display("==================================================");
    $display("     MEDS Lab CORDIC Verification Environment     ");
    $display("==================================================");

    apply_reset();

    // ------------------------------------------------------------------------
    // Test Suite 1: Fundamental Directed Angles
    // ------------------------------------------------------------------------
    $display("\n---> Executing Directed Tests: Cardinal & Standard Angles");
    run_test(0.0);
    run_test(30.0);
    run_test(-30.0);
    run_test(45.0);
    run_test(-45.0);
    run_test(60.0);
    run_test(-60.0);
    run_test(90.0);
    run_test(-90.0);
    run_test(180.0);
    run_test(-180.0);

    // ------------------------------------------------------------------------
    // Test Suite 2: Small & Edge Case Angles
    // ------------------------------------------------------------------------
    $display("\n---> Executing Directed Tests: Small Angle Precision");
    run_test(0.1);
    run_test(-0.1);
    run_test(0.5);
    run_test(-0.5);
    run_test(1.0);
    run_test(-1.0);
    run_test(2.5);

    // ------------------------------------------------------------------------
    // Test Suite 3: Randomized Tests (100+ Pseudo-Random Angles)
    // ------------------------------------------------------------------------
    $display("\n---> Executing Randomized Tests (100 Cases)");
    repeat (100) begin
      // Generate precise fractional degree value in range [-180.00, +180.00]
      rand_angle = ($urandom_range(0, 36000) / 100.0) - 180.0;
      run_test(rand_angle);
    end

    // ------------------------------------------------------------------------
    // Final Summary Report Output
    // ------------------------------------------------------------------------
    $display("\n==========================================");
    $display("       CORDIC Verification Summary        ");
    $display("==========================================");
    $display(" Total Tests       : %0d", total_tests);
    $display(" Passed            : %0d", passed_tests);
    $display(" Failed            : %0d", failed_tests);
    $display(" Maximum Cos Error : %0d LSB", max_cos_err);
    $display(" Maximum Sin Error : %0d LSB", max_sin_err);
    $display(" Allowed Tolerance : %0d LSB", TOLERANCE_LSB);
    $display("==========================================");

    if (failed_tests == 0) begin
      $display("STATUS: SUCCESS - All test cases passed within error threshold.");
    end else begin
      $display("STATUS: FAILURE - %0d test cases exceeded allowed LSB tolerance.", failed_tests);
    end

    $finish;
  end

endmodule
