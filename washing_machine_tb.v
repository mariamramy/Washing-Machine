`timescale 1 ns / 1 ps

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
  wire done_tb;

//////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////// Parameters /////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
  
  localparam IDLE        = 3'b000,
             FILL_WATER  = 3'b001,
             WASH        = 3'b010,
             RINSE       = 3'b011,
             SPIN        = 3'b100,
             DRY         = 3'b101,
             STEAM_CLEAN = 3'b110;
            
  localparam numberOfCounts_1minute  = 32'd60, //fill water
             numberOfCounts_2minutes = 32'd120, // spin
             numberOfCounts_5minutes = 32'd300, // wash and rinse
             numberofCounts_10minutes = 32'd600; //dry,steam clean
             
//////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////// Variables //////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
             
  reg [9:0] period;
  
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
        
          // Test case 3: Check that the filling water phase takes 1 minute.
          test_case_3();
      
          // Test case 4: Check that the washing phase takes 5 minutes.
     	    test_case_4();
      
          // Test case 5: Check that the rinsing phase takes 5 minutes.
          test_case_5();
      
          // Test case 6: Check that the spinning phase takes 2 minutes.
          test_case_6();

          // Test case 7: Check that the drying phase takes 10 minutes.
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

          // Reset
          reset();

          // Test case 11: Check the workability of the dry wash option and that it transitions to the STEAM_CLEAN
          //phase once dry_wash is set to high.
          test_case_11();
          
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
      time_pause_tb = 1'b0;
      period = 'd1000;
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
      #(period)
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
      #(period)
      if( DUT.current_state == FILL_WATER )
        $display("Test case 2 passed");
      else
        $display("Test case 2 failed");
    end
  endtask
  
  task test_case_3;
    begin
      $display("Test case 3 running");
      delay(numberOfCounts_1minute);
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
      delay(numberOfCounts_5minutes);
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
      delay(numberOfCounts_5minutes);
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
      delay(numberOfCounts_2minutes);
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
      delay(numberofCounts_10minutes);
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
      delay(numberOfCounts_1minute);
      // Now filling water is over
      delay(numberOfCounts_5minutes);
      // Now first washing is over
      delay(numberOfCounts_5minutes);
      // Now first rinsing is over
      if(DUT.current_state == WASH)
        begin
          delay(numberOfCounts_5minutes);
          // Now second washing is over
          if(DUT.current_state == RINSE)
            begin
              delay(numberOfCounts_5minutes);
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
      time_pause_tb = 1'b1;
      delay(numberOfCounts_1minute);
      if(DUT.current_state == SPIN)
        begin
          time_pause_tb = 1'b0;
          delay(numberOfCounts_2minutes);
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
      rst_n_tb = 1'b1;
      start_tb = 1'b1;
      dry_wash_tb = 1'b1;
      #(period);
      dry_wash_tb = 1'b0;
      delay(numberofCounts_10minutes);
      if( DUT.current_state == IDLE)
        $display("Test case 11 passed");
      else
        $display("Test case 11 failed");
    end
  endtask


  task delay(input [31:0]  numberOfCounts);
    begin  
       #(numberOfCounts * period);
    end
  endtask
  
////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////// Clock Generator ////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////
  
  always
    #(period/2.0) clk_tb = ~clk_tb;

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
  .done(done_tb)
  );
  
endmodule
