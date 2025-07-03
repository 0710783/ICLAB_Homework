module bridge(input clk, INF.bridge_inf inf);

typedef enum logic[1:0] {	IDLE,
							READ_DATA,
							WRITE_DATA
							}state;

state cs,ns;

always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		cs <= IDLE;
	end
	else begin
		cs <= ns;
	end
end
always_comb begin
	case(cs)
		IDLE: begin 
			if(inf.C_in_valid && inf.C_r_wb)begin
				ns = READ_DATA;
			end
			else if(inf.C_in_valid && !inf.C_r_wb)begin
				ns = WRITE_DATA;
			end
			else begin
				ns = IDLE;
			end
		end
		READ_DATA: begin 
			if(inf.AR_READY)begin 	
				ns = IDLE;
			end
			else begin
				ns = READ_DATA;
			end
	    end
		WRITE_DATA: begin 
			if(inf.AW_READY)begin
				ns = IDLE;
			end
			else begin
				ns = WRITE_DATA;
			end
	    end
		default:begin
			ns = IDLE;
		end
	endcase
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.AW_VALID	<=	'd0;
		inf.AW_ADDR		<=	'd0;
		inf.W_VALID		<=	'd0;
		inf.W_DATA		<=	'd0;
		inf.B_READY		<=	'd0;
	end
	else if(inf.AW_READY)begin
		inf.AW_VALID	<=	'd0;
		inf.AW_ADDR		<=	inf.C_addr*8 + 17'h10000;
		inf.W_VALID		<=	'd1;
		inf.W_DATA		<=	inf.C_data_w;
		inf.B_READY		<=	'd1;
	end
	else if(inf.W_READY)begin
		inf.AW_VALID	<=	'd0;
		inf.AW_ADDR		<=	'd0;
		inf.W_VALID		<=	'd0;
		inf.W_DATA		<=	'd0;
		inf.B_READY		<=	'd1;
	end
	else if(cs==WRITE_DATA)begin
		inf.AW_VALID	<=	'd1;
		inf.AW_ADDR		<=	inf.C_addr*8 + 17'h10000;
		inf.W_VALID		<=	'd0;
		inf.W_DATA		<=	'd0;
		inf.B_READY		<=	'd1;	
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.AR_VALID	<=	'd0;
		inf.AR_ADDR		<=	'd0;
		inf.R_READY		<=	'd0;
	end
	else if(inf.AR_READY)begin
		inf.AR_VALID	<=	'd0;
		inf.AR_ADDR		<=	inf.C_addr*8 + 17'h10000;
		inf.R_READY		<=	'd1;
	end
	else if(inf.R_VALID)begin
		inf.AR_VALID	<=	'd0;
		inf.AR_ADDR		<=	inf.C_addr*8 + 17'h10000;
		inf.R_READY		<=	'd0;
	end
	else if(cs==READ_DATA)begin
		inf.AR_VALID	<=	'd1;
		inf.AR_ADDR		<=	inf.C_addr*8 + 17'h10000;
		inf.R_READY		<=	'd0;
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.C_out_valid <= 'd0;
	end
	else if(inf.R_VALID || inf.B_VALID)begin
		inf.C_out_valid <= 'd1;
	end
	else begin
		inf.C_out_valid <= 'd0;
	end
end


always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.C_data_r <= 'd0;
	end
	else if(inf.R_VALID)begin
		inf.C_data_r <= inf.R_DATA;
	end
	else begin
		inf.C_data_r <= 'd0;
	end
end



endmodule
