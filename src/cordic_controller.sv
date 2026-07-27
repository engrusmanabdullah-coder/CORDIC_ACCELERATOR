`timescale 1ns/1ps

module cordic_controller
(
    input  logic clk,
    input  logic rst,

    input  logic start,
    input  logic iter_done,

    output logic load,
    output logic iterate,
    output logic done
);

    //------------------------------------------------------------
    // FSM State Encoding
    //------------------------------------------------------------

    typedef enum logic [1:0]
    {
        IDLE,
        LOAD,
        ITERATE,
        DONE
    } state_t;

    state_t current_state;
    state_t next_state;

    //------------------------------------------------------------
    // State Register
    //------------------------------------------------------------

    always_ff @(posedge clk or posedge rst)
    begin

        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;

    end

    //------------------------------------------------------------
    // Next-State Logic
    //------------------------------------------------------------

    always_comb
    begin

        next_state = current_state;

        case(current_state)

            //----------------------------------------------------

            IDLE:
            begin
                if(start)
                    next_state = LOAD;
            end

            //----------------------------------------------------

            LOAD:
            begin
                next_state = ITERATE;
            end

            //----------------------------------------------------

            ITERATE:
            begin
                if(iter_done)
                    next_state = DONE;
                else
                    next_state = ITERATE;
            end

            //----------------------------------------------------

            DONE:
            begin
                next_state = IDLE;
            end

            //----------------------------------------------------

            default:
                next_state = IDLE;

        endcase

    end

    //------------------------------------------------------------
    // Output Logic (Moore FSM)
    //------------------------------------------------------------

    always_comb
    begin

        // Default outputs

        load     = 1'b0;
        iterate  = 1'b0;
        done     = 1'b0;

        case(current_state)

            IDLE:
            begin
                // Wait for start
            end

            LOAD:
            begin
                load = 1'b1;
            end

            ITERATE:
            begin
                iterate = 1'b1;
            end

            DONE:
            begin
                done = 1'b1;
            end

            default:
            begin
                load    = 1'b0;
                iterate = 1'b0;
                done    = 1'b0;
            end

        endcase

    end

endmodule
