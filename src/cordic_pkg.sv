package cordic_pkg;

    //----------------------------------------------------------------------
    // Global Parameters
    //----------------------------------------------------------------------

    parameter int DATA_WIDTH = 16;
    parameter int FRAC_BITS  = 15;
    parameter int ITERATIONS = 16;
    
    parameter int INTERNAL_WIDTH = 18;
    
   

    //----------------------------------------------------------------------
    // Fixed-Point Type
    //----------------------------------------------------------------------

    typedef logic signed [DATA_WIDTH-1:0] fixed_t;
    typedef logic signed [INTERNAL_WIDTH-1:0] internal_t;

    //----------------------------------------------------------------------
    // CORDIC Gain Compensation
    //
    // K = 0.607252935
    //
    // Q1.15 representation:
    // K × 2^15 ? 19898
    //----------------------------------------------------------------------

    localparam fixed_t CORDIC_K = 16'sd19898;

    //----------------------------------------------------------------------
    // Useful Constants (Q1.15)
    //----------------------------------------------------------------------

    localparam fixed_t ZERO = 16'sd0;
    localparam fixed_t ONE  = 16'sd32767;
    
        localparam fixed_t ANGLE_90  = 16'sd16384;   // +90° (+PI/2)
        localparam fixed_t ANGLE_180 = 16'h8000;     // 180°  (PI)

    //----------------------------------------------------------------------
    // atan(2^-i) Lookup Table
    //
    // Values stored in RADIANS (Q1.15)
    //
    // Generated as:
    // round(atan(2^-i) * 2^15)
    //----------------------------------------------------------------------

    localparam fixed_t ATAN_TABLE [0:ITERATIONS-1] = '{
        16'sd8192,   // atan(2^-0)/pi  = 0.2500000000
        16'sd4836,   // atan(2^-1)/pi  = 0.1475836177
        16'sd2560,   // atan(2^-2)/pi  = 0.0779791304
        16'sd1299,   // atan(2^-3)/pi  = 0.0395836814
        16'sd651,    // atan(2^-4)/pi  = 0.0198812869
        16'sd326,    // atan(2^-5)/pi  = 0.0099401045
        16'sd163,    // atan(2^-6)/pi  = 0.0049729036
        16'sd81,     // atan(2^-7)/pi  = 0.0024861757
        16'sd41,     // atan(2^-8)/pi  = 0.0012433979
        16'sd20,     // atan(2^-9)/pi  = 0.0006216937
        16'sd10,     // atan(2^-10)/pi = 0.0003108468
        16'sd5,      // atan(2^-11)/pi = 0.0001554234
        16'sd3,      // atan(2^-12)/pi = 0.0000777117
        16'sd1,      // atan(2^-13)/pi = 0.0000388558
        16'sd1,      // atan(2^-14)/pi = 0.0000194279
        16'sd0       // atan(2^-15)/pi = 0.0000097139
    };

endpackage
