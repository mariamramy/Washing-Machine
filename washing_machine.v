module Washing_Machine(input clk,rst,start,double_wash,dry_wash,time_pause,output reg done);

localparam IDLE = 3'b000, // IDLE state
           FILL_WATER = 3'b001, // filling water and detergent state
           WASH = 3'b010, // washing state
           RINSE = 3'b011, // rinsing state
           SPIN = 3'b100, // spinning state
           DRY = 3'b101, // drying state
           STEAM_CLEAN = 3'b110, // washing clothes using steam state
           PAUSE = 3'b111; // time pausing during states 

localparam time_7cycles = 7, //for filling of water,dry washing
           time_5cycles = 5, // for WASH,RINSE,SPIN
           time_10cycles = 10, // for drying,steam_cleaning
           time_20cycles = 20; // for time pausing


reg[2:0] current_state,next_state,prev_state; // for the current,previous and next states
reg[31:0] counter,counter_comb,counter_backup; // counter for the time spent in each state
reg[1:0] number_of_washes; // number of washes done
reg timeout; // signal when a specific time for a state is up and time pause signal.

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


always @(posedge clk or posedge rst) 
begin
    if (rst) begin
        counter_backup <= 0; // Reset backup on reset
        prev_state <= IDLE;

    end else if (time_pause && current_state != PAUSE) begin
        prev_state <= current_state;
        counter_backup <= counter; // Save counter value when entering PAUSE
    end
    else (!time_pause && current_state == PAUSE) begin
    counter_backup <= 0; // Clear counter backup
end
end

always@(*)begin
    next_state = IDLE;
    case(current_state)
    IDLE:
    begin
      if(start)begin
          next_state = FILL_WATER;
      end
      if(dry_wash && start)begin 
        next_state = STEAM_CLEAN;
      end
    end
    FILL_WATER:
    begin
      if(time_pause) // go to the state PAUSE for the time pause
        begin 
          prev_state = current_state;
          next_state = PAUSE;
        end      // Go to the next state (WASH) when the filling water's duration (7 seconds) is over
      else if(timeout)
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
      if(time_pause) // go to the state PAUSE for the time pause
        begin 
          prev_state = current_state;
          next_state = PAUSE;
        end      // Go to the next phase (RINSE) when the WASH's duration (5 seconds) is over
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
      if(time_pause) // go to the state PAUSE for the time pause
        begin 
          prev_state = current_state;
          next_state = PAUSE;
        end
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
      if(time_pause) // go to the state PAUSE for the time pause
        begin 
          prev_state = current_state;
          next_state = PAUSE;
        end
            // When the spinning phase is, go to drying state
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
      if(time_pause) // go to the state PAUSE for the time pause
        begin 
          prev_state = current_state;
          next_state = PAUSE;
        end
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
    STEAM_CLEAN:
    begin
      if(time_pause) // go to the state PAUSE for the time pause
        begin 
          prev_state = current_state;
          next_state = PAUSE;
        end 
      if(timeout)
        begin  
          next_state = IDLE;
        end
      else 
        begin  
          next_state = current_state;
        end
    end
    PAUSE:
    begin 
      if(timeout) //Time to return to the previous state
        begin  
          next_state = prev_state;
        end
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

always@(*)
  begin
    // As long as the machine is not being used, the output done is set indicating the availability of
    // the machine. When a user starts the machine, the output done is deasserted indicating that an 
    // operation is currently running.
    if(current_state == IDLE)
      begin
        done = 'd1;
      end
    else
      begin
        done = 'd0;
      end
  end

always@(*)begin 
  counter_comb = 'b0;
  timeout = 'b0;
  case(current_state) 
    IDLE:
    begin 
      counter_comb = 'b0;
      timeout = 'b0;
    end
    FILL_WATER, STEAM_CLEAN:
    begin
      if (time_pause) 
      begin
        counter_comb = counter; // Hold the counter during pause 
      end 
      else if(counter == time_7secs) 
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
      if (time_pause) 
      begin
        counter_comb = counter; // Hold the counter during pause 
      end 
      else if(counter == time_5secs)
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
      if (time_pause) 
      begin
        counter_comb = counter; // Hold the counter during pause 
      end 
      else if(counter == time_10secs)
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
    PAUSE:
    begin 
      if(counter == time_20secs)
      begin
        counter_comb = counter_backup;  
        timeout = 'd1;
      end
      else 
      begin  
        counter_comb = counter + 'd1;
        timeout = 'd0;
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
