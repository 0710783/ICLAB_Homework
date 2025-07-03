module OS(input clk, INF.OS_inf inf);
import usertype::*;
typedef enum logic[4:0]{IDLE,DATA_IN,START_BUY,GET_SELLER_BUY,CAL_BUY,WRITE_USER,WRITE_SELLER,OUTPUT,START_DEP,JUDGE_SELLER_OR_USER,CHECK_SELLER,CHECK_USER,WAIT_CHECK} state;
logic[3:0]act_save;
logic[7:0]seller_id_save;
logic[7:0]user_id_save;
logic[1:0]item_id_save;
logic[13:0]item_number_save;
logic[63:0]save_seller_data;
logic[63:0]save_user_data;
logic[16:0]amnt_save;
logic[6:0]save_large_number_user,save_large_number_seller,save_medium_number_seller,save_medium_number_user,save_small_number_user,save_small_number_seller;
logic[6:0]cal_cnt;
logic[16:0]save_user_money,save_seller_money;
logic[12:0]save_exp;
logic[1:0]save_user_level;
logic judge_C_invalid;
logic [2:0]cnt_check;
logic judge_check_sell_user;
logic flag_uiif,flag_oom,flag_siine,flag_wif;
logic flag_wsi,flag_wn,flag_wi,flag_wo;
logic flag_last_is_buy;
integer i;
state cs,ns;
logic [8:0]buyer_id[255:0];
logic [2:0]buyer_item_id[255:0];
logic [8:0]buyer_number[255:0];
logic [8:0]save_buyer_history_for_sellerid[255:0];
/////////////////////////
//  FSM
/////////////////////////
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		cs <= IDLE;
	end
	else begin
		cs <= ns;
	end
end
always_comb begin
	if(!inf.rst_n)begin
		ns = IDLE;
	end
	else begin
		case(cs)
			IDLE: begin 
				if(inf.id_valid || inf.act_valid)begin
					ns = DATA_IN;
				end
				else begin
					ns = IDLE;
				end
			end
			DATA_IN: begin 
				if(act_save == Buy && inf.id_valid || act_save == Return && inf.id_valid || act_save == Deposit)begin
					ns = START_BUY;
				end
				else if(act_save == Check)begin
					ns = JUDGE_SELLER_OR_USER;
				end
				else begin
					ns = DATA_IN;
				end
			end
			JUDGE_SELLER_OR_USER:begin
				if(cnt_check > 6)begin
					ns = CHECK_USER;
				end
				else if(cnt_check < 7 && inf.id_valid)begin
					ns = CHECK_SELLER;
				end
				else begin
					ns = JUDGE_SELLER_OR_USER;
				end
			end
			CHECK_SELLER:begin
				if(inf.C_out_valid)begin
					ns = WAIT_CHECK;
				end
				else begin
					ns = CHECK_SELLER;
				end
			end
			WAIT_CHECK:begin
				ns = OUTPUT;
			end
			CHECK_USER:begin	
				if(inf.C_out_valid)begin
					ns = WAIT_CHECK;
				end
				else begin
					ns = CHECK_USER;
				end
			end
			START_BUY:begin
				if(inf.C_out_valid)begin
					ns = GET_SELLER_BUY;
				end
				else begin
					ns = START_BUY;
				end
			end
			GET_SELLER_BUY:begin
				if(inf.C_out_valid)begin
					ns = CAL_BUY;
				end
				else begin
					ns = GET_SELLER_BUY;
				end
			end
			CAL_BUY:begin
				if(cal_cnt == 6)begin
					ns = WRITE_USER;
				end
				else begin
					ns = CAL_BUY;
				end
			end
			WRITE_USER:begin
				if(inf.C_out_valid)begin
					ns = WRITE_SELLER;
				end
				else begin
					ns = WRITE_USER;
				end
			end
			WRITE_SELLER:begin
				if(inf.C_out_valid)begin
					ns = OUTPUT;
				end
				else begin
					ns = WRITE_SELLER;
				end
			end
			OUTPUT:begin
				if(inf.out_valid)begin
					ns = IDLE;
				end
				else begin
					ns = OUTPUT;
				end
			end
			default: begin
				ns = IDLE;
			end
		endcase
	end	
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		judge_check_sell_user <= 0;
	end
	else begin
		if(ns == IDLE)begin
			judge_check_sell_user <= 0;
		end
		else if(ns == CHECK_SELLER)begin
			judge_check_sell_user <= 1;
		end
	end
end
/////////////////////////
//  INPUT
/////////////////////////
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		act_save <= 'd0;
	end
	else begin
		if(ns == IDLE)begin
			act_save <= 0;
		end
		else if(inf.act_valid)begin
			act_save <= inf.D.d_act[0];
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		user_id_save <= 'd0;
	end
	else begin
		if(inf.id_valid && !act_save)begin
			user_id_save <= inf.D.d_id[0];
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		seller_id_save <= 'd0;
	end
	else begin
		if(inf.id_valid && (act_save == Buy || act_save == Return || act_save == Check))begin
			seller_id_save <= inf.D.d_id[0];
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		item_id_save <= 'd0;
	end
	else begin
		if(ns == IDLE)begin
			item_id_save <= 'd0;
		end
		else begin
			if(inf.item_valid)begin
				item_id_save <= inf.D.d_item[0];
			end
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		item_number_save <= 'd0;
	end
	else begin
		if(inf.num_valid)begin
			item_number_save <= inf.D.d_item_num;
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		amnt_save <= 0;
	end
	else begin
		if(inf.amnt_valid)begin
			amnt_save <= inf.D.d_money;
		end
	end
end
logic flag_check_has_seller;
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		for(i=0;i<256;i=i+1)begin
			buyer_id[i] <= 256;
			buyer_item_id[i] <= 4;
			buyer_number[i] <= 64;
			save_buyer_history_for_sellerid[i] <= 256;
		end
	end
	else begin
		if(act_save != Buy && inf.out_valid && inf.err_msg == No_Err)begin
			if(act_save == Return || flag_check_has_seller)begin
				buyer_id[seller_id_save] <= 256;
				save_buyer_history_for_sellerid[seller_id_save] <= 256;
			end
			save_buyer_history_for_sellerid[user_id_save] <= 256;
			buyer_id[user_id_save] <= 256;
			buyer_item_id[user_id_save] <= 4;
			buyer_number[user_id_save] <= 64;
		end
		else if(act_save == Buy && inf.out_valid && inf.err_msg == No_Err)begin
			buyer_id[seller_id_save] <= user_id_save;
			buyer_item_id[seller_id_save] <= item_id_save;
			buyer_number[seller_id_save] <= item_number_save;
			save_buyer_history_for_sellerid[user_id_save] <= seller_id_save;
			save_buyer_history_for_sellerid[seller_id_save] <= 256;
			buyer_id[user_id_save] <= 256;
			buyer_item_id[user_id_save] <= 4;
			buyer_number[user_id_save] <= 64;
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		flag_check_has_seller <= 0;
	end
	else begin
		if(cs == IDLE)begin
			flag_check_has_seller <= 0;
		end
		else begin
			if(act_save == Check && inf.id_valid)begin
				flag_check_has_seller <= 1;
			end
		end
	end
end
/////////////////////////
//  execute
/////////////////////////
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.C_r_wb <= 0;
		inf.C_in_valid <= 0;
		inf.C_addr <= 0;
	end
	else begin
		if(ns == IDLE)begin
			inf.C_r_wb <= 0;
			inf.C_in_valid <= 0;
			inf.C_addr <= 0;
			judge_C_invalid <= 0;
		end
		else begin
			if(inf.C_in_valid && judge_C_invalid)begin
				inf.C_in_valid <= 0;
			end
			else begin
				if(cs == START_BUY)begin
					inf.C_addr <= user_id_save;
					inf.C_r_wb <= 1;
					if(!judge_C_invalid)begin
						inf.C_in_valid <= 1;
					end
					judge_C_invalid <= 1;
					if(inf.C_out_valid)begin
						judge_C_invalid <= 0;
					end
				end
				else if(cs == GET_SELLER_BUY)begin
					inf.C_addr <= seller_id_save;
					if(!judge_C_invalid)begin
						inf.C_in_valid <= 1;
					end
					judge_C_invalid <= 1;
					if(inf.C_out_valid)begin
						judge_C_invalid <= 0;
					end
				end
				else if(cs == CAL_BUY)begin
					if(cal_cnt == 4)begin
						inf.C_in_valid <= 1;
						inf.C_r_wb <= 0;
						inf.C_addr <= user_id_save;
					end
					else if(cal_cnt == 5)begin
						inf.C_in_valid <= 0;
						inf.C_r_wb <= 1;
					end
				end
				else if(cs == WRITE_SELLER)begin
					if(!judge_C_invalid)begin
						inf.C_in_valid <= 1;
						inf.C_r_wb <= 0;
					end
					judge_C_invalid <= 1;
					if(inf.C_out_valid)begin
						judge_C_invalid <= 0;
						inf.C_r_wb <= 1;
					end
					else begin
						inf.C_r_wb <= 0;
					end
					inf.C_addr <= seller_id_save;
				end
				else if(cs == CHECK_SELLER)begin
					inf.C_r_wb <= 1;
					inf.C_addr <= seller_id_save;
					if(!judge_C_invalid)begin
						inf.C_in_valid <= 1;
					end
					judge_C_invalid <= 1;
					if(inf.C_out_valid)begin
						judge_C_invalid <= 0;
					end
				end
				else if(cs == CHECK_USER)begin
					inf.C_r_wb <= 1;
					inf.C_addr <= user_id_save;
					if(!judge_C_invalid)begin
						inf.C_in_valid <= 1;
					end
					judge_C_invalid <= 1;
					if(inf.C_out_valid)begin
						judge_C_invalid <= 0;
					end
				end
			end	
		end	
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		cnt_check <= 0;
	end
	else begin
		if(ns == IDLE)begin
			cnt_check <= 0;
		end
		else if(ns == JUDGE_SELLER_OR_USER)begin
			cnt_check <= cnt_check+1;
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.C_data_w <= 0;
	end
	else begin
		if(ns == CAL_BUY && cal_cnt == 4)begin
			inf.C_data_w[63:56] <= save_user_data[7:0];
			inf.C_data_w[55:48] <= save_user_data[15:8];
			inf.C_data_w[47:40] <= save_user_data[23:16];
			inf.C_data_w[39:32] <= save_user_data[31:24];
			inf.C_data_w[31:24] <= save_user_data[39:32];
			inf.C_data_w[23:16] <= save_user_data[47:40];
			inf.C_data_w[15:8] <= save_user_data[55:48];
			inf.C_data_w[7:0] <= save_user_data[63:56];
		end
		else if(ns == WRITE_SELLER)begin
			inf.C_data_w[63:56] <= save_seller_data[7:0];
			inf.C_data_w[55:48] <= save_seller_data[15:8];
			inf.C_data_w[47:40] <= save_seller_data[23:16];
			inf.C_data_w[39:32] <= save_seller_data[31:24];
			inf.C_data_w[31:24] <= save_seller_data[39:32];
			inf.C_data_w[23:16] <= save_seller_data[47:40];
			inf.C_data_w[15:8] <= save_seller_data[55:48];
			inf.C_data_w[7:0] <= save_seller_data[63:56];
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		save_seller_data <= 'd0;
		save_user_data <= 'd0;
	end
	else begin
		if(cs == START_BUY && inf.C_out_valid || cs == CHECK_USER && inf.C_out_valid)begin
			save_user_data[7:0] <= inf.C_data_r[63:56];
			save_user_data[15:8] <= inf.C_data_r[55:48];
			save_user_data[23:16] <= inf.C_data_r[47:40];
			save_user_data[31:24] <= inf.C_data_r[39:32];
			save_user_data[39:32] <= inf.C_data_r[31:24];
			save_user_data[47:40] <= inf.C_data_r[23:16];
			save_user_data[55:48] <= inf.C_data_r[15:8];
			save_user_data[63:56] <= inf.C_data_r[7:0];
		end
		else if(cs == GET_SELLER_BUY && inf.C_out_valid || cs == CHECK_SELLER && inf.C_out_valid)begin
			save_seller_data[7:0] <= inf.C_data_r[63:56];
			save_seller_data[15:8] <= inf.C_data_r[55:48];
			save_seller_data[23:16] <= inf.C_data_r[47:40];
			save_seller_data[31:24] <= inf.C_data_r[39:32];
			save_seller_data[39:32] <= inf.C_data_r[31:24];
			save_seller_data[47:40] <= inf.C_data_r[23:16];
			save_seller_data[55:48] <= inf.C_data_r[15:8];
			save_seller_data[63:56] <= inf.C_data_r[7:0];
		end
		else if(cs == CAL_BUY && cal_cnt == 3 && (act_save == Buy || act_save == Return))begin
			save_user_data[31:16] <= save_user_money[15:0];
			save_seller_data[31:16] <= save_seller_money[15:0];
			save_user_data[45] <= save_user_level[1];
			save_user_data[44] <= save_user_level[0];	
			save_user_data[43:32] <= save_exp[11:0];
			save_user_data[7:0] <= seller_id_save;
			save_user_data[13:8] <= item_number_save;
			save_user_data[15:14] <= item_id_save;
			if(item_id_save == 3)begin
				save_seller_data[51:46] <= save_small_number_seller[5:0];
				save_user_data[51:46] <= save_small_number_user[5:0];
			end
			else if(item_id_save == 2)begin
				save_seller_data[57:52] <= save_medium_number_seller[5:0];
				save_user_data[57:52] <= save_medium_number_user[5:0];
			end
			else if(item_id_save == 1)begin
				save_seller_data[63:58] <= save_large_number_seller[5:0];
				save_user_data[63:58] <= save_large_number_user[5:0];
			end
		end
		else if(act_save == Deposit && cs == CAL_BUY && cal_cnt == 3)begin
			save_user_data[31:16] <= save_user_money[15:0];
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		flag_wo <= 0;
	end
	else begin
		if(ns == IDLE)begin
			flag_wo <= 0;
		end
		else begin
			if((buyer_id[save_buyer_history_for_sellerid[user_id_save]] != user_id_save || save_buyer_history_for_sellerid[user_id_save] == 256) && cs == CAL_BUY)begin
				flag_wo <= 1;
			end
		end	
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		save_small_number_user <= 0;
		save_small_number_seller <= 0;
		save_medium_number_user <= 0;
		save_medium_number_seller <= 0;
		save_large_number_user <= 0;
		save_large_number_seller <= 0;
		save_seller_money <= 0;
		save_user_money <= 0;
		save_exp <= 0;
		save_user_level <= 0;
		flag_uiif <= 0;
		flag_siine <= 0;
		flag_oom <= 0;
		flag_wif <= 0;
		flag_wsi <= 0;
		flag_wn <= 0;
		flag_wi <= 0;
	end
	else begin
		if(ns == IDLE)begin
			flag_uiif <= 0;
			flag_siine <= 0;
			flag_oom <= 0;
			flag_wif <= 0;
			flag_wsi <= 0;
			flag_wn <= 0;
			flag_wi <= 0;
			save_medium_number_seller <= 0;
			save_medium_number_user <= 0;
			save_large_number_seller <= 0;
			save_large_number_user <= 0;
		end
		else if(cs == CAL_BUY && act_save == Return)begin
			if(cal_cnt == 1)begin
				save_small_number_seller <= save_seller_data[51:46];
				save_small_number_user <= save_user_data[51:46];
				save_medium_number_seller <= save_seller_data[57:52];
				save_medium_number_user <= save_user_data[57:52];
				save_large_number_seller <= save_seller_data[63:58];
				save_large_number_user <= save_user_data[63:58];
				save_seller_money <= save_seller_data[31:16];
				save_user_money <= save_user_data[31:16];
				save_exp <= save_user_data[43:32];
				save_user_level <= save_user_data[45:44];
			end
			else if(cal_cnt == 2)begin
				if((save_buyer_history_for_sellerid[user_id_save] != seller_id_save || save_buyer_history_for_sellerid[user_id_save] == 256 || buyer_item_id[seller_id_save] != item_id_save || buyer_item_id[seller_id_save] == 4 || buyer_number[seller_id_save] != item_number_save || buyer_number[seller_id_save] == 64 ) && cs == CAL_BUY)begin
					if((save_buyer_history_for_sellerid[user_id_save] != seller_id_save || buyer_id[user_id_save] == 256) || save_buyer_history_for_sellerid[user_id_save] != seller_id_save)begin
						flag_wsi <= 1;
					end
					else if((buyer_number[user_id_save] != item_number_save || buyer_number[user_id_save] == 64) || item_id_save != buyer_item_id[seller_id_save])begin
						flag_wn <= 1;
					end
					else begin
						flag_wi <= 1;
					end
				end
				else begin
					if(!flag_wo)begin
						if(item_id_save == 3)begin //small
							save_small_number_seller <= save_small_number_seller + item_number_save;
							save_seller_money <= save_seller_money - item_number_save * 100;
							save_small_number_user <= save_small_number_user - item_number_save;
							save_user_money <= save_user_money + item_number_save * 100;
						end
						else if(item_id_save == 2)begin //medium
							save_medium_number_seller <= save_medium_number_seller + item_number_save;
							save_seller_money <= save_seller_money - item_number_save * 200;
							save_medium_number_user <= save_medium_number_user - item_number_save;
							save_user_money <= save_user_money + item_number_save * 200;
						end
						else if(item_id_save == 1)begin // large
							save_large_number_seller <= save_large_number_seller + item_number_save;
							save_seller_money <= save_seller_money - item_number_save * 300;
							save_large_number_user <= save_large_number_user - item_number_save;
							save_user_money <= save_user_money + item_number_save * 300;
						end
					end
				end	
			end
		end
		else if(item_id_save == 3 && cs == CAL_BUY && act_save == Buy)begin //small
			if(cal_cnt == 1)begin
				save_small_number_seller <= save_seller_data[51:46];
				save_small_number_user <= save_user_data[51:46];
				save_seller_money <= save_seller_data[31:16];
				save_user_money <= save_user_data[31:16];
				save_exp <= save_user_data[43:32];
				save_user_level <= save_user_data[45:44];
			end
			else if(cal_cnt == 2)begin
				if(save_small_number_user + item_number_save <= 63 && save_small_number_seller >= item_number_save)begin
					if((save_user_level == 2'b00 && save_user_money >= item_number_save * 100 + 10) || save_user_level == 2'b01 && save_user_money >= item_number_save * 100 + 30 || (save_user_level == 2'b10 && save_user_money >= item_number_save * 100 + 50) || (save_user_level == 2'b11 && save_user_money >= item_number_save * 100 + 70))begin
						save_small_number_seller <= save_small_number_seller - item_number_save;
						if(save_seller_money + item_number_save * 100 > 65535)begin
							save_seller_money <= 65535;
						end
						else begin
							save_seller_money <= save_seller_money + item_number_save * 100;
						end
						if(save_user_level == 2'b11)begin
							save_user_money <= save_user_money - item_number_save * 100 - 70;
						end
						else if(save_user_level == 2'b10)begin
							save_user_money <= save_user_money - item_number_save * 100 - 50;
						end
						else if(save_user_level == 2'b01)begin
							save_user_money <= save_user_money - item_number_save * 100 - 30;
						end
						else if(save_user_level == 2'b00)begin
							save_user_money <= save_user_money - item_number_save * 100 - 10;
						end
						if((save_exp + item_number_save*20 >= 1000) && save_user_level == 2'b11)begin
							save_user_level <= 2'b10;
							save_exp <= 0;
						end
						else if((save_exp + item_number_save*20 >= 2500) && save_user_level == 2'b10)begin
							save_user_level <= 2'b01;
							save_exp <= 0;
						end
						else if((save_exp + item_number_save*20 >= 4000) && save_user_level == 2'b01)begin
							save_user_level <= 2'b00;
							save_exp <= 0;
						end
						else if(save_user_level == 2'b00)begin
							save_exp <= 0;
						end
						else begin
							save_exp <= save_exp + item_number_save*20;
						end
						save_small_number_user <= save_small_number_user + item_number_save;
					end
					else begin
						flag_oom <= 1;
					end
				end	
				else begin
					if(save_small_number_user + item_number_save > 63)begin
						flag_uiif <= 1;
					end
					if(save_small_number_seller < item_number_save)begin
						flag_siine <= 1;
					end
				end
			end
		end
		else if(item_id_save == 2 && cs == CAL_BUY && act_save == Buy)begin //medium
			if(cal_cnt == 1)begin
				save_medium_number_seller <= save_seller_data[57:52];
				save_medium_number_user <= save_user_data[57:52];
				save_seller_money <= save_seller_data[31:16];
				save_user_money <= save_user_data[31:16];
				save_exp <= save_user_data[43:32];
				save_user_level <= save_user_data[45:44];
			end
			else if(cal_cnt == 2)begin
				if(save_medium_number_user + item_number_save <= 63 && save_medium_number_seller >= item_number_save)begin
					if((save_user_level == 2'b00 && save_user_money >= item_number_save * 200 + 10) || save_user_level == 2'b01 && save_user_money >= item_number_save * 200 + 30 || (save_user_level == 2'b10 && save_user_money >= item_number_save * 200 + 50) || (save_user_level == 2'b11 && save_user_money >= item_number_save * 200 + 70))begin
						save_medium_number_seller <= save_medium_number_seller - item_number_save;
						if(save_seller_money + item_number_save * 200 > 65535)begin
							save_seller_money <= 65535;
						end
						else begin
							save_seller_money <= save_seller_money + item_number_save * 200;
						end
						if(save_user_level == 2'b11)begin
							save_user_money <= save_user_money - item_number_save * 200 - 70;
						end
						else if(save_user_level == 2'b10)begin
							save_user_money <= save_user_money - item_number_save * 200 - 50;
						end
						else if(save_user_level == 2'b01)begin
							save_user_money <= save_user_money - item_number_save * 200 - 30;
						end
						else if(save_user_level == 2'b00)begin
							save_user_money <= save_user_money - item_number_save * 200 - 10;
						end
						if((save_exp + item_number_save * 40 >= 1000) && save_user_level == 2'b11)begin
							save_user_level <= 2'b10;
							save_exp <= 0;
						end
						else if((save_exp + item_number_save * 40 >= 2500) && save_user_level == 2'b10)begin
							save_user_level <= 2'b01;
							save_exp <= 0;
						end
						else if((save_exp + item_number_save * 40 >= 4000) && save_user_level == 2'b01)begin
							save_user_level <= 2'b00;
							save_exp <= 0;
						end
						else if(save_user_level == 2'b00)begin
							save_exp <= 0;
						end
						else begin
							save_exp <= save_exp + item_number_save * 40;
						end
						save_medium_number_user <= save_medium_number_user + item_number_save;
					end
					else begin
						flag_oom <= 1;
					end
				end	
				else begin
					if(save_medium_number_user + item_number_save > 63)begin
						flag_uiif <= 1;
					end
					if(save_medium_number_seller < item_number_save)begin
						flag_siine <= 1;
					end
				end
			end
		end
		else if(item_id_save == 1 && cs == CAL_BUY && act_save == Buy)begin //large
			if(cal_cnt == 'd1)begin
				save_large_number_seller <= save_seller_data[63:58];
				save_large_number_user <= save_user_data[63:58];
				save_seller_money <= save_seller_data[31:16];
				save_user_money <= save_user_data[31:16];
				save_exp <= save_user_data[43:32];
				save_user_level <= save_user_data[45:44];
			end
			else if(cal_cnt == 'd2)begin
				if(save_large_number_user + item_number_save <= 63 && save_large_number_seller >= item_number_save)begin
					if((save_user_level == 2'b00 && save_user_money >= item_number_save * 300 + 10) || save_user_level == 2'b01 && save_user_money >= item_number_save * 300 + 30 || (save_user_level == 2'b10 && save_user_money >= item_number_save * 300 + 50) || (save_user_level == 2'b11 && save_user_money >= item_number_save * 300 + 70))begin
						save_large_number_seller <= save_large_number_seller - item_number_save;
						if(save_seller_money + item_number_save * 300 > 65535)begin
							save_seller_money <= 65535;
						end
						else begin
							save_seller_money <= save_seller_money + item_number_save * 300;
						end
						if(save_user_level == 2'b11)begin
							save_user_money <= save_user_money - item_number_save * 300 - 70;
						end
						else if(save_user_level == 2'b10)begin
							save_user_money <= save_user_money - item_number_save * 300 - 50;
						end
						else if(save_user_level == 2'b01)begin
							save_user_money <= save_user_money - item_number_save * 300 - 30;
						end
						else if(save_user_level == 2'b00)begin
							save_user_money <= save_user_money - item_number_save * 300 - 10;
						end
						if((save_exp + item_number_save*60 >= 1000) && save_user_level == 2'b11)begin
							save_user_level <= 2'b10;
							save_exp <= 0;
						end
						else if((save_exp + item_number_save*60 >= 2500) && save_user_level == 2'b10)begin
							save_user_level <= 2'b01;
							save_exp <= 0;
						end
						else if((save_exp + item_number_save*60 >= 4000) && save_user_level == 2'b01)begin
							save_user_level <= 2'b00;
							save_exp <= 0;
						end
						else if(save_user_level == 2'b00)begin
							save_exp <= 0;
						end
						else begin
							save_exp <= save_exp + item_number_save*60;
						end
						save_large_number_user <= save_large_number_user + item_number_save;
					end
					else begin
						flag_oom <= 1;
					end
				end	
				else begin
					if(save_large_number_user + item_number_save > 63)begin
						flag_uiif <= 1;
					end
					if(save_large_number_seller < item_number_save)begin
						flag_siine <= 1;
					end
				end
			end
		end
		else if(cs == CAL_BUY && act_save == Deposit)begin //Deposit
			if(cal_cnt == 0)begin
				save_user_money <= save_user_data[31:16];
			end
			else if(cal_cnt == 1)begin
				if(save_user_money + amnt_save < 65536)begin
					save_user_money <= save_user_money + amnt_save;
				end
				else begin
					flag_wif <= 1;
				end
			end
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		flag_last_is_buy <= 0;
	end
	else begin
		if(flag_last_is_buy && inf.out_valid && inf.err_msg == No_Err && act_save != Buy)begin
			flag_last_is_buy <= 0;
		end
		else begin
			if(act_save == Buy && inf.out_valid && inf.err_msg == No_Err)begin
				flag_last_is_buy <= 1;
			end
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		cal_cnt <= 0;
	end
	else begin
		if(ns == IDLE)begin
			cal_cnt <= 0;
		end
		else if(cs == CAL_BUY)begin
			cal_cnt <= cal_cnt + 1;
		end
	end
end
/////////////////////////
//  OUTPUT
/////////////////////////
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.out_valid <= 'd0;
	end
	else begin
		if(ns == OUTPUT)begin
			inf.out_valid <= 'd1;
		end
		else if(cs == OUTPUT)begin
			inf.out_valid <= 0;
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.out_info <= 'd0;
	end
	else begin
		if(ns == OUTPUT)begin
			if(act_save == Buy)begin
				if(flag_oom || flag_siine || flag_uiif)begin
					inf.out_info <= 0;
				end
				else begin
					inf.out_info <= save_user_data[31:0];
				end
			end
			else if(act_save == Return)begin
				if(flag_wo || flag_wsi || flag_wn || flag_wi)begin
					inf.out_info <= 0;
				end
				else begin
					inf.out_info <= {14'd0,save_user_data[63:46]};
				end
			end
			else if(act_save == Deposit)begin
				if(flag_wif)begin
					inf.out_info <= 0;
				end
				else begin
					inf.out_info <= {16'd0,save_user_money};
				end
			end
			else if(act_save == Check && judge_check_sell_user)begin
				inf.out_info <= {14'd0,save_seller_data[63:46]};
			end
			else if(act_save == Check && !judge_check_sell_user)begin
				inf.out_info <= {16'd0,save_user_data[31:16]};
			end
		end	
		else if(cs == OUTPUT)begin
			inf.out_info <= 0;
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.err_msg <= No_Err;
	end
	else begin
		if(ns == IDLE)begin
			inf.err_msg <= No_Err;
		end
		else if(act_save == Return && flag_wo)begin
			inf.err_msg <= Wrong_act;
		end
		else if(act_save == Return && flag_wsi && !flag_wo)begin
			inf.err_msg <= Wrong_ID;
		end
		else if(act_save == Return && flag_wn && !flag_wsi && !flag_wo)begin
			inf.err_msg <= Wrong_Num;
		end
		else if(act_save == Return && flag_wi && !flag_wn && !flag_wsi && !flag_wo)begin
			inf.err_msg <= Wrong_Item;
		end
		else if(act_save == Buy && flag_uiif)begin
			inf.err_msg <= INV_Full;
		end
		else if(act_save == Buy && flag_siine && !flag_uiif)begin
			inf.err_msg <= INV_Not_Enough;
		end
		else if(act_save == Buy && !flag_siine && !flag_uiif && flag_oom)begin
			inf.err_msg <= Out_of_money;
		end
		else if(act_save == Deposit && flag_wif)begin
			inf.err_msg <= Wallet_is_Full;
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.complete <= 'd0;
	end
	else begin
		if(act_save == Deposit && flag_wif || act_save == Buy && (flag_oom || flag_siine || flag_uiif) || (act_save == Return && (flag_wo || flag_wsi || flag_wn || flag_wi)))begin
			inf.complete <= 'd0;
		end
		else begin
			if(ns == OUTPUT)begin
				inf.complete <= 'd1;
			end
			else if(cs == OUTPUT)begin
				inf.complete <= 0;
			end
		end
	end
end
endmodule