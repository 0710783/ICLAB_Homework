module MMT(
// input signals
    clk,
    rst_n,
    in_valid,
	in_valid2,
    matrix,
	matrix_size,
    matrix_idx,
    mode,
	
// output signals
    out_valid,
    out_value
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input        clk, rst_n, in_valid, in_valid2;
input [7:0]  matrix;
input [1:0]  matrix_size,mode;
input [4:0]  matrix_idx;

output reg       	     out_valid;
output reg signed [49:0] out_value;
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
parameter IDLE = 3'b000;
parameter INPUT_DATA = 3'b001; //in_valid
parameter INPUT_DATA2 = 3'b010; //in_valid2
parameter BEFORE_INV2 = 3'b011;
parameter SAVE_THREE_MAT = 3'b100;
parameter CAL = 3'b101;
parameter OUT_DATA = 3'b110;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
integer i;
wire [12:0]INPUT_A;
wire [7:0]INPUT_D,INPUT_Q;
wire WEN_DATA_SAVE;

reg signed[12:0]INPUT_A_reg;
reg signed[7:0]INPUT_D_reg;
reg WEN_DATA_SAVE_reg;
reg [1:0]mat_size;
reg [2:0]cs,ns;
reg [12:0]INPUT_A_reg_savefirst;
reg [12:0]INPUT_D_reg_savefirst;
reg [4:0]mat_ind_save[2:0];
reg [12:0]mat_ind_initial_location[2:0];
reg [1:0]mode_save;
reg [1:0]count_inputvalid2;
reg judge_invalid2;
reg [4:0]square_side;
reg [8:0]square_side_twice;
reg signed[7:0]three_matrix_save[767:0];
reg [12:0]three_matrix_index_save[767:0];
reg [9:0]count_three_mat_save;
reg signed[19:0]every_mul_result;
reg [9:0]A,B,B_forBT,A_forAT;
reg [9:0]COUNT_IN;
reg signed[49:0]OUTPUT_SAVE;
reg [3:0]INDEX_I,INDEX_J;
reg [3:0]COUNT_INPUT_ITERATION;
//---------------------------------------------------------------------
//   SRAM
//---------------------------------------------------------------------
SRAM DATA_SAVE(
	.A(INPUT_A),
	.D(INPUT_D),
	.Q(INPUT_Q),
	.CLK(clk),
	.WEN(WEN_DATA_SAVE),
	.CEN(1'b0),
	.OEN(1'b0)
);
assign INPUT_A = INPUT_A_reg;
assign INPUT_D = INPUT_D_reg;
assign WEN_DATA_SAVE = WEN_DATA_SAVE_reg;
//---------------------------------------------------------------------
//   FSM
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cs <= IDLE;
	end
	else begin
		cs <= ns;
	end
end
always @(*)begin
	case(cs)
		IDLE:begin
			if(in_valid)begin
				ns = INPUT_DATA;
			end
			else begin
				ns = IDLE;
			end
		end
		INPUT_DATA:begin
			if(!in_valid && cs == INPUT_DATA)begin
				ns = BEFORE_INV2;
			end
			else begin
				ns = INPUT_DATA;
			end
		end
		BEFORE_INV2:begin
			if(!in_valid2 && judge_invalid2)begin
				ns = SAVE_THREE_MAT;
			end
			else begin
				ns = BEFORE_INV2;
			end
		end
		SAVE_THREE_MAT:begin
			if(count_three_mat_save == square_side_twice*3+3)begin
				ns = CAL;
			end
			else begin
				ns = SAVE_THREE_MAT;
			end
		end
		CAL:begin
			if(COUNT_IN == square_side_twice)begin
				ns = OUT_DATA;
			end
			else begin
				ns = CAL;
			end
		end
		OUT_DATA:begin
			if(COUNT_INPUT_ITERATION == 9)begin
				ns = IDLE;
			end
			else begin
				ns = BEFORE_INV2;
			end
		end
		default:begin
			ns = IDLE;
		end
	endcase
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		judge_invalid2 <= 0;
	end
	else begin
		if(in_valid2)begin
			judge_invalid2 <= 1;
		end
		else begin
			judge_invalid2 <= 0;
		end
	end
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		COUNT_INPUT_ITERATION <= 0;
	end
	else begin
		if(out_valid)begin
			COUNT_INPUT_ITERATION <= COUNT_INPUT_ITERATION+1;
		end
		else begin
			if(in_valid)begin
				COUNT_INPUT_ITERATION <= 0;
			end
			else begin
				COUNT_INPUT_ITERATION <= COUNT_INPUT_ITERATION;
			end
		end
	end
end
//---------------------------------------------------------------------
//   Catch input & save
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		mat_size <= 0;
	end
	else begin
		if(in_valid && cs == IDLE)begin
			mat_size <= matrix_size;
		end
	end
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		square_side <= 0;
		square_side_twice <= 0;
	end
	else begin
		if(cs == INPUT_DATA)begin
			case(mat_size)
				2'b00:begin
					square_side <= 2;
					square_side_twice <= 4;
				end
				2'b01:begin
					square_side <= 4;
					square_side_twice <= 16;
				end
				2'b10:begin
					square_side <= 8;
					square_side_twice <= 64;
				end
				2'b11:begin
					square_side <= 16;
					square_side_twice <= 256;
				end
			endcase
		end
	end
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		INPUT_D_reg_savefirst <= 0;
	end
	else begin
		if(in_valid)begin
			INPUT_D_reg_savefirst <= matrix;
		end
	end
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		INPUT_D_reg <= 0;
	end
	else begin
		if(cs == INPUT_DATA)begin
			INPUT_D_reg <= INPUT_D_reg_savefirst;
		end
		else begin
			INPUT_D_reg <= 0;
		end
	end
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		INPUT_A_reg_savefirst <= 0;
	end
	else begin
		if(ns == INPUT_DATA && cs == INPUT_DATA)begin
			INPUT_A_reg_savefirst <= INPUT_A_reg_savefirst + 1;
		end
		else begin
			if(COUNT_INPUT_ITERATION == 10)begin
				INPUT_A_reg_savefirst <= 0;
			end
		end
	end
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		INPUT_A_reg <= 0;
	end
	else begin
		if(ns == SAVE_THREE_MAT)begin
			if(cs == SAVE_THREE_MAT && count_three_mat_save == 1)begin
				INPUT_A_reg <= mat_ind_initial_location[0];
			end
			else begin
				INPUT_A_reg <= three_matrix_index_save[count_three_mat_save-1];	
			end
		end
		else begin			
			INPUT_A_reg <= INPUT_A_reg_savefirst;
		end
	end
end
always @(posedge clk or negedge rst_n)begin	
	if(!rst_n)begin
		WEN_DATA_SAVE_reg <= 'd1;
	end
	else begin
		if(cs == INPUT_DATA)begin
			WEN_DATA_SAVE_reg <= 'd0;
		end
		else begin
			WEN_DATA_SAVE_reg <= 'd1;
		end
	end
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		mode_save <= 0;
	end
	else begin
		if(in_valid2 && !judge_invalid2)begin
			mode_save <= mode;
		end
	end
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<3;i=i+1)begin
			mat_ind_save[i] <= 0;
		end
		count_inputvalid2 <= 0;
	end
	else begin
		if(in_valid2)begin
			mat_ind_save[count_inputvalid2] <= matrix_idx;
			count_inputvalid2 <= count_inputvalid2+1;
		end
		else begin
			count_inputvalid2 <= 0;
			for(i=0;i<3;i=i+1)begin
				mat_ind_save[i] <= mat_ind_save[i];
			end
		end
	end
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<3;i=i+1)begin
			mat_ind_initial_location[i] <= 0;
		end
	end
	else begin
		if(ns == SAVE_THREE_MAT)begin
			for(i=0;i<3;i=i+1)begin
				mat_ind_initial_location[i] <= mat_ind_save[i]*square_side_twice;
			end
		end
		else begin
			if(out_valid)begin
				for(i=0;i<3;i=i+1)begin
					mat_ind_initial_location[i] <= 0;
				end
			end
			else begin
				for(i=0;i<3;i=i+1)begin
					mat_ind_initial_location[i] <= mat_ind_initial_location[i];
				end
			end
		end
	end
end
//---------------------------------------------------------------------
//   Take the value to Three Matrix
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<768;i=i+1)begin
			three_matrix_index_save[i] <= 0;
		end
		count_three_mat_save <= 0;
	end
	else begin
		if(ns == SAVE_THREE_MAT)begin
			three_matrix_index_save[0] <= mat_ind_initial_location[0];
			count_three_mat_save <= count_three_mat_save+1;
			if(count_three_mat_save<(square_side_twice))begin
				three_matrix_index_save[count_three_mat_save] <= mat_ind_initial_location[0]+count_three_mat_save;
			end
			else if(count_three_mat_save > (square_side_twice-1) && count_three_mat_save < (2*square_side_twice))begin
				three_matrix_index_save[count_three_mat_save] <= mat_ind_initial_location[1]+count_three_mat_save-square_side_twice;
			end
			else if(count_three_mat_save > (2*square_side_twice-1) && count_three_mat_save < (3*square_side_twice))begin
				three_matrix_index_save[count_three_mat_save] <= mat_ind_initial_location[2]+count_three_mat_save-2*square_side_twice;
			end
		end
		else begin
			count_three_mat_save <= 0;
		end
	end
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<768;i=i+1)begin
			three_matrix_save[i] <= 0;
		end
	end
	else begin
		if(count_three_mat_save > 2)begin
			three_matrix_save[count_three_mat_save-3] <= INPUT_Q;
		end
		else begin
			if(COUNT_INPUT_ITERATION == 10)begin
				for(i=0;i<768;i=i+1)begin
					three_matrix_save[i] <= 0;
				end
			end
		end
	end
end
//---------------------------------------------------------------------
//   Cal
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		every_mul_result = 0;
	end
	else begin
		if(cs == CAL)begin
			case(mat_size)
				2'b00:begin //2*2
					if(mode_save == 2'b00 || mode_save == 2'b11)begin
						every_mul_result = three_matrix_save[A]*three_matrix_save[B]+three_matrix_save[A+1]*three_matrix_save[B+2]; 
					end
					else if(mode_save == 2'b01)begin
						every_mul_result = three_matrix_save[A_forAT]*three_matrix_save[B]+three_matrix_save[A_forAT+2]*three_matrix_save[B+2]; 
					end
					else begin
						every_mul_result = three_matrix_save[A]*three_matrix_save[B_forBT]+three_matrix_save[A+1]*three_matrix_save[B_forBT+1];
					end
				end
				2'b01:begin //4*4
					if(mode_save == 2'b00 || mode_save == 2'b11)begin
						every_mul_result = three_matrix_save[A]*three_matrix_save[B]+three_matrix_save[A+1]*three_matrix_save[B+4]+three_matrix_save[A+2]*three_matrix_save[B+8]+three_matrix_save[A+3]*three_matrix_save[B+12]; 
					end
					else if(mode_save == 2'b01)begin
						every_mul_result = three_matrix_save[A_forAT]*three_matrix_save[B]+three_matrix_save[A_forAT+4]*three_matrix_save[B+4]+three_matrix_save[A_forAT+8]*three_matrix_save[B+8]+three_matrix_save[A_forAT+12]*three_matrix_save[B+12]; 
					end
					else begin
						every_mul_result = three_matrix_save[A]*three_matrix_save[B_forBT]+three_matrix_save[A+1]*three_matrix_save[B_forBT+1]+three_matrix_save[A+2]*three_matrix_save[B_forBT+2]+three_matrix_save[A+3]*three_matrix_save[B_forBT+3];
					end
				end
				2'b10:begin //8*8
					if(mode_save == 2'b00 || mode_save == 2'b11)begin
						every_mul_result = three_matrix_save[A]*three_matrix_save[B]+three_matrix_save[A+1]*three_matrix_save[B+8]+three_matrix_save[A+2]*three_matrix_save[B+16]+three_matrix_save[A+3]*three_matrix_save[B+24]+three_matrix_save[A+4]*three_matrix_save[B+32]+three_matrix_save[A+5]*three_matrix_save[B+40]+three_matrix_save[A+6]*three_matrix_save[B+48]+three_matrix_save[A+7]*three_matrix_save[B+56]; 
					end
					else if(mode_save == 2'b01)begin
						every_mul_result = three_matrix_save[A_forAT]*three_matrix_save[B]+three_matrix_save[A_forAT+8]*three_matrix_save[B+8]+three_matrix_save[A_forAT+16]*three_matrix_save[B+16]+three_matrix_save[A_forAT+24]*three_matrix_save[B+24]+three_matrix_save[A_forAT+32]*three_matrix_save[B+32]+three_matrix_save[A_forAT+40]*three_matrix_save[B+40]+three_matrix_save[A_forAT+48]*three_matrix_save[B+48]+three_matrix_save[A_forAT+56]*three_matrix_save[B+56]; 
					end
					else begin
						every_mul_result = three_matrix_save[A]*three_matrix_save[B_forBT]+three_matrix_save[A+1]*three_matrix_save[B_forBT+1]+three_matrix_save[A+2]*three_matrix_save[B_forBT+2]+three_matrix_save[A+3]*three_matrix_save[B_forBT+3]+three_matrix_save[A+4]*three_matrix_save[B_forBT+4]+three_matrix_save[A+5]*three_matrix_save[B_forBT+5]+three_matrix_save[A+6]*three_matrix_save[B_forBT+6]+three_matrix_save[A+7]*three_matrix_save[B_forBT+7];
					end
				end
				default:begin //16*16
					if(mode_save == 2'b00 || mode_save == 2'b11)begin
						every_mul_result = three_matrix_save[A]*three_matrix_save[B]+three_matrix_save[A+1]*three_matrix_save[B+16]+three_matrix_save[A+2]*three_matrix_save[B+32]+three_matrix_save[A+3]*three_matrix_save[B+48]+three_matrix_save[A+4]*three_matrix_save[B+64]+three_matrix_save[A+5]*three_matrix_save[B+80]+three_matrix_save[A+6]*three_matrix_save[B+96]+three_matrix_save[A+7]*three_matrix_save[B+112]+three_matrix_save[A+8]*three_matrix_save[B+128]+three_matrix_save[A+9]*three_matrix_save[B+144]+three_matrix_save[A+10]*three_matrix_save[B+160]+three_matrix_save[A+11]*three_matrix_save[B+176]+three_matrix_save[A+12]*three_matrix_save[B+192]+three_matrix_save[A+13]*three_matrix_save[B+208]+three_matrix_save[A+14]*three_matrix_save[B+224]+three_matrix_save[A+15]*three_matrix_save[B+240]; 
					end
					else if(mode_save == 2'b01)begin
						every_mul_result = three_matrix_save[A_forAT]*three_matrix_save[B]+three_matrix_save[A_forAT+16]*three_matrix_save[B+16]+three_matrix_save[A_forAT+32]*three_matrix_save[B+32]+three_matrix_save[A_forAT+48]*three_matrix_save[B+48]+three_matrix_save[A_forAT+64]*three_matrix_save[B+64]+three_matrix_save[A_forAT+80]*three_matrix_save[B+80]+three_matrix_save[A_forAT+96]*three_matrix_save[B+96]+three_matrix_save[A_forAT+112]*three_matrix_save[B+112]+three_matrix_save[A_forAT+128]*three_matrix_save[B+128]+three_matrix_save[A_forAT+144]*three_matrix_save[B+144]+three_matrix_save[A_forAT+160]*three_matrix_save[B+160]+three_matrix_save[A_forAT+176]*three_matrix_save[B+176]+three_matrix_save[A_forAT+192]*three_matrix_save[B+192]+three_matrix_save[A_forAT+208]*three_matrix_save[B+208]+three_matrix_save[A_forAT+224]*three_matrix_save[B+224]+three_matrix_save[A_forAT+240]*three_matrix_save[B+240]; 
					end
					else begin
						every_mul_result = three_matrix_save[A]*three_matrix_save[B_forBT]+three_matrix_save[A+1]*three_matrix_save[B_forBT+1]+three_matrix_save[A+2]*three_matrix_save[B_forBT+2]+three_matrix_save[A+3]*three_matrix_save[B_forBT+3]+three_matrix_save[A+4]*three_matrix_save[B_forBT+4]+three_matrix_save[A+5]*three_matrix_save[B_forBT+5]+three_matrix_save[A+6]*three_matrix_save[B_forBT+6]+three_matrix_save[A+7]*three_matrix_save[B_forBT+7]+three_matrix_save[A+8]*three_matrix_save[B_forBT+8]+three_matrix_save[A+9]*three_matrix_save[B_forBT+9]+three_matrix_save[A+10]*three_matrix_save[B_forBT+10]+three_matrix_save[A+11]*three_matrix_save[B_forBT+11]+three_matrix_save[A+12]*three_matrix_save[B_forBT+12]+three_matrix_save[A+13]*three_matrix_save[B_forBT+13]+three_matrix_save[A+14]*three_matrix_save[B_forBT+14]+three_matrix_save[A+15]*three_matrix_save[B_forBT+15];
					end
				end
			endcase
		end
		else begin
			every_mul_result = 0;
		end
	end
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		OUTPUT_SAVE <= 0;
	end
	else begin
		if(cs == CAL && COUNT_IN > 0 && COUNT_IN < square_side_twice+1)begin
			if(mode_save == 2'b00 || mode_save == 2'b01 || mode_save == 2'b10)begin
				OUTPUT_SAVE <= OUTPUT_SAVE+three_matrix_save[2*square_side_twice+INDEX_J*square_side+INDEX_I]*every_mul_result;
			end
			else begin
				OUTPUT_SAVE <= OUTPUT_SAVE+three_matrix_save[2*square_side_twice+INDEX_I*square_side+INDEX_J]*every_mul_result;
			end
		end
		else begin
			if(out_valid)begin
				OUTPUT_SAVE <= 0;
			end
			else begin
				OUTPUT_SAVE <= OUTPUT_SAVE;
			end
		end
	end
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		INDEX_J <= 0;
		INDEX_I <= 0;
	end
	else begin
		if(cs == CAL && COUNT_IN > 0)begin
			if(INDEX_J == square_side-1)begin
				INDEX_I <= INDEX_I+1;
				INDEX_J <= 0;
			end
			else begin
				INDEX_J <= INDEX_J+1;
				INDEX_I <= INDEX_I;
			end
		end
		else begin
			INDEX_I <= 0;
			INDEX_J <= 0;
		end
	end
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		B <= 0;
	end
	else begin
		if(ns == CAL)begin
			if(B == square_side_twice+square_side-1)begin
				B <= square_side_twice;
			end
			else begin
				B <= B+1;
			end
		end
		else begin
			B <= square_side_twice-1;
		end
	end
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		A <= 0;
	end
	else begin
		if(ns == CAL)begin
			if(B == square_side_twice+square_side-1)begin
				A <= A+square_side;
			end
		end
		else begin
			A <= 0;
		end
	end
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		A_forAT <= 0;
	end
	else begin
		if(ns == CAL)begin
			if(B == square_side_twice+square_side-1)begin
				A_forAT <= A_forAT+1;
			end
		end
		else begin
			A_forAT <= 0;
		end
	end
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		B_forBT <= 0;
	end
	else begin
		if(ns == CAL)begin
			if(B_forBT == square_side_twice+square_side*(square_side-1))begin
				B_forBT <= square_side_twice;
			end
			else begin
				B_forBT <= B_forBT+square_side;
			end
		end
		else begin
			B_forBT <= square_side_twice-square_side;
		end
	end
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		COUNT_IN <= 0;
	end
	else begin
		if(cs == CAL)begin
			COUNT_IN <= COUNT_IN+1;
		end
		else begin
			COUNT_IN <= 0;
		end
	end
end
//---------------------------------------------------------------------
//   OUTPUT
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_value <= 0;
	end
	else begin
		if(cs == OUT_DATA)begin
			out_value <= OUTPUT_SAVE;
		end
		else begin
			out_value <= 0;
		end
	end
end
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_valid <= 0;
	end
	else begin
		if(cs == OUT_DATA)begin
			out_valid <= 1;
		end
		else begin
			out_valid <= 0;
		end
	end
end
endmodule
