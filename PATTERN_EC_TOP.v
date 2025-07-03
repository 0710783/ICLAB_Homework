//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright Optimum Application-Specific Integrated System Laboratory
//    All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : PATTERN.v
//   	Module Name : PATTERN
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifdef RTL_TOP
    `define CYCLE_TIME 60.0
`endif

`ifdef GATE_TOP
    `define CYCLE_TIME 60.0
`endif

module PATTERN (
    // Output signals
    clk, rst_n, in_valid,
    in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a,
    // Input signals
    out_valid, out_Rx, out_Ry
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
output reg clk, rst_n, in_valid;
output reg [5:0] in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a;
input out_valid;
input [5:0] out_Rx, out_Ry;

//================================================================
// wire & registers 
//================================================================
reg[9*8:1]  reset_color       = "\033[1;0m";
reg[10*8:1] txt_black_prefix  = "\033[1;30m";
reg[10*8:1] txt_blue_prefix   = "\033[1;34m";
reg[10*8:1] txt_green_prefix  = "\033[1;32m";

integer SEED = 22;
integer i, t;
integer patcnt, PATNUM = 100;
integer latency, total_latency, max_latency;
integer prime_num, prime_choice;
integer px, py, qx, qy;
integer s_num, s_denum, s_denum_inv, s;
integer gold_rx, gold_ry;
integer curve_a;
//================================================================
//    clock
//================================================================
real CYCLE = `CYCLE_TIME;
initial 
begin
	clk = 0;
end
always #(CYCLE/2.0) clk = ~clk;

//================================================================
//    initial
//================================================================
initial 
begin
	rst_n = 1'b1;
	in_valid = 1'b0;
	
	in_Px = 'dx;
	in_Py = 'dx;
	in_Qx = 'dx;
	in_Qy = 'dx;
	in_prime = 'dx;
	in_a = 'dx;
	
	total_latency = 0;
	max_latency = 0;
	
	reset_task;
	for (patcnt = 1; patcnt <= PATNUM; patcnt = patcnt + 1) begin
		gen_input_task;
		gen_gold_task;
		input_task;
		wait_out_valid_task;
		check_ans_task;
	end
	display_pass;
end

//================================================================
// task
//================================================================
task reset_task; begin

    force clk = 0;
    rst_n     = 1'b1;
	in_valid = 1'b0;
	
	in_Px = 'dx;
	in_Py = 'dx;
	in_Qx = 'dx;
	in_Qy = 'dx;
	in_prime = 'dx;
	in_a = 'dx;
	
    #(CYCLE/2.0) rst_n = 0;
    #(CYCLE/2.0) rst_n = 1;
    if (out_valid !== 0 || out_Rx !== 0 || out_Ry !== 0) begin
        $display("                                           `:::::`                                                       ");
        $display("                                          .+-----++                                                      ");
        $display("                .--.`                    o:------/o                                                      ");
        $display("              /+:--:o/                   //-------y.          -//:::-        `.`                         ");
        $display("            `/:------y:                  `o:--::::s/..``    `/:-----s-    .:/:::+:                       ");
        $display("            +:-------:y                `.-:+///::-::::://:-.o-------:o  `/:------s-                      ");
        $display("            y---------y-        ..--:::::------------------+/-------/+ `+:-------/s                      ");
        $display("           `s---------/s       +:/++/----------------------/+-------s.`o:--------/s                      ");
        $display("           .s----------y-      o-:----:---------------------/------o: +:---------o:                      ");
        $display("           `y----------:y      /:----:/-------/o+----------------:+- //----------y`                      ");
        $display("            y-----------o/ `.--+--/:-/+--------:+o--------------:o: :+----------/o                       ");
        $display("            s:----------:y/-::::::my-/:----------/---------------+:-o-----------y.                       ");
        $display("            -o----------s/-:hmmdy/o+/:---------------------------++o-----------/o                        ");
        $display("             s:--------/o--hMMMMMh---------:ho-------------------yo-----------:s`                        ");
        $display("             :o--------s/--hMMMMNs---------:hs------------------+s------------s-                         ");
        $display("              y:-------o+--oyhyo/-----------------------------:o+------------o-                          ");
        $display("              -o-------:y--/s--------------------------------/o:------------o/                           ");
        $display("               +/-------o+--++-----------:+/---------------:o/-------------+/                            ");
        $display("               `o:-------s:--/+:-------/o+-:------------::+d:-------------o/                             ");
        $display("                `o-------:s:---ohsoosyhh+----------:/+ooyhhh-------------o:                              ");
        $display("                 .o-------/d/--:h++ohy/---------:osyyyyhhyyd-----------:o-                               ");
        $display("                 .dy::/+syhhh+-::/::---------/osyyysyhhysssd+---------/o`                                ");
        $display("                  /shhyyyymhyys://-------:/oyyysyhyydysssssyho-------od:                                 ");
        $display("                    `:hhysymmhyhs/:://+osyyssssydyydyssssssssyyo+//+ymo`                                 ");
        $display("                      `+hyydyhdyyyyyyyyyyssssshhsshyssssssssssssyyyo:`                                   ");
        $display("                        -shdssyyyyyhhhhhyssssyyssshssssssssssssyy+.    Output signal should be 0         ");
        $display("                         `hysssyyyysssssssssssssssyssssssssssshh+                                        ");
        $display("                        :yysssssssssssssssssssssssssssssssssyhysh-     after the reset signal is asserted");
        $display("                      .yyhhdo++oosyyyyssssssssssssssssssssssyyssyh/                                      ");
        $display("                      .dhyh/--------/+oyyyssssssssssssssssssssssssy:   at %4d ps                         ", $time*1000);
        $display("                       .+h/-------------:/osyyysssssssssssssssyyh/.                                      ");
        $display("                        :+------------------::+oossyyyyyyyysso+/s-                                       ");
        $display("                       `s--------------------------::::::::-----:o                                       ");
        $display("                       +:----------------------------------------y`                                      ");
        repeat(5) #(CYCLE);
        $finish;
    end
    #(CYCLE/2.0) release clk;
end endtask

task gen_input_task; begin	
	if (patcnt < 5)
		prime_choice = {$random(SEED)} % 2;
	else
		prime_choice = {$random(SEED)} % 16;
		
	case (prime_choice)
	'd0 :	prime_num = 5;
	'd1 :	prime_num = 7;
	'd2 :	prime_num = 11;
	'd3 :	prime_num = 13;
	'd4 :	prime_num = 17;
	'd5 :	prime_num = 19;
	'd6 :	prime_num = 23;
	'd7 :	prime_num = 29;
	'd8 :	prime_num = 31;
	'd9 :	prime_num = 37;
	'd10 :	prime_num = 41;
	'd11 :	prime_num = 43;
	'd12 :	prime_num = 47;
	'd13 :	prime_num = 53;
	'd14 :	prime_num = 59;
	'd15 :	prime_num = 61;
	'd16 :	prime_num = 67;
	'd17 :	prime_num = 71;
	'd18 :	prime_num = 73;
	'd19 :	prime_num = 79;
	'd20 :	prime_num = 83;
	'd21 :	prime_num = 89;
	'd22 :	prime_num = 97;
	'd23 :	prime_num = 101;
	'd24 :	prime_num = 103;
	'd25 :	prime_num = 107;
	'd26 :	prime_num = 109;
	'd27 :	prime_num = 113;
	default :	prime_num = 127;
	endcase
	// prime_num = 61;
	px = {$random(SEED)} % (prime_num-1) + 1;
	py = {$random(SEED)} % (prime_num-1) + 1;
	
	if (patcnt < PATNUM/2) begin
		qx = {$random(SEED)} % (prime_num-1) + 1;
		qy = {$random(SEED)} % (prime_num-1) + 1;
	end
	else begin
		qx = px;
		qy = py;
	end

	
	
	while ((px == qx) && (qy != py)) begin
		px = {$random(SEED)} % (prime_num-1) + 1;
		py = {$random(SEED)} % (prime_num-1) + 1;
		qx = {$random(SEED)} % (prime_num-1) + 1;
		qy = {$random(SEED)} % (prime_num-1) + 1;
	end
	
	curve_a = {$random(SEED)} % (prime_num-1) + 1;
	
end endtask

task gen_gold_task; begin
	if ((px == qx) && (py == qy)) begin
		s_num = (3*(px**2) + curve_a) % prime_num;
		s_denum = (2*py) % prime_num;
	end
	else begin
		s_num = (qy - py + prime_num) % prime_num;
		s_denum = (qx - px + prime_num) % prime_num;
	end
	
	for (i = 0; i < prime_num; i = i + 1) begin
		if ((s_denum * i) % prime_num == 1)
			s_denum_inv = i;
	end
	s = (s_num * s_denum_inv) % prime_num;
	
	gold_rx = (s**2 - px - qx) % prime_num;
	gold_ry = (s*(px - gold_rx) - py) % prime_num;
	while (gold_rx < 0)
		gold_rx = gold_rx + prime_num;
	while (gold_ry < 0)
		gold_ry = gold_ry + prime_num;
end endtask

task input_task; begin
	t = $urandom_range(3, 1);
	for (i = 0; i < t; i = i + 1) begin
		if (out_valid !== 1'b0 || out_Rx !== 'b0 || out_Ry !== 'b0) begin
			$display("************************************************************");  
			$display("                          FAIL!                              ");    
			$display("*  Output signal should be 0 after initial RESET  at %8t   *",$time);
			$display("************************************************************");
			repeat(10) #CYCLE;
			$finish;
		end
		@(negedge clk);
	end
	
	in_valid = 1;
	in_Px = px;
	in_Py = py;
	in_Qx = qx;
	in_Qy = qy;
	in_prime = prime_num;
	in_a = curve_a;
	
	if (out_valid === 'd1) begin
		$display("************************************************************");  
		$display("                          FAIL!                              ");    
		$display("*  Output signal should be 0 when in_valid is 1  at %8t   *",$time);
		$display("************************************************************");
		repeat(5) #(CYCLE);
		$finish;
	end
	@(negedge clk);
	
	// Disable input
	in_valid = 1'b0;
	in_Px = 'dx;
	in_Py = 'dx;
	in_Qx = 'dx;
	in_Qy = 'dx;
	in_prime = 'dx;
	in_a = 'dx;
	
end endtask

task wait_out_valid_task; begin
    latency = 0;
    while(out_valid !== 1'b1) begin
	latency = latency + 1;
      if( latency == 1000) begin
          $display("********************************************************");     
          $display("                          FAIL!                              ");
          $display("*  The execution latency are over 1000 cycles  at %8t   *",$time);//over max
          $display("********************************************************");
	    repeat(2)@(negedge clk);
	    $finish;
      end
     @(negedge clk);
   end
   total_latency = total_latency + latency;
end endtask

task check_ans_task; begin
	if (out_Rx !== gold_rx || out_Ry !== gold_ry) begin
			display_fail;
            $display ("-------------------------------------------------------------------");
            $display ("*                    (in_Px = %4d, in_Py = %4d)                ",px, py);
			$display ("*                    (in_Qx = %4d, in_Qy = %4d)                ",qx, qy);
			$display ("*                    (in_prime = %4d, in_a = %4d)                ", prime_num, curve_a);
            $display ("*                            wrong out                         ");
			$display ("*                    (denum = %4d, inv_denum = %4d)                ", s_denum, s_denum_inv);
            $display ("                     answer should be : (%4d, %4d)     ", gold_rx, gold_ry);
			$display ("                     your answer is   : (%4d, %4d)     ", out_Rx, out_Ry);
            $display ("-------------------------------------------------------------------");
            #(100);
            $finish ;
    end
	else begin
		$display ("    %0spass pattern %5d%0s", txt_blue_prefix, patcnt, reset_color);
		@(negedge clk);	
	end
end endtask

task display_fail;
begin
        $display("\n");
        $display("\n");
		$display("%0s", reset_color);
        $display("        ----------------------------               ");
        $display("        --                        --       |\__||  ");
        $display("        --  OOPS!!                --      / X,X  | ");
        $display("        --                        --    /_____   | ");
        $display("        --  Simulation Failed!!   --   /^ ^ ^ \\  |");
        $display("        --                        --  |^ ^ ^ ^ |w| ");
        $display("        ----------------------------   \\m___m__|_|");
        $display("\n");
end
endtask

task display_pass;
begin
        $display("\n");
        $display("\n");
		$display("%0s", reset_color);
        $display("        ----------------------------               ");
        $display("        --                        --       |\__||  ");
        $display("        --  Congratulations !!    --      / O.O  | ");
        $display("        --                        --    /_____   | ");
        $display("        --  Simulation out!!     --   /^ ^ ^ \\  |");
        $display("        --                        --  |^ ^ ^ ^ |w| ");
        $display("        ----------------------------   \\m___m__|_|");
        $display("\n");
		$display ("total_latency : %d", total_latency);
		$display ("max_latency : %d", max_latency);
		$display ("PATNUM : %d", PATNUM);
		$finish ;
end
endtask

always @(*) begin
	if(latency > max_latency) begin
		max_latency = latency;
	end 
end

endmodule