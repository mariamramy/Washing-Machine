//////////////////////////// Module ports list, declaration, and data type ///////////////////////////////

module Washing_Machine(
  input wire rst_n,
  input wire clk,
  input wire start,
  input wire double_wash,
  input wire dry_wash,
  input wire time_pause,  // time_pause input added
  input wire door_closed, 
  output reg done,
  output reg error_signal // signal to show if error occurs due to door being open
);


///////////////////////////////////////////////// Parameters /////////////////////////////////////////////

// Define states
localparam IDLE        = 3'b000,
           FILL_WATER  = 3'b001,
           WASH        = 3'b010,
           RINSE       = 3'b011,
           SPIN        = 3'b100,
           DRY         = 3'b101,
           STEAM_CLEAN = 3'b110,
           ERROR       = 3'b111;

// Define the number of counts required by the counter to reach specific time
localparam numberOfCounts_10seconds  = 6'd9,   // Fill water
           numberOfCounts_20seconds  = 6'd19,  // Spin
           numberOfCounts_50seconds  = 6'd49,  // Wash and rinse
           numberofCounts_1minute    = 6'd59;  // Dry, steam clean

//////////////////////////////// Variables and Internal Connections //////////////////////////////////////

reg [2:0] current_state, next_state, prev_state;
reg [5:0] counter, counter_comb, backup_counter;
reg timeout;
reg [1:0] number_of_washes;

//////////////////////////////////// Sequential Procedural Blocks ////////////////////////////////////////

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
    prev_state <= IDLE; // Initialize prev_state to IDLE
  end else begin
    current_state <= next_state; // Update the state normally
    // Save state only when entering ERROR state
    if (current_state != ERROR && next_state == ERROR) begin
      prev_state <= current_state;
    end
  end
end

// Counter sequential logic
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    counter <= 'd0; // Reset the counter asynchronously
    backup_counter <= 'd0; // Initialize backup_counter
  end else begin
    // Normal counter update logic
    if (current_state != ERROR) begin
      counter <= counter_comb;
    end

    // Save counter when entering ERROR state
    if (current_state != ERROR && next_state == ERROR) begin
      backup_counter <= counter;
    end

    // Restore counter when exiting ERROR state
    if (current_state == ERROR && next_state != ERROR) begin
      counter <= backup_counter;
    end
  end
end

//////////////////////////////////// Combinational Procedural Blocks /////////////////////////////////////


// Next state combinational logic
always @(*) begin
  next_state = IDLE; // Default value to avoid unintentional latches
  error_signal = 1'b0;
  case (current_state)
    IDLE: begin
      if(!door_closed) begin
        next_state = ERROR;
        error_signal = 'b1;  
      end else if (dry_wash && start) begin
        next_state = STEAM_CLEAN; // Transition to STEAM_CLEAN
      end else if (start) begin
        next_state = FILL_WATER; // Transition to FILL_WATER
      end else begin
        next_state = current_state; // Remain in IDLE
      end
    end

    FILL_WATER: begin
      if (!door_closed) begin
        next_state = ERROR; // Transition to ERROR if door not closed
        error_signal = 'b1;
      end else if (timeout) begin
        next_state = WASH; // Transition to WASH
      end else begin
        next_state = current_state; // Remain in IDLE
      end
    end

    WASH: begin
      if (!door_closed) begin
        next_state = ERROR; // Transition to ERROR if door not closed
        error_signal = 'b1;
      end else if (timeout) begin
        next_state = RINSE; // Transition to WASH
      end else begin
        next_state = current_state; // Remain in IDLE
      end
    end

    RINSE: begin
      if (!door_closed) begin
        next_state = ERROR; // Transition to ERROR if door not closed
        error_signal = 'b1;
      end else if (timeout) begin
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
      if (!door_closed) begin
        next_state = ERROR; // Transition to ERROR if door not closed
        error_signal = 'b1;
      end else if (timeout) begin
        next_state = DRY; // Transition to DRY
      end else begin
        next_state = current_state; // Remain in IDLE
      end
    end

    DRY: begin
      if (!door_closed) begin
        next_state = ERROR; // Transition to ERROR if door not closed
        error_signal = 'b1;
      end else if (timeout) begin
        next_state =IDLE; // Transition back to IDLE after complete cycle
      end else begin
        next_state = current_state; // Remain in IDLE
      end
    end
    STEAM_CLEAN: begin
      if (!door_closed) begin
        next_state = ERROR; // Transition to ERROR if door not closed
        error_signal = 'b1;
      end else if (timeout) begin
        next_state =IDLE; // Transition back to IDLE after steam clean
      end else begin
        next_state = current_state; // Remain in IDLE
      end
    end

    ERROR: begin  
      if (door_closed) begin  
        next_state = prev_state;
        error_signal = 'b0;
      end else begin 
        next_state = current_state; // Remain in ERROR
        end  
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

//psl default clock = rose(clk);
//psl property Reset_To_IDLE = always (rst_n == 0 -> next(current_state == IDLE));
//psl assert Reset_To_IDLE;

//psl property Done_Only_In_IDLE = always ((current_state == IDLE) -> (done == 1));
//psl assert Done_Only_In_IDLE;

//psl property IDLE_To_FILL_WATER = always ((current_state == IDLE && start && !dry_wash) -> eventually!(current_state == FILL_WATER));
//psl assert IDLE_To_FILL_WATER;

//psl property IDLE_To_STEAM_CLEAN = always ((current_state == IDLE && start && dry_wash) -> eventually!(current_state == STEAM_CLEAN));
//psl assert IDLE_To_STEAM_CLEAN;

//psl property Double_Wash_Transition = always ((current_state == RINSE && double_wash && number_of_washes == 1) -> eventually!(current_state == WASH));
//psl assert Double_Wash_Transition;

// Timeout for FILL_WATER
//psl property Timeout_Fill_Water = always ((current_state == FILL_WATER && counter == numberOfCounts_10seconds) -> timeout);
//psl assert Timeout_Fill_Water;

// Timeout for WASH and RINSE
//psl property Timeout_Wash_Rinse = always (((current_state == WASH || current_state == RINSE) && counter == numberOfCounts_50seconds) -> timeout);
//psl assert Timeout_Wash_Rinse;

// Timeout for SPIN
//psl property Timeout_Spin = always ((current_state == SPIN && counter == numberOfCounts_20seconds) -> timeout);
//psl assert Timeout_Spin;

// Timeout for DRY and STEAM_CLEAN
//psl property Timeout_Dry_Steam = always (((current_state == DRY || current_state == STEAM_CLEAN) && counter == numberofCounts_1minute) -> timeout);
//psl assert Timeout_Dry_Steam;

//psl property Time_Pause_Functionality = always (time_pause -> (counter == prev(counter_comb)));
//psl assert Time_Pause_Functionality;

// Ensure state restoration from ERROR
//psl property Error_State_Restore = always ((current_state == ERROR && door_closed) -> next(current_state == prev_state));
//psl assert Error_State_Restore;

// Ensure counter restoration from ERROR
//psl property Error_Counter_Restore = always ((current_state == ERROR && door_closed) -> next(counter == backup_counter));
//psl assert Error_Counter_Restore;

//psl property Steam_Clean_Behavior = always ((current_state == STEAM_CLEAN && timeout) -> next(current_state == IDLE));
//psl assert Steam_Clean_Behavior;


endmodule
