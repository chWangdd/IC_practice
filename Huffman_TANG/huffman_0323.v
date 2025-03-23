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

parameter INPUT_FILE  = 2'd0, 
		  INIT_INPUT  = 2'd1,
		  MASK        = 2'd3,
		  OUTPUT_FILE = 2'd2;
		  
		  
parameter PIX1  = 8'd1,
		  PIX2	= 8'd2,
		  PIX3	= 8'd3,
		  PIX4	= 8'd4,
		  PIX5	= 8'd5,
		  PIX6	= 8'd6;

reg [DATA_SIZE-1:0] Element_r [1:6];
reg [DATA_SIZE-1:0] Element_w [1:6];

reg [2:0] IDX_r [1:6];
reg [2:0] IDX_w [1:6];

reg [1:0] state_r, state_w;
reg [6:0] counter_r, counter_w;
reg [ADDR_SIZE-1:0] sram_a_r, sram_a_w;
reg [DATA_SIZE-1:0] sram_d_r, sram_d_w;
reg sram_wen_r, sram_wen_w;

reg [6:1] MASK_r [1:6];
reg [6:1] MASK_w [1:6];

reg [2:0] TIME_r [1:6];
reg [2:0] TIME_w [1:6];

reg finish_w, finish_r;

assign sram_a = sram_a_r;
assign sram_d = sram_d_r;
assign sram_wen = sram_wen_r;
assign finish = finish_r;

always@(posedge reset or posedge clk)begin: FF
	if(reset)begin
		Element_r[1] <= 0; IDX_r[1] <= 0; 
		Element_r[2] <= 0; IDX_r[2] <= 0; 
		Element_r[3] <= 0; IDX_r[3] <= 0; 
		Element_r[4] <= 0; IDX_r[4] <= 0; 
		Element_r[5] <= 0; IDX_r[5] <= 0; 
		Element_r[6] <= 0; IDX_r[6] <= 0; 
		sram_a_r    <= 0;
		sram_d_r    <= 0;
		sram_wen_r  <= 1;
		counter_r   <= 0;
		state_r     <= INPUT_FILE;
		finish_r    <= 0;
	end
	else begin
		Element_r[6] <= Element_w[6]; IDX_r[1] <= IDX_w[1]; 
		Element_r[5] <= Element_w[5]; IDX_r[2] <= IDX_w[2]; 
		Element_r[4] <= Element_w[4]; IDX_r[3] <= IDX_w[3]; 
		Element_r[3] <= Element_w[3]; IDX_r[4] <= IDX_w[4]; 
		Element_r[2] <= Element_w[2]; IDX_r[5] <= IDX_w[5]; 
		Element_r[1] <= Element_w[1]; IDX_r[6] <= IDX_w[6]; 
		
		sram_a_r    <= sram_a_w;
		sram_d_r    <= sram_d_w;
		sram_wen_r  <= sram_wen_w;
		counter_r   <= counter_w;
		state_r     <= state_w;
		finish_r    <= finish_w;
	end
end

always@(*)begin: FSM //Need FIXING
	state_w = state_r;
	case(state_r) 
		INPUT_FILE: begin
			state_w = (counter_r == 100) ? INIT_INPUT : INPUT_FILE;
		end
		INIT_INPUT: begin
			state_w = (counter_r == 10) ? MASK : INIT_INPUT;
		end
		MASK: begin
			state_w = (counter_r == 5) ? OUTPUT_FILE : MASK;
		end
		OUTPUT_FILE: begin
			state_w = (counter_r == 13) ? INPUT_FILE : OUTPUT_FILE;
		end
		default: begin
			state_w = INPUT_FILE;
		end
	endcase	
end

always@(*)begin: counter //Need FIXING 
	counter_w = counter_r;
	case(state_r)
		INPUT_FILE: begin
			counter_w = (counter_r == 100) ? 0 : counter_r + 1;
		end
		INIT_INPUT: begin
			counter_w = (counter_r == 10) ? 0 : counter_r + 1;
		end
		MASK: begin
			counter_w = (counter_r == 5) ? 0 : counter_r + 1;
		end
		OUTPUT_FILE: begin
			counter_w = (counter_r == 13) ?  0 : counter_r + 1;
		end
		default: begin
			counter_w = 0; 
		end
	endcase
end

always@(*)begin: ADDER_and_SORTER
	Element_w[1] = Element_r[1]; IDX_w[1] = IDX_r[1]; 
	Element_w[2] = Element_r[2]; IDX_w[2] = IDX_r[2]; 
	Element_w[3] = Element_r[3]; IDX_w[3] = IDX_r[3]; 
	Element_w[4] = Element_r[4]; IDX_w[4] = IDX_r[4]; 
	Element_w[5] = Element_r[5]; IDX_w[5] = IDX_r[5]; 
	Element_w[6] = Element_r[6]; IDX_w[6] = IDX_r[6]; 
	if((state_r == INPUT_FILE) && (counter_r))begin
		case(sram_q)
			PIX1:   Element_w[1] = Element_r[1] + 1;
			PIX2:   Element_w[2] = Element_r[2] + 1;
			PIX3:   Element_w[3] = Element_r[3] + 1;
			PIX4:   Element_w[4] = Element_r[4] + 1;
			PIX5:   Element_w[5] = Element_r[5] + 1;
			PIX6:   Element_w[6] = Element_r[6] + 1;
			default: ;
		endcase
		IDX_w[1] = 1;
		IDX_w[2] = 2;
		IDX_w[3] = 3;
		IDX_w[4] = 4;
		IDX_w[5] = 5;
		IDX_w[6] = 6;
	end
	else if(state_r == INIT_INPUT)begin
		case(counter_r)
			7'd6: begin
				Element_w[1] = (Element_r[2] > Element_r[1]) ? Element_r[2] : Element_r[1];
				Element_w[2] = (Element_r[2] > Element_r[1]) ? Element_r[1] : Element_r[2];
				Element_w[3] = (Element_r[4] > Element_r[3]) ? Element_r[4] : Element_r[3];
				Element_w[4] = (Element_r[4] > Element_r[3]) ? Element_r[3] : Element_r[4];
				Element_w[5] = (Element_r[6] > Element_r[5]) ? Element_r[6] : Element_r[5];
				Element_w[6] = (Element_r[6] > Element_r[5]) ? Element_r[5] : Element_r[6];
				IDX_w[1] = (Element_r[2] > Element_r[1]) ? IDX_r[2] : IDX_r[1];
				IDX_w[2] = (Element_r[2] > Element_r[1]) ? IDX_r[1] : IDX_r[2];
				IDX_w[3] = (Element_r[4] > Element_r[3]) ? IDX_r[4] : IDX_r[3];
				IDX_w[4] = (Element_r[4] > Element_r[3]) ? IDX_r[3] : IDX_r[4];
				IDX_w[5] = (Element_r[6] > Element_r[5]) ? IDX_r[6] : IDX_r[5];
				IDX_w[6] = (Element_r[6] > Element_r[5]) ? IDX_r[5] : IDX_r[6];
			end
			7'd7: begin
				Element_w[2] = (Element_r[3] > Element_r[2]) ? Element_r[3] : Element_r[2];
				Element_w[3] = (Element_r[3] > Element_r[2]) ? Element_r[2] : Element_r[3];
				Element_w[4] = (Element_r[5] > Element_r[4]) ? Element_r[5] : Element_r[4];
				Element_w[5] = (Element_r[5] > Element_r[4]) ? Element_r[4] : Element_r[5];
				IDX_w[5] = (Element_r[5] > Element_r[4]) ? IDX_r[4] : IDX_r[5];
				IDX_w[4] = (Element_r[5] > Element_r[4]) ? IDX_r[5] : IDX_r[4];
				IDX_w[3] = (Element_r[3] > Element_r[2]) ? IDX_r[2] : IDX_r[3];
				IDX_w[2] = (Element_r[3] > Element_r[2]) ? IDX_r[3] : IDX_r[2];
			end
			7'd8: begin
				Element_w[1] = (Element_r[2] > Element_r[1]) ? Element_r[2] : Element_r[1];
				Element_w[2] = (Element_r[2] > Element_r[1]) ? Element_r[1] : Element_r[2];
				Element_w[3] = (Element_r[4] > Element_r[3]) ? Element_r[4] : Element_r[3];
				Element_w[4] = (Element_r[4] > Element_r[3]) ? Element_r[3] : Element_r[4];
				Element_w[5] = (Element_r[6] > Element_r[5]) ? Element_r[6] : Element_r[5];
				Element_w[6] = (Element_r[6] > Element_r[5]) ? Element_r[5] : Element_r[6];
				IDX_w[6] = (Element_r[6] > Element_r[5]) ? IDX_r[5] : IDX_r[6];				
				IDX_w[5] = (Element_r[6] > Element_r[5]) ? IDX_r[6] : IDX_r[5];				
				IDX_w[4] = (Element_r[4] > Element_r[3]) ? IDX_r[3] : IDX_r[4];				
				IDX_w[3] = (Element_r[4] > Element_r[3]) ? IDX_r[4] : IDX_r[3];				
				IDX_w[2] = (Element_r[2] > Element_r[1]) ? IDX_r[1] : IDX_r[2];				
				IDX_w[1] = (Element_r[2] > Element_r[1]) ? IDX_r[2] : IDX_r[1];				
			end
			7'd9: begin
				Element_w[2] = (Element_r[3] > Element_r[2]) ? Element_r[3] : Element_r[2];
				Element_w[3] = (Element_r[3] > Element_r[2]) ? Element_r[2] : Element_r[3];
				Element_w[4] = (Element_r[5] > Element_r[4]) ? Element_r[5] : Element_r[4];
				Element_w[5] = (Element_r[5] > Element_r[4]) ? Element_r[4] : Element_r[5];
				IDX_w[5] = (Element_r[5] > Element_r[4]) ? IDX_r[4] : IDX_r[5];
				IDX_w[4] = (Element_r[5] > Element_r[4]) ? IDX_r[5] : IDX_r[4];
				IDX_w[3] = (Element_r[3] > Element_r[2]) ? IDX_r[2] : IDX_r[3];
				IDX_w[2] = (Element_r[3] > Element_r[2]) ? IDX_r[3] : IDX_r[2];		
			end
			7'd10: begin
				Element_w[1] = (Element_r[2] > Element_r[1]) ? Element_r[2] : Element_r[1];
				Element_w[2] = (Element_r[2] > Element_r[1]) ? Element_r[1] : Element_r[2];
				Element_w[3] = (Element_r[4] > Element_r[3]) ? Element_r[4] : Element_r[3];
				Element_w[4] = (Element_r[4] > Element_r[3]) ? Element_r[3] : Element_r[4];
				Element_w[5] = (Element_r[6] > Element_r[5]) ? Element_r[6] : Element_r[5];
				Element_w[6] = (Element_r[6] > Element_r[5]) ? Element_r[5] : Element_r[6];
				IDX_w[6] = (Element_r[6] > Element_r[5]) ? IDX_r[5] : IDX_r[6];				
				IDX_w[5] = (Element_r[6] > Element_r[5]) ? IDX_r[6] : IDX_r[5];				
				IDX_w[4] = (Element_r[4] > Element_r[3]) ? IDX_r[3] : IDX_r[4];				
				IDX_w[3] = (Element_r[4] > Element_r[3]) ? IDX_r[4] : IDX_r[3];				
				IDX_w[2] = (Element_r[2] > Element_r[1]) ? IDX_r[1] : IDX_r[2];				
				IDX_w[1] = (Element_r[2] > Element_r[1]) ? IDX_r[2] : IDX_r[1];				
			end
			default: begin
			
			end
		endcase
	end
end

always@(*)begin: OUTPUT_MODE
	sram_a_w = sram_a_r;	
	sram_d_w = sram_d_r;	
	sram_wen_w = sram_wen_r;
	finish_w = 0;
	if(state_r == INPUT_FILE)begin
		sram_a_w = 8'd1 + counter_r;
		sram_d_w = 0;
		sram_wen_w = 1;
	end
	else if(state_r == INIT_INPUT)begin
		sram_a_w = 8'd128 + counter_r;
		case(counter_r)
			7'd0: begin
				sram_d_w = Element_r[1];
				sram_wen_w = 0;	
			end
			7'd1: begin
				sram_d_w = Element_r[2];
				sram_wen_w = 0;
			end
			7'd2: begin
				sram_d_w = Element_r[3];
				sram_wen_w = 0;
			end
			7'd3: begin
				sram_d_w = Element_r[4];
				sram_wen_w = 0;
			end
			7'd4: begin
				sram_d_w = Element_r[5];
				sram_wen_w = 0;
			end
			7'd5: begin
				sram_d_w = Element_r[6];
				sram_wen_w = 0;
			end
			default: begin
				sram_d_w = 0;
				sram_wen_w = 1;			
			end
		endcase
	end
	else if(state_r == OUTPUT_FILE)begin
		sram_a_w = 134 + counter_r;
		case(counter_r)
			7'd0: begin
				sram_d_w = MASK_r[1];
				sram_wen_w = 0;
			end
			7'd1: begin
				sram_d_w = MASK_r[2];
				sram_wen_w = 0;
			end
			7'd2: begin
				sram_d_w = MASK_r[3];
				sram_wen_w = 0;
			end
			7'd3: begin
				sram_d_w = MASK_r[4];
				sram_wen_w = 0;
			end
			7'd4: begin
				sram_d_w = MASK_r[5];
				sram_wen_w = 0;
			end
			7'd5: begin
				sram_d_w = MASK_r[6];
				sram_wen_w = 0;			
			end
			7'd6: begin
				sram_d_w = (TIME_r[1] == 1) ? 1 : (TIME_r[1] == 2) ? 3 : (TIME_r[1] == 3) ? 7 : (TIME_r[1] == 4) ? 15 : (TIME_r[1] == 5) ? 31 : 63;
				sram_wen_w = 0;
			end
			7'd7: begin
				sram_d_w = (TIME_r[2] == 1) ? 1 : (TIME_r[2] == 2) ? 3 : (TIME_r[2] == 3) ? 7 : (TIME_r[2] == 4) ? 15 : (TIME_r[2] == 5) ? 31 : 63;
				sram_wen_w = 0;
			end
			7'd8: begin
				sram_d_w = (TIME_r[3] == 1) ? 1 : (TIME_r[3] == 2) ? 3 : (TIME_r[3] == 3) ? 7 : (TIME_r[3] == 4) ? 15 : (TIME_r[3] == 5) ? 31 : 63;
				sram_wen_w = 0;
			end
			7'd9: begin
				sram_d_w = (TIME_r[4] == 1) ? 1 : (TIME_r[4] == 2) ? 3 : (TIME_r[4] == 3) ? 7 : (TIME_r[4] == 4) ? 15 : (TIME_r[4] == 5) ? 31 : 63;
				sram_wen_w = 0;
			end
			7'd10: begin
				sram_d_w = (TIME_r[5] == 1) ? 1 : (TIME_r[5] == 2) ? 3 : (TIME_r[5] == 3) ? 7 : (TIME_r[5] == 4) ? 15 : (TIME_r[5] == 5) ? 31 : 63;
				sram_wen_w = 0;
			end
			7'd11: begin
				sram_d_w = (TIME_r[6] == 1) ? 1 : (TIME_r[6] == 2) ? 3 : (TIME_r[6] == 3) ? 7 : (TIME_r[6] == 4) ? 15 : (TIME_r[6] == 5) ? 31 : 63;
				sram_wen_w = 0;
				finish_w = 1;
			end
			7'd12: begin
				sram_d_w = MASK_r[6];
				sram_wen_w = 1;
			end
		endcase
	end
end

reg [DATA_SIZE-1:0] Sorted_Element_r [1:6];
reg [DATA_SIZE-1:0] Sorted_Element_w [1:6];

reg [2:0] SORTED_IDX_r [1:6];
reg [2:0] SORTED_IDX_w [1:6];

reg [6:1] QUEUE_IDX_LIST_r [1:3];
reg [6:1] QUEUE_IDX_LIST_w [1:3];

reg [6:0] QUEUE_VALUE_r [1:3];
reg [6:0] QUEUE_VALUE_w [1:3];

integer i, j, k;

always@(*)begin: SORT_MODULE
	for(i = 1; i <= 6; i = i + 1)begin
		MASK_w[i]           = MASK_r[i]; 
		TIME_w[i]           = TIME_r[i];
		Sorted_Element_w[i] = Sorted_Element_r[i]; 
		SORTED_IDX_w[i]     = SORTED_IDX_r[i];
	end
	for (j = 1; j <= 3; j = j + 1)begin
		QUEUE_IDX_LIST_w[j] = QUEUE_IDX_LIST_r[j];
		QUEUE_VALUE_w[j]    = QUEUE_VALUE_r[j]; 	
	end
	if(state_r == MASK)begin
		case(counter_r)
			7'd0: begin
				for(i = 1; i <= 6; i = i + 1)begin
					MASK_w[i] = 0;
					TIME_w[i] = 0;
					Sorted_Element_w[i] = Element_r[i];
					SORTED_IDX_w[i] = IDX_r[i];
				end
				for (j = 1; j <= 3; j = j + 1)begin
					QUEUE_IDX_LIST_w[j] = 0;
					QUEUE_VALUE_w[j]    = 101; 	
				end
			end
			default: begin
				if((QUEUE_VALUE_r[3] <= Sorted_Element_r[6]) && (QUEUE_VALUE_r[2] <= Sorted_Element_r[6]))begin
					QUEUE_VALUE_w[1] = 101; 
					QUEUE_IDX_LIST_w[1] = 0;
					QUEUE_VALUE_w[2] = (QUEUE_VALUE_r[1] >= QUEUE_VALUE_r[2] + QUEUE_VALUE_r[3]) ? QUEUE_VALUE_r[1] : QUEUE_VALUE_r[2] + QUEUE_VALUE_r[3];
					QUEUE_VALUE_w[3] = (QUEUE_VALUE_r[1] >= QUEUE_VALUE_r[2] + QUEUE_VALUE_r[3]) ? QUEUE_VALUE_r[2] + QUEUE_VALUE_r[3] : QUEUE_VALUE_r[1];
					QUEUE_IDX_LIST_w[2] = (QUEUE_VALUE_r[1] >= QUEUE_VALUE_r[2] + QUEUE_VALUE_r[3]) ? QUEUE_IDX_LIST_r[1] : QUEUE_IDX_LIST_r[3] | QUEUE_IDX_LIST_r[2];
					QUEUE_IDX_LIST_w[3] = (QUEUE_VALUE_r[1] >= QUEUE_IDX_LIST_r[2] + QUEUE_IDX_LIST_r[3]) ? QUEUE_IDX_LIST_r[3] | QUEUE_IDX_LIST_r[2] : QUEUE_IDX_LIST_r[1];
					for(k = 1; k <= 6; k = k + 1)begin
						if(QUEUE_IDX_LIST_r[3][k])begin
							TIME_w[k] = TIME_r[k] + 1;
							case(TIME_r[k])
								3'd1: MASK_w[k] = MASK_r[k] + 2;
								3'd2: MASK_w[k] = MASK_r[k] + 4;
								3'd3: MASK_w[k] = MASK_r[k] + 8;
								3'd4: MASK_w[k] = MASK_r[k] + 16;
								3'd5: MASK_w[k] = MASK_r[k] + 32;
								default: MASK_w[k] = MASK_r[k];
							endcase
						end
						else if(QUEUE_IDX_LIST_r[2][k])begin
							TIME_w[k] = TIME_r[k] + 1;
						end
					end
				end
				else if (!(QUEUE_VALUE_r[3] <= Sorted_Element_r[6]) && !(QUEUE_VALUE_r[3] <= Sorted_Element_r[5]))begin
					Sorted_Element_w[1] = 101;				   SORTED_IDX_w[1] = 0;
					Sorted_Element_w[2] = 101;				   SORTED_IDX_w[2] = 0;
					Sorted_Element_w[3] = Sorted_Element_r[1]; SORTED_IDX_w[3] = SORTED_IDX_r[1];
					Sorted_Element_w[4] = Sorted_Element_r[2]; SORTED_IDX_w[4] = SORTED_IDX_r[2];
					Sorted_Element_w[5] = Sorted_Element_r[3]; SORTED_IDX_w[5] = SORTED_IDX_r[3];
					Sorted_Element_w[6] = Sorted_Element_r[4]; SORTED_IDX_w[6] = SORTED_IDX_r[4];
					if(QUEUE_VALUE_r[2] < Sorted_Element_r[6] + Sorted_Element_r[5])begin
						QUEUE_VALUE_w[1] = Sorted_Element_r[5] + Sorted_Element_r[6];
						case(SORTED_IDX_r[5])
							3'd1: QUEUE_IDX_LIST_w[1] = QUEUE_IDX_LIST_r[1] + 1;
							3'd2: QUEUE_IDX_LIST_w[1] = QUEUE_IDX_LIST_r[1] + 2;
							3'd3: QUEUE_IDX_LIST_w[1] = QUEUE_IDX_LIST_r[1] + 4;
							3'd4: QUEUE_IDX_LIST_w[1] = QUEUE_IDX_LIST_r[1] + 8;
							3'd5: QUEUE_IDX_LIST_w[1] = QUEUE_IDX_LIST_r[1] + 16;
							3'd6: QUEUE_IDX_LIST_w[1] = QUEUE_IDX_LIST_r[1] + 32;
							default: QUEUE_IDX_LIST_w[1] = QUEUE_IDX_LIST_r[1];
						endcase
						case(SORTED_IDX_r[6])
							3'd1: QUEUE_IDX_LIST_w[1] = QUEUE_IDX_LIST_w[1] + 1;
							3'd2: QUEUE_IDX_LIST_w[1] = QUEUE_IDX_LIST_w[1] + 2;
							3'd3: QUEUE_IDX_LIST_w[1] = QUEUE_IDX_LIST_w[1] + 4;
							3'd4: QUEUE_IDX_LIST_w[1] = QUEUE_IDX_LIST_w[1] + 8;
							3'd5: QUEUE_IDX_LIST_w[1] = QUEUE_IDX_LIST_w[1] + 16;
							3'd6: QUEUE_IDX_LIST_w[1] = QUEUE_IDX_LIST_w[1] + 32;
							default: QUEUE_IDX_LIST_w[1] = QUEUE_IDX_LIST_r[1];
						endcase
					end
					else if(QUEUE_VALUE_r[3] >= Sorted_Element_r[6] + Sorted_Element_r[5])begin
						QUEUE_VALUE_w[3] = Sorted_Element_r[5] + Sorted_Element_r[6];
						QUEUE_VALUE_w[2] = QUEUE_VALUE_r[3]; QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_r[3];
						QUEUE_VALUE_w[1] = QUEUE_VALUE_r[2]; QUEUE_IDX_LIST_w[1] = QUEUE_IDX_LIST_r[2];
						case(SORTED_IDX_r[6])
							3'd1: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_r[1] + 1;
							3'd2: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_r[1] + 2;
							3'd3: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_r[1] + 4;
							3'd4: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_r[1] + 8;
							3'd5: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_r[1] + 16;
							3'd6: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_r[1] + 32;
							default: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_r[1];
						endcase
						case(SORTED_IDX_r[5])
							3'd1: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_w[3] + 1;
							3'd2: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_w[3] + 2;
							3'd3: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_w[3] + 4;
							3'd4: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_w[3] + 8;
							3'd5: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_w[3] + 16;
							3'd6: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_w[3] + 32;
							default: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_r[1];
						endcase
					end
					else begin
						QUEUE_VALUE_w[2] = Sorted_Element_r[5] + Sorted_Element_r[6];
						QUEUE_VALUE_w[1] = QUEUE_VALUE_r[2]; QUEUE_IDX_LIST_w[1] = QUEUE_IDX_LIST_r[2];
						case(SORTED_IDX_r[6])
							3'd1: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_r[1] + 1;
							3'd2: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_r[1] + 2;
							3'd3: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_r[1] + 4;
							3'd4: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_r[1] + 8;
							3'd5: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_r[1] + 16;
							3'd6: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_r[1] + 32;
							default: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_r[1];
						endcase
						case(SORTED_IDX_r[5])
							3'd1: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_w[2] + 1;
							3'd2: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_w[2] + 2;
							3'd3: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_w[2] + 4;
							3'd4: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_w[2] + 8;
							3'd5: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_w[2] + 16;
							3'd6: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_w[2] + 32;
							default: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_r[1];
						endcase					
					end	
					case(SORTED_IDX_r[5])
						3'd1: begin		TIME_w[1] = 1; end
						3'd2: begin		TIME_w[2] = 1; end
						3'd3: begin		TIME_w[3] = 1; end
						3'd4: begin		TIME_w[4] = 1; end
						3'd5: begin		TIME_w[5] = 1; end
						3'd6: begin		TIME_w[6] = 1; end
						default: begin	end
					endcase
					case(SORTED_IDX_r[6])
						3'd1: begin		TIME_w[1] = 1; MASK_w[1] = 1; end
						3'd2: begin		TIME_w[2] = 1; MASK_w[2] = 1; end
						3'd3: begin		TIME_w[3] = 1; MASK_w[3] = 1; end
						3'd4: begin		TIME_w[4] = 1; MASK_w[4] = 1; end
						3'd5: begin		TIME_w[5] = 1; MASK_w[5] = 1; end
						3'd6: begin		TIME_w[6] = 1; MASK_w[6] = 1; end
					endcase
				end
				else begin
					if(QUEUE_VALUE_r[2] < QUEUE_VALUE_r[3] + Sorted_Element_r[6])begin
						QUEUE_VALUE_w[2] = QUEUE_VALUE_r[3] + Sorted_Element_r[6];
						QUEUE_VALUE_w[3] = QUEUE_VALUE_r[2]; QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_r[2];
						case(SORTED_IDX_r[6])
							3'd1: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_r[3] + 1;
							3'd2: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_r[3] + 2;
							3'd3: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_r[3] + 4;
							3'd4: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_r[3] + 8;
							3'd5: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_r[3] + 16;
							3'd6: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_r[3] + 32;
							default: QUEUE_IDX_LIST_w[2] = QUEUE_IDX_LIST_r[3];
						endcase
					end
					else begin
						QUEUE_VALUE_w[3] = QUEUE_VALUE_r[3] + Sorted_Element_r[6];
						case(SORTED_IDX_r[6])
							3'd1: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_r[3] + 1;
							3'd2: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_r[3] + 2;
							3'd3: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_r[3] + 4;
							3'd4: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_r[3] + 8;
							3'd5: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_r[3] + 16;
							3'd6: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_r[3] + 32;
							default: QUEUE_IDX_LIST_w[3] = QUEUE_IDX_LIST_r[3];
						endcase						
					end
					if((QUEUE_VALUE_r[3] <= Sorted_Element_r[6]) && !(QUEUE_VALUE_r[2] <= Sorted_Element_r[6]))begin
						for(i = 1; i <= 6; i = i + 1)begin
							if(QUEUE_IDX_LIST_r[3][i])begin
								TIME_w[i] = TIME_r[i] + 1;
								case(TIME_r[i])
									3'd1: MASK_w[i] = MASK_r[i] + 2;
									3'd2: MASK_w[i] = MASK_r[i] + 4;
									3'd3: MASK_w[i] = MASK_r[i] + 8;
									3'd4: MASK_w[i] = MASK_r[i] + 16;
									3'd5: MASK_w[i] = MASK_r[i] + 32;
									default: MASK_w[i] = MASK_r[i];
								endcase 
							end
						end
						case(SORTED_IDX_r[6])
							3'd1: TIME_w[1] = 1;
							3'd2: TIME_w[2] = 1;
							3'd3: TIME_w[3] = 1;
							3'd4: TIME_w[4] = 1;
							3'd5: TIME_w[5] = 1;
							3'd6: TIME_w[6] = 1;
							default: ;
						endcase
					end
					else begin
						for(i = 1; i <= 6; i = i + 1)begin
							if(QUEUE_IDX_LIST_r[3][i])begin
								TIME_w[i] = TIME_r[i] + 1;
							end
						end
						case(SORTED_IDX_r[6])
							3'd1: begin TIME_w[1] = 1; MASK_w[1] = 1; end
							3'd2: begin TIME_w[2] = 1; MASK_w[2] = 1; end
							3'd3: begin TIME_w[3] = 1; MASK_w[3] = 1; end
							3'd4: begin TIME_w[4] = 1; MASK_w[4] = 1; end
							3'd5: begin TIME_w[5] = 1; MASK_w[5] = 1; end
							3'd6: begin TIME_w[6] = 1; MASK_w[6] = 1; end
							default: ;
						endcase						
					end
					SORTED_IDX_w[2] = SORTED_IDX_r[1]; Sorted_Element_w[2] = Sorted_Element_r[1];
					SORTED_IDX_w[3] = SORTED_IDX_r[2]; Sorted_Element_w[3] = Sorted_Element_r[2];
					SORTED_IDX_w[4] = SORTED_IDX_r[3]; Sorted_Element_w[4] = Sorted_Element_r[3];
					SORTED_IDX_w[5] = SORTED_IDX_r[4]; Sorted_Element_w[5] = Sorted_Element_r[4];
					SORTED_IDX_w[6] = SORTED_IDX_r[5]; Sorted_Element_w[6] = Sorted_Element_r[5];
					SORTED_IDX_w[1] = 0; Sorted_Element_w[1] = 101;
				end
			end
		endcase
	end
end

always@(posedge reset or posedge clk)begin: FF_SORT
	if(reset)begin
		for(i = 1; i <= 6; i = i + 1)begin
			MASK_r[i]                 <= 0; 
			TIME_r[i]                 <= 0;
			Sorted_Element_r[i]       <= 0;
			SORTED_IDX_r[i]           <= 0;
		end
		for(j = 1; j <= 3; j = j + 1)begin
			QUEUE_IDX_LIST_r[j]       <= 0;
			QUEUE_VALUE_r[j]          <= 0;		
		end
	end
	else begin
		for(i = 1; i <= 6; i = i + 1)begin
			MASK_r[i]                 <= MASK_w[i]; 
			TIME_r[i]                 <= TIME_w[i];
			Sorted_Element_r[i]       <= Sorted_Element_w[i]; 
			SORTED_IDX_r[i]           <= SORTED_IDX_w[i];
		end
		for(j = 1; j <= 3; j = j + 1)begin
			QUEUE_IDX_LIST_r[j]       <= QUEUE_IDX_LIST_w[j];
			QUEUE_VALUE_r[j]          <= QUEUE_VALUE_w[j]; 		
		end
	end
end

endmodule