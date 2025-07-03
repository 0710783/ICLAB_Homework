module CC(
  in_s0,
  in_s1,
  in_s2,
  in_s3,
  in_s4,
  in_s5,
  in_s6,
  opt,
  a,
  b,
  s_id0,
  s_id1,
  s_id2,
  s_id3,
  s_id4,
  s_id5,
  s_id6,
  out

);
input [3:0]in_s0;
input [3:0]in_s1;
input [3:0]in_s2;
input [3:0]in_s3;
input [3:0]in_s4;
input [3:0]in_s5;
input [3:0]in_s6;
input [2:0]opt;
input [1:0]a;
input [2:0]b;
output reg[2:0] s_id0;
output reg[2:0] s_id1;
output reg[2:0] s_id2;
output reg[2:0] s_id3;
output reg[2:0] s_id4;
output reg[2:0] s_id5;
output reg[2:0] s_id6;
output reg[2:0] out; 
//==================================================================
// reg & wire
reg signed [4:0]sign_in_s[6:0];
reg signed [6:0]sign_in_s_tolinear[6:0];
reg [2:0]student[6:0];
reg signed[4:0]average;
reg signed[4:0]temp;
reg signed[4:0]temp2;
reg signed[4:0]pass_score;
reg signed[4:0]pass_save_score;
integer i,j;
reg [2:0]asave,bsave;
//==================================================================

//==================================================================
// design
always @(*) begin
	out = 0;
	asave = a;
	bsave = b;
	
	student[0] = 3'b000;
	student[1] = 3'b001;
	student[2] = 3'b010;
	student[3] = 3'b011;
	student[4] = 3'b100;
	student[5] = 3'b101;
	student[6] = 3'b110;
	
	if(!opt[0])begin  //opt0=0,unsigned
		sign_in_s[0] = {1'b0,in_s0};
		sign_in_s[1] = {1'b0,in_s1};
		sign_in_s[2] = {1'b0,in_s2};
		sign_in_s[3] = {1'b0,in_s3};
		sign_in_s[4] = {1'b0,in_s4};
		sign_in_s[5] = {1'b0,in_s5};
		sign_in_s[6] = {1'b0,in_s6};
	end
	else begin  //opt0=1,signed
		sign_in_s[0] = {in_s0[3],in_s0};
		sign_in_s[1] = {in_s1[3],in_s1};
		sign_in_s[2] = {in_s2[3],in_s2};
		sign_in_s[3] = {in_s3[3],in_s3};
		sign_in_s[4] = {in_s4[3],in_s4};
		sign_in_s[5] = {in_s5[3],in_s5};
		sign_in_s[6] = {in_s6[3],in_s6};
	end
	
	for(i=0;i<6;i=i+1)begin
		for(j=i+1;j<7;j=j+1)begin
			if(!opt[1])begin
				if(sign_in_s[i]>sign_in_s[j])begin
					temp = sign_in_s[i];
					sign_in_s[i] = sign_in_s[j];
					sign_in_s[j] = temp;
					temp2 = student[i];
					student[i] = student[j];
					student[j] = temp2;
				end
				else if(sign_in_s[i]<sign_in_s[j])begin
					sign_in_s[i] = sign_in_s[i];
				end
				else begin
					if(student[i]>student[j])begin
						temp2 = student[i];
						student[i] = student[j];
						student[j] = temp2;
					end
					else begin
						student[i] = student[i];
					end
				end
			end	
			else begin
				if(sign_in_s[i]<sign_in_s[j])begin
					temp = sign_in_s[i];
					sign_in_s[i] = sign_in_s[j];
					sign_in_s[j] = temp;
					temp2 = student[i];
					student[i] = student[j];
					student[j] = temp2;
				end
				else if(sign_in_s[i]>sign_in_s[j])begin
					sign_in_s[i] = sign_in_s[i];
				end
				else begin
					if(student[i]>student[j])begin
						temp2 = student[i];
						student[i] = student[j];
						student[j] = temp2;
					end
					else begin
						student[i] = student[i];
					end
				end
			end	
		end
	end

	
	for(i=0;i<7;i=i+1)begin
		sign_in_s_tolinear[i] = sign_in_s[i];
	end
	average = (sign_in_s[0]+sign_in_s[1]+sign_in_s[2]+sign_in_s[3]+sign_in_s[4]+sign_in_s[5]+sign_in_s[6])/7;
	pass_save_score = average-bsave;
	pass_score = pass_save_score - asave;
	case(asave)
		3'b000:
			pass_score = pass_save_score;
		3'b001:
			for(i=0;i<7;i=i+1)begin
				if(sign_in_s[i][4]==0)begin
					sign_in_s_tolinear[i] = sign_in_s[i] <<< 1;
				end
				else begin
					sign_in_s_tolinear[i]=sign_in_s[i]/2;
				end
			end
		3'b010:
			for(i=0;i<7;i=i+1)begin
				if(sign_in_s[i][4]==0)begin
					sign_in_s_tolinear[i] = sign_in_s[i]+sign_in_s[i]+sign_in_s[i];
				end
				else begin
					if(sign_in_s[i]==-1)begin
						sign_in_s_tolinear[i]=0;
					end
					else begin
						sign_in_s_tolinear[i] = sign_in_s[i] /3;
					end
				end
			end
		default:
			for(i=0;i<7;i=i+1)begin
				if(sign_in_s[i][4]==0)begin
					sign_in_s_tolinear[i] = sign_in_s[i] <<< 2;
				end
				else begin
					if(sign_in_s[i]==-1)begin
						sign_in_s_tolinear[i]=0;
					end
					else begin
						sign_in_s_tolinear[i] = sign_in_s[i] /4;
					end
				end
			end
	endcase
	/*for(i = 0;i<7;i=i+1)begin
		$display("%d %d",sign_in_s[i],sign_in_s_tolinear[i]);
	end
	$display("\n");
	$display("opt1=%d opt2 = %d a=%d b=%d average=%d",opt[1],opt[2],a,b,average);*/
	for(i=0;i<7;i=i+1)begin
		if(sign_in_s_tolinear[i]<pass_score)begin
			out = out+1;
		end
		else begin	
			out = out;
		end
	end
	if(!opt[2])begin  //passed
		out = 3'b111-out;
	end
	else begin //failed
		out = out;
	end
	s_id0 = student[0];
	s_id1 = student[1];
	s_id2 = student[2];
	s_id3 = student[3];
	s_id4 = student[4];
	s_id5 = student[5];
	s_id6 = student[6];
end
//==================================================================
endmodule
