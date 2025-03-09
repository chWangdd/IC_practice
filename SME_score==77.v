module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output match;
output [4:0] match_index;
output valid;

parameter S_idle = 3'b000 ;
parameter S_comp = 3'b010 ;
parameter S_finish = 3'b100 ;

parameter open = 2'b00 ;
parameter ending = 2'b01 ;
parameter space = 2'b10 ;
parameter others = 2'b11 ;
// reg match;
// reg [4:0] match_index;
// reg valid;

// ^ 開頭, 5E
// $ 結尾, 24
// . 任一單一字元, 2E
// * 任一多字元, 2A
integer i ;
// registers
//// read input string sequence
reg [7:0] string_mem[0:31]; // input string
reg [7:0] pat_mem[0:7]; // input pattern
reg [7:0] pattern[0:7]; // input pattern
reg change_string, isstring_ff; // input isstring
reg start_compare, ispattern_ff; // input pattern
reg refresh_pat ;
reg var_length ;
reg [7:0] word_length_bi ;
reg [2:0] word_length_sum ;
reg [4:0] countdown;
reg [4:0] index, select_index;
reg found_it, success_match;
wire cash_exist, open_exist ;
//// verify the pattern's character in the string to jump out early
reg check_var;
//// FSM
reg [2:0]state_w, state_r ;
//// search for word
reg [2:0]progress_pat;
reg [4:0]progress_str;
// assignments
assign cash_exist =  (pat_mem[0]==8'h24)|| (pat_mem[1]==8'h24)|| (pat_mem[2]==8'h24)|| (pat_mem[3]==8'h24)|| (pat_mem[4]==8'h24)|| (pat_mem[5]==8'h24)||(pat_mem[6]==8'h24)||(pat_mem[7]==8'h24) ;
assign open_exist =  (pat_mem[0]==8'h5E)|| (pat_mem[1]==8'h5E)|| (pat_mem[2]==8'h5E)|| (pat_mem[3]==8'h5E)|| (pat_mem[4]==8'h5E)|| (pat_mem[5]==8'h5E)||(pat_mem[6]==8'h5E)||(pat_mem[7]==8'h5E) ;

assign valid = (state_r==S_finish) ;
assign match_index = select_index ;
assign match = success_match ;
// FSM
always @(*) begin
    case(state_r)
        S_idle : begin
            if(start_compare) state_w = S_comp ;
            else state_w = S_idle ;
        end
        S_comp : begin
            if(countdown!=5'd0) state_w = S_comp ;
            else begin
                if(found_it) state_w = S_finish ; 
                else state_w = S_finish ;
            end
        end
        S_finish : begin
            state_w = S_idle ;
        end
        default : state_w = S_idle ;
    endcase
end
// 判斷input string是否要更新
always @(*) begin
    change_string = (!isstring_ff & isstring) ;
    start_compare = ispattern_ff & !ispattern ; 
    refresh_pat = ispattern & !ispattern_ff ;
end
always @(*) begin
    if(pat_mem[0]==8'h5E) begin // ^開頭
        for(i=0;i<7;i=i+1) begin
            pattern[i] = (pat_mem[i]==8'h24)? 8'hff : pat_mem[i+1] ;
        end
        //pattern[0:6] = pat_mem[1:7] ;
        pattern[7] = 8'hff ;
    end
    else begin 
        for(i=0;i<8;i=i+1) begin
            pattern[i] = (pat_mem[i]==8'h24)? 8'hff : pat_mem[i] ;
        end    
    end
end

always @(*) begin
    case(word_length_sum)
        1: found_it = ((pattern[0] == string_mem[0]) || (pattern[0] == 8'h2E)) &&
                      ((cash_exist && (string_mem[1] == 8'h20 || string_mem[1] == 8'h00)) || (~cash_exist)) &&
                      ((open_exist && (string_mem[31] == 8'h20 || string_mem[31] == 8'h00)) || (~open_exist)) ;
                      
        2: found_it = ((pattern[0] == string_mem[0]) || (pattern[0] == 8'h2E)) &&
                      ((pattern[1] == string_mem[1]) || (pattern[1] == 8'h2E)) &&
                      ((cash_exist && (string_mem[2] == 8'h20 || string_mem[2] == 8'h00)) || (~cash_exist)) &&
                      ((open_exist && (string_mem[31] == 8'h20 || string_mem[31] == 8'h00)) || (~open_exist)) ;
                      
        3: found_it = ((pattern[0] == string_mem[0]) || (pattern[0] == 8'h2E)) &&
                      ((pattern[1] == string_mem[1]) || (pattern[1] == 8'h2E)) &&
                      ((pattern[2] == string_mem[2]) || (pattern[2] == 8'h2E)) &&
                      ((cash_exist && (string_mem[3] == 8'h20 || string_mem[3] == 8'h00)) || (~cash_exist)) &&
                      ((open_exist && (string_mem[31] == 8'h20 || string_mem[31] == 8'h00)) || (~open_exist)) ;
                      
        4: found_it = ((pattern[0] == string_mem[0]) || (pattern[0] == 8'h2E)) &&
                      ((pattern[1] == string_mem[1]) || (pattern[1] == 8'h2E)) &&
                      ((pattern[2] == string_mem[2]) || (pattern[2] == 8'h2E)) &&
                      ((pattern[3] == string_mem[3]) || (pattern[3] == 8'h2E)) &&
                      ((cash_exist && (string_mem[4] == 8'h20 || string_mem[4] == 8'h00)) || (~cash_exist)) &&
                      ((open_exist && (string_mem[31] == 8'h20 || string_mem[31] == 8'h00)) || (~open_exist)) ;
                      
        5: found_it = ((pattern[0] == string_mem[0]) || (pattern[0] == 8'h2E)) &&
                      ((pattern[1] == string_mem[1]) || (pattern[1] == 8'h2E)) &&
                      ((pattern[2] == string_mem[2]) || (pattern[2] == 8'h2E)) &&
                      ((pattern[3] == string_mem[3]) || (pattern[3] == 8'h2E)) &&
                      ((pattern[4] == string_mem[4]) || (pattern[4] == 8'h2E)) &&
                      ((cash_exist && (string_mem[5] == 8'h20 || string_mem[5] == 8'h00)) || (~cash_exist)) &&
                      ((open_exist && (string_mem[31] == 8'h20 || string_mem[31] == 8'h00)) || (~open_exist)) ;
                      
        6: found_it = ((pattern[0] == string_mem[0]) || (pattern[0] == 8'h2E)) &&
                      ((pattern[1] == string_mem[1]) || (pattern[1] == 8'h2E)) &&
                      ((pattern[2] == string_mem[2]) || (pattern[2] == 8'h2E)) &&
                      ((pattern[3] == string_mem[3]) || (pattern[3] == 8'h2E)) &&
                      ((pattern[4] == string_mem[4]) || (pattern[4] == 8'h2E)) &&
                      ((pattern[5] == string_mem[5]) || (pattern[5] == 8'h2E)) &&
                      ((cash_exist && (string_mem[6] == 8'h20 || string_mem[6] == 8'h00)) || (~cash_exist)) &&
                      ((open_exist && (string_mem[31] == 8'h20 || string_mem[31] == 8'h00)) || (~open_exist)) ;
                      
        7: found_it = ((pattern[0] == string_mem[0]) || (pattern[0] == 8'h2E)) &&
                      ((pattern[1] == string_mem[1]) || (pattern[1] == 8'h2E)) &&
                      ((pattern[2] == string_mem[2]) || (pattern[2] == 8'h2E)) &&
                      ((pattern[3] == string_mem[3]) || (pattern[3] == 8'h2E)) &&
                      ((pattern[4] == string_mem[4]) || (pattern[4] == 8'h2E)) &&
                      ((pattern[5] == string_mem[5]) || (pattern[5] == 8'h2E)) &&
                      ((pattern[6] == string_mem[6]) || (pattern[6] == 8'h2E)) &&
                      ((cash_exist && (string_mem[7] == 8'h20 || string_mem[7] == 8'h00)) || (~cash_exist)) &&
                      ((open_exist && (string_mem[31] == 8'h20 || string_mem[31] == 8'h00)) || (~open_exist)) ;
                      
        8: found_it = ((pattern[0] == string_mem[0]) || (pattern[0] == 8'h2E)) &&
                      ((pattern[1] == string_mem[1]) || (pattern[1] == 8'h2E)) &&
                      ((pattern[2] == string_mem[2]) || (pattern[2] == 8'h2E)) &&
                      ((pattern[3] == string_mem[3]) || (pattern[3] == 8'h2E)) &&
                      ((pattern[4] == string_mem[4]) || (pattern[4] == 8'h2E)) &&
                      ((pattern[5] == string_mem[5]) || (pattern[5] == 8'h2E)) &&
                      ((pattern[6] == string_mem[6]) || (pattern[6] == 8'h2E)) &&
                      ((pattern[7] == string_mem[7]) || (pattern[7] == 8'h2E)) &&
                      ((cash_exist && (string_mem[8] == 8'h20 || string_mem[8] == 8'h00)) || (~cash_exist)) &&
                      ((open_exist && (string_mem[31] == 8'h20 || string_mem[31] == 8'h00)) || (~open_exist)) ;

        default: found_it = 1'b0;
    endcase
end



/*
always @(*) begin
    found_it = 
    (
    (word_length_sum==1)? (pattern[0]==string_mem[0]) :
    (word_length_sum==2)? (pattern[0]==string_mem[0])&&(pattern[1]==string_mem[1]) :
    (word_length_sum==3)? (pattern[0]==string_mem[0])&&(pattern[1]==string_mem[1])&&(pattern[2]==string_mem[2]):
    (word_length_sum==4)? (pattern[0]==string_mem[0])&&(pattern[1]==string_mem[1])&&(pattern[2]==string_mem[2])&&(pattern[3]==string_mem[3]):
    (word_length_sum==5)? (pattern[0]==string_mem[0])&&(pattern[1]==string_mem[1])&&(pattern[2]==string_mem[2])&&(pattern[3]==string_mem[3])&&(pattern[4]==string_mem[4]):
    (word_length_sum==6)? (pattern[0]==string_mem[0])&&(pattern[1]==string_mem[1])&&(pattern[2]==string_mem[2])&&(pattern[3]==string_mem[3])&&(pattern[4]==string_mem[4])&&(pattern[5]==string_mem[5]):
    (word_length_sum==7)? (pattern[0]==string_mem[0])&&(pattern[1]==string_mem[1])&&(pattern[2]==string_mem[2])&&(pattern[3]==string_mem[3])&&(pattern[4]==string_mem[4])&&(pattern[5]==string_mem[5])&&(pattern[6]==string_mem[6]):
    (word_length_sum==8)? (pattern[0]==string_mem[0])&&(pattern[1]==string_mem[1])&&(pattern[2]==string_mem[2])&&(pattern[3]==string_mem[3])&&(pattern[4]==string_mem[4])&&(pattern[5]==string_mem[5])&&(pattern[6]==string_mem[6])&&(pattern[7]==string_mem[7]) :
    0 );
end
*/
// 判斷pattern的字是否為變數
always @(*) begin
    check_var = (chardata==8'h5E)||(chardata==8'h2E)||(chardata==8'h2A) ; // this is unknown variable
end
always @(*) begin
    var_length = (pat_mem[0]==8'h2A)|| (pat_mem[1]==8'h2A)|| (pat_mem[2]==8'h2A)|| (pat_mem[3]==8'h2A)|| (pat_mem[4]==8'h2A)|| (pat_mem[5]==8'h2A)||(pat_mem[6]==8'h2A)||(pat_mem[7]==8'h2A) ;
end

always @(*) begin
    if(pat_mem[0]==8'h5E) begin
        for(i=1;i<8;i=i+1) begin
            word_length_bi[i] = (pat_mem[i]!=8'hff) && (pat_mem[i]!=8'h24) ;
        end
        word_length_bi[0] = 0 ; 
    end
    else if (var_length) begin
        for(i=0;i<8;i=i+1) begin
            word_length_bi[i] = 1 ;
        end
    end
    else begin
        for(i=0;i<8;i=i+1) begin
            word_length_bi[i] = (pat_mem[i]!=8'hff) && (pat_mem[i]!=8'h24) ;
        end
    end
end
always @(*) begin
    if(pat_mem[0]==8'h5E) begin // 有^
        word_length_sum[2:0] = (!word_length_bi[2])? 1: (!word_length_bi[3])? 2:  (!word_length_bi[4])? 3:  (!word_length_bi[5])? 4:  (!word_length_bi[6])? 5:  (!word_length_bi[7])? 6 : 7 ;
    end
    else begin //沒^
       word_length_sum[2:0] =
(!word_length_bi[1]) ? 1 :
(!word_length_bi[2]) ? 2 :
(!word_length_bi[3]) ? 3 :
(!word_length_bi[4]) ? 4 :
(!word_length_bi[5]) ? 5 :
(!word_length_bi[6]) ? 6 :
(!word_length_bi[7]) ? 7 : 0;
    end
end
// seq
always @(posedge clk or posedge reset) begin
    isstring_ff <= isstring ;
    ispattern_ff <= ispattern ;
end

// string and index label
always @(posedge clk or posedge reset) begin
    if(reset) begin
        for(i=0;i<32;i=i+1) begin
            string_mem[i] <= 0 ;
            index <= 0 ;
            select_index <= 5'd31 ;
        end
    end
    else begin
        if(isstring) begin
            string_mem[0] = (progress_str==0)? chardata : string_mem[0] ;
            for(i=1;i<32;i=i+1) begin
                if(change_string) string_mem[i] <= 0 ;
                else begin
                    if(i==progress_str) string_mem[i] <= chardata ;
                    else string_mem[i] <= string_mem[i] ;
                end
           end
           index <= (change_string)? 0 : index ;
           select_index <= 5'd31 ; 
        end
        else begin 
            if(state_r==S_comp) begin
                for(i=0;i<31;i=i+1) begin
                    string_mem[i] <= string_mem[i+1] ;
                end
                string_mem[31] <= string_mem[0] ;
                index <= index+1 ;
                select_index <= ( (found_it)&&(select_index>index) )? index :select_index ;
            end
            else if (state_r==S_finish) begin
                for(i=0;i<32;i=i+1) begin
                    string_mem[i] <= string_mem[i] ;
                end
                index <= index ;
                select_index <= select_index ;
            end
            else begin
                for(i=0;i<32;i=i+1) begin
                    string_mem[i] <= string_mem[i] ;
                end
                index <= index ;
                select_index <= 5'd31 ; 
            end
        end
    end
end
// pattern
always @(posedge clk or posedge reset) begin
    if(reset) begin
            for(i=0;i<8;i=i+1) begin
                pat_mem[i] <= 8'hff ;
            end
    end
    else begin
        if(refresh_pat) begin
            pat_mem[0] <= (ispattern)? chardata : pat_mem[0] ;
            for(i=1;i<8;i=i+1) begin
                pat_mem[i] <= 8'hff ;
            end        
        end
        else begin
            for(i=0;i<8;i=i+1) begin
                if(i==progress_pat) pat_mem[i] <= (ispattern)? chardata : pat_mem[i] ;
                else pat_mem[i] <= pat_mem[i] ;
            end
        end
    end
end
// time tracking
always @(posedge clk or posedge reset) begin
    if(reset) begin
        progress_pat <= 0 ;
        progress_str <= 0 ;
    end
    else begin
        if(ispattern) begin
            progress_pat <= progress_pat + 3'd1 ;
            progress_str <= 0 ;
        end
        else if (isstring) begin
            progress_pat <= 0 ;
            progress_str <= progress_str + 3'd1 ;
        end
        else begin
            progress_pat <= 0 ;
            progress_str <= 0 ;
        end
    end
end
// countdown for compare
always @(posedge clk or posedge reset) begin
    if(reset) begin
        countdown <= 0 ;
    end
    else begin
        if(start_compare || (state_r== S_comp) )  countdown <= countdown + 1 ;
        else countdown <= 0 ;
    end
end

// state 
always @(posedge clk or posedge reset) begin
    if(reset) begin
        state_r <= S_idle ;
    end
    else begin
        state_r <= state_w ;
    end
end
always @(posedge clk or posedge reset) begin
    if(reset) begin
        success_match <= 0 ;
    end
    else begin
        success_match <= (state_r==S_finish || state_r==S_idle)? 0:(success_match|found_it) ;
    end
end

endmodule
