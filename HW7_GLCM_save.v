//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NCTU ED415
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 spring
//   Midterm Proejct            : GLCM 
//   Author                     : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : GLCM.v
//   Module Name : GLCM
//   Release version : V1.0 (Release Date: 2023-04)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module GLCM(
				clk,	
			  rst_n,	
	
			in_addr_M,
			in_addr_G,
			in_dir,
			in_dis,
			in_valid,
			out_valid,
	

         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 
);
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 32;
input			  clk,rst_n;



// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
	   therefore I declared output of AXI as wire in Poly_Ring
*/
   
// -----------------------------
// IO port
input [ADDR_WIDTH-1:0]      in_addr_M;
input [ADDR_WIDTH-1:0]      in_addr_G;
input [1:0]  	  		in_dir;
input [3:0]	    		in_dis;
input 			    	in_valid;
output reg 	              out_valid;
// -----------------------------


// axi write address channel 
output  wire [ID_WIDTH-1:0]        awid_m_inf; //
output  wire [ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [2:0]            awsize_m_inf; //
output  wire [1:0]           awburst_m_inf; //
output  wire [3:0]             awlen_m_inf; //
output  wire                 awvalid_m_inf;
input   wire                 awready_m_inf; 
// axi write data channel 
output  wire [ DATA_WIDTH-1:0]     wdata_m_inf;
output  wire                   wlast_m_inf;
output  wire                  wvalid_m_inf;
input   wire                  wready_m_inf;
// axi write response channel
input   wire [ID_WIDTH-1:0]         bid_m_inf;//
input   wire [1:0]             bresp_m_inf; 
input   wire              	   bvalid_m_inf;
output  wire                  bready_m_inf; //
// -----------------------------
// axi read address channel 
output  wire [ID_WIDTH-1:0]       arid_m_inf; //
output  wire [ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [3:0]            arlen_m_inf;
output  wire [2:0]           arsize_m_inf; //
output  wire [1:0]          arburst_m_inf; //
output  wire                arvalid_m_inf;
input   wire               arready_m_inf; 
// -----------------------------
// axi read data channel 
input   wire [ID_WIDTH-1:0]         rid_m_inf;
input   wire [DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [1:0]             rresp_m_inf; 
input   wire                   rlast_m_inf;
input   wire                  rvalid_m_inf;
output  wire                  rready_m_inf; //
// -----------------------------
reg [ADDR_WIDTH-1:0]      in_addr_M_save;
reg [ADDR_WIDTH-1:0]      in_addr_G_save;
reg [1:0]  	  		in_dir_save;
reg [3:0]	    		in_dis_save;
reg [2:0]cs,ns,rcs,rns,wcs,wns;
reg [7:0]cnt_input;
reg [2:0]cnt_four_time;
reg arvalid_m_inf_reg;
reg [31:0]awaddr_m_inf_reg;
reg [5:0]INPUT_A_reg;
reg [7:0]GLCM_OUT[1023:0];
reg [3:0]row_set,col_set;
reg [8:0]count_256;
reg [4:0]GL_col,GL_row;
reg awvalid_m_inf_reg;
reg wvalid_m_inf_reg;
reg [9:0]count_write_input;
reg [3:0]count_len_16;
reg [5:0]count_write_64;

parameter IDLE = 3'b000;
parameter INPUT_DR = 3'b001;
parameter GET_DATA = 3'b010;
parameter CAL = 3'b011;
parameter WRINTODRAM = 3'b100;
parameter OUTPUT_DATA = 3'b101;
parameter OUTPUT_DATA_DELAY = 3'b110;

parameter RIDLE = 3'b000;
parameter RINPUT = 3'b001;
parameter ONLY_FOR_DELAY = 3'b010;
parameter R_GET_DATA = 3'b011;
parameter RFINSH = 3'b100;

parameter WIDLE = 3'b000;
parameter WINPUT = 3'b001;
parameter W_ONLY_FOR_DELAY = 3'b010;
parameter W_PUT_DATA = 3'b011;
parameter WFINISH = 3'b100;

wire [5:0]INPUT_A;
wire [31:0]INPUT_D;
wire [31:0]INPUT_Q;
wire WEN_DATA_SAVE;
reg [7:0]save_input_mat[255:0];
reg [7:0]count;
integer i;

assign awid_m_inf = 4'b0000;
assign awsize_m_inf = 3'b010;
assign awburst_m_inf = 2'b01;
assign awlen_m_inf = 4'b1111;

assign bready_m_inf = 1'b1;

assign arid_m_inf = 4'b0000;
assign arsize_m_inf = 3'b010;
assign arburst_m_inf = 2'b01;
assign arvalid_m_inf = arvalid_m_inf_reg;
assign araddr_m_inf = in_addr_M_save;
assign arlen_m_inf = 4'b1111;

assign rready_m_inf = 1'b1;
MID DATA_SAVE(
	.A(INPUT_A),
	.D(INPUT_D),
	.Q(INPUT_Q),
	.CLK(clk),
	.WEN(WEN_DATA_SAVE),
	.CEN(1'b0),
	.OEN(1'b0)
);
assign WEN_DATA_SAVE = (ns == 2)?0:1;
assign INPUT_D = (ns == 2)?rdata_m_inf:0;
assign INPUT_A = INPUT_A_reg;
//------------------------------
//FSM
//------------------------------
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
					ns = INPUT_DR;
				end
				else begin
					ns = IDLE;
				end
			end
			INPUT_DR:begin
				if(rvalid_m_inf)begin
					ns = GET_DATA;
				end
				else begin
					ns = INPUT_DR;
				end
			end
			GET_DATA:begin
				if(cnt_four_time == 3 && rvalid_m_inf && rlast_m_inf)begin
					ns = CAL;
				end
				else if(cnt_four_time < 4 && rvalid_m_inf)begin
					ns = GET_DATA;
				end
				else begin
					ns = INPUT_DR;
				end
			end
			CAL:begin
				if(count_256 == 255)begin
					ns = WRINTODRAM;
				end
				else begin
					ns = CAL;
				end
			end
			WRINTODRAM:begin
				if(wcs == WFINISH)begin
					ns = OUTPUT_DATA;
				end
				else begin
					ns = WRINTODRAM;
				end
			end
			OUTPUT_DATA:begin
				ns = OUTPUT_DATA_DELAY;
			end
			default:begin
				ns = IDLE;
			end
		endcase
	end
end
//------------------------------
//Read FSM
//------------------------------
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		rcs <= IDLE;
	end
	else begin
		rcs <= rns;
	end
end
always@(*)begin
	if(!rst_n)begin
		rns = RIDLE;
	end
	else begin
		case(rcs)
			RIDLE:begin
				if(cs == INPUT_DR)begin
					rns = RINPUT;
				end
				else begin
					rns = RIDLE;
				end
			end
			RINPUT:begin
				rns = ONLY_FOR_DELAY;
			end
			ONLY_FOR_DELAY:begin
				rns = R_GET_DATA;
			end
			R_GET_DATA:begin
				if(cnt_four_time < 3 && rlast_m_inf)begin
					rns = RINPUT;
				end
				else if(cnt_four_time > 2 && rlast_m_inf)begin
					rns = RFINSH;
				end
				else begin
					rns = R_GET_DATA;
				end
			end
			RFINSH:begin
				if(cs == CAL)begin
					rns = RIDLE;
				end
				else begin
					rns = RFINSH;
				end
			end
			default:begin
				rns = RIDLE;
			end
		endcase
	end
end
//------------------------------
//Write FSM
//------------------------------
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		wcs <= WIDLE;
	end
	else begin
		wcs <= wns;
	end
end
always@(*)begin
	case(wcs)
		WIDLE:begin
			if(cs == WRINTODRAM)begin
				wns = WINPUT;
			end
			else begin
				wns = WIDLE;
			end
		end
		WINPUT:begin
			wns = W_ONLY_FOR_DELAY;
		end
		W_ONLY_FOR_DELAY:begin
			wns = W_PUT_DATA;
		end
		W_PUT_DATA:begin
			if(wlast_m_inf && count_write_64 < 15)begin
				wns = WINPUT;
			end
			else if(wlast_m_inf && count_write_64 == 15)begin
				wns = WFINISH;
			end
			else begin
				wns = W_PUT_DATA;
			end
		end
		WFINISH:begin
			if(cs == OUTPUT_DATA)begin
				wns = WIDLE;
			end
			else begin
				wns = WFINISH;
			end
		end
		default:begin
			wns = WIDLE;
		end
	endcase
end
//------------------------------
//initial
//------------------------------
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		in_addr_M_save <= 0;
		in_addr_G_save <= 0;
		in_dir_save <= 0;
		in_dis_save <= 0;
	end
	else begin
		if(in_valid)begin
			in_addr_M_save <= in_addr_M;
			in_addr_G_save <= in_addr_G;
			in_dir_save <= in_dir;
			in_dis_save <= in_dis;
		end
		else if(rlast_m_inf)begin
			in_addr_M_save <= in_addr_M_save+64;
		end
	end
end
//------------------------------
//WRITE Data into dram
//------------------------------
assign awvalid_m_inf = awvalid_m_inf_reg;
assign awaddr_m_inf = awaddr_m_inf_reg;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		awvalid_m_inf_reg <= 0;
	end
	else begin
		if(wns == WINPUT || wns == W_ONLY_FOR_DELAY)begin
			awvalid_m_inf_reg <= 1;
		end
		else begin
			awvalid_m_inf_reg <= 0;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		awaddr_m_inf_reg <= 0;
	end
	else begin
		awaddr_m_inf_reg <= in_addr_G_save + count_write_64 * 64;
	end
end
assign wvalid_m_inf = wvalid_m_inf_reg;
assign wlast_m_inf = (count_len_16 == 15)?1:0;
assign wdata_m_inf = {GLCM_OUT[count_write_input+3],GLCM_OUT[count_write_input+2],GLCM_OUT[count_write_input+1],GLCM_OUT[count_write_input]};
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		count_write_input <= 0;
	end
	else begin
		if(wready_m_inf)begin
			count_write_input <= count_write_input+4;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		wvalid_m_inf_reg <= 0;
	end
	else begin
		if(wns == W_PUT_DATA)begin
			wvalid_m_inf_reg <= 1;
		end
		else begin
			wvalid_m_inf_reg <= 0;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		count_len_16 <= 0;
	end
	else begin
		if(wcs == W_PUT_DATA && count_len_16 < 16 && wready_m_inf)begin
			count_len_16 <= count_len_16+1;
		end
		else begin
			count_len_16 <= 0;
		end
	end
end
//------------------------------
//INPUT Data from dram
//------------------------------
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		count_write_64 <= 0;
	end
	else begin
		if(count_write_64 == 15 && wlast_m_inf || in_valid)begin
			count_write_64 <= 0;
		end
		else if(wlast_m_inf)begin
			count_write_64 <= count_write_64+1;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<256;i=i+1)begin
			save_input_mat[i] <= 0;
		end
	end
	else begin
		if(ns == 2 || (cnt_four_time == 3 && rlast_m_inf && rvalid_m_inf))begin
			save_input_mat[count+3] <= {3'b000,rdata_m_inf[28],rdata_m_inf[27],rdata_m_inf[26],rdata_m_inf[25],rdata_m_inf[24]};
			save_input_mat[count+2] <= {3'b000,rdata_m_inf[20],rdata_m_inf[19],rdata_m_inf[18],rdata_m_inf[17],rdata_m_inf[16]};
			save_input_mat[count+1] <= {3'b000,rdata_m_inf[12],rdata_m_inf[11],rdata_m_inf[10],rdata_m_inf[9],rdata_m_inf[8]};
			save_input_mat[count] <= {3'b000,rdata_m_inf[4],rdata_m_inf[3],rdata_m_inf[2],rdata_m_inf[1],rdata_m_inf[0]};
		end	
	end
end 
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		count <= 0;
	end
	else begin
		if(ns == 2 || (cnt_four_time == 3 && rlast_m_inf && rvalid_m_inf))begin
			count <= count+4;
		end
		else if(ns == 3)begin
			count <= 0;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		INPUT_A_reg <= 0;
	end
	else begin
		if(ns == 2)begin
			INPUT_A_reg <= INPUT_A_reg+1;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cnt_four_time <= 0;
	end
	else begin
		if(rlast_m_inf)begin
			cnt_four_time <= cnt_four_time+1;
		end
		else if(rcs == RFINSH)begin
			cnt_four_time <= 0;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cnt_input <= 0;
	end
	else begin
		if(cs == INPUT_DR)begin
			cnt_input <= cnt_input+1;
		end
		else if(cs == OUTPUT_DATA)begin
			cnt_input <= 0;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		arvalid_m_inf_reg <= 0;
	end
	else begin
		if(rns == RINPUT)begin
			arvalid_m_inf_reg <= 1;
		end
		else begin
			if(rcs == ONLY_FOR_DELAY)begin
				arvalid_m_inf_reg <= 0;
			end
		end
	end
end
//------------------------------
//CAL
//------------------------------
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		row_set <= 0;
		col_set <= 0;
	end
	else begin
		case(in_dir_save)
			2'b01:begin
				row_set <= in_dis_save;
				col_set <= 0;
			end
			2'b10:begin
				row_set <= 0;
				col_set <= in_dis_save;
			end
			default:begin
				row_set <= in_dis_save;
				col_set <= in_dis_save;
			end
		endcase
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		count_256 <= 0;
	end
	else begin
		if(cs == CAL)begin
			count_256 <= count_256+1;
		end
	end
end
always@(*)begin
	if(!rst_n)begin
		GL_row = 0;
		GL_col = 0;
	end
	else begin
		GL_row = save_input_mat[count_256];
		if((count_256 + row_set * 16 < 256) && ((count_256 < 16 && count_256+col_set < 16) || (count_256 < 32 && count_256 > 15 && count_256+col_set < 32 && count_256+col_set > 15) || (count_256 < 48 && count_256+col_set < 48 && count_256 > 31 && count_256+col_set > 31) || (count_256 < 64 && count_256+col_set < 64 && count_256 > 47 && count_256+col_set > 47) || (count_256 < 80 && count_256+col_set < 80 && count_256 > 63 && count_256+col_set > 63) || (count_256 < 96 && count_256+col_set < 96 && count_256 > 79 && count_256+col_set > 79) || (count_256 < 112 && count_256+col_set < 112 && count_256 > 95 && count_256+col_set > 95) || (count_256 < 128 && count_256+col_set < 128 && count_256 > 111 && count_256+col_set > 111) || (count_256 < 144 && count_256+col_set < 144 && count_256 > 127 && count_256+col_set > 127) || (count_256 < 160 && count_256+col_set < 160 && count_256 > 143 && count_256+col_set > 143) || (count_256 < 176 && count_256+col_set < 176 && count_256 > 159 && count_256+col_set > 159) || (count_256 < 192 && count_256+col_set < 192 && count_256 > 175 && count_256+col_set > 175) || (count_256 < 208 && count_256+col_set < 208 && count_256 > 191 && count_256+col_set > 191) || (count_256 < 224 && count_256+col_set < 224 && count_256 > 207 && count_256+col_set > 207) || (count_256 < 240 && count_256+col_set < 240 && count_256 > 223 && count_256+col_set > 223) || (count_256 < 256 && count_256+col_set < 256 && count_256 > 239 && count_256+col_set > 239)))begin
			GL_col = save_input_mat[count_256 + row_set * 16 + col_set];
		end
		else begin
			GL_col = 0;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<1024;i=i+1)begin
			GLCM_OUT[i] <= 0;
		end
	end
	else begin
		if(cs == CAL)begin
			if((count_256 + row_set * 16 < 256) && ((count_256 < 16 && count_256+col_set < 16) || (count_256 < 32 && count_256 > 15 && count_256+col_set < 32 && count_256+col_set > 15) || (count_256 < 48 && count_256+col_set < 48 && count_256 > 31 && count_256+col_set > 31) || (count_256 < 64 && count_256+col_set < 64 && count_256 > 47 && count_256+col_set > 47) || (count_256 < 80 && count_256+col_set < 80 && count_256 > 63 && count_256+col_set > 63) || (count_256 < 96 && count_256+col_set < 96 && count_256 > 79 && count_256+col_set > 79) || (count_256 < 112 && count_256+col_set < 112 && count_256 > 95 && count_256+col_set > 95) || (count_256 < 128 && count_256+col_set < 128 && count_256 > 111 && count_256+col_set > 111) || (count_256 < 144 && count_256+col_set < 144 && count_256 > 127 && count_256+col_set > 127) || (count_256 < 160 && count_256+col_set < 160 && count_256 > 143 && count_256+col_set > 143) || (count_256 < 176 && count_256+col_set < 176 && count_256 > 159 && count_256+col_set > 159) || (count_256 < 192 && count_256+col_set < 192 && count_256 > 175 && count_256+col_set > 175) || (count_256 < 208 && count_256+col_set < 208 && count_256 > 191 && count_256+col_set > 191) || (count_256 < 224 && count_256+col_set < 224 && count_256 > 207 && count_256+col_set > 207) || (count_256 < 240 && count_256+col_set < 240 && count_256 > 223 && count_256+col_set > 223) || (count_256 < 256 && count_256+col_set < 256 && count_256 > 239 && count_256+col_set > 239)))begin
				GLCM_OUT[GL_row * 32 + GL_col] <= GLCM_OUT[GL_row * 32 + GL_col]+1;
			end
		end
		else if(in_valid)begin
			for(i=0;i<1024;i=i+1)begin
				GLCM_OUT[i] <= 0;
			end
		end
	end
end
//------------------------------
//OUTPUT
//------------------------------
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_valid <= 0;
	end
	else begin
		if(cs == OUTPUT_DATA_DELAY)begin
			out_valid <= 1;
		end
		else begin
			out_valid <= 0;
		end
	end
end
endmodule
