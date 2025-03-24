module huffman # (
    parameter DATA_SIZE   = 8,
    parameter ADDR_SIZE   = 10
)
(
    clk,
    reset, 
    sram_a, 
    sram_d, 
    sram_wen, 
    sram_q, 
    finish
);

    input                   clk;
    input                   reset;
    input   [DATA_SIZE-1:0] sram_q;
    output  [ADDR_SIZE-1:0] sram_a;
    output  [DATA_SIZE-1:0] sram_d;
    output                  sram_wen;
    output                  finish;

parameter S_idle =  4'd0 ;
parameter S_sort12 =  4'd1 ;
parameter S_sort23 =  4'd2 ;
parameter S_sort21 =  4'd3 ;
parameter S_merge =  4'd4 ;

parameter S_Queue1 =  4'd5 ;
parameter S_Queue2 =  4'd6 ;
parameter S_Queue3 =  4'd7 ;
parameter S_Queue4 =  4'd8 ;
parameter S_cal    =  4'd9 ;
parameter S_finish =  4'd10 ;

integer i;
integer j;


reg [7:0]count_1r, count_1w;
reg [7:0]count_2r, count_2w;
reg [7:0]count_3r, count_3w;
reg [7:0]count_4r, count_4w;
reg [7:0]count_5r, count_5w;
reg [7:0]count_6r, count_6w;

reg [2:0]index_r[0:5];
reg [2:0]index_w[0:5];

reg [2:0]final_index[1:6];
reg [7:0]final_count[1:6]; 
reg [2:0]final_index_w[1:6];
reg [7:0]final_count_w[1:6]; 

reg [3:0]state_r, state_w ;

reg [7:0] sram_value ;

reg [2:0] merge_counter;
reg [2:0] build_counter;
reg [2:0] split_counter;
reg [2:0] out_counter;

reg [7:0] accum_r, accum_w ;
reg z_node ;


// read pattern
reg read_en_r, read_en_w; 
reg [9:0]read_addr_r, read_addr_w; 
reg [12:0] global_counter; 
reg stop_reading;
reg start_calculate;


reg [7:0] trace_value_r, trace_value_w ;
reg [7:0] trace_mask_r, trace_mask_w ;
reg [7:0] huff_code_r, huff_code_w ;
reg [7:0] output_code[1:6] ;
reg [7:0] output_mask[1:6] ;
reg [7:0]output_to_sram ;
reg [7:0]get_count ;
reg [7:0]get_hc ;
reg [7:0]get_mask ;
reg [7:0]get_addr ;
reg [7:0]get_addr_r ;

// new Q
reg [7:0] generate_group1_w , generate_group1_r ;
reg [7:0] generate_group2_w , generate_group2_r ; 
reg [7:0] compare_list[0:2] ; 
reg [7:0] record_r, record_w ; 

reg [7:0] mask_r[1:6] ; 
reg [7:0] mask_w[1:6] ; 
reg [4:0] q_counter ;

reg [7:0]hc6_r , hc6_w ;
reg [7:0]hc5_r , hc5_w ;
reg [7:0]hc4_r , hc4_w ;
reg [7:0]hc3_r , hc3_w ;
reg [7:0]hc2_r , hc2_w ;
reg [7:0]hc1_r , hc1_w ;

reg [6:0]list1_r, list1_w ;
reg [6:0]list2_r, list2_w ;
reg [3:0]logicc_r, logicc_w ;

reg [7:0]mask1_r , mask1_w ;
reg [7:0]mask2_r , mask2_w ;
reg [7:0]mask3_r , mask3_w ;
reg [7:0]mask4_r , mask4_w ;
reg [7:0]mask5_r , mask5_w ;
reg [7:0]mask6_r , mask6_w ;
wire read_allow ;
reg [7:0] height , height_r ;

wire [2:0] pick_index;
wire [7:0] pick_count;
wire bucket1_empty;
wire bucket2_empty;

wire sorting ;
// assignments
assign sram_a   = (state_r==S_idle)?(read_addr_r):(get_addr_r) ;
assign sram_d = output_to_sram ;
assign sram_wen = read_en_r  ; 
assign finish = (state_r==S_finish) ;

assign read_allow = (global_counter[12:0] > 12'h003)  ;

assign  bucket1_empty = (count_1r==0) ;
assign  bucket2_empty = (count_4r==0) ;
assign pick_index = 
        (bucket1_empty)?  index_r[3] :
        (bucket2_empty)?  index_r[0] :
        (count_1r>count_4r)? index_r[0] :  ( ( (count_1r==count_4r) & (index_r[0]<index_r[3]) )? index_r[0] : index_r[3] ) ;
// ( ( (count_1r==count_4r) & (index_r[0]<index_r[3]) )? index_r[0] : index_r[3] )
assign pick_count = 
        (bucket1_empty)? count_4r :
        (bucket2_empty)? count_1r :
        (count_1r>count_4r)? count_1r :  ( ( (count_1r==count_4r) & (index_r[0]<index_r[3]) )? count_1r : count_4r );

assign sorting = (state_r==S_sort12) || (state_r==S_sort21) || (state_r==S_sort23) || (state_r==S_merge) ;



// read input pattern
always @(*) begin
    read_en_w = ( (global_counter>=12'd1) && (global_counter<=12'd103) ) ;
    read_addr_w = global_counter - 1 ;
    stop_reading = (global_counter > 12'd103) ;
    start_calculate = (global_counter > 12'd103) ;
end

// state 
always @(*) begin
    case(state_r)
        S_idle : state_w = (start_calculate)? S_sort12 : S_idle ;
        S_sort12 : state_w = S_sort23 ;
        S_sort23 : state_w = S_sort21 ;
        S_sort21 : state_w = S_merge;
        S_merge : state_w =  (merge_counter==5)? S_Queue1: S_merge;
        S_Queue1 : state_w =  S_Queue2;
        S_Queue2 : state_w =  S_Queue3 ;
        S_Queue3 : state_w = S_Queue4 ;
        S_Queue4 : state_w = S_cal ;
        S_cal : state_w = S_finish ;
        S_finish : state_w = S_finish ;
        default : state_w = S_idle ;
    endcase
end
// sorting
always @(*) begin
    case(state_r)
        S_idle : begin
            for(i=0;i<6;i=i+1) begin
                index_w[i] = index_r[i] ;
            end
                count_1w = (read_allow & read_en_r)? ((sram_value==1)?count_1r+1:count_1r) : count_1r ;
                count_2w = (read_allow & read_en_r)? ((sram_value==2)?count_2r+1:count_2r) : count_2r ;
                count_3w = (read_allow & read_en_r)? ((sram_value==3)?count_3r+1:count_3r) : count_3r ;
                count_4w = (read_allow & read_en_r)? ((sram_value==4)?count_4r+1:count_4r) : count_4r ;
                count_5w = (read_allow & read_en_r)? ((sram_value==5)?count_5r+1:count_5r) : count_5r ;
                count_6w = (read_allow & read_en_r)? ((sram_value==6)?count_6r+1:count_6r) : count_6r ;      
        end
        S_sort12: begin
            index_w[0] = (count_1r>count_2r)? index_r[0] : index_r[1] ;
            index_w[1] = (count_1r>count_2r)? index_r[1] : index_r[0] ;
            index_w[3] = (count_4r>count_5r)? index_r[3] : index_r[4] ;
            index_w[4] = (count_4r>count_5r)? index_r[4] : index_r[3] ;
            index_w[2] = index_r[2];
            index_w[5] = index_r[5] ;
            count_1w = (count_1r>count_2r)? count_1r : count_2r ;
            count_2w = (count_1r>count_2r)? count_2r : count_1r ;
            count_4w = (count_4r>count_5r)? count_4r : count_5r ;
            count_5w = (count_4r>count_5r)? count_5r : count_4r ;
            count_3w = count_3r ;
            count_6w = count_6r ;
        end
        S_sort23: begin
            index_w[1] = (count_2r>count_3r)? index_r[1] : index_r[2] ;
            index_w[2] = (count_2r>count_3r)? index_r[2] : index_r[1] ;
            index_w[4] = (count_5r>count_6r)? index_r[4] : index_r[5] ;
            index_w[5] = (count_5r>count_6r)? index_r[5] : index_r[4] ;
            index_w[0] = index_r[0];
            index_w[3] = index_r[3] ;
            count_2w = (count_2r>count_3r)? count_2r : count_3r ;
            count_3w = (count_2r>count_3r)? count_3r : count_2r ;
            count_5w = (count_5r>count_6r)? count_5r : count_6r ;
            count_6w = (count_5r>count_6r)? count_6r : count_5r ;
            count_1w = count_1r ;
            count_4w = count_4r ;
        end
        S_sort21: begin
            index_w[0] = (count_1r>count_2r)? index_r[0] : index_r[1] ;
            index_w[1] = (count_1r>count_2r)? index_r[1] : index_r[0] ;
            index_w[3] = (count_4r>count_5r)? index_r[3] : index_r[4] ;
            index_w[4] = (count_4r>count_5r)? index_r[4] : index_r[3] ;
            index_w[2] = index_r[2];
            index_w[5] = index_r[5] ;
            count_1w = (count_1r>count_2r)? count_1r : count_2r ;
            count_2w = (count_1r>count_2r)? count_2r : count_1r ;
            count_4w = (count_4r>count_5r)? count_4r : count_5r ;
            count_5w = (count_4r>count_5r)? count_5r : count_4r ;
            count_3w = count_3r ;
            count_6w = count_6r ;
        end
        S_merge: begin
            index_w[0] = (count_1r>count_4r)? index_r[1] : ((count_1r==count_4r) && (index_r[0]<index_r[3]))? index_r[1] : index_r[0] ;
            index_w[1] = (count_1r>count_4r)? index_r[2] : ((count_1r==count_4r) && (index_r[0]<index_r[3]))? index_r[2] : index_r[1] ;
            index_w[2] = (count_1r>count_4r)? 0          : ((count_1r==count_4r) && (index_r[0]<index_r[3]))? 0          : index_r[2] ;
            index_w[3] = (count_1r>count_4r)? index_r[3] : ((count_1r==count_4r) && (index_r[0]<index_r[3]))? index_r[3] : index_r[4] ;
            index_w[4] = (count_1r>count_4r)? index_r[4] : ((count_1r==count_4r) && (index_r[0]<index_r[3]))? index_r[4] : index_r[5] ;
            index_w[5] = (count_1r>count_4r)? index_r[5] : ((count_1r==count_4r) && (index_r[0]<index_r[3]))? index_r[5] : 0 ;
            count_1w = (count_1r>count_4r)? count_2r : ((count_1r==count_4r) && (index_r[0]<index_r[3]))? count_2r:count_1r ;
            count_2w = (count_1r>count_4r)? count_3r : ((count_1r==count_4r) && (index_r[0]<index_r[3]))? count_3r:count_2r ;
            count_3w = (count_1r>count_4r)? 0        : ((count_1r==count_4r) && (index_r[0]<index_r[3]))? 0       :count_3r ;
            count_4w = (count_1r>count_4r)? count_4r : ((count_1r==count_4r) && (index_r[0]<index_r[3]))? count_4r:count_5r ;
            count_5w = (count_1r>count_4r)? count_5r : ((count_1r==count_4r) && (index_r[0]<index_r[3]))? count_5r:count_6r ;
            count_6w = (count_1r>count_4r)? count_6r : ((count_1r==count_4r) && (index_r[0]<index_r[3]))? count_6r:0 ;
        end
        default : begin
            for(i=0;i<6;i=i+1) begin
                index_w[i] = index_r[i] ;
            end
            count_1w = 0;
            count_2w = 0;
            count_3w = 0;
            count_4w = 0;
            count_5w = 0;
            count_6w = 0;
        end
    endcase
end

always @(*) begin
    case(state_r)
        S_merge: begin
            for(i=1;i<6;i=i+1) begin
                final_index_w[i] = final_index[i+1] ;
            end
            final_index_w[6] = pick_index ;
            for(i=1;i<6;i=i+1) begin
                final_count_w[i] = final_count[i+1] ;
            end
            final_count_w[6] = pick_count ;
        end

        default : begin
            for(i=1;i<6;i=i+1) begin
                final_index_w[i] = final_index[i] ;
            end
            final_index_w[6] = final_index[6];
            for(i=1;i<6;i=i+1) begin
                final_count_w[i] = final_count[i] ;
            end
            final_count_w[6] = final_count[6] ;
        end
    endcase
end


// global clock 
always @(posedge clk or posedge reset) begin
    if(reset) sram_value <= 0 ;
    else      sram_value <= sram_q ;
end
// read sram value
always @(posedge clk or posedge reset) begin
    if(reset) global_counter <= 0 ;
    else      global_counter <= global_counter + 1 ;
end

always @(posedge clk or posedge reset) begin
    if(reset) begin
        read_en_r <= 1 ;
        read_addr_r <= 10'd100 ;
    end
    else  begin
        read_en_r <= read_en_w ;
        read_addr_r <= read_addr_w ;      
    end
end

always @(posedge clk or posedge reset) begin
    if(reset) begin
        count_1r <= 0;
        count_2r <= 0;
        count_3r <= 0;
        count_4r <= 0;
        count_5r <= 0;
        count_6r <= 0;
    end
    else  begin
        count_1r <= (stop_reading&!sorting)? count_1r :count_1w ;
        count_2r <= (stop_reading&!sorting)? count_2r :count_2w ;
        count_3r <= (stop_reading&!sorting)? count_3r :count_3w ;
        count_4r <= (stop_reading&!sorting)? count_4r :count_4w ;
        count_5r <= (stop_reading&!sorting)? count_5r :count_5w ;
        count_6r <= (stop_reading&!sorting)? count_6r :count_6w ;  
    end
end
always @(posedge clk or posedge reset) begin
    if(reset) state_r <= S_idle ;
    else  state_r <= state_w ;
end
always @(posedge clk or posedge reset) begin
    if(reset) begin
        for(i=0;i<6;i=i+1) begin
            index_r[i] <= i ;
        end
    end
    else  begin
        for(i=0;i<6;i=i+1) begin
            index_r[i] <= index_w[i] ;
        end
    end
end


always @(posedge clk or posedge reset) begin
    if(reset) begin
        for(i=1;i<7;i=i+1) begin
            final_index[i] <= 0 ;
        end
        for(i=1;i<7;i=i+1) begin
            final_count[i] <= 0 ;
        end
    end
    else  begin
        for(i=1;i<7;i=i+1) begin
            final_index[i] <= final_index_w[i] ;
        end
        for(i=1;i<7;i=i+1) begin
            final_count[i] <= final_count_w[i] ;
        end
    end
end

// counter for each state calculatoin
always @(posedge clk or posedge reset) begin
    if(reset) merge_counter <= 0 ;
    else  merge_counter <= (merge_counter==5)? 0 : (state_r==S_merge)? merge_counter + 1 : merge_counter ;
end


// start the huffman encoding using Queue


always @(*) begin
    case(state_r)
    S_Queue1 : begin
        compare_list[0] =  final_count[6] + final_count[5];
        compare_list[1] =  final_count[4];
        compare_list[2] =  final_count[3];

        generate_group1_w = (compare_list[0]>compare_list[1] && compare_list[0]>compare_list[2])? compare_list[0]                 : compare_list[0] ;
        generate_group2_w = (compare_list[0]>compare_list[1] && compare_list[0]>compare_list[2])? compare_list[1]+compare_list[2] : compare_list[1] ;

        list1_w = (compare_list[0]>compare_list[1] && compare_list[0]>compare_list[2])? 7'b1100000 : 7'b1100000 ;
        list2_w = (compare_list[0]>compare_list[1] && compare_list[0]>compare_list[2])? 7'b0011000 : 7'b0010000 ;

        logicc_w =  (compare_list[0]>compare_list[1] && compare_list[0]>compare_list[2])? 3 : (compare_list[1]>=compare_list[0])? 2 : 1 ;

    end
    S_Queue2 : begin // finish 6,5,4,3
        compare_list[0] =  generate_group1_r ;
        compare_list[1] =  generate_group2_r ;
        compare_list[2] =  final_count[3] ;

        generate_group1_w = (logicc_r==3)? generate_group1_r : generate_group1_r + generate_group2_r  ;
        generate_group2_w = (logicc_r==3)? generate_group2_r : final_count[3] ;

        list1_w = (logicc_r==3)? list1_r : 7'b1110000 ;
        list2_w = (logicc_r==3)? list2_r : 7'b0001000 ;

        logicc_w =  (logicc_r==3)? 3 : 1 ;
    end
    S_Queue3 : begin // finish 6,5,4,3,2
        compare_list[0] =  generate_group1_r ; 
        compare_list[1] =  generate_group2_r ;
        compare_list[2] =  final_count[2] ;

        generate_group1_w = ( (final_count[2]>generate_group2_r)?  generate_group1_r + generate_group2_r : final_count[2] + generate_group1_r )  ;
        generate_group2_w = ( (final_count[2]>generate_group2_r)?  final_count[2]                        : generate_group2_r ) ;

        list1_w =  (final_count[2]>generate_group2_r)? (list1_r | list2_r) :  ( {7'b0000100}|(list1_r) ) ;
        list2_w =  (final_count[2]>generate_group2_r)? {7'b0000100}        :  (list2_r) ;

        logicc_w =  (logicc_r==3)? 3 : 1 ;

    end
    S_Queue4 : begin // finish 6,5,4,3,2,1
        compare_list[0] =  generate_group1_r ; 
        compare_list[1] =  generate_group2_r ;
        compare_list[2] =  final_count[1] ;

        generate_group1_w = (final_count[1]>generate_group1_r && final_count[1]>generate_group2_r)?  generate_group1_r + generate_group2_r
        : (generate_group1_r > generate_group2_r)? final_count[1] + generate_group2_r : final_count[1] + generate_group1_r  ;
        generate_group2_w = (final_count[1]>generate_group1_r && final_count[1]>generate_group2_r)?  final_count[1]
        : (generate_group1_r > generate_group2_r)? generate_group1_r : generate_group2_r  ;

        list1_w = (final_count[1]>generate_group1_r && final_count[1]>generate_group2_r)?  (list1_r | list2_r)
        : (generate_group1_r > generate_group2_r)? ({7'b0000010} | list2_r) : ({7'b0000010} | list1_r)  ;
        list2_w = (final_count[1]>generate_group1_r && final_count[1]>generate_group2_r)?  {7'b0000010}
        : (generate_group1_r > generate_group2_r)? list1_r : list2_r ;

        logicc_w =  (logicc_r==3)? 3 : 1 ;

    end
    S_cal : begin // finish 6,5,4,3,2,1
        compare_list[0] =  0 ;
        compare_list[1] =  0 ;
        compare_list[2] =  0 ;
        generate_group1_w = 0 ;
        generate_group2_w = 0 ;
        list1_w = list1_r ;
        list2_w = list2_r;

        logicc_w =  logicc_r ;
    end
    default : begin
        compare_list[0] =  0 ;
        compare_list[1] =  0 ;
        compare_list[2] =  0 ;
        generate_group1_w = 0 ;
        generate_group2_w = 0 ;
        list1_w = list1_r ;
        list2_w = list2_r;

        logicc_w =  logicc_r ;
    end
    endcase
end

always @(*) begin
    case(state_r)
    S_Queue1 : begin
        hc1_w = 8'd0 ;
        hc2_w = 8'd0 ;
        hc3_w = 8'd0 ;
        hc4_w = 8'd0 ;
        hc5_w = 8'd0 ;
        hc6_w = 8'd1 ; // finish 6,5
        height = 8'd1 ;

        mask1_w = 0 ;
        mask2_w = 0 ;
        mask3_w = 0 ;
        mask4_w = 0 ;
        mask5_w = 1 ;
        mask6_w = 1 ;
    end
    S_Queue2 : begin 
        hc1_w = 8'd0 ;
        hc2_w = 8'd0 ;
        hc3_w = 0 ;
        hc4_w = (logicc_r==3)? height : (logicc_r==2)? {8'd0} : {8'd1} ;
        hc5_w = (logicc_r==3)? hc5_r    : (logicc_r==2)? {hc5_r|height} : {hc5_r} ;
        hc6_w = (logicc_r==3)? hc6_r    : (logicc_r==2)? {hc6_r|height} : {hc6_r} ; // finish 6,5,4
        height = (logicc_r==3)? 8'd1:8'd2 ;

        mask1_w = 0 ;
        mask2_w = 0 ;
        mask3_w = (generate_group1_r<generate_group2_r)? ((list1_r[3]==1)?{(hc3_r<<1)+1}:hc3_r) : ((list2_r[3]==1)?{(hc3_r<<1)+1}:hc3_r) ;
        mask4_w = (generate_group1_r<generate_group2_r)? ((list1_r[4]==1)?{(hc4_r<<1)+1}:hc4_r) : ((list2_r[4]==1)?{(hc3_r<<1)+1}:hc4_r) ;
        mask5_w = (logicc_r==3) ? 1 : 3 ;
        mask6_w = (logicc_r==3) ? 1 : 3 ; // 6,5,4 mask
    end
    S_Queue3 : begin // finish 6,5,4,3
        hc1_w =  0 ;
        hc2_w =  0 ;
        hc3_w =  (logicc_r==3)? 8'd0 : (generate_group1_r==generate_group2_r)? 0 : (generate_group1_r<generate_group2_r)? ((list1_r[3]==1)?{1}:hc3_r) : ((list2_r[3]==1)?{1}:hc3_r)  ;
        hc4_w =  (generate_group1_r==generate_group2_r)? {hc4_r|(height>>1)} :(generate_group1_r<generate_group2_r)? ((list1_r[4]==1)?{hc4_r|(height>>1)}:hc4_r) : ((list2_r[4]==1)?{hc4_r|(height>>1)}:hc4_r)  ;
        hc5_w =  (generate_group1_r==generate_group2_r)? {hc5_r|height} :(generate_group1_r<generate_group2_r)? ((list1_r[5]==1)?{hc5_r|height}:hc5_r) : ((list2_r[5]==1)?{hc5_r|height}:hc5_r)  ;
        hc6_w =  (generate_group1_r==generate_group2_r)? {hc6_r|height} :(generate_group1_r<generate_group2_r)? ((list1_r[6]==1)?{hc6_r|height}:hc6_r) : ((list2_r[6]==1)?{hc6_r|height}:hc6_r)  ;
        height = (logicc_r==3)? 8'd2 : 8'd4 ;

        mask1_w = 0 ;
        mask2_w = 0 ;
        mask3_w = (mask4_r<<1)  + 1;
        mask4_w = (mask4_r<<1)  + 1 ;
        mask5_w = (mask5_r<<1)  + 1 ;
        mask6_w = (mask6_r<<1)  + 1 ; //6,5,4,3 mask

    end
    S_Queue4 : begin // finish 6,5,4,3,2,1
        hc1_w =  0 ;
        hc2_w =  (generate_group1_r==generate_group2_r)? 0  : (generate_group1_r<generate_group2_r)? ((list1_r[2]==1)?{1}:hc2_r) : ((list2_r[2]==1)?{1}:hc2_r)  ;
        hc3_w =  (generate_group1_r==generate_group2_r)? {hc3_r|(height>>2)} : (generate_group1_r<generate_group2_r)? ((list1_r[3]==1)?{hc3_r|(height>>2)}:hc3_r) : ((list2_r[3]==1)?{hc3_r|(height>>2)}:hc3_r)  ;
        hc4_w =  (generate_group1_r==generate_group2_r)? {hc4_r|(height>>1)} : (generate_group1_r<generate_group2_r)? ((list1_r[4]==1)?{hc4_r|(height>>1)}:hc4_r) : ((list2_r[4]==1)?{hc4_r|(height>>1)}:hc4_r)  ;
        hc5_w =  (generate_group1_r==generate_group2_r)? {hc5_r|height} : (generate_group1_r<generate_group2_r)? ((list1_r[5]==1)?{hc5_r|height}:hc5_r) : ((list2_r[5]==1)?{hc5_r|height}:hc5_r)  ;
        hc6_w =  (generate_group1_r==generate_group2_r)? {hc6_r|height} : (generate_group1_r<generate_group2_r)? ((list1_r[6]==1)?{hc6_r|height}:hc6_r) : ((list2_r[6]==1)?{hc6_r|height}:hc6_r)  ;
        height = height_r << 1 ;

        mask1_w = 0 ;
        mask2_w = 1 ;
        mask3_w = (mask3_r<<1)  + 1 ;
        mask4_w = (mask4_r<<1)  + 1 ;
        mask5_w = (mask5_r<<1)  + 1 ;
        mask6_w = (mask6_r<<1)  + 1 ; 
    end
    S_cal : begin // output
        hc1_w =  (generate_group1_r<generate_group2_r)? ((list1_r[1]==1)?{1}:hc1_r) : ((list2_r[1]==1)?{1}:hc1_r)  ;
        hc2_w =  (generate_group1_r<generate_group2_r)? ((list1_r[2]==1)?{hc2_r|(height>>3)}:hc2_r) : ((list2_r[2]==1)?{hc2_r|(height>>3)}:hc2_r)  ;
        hc3_w =  (generate_group1_r<generate_group2_r)? ((list1_r[3]==1)?{hc3_r|(height>>2)}:hc3_r) : ((list2_r[3]==1)?{hc3_r|(height>>2)}:hc3_r)  ;
        hc4_w =  (generate_group1_r<generate_group2_r)? ((list1_r[4]==1)?{hc4_r|(height>>1)}:hc4_r) : ((list2_r[4]==1)?{hc4_r|(height>>1)}:hc4_r)  ;
        hc5_w =  (generate_group1_r<generate_group2_r)? ((list1_r[5]==1)?{hc5_r|height}:hc5_r) : ((list2_r[5]==1)?{hc5_r|height}:hc5_r)  ;
        hc6_w =  (generate_group1_r<generate_group2_r)? ((list1_r[6]==1)?{hc6_r|height}:hc6_r) : ((list2_r[6]==1)?{hc6_r|height}:hc6_r)  ;
        height = height_r << 1 ;

        mask1_w = ( (list1_r[5] & list2_r[6] ) || (list1_r[6] & list2_r[5] ) )? 3 : 1 ;
        mask2_w = ( (list1_r[5] & list2_r[6] ) || (list1_r[6] & list2_r[5] ) )? 3 : (mask2_r<<1)  + 1 ;
        mask3_w = (mask3_r<<1)  + 1 ;
        mask4_w = (mask4_r<<1)  + 1 ;
        mask5_w = (mask5_r<<1)  + 1 ;
        mask6_w = (mask6_r<<1)  + 1 ; 
    end
    default : begin
        hc1_w = 0 ;
        hc2_w = 0 ;
        hc3_w = 0 ;
        hc4_w = 0 ;
        hc5_w = 0 ;
        hc6_w = 0 ;

        height = 0 ;

        mask1_w = mask1_r ; 
        mask2_w = mask2_r ; 
        mask3_w = mask3_r ; 
        mask4_w = mask4_r ; 
        mask5_w = mask5_r ; 
        mask6_w = mask6_r ; 
    end
    endcase
end



always @(posedge clk or posedge reset) begin
    if(reset) begin 
        generate_group1_r <= 0 ;
        generate_group2_r <= 0 ;
        list1_r <= 0 ;
        list2_r <= 0 ;
        logicc_r <= 0 ;
        hc1_r <= 0 ;
        hc2_r <= 0 ;
        hc3_r <= 0 ;
        hc4_r <= 0 ;
        hc5_r <= 0 ;
        hc6_r <= 0 ;
        height_r <= 0 ;

        mask1_r <= 0 ;
        mask2_r <= 0 ;
        mask3_r <= 0 ;
        mask4_r <= 0 ;
        mask5_r <= 0 ;
        mask6_r <= 0 ;
    end
    else  begin
        generate_group1_r <= generate_group1_w ;
        generate_group2_r <= generate_group2_w ;
        list1_r <= list1_w ;
        list2_r <= list2_w ;
        logicc_r <= logicc_w ;
        hc1_r <= hc1_w ;
        hc2_r <= hc2_w ;
        hc3_r <= hc3_w ;
        hc4_r <= hc4_w ;
        hc5_r <= hc5_w ;
        hc6_r <= hc6_w ;
        height_r <= height ;

        mask1_r <= mask1_w ;
        mask2_r <= mask2_w ;
        mask3_r <= mask3_w ;
        mask4_r <= mask4_w ;
        mask5_r <= mask5_w ;
        mask6_r <= mask6_w ;
    end
end






endmodule

