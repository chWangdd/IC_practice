
`timescale 1ns/10ps

module  CONV(
	input		clk,
	input		reset,
	output		busy,	
	input		ready,	
			
	output		[11:0]iaddr,
	input		[19:0]idata,	
	
	output	 	cwr,
	output	 	[11:0]caddr_wr,
	output	 	[19:0]cdata_wr,
	
	output	 	crd,
	output	 	[11:0]caddr_rd,
	input	 	[19:0]cdata_rd,
	
	output	 	[2:0]csel
	);
integer i ;

reg [4:0] state_r,state_w ;

reg signed[19:0] pixel_data_ff ;
reg [11:0] get_data_addr ;
reg busy_ff ;
reg wait_one ;
reg end_one ;

reg signed[19:0] mul20_1 ; // {4,16}
reg signed[19:0] mul20_2 ; // {4.16}
reg signed[39:0] mul40 ; // {8,32}
reg signed[42:0] sumup_r , sumup_w ; //{11,32}
reg signed[42:0] temp,temp2 ; //{11,32}
reg [19:0]layer0_ans ;
reg [19:0]relu_ans ;


reg [19:0] pp ;

reg [3:0]  read_pixel_counter ;
reg [11:0] wout_cnt ;
wire case1,case2,case3,case4 ;
wire case5, case6 ;
wire case7, case8 ;
reg padding[1:9] ;

reg [9:0] maxpool_counter ;
wire maxpool_out_en ;
reg [11:0] maxpool_addr_r , maxpool_addr_w ;
reg signed [19:0]maxvalue_r, maxvalue_w ;
reg signed [19:0] layer0_data ;
wire debug ;

// read control cases assignment
assign case1 = (wout_cnt==0) ;
assign case2 = (wout_cnt==63) ;
assign case3 = (wout_cnt==4032) ;
assign case4 = (wout_cnt==4095) ;
assign case5 = (wout_cnt<63) ;
assign case6 = (wout_cnt>4032) ;
assign case7 = (wout_cnt[5:0]==0) ;
assign case8 = (wout_cnt[5:0]==63) ;

assign maxpool_out_en = (state_r==14) ;

// port assignment
assign busy = busy_ff ;
assign iaddr = get_data_addr ;

assign crd = (state_r>=10) ;
assign caddr_rd = (state_r>=10)? maxpool_addr_r : 0 ;

assign cwr = (state_r>=10)? maxpool_out_en :(state_r==1) ;
assign caddr_wr = (state_r>=10)? (maxpool_counter) : (wout_cnt-1) ;
assign cdata_wr = (state_r>=10)? maxvalue_w : relu_ans ;
assign csel = (maxpool_out_en)? 3 : 1 ;

assign debug =  (maxpool_addr_r[6:0]==127) ;

always @(posedge clk or posedge reset) begin
    if(reset) wout_cnt <= 0 ;
	else wout_cnt <= (ready)? 0 :(read_pixel_counter==9)? wout_cnt + 1: wout_cnt ;
end
always @(posedge clk or posedge reset) begin
    if(reset) read_pixel_counter <= 0 ;
	else read_pixel_counter <=  (ready)? 0 :(read_pixel_counter==9)? 1 : read_pixel_counter + 1 ;
end
always @(posedge clk or posedge reset) begin
    if(reset) sumup_r <= 0 ;
	else sumup_r <=  (ready)? 0 :(read_pixel_counter==9)? 0 : sumup_w ;
end
always @(posedge clk or posedge reset) begin
    if(reset) state_r <= 0 ;
	else state_r <=  (ready)? 0 :state_w ;
end
always @(posedge clk or posedge reset) begin
    if(reset) busy_ff <= 0 ;
	else busy_ff <= (end_one)? 0 : 1 ;
end
always @(posedge clk or posedge reset) begin
    if(reset) wait_one <= 0 ;
	else wait_one <= (state_r==9 && wout_cnt==4095)? 1 : 0 ;
end
always @(posedge clk or posedge reset) begin
    if(reset) end_one <= 0 ;
	else end_one <= (state_r==14 && maxpool_counter==1023)? 1 : 0 ;
end
always @(posedge clk or posedge reset) begin
    if(reset) relu_ans <= 0 ;
	else relu_ans <= layer0_ans ;
end

always @(posedge clk or posedge reset) begin
    if(reset) begin
		for(i=1;i<10;i=i+1) begin
			padding[i] <=  0 ;
		end
	end
	else begin
	    padding[1] <= (case1 | case2 | case5 | case8) ; 
	    padding[2] <= (case1 | case2 | case5) ; 
	    padding[3] <= (case1 | case2 | case4 | case5 | case8) ; 

	    padding[4] <= (case1 | case3 | case7) ; 
	    padding[5] <= 0 ; 
	    padding[6] <= (case2 | case4 | case8) ; 

	    padding[7] <= (case1 | case3 | case4 | case6 | case7) ; 
	    padding[8] <= (case3 | case4 | case6) ; 
	    padding[9] <= (case2 | case3 | case4 | case6 | case8) ; 
	end
end
always @(posedge clk or posedge reset) begin
    if(reset) pixel_data_ff <= 0 ;
	else pixel_data_ff <= idata ;
end
always @(posedge clk or posedge reset) begin
    if(reset) layer0_data <= 0 ;
	else layer0_data <= cdata_rd ;
end



always @(*) begin
	case(state_r)
	0 : state_w = 1 ;
	1 : state_w = (wait_one)? 10 : 2 ;
	2 : state_w = 3 ;
	3 : state_w = 4 ;
	4 : state_w = 5 ;
	5 : state_w = 6 ;
	6 : state_w = 7 ;
	7 : state_w = 8 ;
	8 : state_w = 9 ;
	9 : state_w = 1 ;
	10 : state_w = 11 ;
	11 : state_w = 12 ;
	12 : state_w = 13 ;
	13 : state_w = 14 ;
	14 : state_w = 10 ;
	default : state_w = 0 ;
	endcase
end
always @(*) begin
	case(state_r)
	0 : begin
	    get_data_addr = 0 ;
		mul20_1 = 0 ;
		mul20_2 = 0 ;
	end
	1 : begin
	    get_data_addr = (case1)? 0 : (case2)? 0  : (case3)? 3968 : (case4)? 4031 : (case5)? 0           :(case6)? wout_cnt-64 :(case7)? wout_cnt-64 :(case8)? wout_cnt-64 : wout_cnt-64 ;
		mul20_1 = 20'h0A89E ;
		mul20_2 = (case3)? 0 : (!padding[1])? pixel_data_ff : 0 ;
	end
	2 : begin
	    get_data_addr = (case1)? 0 : (case2)? 0  : (case3)? 3969 : (case4)? 0    : (case5)? 0           :(case6)? wout_cnt-63 :(case7)? wout_cnt-63 :(case8)? 0           : wout_cnt-63 ;
		mul20_1 = 20'h092D5;
		mul20_2 = (!padding[2])? pixel_data_ff : 0 ;
	end
	3 : begin
	    get_data_addr = (case1)? 0 : (case2)? 62 : (case3)? 0    : (case4)? 4094 : (case5)? wout_cnt-1  :(case6)? wout_cnt-1  :(case7)? 0           :(case8)? wout_cnt-1  : wout_cnt-1 ;
		mul20_1 = 20'h06D43;
		mul20_2 = (!padding[3])? pixel_data_ff : 0 ;
	end
	4 : begin
	    get_data_addr = (case1)? 0 : (case2)? 63 : (case3)? 4032 : (case4)? 4095 : (case5)? wout_cnt    :(case6)? wout_cnt    :(case7)? wout_cnt    :(case8)? wout_cnt    : wout_cnt ;
		mul20_1 = 20'h01004;
		mul20_2 = (!padding[4])? pixel_data_ff : 0 ;
	end
	5 : begin
	    get_data_addr = (case1)? 1 : (case2)? 0  : (case3)? 4033 : (case4)?    0 : (case5)? wout_cnt+1  :(case6)? wout_cnt+1  :(case7)? wout_cnt+1  :(case8)? 0           : wout_cnt+1 ;
		mul20_1 = 20'hF8F71;
		mul20_2 = (!padding[5])? pixel_data_ff : 0 ;	
	end
	6 :begin
	    get_data_addr = (case1)? 0 : (case2)? 126: (case3)? 0    : (case4)?    0 : (case5)? wout_cnt+63 :(case6)? 0           :(case7)? 0           :(case8)? wout_cnt+63 : wout_cnt+63 ;
		mul20_1 = 20'hF6E54;	
		mul20_2 = (!padding[6])? pixel_data_ff : 0 ;			
	end
	7 : begin
	    get_data_addr = (case1)? 64 : (case2)? 127:(case3)? 0    : (case4)?    0 : (case5)? wout_cnt+64 :(case6)? 0           :(case7)? wout_cnt+64 :(case8)? wout_cnt+64 : wout_cnt+64 ;
		mul20_1 = 20'hFA6D7;
		mul20_2 = (!padding[7])? pixel_data_ff : 0 ;				
	end
	8 : begin
	    get_data_addr = (case1)? 65 : (case2)? 0  : (case3)? 0   : (case4)?    0 : (case5)? wout_cnt+65 :(case6)? 0           :(case7)? wout_cnt+65 :(case8)? 0           : wout_cnt+65 ;
		mul20_1 = 20'hFC834;	
		mul20_2 = (!padding[8])? pixel_data_ff : 0 ;		
	end
	9 : begin
	    get_data_addr = (case1)? 0  : (case2)? 0  : (case3)?3968 : (case4)?    0 : (case5)? 0           :(case6)? wout_cnt-64 :(case7)? wout_cnt-64 :(case8)? 0           : wout_cnt-64 ;
		mul20_1 = 20'hFAC19;
		mul20_2 = (!padding[9])? pixel_data_ff : 0 ;	
	end
	default : begin
		get_data_addr = 0 ;
		mul20_1 = 0 ;
		mul20_2 = 0 ;
	end
	endcase
end
always @(*) begin
	mul40 = mul20_1 * mul20_2 ;
	sumup_w = sumup_r + { {3{mul40[39]}} , mul40 } ;
	temp = (state_r==9)? sumup_w + {7'd0,20'h01310,16'd0} : sumup_w ;
	temp2 = (temp[15]==1 && (state_r==9))? temp + {26'd0,1'b1,16'd0} : temp ;
	layer0_ans = (temp2[42]==1)? 0 : temp2[35:16] ; 
end
always @(*) begin
	case(state_r)
	10 : maxpool_addr_w = maxpool_addr_r + 1 ;
	11 : maxpool_addr_w = maxpool_addr_r + 63 ;
	12 : maxpool_addr_w = maxpool_addr_r + 1 ;
	13 : maxpool_addr_w = (maxpool_addr_r[6:0]==127)? maxpool_addr_r + 1 : maxpool_addr_r - 63 ;
	14 : maxpool_addr_w = maxpool_addr_r ;
	default : maxpool_addr_w = 0  ; 
	endcase
end
always @(*) begin
	case(state_r)
	10 : maxvalue_w = 20'hfffff ;
	11 : maxvalue_w = ($signed(maxvalue_r) > $signed(layer0_data))? maxvalue_r : layer0_data ;
	12 : maxvalue_w = ($signed(maxvalue_r) > $signed(layer0_data))? maxvalue_r : layer0_data ;
	13 : maxvalue_w = ($signed(maxvalue_r) > $signed(layer0_data))? maxvalue_r : layer0_data ;
	14 : maxvalue_w = ($signed(maxvalue_r) > $signed(layer0_data))? maxvalue_r : layer0_data ;
	default : maxvalue_w = 20'hfffff  ; 
	endcase
end


always @(posedge clk or posedge reset) begin
    if(reset) maxpool_addr_r <= 0 ;
	else maxpool_addr_r <= maxpool_addr_w ;
end
always @(posedge clk or posedge reset) begin
    if(reset) maxvalue_r <= 20'hfffff;
	else maxvalue_r <= (maxpool_counter==0 && (state_r==10 || state_r==1))? 20'hfffff : maxvalue_w ;
end
always @(posedge clk or posedge reset) begin
    if(reset) maxpool_counter <= 0 ;
	else maxpool_counter <= (state_r==14)? maxpool_counter + 1 : maxpool_counter ;
end



endmodule









