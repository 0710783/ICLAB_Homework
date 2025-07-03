// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on

module SNN(
	// Input signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	img,
	ker,
	weight,

	// Output signals
	out_valid,
	out_data
);

input clk;
input rst_n;
input in_valid;
input cg_en;
input [7:0] img;
input [7:0] ker;
input [7:0] weight;

output reg out_valid;
output reg [9:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
reg [7:0]img_save[35:0];
reg [7:0]img_save2[35:0];
reg [7:0]ker_save[8:0];
reg [7:0]weight_save[3:0];
reg [2:0]cs,ns;
reg [7:0]input_count;
reg [23:0]feature_map_before_quan[15:0];
reg [16:0]fouronemap[3:0];
reg [16:0]fouronemap2[3:0];
reg [5:0]count_for_feature_map_before_quan;
reg [5:0]count_for_feature_map_before_quan2;
reg [5:0]count_save;
reg [5:0]count_save2;
reg [7:0]twotwomap[3:0];
reg [5:0]count_cal,count_cal2;
reg [3:0]index_max;
reg [8:0]distance_before[3:0];
reg [11:0]distance;
parameter IDLE = 3'b000;
parameter INPUT_DATA = 3'b001;
parameter CAL_1_GET_2 = 3'b010;
parameter CAL = 3'b011;
parameter CAL_2 = 3'b100;
parameter CAL_2_START = 3'b101;
parameter OUTPUT_DATA = 3'b110;
wire save_sleep1,save_sleep2,save_sleep3,save_sleep4,save_sleep5,save_sleep6;
integer i;
/*** GC ***/
wire clk1, clk2, clk3, clk4, clk5, clk6;
wire sleep1, sleep2, sleep3, sleep4, sleep5, sleep6;

assign sleep1 = cg_en && (save_sleep1!=1);
assign sleep2 = cg_en && (save_sleep2!=1);
assign sleep3 = cg_en && (save_sleep3!=1);
assign sleep4 = cg_en && (save_sleep4!=1);
assign sleep5 = cg_en && (save_sleep5!=1);
assign sleep6 = cg_en && (save_sleep6!=1);
GATED_OR GATED_CLK1(
	.CLOCK(clk),
	.SLEEP_CTRL(sleep1),
	.RST_N(rst_n),
	.CLOCK_GATED(clk1)
);

GATED_OR GATED_CLK2(
	.CLOCK(clk),
	.SLEEP_CTRL(sleep2),
	.RST_N(rst_n),
	.CLOCK_GATED(clk2)
);

GATED_OR GATED_CLK3(
	.CLOCK(clk),
	.SLEEP_CTRL(sleep3),
	.RST_N(rst_n),
	.CLOCK_GATED(clk3)
);

GATED_OR GATED_CLK4(
	.CLOCK(clk),
	.SLEEP_CTRL(sleep4),
	.RST_N(rst_n),
	.CLOCK_GATED(clk4)
);

GATED_OR GATED_CLK5(
	.CLOCK(clk),
	.SLEEP_CTRL(sleep5),
	.RST_N(rst_n),
	.CLOCK_GATED(clk5)
);

GATED_OR GATED_CLK6(
	.CLOCK(clk),
	.SLEEP_CTRL(sleep6),
	.RST_N(rst_n),
	.CLOCK_GATED(clk6)
);
assign save_sleep1 = (count_cal2 == 9 || count_cal2 == 10)?1:0;
assign save_sleep2 = (ns == IDLE || count_cal2 == 8)?1:0;
assign save_sleep3 = (ns == IDLE || count_cal2 == 5 || count_cal2==6)?1:0;
assign save_sleep4 = (ns == IDLE || count_cal == 5 || count_cal == 6)?1:0;
assign save_sleep5 = (ns == IDLE || ns == CAL_1_GET_2 || ns == CAL_2)?1:0;
assign save_sleep6 = (ns == IDLE || ns == INPUT_DATA || ns == CAL_1_GET_2)?1:0;
//==============================================//
//                  FSM                         //
//==============================================//
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cs <= IDLE;
	end
	else begin
		cs <= ns;
	end
end
always@(*)begin
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
				if(input_count == 36)begin
					ns = CAL_1_GET_2;
				end
				else begin
					ns = INPUT_DATA;
				end
			end
			CAL_1_GET_2:begin
				if(input_count == 72)begin
					ns = CAL;
				end
				else begin
					ns = CAL_1_GET_2;
				end
			end
			CAL:begin
				if(count_cal == 8)begin
					ns = CAL_2;
				end
				else begin
					ns = CAL;
				end
			end
			CAL_2:begin
				if(count_for_feature_map_before_quan2 == 32)begin
					ns = CAL_2_START;
				end
				else begin
					ns = CAL_2;
				end
			end
			CAL_2_START:begin
				if(count_cal2 == 11)begin
					ns = OUTPUT_DATA;
				end
				else begin
					ns = CAL_2_START;
				end
			end
			OUTPUT_DATA:begin
				ns = IDLE;
			end
			default:begin
				ns = IDLE;
			end
		endcase
	end
end
//==============================================//
//                  input                       //
//==============================================//
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		input_count <= 0;
	end
	else begin
		if(in_valid)begin
			input_count <= input_count+1;
		end
		else begin
			input_count <= 0;
		end
	end
end
always@(posedge clk6 or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<36;i=i+1)begin
			img_save[i] <= 0;
			img_save2[i] <= 0;
		end
		for(i=0;i<9;i=i+1)begin
			ker_save[i] <= 0;
		end
	    for(i=0;i<4;i=i+1)begin
			weight_save[i] <= 0;
		end
	end
	else begin
		if(ns == INPUT_DATA || ns == CAL_1_GET_2)begin
			if(input_count < 5)begin
				weight_save[input_count] <= weight;
				ker_save[input_count] <= ker;
				img_save[input_count] <= img;
			end
			else if(input_count > 4 && input_count < 10)begin
				ker_save[input_count] <= ker;
				img_save[input_count] <= img;
			end
			else if(input_count > 9 && input_count < 36)begin
				img_save[input_count] <= img;
			end
			else if(input_count > 35 && input_count < 72)begin
				img_save2[input_count-36] <= img;
			end
		end	
		else if(ns == IDLE)begin
			for(i=0;i<36;i=i+1)begin
				img_save[i] <= 0;
				img_save2[i] <= 0;
			end
			for(i=0;i<9;i=i+1)begin
				ker_save[i] <= 0;
			end
			for(i=0;i<4;i=i+1)begin
				weight_save[i] <= 0;
			end
		end
	end
end
//==============================================//
//                  CAL                         //
//==============================================//
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		count_for_feature_map_before_quan <= 0;
	end
	else begin
		if(ns == CAL_1_GET_2 && count_for_feature_map_before_quan < 32)begin
			count_for_feature_map_before_quan <= count_for_feature_map_before_quan+1;
		end
		else if(ns == IDLE)begin
			count_for_feature_map_before_quan <= 0;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		count_for_feature_map_before_quan2 <= 0;
	end
	else begin
		if(ns == CAL_2 && count_for_feature_map_before_quan2 < 32)begin
			count_for_feature_map_before_quan2 <= count_for_feature_map_before_quan2+1;
		end
		else if(ns == IDLE)begin
			count_for_feature_map_before_quan2 <= 0;
		end
	end
end
always@(*)begin
	if(!rst_n)begin
		count_save = 0;
	end
	else begin
		if(ns == CAL_1_GET_2)begin
			if(count_for_feature_map_before_quan < 4)begin
				count_save = count_for_feature_map_before_quan;
			end
			else if(count_for_feature_map_before_quan > 3 && count_for_feature_map_before_quan < 8)begin
				count_save = count_for_feature_map_before_quan + 2;
			end
			else if(count_for_feature_map_before_quan > 7 && count_for_feature_map_before_quan < 12)begin
				count_save = count_for_feature_map_before_quan + 4;
			end
			else begin
				count_save = count_for_feature_map_before_quan + 6;
			end
		end
		else begin
			count_save = 0;
		end
	end
end
always@(*)begin
	if(!rst_n)begin
		count_save2 = 0;
	end
	else begin
		if(ns == CAL_2)begin
			if(count_for_feature_map_before_quan2 < 4)begin
				count_save2 = count_for_feature_map_before_quan2;
			end
			else if(count_for_feature_map_before_quan2 > 3 && count_for_feature_map_before_quan2 < 8)begin
				count_save2 = count_for_feature_map_before_quan2 + 2;
			end
			else if(count_for_feature_map_before_quan2 > 7 && count_for_feature_map_before_quan2 < 12)begin
				count_save2 = count_for_feature_map_before_quan2 + 4;
			end
			else begin
				count_save2 = count_for_feature_map_before_quan2 + 6;
			end
		end
		else begin
			count_save2 = 0;
		end
	end
end
always@(posedge clk5 or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<16;i=i+1)begin
			feature_map_before_quan[i] <= 0;
		end
	end
	else begin
		if(ns == CAL_1_GET_2 && count_for_feature_map_before_quan < 32)begin
			if(count_for_feature_map_before_quan < 16)begin
				feature_map_before_quan[count_for_feature_map_before_quan] <= img_save[count_save]*ker_save[0]+img_save[count_save+1]*ker_save[1]+img_save[count_save+2]*ker_save[2]+img_save[count_save+6]*ker_save[3]+img_save[count_save+7]*ker_save[4]+img_save[count_save+8]*ker_save[5]+img_save[count_save+12]*ker_save[6]+img_save[count_save+13]*ker_save[7]+img_save[count_save+14]*ker_save[8];
			end
			else begin
				feature_map_before_quan[count_for_feature_map_before_quan-16] <= feature_map_before_quan[count_for_feature_map_before_quan-16]/2295;
			end
		end
		else if(ns == CAL_2 && count_for_feature_map_before_quan2 < 32)begin
			if(count_for_feature_map_before_quan2 < 16)begin
				feature_map_before_quan[count_for_feature_map_before_quan2] <= img_save2[count_save2]*ker_save[0]+img_save2[count_save2+1]*ker_save[1]+img_save2[count_save2+2]*ker_save[2]+img_save2[count_save2+6]*ker_save[3]+img_save2[count_save2+7]*ker_save[4]+img_save2[count_save2+8]*ker_save[5]+img_save2[count_save2+12]*ker_save[6]+img_save2[count_save2+13]*ker_save[7]+img_save2[count_save2+14]*ker_save[8];
			end
			else begin
				feature_map_before_quan[count_for_feature_map_before_quan2-16] <= feature_map_before_quan[count_for_feature_map_before_quan2-16]/2295;
			end
		end
		else if(ns == IDLE)begin
			for(i=0;i<16;i=i+1)begin
				feature_map_before_quan[i] <= 0;
			end
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		count_cal <= 0;
		count_cal2 <= 0;
	end
	else begin
		if(ns == CAL)begin
			count_cal <= count_cal + 1;
		end
		else if(ns == CAL_2_START)begin
			count_cal2 <= count_cal2 + 1;
		end
		else if(ns == IDLE)begin
			count_cal <= 0;
			count_cal2 <= 0;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		index_max <= 0;
	end
	else begin
		if(ns == CAL)begin
			if(count_cal == 0)begin
				index_max <= 0;
			end
			else if(count_cal == 1)begin
				index_max <= 1;
			end
			else if(count_cal == 2)begin
				index_max <= 4;
			end
			else begin
				index_max <= 5;
			end
		end
		else if(ns == CAL_2_START)begin
			if(count_cal2 == 0)begin
				index_max <= 0;
			end
			else if(count_cal2 == 1)begin
				index_max <= 1;
			end
			else if(count_cal2 == 2)begin
				index_max <= 4;
			end
			else begin
				index_max <= 5;
			end
		end
		else if(ns == IDLE)begin
			index_max <= 0;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<4;i=i+1)begin
			twotwomap[i] <= 0;
		end
	end
	else begin
		if(ns == CAL || cs == CAL_2_START)begin
			if(twotwomap[0] <= feature_map_before_quan[index_max])begin
				twotwomap[0] <= feature_map_before_quan[index_max];
			end
			if(twotwomap[1] <= feature_map_before_quan[index_max+2])begin
				twotwomap[1] <= feature_map_before_quan[index_max+2];
			end
			if(twotwomap[2] <= feature_map_before_quan[index_max+8])begin
				twotwomap[2] <= feature_map_before_quan[index_max+8];
			end
			if(twotwomap[3] <= feature_map_before_quan[index_max+10])begin
				twotwomap[3] <= feature_map_before_quan[index_max+10];
			end
		end
		else if(ns == IDLE || (ns == CAL_2_START && cs == CAL_2))begin
			for(i=0;i<4;i=i+1)begin
				twotwomap[i] <= 0;
			end
		end
	end
end
always@(posedge clk4 or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<4;i=i+1)begin
			fouronemap[i] <= 0;
		end
	end
	else begin
		if(count_cal == 5)begin
			fouronemap[0] <= twotwomap[0]*weight_save[0]+twotwomap[1]*weight_save[2];
			fouronemap[1] <= twotwomap[0]*weight_save[1]+twotwomap[1]*weight_save[3];
			fouronemap[2] <= twotwomap[2]*weight_save[0]+twotwomap[3]*weight_save[2];
			fouronemap[3] <= twotwomap[2]*weight_save[1]+twotwomap[3]*weight_save[3];
		end
		else if(count_cal == 6)begin
			for(i=0;i<4;i=i+1)begin
				fouronemap[i] <= fouronemap[i]/510;
			end
		end
		else if(ns == IDLE)begin
			for(i=0;i<4;i=i+1)begin
				fouronemap[i] <= 0;
			end
		end
	end
end
always@(posedge clk3 or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<4;i=i+1)begin
			fouronemap2[i] <= 0;
		end
	end
	else begin
		if(count_cal2 == 5)begin
			fouronemap2[0] <= twotwomap[0]*weight_save[0]+twotwomap[1]*weight_save[2];
			fouronemap2[1] <= twotwomap[0]*weight_save[1]+twotwomap[1]*weight_save[3];
			fouronemap2[2] <= twotwomap[2]*weight_save[0]+twotwomap[3]*weight_save[2];
			fouronemap2[3] <= twotwomap[2]*weight_save[1]+twotwomap[3]*weight_save[3];
		end
		else if(count_cal2 == 6)begin
			for(i=0;i<4;i=i+1)begin
				fouronemap2[i] <= fouronemap2[i]/510;
			end
		end
		else if(ns == IDLE)begin
			for(i=0;i<4;i=i+1)begin
				fouronemap2[i] <= 0;
			end
		end
	end
end
always@(posedge clk2 or negedge rst_n)begin
	if(!rst_n)begin
		distance_before[0] <= 0;
		distance_before[1] <= 0;
		distance_before[2] <= 0;
		distance_before[3] <= 0;
	end
	else begin
		if(count_cal2 == 8)begin
			if(fouronemap[0] > fouronemap2[0])begin
				distance_before[0] <= fouronemap[0] - fouronemap2[0];
			end
			else begin
				distance_before[0] <= fouronemap2[0] - fouronemap[0];
			end
			if(fouronemap[1] > fouronemap2[1])begin
				distance_before[1] <= fouronemap[1] - fouronemap2[1];
			end
			else begin
				distance_before[1] <= fouronemap2[1] - fouronemap[1];
			end
			if(fouronemap[2] > fouronemap2[2])begin
				distance_before[2] <= fouronemap[2] - fouronemap2[2];
			end
			else begin
				distance_before[2] <= fouronemap2[2] - fouronemap[2];
			end
			if(fouronemap[3] > fouronemap2[3])begin
				distance_before[3] <= fouronemap[3] - fouronemap2[3];
			end
			else begin
				distance_before[3] <= fouronemap2[3] - fouronemap[3];
			end
		end
		else if(ns == IDLE)begin
			distance_before[0] <= 0;
			distance_before[1] <= 0;
			distance_before[2] <= 0;
			distance_before[3] <= 0;
		end
	end
end
always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n)begin
		distance <= 0;
	end
	else begin
		if(count_cal2 == 9)begin
			distance <= distance_before[0]+distance_before[1]+distance_before[2]+distance_before[3];
		end
		else if(count_cal2 == 10)begin
			if(distance < 16)begin
				distance <= 0;
			end
		end
	end
end
//==============================================//
//                  output                      //
//==============================================//
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_data <= 0;
	end
	else begin
		if(ns == OUTPUT_DATA)begin
			out_data <= distance;
		end
		else begin
			out_data <= 0;
		end
	end
end
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

endmodule
