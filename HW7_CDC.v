`include "AFIFO.v"

module CDC #(parameter DSIZE = 8,
			   parameter ASIZE = 4)(
	//Input Port
	rst_n,
	clk1,
    clk2,
	in_valid,
    doraemon_id,
    size,
    iq_score,
    eq_score,
    size_weight,
    iq_weight,
    eq_weight,
    //Output Port
	ready,
    out_valid,
	out,
    
); 
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
output reg  [7:0] out;
output reg	out_valid,ready;

input rst_n, clk1, clk2, in_valid;
input  [4:0]doraemon_id;
input  [7:0]size;
input  [7:0]iq_score;
input  [7:0]eq_score;
input [2:0]size_weight,iq_weight,eq_weight;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
parameter IDLE = 3'b101;
parameter INPUTDATA = 3'b001;
parameter READYDATA = 3'b010;
parameter CAL = 3'b011;
parameter FINISH = 3'b100;

reg [7:0]out_reg;
reg out_valid_reg;
reg [2:0]cs,ns,nnn;
reg [4:0]doraemon_id_save[4:0];
reg [7:0]eq_score_save[4:0];
reg [7:0]iq_score_save[4:0];
reg [7:0]size_save[4:0];
reg [2:0]eq_weight_save;
reg [2:0]iq_weight_save;
reg [2:0]size_weight_save;
reg [2:0]count_init_four;
reg [12:0]finalvalue[4:0];
reg [2:0]min_door;
reg [4:0]min_id;
reg [7:0]output_final;
reg [7:0]outout_reg;
reg [7:0]count60;
reg [7:0]count5;
reg pullhigh;
reg judgecal;
reg [15:0]calall;
wire[7:0]output_inputa;
wire rempty,wfull,rinc,winc;
wire [7:0]real_output;
integer i;
//---------------------------------------------------------------------
//   FSM for clk1 and input
//---------------------------------------------------------------------
always@(posedge clk1 or negedge rst_n)begin
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
					ns = INPUTDATA;
				end
				else begin
					ns = IDLE;
				end
			end
			INPUTDATA:begin
				if(count_init_four < 4)begin
					ns = INPUTDATA;
				end
				else begin
					ns = READYDATA;
				end
			end
			READYDATA:begin
				if(in_valid)begin
					ns = CAL;
				end
				else begin
					ns = READYDATA;
				end
			end
			CAL:begin
				if(!in_valid)begin
					ns = READYDATA;
				end
				else if(!in_valid)begin
					ns = IDLE;
				end
				else begin
					ns = CAL;
				end
			end
			default:begin
				ns = IDLE;
			end
		endcase
	end
end
always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n)begin
		nnn <= 0;
	end
	else begin
		nnn <= cs;
	end
end
always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n)begin
		count_init_four <= 0;
	end
	else begin
		if(count_init_four == 4)begin
			count_init_four <= 0;
		end
		else if(in_valid)begin
			count_init_four <= count_init_four + 1;
		end
	end
end
//---------------------------------------------------------------------
//   save initial data
//---------------------------------------------------------------------
always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n)begin
		calall <= 0;
	end
	else begin
		if(in_valid)begin
			calall <= calall+1;
		end
	end
end
always@(*)begin
	if(!rst_n)begin
		finalvalue[0] = 0;
		finalvalue[1] = 0;
		finalvalue[2] = 0;
		finalvalue[3] = 0;
		finalvalue[4] = 0;
	end
	else begin
		finalvalue[0] = size_weight_save*size_save[0]+iq_weight_save*iq_score_save[0]+eq_weight_save*eq_score_save[0];
		finalvalue[1] = size_weight_save*size_save[1]+iq_weight_save*iq_score_save[1]+eq_weight_save*eq_score_save[1];
        finalvalue[2] = size_weight_save*size_save[2]+iq_weight_save*iq_score_save[2]+eq_weight_save*eq_score_save[2];
		finalvalue[3] = size_weight_save*size_save[3]+iq_weight_save*iq_score_save[3]+eq_weight_save*eq_score_save[3];
		finalvalue[4] = size_weight_save*size_save[4]+iq_weight_save*iq_score_save[4]+eq_weight_save*eq_score_save[4];
	end
end
always@(*)begin
	if(!rst_n)begin
		min_door = 0;
		min_id = 0;
	end
	else begin
		if(cs == 2 && !judgecal)begin
			min_door = 4;
			min_id = 0;
		end
		else if((finalvalue[0] >= finalvalue[1] && finalvalue[0] >= finalvalue[2] && finalvalue[0] >= finalvalue[3] && finalvalue[0] >= finalvalue[4]))begin
			min_door = 3'b000;
			min_id = doraemon_id_save[0];
		end
		else if((finalvalue[1] >= finalvalue[0] && finalvalue[1] >= finalvalue[2] && finalvalue[1] >= finalvalue[3] && finalvalue[1] >= finalvalue[4]))begin
			if(finalvalue[1] == finalvalue[0])begin
				min_door = 3'b000;
				min_id = doraemon_id_save[0];
			end
			else begin
				min_door = 3'b001;
				min_id = doraemon_id_save[1];
			end
		end
		else if((finalvalue[2] >= finalvalue[0] && finalvalue[2] >= finalvalue[1] && finalvalue[2] >= finalvalue[3] && finalvalue[2] >= finalvalue[4]))begin
			if(finalvalue[2] == finalvalue[0])begin
				min_door = 3'b000;
				min_id = doraemon_id_save[0];
			end
			else if(finalvalue[2] == finalvalue[1] && finalvalue[1] > finalvalue[0])begin
				min_door = 3'b001;
				min_id = doraemon_id_save[1];
			end
			else begin
				min_door = 3'b010;
				min_id = doraemon_id_save[2];
			end
		end
		else if((finalvalue[3] >= finalvalue[0] && finalvalue[3] >= finalvalue[1] && finalvalue[3] >= finalvalue[2] && finalvalue[3] >= finalvalue[4]))begin
			if(finalvalue[3] == finalvalue[0])begin
				min_door = 3'b000;
				min_id = doraemon_id_save[0];
			end
			else if(finalvalue[3] == finalvalue[1] && finalvalue[1] > finalvalue[0])begin
				min_door = 3'b001;
				min_id = doraemon_id_save[1];
			end
			else if(finalvalue[3] == finalvalue[2] && finalvalue[2] > finalvalue[0] && finalvalue[2] > finalvalue[1])begin
				min_door = 3'b010;
				min_id = doraemon_id_save[2];
			end
			else begin
				min_door = 3'b011;
				min_id = doraemon_id_save[3];
			end
		end
		else begin
			min_door = 3'b100;
			min_id = doraemon_id_save[4];
		end
	end
end
always@(*)begin
	if(!rst_n)begin
		output_final = 0;
	end
	else begin
		output_final = {min_door,min_id};
	end
end
always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n)begin
		doraemon_id_save[0] <= 0;
		doraemon_id_save[1] <= 0;
		doraemon_id_save[2] <= 0;
		doraemon_id_save[3] <= 0;
		doraemon_id_save[4] <= 0;
	end
	else begin
		if(in_valid && ns!=CAL)begin
			doraemon_id_save[count_init_four] <= doraemon_id;
		end
		else if(in_valid && ns == CAL)begin
			doraemon_id_save[min_door] <= doraemon_id;
		end
	end
end
always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n)begin
		eq_score_save[0] <= 0;
		eq_score_save[1] <= 0;
		eq_score_save[2] <= 0;
		eq_score_save[3] <= 0;
		eq_score_save[4] <= 0;
	end
	else begin
		if(in_valid && ns!=CAL)begin
			eq_score_save[count_init_four] <= eq_score;
		end
		else if(in_valid && ns == CAL)begin
			eq_score_save[min_door] <= eq_score;
		end
	end
end
always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n)begin
		iq_score_save[0] <= 0;
		iq_score_save[1] <= 0;
		iq_score_save[2] <= 0;
		iq_score_save[3] <= 0;
		iq_score_save[4] <= 0;
	end
	else begin
		if(in_valid && ns!=CAL)begin
			iq_score_save[count_init_four] <= iq_score;
		end
		else if(in_valid && ns == CAL)begin
			iq_score_save[min_door] <= iq_score;
		end
	end
end
always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n)begin
		size_save[0] <= 0;
		size_save[1] <= 0;
		size_save[2] <= 0;
		size_save[3] <= 0;
		size_save[4] <= 0;
	end
	else begin
		if(in_valid && ns!=CAL)begin
			size_save[count_init_four] <= size;
		end
		else if(in_valid)begin
			size_save[min_door] <= size;
		end
	end
end
always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n)begin
		count60 <= 0;
	end
	else begin
		if(cs == CAL && count60 < 6)begin
			count60 <= count60 + 1;
		end
		else begin
			count60 <= 0;
		end
	end
end
always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n)begin
		ready <= 0;
	end
	else begin
		if(calall > 5998)begin
			ready <= 0;
		end
		else if(cs == READYDATA && calall < 5999)begin
			ready <= 1;
		end
		else if(cs == CAL)begin
			if(count60 == 6)begin
				ready <= 0;
			end
		end
	end
end
always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n)begin
		judgecal <= 0;
	end
	else begin
		if(cs == CAL)begin
			judgecal <= 1;
		end
	end
end
always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n)begin
		eq_weight_save <= 0;
		iq_weight_save <= 0;
		size_weight_save <= 0;
	end
	else begin
		if(ns == CAL)begin
			eq_weight_save <= eq_weight;
			iq_weight_save <= iq_weight;
			size_weight_save <= size_weight;
		end
	end
end
always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n)begin
		outout_reg <= 0;
	end
	else begin
		outout_reg <= output_final;
	end
end
assign winc = (nnn == CAL)?1'b1:1'b0;
assign rinc = (!rempty)?1'b1:1'b0;
assign output_inputa = outout_reg;
AFIFO #(.DSIZE(8),.ASIZE(4)) AFIFO1(
	//Input Port
	.rst_n(rst_n),
    //Input Port (read)
    .rclk(clk2),
    .rinc(rinc),
	//Input Port (write)
    .wclk(clk1),
    .winc(winc),
	.wdata(output_inputa),

    //Output Port (read)
    .rempty(rempty),
	.rdata(real_output),
    //Output Port (write)
    .wfull(wfull)
);
//---------------------------------------------------------------------
//   OUTPUT
//---------------------------------------------------------------------
always@(posedge clk2 or negedge rst_n)begin
	if(!rst_n)begin
		count5 <= 0;
	end
	else begin
		count5 <= count5 + 1;
	end
end
always@(posedge clk2 or negedge rst_n)begin
	if(!rst_n)begin
		pullhigh <= 0;
	end
	else begin
		if(count5 == 10)begin
			pullhigh <= 1;
		end
	end
end
always@(posedge clk2 or negedge rst_n)begin
	if(!rst_n)begin
		out_reg <= 0;
	end
	else begin
		if(pullhigh)begin
			if(!rempty)begin
				out_reg <= real_output;
			end
		end
	end
end
always@(posedge clk2 or negedge rst_n)begin
	if(!rst_n)begin
		out_valid_reg <= 0;
	end
	else begin
		if(pullhigh)begin
			if(!rempty)begin
				out_valid_reg <= 1;
			end
			else begin
				out_valid_reg <= 0;
			end
		end
	end
end
always@(posedge clk2 or negedge rst_n)begin
	if(!rst_n)begin
		out_valid <= 0;
	end
	else begin
		if(pullhigh)begin
			out_valid <= out_valid_reg;
		end
	end
end
always@(posedge clk2 or negedge rst_n)begin
	if(!rst_n)begin
		out <= 0;
	end
	else begin
		if(!out_valid_reg)begin
			out <= 0;
		end
		else if(pullhigh)begin
			out <= out_reg;
		end
	end
end
endmodule
