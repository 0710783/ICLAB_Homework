module SUBWAY(
    //Input Port
    clk,
    rst_n,
    in_valid,
    init,
    in0,
    in1,
    in2,
    in3,
    //Output Port
    out_valid,
    out
);


input clk, rst_n;
input in_valid;
input [1:0] init;
input [1:0] in0, in1, in2, in3; 
output reg       out_valid;
output reg [1:0] out;


//==============================================//
//       parameter & integer declaration        //
//==============================================//
integer i,j;

//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [1:0]wholemap[3:0][63:0]; // save all the input
reg [1:0]block[3:0][63:0];
reg [2:0]pos_init; //first standing place
reg [7:0]inputcounting;
reg [2:0]c_state,n_state;
reg [2:0]stack[63:0];
reg [7:0]stack_index,walking_index_j;
reg [2:0]walking_index_i;
reg out_ready;
reg out_has_been_opened;
reg [7:0]outcount;
//==============================================//
//                  design                      //
//==============================================//
always @ (posedge clk or negedge rst_n)begin  //save_input
	if(!rst_n)begin
		for(i=0;i<4;i=i+1)begin
			for(j=0;j<64;j=j+1)begin
				wholemap[i][j] <= 0;
			end
		end
		pos_init <= 4;
		inputcounting <= 0;
	end
	else begin
		if(in_valid)begin
			if(inputcounting == 0)begin
				pos_init <= init;
			end
			else begin
				pos_init <= pos_init;
			end
			wholemap[0][inputcounting] <= in0;
			wholemap[1][inputcounting] <= in1;
			wholemap[2][inputcounting] <= in2;
			wholemap[3][inputcounting] <= in3;
			inputcounting <= inputcounting+1;
			/*$display("%d",wholemap[pos_init][0]);
				for(i=0;i<4;i=i+1)begin
					for(j=0;j<64;j=j+1)begin
						$write("%d",wholemap[i][j]);
					end
					$display("\n");
				end
			$display("\n");*/
		end
		else begin
			inputcounting <= 0;
			if(out_valid)begin
				pos_init <= 4;	
				for(i=0;i<4;i=i+1)begin
					for(j=0;j<64;j=j+1)begin
						wholemap[i][j] <= 0;
					end
				end
			end
			else begin
				pos_init <= pos_init;
			end
		end
	end
end
/////////////////////////////////////////////////
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<4;i=i+1)begin
			for(j=0;j<64;j=j+1)begin
				block[i][j] <= 0;
			end
		end
		for(i=0;i<64;i=i+1)begin
			stack[i] <= 0;
		end
		stack_index <= 0;
		walking_index_i <= 0;
		walking_index_j <= 0;
		out_ready <= 0;
	end
	else begin
		if(in_valid)begin
			for(i=0;i<4;i=i+1)begin
				for(j=0;j<64;j=j+1)begin
					block[i][j] <= 0;
				end
			end
			walking_index_i <= pos_init;
			walking_index_j <= 0;
			stack_index <= 0;
			out_ready <= 0;
		end
		else begin
			if(walking_index_j == 62)begin
				if(outcount == 62 || (out_valid && !out_ready))begin
					out_ready <= 0;
				end
				else begin
					if(out_has_been_opened && !out_valid)begin
						out_ready <= 0;
					end
					else begin
						out_ready <= 1;
					end
				end
			end
			else begin
				out_ready <= 0;
				//forward
				if((wholemap[walking_index_i][walking_index_j+1]==2'b00 || wholemap[walking_index_i][walking_index_j+1]==2'b10) && block[walking_index_i][walking_index_j+1]==0)begin
					walking_index_j <= walking_index_j+1;
					stack[stack_index] <= 2'd0;
					stack_index <= stack_index+1;
				end
				else begin
					//left
					if((wholemap[walking_index_i][walking_index_j+1]==2'b01 || wholemap[walking_index_i][walking_index_j+1]==2'b10 || wholemap[walking_index_i][walking_index_j+1]==2'b11 || (wholemap[walking_index_i][walking_index_j+1]==2'b00 && block[walking_index_i][walking_index_j+1]==1)) && wholemap[walking_index_i-1][walking_index_j+1]==2'b00 && walking_index_i!=0 && block[walking_index_i-1][walking_index_j+1]==0)begin
						walking_index_j <= walking_index_j+1;
						walking_index_i <= walking_index_i-1;
						stack[stack_index] <= 2'd2;
						stack_index <= stack_index+1;
					end
					else begin
						//right
						if((wholemap[walking_index_i][walking_index_j+1]==2'b01 || wholemap[walking_index_i][walking_index_j+1]==2'b10 || wholemap[walking_index_i][walking_index_j+1]==2'b11 || (wholemap[walking_index_i][walking_index_j+1]==2'b00 && block[walking_index_i][walking_index_j+1]==1)) && wholemap[walking_index_i+1][walking_index_j+1]==2'b00 && walking_index_i!=3 && block[walking_index_i+1][walking_index_j+1]==0)begin
							walking_index_j <= walking_index_j+1;
							walking_index_i <= walking_index_i+1;
							stack[stack_index] <= 2'd1;
							stack_index <= stack_index+1;
						end
						else begin
							if(wholemap[walking_index_i][walking_index_j+1]==2'b11 || block[walking_index_i][walking_index_j+1]==1)begin //He should jump but it is the train in front of him,very bad
								block[walking_index_i][walking_index_j] <= 1;
								stack_index <= stack_index-1;
								stack[stack_index-1] <= 0;
								walking_index_j <= walking_index_j-1;
								if(stack[stack_index-1] == 2'd0)begin //forward
									walking_index_i <= walking_index_i;
								end
								else if(stack[stack_index-1] == 2'd1)begin //right
									walking_index_i <= walking_index_i-1;
								end
								else if(stack[stack_index-1] == 2'd2)begin //left
									walking_index_i <= walking_index_i+1;
								end
								else begin //jump
									walking_index_i <= walking_index_i;
								end
							end
							else begin //jump over it
								walking_index_j <= walking_index_j+1;
								stack[stack_index] <= 2'd3;
								stack_index <= stack_index+1;
							end
						end
					end
				end
			end	
		end
	end
end
//==============================================//
//                  output                      //
//==============================================//
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out <= 0;
		outcount <= 0;
	end
	else begin
		if(in_valid)begin
			outcount <= 0;
		end
		else begin
			if(out_ready)begin
				out <= stack[outcount];
				if(outcount == 63)begin
					outcount <= 0;
				end
				else begin
					outcount <= outcount+1;
				end
			end
			else begin
				out <= 0;
			end
		end	
	end
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_valid <= 0;
		out_has_been_opened <= 0;
	end
	else begin
		if(in_valid)begin
			out_has_been_opened <= 0;
		end
		else begin
			if(out_ready)begin
				out_has_been_opened <= 1;
				if(outcount == 63)begin
					out_valid <= 0;
				end
				else begin
					out_valid <= 1;
				end
			end
			else begin
				out_valid <= 0;
			end
		end	
	end
end


endmodule

