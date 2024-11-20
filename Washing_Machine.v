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
  output reg done
);

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
localparam numberOfCounts_10seconds  = 6'd9,   // Fill water
           numberOfCounts_20seconds  = 6'd19,  // Spin
           numberOfCounts_50seconds  = 6'd49,  // Wash and rinse
           numberofCounts_1minute    = 6'd59;  // Dry, steam clean

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// Variables and Internal Connections //////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

reg [2:0] current_state, next_state;
reg [5:0] counter, counter_comb;
reg timeout;
reg [1:0] number_of_washes;

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// Sequential Procedural Blocks /////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

// Logic to support the "double wash" option
always @(posedge clk) begin
  if (current_state == IDLE) begin
    number_of_washes <= 'd0; // Reset the number of washes in IDLE
  end else if ((current_state == WASH) && timeout) begin
    number_of_washes <= number_of_washes + 'd1; // Increment the number of washes
  end
end  

// Current state sequential logic
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    current_state <= IDLE; // Reset to IDLE state asynchronously
  end else begin
    current_state <= next_state; // Transition to the next state
  end
end

// 6-bit counter sequential logic
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    counter <= 'd0; // Reset the counter asynchronously
  end else begin
    counter <= counter_comb; // Update counter based on combinational logic
  end
end

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// Combinational Procedural Blocks /////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

// Next state combinational logic
always @(*) begin
  next_state = IDLE; // Default value to avoid unintentional latches

  case (current_state)
    IDLE: begin
      if (dry_wash && start) begin
        next_state = STEAM_CLEAN; // Transition to STEAM_CLEAN
      end else if (start) begin
        next_state = FILL_WATER; // Transition to FILL_WATER
      end else begin
        next_state = current_state; // Remain in IDLE
      end
    end

    FILL_WATER: begin
      next_state = timeout ? WASH : current_state; // Transition to WASH on timeout
    end

    WASH: begin
      next_state = timeout ? RINSE : current_state; // Transition to RINSE on timeout
    end

    RINSE: begin
      if (timeout) begin
        if (double_wash && (number_of_washes == 'd1)) begin
          next_state = WASH; // Transition to WASH for second wash
        end else begin
          next_state = SPIN; // Otherwise, transition to SPIN
        end
      end else begin
        next_state = current_state; // Remain in RINSE
      end
    end

    SPIN: begin
      next_state = timeout ? DRY : current_state; // Transition to DRY on timeout
    end

    DRY: begin
      next_state = timeout ? IDLE : current_state; // Transition to IDLE on timeout
    end

    STEAM_CLEAN: begin
      next_state = timeout ? IDLE : current_state; // Transition to IDLE on timeout
    end

    default: begin
      next_state = IDLE; // Default case
    end
  endcase
end

// Output combinational logic
always @(*) begin
  done = (current_state == IDLE) ? 'd1 : 'd0; // 'done' is high only in IDLE state
end

// 6-bit counter combinational logic
always @(*) begin
  counter_comb = counter;
  timeout = 1'b0;

  case (current_state)
    IDLE: begin
      counter_comb = 'd0; // Counter does not count in IDLE
      timeout = 1'b0;
    end

    FILL_WATER: begin
      if (counter == numberOfCounts_10seconds) begin
        counter_comb = 'd0; // Reset counter and set timeout
        timeout = 1'b1;
      end else if (time_pause) begin
        counter_comb = counter; // Freeze counter
        timeout = 1'b0;
      end else begin
        counter_comb = counter + 1'd1; // Increment counter
        timeout = 1'b0;
      end
    end

    // Similar logic applies for other states (WASH, RINSE, SPIN, DRY, STEAM_CLEAN)
    WASH: begin
      if (counter == numberOfCounts_50seconds) begin
        counter_comb = 'd0;
        timeout = 1'b1;
      end else if (time_pause) begin
        counter_comb = counter;
        timeout = 1'b0;
      end else begin
        counter_comb = counter + 1'd1;
        timeout = 1'b0;
      end
    end

    RINSE: begin
      if (counter == numberOfCounts_50seconds) begin
        counter_comb = 'd0;
        timeout = 1'b1;
      end else if (time_pause) begin
        counter_comb = counter;
        timeout = 1'b0;
      end else begin
        counter_comb = counter + 1'd1;
        timeout = 1'b0;
      end
    end

    SPIN: begin
      if (counter == numberOfCounts_20seconds) begin
        counter_comb = 'd0;
        timeout = 1'b1;
      end else if (time_pause) begin
        counter_comb = counter;
        timeout = 1'b0;
      end else begin
        counter_comb = counter + 1'd1;
        timeout = 1'b0;
      end
    end

    DRY: begin
      if (counter == numberofCounts_1minute) begin
        counter_comb = 'd0;
        timeout = 1'b1;
      end else if (time_pause) begin
        counter_comb = counter;
        timeout = 1'b0;
      end else begin
        counter_comb = counter + 1'd1;
        timeout = 1'b0;
      end
    end

    STEAM_CLEAN: begin
      if (counter == numberofCounts_1minute) begin
        counter_comb = 'd0;
        timeout = 1'b1;
      end else if (time_pause) begin
        counter_comb = counter;
        timeout = 1'b0;
      end else begin
        counter_comb = counter + 1'd1;
        timeout = 1'b0;
      end
    end

    default: begin
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

// PSL assertions
// Ensure 'done' is high only in the IDLE state
// psl property Done_Only_In_IDLE = always ((current_state == IDLE) -> (done == 1));
// psl assert Done_Only_In_IDLE;

// Ensure proper transition from IDLE to FILL_WATER when 'start' is asserted
// psl property IDLE_To_FILL_WATER = always ((current_state == IDLE && start && !dry_wash) -> eventually!(current_state == FILL_WATER));
// psl assert IDLE_To_FILL_WATER;

// Ensure correct double wash behavior
// psl property Double_Wash_Transition = always ((current_state == RINSE && double_wash && number_of_washes == 1) -> eventually!(current_state == WASH));
// psl assert Double_Wash_Transition;

// Ensure timeout flag is set at correct counter values
// psl property Timeout_Correctness = always ((current_state == FILL_WATER && counter == numberOfCounts_10seconds) -> timeout);
// psl assert Timeout_Correctness;

// Ensure 'time_pause' freezes the counter
// psl property Time_Pause_Functionality = always (time_pause -> (counter == prev(counter_comb)));
// psl assert Time_Pause_Functionality;

// Ensure proper behavior for STEAM_CLEAN
// psl property Steam_Clean_Behavior = always ((current_state == STEAM_CLEAN && timeout) -> next(current_state == IDLE));
// psl assert Steam_Clean_Behavior;

endmodule
