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
parameter S_comp = 3'b001 ;
parameter S_finish = 3'b110 ;

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
reg found_it;
//// verify the pattern's character in the string to jump out early
reg check_var;
//// FSM
reg [2:0]state_w, state_r ;
//// search for word
reg [2:0]progress_pat;
reg [4:0]progress_str;
// assignments
assign valid = (state_r==S_finish) ;
assign match_index = countdown ;
assign match = found_it ;
// FSM
always @(*) begin
    case(state_r)
        S_idle : begin
            if(start_compare) state_w = S_comp ;
            else state_w = S_idle ;
        end
        S_comp : begin
            if(found_it) state_w = S_finish ; 
            else begin
                if(countdown!=5'd0) state_w = S_comp ;
                else begin
                    state_w = S_finish ;
                end
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
    if(pat_mem[0]==8'h5E) begin
        pattern[0:6] = pat_mem[1:7] ;
        pattern[7] = 8'h00 ;
    end
    else pattern[0:7] = pat_mem[0:7] ;
end
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
        word_length_sum[2:0] = (!pat_mem[2])? 1: (!pat_mem[3])? 2:  (!pat_mem[4])? 3:  (!pat_mem[5])? 4:  (!pat_mem[6])? 5:  (!pat_mem[7])? 6 : 7 ;
    end
    else begin //沒^
        word_length_sum[2:0] = (!pat_mem[1])? 1:(!pat_mem[2])? 2: (!pat_mem[3])? 3:  (!pat_mem[4])? 4:  (!pat_mem[5])? 5:  (!pat_mem[6])?6 : (!pat_mem[7])? 7 : 0 ;
    end
end
// seq
always @(posedge clk or posedge reset) begin
    isstring_ff <= isstring ;
    ispattern_ff <= ispattern ;
end
always @(posedge clk or posedge reset) begin
    if(reset) begin
        for(i=0;i<32;i=i+1) begin
            string_mem[i] <= 0 ;
        end
    end
    else begin
        if(isstring) begin
            string_mem[0] = (progress_str==0)? chardata : string_mem[0] ;
            for(i=1;i<32;i=i+1) begin
                if(i==progress_str) string_mem[i] <= chardata ;
                else string_mem[i] <= string_mem[i] ;
           end
        end
        else begin 
            if(state_r==S_comp) begin
                for(i=0;i<31;i=i+1) begin
                    string_mem[i] <= string_mem[i+1] ;
                end
                string_mem[31] <= string_mem[0] ;
            end
            else if (state_r==S_finish) begin
                for(i=0;i<32;i=i+1) begin
                    string_mem[i] <= string_mem[i] ;
                end
            end
            else begin
                for(i=0;i<32;i=i+1) begin
                    string_mem[i] <= string_mem[i] ;
                end
            end
        end
    end
end

always @(posedge clk or posedge reset) begin
    if(reset) begin
        for(i=0;i<8;i=i+1) begin
            pat_mem[i] <= 8'h00 ;
        end
    end
    else begin
        if(ispattern || (progress_pat!=3'd0) ) begin
            pat_mem[0] = (progress_pat==0)? chardata : pat_mem[0] ;
            for(i=1;i<8;i=i+1) begin
                if(i==progress_pat) pat_mem[i] <= chardata ;
                else pat_mem[i] <= pat_mem[i] ;
           end
        end
        else begin 
            for(i=0;i<8;i=i+1) begin
                pat_mem[i] <= pat_mem[i] ;
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
// record words opening and ending
always @(posedge clk or posedge reset) begin
    if(reset) begin
            for(i=0;i<8;i=i+1) begin
                pat_mem[i] <= 8'hff ;
            end
    end
    else begin
        if(ispattern || (progress_pat!=3'd0) ) begin
            pat_mem[0] = (progress_pat==0)? chardata : pat_mem[0] ;
            for(i=1;i<8;i=i+1) begin
                if(i==progress_pat) pat_mem[i] <= chardata ;
                else pat_mem[i] <= pat_mem[i] ;
           end
        end
        else begin 
            for(i=0;i<8;i=i+1) begin
                pat_mem[i] <= pat_mem[i] ;
            end
        end
    end
end
always @(posedge clk or posedge reset) begin
    if(reset) begin
        state_r <= S_idle ;
    end
    else begin
        state_r <= state_w ;
    end
end
endmodule
