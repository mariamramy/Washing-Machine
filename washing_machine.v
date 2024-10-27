module Washing_Machine(input clk,rst,start,double_wash,dry_wash,time_pause,output reg done);

localparam IDLE = 3'b000, // IDLE state
           FILL_WATER = 3'b001, // filling water and detergent state
           WASH = 3'b010, // washing state
           RINSE = 3'b011, // rinsing state
           SPIN = 3'b100, // spinning state
           DRY = 3'b101; // drying state
           STEAM_CLEAN = 3'b110; // washing clothes using steam state

localparam time_7secs = 32'd7, //for filling of water,dry washing
           time_5secs = 32'd5, // for WASH,RINSE,SPIN
           time_10secs = 32'd10; // for drying


reg[2:0] current_state,next_state; // for the current and next states
reg[31:0] counter,counter_comb; // counter for the time spent in each state
reg[1:0] number_of_washes; // number of washes done
reg timeout; // signal when a specific time for a state is up.

// when in IDLE el number of washes resets o zero w in the wash state,  after the wash cycle completes (timeout), the number of washes increments.
always@(posedge clk)
begin
    if(current_state == IDLE)
    begin
        number_of_washes <= 2'd00; 
    end
    else if (current_state == WASH && timeout)
    begin
        number_of_washes <= number_of_washes + 'd1; // increment number of washes when we are in the WASH state and the timeout is 1
    end
end

    // When the reset is high the washing machine enters the idle state 
always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        current_state <= IDLE;
    end
    else 
    begin
        current_state <= next_state; // if its not reset then we go to the next state
    end
end

always@(posedge clk or posedge rst)
begin
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
      if(dry_wash)begin 
        next_state <= STEAM_CLEAN;
      end
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
            // Go to the next phase (RINSE) when the WASH's duration (5 seconds) is over
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
            // When the spinning phase is, go to DRY state
      if(timeout)
        begin
          next_state = DRY;
        end
            // Otherwise, continue spinning
      else
        begin
          next_state = current_state;
        end
    end
    DRY:
    begin
        // When the drying phase is over (and accordingly the whole operation), return to IDLE state
      if(timeout)
        begin
          done = 'b1;
          next_state = IDLE;
        end
        // Otherwise, continue drying
      else
        begin
          done = 'b0;
          next_state = current_state;
        end
    end
    STEAM_CLEAN:
    begin 
      if(timeout)
        begin
          dry_wash <= 'd0;
          done = 'b1;  
          next_state = IDLE;
        end
      else 
        begin
          done = 'b0;  
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
always@(*)begin 
  counter_comb = 'b0;
  timeout = 'b0;
  case(current_state)begin  
    IDLE:
    begin 
      counter_comb = 'b0;
      timeout = 'b0;
    end
    FILL_WATER,STEAM_CLEAN:
    begin 
      if(counter == time_7secs) 
      begin 
        counter_comb = 'd0;
        timeout = 'd1;
      end
      else 
      begin  
        counter_comb = counter + 'd1;
        timeout = 'd0;
      end
    end
    WASH,RINSE,SPIN:
    begin 
      if(counter == time_5secs)
      begin  
        counter_comb = 'd0;
        timeout = 'd1;
      end
      else 
      begin  
        counter_comb = counter + 'd1;
        timeout = 'd0;
      end
    end
    DRY:
    begin 
      if(counter == time_10secs)
      begin  
        counter_comb = 'd0;
        timeout = 'd1;
      end
      else 
      begin  
        counter_comb = counter + 'd1;
        timeout = 'd0;
      end
    end
  end
  default:
  begin 
    counter_comb = 'd0;
    timeout = 'd0;
  end
endcase  
end
endmodule
