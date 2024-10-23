module Washing_machine(
    input clk,rst,start,double_wash,dry_wash,stop,time_pause;
    output reg done;
);

localparam IDLE = 3'b000, // IDLE state
           FILL_WATER = 3'b001, // filling water and detergent state
           WASH = 3'b010, // WASH state
           RINSE = 3'b011, // rinse state
           SPIN = 3'b100, // drying state
           DRY = 3'b101; // dry WASH state

localparam time_7secs = 32'd7, //for filling of water
           time_5secs = 32'd5, // for WASH,RINSE
           time_10secs = 32'd10; // for drying,dry WASH


reg [2:0] current_state,next_state; // for the current and next states
reg[31:0] counter,counter_comb; // counter for the time
reg[1:0] number_of_washes; // number of washes done
reg timeout;


always@(posedge clk)begin
    if(current_state == IDLE)
    begin
        number_of_washes <= 2'd00; 
    end
    else if (current_state == WASH && timeout)
    begin
        number_of_washes <= number_of_washes + 'd1; // increment number of washes when we are in the WASH state and the timeout is 1
    end
end
always@(posedge clk or posedge rst)begin
    if(rst)
    begin
        current_state <= IDLE;
    end
    else 
    begin
        current_state <= next_state; // if its not reset then we go to the next state
    end
end

always@(posedge clk or posedge rst)begin
    if(rst)
    begin
        counter <= 'd0;
    end
    else 
    begin
        counter <= counter_comb; // store value of counter for time for all states
    end
end

always@(*)begin
    next_state <= IDLE;
    case(current_state)
    IDLE:
    begin

        if(start)begin
            next_state <= FILL_WATER;
        end
        /*else if(stop)begin
            next_state <= current_state;
        end */
    end
    FILL_WATER:
          begin
            // Go to the next state (WASH) when the filling water's duration (7 seconds) is over
            if(timeout)
              begin
                next_state = WASH;
              end
            // Otherwise, continue filling water
            else
              begin
                next_state = current_state;
              end

          end
        WASH:
          begin
            // Go to the next phase (RINSE) when the WASH's duration (5 minutes) is over
            if(timeout)
              begin
                next_state = RINSE;
              end
            else
              begin
                // Otherwise, continue WASH
                next_state = current_state;
              end
          end
        RINSE:
          begin
            if(timeout)
              begin
                // when the RINSE's duration is over, check if the user is requesting a second wash
                if(double_wash)
                  begin
                    // Check the number_of_washes counter first. If we have done only 1 wash, then go to the 
                    // WASH state for the second wash.
                    if(number_of_washes == 'd1)
                      begin
                        next_state = WASH;
                      end
                    // Otherwise if the second wash is already done, go to the SPIN state.
                    else
                      begin
                        next_state = SPIN;
                      end
                  end
                // If no second wash is requested by the user, then go to the SPIN state.
                else
                  begin
                    next_state = SPIN;
                  end
              end
            // Otherwise, if the RINSE phase's duration is not over yet, remain in the RINSE state
            else
              begin
                next_state = current_state;
              end
          end
        SPIN:
          begin
            // When the drying phase is over (and accordingly the whole operation), return to IDLE state
            if(timeout)
              begin
                next_state = DRY;
              end
            // Otherwise, continue drying
            else
              begin
                next_state = current_state;
              end
          end
        // A default case for any unexpected behavior and to also avoid any unintentional latches
        default:
          begin
            next_state = IDLE;
          end
        DRY:
          begin
            // When the drying phase is over (and accordingly the whole operation), return to IDLE state
            if(timeout)
              begin
                next_state = IDLE;
              end
            // Otherwise, continue drying
            else
              begin
                next_state = current_state;
              end
          end
        // A default case for any unexpected behavior and to also avoid any unintentional latches
        default:
          begin
            next_state = IDLE;
          end  
      endcase

end

