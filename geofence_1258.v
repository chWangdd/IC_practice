module geofence ( clk,reset,X,Y,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output valid;
output is_inside;

parameter S_idle = 4'd10 ;
parameter S_eval = 4'd12 ;
parameter S_wait = 4'd11 ;;
parameter S_5p = 4'd5 ;
parameter S_4p1n = 4'd4 ;
parameter S_3p2n = 4'd3 ;
parameter S_2p3n = 4'd2 ;
parameter S_1p4n = 4'd1 ;
parameter S_5n = 4'd0;
parameter S_target = 4'd14 ;
parameter S_finish = 4'd15;
integer i ;
// registers
reg signed[9:0]x[0:6]; // 6 is for target
reg signed[9:0]y[0:6]; // 6 is for target
reg signed[9:0]x_new[0:6]; // 6 is for target
reg signed[9:0]y_new[0:6]; // 6 is for target
reg [3:0] state_r, state_w;
reg [2:0] read_counter_r, read_counter_w ;


reg signed [10:0] vector1_x [0:4]
reg signed [10:0] vector2_x [0:4];
reg signed [10:0] vector1_y [0:4]
reg signed [10:0] vector2_y [0:4];
reg signed [20:0] outer_product [0:4];

reg signed [10:0] sort_vector1_x [0:4]
reg signed [10:0] sort_vector2_x [0:4];
reg signed [10:0] sort_vector1_y [0:4]
reg signed [10:0] sort_vector2_y [0:4];
reg signed [20:0] sort_outer_product [0:4];

reg [2:0] evaluate ;
reg direction ;
reg [4:0] direction_label; 

//// we use (x[5],y[5]) as anchor point, starting point
//// first, we calculate
// (p4-p5)*(p3-p5)
// (p3-p5)*(p2-p5)
// (p2-p5)*(p1-p5)
// (p1-p5)*(p0-p5)
// (p0-p5)*(p4-p5)
///// pick the majority result, there is multiple cases
/*
5+ 
4+1-
3+2-
2+3-
1+4-
5- 
*/


reg [2:0] countdown_r, countdown_w;
reg valid_logic ;
reg start_sending_inf, reset_ff, valid_ff;

reg [2:0]counter_for_target_calculation ; 

wire finish_reading_inf ;
wire lost1_location;
wire signed [10:0]lost1_x ;
wire signed [10:0]lost1_y ;
wire [2:0] lost1_insert_index ;
// assignments
assign finish_reading_inf = (read_counter_r==0) ;

assign lost1_location = (direction)? 
                        ( (direction_label[0]==0)?0:(direction_label[1]==0)?1:(direction_label[2]==0)?2:(direction_label[3]==0)?3:4 )
                    :   ( (direction_label[0]==1)?0:(direction_label[1]==1)?1:(direction_label[2]==1)?2:(direction_label[3]==1)?3:4 ) ;
assign lost1_x = x[lost1_location]-x[5];
assign lost1_y = y[lost1_location]-y[5];

assign valid = valid_logic ;

always @(*) begin
    case(state_r)
    S_idle : state_w = (start_sending_inf)? S_idle : S_wait ;
    S_wait : state_w = (finish_reading_inf)? S_eval : S_wait ;
    S_eval : begin
        state_w = 
        (evaluate==0)? S_5p :
        (evaluate==1)? S_4p1n :
        (evaluate==2)? S_3p2n :
        (evaluate==3)? S_2p3n :
        (evaluate==4)? S_1p4n : S_5n  ;   
    end
    S_5p : state_w = S_target ;
    S_4p1n :
    S_3p2n :
    S_2p3n :
    S_1p4n :
    S_5n : state_w = S_target ;
    S_target : state_w = S_finish ;
    S_finish : state_w = S_idle 
    endcase
    default : state_w = S_idle ;
end

always @(*) begin
    case(state_r)
    S_idle : state_w = (start_sending_inf)? S_idle : S_wait ;
    S_wait : state_w = (finish_reading_inf)? S_eval : S_wait ;
    S_eval : begin
        state_w = 
        (evaluate==0)? S_5p :
        (evaluate==1)? S_4p1n :
        (evaluate==2)? S_3p2n :
        (evaluate==3)? S_2p3n :
        (evaluate==4)? S_1p4n : S_5n  ;   
    end
    S_5p : state_w = S_target ;
    S_4p1n :
    S_3p2n :
    S_2p3n :
    S_1p4n :
    S_5n : state_w = S_target ;
    S_target : state_w = S_finish ;
    S_finish : state_w = S_idle 
    endcase
    default : state_w = S_idle ;
end

always @(*) begin
    read_counter_w = (finish_reading_inf 0)? 7:(start_sending_inf)? 6:read_counter_r-1 ; 
end

always @(*) begin
    for(i=0;i<5;i=i+1)begin
        vector1_x[i] = x[i] - x[5] ; 
        vector1_y[i] = y[i] - y[5] ; 
        vector2_x[i] = x[3-i] - x[5] ; 
        vector2_y[i] = y[3-i] - y[5] ;
        outer_product[i] = (vector1_x[i]*vector2_y[i]) - (vector2_x[i]*vector1_y[i]) ; 
    end
    outer_product[4] = (vector1_x[4]*vector2_y[4]) - (vector2_x[4]*vector1_y[4]) ; 
end

always @(*) begin
    evaluate = outer_product[4][20] + outer_product[3][20] + outer_product[2][20] + outer_product[1][20] + outer_product[0][20]  ;
    direction_label[0] = outer_product[0][20] ;
    direction_label[1] = outer_product[1][20] ;
    direction_label[2] = outer_product[2][20] ;
    direction_label[3] = outer_product[3][20] ;
    direction_label[4] = outer_product[4][20] ;
    direction = (evaluate==0) ||  (evaluate==1) ||  (evaluate==2) ;
end
always @(*) begin
    case(evaluate)
    3'd1: begin
        for(i=0;i<4;i=i+1)begin
            sort_vector1_x[i] = x[4-i] - x[5] ; 
            sort_vector1_y[i] = y[4-i] - y[5] ; 
            sort_vector2_x[i] = lost1_x - x[5] ; 
            sort_vector2_y[i] = lost1_y - y[5] ;
            sort_outer_product[i] = (vector1_x[i]*vector2_y[i]) - (vector2_x[i]*vector1_y[i]) ; 
        end
    end
    3'd4: begin
        for(i=0;i<4;i=i+1)begin
            sort_vector1_x[i] = x[4-i] - x[5] ; 
            sort_vector1_y[i] = y[4-i] - y[5] ; 
            sort_vector2_x[i] = lost1_x - x[5] ; 
            sort_vector2_y[i] = lost1_y - y[5] ;
            sort_outer_product[i] = (vector1_x[i]*vector2_y[i]) - (vector2_x[i]*vector1_y[i]) ; 
        end
    end
    3'd2: begin
        for(i=0;i<4;i=i+1)begin
            sort_vector1_x[i] = 0 ;
            sort_vector1_y[i] = 0 ;
            sort_vector2_x[i] = 0 ;
            sort_vector2_y[i] = 0 ;
            sort_outer_product[i] = 0 ;
        end
    end
    3'd3: begin
        for(i=0;i<4;i=i+1)begin
            sort_vector1_x[i] = 0 ;
            sort_vector1_y[i] = 0 ;
            sort_vector2_x[i] = 0 ;
            sort_vector2_y[i] = 0 ;
            sort_outer_product[i] = 0 ;
        end
    end
    endcase
    default : begin
        for(i=0;i<4;i=i+1)begin
            sort_vector1_x[i] = 0 ;
            sort_vector1_y[i] = 0 ;
            sort_vector2_x[i] = 0 ;
            sort_vector2_y[i] = 0 ;
            sort_outer_product[i] = 0 ;
        end
    end
end


//////////////////////////////////////// SEQ
always @(posedge clk or posedge reset ) begin
    if(reset) begin
        for(i=0;i<7;i=i+1) begin
            x[i] <= 0 ;
            y[i] <= 0 ;
        end
    end
    else begin
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
end

always @(posedge clk) begin
    start_sending_inf <= reset_ff || valid_logic ;
    reset_ff <= reset ;
    valid_ff <= valid_logic ;
end
always @(posedge clk or posedge reset) begin
    if(reset) read_counter_r <= 3'd6 ;
    else read_counter_r <= read_counter_w ;
end
always @(posedge clk or posedge reset) begin
    if(reset) state_r <= S_idle ;
    else state_r <= state_w ;
end

endmodule

