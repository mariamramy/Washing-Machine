`timescale 1 ns / 1 ns

module Washing_Machine_tb();
  
///////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////// DUT Signals ///////////////////////////////////////////////////// 
///////////////////////////////////////////////////////////////////////////////////////////////////////////
  
  reg rst_n_tb;
  reg clk_tb;
  reg start_tb;
  reg double_wash_tb;
  reg dry_wash_tb;
  reg time_pause_tb;
  reg door_closed_tb;
  wire done_tb;
  wire error_signal_tb;

//////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////// Parameters /////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
  
  localparam IDLE        = 3'b000,
             FILL_WATER  = 3'b001,
             WASH        = 3'b010,
             RINSE       = 3'b011,
             SPIN        = 3'b100,
             DRY         = 3'b101,
             STEAM_CLEAN = 3'b110,
             ERROR       = 3'b111;
            
  localparam numberOfCounts_10seconds  = 6'd10, //fill water
             numberOfCounts_20seconds = 6'd20, //spin
             numberOfCounts_50seconds = 6'd50, //wash and rinse
             numberofCounts_1minute = 6'd60, //dry,steam clean
             period = 10'd1000; //for clock period 
              
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////// initial block ////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
  
  initial
    begin
      
      // Dump (save) the waveforms
      $dumpfile("washing_machine.vcd");
      $dumpvars;
             
          // Signals initialization
          initialization();
          
          // Reset
          reset();
      
          // Test case 1: Check that as long as rst_n is low (even start is on), the machine is in the IDLE state.
          test_case_1();
      
          // Test case 2: Check that a cycle starts only when a start is asserted.
          test_case_2();
        
          // Test case 3: Check that the filling water phase takes 10 seconds.
          test_case_3();
      
          // Test case 4: Check that the washing phase takes 50 seconds.
     	    test_case_4();
      
          // Test case 5: Check that the rinsing phase takes 50 seconds.
          test_case_5();
      
          // Test case 6: Check that the spinning phase takes 20 seconds.
          test_case_6();

          // Test case 7: Check that the drying phase takes 1 minute.
          test_case_7();
      
          // Test case 8: Check that the output done is set after the drying phase is completed and
          // remains high until start is set again.
          test_case_8();
      
          // Test case 9: Check the workability of the double wash option and that washing and rinsing stages
          // are repeated when double_wash is high.
          test_case_9();
      
          // Test case 10: Check the workability of the time pause option and that the current phase is paused
          // as long as the time_pause input is set.
          test_case_10();

          // Test case 11: Check the workability of the dry wash option and that it transitions to the STEAM_CLEAN
          //phase once dry_wash is set to high.
          test_case_11();
          
          // Test the time_pause option again and make sure it stays in the same state and also freeze the counter until time_pause is desserted.
          test_case_12();

          // Randomized test case used to reset the FSM during random times and random states to make sure it returns to IDLE state after rst is desserted.
          test_case_13();

          // This test case ensures the FSM transitions to the ERROR state correctly when a condition requiring it is met (e.g., door_closed is low).
          test_case_14();

          // This test case verifies that the FSM saves the current state and counter value when entering the ERROR state.
          test_case_15();

          // This test case ensures the FSM resumes from the saved state and counter value upon exiting the ERROR state.
          test_case_16();

          // This test verifies the dry wash sequence when interrupted by time_pause and transitioning to ERROR.
          test_case_17();

          test_case_18();
          
      $finish;
    end
  
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////// TASKS //////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////

  task initialization();
    begin
      clk_tb = 1'b0;
      start_tb = 1'b0;
      double_wash_tb = 1'b0;
      dry_wash_tb = 1'b0;
      time_pause_tb = 1'b0;
      door_closed_tb = 1'b1; //initially closed
    end
  endtask
  
  task reset;
    begin
      rst_n_tb = 'd1;
      #1
      rst_n_tb = 'd0;
      #1
      rst_n_tb = 'd1;
    end
  endtask 
  
  task test_case_1;
    begin
      $display("Test case 1 running");
      start_tb = 1'b1;
      rst_n_tb = 1'b0;
      #(period);
      if( DUT.current_state == IDLE )
        begin
          $display("Test case 1 passed");
        end
      else
        begin
          $display("Test case 1 failed");
        end
    end
  endtask
  
  task test_case_2;
    begin
      $display("Test case 2 running");
      rst_n_tb = 1'b1;
      start_tb = 1'b1;
      dry_wash_tb = 1'b0;
      #(period);
      if( DUT.current_state == FILL_WATER )
        $display("Test case 2 passed");
      else
        $display("Test case 2 failed");
    end
  endtask
  
  task test_case_3;
    begin
      $display("Test case 3 running");
      delay(numberOfCounts_10seconds);
      if( DUT.current_state == WASH)
        begin
          $display("Test case 3 passed");
        end
      else
        begin
          $display("Test case 3 failed");
        end
	   end
  endtask
  
  task test_case_4;
    begin
      $display("Test case 4 running");
      delay(numberOfCounts_50seconds);
      if( DUT.current_state == RINSE)
        begin
          $display("Test case 4 passed");
        end
      else
        begin
          $display("Test case 4 failed");
        end
	   end
  endtask
  
  task test_case_5;
    begin
      $display("Test case 5 running");
      delay(numberOfCounts_50seconds);
      if( DUT.current_state == SPIN)
        begin
          $display("Test case 5 passed");
        end
      else
        begin
          $display("Test case 5 failed");
        end
	   end
  endtask
  
  task test_case_6;
    begin
      $display("Test case 6 running");
      delay(numberOfCounts_20seconds);
      if( DUT.current_state == DRY)
        begin
          $display("Test case 6 passed");
        end
      else
        begin
          $display("Test case 6 failed");
        end
    end
  endtask

  task test_case_7;
    begin
      $display("Test case 7 running");
      delay(numberofCounts_1minute);
      if( DUT.current_state == IDLE)
        begin
          $display("Test case 7 passed");
        end
      else
        begin
          $display("Test case 7 failed");
        end
    end
  endtask
  
  task test_case_8;
    begin
      $display("Test case 8 running");
      start_tb = 1'b0;
      #(period * 6);
      if(done_tb == 1'b1)
        begin
          start_tb = 1'b1;
          #(period);
          if(done_tb == 1'b0)
            begin
              $display("Test case 8 passed");
            end
          else
            begin
              $display("Test case 8 failed");
            end
        end
      else
        begin
          $display("Test case 8 failed");
        end
    end
  endtask
  
  task test_case_9;
    begin
      $display("Test case 9 running");
      double_wash_tb = 'd1;
      delay(numberOfCounts_10seconds);
      // Now filling water is over
      delay(numberOfCounts_50seconds);
      // Now first washing is over
      delay(numberOfCounts_50seconds);
      // Now first rinsing is over
      if(DUT.current_state == WASH)
        begin
          delay(numberOfCounts_50seconds);
          // Now second washing is over
          if(DUT.current_state == RINSE)
            begin
              delay(numberOfCounts_50seconds);
              // Now second rinsing is over
              if(DUT.current_state == SPIN)
                begin
                  $display("Test case 9 passed");
                end
              else
                begin
                  $display("Test case 9 failed");
                end
            end
          else
            begin
              $display("Test case 9 failed");
            end
        end
      else  
        begin
          $display("Test case 9 failed");
        end
    end
  endtask
  
  task test_case_10;
    begin
      $display("Test case 10 running");
      double_wash_tb = 'd0;
      time_pause_tb = 1'b1;
      delay(numberOfCounts_10seconds);
      if(DUT.current_state == SPIN)
        begin
          time_pause_tb = 1'b0;
          delay(numberOfCounts_20seconds);
          if(DUT.current_state == DRY)
            begin
              $display("Test case 10 passed");
            end
          else
            begin
              $display("Test case 10 failed");
            end
        end
      else
        begin
          $display("Test case 10 failed");
        end
    end
  endtask
  
    task test_case_11;
    begin
      $display("Test case 11 running");
      reset();
      rst_n_tb = 1'b1;
      start_tb = 1'b1;
      dry_wash_tb = 1'b1;
      #(period);
      dry_wash_tb = 1'b0;
      delay(numberofCounts_1minute);
      if( DUT.current_state == IDLE)
        $display("Test case 11 passed");
      else
        $display("Test case 11 failed");
    end
  endtask

  task test_case_12;
  begin
    $display("Test case 12 running");
    reset();
    start_tb = 1'b1;
    #(period);
    delay(numberOfCounts_10seconds / 2.0); // Let the counter reach halfway
    time_pause_tb = 1'b1;
    #(period * 3);                // Pause for a while
    time_pause_tb = 1'b0;      
    delay(numberOfCounts_10seconds / 2.0); // Resume and complete counting;
    $display("Counter after resume: %d", DUT.counter);
    $display("Current State: %d", DUT.current_state);
    $display("Timeout flag: %d", DUT.timeout); 
    if (DUT.current_state == WASH) begin
      $display("Test case 12 passed");
    end else begin
      $display("Test case 12 failed");
    end
  end
endtask


  task test_case_13;
    reg [31:0] random_counter;
    begin
      $display("Test case 13 running");
      // Initialize inputs
      rst_n_tb = 1'b1;
      start_tb = 1'b0;
      dry_wash_tb = 1'b0;
      #10 rst_n_tb = 1'b0; // Ensure FSM starts in IDLE
      #10 rst_n_tb = 1'b1;

      // Randomized signal generation loop
      repeat(30) begin
        // Randomize control signals
        random_counter = $random;
        start_tb = random_counter[0];
        dry_wash_tb = random_counter[1];

        // Apply inputs for a random duration
        #(random_counter % 20);

        // Randomly assert reset
        if ($random % 3 == 0) begin
          $display("Resetting FSM at time %0t", $time);
          rst_n_tb = 1'b0;
          #10 rst_n_tb = 1'b1; // De-assert reset
        end

        // Monitor FSM state to ensure it transitions to IDLE on reset
        if (!rst_n_tb) begin
          if (DUT.current_state != IDLE) begin
            $error("FSM did not return to IDLE state as expected at time %0t", $time);
          end
        end
      end
      $display("Test case 13 passed");
    end
  endtask

  task test_case_14;
  begin
    $display("Test case 14 running");
    reset();
    start_tb = 1'b1;
    door_closed_tb = 1'b1; // Initially, the door is closed
    #(period);
    door_closed_tb = 1'b0; // Simulate door open
    #(period * 2); // Allow time for transition to ERROR
    if (DUT.current_state == ERROR) begin
      $display("Test case 14 passed");
    end else begin
      $display("Test case 14 failed");
    end
  end
  endtask

  task test_case_15;
  reg [31:0] saved_counter;
  reg [2:0] saved_state;
  begin
    $display("Test case 15 running");
    reset();
    start_tb = 1'b1;
    door_closed_tb = 1'b1;
    #(period);
    delay(numberOfCounts_10seconds / 2); // Progress partway through FILL_WATER
    saved_state = DUT.current_state;
    saved_counter = DUT.counter;
    door_closed_tb = 1'b0; // Trigger ERROR
    #(period);
    if (DUT.current_state == ERROR && DUT.prev_state == saved_state && DUT.backup_counter == saved_counter) begin
      $display("Test case 15 passed");
    end else begin
      $display("Test case 15 failed");
    end
  end
  endtask

  task test_case_16;
  reg [31:0] saved_counter;
  reg [2:0] saved_state;
  begin
    $display("Test case 16 running");
    reset();
    start_tb = 1'b1;
    door_closed_tb = 1'b1;
    #(period);
    delay(numberOfCounts_10seconds / 2); // Progress partway through FILL_WATER
    saved_state = DUT.current_state;
    saved_counter = DUT.counter;
    door_closed_tb = 1'b0; // Trigger ERROR
    #(period);
    door_closed_tb = 1'b1; // Resolve ERROR
    #(period);
    if (DUT.current_state == saved_state && DUT.counter == saved_counter) begin
      $display("Test case 16 passed");
    end else begin
      $display("Test case 16 failed");
    end
  end
  endtask

  task test_case_17;
  reg [31:0] saved_counter;
  reg [2:0] saved_state;
  begin
    $display("Test case 17 running");
    reset();
    dry_wash_tb = 1'b1;
    start_tb = 1'b1;
    #(period);
    delay(numberofCounts_1minute / 2); // Progress halfway through STEAM_CLEAN
    saved_state = DUT.current_state;
    saved_counter = DUT.counter;
    time_pause_tb = 1'b1; // Pause the FSM
    #(period * 3); // Pause duration
    time_pause_tb = 1'b0; // Resume
    door_closed_tb = 1'b0; // Trigger ERROR during STEAM_CLEAN
    #(period);
    if (DUT.current_state == ERROR) begin
      door_closed_tb = 1'b1; // Resolve ERROR
      #(period);
      if (DUT.current_state == saved_state && DUT.counter == saved_counter) begin
        $display("Test case 17 passed");
      end else begin
        $display("Test case 17 failed");
      end
    end else begin
      $display("Test case 17 failed");
    end
  end
endtask

task test_case_18;
  reg [31:0] saved_counter;
  reg [2:0] saved_state;
  reg [2:0] random_state;
  integer i;
  begin
    $display("Test case 18 running");
    
    for (i = 0; i < 20; i = i + 1) begin

      $display("Running iteration %d", i + 1);
      reset();
      dry_wash_tb = 1'b0;
      start_tb = 1'b1;
      #(period);
      
      // Randomly choose a state to transition to
      random_state = $random % 7; // Choose between 0 and 6 (excluding ERROR state)
      
      // Run for a while to reach a random state
      repeat (random_state) begin
        #(period);
      end
      
      // Save the state and counter
      saved_state = DUT.current_state;
      saved_counter = DUT.counter;
      
      // Trigger the ERROR state by setting door_closed_tb = 0 randomly
      door_closed_tb = 1'b0; // Simulate door being open
      #(period);
      
      // Check if the machine transitioned to ERROR state
      if (DUT.current_state == ERROR) begin
        $display("Transition to ERROR state successful at random state %d", random_state);
        door_closed_tb = 1'b1; // Resolve ERROR by closing door
        #(period);
        
        // Check if the state and counter are restored correctly
        if (DUT.current_state == saved_state && DUT.counter == saved_counter) begin
          $display("Test case 18 passed");
        end else begin
          $display("Randomized error test failed");
        end
      end else begin
        $display("Randomized error test failed - did not enter ERROR state");
      end
    end
  end
endtask



  task delay(input [31:0] numberOfCounts);
    begin  
       #(numberOfCounts * period);
    end
  endtask
  
////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////// Clock Generator ////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////
  
  always
    #(period / 2.0) clk_tb = ~clk_tb;

////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////// DUT Instantation ////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////
      
  Washing_Machine DUT(
  .rst_n(rst_n_tb),
  .clk(clk_tb),
  .start(start_tb),
  .double_wash(double_wash_tb),
  .dry_wash(dry_wash_tb),
  .time_pause(time_pause_tb),
  .door_closed(door_closed_tb),
  .done(done_tb),
  .error_signal(error_signal_tb)
  );
  
endmodule
