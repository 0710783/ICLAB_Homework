module QUEEN(
    //Input Port
    clk,
    rst_n,

    in_valid,
    col,
    row,

    in_valid_num,
    in_num,

    out_valid,
    out,

    );

input               clk, rst_n, in_valid,in_valid_num;
input       [3:0]   col,row;
input       [2:0]   in_num;

output reg          out_valid;
output reg  [3:0]   out;

//==============================================//
//             Parameter and Integer            //
//==============================================//
integer i,j,index_i,index_j,index_stack,index_exist,column_output;
parameter s_idle = 3'b000;
parameter s_input = 3'b001;
parameter s_rst = 3'b010;
//==============================================//
//                 reg declaration              //
//==============================================//
reg [11:0]save_input_for_block[11:0]; //if block:1,else:0
reg [2:0] state;
reg judge; //judge if invalid has happened or not
reg judge_real;//judge if invalid is over
reg output_ready;
reg judge_bad;
reg [3:0]judge_exist[5:0];
reg [3:0]save_out_col[11:0];
reg [3:0]save_out_row[11:0];
reg [3:0]cal_out_12;
reg out_has_been_opened;
reg [4:0]stack_row[11:0];
reg [4:0]stack_col[11:0];
reg outwait;
reg [3:0]row_save;
reg [3:0]col_save;
reg in_valid_save;
reg [2:0]in_num_real;
//==============================================//
//            FSM State Declaration             //
//==============================================//
//current_state
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		row_save <= 0;
		col_save <= 0;
		in_valid_save <= 0;
		in_num_real <= 0;
	end
	else begin
		if(!in_valid)begin
			row_save <= 0;
			col_save <= 0;
			in_valid_save <= 0;
			in_num_real <= 0;
		end	
		else begin
			row_save <= row;
			col_save <= col;
			in_valid_save <= in_valid;
			in_num_real <= in_num;
		end
	end
end
always @(posedge clk or negedge rst_n)begin  //judge_real must be 1
	if(!rst_n)begin
		output_ready <= 0;
		index_i <= 0;
		index_j <= 0;
		index_stack <= 0;
		for(i=0;i<12;i=i+1)begin
			save_out_col[i] <= 0;
			save_out_row[i] <= 0;
			stack_col[i] <= 14;
			stack_row[i] <= 14;
		end
		state <= s_rst;
	end
	else begin
		if(out_has_been_opened && !out_valid && !in_valid_save)begin
			output_ready <= 0;
			index_i <= 0;
			index_j <= 0;
			index_stack <= 0;
			for(i=0;i<12;i=i+1)begin
				save_out_col[i] <= 0;
				save_out_row[i] <= 0;
				stack_col[i] <= 14;
				stack_row[i] <= 14;
			end
			state <= s_rst;
		end
		else begin
			if(judge_real)begin
				case(state)
					s_idle:begin
						index_i <= 0;
						index_j <= 0;
						state <= s_input;
					end
					s_input:begin
						if(index_stack > 11)begin
							if(out == save_out_row[11])begin
								if(save_out_col[11]==11)begin
									output_ready <= 1;
								end	
								else begin
									output_ready <= 0;
								end
							end
							else begin
								output_ready <= 1;
							end
							for(i=0;i<12;i=i+1)begin
								save_out_col[stack_col[i]] <= stack_col[i];
								save_out_row[stack_col[i]] <= stack_row[i];
							end
						end
						else begin
							if(save_input_for_block[index_i][index_j]==1)begin
								if(index_j == judge_exist[0] || index_j == judge_exist[1] || index_j == judge_exist[2] || index_j == judge_exist[3] || index_j == judge_exist[4] || index_j == judge_exist[5])begin
									index_j <= index_j+1;
									index_i <= 0;
								end	
								else begin
									if(index_i==11 || index_i==12)begin
										index_j <= stack_col[index_stack-1];
										index_i <= stack_row[index_stack-1]+1;
										stack_col[index_stack-1] <= 14;
										stack_row[index_stack-1] <= 14;
										index_stack <= index_stack-1;
									end
									else begin
										index_i <= index_i+1; //row down
									end
								end	
							end
							else begin
								if(judge_bad == 0 && index_i!=12)begin
									stack_col[index_stack] <= index_j;
									stack_row[index_stack] <= index_i;							
									index_stack <= index_stack+1;
									if(index_j != 11)begin
										index_j <= index_j+1;
									end
									else begin
										index_j <= 0;
									end
									index_i <= 0;
								end
								else begin //the position is bad
									if(index_i==11 || index_i==12)begin //the last row in the column is bad
										index_j <= stack_col[index_stack-1];					
										index_i <= stack_row[index_stack-1]+1;
										stack_col[index_stack-1] <= 14;
										stack_row[index_stack-1] <= 14;
										index_stack <= index_stack-1;
									end
									else begin
										index_i <= index_i+1;
										state <= s_input;
									end
								end
							end
						end	
					end
					default:state <= s_idle;
				endcase
			end	
			else begin
				if(in_valid_save)begin
					index_stack <= index_stack+1;
				end
				else begin
					index_stack <= index_stack;
				end	
				stack_col[index_stack] <= col_save;
				stack_row[index_stack] <= row_save;
			end
		end	
	end
end 
always @(*)begin
	if(!rst_n)begin
		judge_bad = 0;
	end
	else begin
		case(index_stack)
			1:begin
				if(index_i == stack_row[0] || index_j == stack_col[0] || (index_i-stack_row[0])==(index_j-stack_col[0]) || (index_i-stack_row[0])== -(index_j-stack_col[0]))begin
					judge_bad = 1;
				end
				else begin
					judge_bad = 0;
				end
			end	
			2:begin
				if(index_i == stack_row[1] || index_j == stack_col[1] || (index_i-stack_row[1])==(index_j-stack_col[1]) || (index_i-stack_row[1])== -(index_j-stack_col[1]) || index_i == stack_row[0] || index_j == stack_col[0] || (index_i-stack_row[0])==(index_j-stack_col[0]) || (index_i-stack_row[0])== -(index_j-stack_col[0]))begin
					judge_bad = 1;
				end
				else begin
					judge_bad = 0;
				end
			end	
			3:begin
				if(index_i == stack_row[2] || index_j == stack_col[2] || (index_i-stack_row[2])==(index_j-stack_col[2]) || (index_i-stack_row[2])== -(index_j-stack_col[2]) || index_i == stack_row[1] || index_j == stack_col[1] || (index_i-stack_row[1])==(index_j-stack_col[1]) || (index_i-stack_row[1])== -(index_j-stack_col[1]) || index_i == stack_row[0] || index_j == stack_col[0] || (index_i-stack_row[0])==(index_j-stack_col[0]) || (index_i-stack_row[0])== -(index_j-stack_col[0]))begin
					judge_bad = 1;
				end
				else begin
					judge_bad = 0;
				end
			end	
			4:begin
				if(index_i == stack_row[3] || index_j == stack_col[3] || (index_i-stack_row[3])==(index_j-stack_col[3]) || (index_i-stack_row[3])== -(index_j-stack_col[3]) || index_i == stack_row[2] || index_j == stack_col[2] || (index_i-stack_row[2])==(index_j-stack_col[2]) || (index_i-stack_row[2])== -(index_j-stack_col[2]) || index_i == stack_row[1] || index_j == stack_col[1] || (index_i-stack_row[1])==(index_j-stack_col[1]) || (index_i-stack_row[1])== -(index_j-stack_col[1]) || index_i == stack_row[0] || index_j == stack_col[0] || (index_i-stack_row[0])==(index_j-stack_col[0]) || (index_i-stack_row[0])== -(index_j-stack_col[0]))begin
					judge_bad = 1;
				end
				else begin
					judge_bad = 0;
				end
			end	
			5:begin
				if(index_i == stack_row[4] || index_j == stack_col[4] || (index_i-stack_row[4])==(index_j-stack_col[4]) || (index_i-stack_row[4])== -(index_j-stack_col[4]) || index_i == stack_row[3] || index_j == stack_col[3] || (index_i-stack_row[3])==(index_j-stack_col[3]) || (index_i-stack_row[3])== -(index_j-stack_col[3]) || index_i == stack_row[2] || index_j == stack_col[2] || (index_i-stack_row[2])==(index_j-stack_col[2]) || (index_i-stack_row[2])== -(index_j-stack_col[2]) || index_i == stack_row[1] || index_j == stack_col[1] || (index_i-stack_row[1])==(index_j-stack_col[1]) || (index_i-stack_row[1])== -(index_j-stack_col[1]) || index_i == stack_row[0] || index_j == stack_col[0] || (index_i-stack_row[0])==(index_j-stack_col[0]) || (index_i-stack_row[0])== -(index_j-stack_col[0]))begin
					judge_bad = 1;
				end
				else begin
					judge_bad = 0;
				end
			end	
			6:begin
				if(index_i == stack_row[5] || index_j == stack_col[5] || (index_i-stack_row[5])==(index_j-stack_col[5]) || (index_i-stack_row[5])== -(index_j-stack_col[5]) || index_i == stack_row[4] || index_j == stack_col[4] || (index_i-stack_row[4])==(index_j-stack_col[4]) || (index_i-stack_row[4])== -(index_j-stack_col[4]) || index_i == stack_row[3] || index_j == stack_col[3] || (index_i-stack_row[3])==(index_j-stack_col[3]) || (index_i-stack_row[3])== -(index_j-stack_col[3]) || index_i == stack_row[2] || index_j == stack_col[2] || (index_i-stack_row[2])==(index_j-stack_col[2]) || (index_i-stack_row[2])== -(index_j-stack_col[2]) || index_i == stack_row[1] || index_j == stack_col[1] || (index_i-stack_row[1])==(index_j-stack_col[1]) || (index_i-stack_row[1])== -(index_j-stack_col[1]) || index_i == stack_row[0] || index_j == stack_col[0] || (index_i-stack_row[0])==(index_j-stack_col[0]) || (index_i-stack_row[0])== -(index_j-stack_col[0]))begin
					judge_bad = 1;
				end
				else begin
					judge_bad = 0;
				end
			end	
			7:begin
				if(index_i == stack_row[6] || index_j == stack_col[6] || (index_i-stack_row[6])==(index_j-stack_col[6]) || (index_i-stack_row[6])== -(index_j-stack_col[6]) || index_i == stack_row[5] || index_j == stack_col[5] || (index_i-stack_row[5])==(index_j-stack_col[5]) || (index_i-stack_row[5])== -(index_j-stack_col[5]) || index_i == stack_row[4] || index_j == stack_col[4] || (index_i-stack_row[4])==(index_j-stack_col[4]) || (index_i-stack_row[4])== -(index_j-stack_col[4]) || index_i == stack_row[3] || index_j == stack_col[3] || (index_i-stack_row[3])==(index_j-stack_col[3]) || (index_i-stack_row[3])== -(index_j-stack_col[3]) || index_i == stack_row[2] || index_j == stack_col[2] || (index_i-stack_row[2])==(index_j-stack_col[2]) || (index_i-stack_row[2])== -(index_j-stack_col[2]) || index_i == stack_row[1] || index_j == stack_col[1] || (index_i-stack_row[1])==(index_j-stack_col[1]) || (index_i-stack_row[1])== -(index_j-stack_col[1]) || index_i == stack_row[0] || index_j == stack_col[0] || (index_i-stack_row[0])==(index_j-stack_col[0]) || (index_i-stack_row[0])== -(index_j-stack_col[0]))begin
					judge_bad = 1;
				end
				else begin
					judge_bad = 0;
				end
			end	
			8:begin
				if(index_i == stack_row[7] || index_j == stack_col[7] || (index_i-stack_row[7])==(index_j-stack_col[7]) || (index_i-stack_row[7])== -(index_j-stack_col[7]) || index_i == stack_row[6] || index_j == stack_col[6] || (index_i-stack_row[6])==(index_j-stack_col[6]) || (index_i-stack_row[6])== -(index_j-stack_col[6]) || index_i == stack_row[5] || index_j == stack_col[5] || (index_i-stack_row[5])==(index_j-stack_col[5]) || (index_i-stack_row[5])== -(index_j-stack_col[5]) || index_i == stack_row[4] || index_j == stack_col[4] || (index_i-stack_row[4])==(index_j-stack_col[4]) || (index_i-stack_row[4])== -(index_j-stack_col[4]) || index_i == stack_row[3] || index_j == stack_col[3] || (index_i-stack_row[3])==(index_j-stack_col[3]) || (index_i-stack_row[3])== -(index_j-stack_col[3]) || index_i == stack_row[2] || index_j == stack_col[2] || (index_i-stack_row[2])==(index_j-stack_col[2]) || (index_i-stack_row[2])== -(index_j-stack_col[2]) || index_i == stack_row[1] || index_j == stack_col[1] || (index_i-stack_row[1])==(index_j-stack_col[1]) || (index_i-stack_row[1])== -(index_j-stack_col[1]) || index_i == stack_row[0] || index_j == stack_col[0] || (index_i-stack_row[0])==(index_j-stack_col[0]) || (index_i-stack_row[0])== -(index_j-stack_col[0]))begin
					judge_bad = 1;
				end
				else begin
					judge_bad = 0;
				end
			end	
			9:begin
				if(index_i == stack_row[8] || index_j == stack_col[8] || (index_i-stack_row[8])==(index_j-stack_col[8]) || (index_i-stack_row[8])== -(index_j-stack_col[8]) || index_i == stack_row[7] || index_j == stack_col[7] || (index_i-stack_row[7])==(index_j-stack_col[7]) || (index_i-stack_row[7])== -(index_j-stack_col[7]) || index_i == stack_row[6] || index_j == stack_col[6] || (index_i-stack_row[6])==(index_j-stack_col[6]) || (index_i-stack_row[6])== -(index_j-stack_col[6]) || index_i == stack_row[5] || index_j == stack_col[5] || (index_i-stack_row[5])==(index_j-stack_col[5]) || (index_i-stack_row[5])== -(index_j-stack_col[5]) || index_i == stack_row[4] || index_j == stack_col[4] || (index_i-stack_row[4])==(index_j-stack_col[4]) || (index_i-stack_row[4])== -(index_j-stack_col[4]) || index_i == stack_row[3] || index_j == stack_col[3] || (index_i-stack_row[3])==(index_j-stack_col[3]) || (index_i-stack_row[3])== -(index_j-stack_col[3]) || index_i == stack_row[2] || index_j == stack_col[2] || (index_i-stack_row[2])==(index_j-stack_col[2]) || (index_i-stack_row[2])== -(index_j-stack_col[2]) || index_i == stack_row[1] || index_j == stack_col[1] || (index_i-stack_row[1])==(index_j-stack_col[1]) || (index_i-stack_row[1])== -(index_j-stack_col[1]) || index_i == stack_row[0] || index_j == stack_col[0] || (index_i-stack_row[0])==(index_j-stack_col[0]) || (index_i-stack_row[0])== -(index_j-stack_col[0]))begin
					judge_bad = 1;
				end
				else begin
					judge_bad = 0;
				end
			end	
			10:begin
				if(index_i == stack_row[9] || index_j == stack_col[9] || (index_i-stack_row[9])==(index_j-stack_col[9]) || (index_i-stack_row[9])== -(index_j-stack_col[9]) || index_i == stack_row[8] || index_j == stack_col[8] || (index_i-stack_row[8])==(index_j-stack_col[8]) || (index_i-stack_row[8])== -(index_j-stack_col[8]) || index_i == stack_row[7] || index_j == stack_col[7] || (index_i-stack_row[7])==(index_j-stack_col[7]) || (index_i-stack_row[7])== -(index_j-stack_col[7]) || index_i == stack_row[6] || index_j == stack_col[6] || (index_i-stack_row[6])==(index_j-stack_col[6]) || (index_i-stack_row[6])== -(index_j-stack_col[6]) || index_i == stack_row[5] || index_j == stack_col[5] || (index_i-stack_row[5])==(index_j-stack_col[5]) || (index_i-stack_row[5])== -(index_j-stack_col[5]) || index_i == stack_row[4] || index_j == stack_col[4] || (index_i-stack_row[4])==(index_j-stack_col[4]) || (index_i-stack_row[4])== -(index_j-stack_col[4]) || index_i == stack_row[3] || index_j == stack_col[3] || (index_i-stack_row[3])==(index_j-stack_col[3]) || (index_i-stack_row[3])== -(index_j-stack_col[3]) || index_i == stack_row[2] || index_j == stack_col[2] || (index_i-stack_row[2])==(index_j-stack_col[2]) || (index_i-stack_row[2])== -(index_j-stack_col[2]) || index_i == stack_row[1] || index_j == stack_col[1] || (index_i-stack_row[1])==(index_j-stack_col[1]) || (index_i-stack_row[1])== -(index_j-stack_col[1]) || index_i == stack_row[0] || index_j == stack_col[0] || (index_i-stack_row[0])==(index_j-stack_col[0]) || (index_i-stack_row[0])== -(index_j-stack_col[0]))begin
					judge_bad = 1;
				end
				else begin
					judge_bad = 0;
				end
			end	
			11:begin
				if(index_i == stack_row[10] || index_j == stack_col[10] || (index_i-stack_row[10])==(index_j-stack_col[10]) || (index_i-stack_row[10])== -(index_j-stack_col[10]) || index_i == stack_row[9] || index_j == stack_col[9] || (index_i-stack_row[9])==(index_j-stack_col[9]) || (index_i-stack_row[9])== -(index_j-stack_col[9]) || index_i == stack_row[8] || index_j == stack_col[8] || (index_i-stack_row[8])==(index_j-stack_col[8]) || (index_i-stack_row[8])== -(index_j-stack_col[8]) || index_i == stack_row[7] || index_j == stack_col[7] || (index_i-stack_row[7])==(index_j-stack_col[7]) || (index_i-stack_row[7])== -(index_j-stack_col[7]) || index_i == stack_row[6] || index_j == stack_col[6] || (index_i-stack_row[6])==(index_j-stack_col[6]) || (index_i-stack_row[6])== -(index_j-stack_col[6]) || index_i == stack_row[5] || index_j == stack_col[5] || (index_i-stack_row[5])==(index_j-stack_col[5]) || (index_i-stack_row[5])== -(index_j-stack_col[5]) || index_i == stack_row[4] || index_j == stack_col[4] || (index_i-stack_row[4])==(index_j-stack_col[4]) || (index_i-stack_row[4])== -(index_j-stack_col[4]) || index_i == stack_row[3] || index_j == stack_col[3] || (index_i-stack_row[3])==(index_j-stack_col[3]) || (index_i-stack_row[3])== -(index_j-stack_col[3]) || index_i == stack_row[2] || index_j == stack_col[2] || (index_i-stack_row[2])==(index_j-stack_col[2]) || (index_i-stack_row[2])== -(index_j-stack_col[2]) || index_i == stack_row[1] || index_j == stack_col[1] || (index_i-stack_row[1])==(index_j-stack_col[1]) || (index_i-stack_row[1])== -(index_j-stack_col[1]) || index_i == stack_row[0] || index_j == stack_col[0] || (index_i-stack_row[0])==(index_j-stack_col[0]) || (index_i-stack_row[0])== -(index_j-stack_col[0]))begin
					judge_bad = 1;
				end
				else begin
					judge_bad = 0;
				end
			end	
			12:begin
				if(index_i == stack_row[11] || index_j == stack_col[11] || (index_i-stack_row[11])==(index_j-stack_col[11]) || (index_i-stack_row[11])== -(index_j-stack_col[11]) || index_i == stack_row[10] || index_j == stack_col[10] || (index_i-stack_row[10])==(index_j-stack_col[10]) || (index_i-stack_row[10])== -(index_j-stack_col[10]) || index_i == stack_row[9] || index_j == stack_col[9] || (index_i-stack_row[9])==(index_j-stack_col[9]) || (index_i-stack_row[9])== -(index_j-stack_col[9]) || index_i == stack_row[8] || index_j == stack_col[8] || (index_i-stack_row[8])==(index_j-stack_col[8]) || (index_i-stack_row[8])== -(index_j-stack_col[8]) || index_i == stack_row[7] || index_j == stack_col[7] || (index_i-stack_row[7])==(index_j-stack_col[7]) || (index_i-stack_row[7])== -(index_j-stack_col[7]) || index_i == stack_row[6] || index_j == stack_col[6] || (index_i-stack_row[6])==(index_j-stack_col[6]) || (index_i-stack_row[6])== -(index_j-stack_col[6]) || index_i == stack_row[5] || index_j == stack_col[5] || (index_i-stack_row[5])==(index_j-stack_col[5]) || (index_i-stack_row[5])== -(index_j-stack_col[5]) || index_i == stack_row[4] || index_j == stack_col[4] || (index_i-stack_row[4])==(index_j-stack_col[4]) || (index_i-stack_row[4])== -(index_j-stack_col[4]) || index_i == stack_row[3] || index_j == stack_col[3] || (index_i-stack_row[3])==(index_j-stack_col[3]) || (index_i-stack_row[3])== -(index_j-stack_col[3]) || index_i == stack_row[2] || index_j == stack_col[2] || (index_i-stack_row[2])==(index_j-stack_col[2]) || (index_i-stack_row[2])== -(index_j-stack_col[2]) || index_i == stack_row[1] || index_j == stack_col[1] || (index_i-stack_row[1])==(index_j-stack_col[1]) || (index_i-stack_row[1])== -(index_j-stack_col[1]) || index_i == stack_row[0] || index_j == stack_col[0] || (index_i-stack_row[0])==(index_j-stack_col[0]) || (index_i-stack_row[0])== -(index_j-stack_col[0]))begin
					judge_bad = 1;
				end
				else begin
					judge_bad = 0;
				end
			end	
			default:begin
				judge_bad = 0;
			end
		endcase
	end	
end
//==============================================//
//                  Input Block                 //
//==============================================//
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		judge <= 0;
	end
	else begin
		if(in_valid || (judge_exist[0]!=13) || in_valid_save)begin
			judge <= 1;
		end
		else begin
			judge <= 0;
		end
	end
end
always @(*)begin
	if(!rst_n)begin
		judge_real = 0;
	end
	else begin
		if(judge && !in_valid_save)begin
			judge_real = 1;
		end
		else begin
			judge_real = 0;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<6;i=i+1)begin
			judge_exist[i] <= 13;
			index_exist <= 0;
		end
	end
	else begin
		if(out_has_been_opened && !out_valid && !in_valid_save)begin
			for(i=0;i<6;i=i+1)begin
				judge_exist[i] <= 13;
				index_exist <= 0;
			end
		end
		else begin
			if(in_valid_save)begin
				index_exist <= index_exist + 1;
				judge_exist[index_exist] <= col_save;
			end
			else begin
				index_exist <= 0;
			end
		end
	end
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<12;i=i+1)begin
			for(j=0;j<12;j=j+1)begin
				save_input_for_block[i][j] <= 0;
			end
		end
	end
	else begin
		if(out_has_been_opened && !out_valid && !in_valid_save)begin
			for(i=0;i<12;i=i+1)begin
				for(j=0;j<12;j=j+1)begin
					save_input_for_block[i][j] <= 0;
				end
			end
		end	
		else begin
			if(in_valid_save || in_num_real==1)begin
				for(i=0;i<12;i=i+1)begin
					if(in_valid_save)begin
						save_input_for_block[i][col_save] <= 1;
						save_input_for_block[row_save][i] <= 1;
					end
					else begin
						if(judge)begin
							save_input_for_block[i][col_save] <= save_input_for_block[i][col_save];
							save_input_for_block[row_save][i] <= save_input_for_block[row_save][i];
						end
						else begin
							save_input_for_block[i][col_save] <= 0;
							save_input_for_block[row_save][i] <= 0;
						end
					end
				end
				if(row_save>col_save)begin
					case(col_save+1)
						1:begin
							save_input_for_block[row_save][col_save] <= 1;
						end
						2:begin
							save_input_for_block[row_save+1][col_save-1] <= 1; //leftdown
							save_input_for_block[row_save-1][col_save-1] <= 1; //leftup
						end
						3:begin
							for(i=1;i<3;i=i+1)begin
								save_input_for_block[row_save+i][col_save-i] <= 1; //leftdown
								save_input_for_block[row_save-i][col_save-i] <= 1; //leftup
							end
						end
						4:begin
							for(i=1;i<4;i=i+1)begin
								save_input_for_block[row_save+i][col_save-i] <= 1; //leftdown
								save_input_for_block[row_save-i][col_save-i] <= 1; //leftup
							end
						end
						5:begin
							for(i=1;i<5;i=i+1)begin
								save_input_for_block[row_save+i][col_save-i] <= 1; //leftdown
								save_input_for_block[row_save-i][col_save-i] <= 1; //leftup
							end
						end
						6:begin
							for(i=1;i<6;i=i+1)begin
								save_input_for_block[row_save+i][col_save-i] <= 1; //leftdown
								save_input_for_block[row_save-i][col_save-i] <= 1; //leftup
							end
						end
						7:begin
							for(i=1;i<7;i=i+1)begin
								save_input_for_block[row_save+i][col_save-i] <= 1; //leftdown
								save_input_for_block[row_save-i][col_save-i] <= 1; //leftup
							end
						end
						8:begin
							for(i=1;i<8;i=i+1)begin
								save_input_for_block[row_save+i][col_save-i] <= 1; //leftdown
								save_input_for_block[row_save-i][col_save-i] <= 1; //leftup
							end
						end
						9:begin
							for(i=1;i<9;i=i+1)begin
								save_input_for_block[row_save+i][col_save-i] <= 1; //leftdown
								save_input_for_block[row_save-i][col_save-i] <= 1; //leftup
							end
						end
						10:begin
							for(i=1;i<10;i=i+1)begin
								save_input_for_block[row_save+i][col_save-i] <= 1; //leftdown
								save_input_for_block[row_save-i][col_save-i] <= 1; //leftup
							end
						end
						11:begin
							for(i=1;i<11;i=i+1)begin	
								save_input_for_block[row_save+i][col_save-i] <= 1; //leftdown
								save_input_for_block[row_save-i][col_save-i] <= 1; //leftup
							end
						end
						default:begin
							save_input_for_block[row_save][col_save] <= 1;
						end
					endcase
					case(12-row_save)
						1:begin
							save_input_for_block[row_save+1][col_save+1] <= 1; //rightdown
							save_input_for_block[row_save+1][col_save-1] <= 1; //rightup
						end
						2:begin
							for(i=1;i<2;i=i+1)begin
								save_input_for_block[row_save+i][col_save+i] <= 1; //rightdown
								save_input_for_block[row_save+i][col_save-i] <= 1; //rightup
							end
						end
						3:begin
							for(i=1;i<3;i=i+1)begin
								save_input_for_block[row_save+i][col_save+i] <= 1; //rightdown
								save_input_for_block[row_save+i][col_save-i] <= 1; //rightup
							end
						end
						4:begin
							for(i=1;i<4;i=i+1)begin
								save_input_for_block[row_save+i][col_save+i] <= 1; //rightdown
								save_input_for_block[row_save+i][col_save-i] <= 1; //rightup
							end
						end
						5:begin
							for(i=1;i<5;i=i+1)begin
								save_input_for_block[row_save+i][col_save+i] <= 1; //rightdown
								save_input_for_block[row_save+i][col_save-i] <= 1; //rightup
							end
						end
						6:begin
							for(i=1;i<6;i=i+1)begin
								save_input_for_block[row_save+i][col_save+i] <= 1; //rightdown
								save_input_for_block[row_save+i][col_save-i] <= 1; //rightup
							end
						end
						7:begin
							for(i=1;i<7;i=i+1)begin
								save_input_for_block[row_save+i][col_save+i] <= 1; //rightdown
								save_input_for_block[row_save+i][col_save-i] <= 1; //rightup
							end
						end
						8:begin
							for(i=1;i<8;i=i+1)begin
								save_input_for_block[row_save+i][col_save+i] <= 1; //rightdown
								save_input_for_block[row_save+i][col_save-i] <= 1; //rightup
							end
						end
						9:begin
							for(i=1;i<9;i=i+1)begin
								save_input_for_block[row_save+i][col_save+i] <= 1; //rightdown
								save_input_for_block[row_save+i][col_save-i] <= 1; //rightup
							end
						end
						10:begin
							for(i=1;i<10;i=i+1)begin
								save_input_for_block[row_save+i][col_save+i] <= 1; //rightdown
								save_input_for_block[row_save+i][col_save-i] <= 1; //rightup
							end
						end
						11:begin
							for(i=1;i<11;i=i+1)begin
								save_input_for_block[row_save+i][col_save+i] <= 1; //rightdown
								save_input_for_block[row_save+i][col_save-i] <= 1; //rightup
							end
						end
						default:begin
							save_input_for_block[row_save][col_save] <= 1;
						end
					endcase
				end
				else begin
					case(row_save+1)
						1:begin
							save_input_for_block[row_save+1][col_save-1] <= 1; //leftdown
							save_input_for_block[row_save-1][col_save-1] <= 1; //leftup
						end
						2:begin
							for(i=1;i<2;i=i+1)begin
								save_input_for_block[row_save+i][col_save-i] <= 1; //leftdown
								save_input_for_block[row_save-i][col_save-i] <= 1; //leftup
							end
						end
						3:begin
							for(i=1;i<3;i=i+1)begin
								save_input_for_block[row_save+i][col_save-i] <= 1; //leftdown
								save_input_for_block[row_save-i][col_save-i] <= 1; //leftup
							end
						end
						4:begin
							for(i=1;i<4;i=i+1)begin
								save_input_for_block[row_save+i][col_save-i] <= 1; //leftdown
								save_input_for_block[row_save-i][col_save-i] <= 1; //leftup
							end
						end
						5:begin
							for(i=1;i<5;i=i+1)begin
								save_input_for_block[row_save+i][col_save-i] <= 1; //leftdown
								save_input_for_block[row_save-i][col_save-i] <= 1; //leftup
							end
						end
						6:begin
							for(i=1;i<6;i=i+1)begin
								save_input_for_block[row_save+i][col_save-i] <= 1; //leftdown
								save_input_for_block[row_save-i][col_save-i] <= 1; //leftup
							end
						end
						7:begin
							for(i=1;i<7;i=i+1)begin
								save_input_for_block[row_save+i][col_save-i] <= 1; //leftdown
								save_input_for_block[row_save-i][col_save-i] <= 1; //leftup
							end
						end
						8:begin
							for(i=1;i<8;i=i+1)begin
								save_input_for_block[row_save+i][col_save-i] <= 1; //leftdown
								save_input_for_block[row_save-i][col_save-i] <= 1; //leftup
							end
						end
						9:begin
							for(i=1;i<9;i=i+1)begin
								save_input_for_block[row_save+i][col_save-i] <= 1; //leftdown
								save_input_for_block[row_save-i][col_save-i] <= 1; //leftup
							end
						end
						10:begin
							for(i=1;i<10;i=i+1)begin
								save_input_for_block[row_save+i][col_save-i] <= 1; //leftdown
								save_input_for_block[row_save-i][col_save-i] <= 1; //leftup
							end
						end
						11:begin
							for(i=1;i<11;i=i+1)begin
								save_input_for_block[row_save+i][col_save-i] <= 1; //leftdown
								save_input_for_block[row_save-i][col_save-i] <= 1; //leftup
							end
						end
						default:begin
							save_input_for_block[row_save][col_save] <= 1;
						end
					endcase
					case(12-col_save)
						1:begin
							save_input_for_block[row_save+1][col_save+1] <= 1; //rightdown
							save_input_for_block[row_save+1][col_save-1] <= 1; //rightup
						end
						2:begin
							for(i=1;i<2;i=i+1)begin
								save_input_for_block[row_save+i][col_save+i] <= 1; //rightdown
								save_input_for_block[row_save+i][col_save-i] <= 1; //rightup
							end
						end
						3:begin
							for(i=1;i<3;i=i+1)begin
								save_input_for_block[row_save+i][col_save+i] <= 1; //rightdown
								save_input_for_block[row_save+i][col_save-i] <= 1; //rightup
							end
						end
						4:begin
							for(i=1;i<4;i=i+1)begin
								save_input_for_block[row_save+i][col_save+i] <= 1; //rightdown
								save_input_for_block[row_save+i][col_save-i] <= 1; //rightup
							end
						end
						5:begin
							for(i=1;i<5;i=i+1)begin
								save_input_for_block[row_save+i][col_save+i] <= 1; //rightdown
								save_input_for_block[row_save+i][col_save-i] <= 1; //rightup
							end
						end
						6:begin
							for(i=1;i<6;i=i+1)begin
								save_input_for_block[row_save+i][col_save+i] <= 1; //rightdown
								save_input_for_block[row_save+i][col_save-i] <= 1; //rightup
							end
						end
						7:begin
							for(i=1;i<7;i=i+1)begin
								save_input_for_block[row_save+i][col_save+i] <= 1; //rightdown
								save_input_for_block[row_save+i][col_save-i] <= 1; //rightup
							end
						end
						8:begin
							for(i=1;i<8;i=i+1)begin
								save_input_for_block[row_save+i][col_save+i] <= 1; //rightdown
								save_input_for_block[row_save+i][col_save-i] <= 1; //rightup
							end
						end
						9:begin
							for(i=1;i<9;i=i+1)begin
								save_input_for_block[row_save+i][col_save+i] <= 1; //rightdown
								save_input_for_block[row_save+i][col_save-i] <= 1; //rightup
							end
						end
						10:begin
							for(i=1;i<10;i=i+1)begin
								save_input_for_block[row_save+i][col_save+i] <= 1; //rightdown
								save_input_for_block[row_save+i][col_save-i] <= 1; //rightup
							end
						end
						11:begin
							for(i=1;i<11;i=i+1)begin
								save_input_for_block[row_save+i][col_save+i] <= 1; //rightdown
								save_input_for_block[row_save+i][col_save-i] <= 1; //rightup
							end
						end
						default:begin
							save_input_for_block[row_save][col_save] <= 1;
						end
					endcase
				end
			end
			else begin
				for(i=0;i<12;i=i+1)begin
					save_input_for_block[i][col_save] <= save_input_for_block[i][col_save];
					save_input_for_block[row_save][i] <= save_input_for_block[row_save][i];
				end
			end
		end	
	end
end
//GOOD LUCKY
//==============================================//
//                  Output reset Block          //
//==============================================//
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out <= 0;
		column_output <= 0;
	end
	else begin
		if(out_has_been_opened && !out_valid)begin
			out <= 0;
			column_output <= 0;
		end
		else begin
			if(outwait)begin
				if(column_output!=12)begin
					out <= save_out_row[column_output];
					column_output <= column_output+1;
				end
				else begin
					out <= 0;
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
		cal_out_12 <= 0;
		out_has_been_opened <= 0;
		outwait <= 0;
	end
	else begin
		if(in_valid_save)begin
			out_valid <= 0;
			cal_out_12 <= 0;
			out_has_been_opened <= 0;
			outwait <= 0;
		end
		else begin
			if(output_ready == 1)begin
				outwait <= 1;
			end
			else begin
				outwait <= 0;
			end
			if(outwait)begin
				out_has_been_opened <= 1;
				out_valid <= 1;
				if(cal_out_12 != 12)begin
					cal_out_12 <= cal_out_12+1;
				end
				else begin
					out_valid <= 0;
				end
			end
			else begin
				out_valid <= 0;
				out_has_been_opened <= 0;
			end
		end	
	end
end

endmodule 
