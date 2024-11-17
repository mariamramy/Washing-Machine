`timescale 1s / 1ms 

module Washing_Machine_tb;

  // Inputs to the Washing Machine
  reg clk_tb;
  reg rst_tb;
  reg start_tb;
  reg double_wash_tb;
  reg dry_wash_tb;
  reg time_pause_tb;

  // Outputs from the Washing Machine
  wire done_tb;

  // Parameters for time periods (in seconds)
  localparam period = 1; // 1 second clock period

  localparam IDLE = 3'b000, // IDLE state
           FILL_WATER = 3'b001, // filling water and detergent state
           WASH = 3'b010, // washing state
           RINSE = 3'b011, // rinsing state
           SPIN = 3'b100, // spinning state
           DRY = 3'b101, // drying state
           STEAM_CLEAN = 3'b110, // washing clothes using steam state
           PAUSE = 3'b111; // time pausing during states 

  // Instantiate the Device Under Test (DUT)
  Washing_Machine DUT (
    .clk(clk_tb),
    .rst(rst_tb),
    .start(start_tb),
    .double_wash(double_wash_tb),
    .dry_wash(dry_wash_tb),
    .time_pause(time_pause_tb),
    .done(done_tb)
  );

  // Clock generator (1 Hz clock, 1-second period)
  always #(period / 2) clk_tb = ~clk_tb;

  // Initialization block
  initial begin
    // Dump waveform for simulation
    $dumpfile("washing_machine.vcd");
    $dumpvars(0, Washing_Machine_tb);

    // Initialize inputs
    clk_tb = 0;
    rst_tb = 0;
    start_tb = 0;
    double_wash_tb = 0;
    dry_wash_tb = 0;
    time_pause_tb = 0;

    // Reset
    rst_tb = 1;
    #2; // Reset for 2 seconds
    rst_tb = 0;
    #2; // Wait for reset to finish

    // Test case 1: Check IDLE state when rst is high
    $display("Test case 1: Check IDLE state after reset");
    start_tb = 1;
    #1;
    start_tb = 0;
    #1;
    if (DUT.current_state == IDLE) 
      $display("Test case 1 passed");
    else
      $display("Test case 1 failed");

    // Test case 2: Check that the washing cycle starts when start is high
    $display("Test case 2: Check washing cycle starts");
    start_tb = 1;
    #1;
    start_tb = 0;
    #6; // Wait for 7 seconds (FILL_WATER state duration)
    if (DUT.current_state == FILL_WATER)
      $display("Test case 2 passed");
    else
      $display("Test case 2 failed");

    // Test case 3: Check timeout after 7 seconds in FILL_WATER
    $display("Test case 3: Check timeout after 7 seconds in FILL_WATER");
    #1; // simulate time elapsing for 7 seconds
    if (DUT.current_state == WASH)
      $display("Test case 3 passed");
    else
      $display("Test case 3 failed");

    // Test case 4: Check washing state for 5 seconds
    $display("Test case 4: Check washing state for 5 seconds");
    #5; // simulate 5 seconds for WASH state
    if (DUT.current_state == RINSE)
      $display("Test case 4 passed");
    else
      $display("Test case 4 failed");

    // Test case 5: Check rinsing state for 5 seconds
    $display("Test case 5: Check rinsing state for 5 seconds");
    #5; // simulate 5 seconds for RINSE state
    if (DUT.current_state == SPIN)
      $display("Test case 5 passed");
    else
      $display("Test case 5 failed");

    // Test case 6: Check spinning state for 5 seconds
    $display("Test case 6: Check spinning state for 5 seconds");
    #5; // simulate 5 seconds for SPIN state
    if (DUT.current_state == DRY)
      $display("Test case 6 passed");
    else
      $display("Test case 6 failed");

    // Test case 7: Check drying state for 10 seconds
    $display("Test case 7: Check drying state for 10 seconds");
    #10; // simulate 10 seconds for DRY state
    if (DUT.current_state == IDLE)
      $display("Test case 7 passed");
    else
      $display("Test case 7 failed");

    // Test case 8: Check steam cleaning for 10 seconds
    $display("Test case 8: Check steam cleaning for 10 seconds");
    dry_wash_tb = 1;
    #10; // simulate 10 seconds for STEAM_CLEAN state
    if (DUT.current_state == IDLE && done_tb)
      $display("Test case 8 passed");
    else
      $display("Test case 8 failed");

    // Test case 9: Check done signal after drying or steam cleaning
    $display("Test case 9: Check done signal after drying/steam cleaning");
    start_tb = 1;
    #7; // simulate time elapsing for 7 seconds in FILL_WATER
    #5; // simulate 5 seconds for WASH
    #5; // simulate 5 seconds for RINSE
    #5; // simulate 5 seconds for SPIN
    #10; // simulate 10 seconds for DRY
    if (DUT.current_state == IDLE && done_tb)
      $display("Test case 9 passed");
    else
      $display("Test case 9 failed");

    // Test case 10: Check the pause functionality
    $display("Test case 10: Check time pause functionality");
    start_tb = 1;
    #5; // simulate initial start
    time_pause_tb = 1;
    #5; // simulate pause for 5 seconds
    time_pause_tb = 0;
    #5;
    if (DUT.current_state == SPIN) // Should resume from SPIN after pause
      $display("Test case 10 passed");
    else
      $display("Test case 10 failed");

    // Test case 11: Check the double wash functionality
    $display("Test case 11: Check double wash functionality");
    start_tb = 1;
    #5;
    double_wash_tb = 1;
    #15; // simulate 2 cycles of washing and rinsing
    if (DUT.current_state == SPIN) // Should go to SPIN after two washes
      $display("Test case 11 passed");
    else
      $display("Test case 11 failed");

    // Test case 12: Check the state after reset during ongoing cycle
    $display("Test case 12: Check reset during ongoing cycle");
    start_tb = 1;
    #5;
    rst_tb = 1;
    #2;
    rst_tb = 0;
    #5;
    if (DUT.current_state == IDLE) // Should return to IDLE after reset
      $display("Test case 12 passed");
    else
      $display("Test case 12 failed");

    // End simulation
    $finish;
  end

endmodule
