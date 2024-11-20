//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////// Module ports list, declaration, and data type ///////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

module Washing_Machine(
  input wire rst_n,
  input wire clk,
  input wire start,
  input wire double_wash,
  input wire dry_wash,
  input wire time_pause,  // time_pause input added
  output reg done);

//////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////// Parameters /////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
  
  // Define states
  localparam IDLE        = 3'b000,
             FILL_WATER  = 3'b001,
             WASH        = 3'b010,
             RINSE       = 3'b011,
             SPIN        = 3'b100,
             DRY         = 3'b101,
             STEAM_CLEAN = 3'b110;
          
  // Define the number of counts required by the counter to reach specific time
  localparam numberOfCounts_10seconds  = 6'd9, //fill water
             numberOfCounts_20seconds = 6'd19, // spin
             numberOfCounts_50seconds = 6'd49, // wash and rinse
             numberofCounts_1minute = 6'd59; //dry,steam clean
  

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// Variables and Internal Connections ////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////

  reg [2:0] current_state, next_state;
  reg [5:0] counter, counter_comb;
  reg timeout;
  reg [1:0] number_of_washes;
  
////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// Sequential Procedural Blocks //////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Logic to support the "double wash" option. A counter number_of_washes is used to count the number of
    // washes in order to make 2 washes whenever the user requests a double wash.
    always@(posedge clk)
      begin
        // If a wash cycle is completed OR the reset button is pressed, reset the number of washes counter for the next
        // user to be able to use the "double wash" option
        if(current_state == IDLE)
          begin
            number_of_washes <= 'd0;
          end
        // If the washing phase is completed, increment the number of washes counter
        else if( (current_state == WASH) && timeout )
          begin
            number_of_washes <= number_of_washes + 'd1;
          end
      end  

  // Current state sequential logic
  always@(posedge clk or negedge rst_n)
    begin
      // If the reset button is pressed, go to the idle state asynchronously
      if(!rst_n)
        begin
          current_state <= IDLE;
        end
      // Otherwise, go to the state decided by the next state combinational logic
      else
        begin
          current_state <= next_state;
        end
    end

  // 32-bit counter sequential logic
  always@(posedge clk or negedge rst_n)
    begin
      // If the reset button is pressed, the counter is reset asynchronously
      if(!rst_n)
        begin
          counter <= 'd0;
        end
      // Otherwise, the counter is loaded with the value decided by the counter's combinational logic
      else
        begin
          counter <= counter_comb;
        end
    end
    
////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// Combinational Procedural Blocks ///////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////
  
  // Next state combinational logic
  always@(*)
    begin
      // Initial value to avoid unintentional latches
      next_state = IDLE;
      case(current_state)
        IDLE:
          begin
            // Check if user wants to steam clean
            if(dry_wash && start)
              begin    
                next_state = STEAM_CLEAN;
              end
            // Otherwise, Begin the operation only when a start is asserted
            else if(start)
              begin
                next_state = FILL_WATER;
              end
            // Otherwise, stay in IDLE state
            else 
            begin  
            next_state = current_state;
            end  
          end
        FILL_WATER:
          begin
            // Go to the next state (wash) when the filling water's duration (2 minutes) is over
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
            // Go to the next phase (rinse) when the washing's duration (5 minutes) is over
            if(timeout)
              begin
                next_state = RINSE;
              end
            else
              begin
                // Otherwise, continue washing
                next_state = current_state;
              end
          end
        RINSE:
          begin
            if(timeout)
              begin
                // when the rinsing's duration is over, check if the user is requesting a second wash
                if(double_wash)
                  begin
                    // Check the number_of_washes counter first. If we have done only 1 wash, then go to the 
                    // WASHING state for the second wash.
                    if(number_of_washes == 'd1)
                      begin
                        next_state = WASH;
                      end
                    // Otherwise if the second wash is already done, go to the SPINNING state.
                    else
                      begin
                        next_state = SPIN;
                      end
                  end
                // If no second wash is requested by the user, then go to the SPINNING state.
                else
                  begin
                    next_state = SPIN;
                  end
              end
            // Otherwise, if the rinsing phase's duration is not over yet, remain in the rinsing state
            else
              begin
                next_state = current_state;
              end
          end
        SPIN:
          begin
            // When the spinning phase is over, go to DRY state
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
            // When the steam cleaning phase is over, return to IDLE state
            if(timeout)
              begin
                next_state = IDLE;
              end
            // Otherwise, continue steam cleaning
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
    
  // Output combinational logic
  always@(*)
    begin
      // As long as the machine is not being used, the output done is set indicating the availability of
      // the machine. When a user starts the machine, the output done is deasserted indicating that an 
      // operation is currently running (i.e. the machine is not available).
      if(current_state == IDLE)
        begin
          done = 'd1;
        end
      else
        begin
          done = 'd0;
        end
    end

  // 32-bit counter combinational logic
  always@(*)
    begin
      // Initial values to avoid unintentional latches
      counter_comb = counter;
      timeout = 1'b0;
      case(current_state)
        IDLE:
        // Counter should not count in the IDLE state
          begin
            counter_comb = 'd0;
            timeout = 1'b0;
          end
        FILL_WATER:
        // Counter should count a number of counts equivalent to 1 minute
                begin
                  // If the counter has reached the required number of counts, reset the counter and fire the timeout flag
                  if(counter == numberOfCounts_10seconds)
                    begin
                      counter_comb = 'd0;
                      timeout = 1'b1;
                    end
                  // Otherwise, if the user has requested to pause the timer, freeze the counter until time_pause is deasserted
                  else if(time_pause)
                    begin
                      counter_comb = counter;
                      timeout = 1'b0;
                    end
                  // Otherwise, increment the counter and keep the timeout flag deasserted
                  else
                    begin
                      counter_comb = counter + 1'd1;
                      timeout = 1'b0;
                    end
                end 
        WASH:
        // Counter should count a number of counts equivalent to 5 minutes
                begin
                  // If the counter has reached the required number of counts, reset the counter and fire the timeout flag
                  if(counter == numberOfCounts_50seconds)
                    begin
                      counter_comb = 'd0;
                      timeout = 1'b1;
                    end
                  // Otherwise, if the user has requested to pause the timer, freeze the counter until time_pause is deasserted
                  else if(time_pause)
                    begin
                      counter_comb = counter;
                      timeout = 1'b0;
                    end
                  // Otherwise, increment the counter and keep the timeout flag deasserted
                  else
                    begin
                      counter_comb = counter + 1'd1;
                      timeout = 1'b0;
                    end
                end
        RINSE:
        // Counter should count a number of counts equivalent to 5 minutes
                begin
                  // Same logic as the washing phase
                  if(counter == numberOfCounts_50seconds)
                    begin
                      counter_comb = 'd0;
                      timeout = 1'b1;
                    end
                  else if(time_pause)
                    begin
                      counter_comb = counter;
                      timeout = 1'b0;
                    end
                  else
                    begin
                      counter_comb = counter + 1'd1;
                      timeout = 1'b0;
                    end
                end  
        SPIN:
        // Counter should count a number of counts equivalent to 2 minutes
                begin
                  // Same logic as the previous phases but for 2 minutes
                  if(counter == numberOfCounts_20seconds)
                    begin
                      counter_comb = 'd0;
                      timeout = 1'b1;
                    end
                  else if(time_pause)
                    begin
                      counter_comb = counter;
                      timeout = 1'b0;
                    end
                  else
                    begin
                      counter_comb = counter + 1'd1;
                      timeout = 1'b0;
                    end
                end
        DRY:
        // Counter should count a number of counts equivalent to 10 minutes
                begin
                  // Same logic as the previous phases but for 10 minutes
                  if(counter == numberofCounts_1minute)
                    begin
                      counter_comb = 'd0;
                      timeout = 1'b1;
                    end
                  else if(time_pause)
                    begin
                      counter_comb = counter;
                      timeout = 1'b0;
                    end
                  else
                    begin
                      counter_comb = counter + 1'd1;
                      timeout = 1'b0;
                    end
                end
        STEAM_CLEAN:
        // Same logic as drying phase
                begin
                  if(counter == numberofCounts_1minute)
                    begin
                      counter_comb = 'd0;
                      timeout = 1'b1;
                    end
                  else if(time_pause)
                    begin
                      counter_comb = counter;
                      timeout = 1'b0;
                    end
                  else
                    begin
                      counter_comb = counter + 1'd1;
                      timeout = 1'b0;
                    end
                end
        default:
          begin
            counter_comb = 'd0;
            timeout = 1'b0;
          end
      endcase
    end



    
    
/*
Ensure the washing machine starts in IDLE when reset is asserted
psl default clock = rose(clk);
psl property Reset_To_IDLE = always (rst_n == 0 -> next(current_state == IDLE));
psl assert Reset_To_IDLE;
*/

// Ensure 'done' is high only in the IDLE state
// psl property Done_Only_In_IDLE = always ((current_state == IDLE) -> (done == 1));
//psl assert Done_Only_In_IDLE;

// Ensure proper transition from IDLE to FILL_WATER when 'start' is asserted
// psl property IDLE_To_FILL_WATER = always ((current_state == IDLE && start && !dry_wash) -> eventually!(current_state == FILL_WATER));
// psl assert IDLE_To_FILL_WATER;

// Ensure correct double wash behavior: RINSE -> WASH if 'double_wash' is enabled and number_of_washes == 1
// psl property Double_Wash_Transition = always ((current_state == RINSE && double_wash && number_of_washes == 1) -> eventually!(current_state == WASH));
// psl assert Double_Wash_Transition;

// Ensure timeout flag is set at correct counter values
//psl property Timeout_Correctness = always ((current_state == FILL_WATER && counter == numberOfCounts_10seconds) -> timeout);
//psl assert Timeout_Correctness;

// Ensure 'time_pause' freezes the counter
// psl property Time_Pause_Functionality = always (time_pause -> (counter == prev(counter_comb)));
// psl assert Time_Pause_Functionality;

// Ensure proper behavior for STEAM_CLEAN
// psl property Steam_Clean_Behavior = always ((current_state == STEAM_CLEAN && timeout) -> eventually!(current_state == IDLE));
// psl assert Steam_Clean_Behavior;

endmodule
