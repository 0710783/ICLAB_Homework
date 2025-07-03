//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//
//   File Name   : CHECKER.sv
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
//`include "Usertype_PKG.sv"

module Checker(input clk, INF.CHECKER inf);
import usertype::*;

covergroup Spec1 @(posedge clk && inf.amnt_valid);
	DATA:coverpoint inf.D.d_money{
		option.at_least = 10 ;
		bins b1 = {[    0:12000]} ;
		bins b2 = {[12001:24000]} ;
		bins b3 = {[24001:36000]} ;
		bins b4 = {[36001:48000]} ;
		bins b5 = {[48001:60000]} ;
	}
endgroup : Spec1

covergroup Spec2 @(posedge clk && inf.id_valid);
   	coverpoint inf.D.d_id[0] {
   		option.at_least = 2 ;
   		option.auto_bin_max = 256 ;
   	}
endgroup : Spec2
// bins*at_least = 25 * 10 = 250
covergroup Spec3 @(posedge clk && inf.act_valid);
   	Action:coverpoint inf.D.d_act[0] {
   		option.at_least = 10 ;
   		bins b1 = {Buy};
		bins b2 = {Check};
		bins b3 = {Deposit};
		bins b4 = {Return} ;
   	}

endgroup : Spec3

covergroup Spec4 @(posedge clk && inf.item_valid);
   	Item_id:coverpoint inf.D.d_item[0] {
   		option.at_least = 20 ;
		bins b2 = {Large};
		bins b3 = {Medium};
		bins b4 = {Small} ;
   	}

endgroup : Spec4
// bins*at_least = 4 * 100 = 400
covergroup Spec5 @(negedge clk && inf.out_valid);
	Error_Msg:coverpoint inf.err_msg {
		option.at_least = 20 ;
		bins b1 = {INV_Not_Enough } ;
		bins b2 = {Out_of_money} ;
		bins b3 = {INV_Full} ;
		bins b4 = {Wallet_is_Full} ;
		bins b5 = {Wrong_ID } ;
		bins b6 = {Wrong_Num} ;
		bins b7 = {Wrong_Item} ;
		bins b8 = {Wrong_act} ;
	}
endgroup : Spec5

covergroup Spec6 @(negedge clk && inf.out_valid);
   	coverpoint inf.complete {
   		option.at_least = 200 ;
   		bins b1 = {0} ;
		bins b2 = {1};
   	}

endgroup : Spec6
//================================================================
//  declare cover group
//================================================================
Spec1 cov_inst_1 = new();
Spec2 cov_inst_2 = new();
Spec3 cov_inst_3 = new();
Spec4 cov_inst_4 = new();
Spec5 cov_inst_5 = new();
Spec6 cov_inst_6 = new();
Action act ;
logic [4:0]count_input_valid,count2;
logic flag_out_in,flag_out_in2;
logic fsm;
logic fffff;
logic last_is_outvalid;
always_ff @(posedge clk or negedge inf.rst_n)  begin
	if (!inf.rst_n)begin
		act <= No_action ;
	end
	else begin 
		if (inf.act_valid===1) 	act <= inf.D.d_act[0] ;
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		count_input_valid <= 0;
	end
	else begin
		if(fsm === 0)begin
			count_input_valid <= 0;
		end
		else if(fsm === 1 && count_input_valid != 6 && !inf.out_valid)begin
			count_input_valid <= count_input_valid + 1;
		end
		else if(fsm === 1 && count_input_valid == 6 && !inf.out_valid)begin
			count_input_valid <= 6;
		end
		else if(inf.out_valid)begin
			count_input_valid <= 0;
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		fsm <= 0;
	end
	else begin
		if((inf.id_valid || inf.act_valid || inf.item_valid || inf.num_valid || inf.amnt_valid) && fsm === 0)begin
			fsm <= 1;
		end
		else if((inf.id_valid || inf.act_valid || inf.item_valid || inf.num_valid || inf.amnt_valid) && fsm === 1)begin
			fsm <= 0;
		end
		else if(inf.out_valid && fsm === 1)begin
			fsm <= 0;
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		flag_out_in <= 0;
	end
	else begin
		if((inf.id_valid || inf.item_valid || inf.amnt_valid || inf.num_valid || inf.act_valid) && count_input_valid == 6 || (inf.id_valid || inf.item_valid || inf.id_valid || inf.amnt_valid || inf.num_valid) && fsm && count_input_valid == 0)begin
			flag_out_in <= 1;
		end
		else begin
			flag_out_in <= 0;
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		count2 <= 0;
	end
	else begin
		if(inf.out_valid)begin
			count2 <= 0;
		end
		else if(count2 === 5)begin
			count2 <= 5;
		end
		else begin
			if(inf.act_valid || inf.id_valid || inf.amnt_valid || inf.num_valid || inf.item_valid)begin
				count2 <= 0;
			end
			else begin
				if(!last_is_outvalid)begin
					count2 <= count2 + 1;
				end
			end
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		flag_out_in2 <= 0;
	end
	else begin
		if(count2 === 5)begin
			flag_out_in2 <= 1;
		end
		else begin
			flag_out_in2 <= 0;
		end
	end
end

always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		last_is_outvalid <= 0;
	end
	else begin
		if(inf.id_valid || inf.act_valid)begin
			last_is_outvalid <= 0;
		end
		else if(inf.out_valid)begin
			last_is_outvalid <= 1;
		end
	end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		fffff <= 0;
	end
	else begin
		if(inf.out_valid)begin
			fffff <= 0;
		end
		else begin
			if(count2 === 5 && (inf.id_valid || inf.act_valid || inf.amnt_valid || inf.num_valid || inf.item_valid))begin
				fffff <= 1;
			end
		end
	end
end
//************************************ below assertion is to check your pattern ***************************************** 
//                                          Please finish and hand in it
// This is an example assertion given by TA, please write other assertions at the below
// assert_interval : assert property ( @(posedge clk)  inf.out_valid |=> inf.id_valid == 0 [*2])
// else
// begin
// 	$display("Assertion X is violated");
// 	$fatal; 
// end

//write other assertions
assert_rst : assert property ( @(posedge inf.rst_n)  !inf.rst_n |-> (inf.AR_VALID === 0 && inf.out_valid===0 && inf.out_info===0 && inf.complete===0 && inf.err_msg===No_Err))
else	begin
	$display("Assertion 1 is violated");
	$fatal; 
end
assert_rst2 : assert property ( @(posedge clk)  (!flag_out_in2) |-> (inf.out_valid===0 && inf.out_info===0 && inf.complete===0 && inf.err_msg===No_Err))
else	begin
	$display("Assertion 1 is violated");
	$fatal; 
end
assert_err : assert property( @(posedge clk) (inf.complete) |-> inf.err_msg===No_Err)
else begin
	$display("Assertion 2 is violated");
	$fatal; 
end

assert_notcomplete : assert property( @(posedge clk) (!inf.complete) |-> inf.out_info===32'b0)
else begin
	$display("Assertion 3 is violated");
	$fatal; 
end

assert_act1 : assert property( @(posedge clk) ((inf.act_valid) |=> inf.act_valid===0))
else begin
	$display("Assertion 4 is violated");
	$fatal; 
end
assert_act2 : assert property( @(posedge clk) ((inf.id_valid) |=> inf.id_valid===0)) 
else begin
	$display("Assertion 4 is violated");
	$fatal; 
end
assert_act3 : assert property( @(posedge clk) ((inf.item_valid) |=> inf.item_valid===0))
else begin
	$display("Assertion 4 is violated");
	$fatal; 
end
assert_act4 : assert property( @(posedge clk) ((inf.num_valid) |=> inf.num_valid===0))
else begin
	$display("Assertion 4 is violated");
	$fatal; 
end
assert_act5 : assert property( @(posedge clk) ((inf.amnt_valid) |=> inf.amnt_valid===0))
else begin
	$display("Assertion 4 is violated");
	$fatal; 
end

assert_overlap : assert property( @(posedge clk) (inf.id_valid + inf.amnt_valid + inf.item_valid + inf.act_valid + inf.num_valid) <=1 )
else begin
	$display("Assertion 5 is violated");
	$fatal; 
end

assert_1_5 : assert property( @(posedge clk) (!flag_out_in))
else begin
	$display("Assertion 6 is violated");
	$fatal; 
end

assert_1_5_2 : assert property( @(posedge clk) (!fffff))
else begin
	$display("Assertion 6 is violated");
	$fatal;
end

assert_valid : assert property( @(posedge clk) (inf.out_valid |=> inf.out_valid===0))
else begin
	$display("Assertion 7 is violated");
	$fatal; 
end

assert_2_10_outvalid :assert property ( @(posedge clk) (inf.out_valid===1)  |-> ##[2:10] ( inf.id_valid===1 || inf.act_valid===1) )  
else begin
 	$display("Assertion 8 is violated");
 	$fatal; 
end
assert_9_1 : assert property ( @(posedge clk) ( (act===Buy||act===Return||act===Check) && (inf.id_valid===1) ) |-> ( ##[1:10000] inf.out_valid===1 ) )
else
begin
	$display("Assertion 9 is violated");
	$fatal; 
end
assert_9_2 : assert property ( @(posedge clk) ( (inf.D.d_act[0]===Check || inf.D.d_act[0]===Buy) && (inf.act_valid===1)) |-> ( ##[1:10000] inf.out_valid===1 ) )
else
begin
	$display("Assertion 9 is violated");
	$fatal; 
end
assert_9_3 : assert property ( @(posedge clk) ( act===Deposit && (inf.amnt_valid===1)) |-> ( ##[1:10000] inf.out_valid===1 ) )
else
begin
	$display("Assertion 9 is violated");
	$fatal; 
end

endmodule