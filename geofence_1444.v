module geofence ( clk,reset,X,Y,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output valid;
output is_inside;

reg valid;
reg is_inside;

parameter DUT     = 3'd1, 
		  ANTENNA = 3'd3, 
		  SORT    = 3'd7,
		  CALC    = 3'd6,
		  OUT     = 3'd4;

reg        [2 :0] state_curr, state_nxt;
reg signed [10:0] DUT_ACC_X_ff, DUT_ACC_Y_ff, DUT_ACC_X_comb, DUT_ACC_Y_comb;
reg signed [10:0] A_X_comb	[5:0];
reg signed [10:0] A_Y_comb	[5:0];
reg signed [10:0] A_X_ff	[5:0];
reg signed [10:0] A_Y_ff	[5:0];		  
reg        [3 :0] counter_comb, counter_ff;


always@(posedge reset or posedge clk)begin
	if(reset)begin
		for(integer i = 0; i < 6; i = i + 1)begin		
			A_X_ff[i] <= 0;
			A_Y_ff[i] <= 0;
		end
		DUT_ACC_X_ff <= 0; 
		DUT_ACC_Y_ff <= 0;
		counter_ff <= 0;
		state_curr <= DUT;
	end	
	else begin
		for(integer i = 0; i < 6 ; i = i + 1)begin
			A_X_ff[i] <= A_X_comb[i];
			A_Y_ff[i] <= A_Y_comb[i];
		end
		DUT_ACC_X_ff <= DUT_ACC_X_comb; 
		DUT_ACC_Y_ff <= DUT_ACC_Y_comb;
		counter_ff <= counter_comb;
		state_curr <= state_nxt;
	end
end

//FSM
always@(*)begin
	state_nxt = state_curr;
	case(state_curr)
		DUT:     state_nxt = ANTENNA;
		ANTENNA: state_nxt = (counter_ff == 5)  ? SORT : ANTENNA;
		SORT:    state_nxt = (counter_ff == 9)  ? CALC : SORT;
		CALC:    state_nxt = (counter_ff == 6)  ? OUT  : CALC;
		OUT:     state_nxt = DUT;
		default: state_nxt = DUT;
	endcase
end

//COUNTER_UTILIZATION
always@(*)begin
	counter_comb = counter_ff;
	if(state_curr == DUT)begin
		counter_comb = 0;
	end
	else if(state_curr == ANTENNA)begin
		counter_comb = (counter_ff == 5) ? 0 : counter_ff + 1;
	end
	else if(state_curr == SORT)begin
		counter_comb  = (counter_ff == 9) ? 0 : counter_ff + 1;
	end
	else if(state_curr == CALC)begin
		counter_comb = (counter_ff == 6) ? 0 : counter_ff + 1;
	end
	else begin
		counter_comb = counter_ff;
	end
end

reg  [1:0]  HOT_ff   [5:0];
reg  [1:0]  HOT_comb [5:0];
reg  [1:0]  compareone;
reg  [2:0]  line1, line2;
reg  valid_comb, is_inside_comb;

//INPUT ASSIGNMENT
always@(*)begin
	for(integer i = 0; i < 6; i = i + 1)begin
		A_X_comb[i] = A_X_ff[i];
		A_Y_comb[i] = A_Y_ff[i];
		HOT_comb[i] = HOT_ff[i];
	end
	DUT_ACC_X_comb = DUT_ACC_X_ff;
	DUT_ACC_Y_comb = DUT_ACC_Y_ff;
	valid_comb = 0;
	is_inside_comb = 0;
	
	if(state_curr == DUT)begin
		DUT_ACC_X_comb = X;
		DUT_ACC_Y_comb = Y;
	end
	else if(state_curr == ANTENNA)begin
		A_X_comb[counter_ff] = X;
		A_Y_comb[counter_ff] = Y;
	end
	else if(state_curr == SORT)begin
		A_X_comb[line1] = (compareone != 0) ? A_X_ff[line1] : A_X_ff[line2];
		A_Y_comb[line1] = (compareone != 0) ? A_Y_ff[line1] : A_Y_ff[line2];
		A_X_comb[line2] = (compareone != 0) ? A_X_ff[line2] : A_X_ff[line1];
		A_Y_comb[line2] = (compareone != 0) ? A_Y_ff[line2] : A_Y_ff[line1];
	end
	else if(state_curr == CALC)begin
		if(counter_ff != 6)begin
			HOT_comb[counter_ff] = compareone;
		end
		else begin
			valid_comb = 1;
			is_inside_comb = ((HOT_ff[0] == HOT_ff[1]) && (HOT_ff[1] == HOT_ff[2]) && (HOT_ff[2] == HOT_ff[3]) && (HOT_ff[3] == HOT_ff[4]) && (HOT_ff[4] == HOT_ff[5]) && (!HOT_ff[0][1]));
		end
	end
end

always@(posedge reset or posedge clk)begin
	if(reset)begin
		for(integer k = 0; k < 6; k = k + 1)begin
			HOT_ff[k] <= 0;
		end
		valid     <= 0;
		is_inside <= 0;
	end
	else begin
		for(integer k = 0; k < 6; k = k + 1)begin
			HOT_ff[k] <= HOT_comb[k];
		end
		valid     <= valid_comb;
		is_inside <= is_inside_comb;
	end
end

COMPARATOR comp1(state_curr, counter_ff, A_X_ff, A_Y_ff, DUT_ACC_X_ff, DUT_ACC_Y_ff, compareone, line1, line2);

endmodule

module COMPARATOR(
state_com,
count_com,
EXT_LIST_X,
EXT_LIST_Y,
D_X,
D_Y,
RESULT_OUT,
LIN1, 
LIN2
);
input        [2:0] state_com;
input        [3:0] count_com;
input signed [10:0] EXT_LIST_X [5:0];
input signed [10:0] EXT_LIST_Y [5:0];
input        [9:0] D_X;
input        [9:0] D_Y;
output       [1:0] RESULT_OUT;
output       [2:0] LIN1, LIN2;

reg signed [20:0] PROD_1, PROD_2;
reg [2:0] L1, L2;
reg [1:0] RESULT;

always@(*)begin
	if(state_com == 3'd7)begin
		case(count_com)
			4'd0: begin
				PROD_1 = (EXT_LIST_X[1] - EXT_LIST_X[0]) * (EXT_LIST_Y[2] - EXT_LIST_Y[0]);
				PROD_2 = (EXT_LIST_X[2] - EXT_LIST_X[0]) * (EXT_LIST_Y[1] - EXT_LIST_Y[0]);
				L1 = 1; L2 = 2;
			end
			4'd1: begin
				PROD_1 = (EXT_LIST_X[1] - EXT_LIST_X[0]) * (EXT_LIST_Y[3] - EXT_LIST_Y[0]);
				PROD_2 = (EXT_LIST_X[3] - EXT_LIST_X[0]) * (EXT_LIST_Y[1] - EXT_LIST_Y[0]);
				L1 = 1; L2 = 3;
			end
			4'd2: begin
				PROD_1 = (EXT_LIST_X[1] - EXT_LIST_X[0]) * (EXT_LIST_Y[4] - EXT_LIST_Y[0]);
				PROD_2 = (EXT_LIST_X[4] - EXT_LIST_X[0]) * (EXT_LIST_Y[1] - EXT_LIST_Y[0]);
				L1 = 1; L2 = 4;
			end
			4'd3: begin
				PROD_1 = (EXT_LIST_X[1] - EXT_LIST_X[0]) * (EXT_LIST_Y[5] - EXT_LIST_Y[0]);
				PROD_2 = (EXT_LIST_X[5] - EXT_LIST_X[0]) * (EXT_LIST_Y[1] - EXT_LIST_Y[0]);
				L1 = 1; L2 = 5;
			end
			4'd4: begin
				PROD_1 = (EXT_LIST_X[2] - EXT_LIST_X[0]) * (EXT_LIST_Y[3] - EXT_LIST_Y[0]);
				PROD_2 = (EXT_LIST_X[3] - EXT_LIST_X[0]) * (EXT_LIST_Y[2] - EXT_LIST_Y[0]);
				L1 = 2; L2 = 3;
			end
			4'd5: begin
				PROD_1 = (EXT_LIST_X[2] - EXT_LIST_X[0]) * (EXT_LIST_Y[4] - EXT_LIST_Y[0]);
				PROD_2 = (EXT_LIST_X[4] - EXT_LIST_X[0]) * (EXT_LIST_Y[2] - EXT_LIST_Y[0]);
				L1 = 2; L2 = 4;
			end
			4'd6: begin
				PROD_1 = (EXT_LIST_X[2] - EXT_LIST_X[0]) * (EXT_LIST_Y[5] - EXT_LIST_Y[0]);
				PROD_2 = (EXT_LIST_X[5] - EXT_LIST_X[0]) * (EXT_LIST_Y[2] - EXT_LIST_Y[0]);
				L1 = 2; L2 = 5;
			end
			4'd7: begin
				PROD_1 = (EXT_LIST_X[3] - EXT_LIST_X[0]) * (EXT_LIST_Y[4] - EXT_LIST_Y[0]);
				PROD_2 = (EXT_LIST_X[4] - EXT_LIST_X[0]) * (EXT_LIST_Y[3] - EXT_LIST_Y[0]);
				L1 = 3; L2 = 4;
			end
			4'd8: begin
				PROD_1 = (EXT_LIST_X[3] - EXT_LIST_X[0]) * (EXT_LIST_Y[5] - EXT_LIST_Y[0]);
				PROD_2 = (EXT_LIST_X[5] - EXT_LIST_X[0]) * (EXT_LIST_Y[3] - EXT_LIST_Y[0]);
				L1 = 3; L2 = 5;
			end
			4'd9: begin
				PROD_1 = (EXT_LIST_X[4] - EXT_LIST_X[0]) * (EXT_LIST_Y[5] - EXT_LIST_Y[0]);
				PROD_2 = (EXT_LIST_X[5] - EXT_LIST_X[0]) * (EXT_LIST_Y[4] - EXT_LIST_Y[0]);
				L1 = 4; L2 = 5;
			end
			default: begin
				PROD_1 = 0; PROD_2 = 0; L1 = 0; L2 = 0;
			end
		endcase
		
		RESULT = (PROD_1 > PROD_2) ? 2'd1 : 2'd0;
		
	end
	else if(state_com == 3'd6)begin
		L1 = 0; L2 = 0;
		case(count_com)
			4'd0: begin
				PROD_1 = (EXT_LIST_X[0] - D_X)           * (EXT_LIST_Y[1] - EXT_LIST_Y[0]);
				PROD_2 = (EXT_LIST_X[1] - EXT_LIST_X[0]) *           (EXT_LIST_Y[0] - D_Y);
			end
			4'd1: begin
				PROD_1 = (EXT_LIST_X[1] - D_X)           * (EXT_LIST_Y[2] - EXT_LIST_Y[1]);
				PROD_2 = (EXT_LIST_X[2] - EXT_LIST_X[1]) *           (EXT_LIST_Y[1] - D_Y);
			end
			4'd2: begin
				PROD_1 = (EXT_LIST_X[2] - D_X)           * (EXT_LIST_Y[3] - EXT_LIST_Y[2]);
				PROD_2 = (EXT_LIST_X[3] - EXT_LIST_X[2]) *           (EXT_LIST_Y[2] - D_Y);
			end
			4'd3: begin
				PROD_1 = (EXT_LIST_X[3] - D_X)           * (EXT_LIST_Y[4] - EXT_LIST_Y[3]);
				PROD_2 = (EXT_LIST_X[4] - EXT_LIST_X[3]) *           (EXT_LIST_Y[3] - D_Y);
			end
			4'd4: begin
				PROD_1 = (EXT_LIST_X[4] - D_X)           * (EXT_LIST_Y[5] - EXT_LIST_Y[4]);
				PROD_2 = (EXT_LIST_X[5] - EXT_LIST_X[4]) *           (EXT_LIST_Y[4] - D_Y);
			end
			4'd5: begin
				PROD_1 = (EXT_LIST_X[5] - D_X)           * (EXT_LIST_Y[0] - EXT_LIST_Y[5]);
				PROD_2 = (EXT_LIST_X[0] - EXT_LIST_X[5]) *           (EXT_LIST_Y[5] - D_Y);
			end
			default: begin
				PROD_1 = 0; PROD_2 = 0; L1 = 0; L2 = 0;
			end
		endcase
		
		RESULT = (PROD_1 > PROD_2) ? 1 : (PROD_1 < PROD_2) ? 0 : 2;
		
	end
	else begin
		L1 = 0; L2 = 0; PROD_1 = 0; PROD_2 = 0; RESULT = 0;
	end
end

assign RESULT_OUT = RESULT;
assign LIN1 = L1;
assign LIN2 = L2;

endmodule
