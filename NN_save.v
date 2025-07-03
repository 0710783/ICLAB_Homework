module NN(
	// Input signals
	clk,
	rst_n,
	in_valid,
	weight_u,
	weight_w,
	weight_v,
	data_x,
	data_h,
	// Output signals
	out_valid,
	out
);

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;
parameter IDLE = 2'b00;
parameter IN   = 2'b01;
parameter CAL  = 2'b10;
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input  clk, rst_n, in_valid;
input [inst_sig_width+inst_exp_width:0] weight_u, weight_w, weight_v;
input [inst_sig_width+inst_exp_width:0] data_x,data_h;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
integer i;
reg [31:0]Y1_out[2:0],Y2_out[2:0],Y3_out[2:0];
reg [8:0]cnt;
reg [31:0]h0_save1[2:0];
reg [31:0]W_save1[8:0],U_save1[8:0],V_save1[8:0];
reg [3:0]input_count;
reg [31:0]x_save1[2:0];
reg [31:0]x1_save[2:0],x2_save[2:0],x3_save[2:0];
reg [31:0]Y_save[2:0];

wire [31:0]h0_save[2:0];
wire [31:0]W_save[8:0],U_save[8:0],V_save[8:0];

wire [31:0]x_save[2:0],uxwh[8:0];

wire [31:0]ux1wh0[8:0],ux1wh0_afterpipe[8:0],addux1wh0[2:0],addux1wh0_afterpipe[2:0],UX[2:0];
wire [7:0]status_ux1wh0[8:0],status_addux1wh0[5:0];
wire [31:0]ux1wh0wh0[8:0],ux1wh0wh0_afterpipe[8:0],addux1wh0wh0[2:0],addux1wh0wh0_afterpipe[2:0],WH[2:0];
wire [7:0]status_ux1wh0wh0[8:0],status_addux1wh0wh0[5:0];
wire [31:0]UX_afterpipe[2:0],WH_afterpipe[2:0];
wire [31:0]h1_save[2:0],h1_save_afterpipe[2:0],GOTOF[2:0],GOTOG[2:0],GOTOG_afterpipe[2:0];
wire [7:0]status_adduw[2:0];
wire [31:0]Y[2:0];
wire [31:0]mulVH[8:0],mulVH_afterpipe[8:0];
wire [31:0]addmulVH[2:0],addmulVH_afterpipe[2:0];
wire [7:0]status_mulVH[8:0],status_addmulVH[5:0];

genvar k;
/////////////////
//     input
/////////////////
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<3;i=i+1)begin
			x1_save[i] <= 0;
			x2_save[i] <= 0;
			x3_save[i] <= 0;
			h0_save1[i] <= 0;
			input_count <= 0;
		end
		for(i=0;i<9;i=i+1)begin
			W_save1[i] <= 0;
			U_save1[i] <= 0;
			V_save1[i] <= 0;
		end
	end
	else begin
		if(out_valid)begin
			for(i=0;i<3;i=i+1)begin
				x1_save[i] <= 0;
				x2_save[i] <= 0;
				x3_save[i] <= 0;
				h0_save1[i] <= 0;
				input_count <= 0;
			end
			for(i=0;i<9;i=i+1)begin
				W_save1[i] <= 0;
				U_save1[i] <= 0;
				V_save1[i] <= 0;
			end
		end
		else begin
			if(in_valid)begin
				if(input_count == 0 || input_count == 1 || input_count == 2)begin
					x1_save[input_count] <= data_x;
					h0_save1[input_count] <= data_h;
				end
				else if(input_count == 3 || input_count == 4 || input_count == 5)begin
					x2_save[input_count-3] <= data_x;
				end
				else if(input_count == 6 || input_count == 7 || input_count == 8)begin
					x3_save[input_count-6] <= data_x;
				end
				W_save1[input_count] <= weight_w;
				U_save1[input_count] <= weight_u;
				V_save1[input_count] <= weight_v;
				input_count <= input_count+1;
			end
			else begin
				if(cnt == 16 || cnt == 24)begin
					for(i=0;i<3;i=i+1)begin
						h0_save1[i] <= h1_save[i];
					end
				end
				else begin
					for(i=0;i<3;i=i+1)begin
						h0_save1[i] <= h0_save1[i];
					end
				end
				input_count <= 0;
			end
		end	
	end
end
/////////////////
//     FSM
/////////////////
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cnt <= 0;
	end
	else begin
		if(cnt == 42)begin
			cnt <= 0;
		end
		else begin
			if(input_count == 1)begin
				cnt <= 6;
			end
			else begin
				cnt <= cnt+1;
			end
		end
	end
end
/////////////////
//     start_cal
/////////////////
always @(*)begin
	if(cnt > 8 && cnt < 18)begin
		for(i=0;i<3;i=i+1)begin
			x_save1[i] = x1_save[i];
		end
	end
	else if(cnt > 17 && cnt < 24)begin
		for(i=0;i<3;i=i+1)begin
			x_save1[i] = x2_save[i];
		end
	end
	else if(cnt > 23)begin
		for(i=0;i<3;i=i+1)begin
			x_save1[i] = x3_save[i];
		end
	end
	else begin
		for(i=0;i<3;i=i+1)begin
			x_save1[i] = 'd0;
		end
	end
end
generate
	for(k=0;k<3;k=k+1)begin
		assign x_save[k] = x_save1[k];
		assign h0_save[k] = h0_save1[k];
	end
	for(k=0;k<9;k=k+1)begin
		assign U_save[k] = U_save1[k];
		assign V_save[k] = V_save1[k];
		assign W_save[k] = W_save1[k];
	end
	/////////////////////
	//      h0x1
	/////////////////////
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							UX1WH01 ( .a(x_save[0]), .b(U_save[0]), .rnd(3'b000), .z(uxwh[0]), .status(status_ux1wh0[0]) );
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							UX1WH02 ( .a(x_save[1]), .b(U_save[1]), .rnd(3'b000), .z(uxwh[1]), .status(status_ux1wh0[1]) );
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							UX1WH03 ( .a(x_save[2]), .b(U_save[2]), .rnd(3'b000), .z(uxwh[2]), .status(status_ux1wh0[2]) );	
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							UX1WH04 ( .a(x_save[0]), .b(U_save[3]), .rnd(3'b000), .z(uxwh[3]), .status(status_ux1wh0[3]) );
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							UX1WH05 ( .a(x_save[1]), .b(U_save[4]), .rnd(3'b000), .z(uxwh[4]), .status(status_ux1wh0[4]) );
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							UX1WH06 ( .a(x_save[2]), .b(U_save[5]), .rnd(3'b000), .z(uxwh[5]), .status(status_ux1wh0[5]) );	
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							UX1WH07 ( .a(x_save[0]), .b(U_save[6]), .rnd(3'b000), .z(uxwh[6]), .status(status_ux1wh0[6]) );
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							UX1WH08 ( .a(x_save[1]), .b(U_save[7]), .rnd(3'b000), .z(uxwh[7]), .status(status_ux1wh0[7]) );
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							UX1WH09 ( .a(x_save[2]), .b(U_save[8]), .rnd(3'b000), .z(uxwh[8]), .status(status_ux1wh0[8]) );
	for(k=0;k<9;k=k+1)begin
		DW03_pipe_reg #(1,1+inst_sig_width+inst_exp_width) UX_REG(.A(uxwh[k]),
															 .B(ux1wh0_afterpipe[k]),
															 .clk(clk));
	end
	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							ADDUX1WH01 ( .a(ux1wh0_afterpipe[0]), .b(ux1wh0_afterpipe[1]), .rnd(3'b000), .z(addux1wh0[0]), .status(status_addux1wh0[0]) );	
	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							ADDUX1WH02 ( .a(ux1wh0_afterpipe[3]), .b(ux1wh0_afterpipe[4]), .rnd(3'b000), .z(addux1wh0[1]), .status(status_addux1wh0[1]) );	
	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							ADDUX1WH03 ( .a(ux1wh0_afterpipe[6]), .b(ux1wh0_afterpipe[7]), .rnd(3'b000), .z(addux1wh0[2]), .status(status_addux1wh0[2]) );
	for(k=0;k<3;k=k+1)begin
		DW03_pipe_reg #(1,1+inst_sig_width+inst_exp_width) UX2_REG(.A(addux1wh0[k]),
															 .B(addux1wh0_afterpipe[k]),
															 .clk(clk));
	end
	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							ADDUX1WH04 ( .a(addux1wh0_afterpipe[0]), .b(ux1wh0_afterpipe[2]), .rnd(3'b000), .z(UX[0]), .status(status_addux1wh0[3]) );	
	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							ADDUX1WH05 ( .a(addux1wh0_afterpipe[1]), .b(ux1wh0_afterpipe[5]), .rnd(3'b000), .z(UX[1]), .status(status_addux1wh0[4]) );	
	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							ADDUX1WH06 ( .a(addux1wh0_afterpipe[2]), .b(ux1wh0_afterpipe[8]), .rnd(3'b000), .z(UX[2]), .status(status_addux1wh0[5]) );
	
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							UX1WH0WH01 ( .a(h0_save[0]), .b(W_save[0]), .rnd(3'b000), .z(ux1wh0wh0[0]), .status(status_ux1wh0wh0[0]) );
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							UX1WH0WH02 ( .a(h0_save[1]), .b(W_save[1]), .rnd(3'b000), .z(ux1wh0wh0[1]), .status(status_ux1wh0wh0[1]) );
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							UX1WH0WH03 ( .a(h0_save[2]), .b(W_save[2]), .rnd(3'b000), .z(ux1wh0wh0[2]), .status(status_ux1wh0wh0[2]) );	
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							UX1WH0WH04 ( .a(h0_save[0]), .b(W_save[3]), .rnd(3'b000), .z(ux1wh0wh0[3]), .status(status_ux1wh0wh0[3]) );
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							UX1WH0WH05 ( .a(h0_save[1]), .b(W_save[4]), .rnd(3'b000), .z(ux1wh0wh0[4]), .status(status_ux1wh0wh0[4]) );
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							UX1WH0WH06 ( .a(h0_save[2]), .b(W_save[5]), .rnd(3'b000), .z(ux1wh0wh0[5]), .status(status_ux1wh0wh0[5]) );	
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							UX1WH0WH07 ( .a(h0_save[0]), .b(W_save[6]), .rnd(3'b000), .z(ux1wh0wh0[6]), .status(status_ux1wh0wh0[6]) );
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							UX1WH0WH08 ( .a(h0_save[1]), .b(W_save[7]), .rnd(3'b000), .z(ux1wh0wh0[7]), .status(status_ux1wh0wh0[7]) );
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							UX1WH0WH09 ( .a(h0_save[2]), .b(W_save[8]), .rnd(3'b000), .z(ux1wh0wh0[8]), .status(status_ux1wh0wh0[8]) );	
	for(k=0;k<9;k=k+1)begin
		DW03_pipe_reg #(1,1+inst_sig_width+inst_exp_width) WH_REG(.A(ux1wh0wh0[k]),
															 .B(ux1wh0wh0_afterpipe[k]),
															 .clk(clk));
	end
	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							ADDUX1WH0WH01 ( .a(ux1wh0wh0_afterpipe[0]), .b(ux1wh0wh0_afterpipe[1]), .rnd(3'b000), .z(addux1wh0wh0[0]), .status(status_addux1wh0wh0[0]) );	
	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							ADDUX1WH0WH02 ( .a(ux1wh0wh0_afterpipe[3]), .b(ux1wh0wh0_afterpipe[4]), .rnd(3'b000), .z(addux1wh0wh0[1]), .status(status_addux1wh0wh0[1]) );	
	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							ADDUX1WH0WH03 ( .a(ux1wh0wh0_afterpipe[6]), .b(ux1wh0wh0_afterpipe[7]), .rnd(3'b000), .z(addux1wh0wh0[2]), .status(status_addux1wh0wh0[2]) );
	for(k=0;k<3;k=k+1)begin
		DW03_pipe_reg #(1,1+inst_sig_width+inst_exp_width) WH2_REG(.A(addux1wh0wh0[k]),
															 .B(addux1wh0wh0_afterpipe[k]),
															 .clk(clk));
	end
	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							ADDUX1WH0WH04 ( .a(addux1wh0wh0_afterpipe[0]), .b(ux1wh0wh0_afterpipe[2]), .rnd(3'b000), .z(WH[0]), .status(status_addux1wh0wh0[3]) );	
	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							ADDUX1WH0WH05 ( .a(addux1wh0wh0_afterpipe[1]), .b(ux1wh0wh0_afterpipe[5]), .rnd(3'b000), .z(WH[1]), .status(status_addux1wh0wh0[4]) );	
	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							ADDUX1WH0WH06 ( .a(addux1wh0wh0_afterpipe[2]), .b(ux1wh0wh0_afterpipe[8]), .rnd(3'b000), .z(WH[2]), .status(status_addux1wh0wh0[5]) );
	for(k=0;k<3;k=k+1)begin
		DW03_pipe_reg #(1,1+inst_sig_width+inst_exp_width) BEFORE_F_REG(.A(WH[k]),
															 .B(WH_afterpipe[k]),
															 .clk(clk));
		DW03_pipe_reg #(1,1+inst_sig_width+inst_exp_width) BEFORE_F2_REG(.A(UX[k]),
															 .B(UX_afterpipe[k]),
															 .clk(clk));
	end	
	for(k=0;k<3;k=k+1)begin
		DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
								ADDUW ( .a(WH_afterpipe[k]), .b(UX_afterpipe[k]), .rnd(3'b000), .z(GOTOF[k]), .status(status_adduw[k]) );
		ReLU V_ReLU(.a(GOTOF[k]),
			.z(h1_save[k]));
		DW03_pipe_reg #(1,1+inst_sig_width+inst_exp_width) GOTOG_REG(.A(h1_save[k]),   
															 .B(h1_save_afterpipe[k]),
															 .clk(clk));  													 
	end
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							VH1 ( .a(h1_save_afterpipe[0]), .b(V_save[0]), .rnd(3'b000), .z(mulVH[0]), .status(status_mulVH[0]) );
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							VH2 ( .a(h1_save_afterpipe[1]), .b(V_save[1]), .rnd(3'b000), .z(mulVH[1]), .status(status_mulVH[1]) );
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							VH3 ( .a(h1_save_afterpipe[2]), .b(V_save[2]), .rnd(3'b000), .z(mulVH[2]), .status(status_mulVH[2]) );	
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							VH4 ( .a(h1_save_afterpipe[0]), .b(V_save[3]), .rnd(3'b000), .z(mulVH[3]), .status(status_mulVH[3]) );
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							VH5 ( .a(h1_save_afterpipe[1]), .b(V_save[4]), .rnd(3'b000), .z(mulVH[4]), .status(status_mulVH[4]) );
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							VH6 ( .a(h1_save_afterpipe[2]), .b(V_save[5]), .rnd(3'b000), .z(mulVH[5]), .status(status_mulVH[5]) );	
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							VH7 ( .a(h1_save_afterpipe[0]), .b(V_save[6]), .rnd(3'b000), .z(mulVH[6]), .status(status_mulVH[6]) );
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							VH8 ( .a(h1_save_afterpipe[1]), .b(V_save[7]), .rnd(3'b000), .z(mulVH[7]), .status(status_mulVH[7]) );
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							VH9 ( .a(h1_save_afterpipe[2]), .b(V_save[8]), .rnd(3'b000), .z(mulVH[8]), .status(status_mulVH[8]) );
	for(k=0;k<9;k=k+1)begin
		DW03_pipe_reg #(1,1+inst_sig_width+inst_exp_width) VH_REG(.A(mulVH[k]),
															 .B(mulVH_afterpipe[k]),
															 .clk(clk));
	end
	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							ADDVH1 ( .a(mulVH_afterpipe[0]), .b(mulVH_afterpipe[1]), .rnd(3'b000), .z(addmulVH[0]), .status(status_addmulVH[0]) );	
	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							ADDVH2 ( .a(mulVH_afterpipe[3]), .b(mulVH_afterpipe[4]), .rnd(3'b000), .z(addmulVH[1]), .status(status_addmulVH[1]) );	
	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							ADDVH3 ( .a(mulVH_afterpipe[6]), .b(mulVH_afterpipe[7]), .rnd(3'b000), .z(addmulVH[2]), .status(status_addmulVH[2]) );
	for(k=0;k<3;k=k+1)begin
		DW03_pipe_reg #(1,1+inst_sig_width+inst_exp_width) ADDVH_REG(.A(addmulVH[k]),
															 .B(addmulVH_afterpipe[k]),
															 .clk(clk));
	end
	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							ADDVH4 ( .a(addmulVH_afterpipe[0]), .b(mulVH_afterpipe[2]), .rnd(3'b000), .z(GOTOG[0]), .status(status_addmulVH[3]) );	
	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							ADDVH5 ( .a(addmulVH_afterpipe[1]), .b(mulVH_afterpipe[5]), .rnd(3'b000), .z(GOTOG[1]), .status(status_addmulVH[4]) );	
	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
							ADDVH6 ( .a(addmulVH_afterpipe[2]), .b(mulVH_afterpipe[8]), .rnd(3'b000), .z(GOTOG[2]), .status(status_addmulVH[5]) );
	for(k=0;k<3;k=k+1)begin
		DW03_pipe_reg #(1,1+inst_sig_width+inst_exp_width) ADDVH_REG(.A(GOTOG[k]),
															 .B(GOTOG_afterpipe[k]),
															 .clk(clk));
		Sigmoids Y_SIGMOID(.a(GOTOG_afterpipe[k]),
					  .z(Y[k]));
	end
endgenerate
/////////////////
//     output
/////////////////
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 'd0;
	end
	else begin
		if(cnt == 33)begin
			out_valid <= 1;
		end
		else begin
			if(cnt == 42)begin
				out_valid <= 0;
			end
			else begin
				out_valid <= out_valid;
			end
		end
	end
end
always @(*)begin
	for(i=0;i<3;i=i+1)begin
		Y_save[i] = Y[i];
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<3;i=i+1)begin
			Y1_out[i] <= 0;
			Y2_out[i] <= 0;
			Y3_out[i] <= 0;
		end
	end
	else begin
		if(in_valid)begin
			for(i=0;i<3;i=i+1)begin
				Y1_out[i] <= 0;
				Y2_out[i] <= 0;
				Y3_out[i] <= 0;
			end
		end
		else begin
			for(i=0;i<3;i=i+1)begin
				if(cnt == 18)begin
					Y1_out[i] <= Y_save[i];
				end
				else begin
					Y1_out[i] <= Y1_out[i];
				end
			end
			for(i=0;i<3;i=i+1)begin
				if(cnt == 26)begin
					Y2_out[i] <= Y_save[i];
				end
				else begin
					Y2_out[i] <= Y2_out[i];
				end
			end
			for(i=0;i<3;i=i+1)begin
				if(cnt == 32)begin
					Y3_out[i] <= Y_save[i];
				end
				else begin
					Y3_out[i] <= Y3_out[i];
				end
			end
		end	
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out <= 'd0;
	end
	else begin
		if(cnt == 33)begin
			out <= Y1_out[0];
		end
		else if(cnt == 34)begin
			out <= Y1_out[1];
		end
		else if(cnt == 35)begin
			out <= Y1_out[2];
		end
		else if(cnt == 36)begin
			out <= Y2_out[0];
		end
		else if(cnt == 37)begin
			out <= Y2_out[1];
		end
		else if(cnt == 38)begin
			out <= Y2_out[2];
		end
		else if(cnt == 39)begin
			out <= Y3_out[0];
		end
		else if(cnt == 40)begin
			out <= Y3_out[1];
		end
		else if(cnt == 41)begin
			out <= Y3_out[2];
		end
		else begin	
			out <= 0;
		end
	end
end
////////////////
endmodule

module ReLU(
	input [31:0] a,
	output reg [31:0] z
);	
wire [31:0]zminus;
wire [7:0]status_div;
DW_fp_div #(23, 8, 0) DIV1
				( .a(a), .b(32'b01000001001000000000000000000000), .rnd(3'b000), .z(zminus), .status(status_div));	
always@(*) begin
	if(a[31]) begin
		z = zminus;
	end
	else begin
		z = a;
	end
end
endmodule

module Sigmoids(
	input [31:0] a,
	output reg [31:0] z
);
wire [31:0] z_exp;
wire [31:0] z_add;
wire [31:0] z_recip;
wire [7:0] exp_status;
wire [7:0] add_status;
wire [7:0] recip_status;
DW_fp_exp #(23, 8, 0, 1) EXP (.a({!a[31],a[30:0]}),
							  .z(z_exp),
							  .status(exp_status));

DW_fp_add #(23, 8, 0) ADD(.a(z_exp),
						  .b(32'h3f80_0000),
						  .rnd(3'b000),
						  .status(add_status),
						  .z(z_add));
							
DW_fp_recip #(23, 8, 0, 0) RECIP(.a(z_add),
								 .rnd(3'b000),
								 .status(recip_status),
								 .z(z_recip));						
always@(*) begin
	z = z_recip;
end
endmodule