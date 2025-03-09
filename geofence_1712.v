module geofence ( clk,reset,X,Y,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output valid;
output is_inside;

parameter S_idle = 4'd00 ;
parameter S_read = 4'b01 ;
parameter S_sort3 = 4'b3 ; // 1->(2->3) , comsider 2 ways
parameter S_sort4 = 4'b4 ; // 1->2->3->(4) , compare2 , consider 3 pos
parameter S_sort5 = 4'b5 ; // 1->2->3->4->(5) , compare3, consider 4 pos
parameter S_sort6 = 4'b6 ; // 1->2->3->4->5->(6), compare4, consider 5 pos
parameter S_calculate = 4'd10 ;
parameter S_finish = 4'd15 ;
integer i ;
// registers
// input
reg signed[9:0]x[0:6]; // 6 is for target
reg signed[9:0]y[0:6]; // 6 is for target
// state
reg [3:0] state_r, state_w ;
// reading input
reg start_sending_inf, reset_ff;
reg [2:0] read_counter_r, read_counter_w ;
wire finish_reading_inf ;
assign finish_reading_inf = (read_counter_r==0) ;
// output
reg valid_ff ;
// sort3
wire signed[10:0] sort3_vectorA[0:1];
wire signed[10:0] sort3_vectorB[0:1];
wire signed[20:0] sort3_product1;
wire signed[20:0] sort3_product2;
wire sort3_switch ;
assign sort3_vectorA[0] = x[1] - x[0] ;
assign sort3_vectorB[0] = x[2] - x[0] ;
assign sort3_vectorA[1] = y[1] - y[0] ;
assign sort3_vectorB[1] = y[2] - y[0] ;
assign sort3_product1 = sort3_vectorA[0]*sort3_vectorB[1] ;
assign sort3_product2 = sort3_vectorA[1]*sort3_vectorB[0] ;
assign sort3_switch = (sort3_product1 > sort3_product2) ;// 1順時針0逆時針



// sort4
//// part1
wire signed[10:0] sort41_vectorA[0:1];
wire signed[10:0] sort41_vectorB[0:1];
wire signed[20:0] sort41_product1;
wire signed[20:0] sort41_product2;
wire sort41_switch ;
assign sort41_vectorA[0] = x[1] - x[0] ;
assign sort41_vectorB[0] = x[2] - x[0] ;
assign sort41_vectorA[1] = y[1] - y[0] ;
assign sort41_vectorB[1] = y[2] - y[0] ;
assign sort41_product1 = sort41_vectorA[0]*sort41_vectorB[1] ;
assign sort41_product2 = sort41_vectorA[1]*sort41_vectorB[0] ;
assign sort41_switch = (sort41_product1 > sort41_product2) ;
//// part2
wire signed[10:0] sort42_vectorA[0:1];
wire signed[10:0] sort42_vectorB[0:1];
wire signed[20:0] sort42_product1;
wire signed[20:0] sort42_product2;
wire sort42_switch ;
assign sort42_vectorA[0] = x[2] - x[0] ;
assign sort42_vectorB[0] = x[3] - x[0] ;
assign sort42_vectorA[1] = y[2] - y[0] ;
assign sort42_vectorB[1] = y[3] - y[0] ;
assign sort42_product1 = sort42_vectorA[0]*sort42_vectorB[1] ;
assign sort42_product2 = sort42_vectorA[1]*sort42_vectorB[0] ;
assign sort42_switch = (sort42_product1 > sort42_product2) ;
/*
wire signed[10:0] sort43_vectorA[0:1];
wire signed[10:0] sort43_vectorB[0:1];
wire signed[20:0] sort43_product1;
wire signed[20:0] sort43_product2;
wire sort43_switch ;
assign sort43_vectorA[0] = x[3] - x[0] ;
assign sort43_vectorB[0] = x[1] - x[0] ;
assign sort43_vectorA[1] = y[3] - y[0] ;
assign sort43_vectorB[1] = y[1] - y[0] ;
assign sort43_product1 = sort43_vectorA[0]*sort43_vectorB[1] ;
assign sort43_product2 = sort43_vectorA[1]*sort43_vectorB[0] ;
assign sort43_switch = (sort43_product1 > sort43_product2) ;
*/
//// decide swap sort4
wire sort4_switch ;
assign sort4_switch = !(sort41_switch & sort42_switch) ; 
// sort5
//// part4
wire signed[10:0] sort54_vectorA[0:1];
wire signed[10:0] sort54_vectorB[0:1];
wire signed[20:0] sort54_product1;
wire signed[20:0] sort54_product2;
wire sort54_switch ;
assign sort54_vectorA[0] = x[3] - x[0] ;
assign sort54_vectorB[0] = x[4] - x[0] ;
assign sort54_vectorA[1] = y[3] - y[0] ;
assign sort54_vectorB[1] = y[4] - y[0] ;
assign sort54_product1 = sort54_vectorA[0]*sort54_vectorB[1] ;
assign sort54_product2 = sort54_vectorA[1]*sort54_vectorB[0] ;
assign sort54_switch = (sort54_product1 > sort54_product2) ;
/*
wire signed[10:0] sort55_vectorA[0:1];
wire signed[10:0] sort55_vectorB[0:1];
wire signed[20:0] sort55_product1;
wire signed[20:0] sort55_product2;
wire sort55_switch ;
assign sort55_vectorA[0] = x[4] - x[0] ;
assign sort55_vectorB[0] = x[1] - x[0] ;
assign sort55_vectorA[1] = y[4] - y[0] ;
assign sort55_vectorB[1] = y[1] - y[0] ;
assign sort55_product1 = sort55_vectorA[0]*sort55_vectorB[1] ;
assign sort55_product2 = sort55_vectorA[1]*sort55_vectorB[0] ;
assign sort55_switch = (sort55_product1 > sort55_product2) ;
*/
//// decide swap sort5
wire sort5_switch ;
assign sort5_switch = !( sort41_switch & sort42_switch & sort54_switch ) ; 
//sort6
//// part6
wire signed[10:0] sort66_vectorA[0:1];
wire signed[10:0] sort66_vectorB[0:1];
wire signed[20:0] sort66_product1;
wire signed[20:0] sort66_product2;
wire sort66_switch ;
assign sort66_vectorA[0] = x[4] - x[0] ;
assign sort66_vectorB[0] = x[5] - x[0] ;
assign sort66_vectorA[1] = y[4] - y[0] ;
assign sort66_vectorB[1] = y[5] - y[0] ;
assign sort66_product1 = sort66_vectorA[0]*sort66_vectorB[1] ;
assign sort66_product2 = sort66_vectorA[1]*sort66_vectorB[0] ;
assign sort66_switch = (sort66_product1 > sort66_product2) ;
//// decide swap sort6
wire sort6_switch ;
assign sort6_switch = !( sort41_switch & sort42_switch & sort54_switch & sort66_switch ); 
//// tracking
reg [2:0]sort4_track ;
reg [2:0]sort5_track ;
reg [2:0]sort6_track ;

//////check output logic
wire inside_logic ;
reg  inside_check ;
wire [5:0]check;
reg signed[10:0] vector1_x[0:5];
reg signed[10:0] vector1_y[0:5];
reg signed[10:0] vector2_x[0:5];
reg signed[10:0] vector2_y[0:5];
assign inside_logic = (state_r== S_calculate)? ( check[0]&check[1]&check[2]&check[3]&check[4]&check[5] ) :0 ;
// output
assign valid = (state_r== S_finish) ;
assign is_inside = inside_check ;

//////////////////////////////////////// COMB
// reading input
always @(*) begin
    read_counter_w = (finish_reading_inf 0)? 7:(start_sending_inf)? 6:read_counter_r-1 ; 
end
// state
always @(*) begin
    case(state_r)
        S_idle : state_w =(start_sending_inf)? S_read : S_idle ;
        S_read : state_w =(finish_reading_inf)? S_sort3 : S_read ;
        S_sort3 : state_w = S_sort4 ;
        S_sort4 : begin
            if(sort4_switch) state_w = S_sort4 ;
            else state_w = S_sort5 ;
        end
        S_sort5 : begin
            if(sort5_switch) state_w = S_sort6 ;
            else state_w = S_sort6 ;
        end
        S_sort6 : begin
            if(sort6_switch) state_w = S_calculate ;
            else state_w = S_sort6 ;
        end
        S_calculate : begin
            state_w = S_finish ;
        end
        S_finish : begin
            state_w = (start_sending_inf)? S_read : S_idle;
        end
        default : state_w = S_idle ;
    endcase
end
always @(*) begin
    for(i=0;i<6;i=i+1) begin
        vector1_x[i] = x[i] - x[6] ;
        vector1_y[i] = y[i] - y[6] ;
    end
    for(i=0;i<5;i=i+1) begin
        vector2_x[i] = x[i+1] - x[i] ;
        vector2_y[i] = y[i+1] - y[i] ;
    end
    vector2_x[5] = x[0] - x[5] ;
    vector2_y[5] = y[0] - y[5] ;
end
always @(*) begin
    for(i=0;i<6;i=i+1) begin
        check[i] = ( (vector2_x[i]*vector1_y[i]) > (vector1_x[i]*vector2_y[i]) ) ;
    end
end
//////////////////////////////////////// SEQ
// start reading input
always @(posedge clk) begin
    start_sending_inf <= reset_ff || valid_logic ;
    reset_ff <= reset ;
end
// reading input
always @(posedge clk or posedge reset) begin
    if(reset) read_counter_r <= 3'd6 ;
    else read_counter_r <= read_counter_w ;
end

always @(posedge clk or posedge reset ) begin
    if(reset) begin
        for(i=0;i<7;i=i+1) begin
            x[i] <= 0 ;
            y[i] <= 0 ;
        end
    end
    else begin
        // read
        if(state_r==S_read) begin
            for(i=0;i<7;i=i+1) begin
                if(i==countdown_r) begin
                    x[i] <= X ;
                    y[i] <= Y ; 
                end
                else begin
                    x[i] <= x[i] ;
                    y[i] <= y[i] ;
                end
            end
        end
        // sort3
        else if(state_r==S_sort3) begin
            for(i=3;i<7;i=i+1) begin
                x[i] <= x[i] ;
                y[i] <= y[i] ;
            end
            x[0] <= x[0] ;
            y[0] <= y[0] ;
            x[1] <= (sort3_switch)? x[1] : x[2] ;
            y[1] <= (sort3_switch)? y[1] : y[2] ;
            x[2] <= (sort3_switch)? x[2] : x[1] ;
            y[2] <= (sort3_switch)? y[2] : y[1] ;
        end
        // sort4
        else if(state_r==S_sort4) begin
            if(sort4_switch) begin
                if(sort4_track==3) begin
                    x[0] <= x[0] ;
                    y[0] <= y[0] ;
                    x[1] <= x[1] ;
                    y[1] <= y[1] ;
                    x[2] <= x[3] ;
                    y[2] <= y[3] ;
                    x[3] <= x[2] ;
                    y[3] <= y[2] ;
                    for(i=4;i<7;i=i+1) begin
                        x[i] <= x[i] ;
                        y[i] <= y[i] ;
                    end
                end
                else if(sort4_track==2) begin
                    x[0] <= x[0] ;
                    y[0] <= y[0] ;
                    x[1] <= x[2] ;
                    y[1] <= y[2] ;
                    x[2] <= x[1] ;
                    y[2] <= y[1] ;
                    for(i=3;i<7;i=i+1) begin
                        x[i] <= x[i] ;
                        y[i] <= y[i] ;
                    end
                end
                else begin
                    for(i=0;i<7;i=i+1) begin
                        x[i] <= x[i] ;
                        y[i] <= y[i] ;
                    end
                end
            end

            else begin
                for(i=0;i<7;i=i+1) begin
                    x[i] <= x[i] ;
                    y[i] <= y[i] ;
                end
            end
        end
        // sort5
        else if(state_r==S_sort5) begin
            if(sort4_switch) begin
                if(sort5_track==4) begin
                    x[3] <= x[4] ;
                    y[3] <= y[4] ;
                    x[4] <= x[3] ;
                    y[4] <= y[3] ;
                    for(i=0;i<3;i=i+1) begin
                        x[i] <= x[i] ;
                        y[i] <= y[i] ;
                    end
                    for(i=5;i<7;i=i+1) begin
                        x[i] <= x[i] ;
                        y[i] <= y[i] ;
                    end
                end
                else if(sort5_track==3) begin
                    x[2] <= x[3] ;
                    y[2] <= y[3] ;
                    x[3] <= x[2] ;
                    y[3] <= y[2] ;
                    for(i=0;i<2;i=i+1) begin
                        x[i] <= x[i] ;
                        y[i] <= y[i] ;
                    end
                    for(i=4;i<7;i=i+1) begin
                        x[i] <= x[i] ;
                        y[i] <= y[i] ;
                    end
                end
                else if(sort5_track==2) begin
                    x[1] <= x[2] ;
                    y[1] <= y[2] ;
                    x[2] <= x[1] ;
                    y[2] <= y[1] ;
                    for(i=0;i<1;i=i+1) begin
                        x[i] <= x[i] ;
                        y[i] <= y[i] ;
                    end
                    for(i=3;i<7;i=i+1) begin
                        x[i] <= x[i] ;
                        y[i] <= y[i] ;
                    end
                end
                else begin
                    for(i=0;i<7;i=i+1) begin
                       x[i] <= x[i] ;
                        y[i] <= y[i] ;
                    end
                end
            end
            else begin
                for(i=0;i<7;i=i+1) begin
                    x[i] <= x[i] ;
                    y[i] <= y[i] ;
                end
            end
        end
        // sort6
        else if(state_r==S_sort6) begin
            if(sort6_switch) begin
                if(sort6_track==4) begin
                    x[3] <= x[4] ;
                    y[3] <= y[4] ;
                    x[4] <= x[3] ;
                    y[4] <= y[3] ;
                    for(i=0;i<3;i=i+1) begin
                        x[i] <= x[i] ;
                        y[i] <= y[i] ;
                    end
                    for(i=5;i<7;i=i+1) begin
                        x[i] <= x[i] ;
                        y[i] <= y[i] ;
                    end
                end
                else if(sort6_track==3) begin
                    x[2] <= x[3] ;
                    y[2] <= y[3] ;
                    x[3] <= x[2] ;
                    y[3] <= y[2] ;
                    for(i=0;i<2;i=i+1) begin
                        x[i] <= x[i] ;
                        y[i] <= y[i] ;
                    end
                    for(i=4;i<7;i=i+1) begin
                        x[i] <= x[i] ;
                        y[i] <= y[i] ;
                    end
                end
                else if(sort6_track==2) begin
                    x[1] <= x[2] ;
                    y[1] <= y[2] ;
                    x[2] <= x[1] ;
                    y[2] <= y[1] ;
                    for(i=0;i<1;i=i+1) begin
                        x[i] <= x[i] ;
                        y[i] <= y[i] ;
                    end
                    for(i=3;i<7;i=i+1) begin
                        x[i] <= x[i] ;
                        y[i] <= y[i] ;
                    end
                end
                else if(sort6_track==5) begin
                    x[4] <= x[5] ;
                    y[4] <= y[5] ;
                    x[5] <= x[4] ;
                    y[5] <= y[4] ;
                    for(i=0;i<4;i=i+1) begin
                        x[i] <= x[i] ;
                        y[i] <= y[i] ;
                    end
                    for(i=6;i<7;i=i+1) begin
                        x[i] <= x[i] ;
                        y[i] <= y[i] ;
                    end
                end
                else begin
                    for(i=0;i<7;i=i+1) begin
                       x[i] <= x[i] ;
                        y[i] <= y[i] ;
                    end
                end
            end
            else begin
                for(i=0;i<7;i=i+1) begin
                    x[i] <= x[i] ;
                    y[i] <= y[i] ;
                end
            end
        end
        else if (state_r== S_finish) begin
            for(i=0;i<7;i=i+1) begin
                x[i] <= 0 ;
                y[i] <= 0 ;
            end
        end
        else begin
            for(i=0;i<7;i=i+1) begin
                x[i] <= x[i] ;
                y[i] <= y[i] ;
            end
        end

    end
end

// sort tracking
always @(posedge clk or posedge reset ) begin
    if(reset) sort4_track <= 3 ;
    else begin
        if(sort4_switch && state_r==S_sort4) sort4_track <= sort4_track - 1 ;
        else sort4_track <= 3 ;
    end
end
always @(posedge clk or posedge reset ) begin
    if(reset) sort5_track <= 4 ;
    else begin
        if(sort5_switch && state_r==S_sort5) sort5_track <= sort5_track - 1 ;
        else sort5_track <= 4 ;
    end
end
always @(posedge clk or posedge reset ) begin
    if(reset) sort6_track <= 5 ;
    else begin
        if(sort6_switch && state_r==S_sort6) sort6_track <= sort6_track - 1 ;
        else sort6_track <= 5 ;
    end
end
// state
always @(posedge clk or posedge reset) begin
    if(reset) state_r <= S_idle ;
    else state_r <= state_w ;
end

// output 
always @(posedge clk) begin
    valid_ff <= valid_logic ;
    inside_check <= inside_logic ;
end

endmodule

