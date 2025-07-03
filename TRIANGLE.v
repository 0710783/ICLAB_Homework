//synopsys translate_off
`include "DW_div.v"
`include "DW_div_seq.v"
`include "DW_div_pipe.v"
//synopsys translate_on

module TRIANGLE(
    clk,
    rst_n,
    in_valid,
    in_length,
    out_cos,
    out_valid,
    out_tri
);
input wire clk, rst_n, in_valid;
input wire [7:0] in_length;

output reg out_valid;
output reg [15:0] out_cos;
output reg [1:0] out_tri;
parameter IDLE = 3'b000;
parameter INPUT_DATA = 3'b001;
parameter CAL = 3'b010;
parameter OUTPUT_DATA = 3'b011;
reg [2:0]cs,ns;
reg signed[17:0]save_input[2:0];
reg [2:0]count;
reg signed[17:0]out_cos_save[2:0];
reg [5:0]cnt;
reg signed[17:0]rega,regb;
wire signed[30:0]regalarge;
reg [2:0]outcount;
integer i;
parameter inst_a_width = 31;
parameter inst_b_width = 18;
parameter inst_tc_mode = 1;
parameter inst_rem_mode = 1;
parameter inst_num_stages = 10;
parameter inst_stall_mode = 1;
parameter inst_rst_mode = 1;
parameter inst_op_iso_mode = 0;
wire inst_hold;
wire inst_start;
wire signed[inst_a_width-1 : 0] inst_a;
wire signed[inst_b_width-1 : 0] inst_b;
wire inst_en;
wire divide_by_0_inst;
wire signed[inst_a_width-1 : 0] quotient_inst;
wire signed[inst_b_width-1 : 0] remainder_inst;
//======================
//FSM
//======================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cs <= IDLE;
	end
	else begin
		cs <= ns;
	end
end
always @(*)begin
	if(!rst_n)begin
		ns = IDLE;
	end
	else begin
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
				if(!in_valid)begin
					ns = CAL;
				end
				else begin
					ns = INPUT_DATA;
				end
			end
			CAL:begin
				if(cnt == 32)begin
					ns = OUTPUT_DATA;
				end
				else begin
					ns = CAL;
				end
			end
			OUTPUT_DATA:begin
				if(outcount == 3)begin
					ns = IDLE;
				end
				else begin
					ns = OUTPUT_DATA;
				end
			end
			default:begin
				ns = IDLE;
			end
		endcase
	end
end
//======================
//getinput
//======================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		save_input[0] <= 0;
		save_input[1] <= 0;
		save_input[2] <= 0;
		count <= 0;
	end
	else begin
		if(ns == INPUT_DATA)begin
			count <= count+1;
			save_input[count] <= in_length;
		end
		else begin
			count <= 0;
			save_input[0] <= save_input[0];
			save_input[1] <= save_input[1];
			save_input[2] <= save_input[2];
		end
	end
end
//=========================
//cal
//=========================
DW_div_pipe #(inst_a_width,
			inst_b_width,
			inst_tc_mode, inst_rem_mode,
			inst_num_stages,
			inst_stall_mode,
			inst_rst_mode,
			inst_op_iso_mode)
			U1 (.clk(clk),
			.rst_n(rst_n),
			.en(inst_en),
			.a(inst_a),
			.b(inst_b),
			.quotient(quotient_inst),
			.remainder(remainder_inst),
			.divide_by_0(divide_by_0_inst) );
assign regalarge = {rega,{13'b0}};
assign inst_a = regalarge;
assign inst_b = regb;
assign inst_hold = 0;
assign inst_start = 0;
assign inst_en = 1;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		rega <= 0;
		regb <= 0;
	end
	else begin
		if(cnt == 1)begin
			rega <= save_input[1]*save_input[1]+save_input[2]*save_input[2]-save_input[0]*save_input[0];
			regb <= 2* save_input[1]*save_input[2];
		end
		else if(cnt == 2)begin
			rega <= save_input[0]*save_input[0]+save_input[2]*save_input[2]-save_input[1]*save_input[1];
			regb <= 2* save_input[0]*save_input[2];	
		end
		else if(cnt == 3)begin
			rega <= save_input[0]*save_input[0]+save_input[1]*save_input[1]-save_input[2]*save_input[2];
			regb <= 2* save_input[0]*save_input[1];	
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cnt <= 0;
	end
	else begin
		if(ns == CAL)begin
			cnt <= cnt+1;
		end
		else if(ns == IDLE)begin
			cnt <= 0;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_cos_save[0] <= 0;
		out_cos_save[1] <= 0;
		out_cos_save[2] <= 0;
	end
	else begin
		if(cnt == 11)begin
			out_cos_save[0] <= quotient_inst;
		end
		else if(cnt == 12)begin
			out_cos_save[1] <= quotient_inst;
		end
		else if(cnt == 13)begin
			out_cos_save[2] <= quotient_inst;
		end
	end
end
//======================
//output
//======================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_valid <= 0;
	end
	else begin
		if(ns == OUTPUT_DATA)begin
			out_valid <= 1;
		end
		else begin
			out_valid <= 0;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_cos <= 0;
		outcount <= 0;
	end
	else begin
		if(ns == OUTPUT_DATA)begin
			outcount <= outcount + 1;
			out_cos <= out_cos_save[outcount];
		end
		else if(ns == IDLE)begin
			outcount <= 0;
			out_cos <= 0;
		end
	end	
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_tri <= 0;
	end
	else begin
		if(ns == OUTPUT_DATA)begin
			if(out_cos_save[0]==0 || out_cos_save[1]==0 || out_cos_save[2]==0)begin
				out_tri <= 2'b11;
			end
			else begin
				if(out_cos_save[0] < 0 || out_cos_save[1] < 0 || out_cos_save[2] < 0)begin
					out_tri <= 2'b01;
				end
				else begin
					out_tri <= 2'b00;
				end
			end
		end
	end
end
endmodule
