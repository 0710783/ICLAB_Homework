`ifdef RTL
    `define CYCLE_TIME 10.0
`endif
`ifdef GATE
    `define CYCLE_TIME 10.0
`endif
`define PATNUM 300 

module PATTERN(
    // Output Signals
    clk,
    rst_n,
    in_valid,
    init,
    in0,
    in1,
    in2,
    in3,
    // Input Signals
    out_valid,
    out
);


/* Input for design */
output reg       clk, rst_n;
output reg       in_valid;
output reg [1:0] init;
output reg [1:0] in0, in1, in2, in3; 


/* Output for pattern */
input            out_valid;
input      [1:0] out; 

integer i,j;
integer answer_count;
integer seed;
integer max_latency,total_latency,latency;
integer patcount;
integer pos1,pos2,pos3,pos4,posinit;
integer obsta1,obsta2,obsta3,obsta4;
integer current_place_i,current_place_j;
integer patnum = `PATNUM;
reg [1:0]allmap[3:0][63:0];
reg [1:0]save_in[3:0];
reg flaginput;
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;


initial begin
	rst_n=0;
	max_latency = 0;
	flaginput = 0;
	reset_task; //3
	pos1=4;
	pos2=4;
	pos3=4;
	pos4=4;
	for(i=0;i<4;i=i+1)begin
		for(j=0;j<64;j=j+1)begin
			allmap[i][j]=0;
		end	
	end
	for(patcount = 0; patcount < patnum; patcount = patcount + 1)begin
		flaginput = 0;
		for(i=0;i<4;i=i+1)begin
			for(j=0;j<64;j=j+1)begin
				allmap[i][j]=0;
			end	
		end
		genmap;
		wait_out_valid_task; //4,5,6
		flaginput = 0;
		current_place_i = posinit; //the first place is allmap[posinit][0];
		current_place_j = 0;
		for (answer_count = 0; answer_count < 63; answer_count = answer_count + 1)begin   		
	        if (out_valid === 1) begin
		        out_check; //8
	        end
	        else if (out_valid !== 1) begin
				if(out !== 0)begin
					$display("SPEC 4 IS FAIL!");  
					$finish;
				end
				else begin
					$display("SPEC 7 IS FAIL!");  
					$finish;
				end
	        end
	       	@(negedge clk);
	    end
	    if(out_valid !== 1'b0 || out !=='b0) begin //out!==0
	        $display("SPEC 7 IS FAIL!");
	        $finish;
	    end
	end
	pass_task;
	seed = 32;
end

task reset_task; begin 
    rst_n = 'b1;
    in_valid = 'b0;
	in0 = 'bx;
	in1 = 'bx;
	in2 = 'bx;
	in3 = 'bx;
    total_latency = 0;
    force clk = 0;
    #CYCLE; rst_n = 0; 
    #CYCLE; rst_n = 1;
    if(out_valid !== 1'b0 || out !=='b0) begin //out!==0
        $display("SPEC 3 IS FAIL!");
        $finish;
    end
	#CYCLE; release clk;
end endtask

task genmap;begin
	//////////////////////////////////////gen train
	for(j=0;j<63;j=j+8)begin
		pos1 = $random(seed)%'d4;
		pos2 = $random(seed)%'d3;
		pos3 = $random(seed)%'d2;
		pos2 = pos1+pos2;
		if(pos2>3)begin	
			pos2=pos2-4;
		end
		pos3=pos2+pos3;
		if(pos3>3)begin
			pos3=pos3-4;
		end
		allmap[pos1][j]=3;
		allmap[pos2][j]=3;
		allmap[pos3][j]=3;
	end
	for(i=0;i<4;i=i+1)begin
		for(j=1;j<63;j=j+1)begin
			if(j%8 === 0 || j%8 === 1 || j%8 === 2 || j%8 === 3)begin
				allmap[i][j]=allmap[i][j-j%8];
			end
		end
	end
	//////////////////////////////////////gen obstacles
	for(j=2;j<63;j=j+2)begin
		if(j%8 != 0)begin
			pos1 = $random(seed)%'d4;
			pos2 = $random(seed)%'d3;
			pos3 = $random(seed)%'d2;
			pos4 = $random(seed)%'d4;
			obsta1 = $random(seed)%'d2;
			obsta2 = $random(seed)%'d2;
			obsta3 = $random(seed)%'d2;
			obsta4 = $random(seed)%'d2;
			pos2 = pos1+pos2;
			if(pos2>3)begin	
				pos2=pos2-4;
			end
			pos3=pos2+pos3;
			if(pos3>3)begin
				pos3=pos3-4;
			end
			if(allmap[pos1][j]!==3)begin
				if(obsta1 === 0)begin
					allmap[pos1][j]=2;
				end
				else begin
					allmap[pos1][j]=1;
				end
			end
			if(allmap[pos2][j]!==3)begin
				if(obsta2 === 0)begin
					allmap[pos2][j]=2;
				end
				else begin
					allmap[pos2][j]=1;
				end
			end
			if(allmap[pos3][j]!==3)begin		
				if(obsta3 === 0)begin
					allmap[pos3][j]=2;
				end
				else begin
					allmap[pos3][j]=1;
				end
			end
			if(allmap[pos4][j]!==3)begin		
				if(obsta4 === 0)begin
					allmap[pos4][j]=2;
				end
				else begin
					allmap[pos4][j]=1;
				end
			end
		end	
	end
	//////////////////////////////////////geninit
	posinit = $random(seed)%'d4;
	if(allmap[posinit][0]===3)begin
		posinit=posinit+1;
		if(posinit > 3)begin
			posinit=posinit-4;
		end
		if(allmap[posinit][0]===3)begin
			posinit=posinit+1;
			if(posinit > 3)begin
				posinit=posinit-4;
			end
			if(allmap[posinit][0]===3)begin
				posinit=posinit+1;
				if(posinit > 3)begin
					posinit=posinit-4;
				end
			end
		end
	end
	//////////////////////////////////////
end endtask
task wait_out_valid_task; begin
    latency = 0;
    while(out_valid !== 1'b1) begin
		if(out!=0)begin
			$display("SPEC 4 IS FAIL!");
			$finish;
		end
		@(negedge clk);
		if(flaginput === 0)begin
			in_valid=1;
			current_place_i = 0;
			current_place_j = 0;
			init = posinit;
			for(j=0;j<64;j=j+1)begin
				in0=allmap[0][j];
				in1=allmap[1][j];
				in2=allmap[2][j];
				in3=allmap[3][j];
				if(out_valid === 1)begin
					$display("SPEC 5 IS FAIL!");
					$finish;
				end
				@(negedge clk);
			end
			in_valid = 0;
			in0 = 'bx;
			in1 = 'bx;
			in2 = 'bx;
			in3 = 'bx;
			init = 'bx;
			flaginput = 1;
		end	
		latency = latency + 1;
			if( latency == 3000) begin
				$display("SPEC 6 IS FAIL!");
				$finish;
			end
	end
   total_latency = total_latency + latency;
end endtask

task out_check; begin
	if(out === 2'd0)begin
		current_place_j = current_place_j+1; //forward
		if(allmap[current_place_i][current_place_j] === 2'b01)begin
			$display("SPEC 8-2 IS FAIL!");
			$finish;
		end
		if(allmap[current_place_i][current_place_j] === 2'b11)begin
			$display("SPEC 8-4 IS FAIL!");
			$finish;
		end
	end
	else if(out === 2'd1)begin
		current_place_i = current_place_i+1; //right
		current_place_j = current_place_j+1;
		if(current_place_i > 3)begin
			$display("SPEC 8-1 IS FAIL!");
			$finish;
		end
		if(allmap[current_place_i][current_place_j] === 2'b01)begin
			$display("SPEC 8-2 IS FAIL!");
			$finish;
		end
		if(allmap[current_place_i][current_place_j] === 2'b10)begin
			$display("SPEC 8-3 IS FAIL!");
			$finish;
		end
		if(allmap[current_place_i][current_place_j] === 2'b11)begin
			$display("SPEC 8-4 IS FAIL!");
			$finish;
		end
	end
	else if(out === 2'd2)begin
		current_place_i = current_place_i-1; //left
		current_place_j = current_place_j+1;
		if(current_place_i < 0)begin
			$display("SPEC 8-1 IS FAIL!");
			$finish;
		end
		if(allmap[current_place_i][current_place_j] === 2'b01)begin
			$display("SPEC 8-2 IS FAIL!");
			$finish;
		end
		if(allmap[current_place_i][current_place_j] === 2'b10)begin
			$display("SPEC 8-3 IS FAIL!");
			$finish;
		end
		if(allmap[current_place_i][current_place_j] === 2'b11)begin
			$display("SPEC 8-4 IS FAIL!");
			$finish;
		end
	end
	else if(out === 2'd3)begin //jump
		current_place_j = current_place_j+1;
		if(allmap[current_place_i][current_place_j] === 2'b10)begin
			$display("SPEC 8-3 IS FAIL!");
			$finish;
		end
		if(allmap[current_place_i][current_place_j] === 2'b11)begin
			$display("SPEC 8-4 IS FAIL!");
			$finish;
		end
		if(current_place_j !== 0)begin
			if(allmap[current_place_i][current_place_j-1] === 2'b10)begin
				$display("SPEC 8-5 IS FAIL!");
				$finish;
			end
		end
	end
end endtask

always @(*) begin
	if(latency > max_latency) begin
		max_latency = latency;
	end 
end
always @(*)begin
	if(out_valid === 0 && out !== 0 && rst_n==1)begin
		$display("SPEC 4 IS FAIL!");
		$finish;
	end
end
task pass_task;begin
	$display("You Pass Task!");
	$display("%d",total_latency);
	$display("%d",max_latency);
	$finish;
end endtask

endmodule