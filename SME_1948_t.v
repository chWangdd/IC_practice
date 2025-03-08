module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output match;
output [4:0] match_index;
output valid;


reg [319:0] string_in_comb, string_in_ff;        
reg [7:0]   pos_comb, pos_ff;                      // 0:255 
reg [7:0]   given_char_comb, given_char_ff;
reg [8:0]   length_string_comb, length_string_ff;   // 32 chars at most

reg [31:0]  qualified_comb, qualified_ff;
	
reg [2:0]   state_curr, state_nxt, state_prev;

reg         match_comb, match_ff, valid_on_comb, valid_on_ff;
reg [4:0]   IDX_comb, IDX_ff; 

reg [6:0] length_along_comb, length_along_ff;

parameter CHAR_HEADER = 8'h5E,
		  CHAR_TAIL   = 8'h24,
		  CHAR_ARBIT  = 8'h2E,
		  CHAR_SPACE  = 8'h20;
	
parameter IDLE  = 3'd0,
		  STRIN = 3'd1,
		  PATIN = 3'd2,
		  PROS  = 3'd3,
		  OUT   = 3'd7;	
	
always@(posedge reset or posedge clk)begin
	if(reset)begin
		string_in_ff      <= 0;
		pos_ff            <= 0;
		length_string_ff  <= 0;
		given_char_ff     <= 0;
		state_curr        <= IDLE;
		state_prev        <= IDLE;
	end
	else begin
		string_in_ff      <= string_in_comb;
		pos_ff            <= pos_comb;	
		length_string_ff  <= length_string_comb;
		given_char_ff     <= given_char_comb;
		state_curr        <= state_nxt;
		state_prev        <= state_curr;
	end
end
	
//FSM
always@(*)begin
	case(state_curr)
	
		IDLE: begin
			if(isstring)       state_nxt = STRIN;
			else 			   state_nxt = IDLE;
		end
		
		STRIN: begin
			if(ispattern)      state_nxt = PATIN;
			else               state_nxt = STRIN;
		end
			
		PATIN: begin
			if(!ispattern)      state_nxt = PROS;
			else                state_nxt = PATIN;
		end
		
		// ***************Controlled by PROCESSOR******************//
		PROS: begin 
			 if(given_char_ff != CHAR_TAIL)     state_nxt = OUT;
			 //else if()
			 else 								state_nxt = PROS;
		end
			
		OUT: begin
			if(isstring)       state_nxt = STRIN;
			else if(ispattern) state_nxt = PATIN;
			else               state_nxt = OUT;
		end
		
		default: begin
								state_nxt = IDLE;
		end
	endcase
end


// Assignment of Input
always@(*)begin

	string_in_comb = string_in_ff;
	pos_comb = pos_ff;
	length_string_comb = length_string_ff;
	given_char_comb = given_char_ff;
	
	if(state_curr == OUT)begin
		case(length_along_ff)
			7'd0: begin
				string_in_comb = string_in_ff;
			end
			7'd8: begin
				string_in_comb = string_in_ff[7:0] << 312 | string_in_ff[319:8];
			end
			7'd16: begin
				string_in_comb = string_in_ff[15:0] << 304 | string_in_ff[319:16];
			end
			7'd24: begin
				string_in_comb = string_in_ff[23:0] << 296 | string_in_ff[319:24];
			end
			7'd32: begin
				string_in_comb = string_in_ff[31:0] << 288 | string_in_ff[319:32];
			end
			7'd40: begin
				string_in_comb = string_in_ff[39:0] << 280 | string_in_ff[319:40];
			end
			7'd48: begin
				string_in_comb = string_in_ff[47:0] << 272 | string_in_ff[319:48];
			end
			7'd56: begin
				string_in_comb = string_in_ff[55:0] << 264 | string_in_ff[319:56];
			end
			7'd64: begin
				string_in_comb = string_in_ff[63:0] << 256 | string_in_ff[319:64];
			end
			default: begin
			
			end
		endcase
		if(isstring)begin
			string_in_comb = 0;
			string_in_comb = chardata;
			pos_comb = 8;
			length_string_comb = 8;
		end
		else begin
			given_char_comb = chardata;
		/*case(length_along_ff)
			7'd0: begin
				string_in_comb = string_in_ff;
			end
			7'd8: begin
				string_in_comb = string_in_ff[7:0] << 312 | string_in_ff[319:8];
			end
			7'd16: begin
				string_in_comb = string_in_ff[15:0] << 304 | string_in_ff[319:16];
			end
			7'd24: begin
				string_in_comb = string_in_ff[23:0] << 296 | string_in_ff[319:24];
			end
			7'd32: begin
				string_in_comb = string_in_ff[31:0] << 288 | string_in_ff[319:32];
			end
			7'd40: begin
				string_in_comb = string_in_ff[39:0] << 280 | string_in_ff[319:40];
			end
			7'd48: begin
				string_in_comb = string_in_ff[47:0] << 272 | string_in_ff[319:48];
			end
			7'd56: begin
				string_in_comb = string_in_ff[55:0] << 264 | string_in_ff[319:56];
			end
			7'd64: begin
				string_in_comb = string_in_ff[63:0] << 256 | string_in_ff[319:64];
			end
			default: begin
			
			end
		endcase*/
		end
	end
	
	else if(state_curr == IDLE)begin
			string_in_comb = 0;
		if(isstring)begin
			string_in_comb = chardata;
			pos_comb = 8;
			length_string_comb = 8;
		end
	end
	
	else if(state_curr == STRIN)begin
		if(isstring)begin
			string_in_comb = (string_in_ff << 8) | chardata;
			pos_comb = pos_ff + 8;
			length_string_comb = length_string_ff + 8;
		end
		else begin
			pos_comb = 8;
			given_char_comb = chardata;
		end
	end
	
	else if(state_curr == PATIN)begin
		if(!ispattern)begin
			pos_comb = 0;
			string_in_comb = (/*(given_char_ff != CHAR_HEADER) ||*/ (given_char_ff != CHAR_TAIL)) ? (string_in_ff[247:0] << 8) | string_in_ff[255:248] : string_in_ff;
		end
		else begin
			given_char_comb = chardata;
			pos_comb = pos_ff + 8;
			//string_in_comb = ((given_char_ff != CHAR_HEADER) && (given_char_ff != CHAR_TAIL)) ? (string_in_ff[247:0] << 8) | string_in_ff[255:248] : string_in_ff;
			string_in_comb = ((chardata == CHAR_HEADER) /*|| (given_char_ff == CHAR_HEADER)*/ || (given_char_ff == CHAR_TAIL) /*|| (given_char_ff == CHAR_HEADER)*/)    ?  string_in_ff : (string_in_ff[247:0] << 8) | string_in_ff[255:248];
		end
	end
	
	// ******************************Controlled by PROCESSOR
	else if(state_curr == PROS)begin
		given_char_comb = 0;
	end
end

//PROCESSOR

reg HEADSEL_comb, HEADSEL_ff;
reg TAILSEL_comb, TAILSEL_ff;

always@(*)begin

	qualified_comb = qualified_ff;
	length_along_comb = length_along_ff;
	valid_on_comb = 0;
	IDX_comb = 0;
	match_comb = 0;
	HEADSEL_comb = HEADSEL_ff;
	
	if((state_curr == PATIN) || (state_curr == PROS))begin
	
		if(given_char_ff == CHAR_HEADER)begin
			qualified_comb[0 ] = !((string_in_ff[7  :  0] != CHAR_SPACE) && (8   != length_string_ff));
			qualified_comb[1 ] = !((string_in_ff[15 :  8] != CHAR_SPACE) && (16  != length_string_ff));
			qualified_comb[2 ] = !((string_in_ff[23 : 16] != CHAR_SPACE) && (24  != length_string_ff));
			qualified_comb[3 ] = !((string_in_ff[31 : 24] != CHAR_SPACE) && (32  != length_string_ff));
			qualified_comb[4 ] = !((string_in_ff[39 : 32] != CHAR_SPACE) && (40  != length_string_ff));
			qualified_comb[5 ] = !((string_in_ff[47 : 40] != CHAR_SPACE) && (48  != length_string_ff));
			qualified_comb[6 ] = !((string_in_ff[55 : 48] != CHAR_SPACE) && (56  != length_string_ff));
			qualified_comb[7 ] = !((string_in_ff[63 : 56] != CHAR_SPACE) && (64  != length_string_ff));

			qualified_comb[8 ] = !((string_in_ff[71 : 64] != CHAR_SPACE) && (72  != length_string_ff));
			qualified_comb[9 ] = !((string_in_ff[79 : 72] != CHAR_SPACE) && (80  != length_string_ff));
			qualified_comb[10] = !((string_in_ff[87 : 80] != CHAR_SPACE) && (88  != length_string_ff));
			qualified_comb[11] = !((string_in_ff[95 : 88] != CHAR_SPACE) && (96  != length_string_ff));
			qualified_comb[12] = !((string_in_ff[103: 96] != CHAR_SPACE) && (104 != length_string_ff));
			qualified_comb[13] = !((string_in_ff[111:104] != CHAR_SPACE) && (112 != length_string_ff));
			qualified_comb[14] = !((string_in_ff[119:112] != CHAR_SPACE) && (120 != length_string_ff));
			qualified_comb[15] = !((string_in_ff[127:120] != CHAR_SPACE) && (128 != length_string_ff));

			qualified_comb[16] = !((string_in_ff[135:128] != CHAR_SPACE) && (136 != length_string_ff));
			qualified_comb[17] = !((string_in_ff[143:136] != CHAR_SPACE) && (144 != length_string_ff));
			qualified_comb[18] = !((string_in_ff[151:144] != CHAR_SPACE) && (152 != length_string_ff));
			qualified_comb[19] = !((string_in_ff[159:152] != CHAR_SPACE) && (160 != length_string_ff));
			qualified_comb[20] = !((string_in_ff[167:160] != CHAR_SPACE) && (168 != length_string_ff));
			qualified_comb[21] = !((string_in_ff[175:168] != CHAR_SPACE) && (176 != length_string_ff));
			qualified_comb[22] = !((string_in_ff[183:176] != CHAR_SPACE) && (184 != length_string_ff));
			qualified_comb[23] = !((string_in_ff[191:184] != CHAR_SPACE) && (192 != length_string_ff));

			qualified_comb[24] = !((string_in_ff[199:192] != CHAR_SPACE) && (200 != length_string_ff));
			qualified_comb[25] = !((string_in_ff[207:200] != CHAR_SPACE) && (208 != length_string_ff));
			qualified_comb[26] = !((string_in_ff[215:208] != CHAR_SPACE) && (216 != length_string_ff));
			qualified_comb[27] = !((string_in_ff[223:216] != CHAR_SPACE) && (224 != length_string_ff));
			qualified_comb[28] = !((string_in_ff[231:224] != CHAR_SPACE) && (232 != length_string_ff));
			qualified_comb[29] = !((string_in_ff[239:232] != CHAR_SPACE) && (240 != length_string_ff));
			qualified_comb[30] = !((string_in_ff[247:240] != CHAR_SPACE) && (248 != length_string_ff));
			qualified_comb[31] = !((string_in_ff[255:247] != CHAR_SPACE) && (256 != length_string_ff));
			
			length_along_comb = 8;
			HEADSEL_comb = 1;
		end
		
		else if(given_char_ff == CHAR_TAIL)begin

			qualified_comb[0 ] = ((string_in_ff[7  :  0] == CHAR_SPACE)||(string_in_ff[7  :  0] == 0)) && (qualified_ff[0 ]);
			qualified_comb[1 ] = ((string_in_ff[15 :  8] == CHAR_SPACE)||(string_in_ff[15 :  8] == 0)) && (qualified_ff[1 ]);
			qualified_comb[2 ] = ((string_in_ff[23 : 16] == CHAR_SPACE)||(string_in_ff[23 : 16] == 0)) && (qualified_ff[2 ]);
			qualified_comb[3 ] = ((string_in_ff[31 : 24] == CHAR_SPACE)||(string_in_ff[31 : 24] == 0)) && (qualified_ff[3 ]);
			qualified_comb[4 ] = ((string_in_ff[39 : 32] == CHAR_SPACE)||(string_in_ff[39 : 32] == 0)) && (qualified_ff[4 ]);
			qualified_comb[5 ] = ((string_in_ff[47 : 40] == CHAR_SPACE)||(string_in_ff[47 : 40] == 0)) && (qualified_ff[5 ]);
			qualified_comb[6 ] = ((string_in_ff[55 : 48] == CHAR_SPACE)||(string_in_ff[55 : 48] == 0)) && (qualified_ff[6 ]);
			qualified_comb[7 ] = ((string_in_ff[63 : 56] == CHAR_SPACE)||(string_in_ff[63 : 56] == 0)) && (qualified_ff[7 ]);
								 
			qualified_comb[8 ] = ((string_in_ff[71 : 64] == CHAR_SPACE)||(string_in_ff[71 : 64] == 0)) && (qualified_ff[8 ]);
			qualified_comb[9 ] = ((string_in_ff[79 : 72] == CHAR_SPACE)||(string_in_ff[79 : 72] == 0)) && (qualified_ff[9 ]);
			qualified_comb[10] = ((string_in_ff[87 : 80] == CHAR_SPACE)||(string_in_ff[87 : 80] == 0)) && (qualified_ff[10]);
			qualified_comb[11] = ((string_in_ff[95 : 88] == CHAR_SPACE)||(string_in_ff[95 : 88] == 0)) && (qualified_ff[11]);
			qualified_comb[12] = ((string_in_ff[103: 96] == CHAR_SPACE)||(string_in_ff[103: 96] == 0)) && (qualified_ff[12]);
			qualified_comb[13] = ((string_in_ff[111:104] == CHAR_SPACE)||(string_in_ff[111:104] == 0)) && (qualified_ff[13]);
			qualified_comb[14] = ((string_in_ff[119:112] == CHAR_SPACE)||(string_in_ff[119:112] == 0)) && (qualified_ff[14]);
			qualified_comb[15] = ((string_in_ff[127:120] == CHAR_SPACE)||(string_in_ff[127:120] == 0)) && (qualified_ff[15]);
								 
			qualified_comb[16] = ((string_in_ff[135:128] == CHAR_SPACE)||(string_in_ff[135:128] == 0)) && (qualified_ff[16]);
			qualified_comb[17] = ((string_in_ff[143:136] == CHAR_SPACE)||(string_in_ff[143:136] == 0)) && (qualified_ff[17]);
			qualified_comb[18] = ((string_in_ff[151:144] == CHAR_SPACE)||(string_in_ff[151:144] == 0)) && (qualified_ff[18]);
			qualified_comb[19] = ((string_in_ff[159:152] == CHAR_SPACE)||(string_in_ff[159:152] == 0)) && (qualified_ff[19]);
			qualified_comb[20] = ((string_in_ff[167:160] == CHAR_SPACE)||(string_in_ff[167:160] == 0)) && (qualified_ff[20]);
			qualified_comb[21] = ((string_in_ff[175:168] == CHAR_SPACE)||(string_in_ff[175:168] == 0)) && (qualified_ff[21]);
			qualified_comb[22] = ((string_in_ff[183:176] == CHAR_SPACE)||(string_in_ff[183:176] == 0)) && (qualified_ff[22]);
			qualified_comb[23] = ((string_in_ff[191:184] == CHAR_SPACE)||(string_in_ff[191:184] == 0)) && (qualified_ff[23]);
								 
			qualified_comb[24] = ((string_in_ff[199:192] == CHAR_SPACE)||(string_in_ff[199:192] == 0)) && (qualified_ff[24]);
			qualified_comb[25] = ((string_in_ff[207:200] == CHAR_SPACE)||(string_in_ff[207:200] == 0)) && (qualified_ff[25]);
			qualified_comb[26] = ((string_in_ff[215:208] == CHAR_SPACE)||(string_in_ff[215:208] == 0)) && (qualified_ff[26]);
			qualified_comb[27] = ((string_in_ff[223:216] == CHAR_SPACE)||(string_in_ff[223:216] == 0)) && (qualified_ff[27]);
			qualified_comb[28] = ((string_in_ff[231:224] == CHAR_SPACE)||(string_in_ff[231:224] == 0)) && (qualified_ff[28]);
			qualified_comb[29] = ((string_in_ff[239:232] == CHAR_SPACE)||(string_in_ff[239:232] == 0)) && (qualified_ff[29]);
			qualified_comb[30] = ((string_in_ff[247:240] == CHAR_SPACE)||(string_in_ff[247:240] == 0)) && (qualified_ff[30]);
			qualified_comb[31] = ((string_in_ff[255:248] == CHAR_SPACE)||(string_in_ff[255:248] == 0)) && (qualified_ff[31]);
			
			TAILSEL_comb = 1;
			
		end
		
		
		else begin
			if(state_curr == PATIN)begin
			
				if(given_char_ff == CHAR_ARBIT)begin
					length_along_comb = length_along_ff + 8;
					
					qualified_comb[0 ] = ((string_in_ff[7  :  0] != 0) && (qualified_ff[0 ]));
					qualified_comb[1 ] = ((string_in_ff[15 :  8] != 0) && (qualified_ff[1 ]));
					qualified_comb[2 ] = ((string_in_ff[23 : 16] != 0) && (qualified_ff[2 ]));
					qualified_comb[3 ] = ((string_in_ff[31 : 24] != 0) && (qualified_ff[3 ]));
					qualified_comb[4 ] = ((string_in_ff[39 : 32] != 0) && (qualified_ff[4 ]));
					qualified_comb[5 ] = ((string_in_ff[47 : 40] != 0) && (qualified_ff[5 ]));
					qualified_comb[6 ] = ((string_in_ff[55 : 48] != 0) && (qualified_ff[6 ]));
					qualified_comb[7 ] = ((string_in_ff[63 : 56] != 0) && (qualified_ff[7 ]));
					qualified_comb[8 ] = ((string_in_ff[71 : 64] != 0) && (qualified_ff[8 ]));
					qualified_comb[9 ] = ((string_in_ff[79 : 72] != 0) && (qualified_ff[9 ]));
					qualified_comb[10] = ((string_in_ff[87 : 80] != 0) && (qualified_ff[10]));
					qualified_comb[11] = ((string_in_ff[95 : 88] != 0) && (qualified_ff[11]));
					qualified_comb[12] = ((string_in_ff[103: 96] != 0) && (qualified_ff[12]));
					qualified_comb[13] = ((string_in_ff[111:104] != 0) && (qualified_ff[13]));
					qualified_comb[14] = ((string_in_ff[119:112] != 0) && (qualified_ff[14]));
					qualified_comb[15] = ((string_in_ff[127:120] != 0) && (qualified_ff[15]));
					qualified_comb[16] = ((string_in_ff[135:128] != 0) && (qualified_ff[16]));
					qualified_comb[17] = ((string_in_ff[143:136] != 0) && (qualified_ff[17]));
					qualified_comb[18] = ((string_in_ff[151:144] != 0) && (qualified_ff[18]));
					qualified_comb[19] = ((string_in_ff[159:152] != 0) && (qualified_ff[19]));
					qualified_comb[20] = ((string_in_ff[167:160] != 0) && (qualified_ff[20]));
					qualified_comb[21] = ((string_in_ff[175:168] != 0) && (qualified_ff[21]));
					qualified_comb[22] = ((string_in_ff[183:176] != 0) && (qualified_ff[22]));
					qualified_comb[23] = ((string_in_ff[191:184] != 0) && (qualified_ff[23]));
					qualified_comb[24] = ((string_in_ff[199:192] != 0) && (qualified_ff[24]));
					qualified_comb[25] = ((string_in_ff[207:200] != 0) && (qualified_ff[25]));
					qualified_comb[26] = ((string_in_ff[215:208] != 0) && (qualified_ff[26]));
					qualified_comb[27] = ((string_in_ff[223:216] != 0) && (qualified_ff[27]));
					qualified_comb[28] = ((string_in_ff[231:224] != 0) && (qualified_ff[28]));
					qualified_comb[29] = ((string_in_ff[239:232] != 0) && (qualified_ff[29]));
					qualified_comb[30] = ((string_in_ff[247:240] != 0) && (qualified_ff[30]));
					qualified_comb[31] = ((string_in_ff[255:248] != 0) && (qualified_ff[31]));					
				end
				
				else begin
					qualified_comb[0 ] = ((string_in_ff[7  :  0] == given_char_ff) && (qualified_ff[0 ]));
					qualified_comb[1 ] = ((string_in_ff[15 :  8] == given_char_ff) && (qualified_ff[1 ]));
					qualified_comb[2 ] = ((string_in_ff[23 : 16] == given_char_ff) && (qualified_ff[2 ]));
					qualified_comb[3 ] = ((string_in_ff[31 : 24] == given_char_ff) && (qualified_ff[3 ]));
					qualified_comb[4 ] = ((string_in_ff[39 : 32] == given_char_ff) && (qualified_ff[4 ]));
					qualified_comb[5 ] = ((string_in_ff[47 : 40] == given_char_ff) && (qualified_ff[5 ]));
					qualified_comb[6 ] = ((string_in_ff[55 : 48] == given_char_ff) && (qualified_ff[6 ]));
					qualified_comb[7 ] = ((string_in_ff[63 : 56] == given_char_ff) && (qualified_ff[7 ]));
					qualified_comb[8 ] = ((string_in_ff[71 : 64] == given_char_ff) && (qualified_ff[8 ]));
					qualified_comb[9 ] = ((string_in_ff[79 : 72] == given_char_ff) && (qualified_ff[9 ]));
					qualified_comb[10] = ((string_in_ff[87 : 80] == given_char_ff) && (qualified_ff[10]));
					qualified_comb[11] = ((string_in_ff[95 : 88] == given_char_ff) && (qualified_ff[11]));
					qualified_comb[12] = ((string_in_ff[103: 96] == given_char_ff) && (qualified_ff[12]));
					qualified_comb[13] = ((string_in_ff[111:104] == given_char_ff) && (qualified_ff[13]));
					qualified_comb[14] = ((string_in_ff[119:112] == given_char_ff) && (qualified_ff[14]));
					qualified_comb[15] = ((string_in_ff[127:120] == given_char_ff) && (qualified_ff[15]));
					qualified_comb[16] = ((string_in_ff[135:128] == given_char_ff) && (qualified_ff[16]));
					qualified_comb[17] = ((string_in_ff[143:136] == given_char_ff) && (qualified_ff[17]));
					qualified_comb[18] = ((string_in_ff[151:144] == given_char_ff) && (qualified_ff[18]));
					qualified_comb[19] = ((string_in_ff[159:152] == given_char_ff) && (qualified_ff[19]));
					qualified_comb[20] = ((string_in_ff[167:160] == given_char_ff) && (qualified_ff[20]));
					qualified_comb[21] = ((string_in_ff[175:168] == given_char_ff) && (qualified_ff[21]));
					qualified_comb[22] = ((string_in_ff[183:176] == given_char_ff) && (qualified_ff[22]));
					qualified_comb[23] = ((string_in_ff[191:184] == given_char_ff) && (qualified_ff[23]));
					qualified_comb[24] = ((string_in_ff[199:192] == given_char_ff) && (qualified_ff[24]));
					qualified_comb[25] = ((string_in_ff[207:200] == given_char_ff) && (qualified_ff[25]));
					qualified_comb[26] = ((string_in_ff[215:208] == given_char_ff) && (qualified_ff[26]));
					qualified_comb[27] = ((string_in_ff[223:216] == given_char_ff) && (qualified_ff[27]));
					qualified_comb[28] = ((string_in_ff[231:224] == given_char_ff) && (qualified_ff[28]));
					qualified_comb[29] = ((string_in_ff[239:232] == given_char_ff) && (qualified_ff[29]));
					qualified_comb[30] = ((string_in_ff[247:240] == given_char_ff) && (qualified_ff[30]));
					qualified_comb[31] = ((string_in_ff[255:248] == given_char_ff) && (qualified_ff[31]));	
					
					length_along_comb = length_along_ff + 8;
				end
				
			end
			else begin
				valid_on_comb = 1;
				match_comb    = 0;
				for (int idx = 0; idx < 32; idx = idx + 1)begin
					if(qualified_ff[idx])begin
						//IDX_comb = (length_string_ff >> 3) - idx - 1 + HEADSEL_ff;
						IDX_comb = ((idx + 1 == (length_string_ff >> 3)) && HEADSEL_ff) ? (length_string_ff >> 3) - idx - 1 : (length_string_ff >> 3) - idx - 1 + HEADSEL_ff;
						match_comb = 1;
					end
				end
			end
		end
	end
	else begin
		qualified_comb = 32'hffff_ffff;
		length_along_comb = (state_curr == OUT) ? 0 : 0;
		HEADSEL_comb = 0;
		TAILSEL_comb = 0;
	end
end



always@(posedge reset or posedge clk)begin

	if(reset)begin
		qualified_ff 	<= 32'hffff_ffff;
		length_along_ff <= 0;
		valid_on_ff 	<= 0;
		match_ff        <= 0;
		IDX_ff          <= 0;
		HEADSEL_ff      <= 0;
		TAILSEL_ff      <= 0;
	end
	
	else begin
		qualified_ff 	<= qualified_comb;
		length_along_ff <= length_along_comb;
		valid_on_ff 	<= valid_on_comb;
		match_ff        <= match_comb;
		IDX_ff          <= IDX_comb;
		HEADSEL_ff      <= HEADSEL_comb;
		TAILSEL_ff      <= TAILSEL_comb;
	end

end

assign match = match_ff;
assign match_index = IDX_ff;
assign valid = valid_on_ff;
	
endmodule

