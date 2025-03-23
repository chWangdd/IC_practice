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
parameter S_build =  4'd5 ;
parameter S_split =  4'd6 ;
parameter S_finish =  4'd7 ;
parameter S_cnt_out =  4'd8 ;
parameter S_hc_out =  4'd9 ;
parameter S_m_out =  4'd10 ;

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

// build tree
reg [5:0]encode_r ; 

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
    read_en_w = ( (global_counter>=12'd1) && (global_counter<=12'd103) ) || !( (state_r==S_cnt_out) || (state_r==S_m_out) || (state_r==S_hc_out) ) ;
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
        S_merge : state_w =  (merge_counter==5)? S_build: S_merge;
        S_build : state_w =  (build_counter==5)? S_split: S_build;
        S_split : state_w =  (split_counter==6)? S_cnt_out: S_split ;
        S_cnt_out : state_w = (out_counter==5)? S_hc_out : S_cnt_out ;
        S_hc_out : state_w = (out_counter==5)? S_m_out : S_hc_out ;
        S_m_out : state_w = (out_counter==5)? S_finish : S_m_out ;
        S_finish: state_w =  S_finish ;
        default : state_w = S_idle ;
    endcase
end
// sorting
always @(*) begin
    case(state_r)
        S_idle : begin
                for(i=0;i<6;i+=1) begin
                    index_w[i] <= i+1 ;
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
            for(i=0;i<6;i+=1) begin
                index_w[i] <= index_r[i] ;
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
            for(i=1;i<6;i+=1) begin
                final_index_w[i] = final_index[i+1] ;
            end
            final_index_w[6] = pick_index ;
            for(i=1;i<6;i+=1) begin
                final_count_w[i] = final_count[i+1] ;
            end
            final_count_w[6] = pick_count ;
        end
        S_build : begin
            for(i=2;i<7;i+=1) begin
                final_index_w[i] = final_index[i-1] ;
            end
            final_index_w[1] = final_index[6];
            for(i=2;i<7;i+=1) begin
                final_count_w[i] = final_count[i-1] ;
            end
            final_count_w[1] = final_count[6] ;
        end
        default : begin
            for(i=1;i<6;i+=1) begin
                final_index_w[i] = final_index[i] ;
            end
            final_index_w[6] = final_index[6];
            for(i=1;i<6;i+=1) begin
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
        for(i=0;i<6;i+=1) begin
            index_r[i] <= i ;
        end
    end
    else  begin
        for(i=0;i<6;i+=1) begin
            index_r[i] <= index_w[i] ;
        end
    end
end


always @(posedge clk or posedge reset) begin
    if(reset) begin
        for(i=1;i<7;i+=1) begin
            final_index[i] <= 0 ;
        end
        for(i=1;i<7;i+=1) begin
            final_count[i] <= 0 ;
        end
    end
    else  begin
        for(i=1;i<7;i+=1) begin
            final_index[i] <= final_index_w[i] ;
        end
        for(i=1;i<7;i+=1) begin
            final_count[i] <= final_count_w[i] ;
        end
    end
end

// counter for each state calculatoin
always @(posedge clk or posedge reset) begin
    if(reset) merge_counter <= 0 ;
    else  merge_counter <= (merge_counter==5)? 0 : (state_r==S_merge)? merge_counter + 1 : merge_counter ;
end
always @(posedge clk or posedge reset) begin
    if(reset) build_counter <= 0 ;
    else  build_counter <= (build_counter==5)? 0 : (state_r==S_build)? build_counter + 1 : build_counter ;
end
always @(posedge clk or posedge reset) begin
    if(reset) split_counter <= 0 ;
    else  split_counter <= (split_counter==6)? 0 : (state_r==S_split)? split_counter + 1 : split_counter ;
end
always @(posedge clk or posedge reset) begin
    if(reset) out_counter <= 0 ;
    else  out_counter <= (split_counter==5)? 0 : (state_r==S_cnt_out || state_r==S_hc_out || state_r==S_m_out)? out_counter + 1 : out_counter ;
end
// build tree by adding nodes
always @(*) begin
    z_node = ( (accum_r < final_count[6]) || (accum_r == final_count[6]) ) ? 0 : 1 ; 
end
always @(posedge clk or posedge reset) begin
    if(reset) begin
        for(i=0;i<7;i+=1) begin
            encode_r[i] <= 0 ;
        end
    end
    else  begin
        if(state_r==S_build) begin
            for(i=0;i<5;i+=1) begin
                encode_r[i] <= encode_r[i+1] ;
            end
            encode_r[5] <= z_node ;
        end
        else if(state_r==S_split) begin
            for(i=1;i<6;i+=1) begin
                encode_r[i] <= encode_r[i-1] ;
            end
            encode_r[0] <= 0 ;
        end
        else begin
            for(i=0;i<6;i+=1) begin
                encode_r[i] <= encode_r[i] ;
            end
        end
    end
end
// calculate accumulate for combination stage aka state_r == S_build
always @(*) begin
    case(state_r)
        S_build : accum_w = accum_r + final_count[6] ;
        default : accum_w = 0 ;
    endcase
end
always @(posedge clk or posedge reset) begin
    if(reset) begin
        accum_r <= 0 ;
    end
    else  begin
        accum_r <= accum_w ;
    end
end

always @( posedge clk or posedge reset) begin
    if(reset) output_to_sram<= 0 ;
    else begin
        output_to_sram <= (state_r==S_cnt_out)?get_count:(state_r==S_hc_out)?get_hc:(state_r==S_m_out)?get_mask:0;
    end
end
// 
always @(*) begin
    case(out_counter)
        3'd0 : begin
            get_count = (final_index[1]==1)? final_count[1] : (final_index[2]==1)? final_count[2] :
            (final_index[3]==1)? final_count[3] : (final_index[4]==1)? final_count[4]  : (final_index[5]==1)? final_count[5] : final_count[6];
            get_hc = output_code[1] ;
            get_mask = output_mask[1] ;
        end
        3'd1 : begin
            get_count = (final_index[1]==2)? final_count[1] : (final_index[2]==2)? final_count[2] :
            (final_index[3]==2)? final_count[3] : (final_index[4]==2)? final_count[4]  : (final_index[5]==2)? final_count[5] : final_count[6];
            get_hc = output_code[2] ;
            get_mask = output_mask[2] ;
        end
        3'd2: begin
            get_count = (final_index[1]==3)? final_count[1] : (final_index[2]==3)? final_count[2] :
            (final_index[3]==3)? final_count[3] : (final_index[4]==3)? final_count[4]  : (final_index[5]==3)? final_count[5] : final_count[6];
            get_hc = output_code[3] ;
            get_mask = output_mask[3] ;
        end
        3'd3: begin
            get_count = (final_index[1]==4)? final_count[1] : (final_index[2]==4)? final_count[2] :
            (final_index[3]==4)? final_count[3] : (final_index[4]==4)? final_count[4]  : (final_index[5]==4)? final_count[5] : final_count[6];
            get_hc = output_code[4] ;
            get_mask = output_mask[4] ;
        end
        3'd4: begin
            get_count = (final_index[1]==5)? final_count[1] : (final_index[2]==5)? final_count[2] :
            (final_index[3]==5)? final_count[3] : (final_index[4]==5)? final_count[4]  : (final_index[5]==5)? final_count[5] : final_count[6];
            get_hc = output_code[5] ;
            get_mask = output_mask[5] ;
        end
        3'd5: begin
            get_count = (final_index[1]==6)? final_count[1] : (final_index[2]==6)? final_count[2] :
            (final_index[3]==6)? final_count[3] : (final_index[4]==6)? final_count[4]  : (final_index[5]==6)? final_count[5] : final_count[6];
            get_hc = output_code[6] ;
            get_mask = output_mask[6] ; 
        end

        default : begin
            get_count = 0;
            get_hc = 0 ;
            get_mask = 0 ; 
        end
    endcase
end
// 
always @(*) begin
    case(out_counter)
        3'd0 : begin
            get_addr = (state_r==S_cnt_out)? 128 
            : (state_r==S_hc_out)? ((final_index[1]==1)?134:(final_index[1]==2)?135:(final_index[1]==3)?136:(final_index[1]==4)?137:(final_index[1]==5)?138:139)
            : ((final_index[1]==1)?140:(final_index[1]==2)?141:(final_index[1]==3)?142:(final_index[1]==4)?143:(final_index[1]==5)?144:145);
        end
        3'd1 : begin
            get_addr = (state_r==S_cnt_out)?129 
            : (state_r==S_hc_out)? (final_index[2]==1)?134:(final_index[2]==2)?135:(final_index[2]==3)?136:(final_index[2]==4)?137:(final_index[2]==5)?138:139
            : (final_index[2]==1)?140:(final_index[2]==2)?141:(final_index[2]==3)?142:(final_index[2]==4)?143:(final_index[2]==5)?144:145;
        end
        3'd2: begin
            get_addr = (state_r==S_cnt_out)?130
            : (state_r==S_hc_out)? (final_index[3]==1)?134:(final_index[3]==2)?135:(final_index[3]==3)?136:(final_index[3]==4)?137:(final_index[3]==5)?138:139
            : (final_index[3]==1)?140:(final_index[3]==2)?141:(final_index[3]==3)?142:(final_index[3]==4)?143:(final_index[3]==5)?144:145;
        end
        3'd3: begin
            get_addr = (state_r==S_cnt_out)?131
            : (state_r==S_hc_out)? (final_index[4]==1)?134:(final_index[4]==2)?135:(final_index[4]==3)?136:(final_index[4]==4)?137:(final_index[4]==5)?138:139
            : (final_index[4]==1)?140:(final_index[4]==2)?141:(final_index[4]==3)?142:(final_index[4]==4)?143:(final_index[4]==5)?144:145;
        end
        3'd4: begin
            get_addr = (state_r==S_cnt_out)?132
            : (state_r==S_hc_out)? (final_index[5]==1)?134:(final_index[5]==2)?135:(final_index[5]==3)?136:(final_index[5]==4)?137:(final_index[5]==5)?138:139
            : (final_index[5]==1)?140:(final_index[5]==2)?141:(final_index[5]==3)?142:(final_index[5]==4)?143:(final_index[5]==5)?144:145;
        end
        3'd5: begin
            get_addr = (state_r==S_cnt_out)?133
            : (state_r==S_hc_out)? (final_index[6]==1)?134:(final_index[6]==2)?135:(final_index[6]==3)?136:(final_index[6]==4)?137:(final_index[6]==5)?138:139
            : (final_index[6]==1)?140:(final_index[6]==2)?141:(final_index[6]==3)?142:(final_index[6]==4)?143:(final_index[6]==5)?144:145;
        end
        default : get_addr = 0;
    endcase
end
always @(posedge clk or posedge reset) begin
    if(reset) get_addr_r <= 8'd0 ;
    else get_addr_r <= get_addr ;
end
// mask ff
always @(posedge clk or posedge reset) begin
    if(reset) trace_mask_r <= 8'd0 ;
    else trace_mask_r <= trace_mask_w ;
end
// trace value and output result comb
always @(*) begin
    case(split_counter)
    3'd0 : begin
        trace_value_w[7:0] = ( encode_r[5] == 1 ) ? 8'h00 : 8'h01 ;
        huff_code_w[7:0]  = ( encode_r[5] == 1 ) ? 8'h01 : 8'h00 ;
        trace_mask_w = 8'h01;
    end
    3'd1 : begin
        trace_value_w[7:0] = ( encode_r[5] == 1 ) ? {6'd0,trace_value_r[0],1'b0} : {6'd0,trace_value_r[0],1'b1} ;
        huff_code_w[7:0]   = ( encode_r[5] == 1 ) ? {6'd0,trace_value_r[0],1'b1} : {6'd0,trace_value_r[0],1'b0} ;
        trace_mask_w = 8'h03;
    end
    3'd2 : begin
        trace_value_w[7:0] = ( encode_r[5] == 1 ) ? {5'd0,trace_value_r[1:0],1'b0} : {5'd0,trace_value_r[1:0],1'b1} ;
        huff_code_w[7:0]   = ( encode_r[5] == 1 ) ? {5'd0,trace_value_r[1:0],1'b1} : {5'd0,trace_value_r[1:0],1'b0} ;
        trace_mask_w = 8'h07;
    end
    3'd3 : begin
        trace_value_w[7:0] = ( encode_r[5] == 1 ) ? {4'd0,trace_value_r[2:0],1'b0} : {4'd0,trace_value_r[2:0],1'b1} ;
        huff_code_w[7:0]   = ( encode_r[5] == 1 ) ? {4'd0,trace_value_r[2:0],1'b1} : {4'd0,trace_value_r[2:0],1'b0}  ;
        trace_mask_w = 8'h0f;
    end
    3'd4 : begin
        trace_value_w[7:0] = ( encode_r[5] == 1 ) ? {3'd0,trace_value_r[3:0],1'b0} : {3'd0,trace_value_r[3:0],1'b1} ;
        huff_code_w[7:0]   = ( encode_r[5] == 1 ) ? {3'd0,trace_value_r[3:0],1'b1}  : {3'd0,trace_value_r[3:0],1'b0}  ;
        trace_mask_w = 8'h1f;
    end
    3'd5 : begin
        trace_value_w[7:0] = ( encode_r[5] == 1 ) ? {2'd0,trace_value_r[4:0],1'b0} : {2'd0,trace_value_r[4:0],1'b1} ;
        huff_code_w[7:0]   = {trace_value_r[7:1],1'b1} ;
        trace_mask_w = 8'h1f;
    end
    default : begin
        trace_value_w[7:0] = 0 ;
        huff_code_w[7:0] = 0 ;
    end
    endcase
end
// trace value and output result ff
always @(posedge clk or posedge reset) begin
    if(reset) begin
        trace_value_r <= 8'd0 ;
        huff_code_r <= 0 ;
    end
    else begin
        trace_value_r <= (state_r==S_idle)? 0 :trace_value_w ;
        huff_code_r <= huff_code_w ;
    end
end
// output huffman code
always @(posedge clk or posedge reset) begin
    if(reset) begin
        for(i=0;i<7;i+=1) begin
            output_code[i] <= 0 ;
            output_mask[i] <= 0 ;
        end
    end
    else begin
        if(state_r==S_split) begin
            for(i=1;i<6;i+=1) begin
                output_code[i] <= output_code[i+1] ;
                output_mask[i] <= output_mask[i+1]; 
            end
            output_code[6] <= huff_code_r ;
            output_mask[6] <= trace_mask_r ;
        end
        else begin
            for(i=1;i<7;i+=1) begin
                output_code[i] <= output_code[i] ;
                output_mask[i] <= output_mask[i]; 
            end
        end
    end
end
reg [7:0]debug_finalcount6 ;
reg debug_encoder5;
always @(*) begin
    debug_finalcount6 = final_count[6] ; 
    debug_encoder5 = encode_r[5] ;
end
endmodule
/*
            for(i=1;i<6;i+=1) begin
                final_index[i] <= final_index[i+1] ;
            end
            final_index[6] <= pick_index ;
            for(i=1;i<6;i+=1) begin
                final_count[i] <= final_count[i+1] ;
            end
            final_count[6] <= pick_count ;
*/