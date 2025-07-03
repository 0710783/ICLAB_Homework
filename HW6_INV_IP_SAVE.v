//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright Optimum Application-Specific Integrated System Laboratory
//    All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : INV_IP.v
//   	Module Name : INV_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module INV_IP #(parameter IP_WIDTH = 6) (
    // Input signals
    IN_1, IN_2,
    // Output signals
    OUT_INV
);

// ===============================================================
// Declaration
// ===============================================================
input  [IP_WIDTH-1:0] IN_1, IN_2; 
output [IP_WIDTH-1:0] OUT_INV;

wire signed[IP_WIDTH+1:0] prime_num,cal_num;
wire signed[IP_WIDTH+1:0] t[9:0],newt[9:0],r[9:0],newr[9:0];
wire signed[IP_WIDTH+1:0] quo[9:0],outputsave[9:0],realoutput[9:0];

integer k;
genvar i;

generate
	assign prime_num = (IN_1>IN_2)?IN_1:IN_2;
	assign cal_num = (IN_1>IN_2)?IN_2:IN_1;
	for(i=0;i<10;i=i+1)begin: loop
		if(i==0)begin
			assign r[0] = prime_num;
			assign newr[0] = cal_num;
			assign t[0] = 0;
			assign newt[0] = 1;
			assign outputsave[0] = 0;
			assign realoutput [0] = 0;
			assign quo[0] = 0;
		end
		else begin
			assign quo[i] = (newr[i-1]==0)?0:r[i-1]/newr[i-1];
			assign t[i] = newt[i-1];
			assign newt[i] = t[i-1]-quo[i]*newt[i-1];
			assign r[i] = newr[i-1];
			assign newr[i] = r[i-1]-quo[i]*newr[i-1];
			assign outputsave[i] = (newr[i]==0)?t[i]:outputsave[i-1];
			assign realoutput[i] = (outputsave[i]<0)?outputsave[i]+prime_num:outputsave[i];
		end
	end
endgenerate
	assign OUT_INV = realoutput[9];
endmodule
