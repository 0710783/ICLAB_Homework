//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright Optimum Application-Specific Integrated System Laboratory
//    All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : EC_TOP.v
//   	Module Name : EC_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "INV_IP.v"
//synopsys translate_on

module EC_TOP(
    // Input signals
    clk, rst_n, in_valid,
    in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a,
    // Output signals
    out_valid, out_Rx, out_Ry
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [6-1:0] in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a;
output reg out_valid;
output reg [6-1:0] out_Rx, out_Ry;

parameter [2:0]IDLE = 3'b00;
parameter [2:0]INPUT_DATA = 3'b01;
parameter [2:0]CAL = 3'b10;
parameter [2:0]OUTPUT_DATA = 3'b11;
reg [2:0]cs,ns;
reg	[6-1:0]save_in_Px,save_in_Py,save_in_Qx,save_in_Qy,save_in_prime,save_in_a,a;
reg [20:0]b;
reg [12:0]save_Sx;
reg [12:0]cx,cy;
reg [6:0]save_xr,save_yr,save_xr_real,save_yr_real;
reg [6:0]Denominator_before,Denominator_after;
reg flaggetdeno,flagb;
reg [4:0]cnt;
wire [6:0]Input_INVIP,Prime_num,Out_swap;
integer i;
// ===============================================================
// FSM
// ===============================================================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cs <= 0;
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
				if(!in_valid)begin
					ns = CAL;
				end
				else begin
					ns = INPUT_DATA;
				end
			end
			CAL:begin
				if(cnt == 9)begin
					ns = OUTPUT_DATA;
				end
				else begin
					ns = CAL;
				end
			end
			OUTPUT_DATA:begin
				if(!out_valid)begin
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
// ===============================================================
// Saveinput
// ===============================================================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		save_in_Px <= 0;
		save_in_Py <= 0;
		save_in_Qx <= 0;
		save_in_Qy <= 0;
		save_in_prime <= 0;
		save_in_a <= 0;
	end
	else begin
		if(ns == INPUT_DATA)begin
			save_in_Px <= in_Px;
			save_in_Py <= in_Py;
			save_in_Qx <= in_Qx;
			save_in_Qy <= in_Qy;
			save_in_prime <= in_prime;
			save_in_a <= in_a;
		end
	end
end
// ===============================================================
// Cal
// ===============================================================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		Denominator_before <= 0;
	end
	else begin
		if(ns == CAL)begin
			if(save_in_Px == save_in_Qx && save_in_Py == save_in_Qy)begin
				if(2*save_in_Py>save_in_prime)begin
					Denominator_before <= 2*save_in_Py-save_in_prime;
				end
				else begin
					Denominator_before <= 2*save_in_Py;
				end
			end
			else begin
				if(save_in_Qx < save_in_Px)begin
					Denominator_before <= save_in_Qx-save_in_Px+save_in_prime;
				end
				else begin
					Denominator_before <= save_in_Qx-save_in_Px;
				end
			end
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		Denominator_after <= 0;
		flaggetdeno <= 0;
	end
	else begin
		if(cs == CAL)begin
			Denominator_after <= Out_swap;
			flaggetdeno <= 1;
		end
		else if(cs == IDLE)begin
			flaggetdeno <= 0;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		b <= 0;
		flagb <= 0;
	end
	else begin
		if(cs == CAL)begin
			if(flaggetdeno)begin
				if(save_in_Px == save_in_Qx && save_in_Py == save_in_Qy)begin
					b <= Denominator_after*(3*save_in_Px*save_in_Px+save_in_a);
				end
				else begin
					b <= Denominator_after*(save_in_Qy-save_in_Py+save_in_prime);
				end
				flagb <= 1;
			end	
		end
		else begin
			b <= 0;
			flagb <= 0;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		save_Sx <= 0;
	end
	else begin
		if(cs == CAL)begin
			if(flagb)begin
				if(save_in_Px == save_in_Qx && save_in_Py == save_in_Qy)begin
					save_Sx <= b%save_in_prime;
				end
				else begin
					save_Sx <= b%save_in_prime;
				end
			end	
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cx <= 0;
	end
	else begin
		if((save_in_Px == 0 && save_in_Py == 0 && save_in_Qx == 0 && save_in_Qy == 0 ))begin
			cx <= 0;
		end
		else begin
			if(cnt == 5)begin
				cx <= (save_Sx*save_Sx+save_in_prime+save_in_prime-save_in_Px-save_in_Qx);
			end	
		end	
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		save_xr <= 0;
		save_yr <= 0;
	end
	else begin
		if((save_in_Px == 0 && save_in_Py == 0 && save_in_Qx == 0 && save_in_Qy == 0 ))begin
			save_xr <= 0;
			save_yr <= 0;
		end
		else begin
			if(cnt == 6)begin
				save_xr <= cx%save_in_prime;
			end	
			else if(cnt == 8)begin
				save_yr <= cy%save_in_prime;
			end
		end	
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cy <= 0;
	end
	else begin
		if((save_in_Px == 0 && save_in_Py == 0 && save_in_Qx == 0 && save_in_Qy == 0 ))begin
			cy <= 0;
		end
		else begin
			if(cnt == 7)begin
				cy <= (save_Sx*a-save_in_Py+save_in_prime);
			end	
		end	
	end
end
always@(*)begin
	if(!rst_n)begin
		a = 0;
	end
	else begin
		if((save_in_Px == 0 && save_in_Py == 0 && save_in_Qx == 0 && save_in_Qy == 0 ))begin
			a = 0;
		end
		else begin
			if(cnt > 3)begin
				if(save_in_Px<save_xr)begin
					a = save_in_Px-save_xr+save_in_prime;
				end
				else begin
					a = save_in_Px-save_xr;
				end
			end	
			else begin
				a = 0;
			end
		end	
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		save_xr_real <= 0;
		save_yr_real <= 0;
	end
	else begin
		if(cnt == 9)begin
			save_xr_real <= save_xr;
			save_yr_real <= save_yr;
		end
		else begin
			save_xr_real <= save_xr_real;
			save_yr_real <= save_yr_real;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cnt <= 0;
	end
	else begin
		if(ns == IDLE)begin
			cnt <= 0;
		end
		else begin
			cnt <= cnt+1;
		end
	end
end
// ===============================================================
// SoftIP
// ===============================================================
assign Input_INVIP = Denominator_before;
assign Prime_num = save_in_prime;
INV_IP #(.IP_WIDTH(7)) INVIP(
	.IN_1(Input_INVIP),
	.IN_2(Prime_num),
	.OUT_INV(Out_swap)
);
// ===============================================================
// Output
// ===============================================================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_valid <= 0;
	end
	else begin
		if(cs == OUTPUT_DATA)begin
			out_valid <= 1;
		end
		else begin
			out_valid <= 0;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_Rx <= 0;
		out_Ry <= 0;
	end
	else begin
		if(cs == OUTPUT_DATA)begin
			out_Rx <= save_xr_real;
			out_Ry <= save_yr_real;
		end
		else begin
			out_Rx <= 0;
			out_Ry <= 0;
		end
	end
end

endmodule

