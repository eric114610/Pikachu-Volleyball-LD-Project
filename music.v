`define silence   32'd50000000

module note_gen(
    clk, // clock from crystal
    rst, // active high reset
    volume, 
    note_div_left, // div for note generation
    note_div_right,
    audio_left,
    audio_right
);

    // I/O declaration
    input clk; // clock from crystal
    input rst; // active low reset
    input [2:0] volume;
    input [21:0] note_div_left, note_div_right; // div for note generation
    output [15:0] audio_left, audio_right;

    // Declare internal signals
    reg [21:0] clk_cnt_next, clk_cnt;
    reg [21:0] clk_cnt_next_2, clk_cnt_2;
    reg b_clk, b_clk_next;
    reg c_clk, c_clk_next;

    // Note frequency generation
    // clk_cnt, clk_cnt_2, b_clk, c_clk
    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            begin
                clk_cnt <= 22'd0;
                clk_cnt_2 <= 22'd0;
                b_clk <= 1'b0;
                c_clk <= 1'b0;
            end
        else
            begin
                clk_cnt <= clk_cnt_next;
                clk_cnt_2 <= clk_cnt_next_2;
                b_clk <= b_clk_next;
                c_clk <= c_clk_next;
            end
    
    // clk_cnt_next, b_clk_next
    always @*
        if (clk_cnt == note_div_left)
            begin
                clk_cnt_next = 22'd0;
                b_clk_next = ~b_clk;
            end
        else
            begin
                clk_cnt_next = clk_cnt + 1'b1;
                b_clk_next = b_clk;
            end

    // clk_cnt_next_2, c_clk_next
    always @*
        if (clk_cnt_2 == note_div_right)
            begin
                clk_cnt_next_2 = 22'd0;
                c_clk_next = ~c_clk;
            end
        else
            begin
                clk_cnt_next_2 = clk_cnt_2 + 1'b1;
                c_clk_next = c_clk;
            end

    // Assign the amplitude of the note
    // Volume is controlled here

    reg [15:0] real_vol_p;
    reg [15:0] real_vol_m;
    always @(*) begin
            case (volume)
                1: real_vol_p = 16'h8000;//16'h0400;
                2: real_vol_p = 16'h0800;
                3: real_vol_p = 16'h1000;
                4: real_vol_p = 16'h2000;
                5: real_vol_p = 16'h4000;
                default: real_vol_p = 16'h8000;
            endcase
    end

    always @(*) begin
            case (volume)
                1: real_vol_m = 16'h8000;//16'hFC00;
                2: real_vol_m = 16'hF800;
                3: real_vol_m = 16'hF000;
                4: real_vol_m = 16'hE000;
                5: real_vol_m = 16'hC000;
                default: real_vol_m = 16'h8000;
            endcase
    end

    assign audio_left = (note_div_left == 22'd1) ? 16'h0000 : 
                                (b_clk == 1'b0) ? real_vol_m : real_vol_p;
    assign audio_right = (note_div_right == 22'd1) ? 16'h0000 : 
                                (c_clk == 1'b0) ? real_vol_m : real_vol_p;

endmodule

module player_control (
	input clk, 
	input reset, 
    input [3:0] state,
	output reg [11:0] ibeat
);
	parameter LEN = 3584;
    reg [11:0] next_ibeat;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			ibeat <= 3600;
		end else begin
            if(state != 0)
                ibeat <= next_ibeat;
            else
                ibeat <= 3600;
		end
	end

    always @* begin
        next_ibeat = (ibeat == 3600) ? 0 : (ibeat + 1 < LEN) ? (ibeat + 1) : 1280;	
    end

endmodule

module speaker_control(
    clk,  // clock from the crystal
    rst,  // active high reset
    audio_in_left, // left channel audio data input
    audio_in_right, // right channel audio data input
    audio_mclk, // master clock
    audio_lrck, // left-right clock, Word Select clock, or sample rate clock
    audio_sck, // serial clock
    audio_sdin // serial audio data input
);

    // I/O declaration
    input clk;  // clock from the crystal
    input rst;  // active high reset
    input [15:0] audio_in_left; // left channel audio data input
    input [15:0] audio_in_right; // right channel audio data input
    output audio_mclk; // master clock
    output audio_lrck; // left-right clock
    output audio_sck; // serial clock
    output audio_sdin; // serial audio data input
    reg audio_sdin;

    // Declare internal signal nodes 
    wire [8:0] clk_cnt_next;
    reg [8:0] clk_cnt;
    reg [15:0] audio_left, audio_right;

    // Counter for the clock divider
    assign clk_cnt_next = clk_cnt + 1'b1;

    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            clk_cnt <= 9'd0;
        else
            clk_cnt <= clk_cnt_next;

    // Assign divided clock output
    assign audio_mclk = clk_cnt[1];
    assign audio_lrck = clk_cnt[8];
    assign audio_sck = 1'b1; // use internal serial clock mode

    // audio input data buffer
    always @(posedge clk_cnt[8] or posedge rst)
        if (rst == 1'b1)
            begin
                audio_left <= 16'd0;
                audio_right <= 16'd0;
            end
        else
            begin
                audio_left <= audio_in_left;
                audio_right <= audio_in_right;
            end

    always @*
        case (clk_cnt[8:4])
            5'b00000: audio_sdin = audio_right[0];
            5'b00001: audio_sdin = audio_left[15];
            5'b00010: audio_sdin = audio_left[14];
            5'b00011: audio_sdin = audio_left[13];
            5'b00100: audio_sdin = audio_left[12];
            5'b00101: audio_sdin = audio_left[11];
            5'b00110: audio_sdin = audio_left[10];
            5'b00111: audio_sdin = audio_left[9];
            5'b01000: audio_sdin = audio_left[8];
            5'b01001: audio_sdin = audio_left[7];
            5'b01010: audio_sdin = audio_left[6];
            5'b01011: audio_sdin = audio_left[5];
            5'b01100: audio_sdin = audio_left[4];
            5'b01101: audio_sdin = audio_left[3];
            5'b01110: audio_sdin = audio_left[2];
            5'b01111: audio_sdin = audio_left[1];
            5'b10000: audio_sdin = audio_left[0];
            5'b10001: audio_sdin = audio_right[15];
            5'b10010: audio_sdin = audio_right[14];
            5'b10011: audio_sdin = audio_right[13];
            5'b10100: audio_sdin = audio_right[12];
            5'b10101: audio_sdin = audio_right[11];
            5'b10110: audio_sdin = audio_right[10];
            5'b10111: audio_sdin = audio_right[9];
            5'b11000: audio_sdin = audio_right[8];
            5'b11001: audio_sdin = audio_right[7];
            5'b11010: audio_sdin = audio_right[6];
            5'b11011: audio_sdin = audio_right[5];
            5'b11100: audio_sdin = audio_right[4];
            5'b11101: audio_sdin = audio_right[3];
            5'b11110: audio_sdin = audio_right[2];
            5'b11111: audio_sdin = audio_right[1];
            default: audio_sdin = 1'b0;
        endcase

endmodule

`define sil   32'd50000000 // slience

`define d3   32'd1175
`define c3B   32'd1109

`define b2   32'd988
`define a2B   32'd932
`define a2   32'd880
`define a2b   32'd831
`define g2   32'd784
`define g2b   32'd740
`define f2B   32'd740
`define f2   32'd698
`define e2   32'd659
`define d2B   32'd622
`define d2   32'd587
`define d2b   32'd554
`define c2B   32'd554
`define c2   32'd523

`define b1   32'd494
`define a1B   32'd466
`define a1   32'd440
`define g1B   32'd415
`define g1   32'd392
`define f1B   32'd370
`define f1   32'd349
`define e1   32'd330
`define d1B   32'd311
`define d1   32'd294
`define c1B   32'd277
`define c1   32'd262

`define b0   32'd247
`define b0b   32'd233
`define a0   32'd220
`define a0b   32'd208
`define g0   32'd196
`define g0b   32'd185
`define f0B   32'd185
`define f0   32'd175
`define f0b   32'd165
`define e0   32'd165
`define e0b   32'd156
`define d0   32'd147
`define d0b   32'd139
`define c0B   32'd139
`define c0   32'd131

`define B   32'd123
`define A   32'd110
`define Ab   32'd104
`define C   32'd65

module music_example (
	input [11:0] ibeatNum,
	output reg [31:0] toneL,
    output reg [31:0] toneR
);

    always @* begin
            case(ibeatNum)
                // --- Measure 1 ---
                12'd0: toneR = `a2; 12'd1: toneR = `a2;
                12'd2: toneR = `a2; 12'd3: toneR = `a2;
                12'd4: toneR = `a2; 12'd5: toneR = `a2;
                12'd6: toneR = `a2; 12'd7: toneR = `a2;
                
                12'd8: toneR = `a2b; 12'd9: toneR = `a2b;
                12'd10: toneR = `a2b; 12'd11: toneR = `a2b;
                12'd12: toneR = `a2b; 12'd13: toneR = `a2b;
                12'd14: toneR = `a2b; 12'd15: toneR = `a2b;

                12'd16: toneR = `g2; 12'd17: toneR = `g2;
                12'd18: toneR = `g2; 12'd19: toneR = `g2;
                12'd20: toneR = `g2; 12'd21: toneR = `g2;
                12'd22: toneR = `g2; 12'd23: toneR = `g2;

                12'd24: toneR = `g2b; 12'd25: toneR = `g2b;
                12'd26: toneR = `g2b; 12'd27: toneR = `g2b;
                12'd28: toneR = `g2b; 12'd29: toneR = `g2b;
                12'd30: toneR = `g2b; 12'd31: toneR = `g2b;

                12'd32: toneR = `a2; 12'd33: toneR = `a2;
                12'd34: toneR = `a2; 12'd35: toneR = `a2;
                12'd36: toneR = `a2; 12'd37: toneR = `a2;
                12'd38: toneR = `a2; 12'd39: toneR = `a2;

                12'd40: toneR = `e2; 12'd41: toneR = `e2;
                12'd42: toneR = `e2; 12'd43: toneR = `e2;
                12'd44: toneR = `e2; 12'd45: toneR = `e2;
                12'd46: toneR = `e2; 12'd47: toneR = `e2;

                12'd48: toneR = `f2; 12'd49: toneR = `f2;
                12'd50: toneR = `f2; 12'd51: toneR = `f2;
                12'd52: toneR = `f2; 12'd53: toneR = `f2;
                12'd54: toneR = `f2; 12'd55: toneR = `f2;

                12'd56: toneR = `e2; 12'd57: toneR = `e2;
                12'd58: toneR = `e2; 12'd59: toneR = `e2;
                12'd60: toneR = `e2; 12'd61: toneR = `e2;
                12'd62: toneR = `e2; 12'd63: toneR = `e2;

                12'd64: toneR = `a2; 12'd65: toneR = `a2;
                12'd66: toneR = `a2; 12'd67: toneR = `a2;
                12'd68: toneR = `a2; 12'd69: toneR = `a2;
                12'd70: toneR = `a2; 12'd71: toneR = `a2;

                12'd72: toneR = `d2B; 12'd73: toneR = `d2B;
                12'd74: toneR = `d2B; 12'd75: toneR = `d2B;
                12'd76: toneR = `d2B; 12'd77: toneR = `d2B;
                12'd78: toneR = `d2B; 12'd79: toneR = `d2B;

                12'd80: toneR = `e2; 12'd81: toneR = `e2;
                12'd82: toneR = `e2; 12'd83: toneR = `e2;
                12'd84: toneR = `e2; 12'd85: toneR = `e2;
                12'd86: toneR = `e2; 12'd87: toneR = `e2;

                12'd88: toneR = `d2; 12'd89: toneR = `d2;
                12'd90: toneR = `d2; 12'd91: toneR = `d2;
                12'd92: toneR = `d2; 12'd93: toneR = `d2;
                12'd94: toneR = `d2; 12'd95: toneR = `d2;

                12'd96: toneR = `a2; 12'd97: toneR = `a2;
                12'd98: toneR = `a2; 12'd99: toneR = `a2;
                12'd100: toneR = `a2; 12'd101: toneR = `a2;
                12'd102: toneR = `a2; 12'd103: toneR = `a2;

                12'd104: toneR = `d2; 12'd105: toneR = `d2;
                12'd106: toneR = `d2; 12'd107: toneR = `d2;
                12'd108: toneR = `d2; 12'd109: toneR = `d2;
                12'd110: toneR = `d2; 12'd111: toneR = `d2;

                12'd112: toneR = `e2; 12'd113: toneR = `e2;
                12'd114: toneR = `e2; 12'd115: toneR = `e2;
                12'd116: toneR = `e2; 12'd117: toneR = `e2;
                12'd118: toneR = `e2; 12'd119: toneR = `e2;

                12'd120: toneR = `d2; 12'd121: toneR = `d2;
                12'd122: toneR = `d2; 12'd123: toneR = `d2;
                12'd124: toneR = `d2; 12'd125: toneR = `d2;
                12'd126: toneR = `d2; 12'd127: toneR = `d2;

                // --- Measure 2 ---
                12'd128: toneR = `a2; 12'd129: toneR = `a2;
                12'd130: toneR = `a2; 12'd131: toneR = `a2;
                12'd132: toneR = `a2; 12'd133: toneR = `a2;
                12'd134: toneR = `a2; 12'd135: toneR = `a2;

                12'd136: toneR = `c2B; 12'd137: toneR = `c2B;
                12'd138: toneR = `c2B; 12'd139: toneR = `c2B;
                12'd140: toneR = `c2B; 12'd141: toneR = `c2B;
                12'd142: toneR = `c2B; 12'd143: toneR = `c2B;

                12'd144: toneR = `d2; 12'd145: toneR = `d2;
                12'd146: toneR = `d2; 12'd147: toneR = `d2;
                12'd148: toneR = `d2; 12'd149: toneR = `d2;
                12'd150: toneR = `d2; 12'd151: toneR = `d2;

                12'd152: toneR = `c2; 12'd153: toneR = `c2;
                12'd154: toneR = `c2; 12'd155: toneR = `c2;
                12'd156: toneR = `c2; 12'd157: toneR = `c2;
                12'd158: toneR = `c2; 12'd159: toneR = `c2;

                12'd160: toneR = `a2; 12'd161: toneR = `a2;
                12'd162: toneR = `a2; 12'd163: toneR = `a2;
                12'd164: toneR = `a2; 12'd165: toneR = `a2;
                12'd166: toneR = `a2; 12'd167: toneR = `a2;

                12'd168: toneR = `c2; 12'd169: toneR = `c2;
                12'd170: toneR = `c2; 12'd171: toneR = `c2;
                12'd172: toneR = `c2; 12'd173: toneR = `c2;
                12'd174: toneR = `c2; 12'd175: toneR = `c2;

                12'd176: toneR = `d2b; 12'd177: toneR = `d2b;
                12'd178: toneR = `d2b; 12'd179: toneR = `d2b;
                12'd180: toneR = `d2b; 12'd181: toneR = `d2b;
                12'd182: toneR = `d2b; 12'd183: toneR = `d2b;

                12'd184: toneR = `c2; 12'd185: toneR = `c2;
                12'd186: toneR = `c2; 12'd187: toneR = `c2;
                12'd188: toneR = `c2; 12'd189: toneR = `c2;
                12'd190: toneR = `c2; 12'd191: toneR = `c2;

                12'd192: toneR = `a2; 12'd193: toneR = `a2;
                12'd194: toneR = `a2; 12'd195: toneR = `a2;
                12'd196: toneR = `a2; 12'd197: toneR = `a2;
                12'd198: toneR = `a2; 12'd199: toneR = `a2;

                12'd200: toneR = `b1; 12'd201: toneR = `b1;
                12'd202: toneR = `b1; 12'd203: toneR = `b1;
                12'd204: toneR = `b1; 12'd205: toneR = `b1;
                12'd206: toneR = `b1; 12'd207: toneR = `b1;

                12'd208: toneR = `c2; 12'd209: toneR = `c2;
                12'd210: toneR = `c2; 12'd211: toneR = `c2;
                12'd212: toneR = `c2; 12'd213: toneR = `c2;
                12'd214: toneR = `c2; 12'd215: toneR = `c2;

                12'd216: toneR = `b1; 12'd217: toneR = `b1;
                12'd218: toneR = `b1; 12'd219: toneR = `b1;
                12'd220: toneR = `b1; 12'd221: toneR = `b1;
                12'd222: toneR = `b1; 12'd223: toneR = `b1;

                12'd224: toneR = `a2; 12'd225: toneR = `a2;
                12'd226: toneR = `a2; 12'd227: toneR = `a2;
                12'd228: toneR = `a2; 12'd229: toneR = `a2;
                12'd230: toneR = `a2; 12'd231: toneR = `a2;

                12'd232: toneR = `a1B; 12'd233: toneR = `a1B;
                12'd234: toneR = `a1B; 12'd235: toneR = `a1B;
                12'd236: toneR = `a1B; 12'd237: toneR = `a1B;
                12'd238: toneR = `a1B; 12'd239: toneR = `a1B;

                12'd240: toneR = `b1; 12'd241: toneR = `b1;
                12'd242: toneR = `b1; 12'd243: toneR = `b1;
                12'd244: toneR = `b1; 12'd245: toneR = `b1;
                12'd246: toneR = `b1; 12'd247: toneR = `b1;

                12'd248: toneR = `a1; 12'd249: toneR = `a1;
                12'd250: toneR = `a1; 12'd251: toneR = `a1;
                12'd252: toneR = `a1; 12'd253: toneR = `a1;
                12'd254: toneR = `a1; 12'd255: toneR = `a1;

                // --- Measure 3 ---
                12'd256: toneR = `d2; 12'd257: toneR = `d2;
                12'd258: toneR = `d2; 12'd259: toneR = `d2;
                12'd260: toneR = `d2; 12'd261: toneR = `d2;
                12'd262: toneR = `d2; 12'd263: toneR = `d2;
                12'd264: toneR = `d2; 12'd265: toneR = `d2;
                12'd266: toneR = `d2; 12'd267: toneR = `d2;
                12'd268: toneR = `d2; 12'd269: toneR = `d2;
                12'd270: toneR = `d2; 12'd271: toneR = `d2;

                12'd272: toneR = `sil; 12'd273: toneR = `sil;
                12'd274: toneR = `sil; 12'd275: toneR = `sil;
                12'd276: toneR = `sil; 12'd277: toneR = `sil;
                12'd278: toneR = `sil; 12'd279: toneR = `sil;
                12'd280: toneR = `sil; 12'd281: toneR = `sil;
                12'd282: toneR = `sil; 12'd283: toneR = `sil;
                12'd284: toneR = `sil; 12'd285: toneR = `sil;
                12'd286: toneR = `sil; 12'd287: toneR = `sil;
                12'd288: toneR = `sil; 12'd289: toneR = `sil;
                12'd290: toneR = `sil; 12'd291: toneR = `sil;
                12'd292: toneR = `sil; 12'd293: toneR = `sil;
                12'd294: toneR = `sil; 12'd295: toneR = `sil;
                12'd296: toneR = `sil; 12'd297: toneR = `sil;
                12'd298: toneR = `sil; 12'd299: toneR = `sil;
                12'd300: toneR = `sil; 12'd301: toneR = `sil;
                12'd302: toneR = `sil; 12'd303: toneR = `sil;

                12'd304: toneR = `e1; 12'd305: toneR = `e1;
                12'd306: toneR = `e1; 12'd307: toneR = `e1;
                12'd308: toneR = `e1; 12'd309: toneR = `e1;
                12'd310: toneR = `e1; 12'd311: toneR = `e1;
                12'd312: toneR = `e1; 12'd313: toneR = `e1;
                12'd314: toneR = `e1; 12'd315: toneR = `e1;
                12'd316: toneR = `e1; 12'd317: toneR = `e1;
                12'd318: toneR = `e1; 12'd319: toneR = `e1;

                12'd320: toneR = `sil; 12'd321: toneR = `sil;
                12'd322: toneR = `sil; 12'd323: toneR = `sil;
                12'd324: toneR = `sil; 12'd325: toneR = `sil;
                12'd326: toneR = `sil; 12'd327: toneR = `sil;
                12'd328: toneR = `sil; 12'd329: toneR = `sil;
                12'd330: toneR = `sil; 12'd331: toneR = `sil;
                12'd332: toneR = `sil; 12'd333: toneR = `sil;
                12'd334: toneR = `sil; 12'd335: toneR = `sil;
                12'd336: toneR = `sil; 12'd337: toneR = `sil;
                12'd338: toneR = `sil; 12'd339: toneR = `sil;
                12'd340: toneR = `sil; 12'd341: toneR = `sil;
                12'd342: toneR = `sil; 12'd343: toneR = `sil;
                12'd344: toneR = `sil; 12'd345: toneR = `sil;
                12'd346: toneR = `sil; 12'd347: toneR = `sil;
                12'd348: toneR = `sil; 12'd349: toneR = `sil;
                12'd350: toneR = `sil; 12'd351: toneR = `sil;

                12'd352: toneR = `f1; 12'd353: toneR = `f1;
                12'd354: toneR = `f1; 12'd355: toneR = `f1;
                12'd356: toneR = `f1; 12'd357: toneR = `f1;
                12'd358: toneR = `f1; 12'd359: toneR = `f1;
                12'd360: toneR = `f1; 12'd361: toneR = `f1;
                12'd362: toneR = `f1; 12'd363: toneR = `f1;
                12'd364: toneR = `f1; 12'd365: toneR = `f1;
                12'd366: toneR = `f1; 12'd367: toneR = `f1;

                12'd368: toneR = `sil; 12'd369: toneR = `sil;
                12'd370: toneR = `sil; 12'd371: toneR = `sil;
                12'd372: toneR = `sil; 12'd373: toneR = `sil;
                12'd374: toneR = `sil; 12'd375: toneR = `sil;
                12'd376: toneR = `sil; 12'd377: toneR = `sil;
                12'd378: toneR = `sil; 12'd379: toneR = `sil;
                12'd380: toneR = `sil; 12'd381: toneR = `sil;
                12'd382: toneR = `sil; 12'd383: toneR = `sil;
                
                // --- Measure 4 ---
                12'd384: toneR = `d1; 12'd385: toneR = `d1;
                12'd386: toneR = `d1; 12'd387: toneR = `d1;
                12'd388: toneR = `d1; 12'd389: toneR = `d1;
                12'd390: toneR = `d1; 12'd391: toneR = `d1;
                12'd392: toneR = `d1; 12'd393: toneR = `d1;
                12'd394: toneR = `d1; 12'd395: toneR = `d1;
                12'd396: toneR = `d1; 12'd397: toneR = `d1;
                12'd398: toneR = `d1; 12'd399: toneR = `d1;

                12'd400: toneR = `e1; 12'd401: toneR = `e1;
                12'd402: toneR = `e1; 12'd403: toneR = `e1;
                12'd404: toneR = `e1; 12'd405: toneR = `e1;
                12'd406: toneR = `e1; 12'd407: toneR = `e1;
                12'd408: toneR = `e1; 12'd409: toneR = `e1;
                12'd410: toneR = `e1; 12'd411: toneR = `e1;
                12'd412: toneR = `e1; 12'd413: toneR = `e1;
                12'd414: toneR = `e1; 12'd415: toneR = `e1;

                12'd416: toneR = `sil; 12'd417: toneR = `sil;
                12'd418: toneR = `sil; 12'd419: toneR = `sil;
                12'd420: toneR = `sil; 12'd421: toneR = `sil;
                12'd422: toneR = `sil; 12'd423: toneR = `sil;
                12'd424: toneR = `sil; 12'd425: toneR = `sil;
                12'd426: toneR = `sil; 12'd427: toneR = `sil;
                12'd428: toneR = `sil; 12'd429: toneR = `sil;
                12'd430: toneR = `sil; 12'd431: toneR = `sil;

                12'd432: toneR = `f1; 12'd433: toneR = `f1;
                12'd434: toneR = `f1; 12'd435: toneR = `f1;
                12'd436: toneR = `f1; 12'd437: toneR = `f1;
                12'd438: toneR = `f1; 12'd439: toneR = `f1;
                12'd440: toneR = `f1; 12'd441: toneR = `f1;
                12'd442: toneR = `f1; 12'd443: toneR = `f1;
                12'd444: toneR = `f1; 12'd445: toneR = `f1;
                12'd446: toneR = `f1; 12'd447: toneR = `f1;

                12'd448: toneR = `sil; 12'd449: toneR = `sil;
                12'd450: toneR = `sil; 12'd451: toneR = `sil;
                12'd452: toneR = `sil; 12'd453: toneR = `sil;
                12'd454: toneR = `sil; 12'd455: toneR = `sil;
                12'd456: toneR = `sil; 12'd457: toneR = `sil;
                12'd458: toneR = `sil; 12'd459: toneR = `sil;
                12'd460: toneR = `sil; 12'd461: toneR = `sil;
                12'd462: toneR = `sil; 12'd463: toneR = `sil;
                12'd464: toneR = `sil; 12'd465: toneR = `sil;
                12'd466: toneR = `sil; 12'd467: toneR = `sil;
                12'd468: toneR = `sil; 12'd469: toneR = `sil;
                12'd470: toneR = `sil; 12'd471: toneR = `sil;
                12'd472: toneR = `sil; 12'd473: toneR = `sil;
                12'd474: toneR = `sil; 12'd475: toneR = `sil;
                12'd476: toneR = `sil; 12'd477: toneR = `sil;
                12'd478: toneR = `sil; 12'd479: toneR = `sil;

                12'd480: toneR = `c1; 12'd481: toneR = `c1;
                12'd482: toneR = `c1; 12'd483: toneR = `c1;
                12'd484: toneR = `c1; 12'd485: toneR = `c1;
                12'd486: toneR = `c1; 12'd487: toneR = `c1;
                12'd488: toneR = `c1; 12'd489: toneR = `c1;
                12'd490: toneR = `c1; 12'd491: toneR = `c1;
                12'd492: toneR = `c1; 12'd493: toneR = `c1;
                12'd494: toneR = `c1; 12'd495: toneR = `c1;      
                
                12'd496: toneR = `sil; 12'd497: toneR = `sil;
                12'd498: toneR = `sil; 12'd499: toneR = `sil;
                12'd500: toneR = `sil; 12'd501: toneR = `sil;
                12'd502: toneR = `sil; 12'd503: toneR = `sil;
                12'd504: toneR = `sil; 12'd505: toneR = `sil;
                12'd506: toneR = `sil; 12'd507: toneR = `sil;
                12'd508: toneR = `sil; 12'd509: toneR = `sil;
                12'd510: toneR = `sil; 12'd511: toneR = `sil;     

                // --- Measure 5 ---
                12'd512: toneR = `d2; 12'd513: toneR = `d2;
                12'd514: toneR = `d2; 12'd515: toneR = `d2;
                12'd516: toneR = `d2; 12'd517: toneR = `d2;
                12'd518: toneR = `d2; 12'd519: toneR = `d2;
                12'd520: toneR = `d2; 12'd521: toneR = `d2;
                12'd522: toneR = `d2; 12'd523: toneR = `d2;
                12'd524: toneR = `d2; 12'd525: toneR = `d2;
                12'd526: toneR = `d2; 12'd527: toneR = `d2;

                12'd528: toneR = `sil; 12'd529: toneR = `sil;
                12'd530: toneR = `sil; 12'd531: toneR = `sil;
                12'd532: toneR = `sil; 12'd533: toneR = `sil;
                12'd534: toneR = `sil; 12'd535: toneR = `sil;
                12'd536: toneR = `sil; 12'd537: toneR = `sil;
                12'd538: toneR = `sil; 12'd539: toneR = `sil;
                12'd540: toneR = `sil; 12'd541: toneR = `sil;
                12'd542: toneR = `sil; 12'd543: toneR = `sil;
                12'd544: toneR = `sil; 12'd545: toneR = `sil;
                12'd546: toneR = `sil; 12'd547: toneR = `sil;
                12'd548: toneR = `sil; 12'd549: toneR = `sil;
                12'd550: toneR = `sil; 12'd551: toneR = `sil;
                12'd552: toneR = `sil; 12'd553: toneR = `sil;
                12'd554: toneR = `sil; 12'd555: toneR = `sil;
                12'd556: toneR = `sil; 12'd557: toneR = `sil;
                12'd558: toneR = `sil; 12'd559: toneR = `sil;

                12'd560: toneR = `e1; 12'd561: toneR = `e1;
                12'd562: toneR = `e1; 12'd563: toneR = `e1;
                12'd564: toneR = `e1; 12'd565: toneR = `e1;
                12'd566: toneR = `e1; 12'd567: toneR = `e1;
                12'd568: toneR = `e1; 12'd569: toneR = `e1;
                12'd570: toneR = `e1; 12'd571: toneR = `e1;
                12'd572: toneR = `e1; 12'd573: toneR = `e1;
                12'd574: toneR = `e1; 12'd575: toneR = `e1;

                12'd576: toneR = `sil; 12'd577: toneR = `sil;
                12'd578: toneR = `sil; 12'd579: toneR = `sil;
                12'd580: toneR = `sil; 12'd581: toneR = `sil;
                12'd582: toneR = `sil; 12'd583: toneR = `sil;
                12'd584: toneR = `sil; 12'd585: toneR = `sil;
                12'd586: toneR = `sil; 12'd587: toneR = `sil;
                12'd588: toneR = `sil; 12'd589: toneR = `sil;
                12'd590: toneR = `sil; 12'd591: toneR = `sil;
                12'd592: toneR = `sil; 12'd593: toneR = `sil;
                12'd594: toneR = `sil; 12'd595: toneR = `sil;
                12'd596: toneR = `sil; 12'd597: toneR = `sil;
                12'd598: toneR = `sil; 12'd599: toneR = `sil;
                12'd600: toneR = `sil; 12'd601: toneR = `sil;
                12'd602: toneR = `sil; 12'd603: toneR = `sil;
                12'd604: toneR = `sil; 12'd605: toneR = `sil;
                12'd606: toneR = `sil; 12'd607: toneR = `sil;

                12'd608: toneR = `f1; 12'd609: toneR = `f1;
                12'd610: toneR = `f1; 12'd611: toneR = `f1;
                12'd612: toneR = `f1; 12'd613: toneR = `f1;
                12'd614: toneR = `f1; 12'd615: toneR = `f1;
                12'd616: toneR = `f1; 12'd617: toneR = `f1;
                12'd618: toneR = `f1; 12'd619: toneR = `f1;
                12'd620: toneR = `f1; 12'd621: toneR = `f1;
                12'd622: toneR = `f1; 12'd623: toneR = `f1;

                12'd624: toneR = `sil; 12'd625: toneR = `sil;
                12'd626: toneR = `sil; 12'd627: toneR = `sil;
                12'd628: toneR = `sil; 12'd629: toneR = `sil;
                12'd630: toneR = `sil; 12'd631: toneR = `sil;
                12'd632: toneR = `sil; 12'd633: toneR = `sil;
                12'd634: toneR = `sil; 12'd635: toneR = `sil;
                12'd636: toneR = `sil; 12'd637: toneR = `sil;
                12'd638: toneR = `sil; 12'd639: toneR = `sil;

                // --- Measure 5 ---
                12'd640: toneR = `d1; 12'd641: toneR = `d1;
                12'd642: toneR = `d1; 12'd643: toneR = `d1;
                12'd644: toneR = `d1; 12'd645: toneR = `d1;
                12'd646: toneR = `d1; 12'd647: toneR = `d1;
                12'd648: toneR = `d1; 12'd649: toneR = `d1;
                12'd650: toneR = `d1; 12'd651: toneR = `d1;
                12'd652: toneR = `d1; 12'd653: toneR = `d1;
                12'd654: toneR = `d1; 12'd655: toneR = `d1;
                
                12'd656: toneR = `e1; 12'd657: toneR = `e1;
                12'd658: toneR = `e1; 12'd659: toneR = `e1;
                12'd660: toneR = `e1; 12'd661: toneR = `e1;
                12'd662: toneR = `e1; 12'd663: toneR = `e1;
                12'd664: toneR = `e1; 12'd665: toneR = `e1;
                12'd666: toneR = `e1; 12'd667: toneR = `e1;
                12'd668: toneR = `e1; 12'd669: toneR = `e1;
                12'd670: toneR = `e1; 12'd671: toneR = `e1;

                12'd672: toneR = `sil; 12'd673: toneR = `sil;
                12'd674: toneR = `sil; 12'd675: toneR = `sil;
                12'd676: toneR = `sil; 12'd677: toneR = `sil;
                12'd678: toneR = `sil; 12'd679: toneR = `sil;
                12'd680: toneR = `sil; 12'd681: toneR = `sil;
                12'd682: toneR = `sil; 12'd683: toneR = `sil;
                12'd684: toneR = `sil; 12'd685: toneR = `sil;
                12'd686: toneR = `sil; 12'd687: toneR = `sil;

                12'd688: toneR = `f1; 12'd689: toneR = `f1;
                12'd690: toneR = `f1; 12'd691: toneR = `f1;
                12'd692: toneR = `f1; 12'd693: toneR = `f1;
                12'd694: toneR = `f1; 12'd695: toneR = `f1;
                12'd696: toneR = `f1; 12'd697: toneR = `f1;
                12'd698: toneR = `f1; 12'd699: toneR = `f1;
                12'd700: toneR = `f1; 12'd701: toneR = `f1;
                12'd702: toneR = `f1; 12'd703: toneR = `f1;

                12'd704: toneR = `sil; 12'd705: toneR = `sil;
                12'd706: toneR = `sil; 12'd707: toneR = `sil;
                12'd708: toneR = `sil; 12'd709: toneR = `sil;
                12'd710: toneR = `sil; 12'd711: toneR = `sil;
                12'd712: toneR = `sil; 12'd713: toneR = `sil;
                12'd714: toneR = `sil; 12'd715: toneR = `sil;
                12'd716: toneR = `sil; 12'd717: toneR = `sil;
                12'd718: toneR = `sil; 12'd719: toneR = `sil;
                12'd720: toneR = `sil; 12'd721: toneR = `sil;
                12'd722: toneR = `sil; 12'd723: toneR = `sil;
                12'd724: toneR = `sil; 12'd725: toneR = `sil;
                12'd726: toneR = `sil; 12'd727: toneR = `sil;
                12'd728: toneR = `sil; 12'd729: toneR = `sil;
                12'd730: toneR = `sil; 12'd731: toneR = `sil;
                12'd732: toneR = `sil; 12'd733: toneR = `sil;
                12'd734: toneR = `sil; 12'd735: toneR = `sil;

                12'd736: toneR = `c2; 12'd737: toneR = `c2;
                12'd738: toneR = `c2; 12'd739: toneR = `c2;
                12'd740: toneR = `c2; 12'd741: toneR = `c2;
                12'd742: toneR = `c2; 12'd743: toneR = `c2;
                12'd744: toneR = `c2; 12'd745: toneR = `c2;
                12'd746: toneR = `c2; 12'd747: toneR = `c2;
                12'd748: toneR = `c2; 12'd749: toneR = `c2;
                12'd750: toneR = `c2; 12'd751: toneR = `c2;

                12'd752: toneR = `c2B; 12'd753: toneR = `c2B;
                12'd754: toneR = `c2B; 12'd755: toneR = `c2B;
                12'd756: toneR = `c2B; 12'd757: toneR = `c2B;
                12'd758: toneR = `c2B; 12'd759: toneR = `c2B;
                12'd760: toneR = `c2B; 12'd761: toneR = `c2B;
                12'd762: toneR = `c2B; 12'd763: toneR = `c2B;
                12'd764: toneR = `c2B; 12'd765: toneR = `c2B;
                12'd766: toneR = `c2B; 12'd767: toneR = `c2B;

                12'd768: toneR = `b1; 12'd769: toneR = `b1;
                12'd770: toneR = `b1; 12'd771: toneR = `b1;
                12'd772: toneR = `b1; 12'd773: toneR = `b1;
                12'd774: toneR = `b1; 12'd775: toneR = `b1;
                12'd776: toneR = `b1; 12'd777: toneR = `b1;
                12'd778: toneR = `b1; 12'd779: toneR = `b1;
                12'd780: toneR = `b1; 12'd781: toneR = `b1;
                12'd782: toneR = `b1; 12'd783: toneR = `b1;

                12'd784: toneR = `sil; 12'd785: toneR = `sil;
                12'd786: toneR = `sil; 12'd787: toneR = `sil;
                12'd788: toneR = `sil; 12'd789: toneR = `sil;
                12'd790: toneR = `sil; 12'd791: toneR = `sil;
                12'd792: toneR = `sil; 12'd793: toneR = `sil;
                12'd794: toneR = `sil; 12'd795: toneR = `sil;
                12'd796: toneR = `sil; 12'd797: toneR = `sil;
                12'd798: toneR = `sil; 12'd799: toneR = `sil;
                12'd800: toneR = `sil; 12'd801: toneR = `sil;
                12'd802: toneR = `sil; 12'd803: toneR = `sil;
                12'd804: toneR = `sil; 12'd805: toneR = `sil;
                12'd806: toneR = `sil; 12'd807: toneR = `sil;
                12'd808: toneR = `sil; 12'd809: toneR = `sil;
                12'd810: toneR = `sil; 12'd811: toneR = `sil;
                12'd812: toneR = `sil; 12'd813: toneR = `sil;
                12'd814: toneR = `sil; 12'd815: toneR = `sil;

                12'd816: toneR = `c2B; 12'd817: toneR = `c2B;
                12'd818: toneR = `c2B; 12'd819: toneR = `c2B;
                12'd820: toneR = `c2B; 12'd821: toneR = `c2B;
                12'd822: toneR = `c2B; 12'd823: toneR = `c2B;
                12'd824: toneR = `c2B; 12'd825: toneR = `c2B;
                12'd826: toneR = `c2B; 12'd827: toneR = `c2B;
                12'd828: toneR = `c2B; 12'd829: toneR = `c2B;
                12'd830: toneR = `c2B; 12'd831: toneR = `c2B;

                12'd832: toneR = `sil; 12'd833: toneR = `sil;
                12'd834: toneR = `sil; 12'd835: toneR = `sil;
                12'd836: toneR = `sil; 12'd837: toneR = `sil;
                12'd838: toneR = `sil; 12'd839: toneR = `sil;
                12'd840: toneR = `sil; 12'd841: toneR = `sil;
                12'd842: toneR = `sil; 12'd843: toneR = `sil;
                12'd844: toneR = `sil; 12'd845: toneR = `sil;
                12'd846: toneR = `sil; 12'd847: toneR = `sil;
                12'd848: toneR = `sil; 12'd849: toneR = `sil;
                12'd850: toneR = `sil; 12'd851: toneR = `sil;
                12'd852: toneR = `sil; 12'd853: toneR = `sil;
                12'd854: toneR = `sil; 12'd855: toneR = `sil;
                12'd856: toneR = `sil; 12'd857: toneR = `sil;
                12'd858: toneR = `sil; 12'd859: toneR = `sil;
                12'd860: toneR = `sil; 12'd861: toneR = `sil;
                12'd862: toneR = `sil; 12'd863: toneR = `sil;

                12'd864: toneR = `d2; 12'd865: toneR = `d2;
                12'd866: toneR = `d2; 12'd867: toneR = `d2;
                12'd868: toneR = `d2; 12'd869: toneR = `d2;
                12'd870: toneR = `d2; 12'd871: toneR = `d2;
                12'd872: toneR = `d2; 12'd873: toneR = `d2;
                12'd874: toneR = `d2; 12'd875: toneR = `d2;
                12'd876: toneR = `d2; 12'd877: toneR = `d2;
                12'd878: toneR = `d2; 12'd879: toneR = `d2;

                12'd880: toneR = `sil; 12'd881: toneR = `sil;
                12'd882: toneR = `sil; 12'd883: toneR = `sil;
                12'd884: toneR = `sil; 12'd885: toneR = `sil;
                12'd886: toneR = `sil; 12'd887: toneR = `sil;
                12'd888: toneR = `sil; 12'd889: toneR = `sil;
                12'd890: toneR = `sil; 12'd891: toneR = `sil;
                12'd892: toneR = `sil; 12'd893: toneR = `sil;
                12'd894: toneR = `sil; 12'd895: toneR = `sil;

                12'd896: toneR = `b1; 12'd897: toneR = `b1;
                12'd898: toneR = `b1; 12'd899: toneR = `b1;
                12'd900: toneR = `b1; 12'd901: toneR = `b1;
                12'd902: toneR = `b1; 12'd903: toneR = `b1;
                12'd904: toneR = `b1; 12'd905: toneR = `b1;
                12'd906: toneR = `b1; 12'd907: toneR = `b1;
                12'd908: toneR = `b1; 12'd909: toneR = `b1;
                12'd910: toneR = `b1; 12'd911: toneR = `b1;

                12'd912: toneR = `c2B; 12'd913: toneR = `c2B;
                12'd914: toneR = `c2B; 12'd915: toneR = `c2B;
                12'd916: toneR = `c2B; 12'd917: toneR = `c2B;
                12'd918: toneR = `c2B; 12'd919: toneR = `c2B;
                12'd920: toneR = `c2B; 12'd921: toneR = `c2B;
                12'd922: toneR = `c2B; 12'd923: toneR = `c2B;
                12'd924: toneR = `c2B; 12'd925: toneR = `c2B;
                12'd926: toneR = `c2B; 12'd927: toneR = `c2B;

                12'd928: toneR = `sil; 12'd929: toneR = `sil;
                12'd930: toneR = `sil; 12'd931: toneR = `sil;
                12'd932: toneR = `sil; 12'd933: toneR = `sil;
                12'd934: toneR = `sil; 12'd935: toneR = `sil;
                12'd936: toneR = `sil; 12'd937: toneR = `sil;
                12'd938: toneR = `sil; 12'd939: toneR = `sil;
                12'd940: toneR = `sil; 12'd941: toneR = `sil;
                12'd942: toneR = `sil; 12'd943: toneR = `sil;

                12'd944: toneR = `d2; 12'd945: toneR = `d2;
                12'd946: toneR = `d2; 12'd947: toneR = `d2;
                12'd948: toneR = `d2; 12'd949: toneR = `d2;
                12'd950: toneR = `d2; 12'd951: toneR = `d2;
                12'd952: toneR = `d2; 12'd953: toneR = `d2;
                12'd954: toneR = `d2; 12'd955: toneR = `d2;
                12'd956: toneR = `d2; 12'd957: toneR = `d2;
                12'd958: toneR = `d2; 12'd959: toneR = `d2;

                12'd960: toneR = `sil; 12'd961: toneR = `sil;
                12'd962: toneR = `sil; 12'd963: toneR = `sil;
                12'd964: toneR = `sil; 12'd965: toneR = `sil;
                12'd966: toneR = `sil; 12'd967: toneR = `sil;
                12'd968: toneR = `sil; 12'd969: toneR = `sil;
                12'd970: toneR = `sil; 12'd971: toneR = `sil;
                12'd972: toneR = `sil; 12'd973: toneR = `sil;
                12'd974: toneR = `sil; 12'd975: toneR = `sil;
                12'd976: toneR = `sil; 12'd977: toneR = `sil;
                12'd978: toneR = `sil; 12'd979: toneR = `sil;
                12'd980: toneR = `sil; 12'd981: toneR = `sil;
                12'd982: toneR = `sil; 12'd983: toneR = `sil;
                12'd984: toneR = `sil; 12'd985: toneR = `sil;
                12'd986: toneR = `sil; 12'd987: toneR = `sil;
                12'd988: toneR = `sil; 12'd989: toneR = `sil;
                12'd990: toneR = `sil; 12'd991: toneR = `sil;

                12'd992: toneR = `c2; 12'd993: toneR = `c2;
                12'd994: toneR = `c2; 12'd995: toneR = `c2;
                12'd996: toneR = `c2; 12'd997: toneR = `c2;
                12'd998: toneR = `c2; 12'd999: toneR = `c2;
                12'd1000: toneR = `c2; 12'd1001: toneR = `c2;
                12'd1002: toneR = `c2; 12'd1003: toneR = `c2;
                12'd1004: toneR = `c2; 12'd1005: toneR = `c2;
                12'd1006: toneR = `c2; 12'd1007: toneR = `c2;

                12'd1008: toneR = `a2B; 12'd1009: toneR = `a2B;
                12'd1010: toneR = `a2B; 12'd1011: toneR = `a2B;
                12'd1012: toneR = `a2B; 12'd1013: toneR = `a2B;
                12'd1014: toneR = `a2B; 12'd1015: toneR = `a2B;
                12'd1016: toneR = `a2B; 12'd1017: toneR = `a2B;
                12'd1018: toneR = `a2B; 12'd1019: toneR = `a2B;
                12'd1020: toneR = `a2B; 12'd1021: toneR = `a2B;
                12'd1022: toneR = `a2B; 12'd1023: toneR = `a2B;

                12'd1024: toneR = `b2; 12'd1025: toneR = `b2;
                12'd1026: toneR = `b2; 12'd1027: toneR = `b2;
                12'd1028: toneR = `b2; 12'd1029: toneR = `b2;
                12'd1030: toneR = `b2; 12'd1031: toneR = `b2;
                12'd1032: toneR = `b2; 12'd1033: toneR = `b2;
                12'd1034: toneR = `b2; 12'd1035: toneR = `b2;
                12'd1036: toneR = `b2; 12'd1037: toneR = `b2;
                12'd1038: toneR = `b2; 12'd1039: toneR = `b2;

                12'd1040: toneR = `sil; 12'd1041: toneR = `sil;
                12'd1042: toneR = `sil; 12'd1043: toneR = `sil;
                12'd1044: toneR = `sil; 12'd1045: toneR = `sil;
                12'd1046: toneR = `sil; 12'd1047: toneR = `sil;
                12'd1048: toneR = `sil; 12'd1049: toneR = `sil;
                12'd1050: toneR = `sil; 12'd1051: toneR = `sil;
                12'd1052: toneR = `sil; 12'd1053: toneR = `sil;
                12'd1054: toneR = `sil; 12'd1055: toneR = `sil;
                12'd1056: toneR = `sil; 12'd1057: toneR = `sil;
                12'd1058: toneR = `sil; 12'd1059: toneR = `sil;
                12'd1060: toneR = `sil; 12'd1061: toneR = `sil;
                12'd1062: toneR = `sil; 12'd1063: toneR = `sil;
                12'd1064: toneR = `sil; 12'd1065: toneR = `sil;
                12'd1066: toneR = `sil; 12'd1067: toneR = `sil;
                12'd1068: toneR = `sil; 12'd1069: toneR = `sil;
                12'd1070: toneR = `sil; 12'd1071: toneR = `sil;

                12'd1072: toneR = `c3B; 12'd1073: toneR = `c3B;
                12'd1074: toneR = `c3B; 12'd1075: toneR = `c3B;
                12'd1076: toneR = `c3B; 12'd1077: toneR = `c3B;
                12'd1078: toneR = `c3B; 12'd1079: toneR = `c3B;
                12'd1080: toneR = `c3B; 12'd1081: toneR = `c3B;
                12'd1082: toneR = `c3B; 12'd1083: toneR = `c3B;
                12'd1084: toneR = `c3B; 12'd1085: toneR = `c3B;
                12'd1086: toneR = `c3B; 12'd1087: toneR = `c3B;

                12'd1088: toneR = `sil; 12'd1089: toneR = `sil;
                12'd1090: toneR = `sil; 12'd1091: toneR = `sil;
                12'd1092: toneR = `sil; 12'd1093: toneR = `sil;
                12'd1094: toneR = `sil; 12'd1095: toneR = `sil;
                12'd1096: toneR = `sil; 12'd1097: toneR = `sil;
                12'd1098: toneR = `sil; 12'd1099: toneR = `sil;
                12'd1100: toneR = `sil; 12'd1101: toneR = `sil;
                12'd1102: toneR = `sil; 12'd1103: toneR = `sil;
                12'd1104: toneR = `sil; 12'd1105: toneR = `sil;
                12'd1106: toneR = `sil; 12'd1107: toneR = `sil;
                12'd1108: toneR = `sil; 12'd1109: toneR = `sil;
                12'd1110: toneR = `sil; 12'd1111: toneR = `sil;
                12'd1112: toneR = `sil; 12'd1113: toneR = `sil;
                12'd1114: toneR = `sil; 12'd1115: toneR = `sil;
                12'd1116: toneR = `sil; 12'd1117: toneR = `sil;
                12'd1118: toneR = `sil; 12'd1119: toneR = `sil;

                12'd1120: toneR = `d3; 12'd1121: toneR = `d3;
                12'd1122: toneR = `d3; 12'd1123: toneR = `d3;
                12'd1124: toneR = `d3; 12'd1125: toneR = `d3;
                12'd1126: toneR = `d3; 12'd1127: toneR = `d3;
                12'd1128: toneR = `d3; 12'd1129: toneR = `d3;
                12'd1130: toneR = `d3; 12'd1131: toneR = `d3;
                12'd1132: toneR = `d3; 12'd1133: toneR = `d3;
                12'd1134: toneR = `d3; 12'd1135: toneR = `d3;

                12'd1136: toneR = `sil; 12'd1137: toneR = `sil;
                12'd1138: toneR = `sil; 12'd1139: toneR = `sil;
                12'd1140: toneR = `sil; 12'd1141: toneR = `sil;
                12'd1142: toneR = `sil; 12'd1143: toneR = `sil;
                12'd1144: toneR = `sil; 12'd1145: toneR = `sil;
                12'd1146: toneR = `sil; 12'd1147: toneR = `sil;
                12'd1148: toneR = `sil; 12'd1149: toneR = `sil;
                12'd1150: toneR = `sil; 12'd1151: toneR = `sil;

                12'd1152: toneR = `b2; 12'd1153: toneR = `b2;
                12'd1154: toneR = `b2; 12'd1155: toneR = `b2;
                12'd1156: toneR = `b2; 12'd1157: toneR = `b2;
                12'd1158: toneR = `b2; 12'd1159: toneR = `b2;
                12'd1160: toneR = `b2; 12'd1161: toneR = `b2;
                12'd1162: toneR = `b2; 12'd1163: toneR = `b2;
                12'd1164: toneR = `b2; 12'd1165: toneR = `b2;
                12'd1166: toneR = `b2; 12'd1167: toneR = `b2;

                12'd1168: toneR = `c3B; 12'd1169: toneR = `c3B;
                12'd1170: toneR = `c3B; 12'd1171: toneR = `c3B;
                12'd1172: toneR = `c3B; 12'd1173: toneR = `c3B;
                12'd1174: toneR = `c3B; 12'd1175: toneR = `c3B;
                12'd1176: toneR = `c3B; 12'd1177: toneR = `c3B;
                12'd1178: toneR = `c3B; 12'd1179: toneR = `c3B;
                12'd1180: toneR = `c3B; 12'd1181: toneR = `c3B;
                12'd1182: toneR = `c3B; 12'd1183: toneR = `c3B;

                12'd1184: toneR = `sil; 12'd1185: toneR = `sil;
                12'd1186: toneR = `sil; 12'd1187: toneR = `sil;
                12'd1188: toneR = `sil; 12'd1189: toneR = `sil;
                12'd1190: toneR = `sil; 12'd1191: toneR = `sil;
                12'd1192: toneR = `sil; 12'd1193: toneR = `sil;
                12'd1194: toneR = `sil; 12'd1195: toneR = `sil;
                12'd1196: toneR = `sil; 12'd1197: toneR = `sil;
                12'd1198: toneR = `sil; 12'd1199: toneR = `sil;

                12'd1200: toneR = `d3; 12'd1201: toneR = `d3;
                12'd1202: toneR = `d3; 12'd1203: toneR = `d3;
                12'd1204: toneR = `d3; 12'd1205: toneR = `d3;
                12'd1206: toneR = `d3; 12'd1207: toneR = `d3;
                12'd1208: toneR = `d3; 12'd1209: toneR = `d3;
                12'd1210: toneR = `d3; 12'd1211: toneR = `d3;
                12'd1212: toneR = `d3; 12'd1213: toneR = `d3;
                12'd1214: toneR = `d3; 12'd1215: toneR = `d3;

                12'd1216: toneR = `sil; 12'd1217: toneR = `sil;
                12'd1218: toneR = `sil; 12'd1219: toneR = `sil;
                12'd1220: toneR = `sil; 12'd1221: toneR = `sil;
                12'd1222: toneR = `sil; 12'd1223: toneR = `sil;
                12'd1224: toneR = `sil; 12'd1225: toneR = `sil;
                12'd1226: toneR = `sil; 12'd1227: toneR = `sil;
                12'd1228: toneR = `sil; 12'd1229: toneR = `sil;
                12'd1230: toneR = `sil; 12'd1231: toneR = `sil;
                12'd1232: toneR = `sil; 12'd1233: toneR = `sil;
                12'd1234: toneR = `sil; 12'd1235: toneR = `sil;
                12'd1236: toneR = `sil; 12'd1237: toneR = `sil;
                12'd1238: toneR = `sil; 12'd1239: toneR = `sil;
                12'd1240: toneR = `sil; 12'd1241: toneR = `sil;
                12'd1242: toneR = `sil; 12'd1243: toneR = `sil;
                12'd1244: toneR = `sil; 12'd1245: toneR = `sil;
                12'd1246: toneR = `sil; 12'd1247: toneR = `sil;

                12'd1248: toneR = `a2; 12'd1249: toneR = `a2;
                12'd1250: toneR = `a2; 12'd1251: toneR = `a2;
                12'd1252: toneR = `a2; 12'd1253: toneR = `a2;
                12'd1254: toneR = `a2; 12'd1255: toneR = `a2;
                12'd1256: toneR = `a2; 12'd1257: toneR = `a2;
                12'd1258: toneR = `a2; 12'd1259: toneR = `a2;
                12'd1260: toneR = `a2; 12'd1261: toneR = `a2;
                12'd1262: toneR = `a2; 12'd1263: toneR = `a2;

                12'd1264: toneR = `c2B; 12'd1265: toneR = `c2B;
                12'd1266: toneR = `c2B; 12'd1267: toneR = `c2B;
                12'd1268: toneR = `c2B; 12'd1269: toneR = `c2B;
                12'd1270: toneR = `c2B; 12'd1271: toneR = `c2B;
                12'd1272: toneR = `c2B; 12'd1273: toneR = `c2B;
                12'd1274: toneR = `c2B; 12'd1275: toneR = `c2B;
                12'd1276: toneR = `c2B; 12'd1277: toneR = `c2B;
                12'd1278: toneR = `c2B; 12'd1279: toneR = `c2B;
            
                12'd1280: toneR = `b1; 12'd1281: toneR = `b1;
                12'd1282: toneR = `b1; 12'd1283: toneR = `b1;
                12'd1284: toneR = `b1; 12'd1285: toneR = `b1;
                12'd1286: toneR = `b1; 12'd1287: toneR = `b1;
                12'd1288: toneR = `b1; 12'd1289: toneR = `b1;
                12'd1290: toneR = `b1; 12'd1291: toneR = `b1;
                12'd1292: toneR = `b1; 12'd1293: toneR = `b1;
                12'd1294: toneR = `b1; 12'd1295: toneR = `b1;
                12'd1296: toneR = `b1; 12'd1297: toneR = `b1;
                12'd1298: toneR = `b1; 12'd1299: toneR = `b1;
                12'd1300: toneR = `b1; 12'd1301: toneR = `b1;
                12'd1302: toneR = `b1; 12'd1303: toneR = `b1;
                12'd1304: toneR = `b1; 12'd1305: toneR = `b1;
                12'd1306: toneR = `b1; 12'd1307: toneR = `b1;
                12'd1308: toneR = `b1; 12'd1309: toneR = `b1;
                12'd1310: toneR = `b1; 12'd1311: toneR = `b1;
                12'd1312: toneR = `b1; 12'd1313: toneR = `b1;
                12'd1314: toneR = `b1; 12'd1315: toneR = `b1;
                12'd1316: toneR = `b1; 12'd1317: toneR = `b1;
                12'd1318: toneR = `b1; 12'd1319: toneR = `b1;
                12'd1320: toneR = `b1; 12'd1321: toneR = `b1;
                12'd1322: toneR = `b1; 12'd1323: toneR = `b1;
                12'd1324: toneR = `b1; 12'd1325: toneR = `b1;
                12'd1326: toneR = `b1; 12'd1327: toneR = `b1;

                12'd1328: toneR = `f1B; 12'd1329: toneR = `f1B;
                12'd1330: toneR = `f1B; 12'd1331: toneR = `f1B;
                12'd1332: toneR = `f1B; 12'd1333: toneR = `f1B;
                12'd1334: toneR = `f1B; 12'd1335: toneR = `f1B;
                12'd1336: toneR = `f1B; 12'd1337: toneR = `f1B;
                12'd1338: toneR = `f1B; 12'd1339: toneR = `f1B;
                12'd1340: toneR = `f1B; 12'd1341: toneR = `f1B;
                12'd1342: toneR = `f1B; 12'd1343: toneR = `f1B;
                12'd1344: toneR = `f1B; 12'd1345: toneR = `f1B;
                12'd1346: toneR = `f1B; 12'd1347: toneR = `f1B;
                12'd1348: toneR = `f1B; 12'd1349: toneR = `f1B;
                12'd1350: toneR = `f1B; 12'd1351: toneR = `f1B;
                12'd1352: toneR = `f1B; 12'd1353: toneR = `f1B;
                12'd1354: toneR = `f1B; 12'd1355: toneR = `f1B;
                12'd1356: toneR = `f1B; 12'd1357: toneR = `f1B;
                12'd1358: toneR = `f1B; 12'd1359: toneR = `f1B;
                12'd1360: toneR = `f1B; 12'd1361: toneR = `f1B;
                12'd1362: toneR = `f1B; 12'd1363: toneR = `f1B;
                12'd1364: toneR = `f1B; 12'd1365: toneR = `f1B;
                12'd1366: toneR = `f1B; 12'd1367: toneR = `f1B;
                12'd1368: toneR = `f1B; 12'd1369: toneR = `f1B;
                12'd1370: toneR = `f1B; 12'd1371: toneR = `f1B;
                12'd1372: toneR = `f1B; 12'd1373: toneR = `f1B;
                12'd1374: toneR = `f1B; 12'd1375: toneR = `f1B;
                12'd1376: toneR = `f1B; 12'd1377: toneR = `f1B;
                12'd1378: toneR = `f1B; 12'd1379: toneR = `f1B;
                12'd1380: toneR = `f1B; 12'd1381: toneR = `f1B;
                12'd1382: toneR = `f1B; 12'd1383: toneR = `f1B;
                12'd1384: toneR = `f1B; 12'd1385: toneR = `f1B;
                12'd1386: toneR = `f1B; 12'd1387: toneR = `f1B;
                12'd1388: toneR = `f1B; 12'd1389: toneR = `f1B;
                12'd1390: toneR = `f1B; 12'd1391: toneR = `f1B;
                12'd1392: toneR = `f1B; 12'd1393: toneR = `f1B;
                12'd1394: toneR = `f1B; 12'd1395: toneR = `f1B;
                12'd1396: toneR = `f1B; 12'd1397: toneR = `f1B;
                12'd1398: toneR = `f1B; 12'd1399: toneR = `f1B;
                12'd1400: toneR = `f1B; 12'd1401: toneR = `f1B;
                12'd1402: toneR = `f1B; 12'd1403: toneR = `f1B;
                12'd1404: toneR = `f1B; 12'd1405: toneR = `f1B;
                12'd1406: toneR = `f1B; 12'd1407: toneR = `f1B;

                12'd1408: toneR = `f1B; 12'd1409: toneR = `f1B;
                12'd1410: toneR = `f1B; 12'd1411: toneR = `f1B;
                12'd1412: toneR = `f1B; 12'd1413: toneR = `f1B;
                12'd1414: toneR = `f1B; 12'd1415: toneR = `f1B;
                12'd1416: toneR = `f1B; 12'd1417: toneR = `f1B;
                12'd1418: toneR = `f1B; 12'd1419: toneR = `f1B;
                12'd1420: toneR = `f1B; 12'd1421: toneR = `f1B;
                12'd1422: toneR = `f1B; 12'd1423: toneR = `f1B;
                12'd1424: toneR = `f1B; 12'd1425: toneR = `f1B;
                12'd1426: toneR = `f1B; 12'd1427: toneR = `f1B;
                12'd1428: toneR = `f1B; 12'd1429: toneR = `f1B;
                12'd1430: toneR = `f1B; 12'd1431: toneR = `f1B;
                12'd1432: toneR = `f1B; 12'd1433: toneR = `f1B;
                12'd1434: toneR = `f1B; 12'd1435: toneR = `f1B;
                12'd1436: toneR = `f1B; 12'd1437: toneR = `f1B;
                12'd1438: toneR = `f1B; 12'd1439: toneR = `f1B;

                12'd1440: toneR = `b1; 12'd1441: toneR = `b1;
                12'd1442: toneR = `b1; 12'd1443: toneR = `b1;
                12'd1444: toneR = `b1; 12'd1445: toneR = `b1;
                12'd1446: toneR = `b1; 12'd1447: toneR = `b1;
                12'd1448: toneR = `b1; 12'd1449: toneR = `b1;
                12'd1450: toneR = `b1; 12'd1451: toneR = `b1;
                12'd1452: toneR = `b1; 12'd1453: toneR = `b1;
                12'd1454: toneR = `b1; 12'd1455: toneR = `b1;
                12'd1456: toneR = `b1; 12'd1457: toneR = `b1;
                12'd1458: toneR = `b1; 12'd1459: toneR = `b1;
                12'd1460: toneR = `b1; 12'd1461: toneR = `b1;
                12'd1462: toneR = `b1; 12'd1463: toneR = `b1;
                12'd1464: toneR = `b1; 12'd1465: toneR = `b1;
                12'd1466: toneR = `b1; 12'd1467: toneR = `b1;
                12'd1468: toneR = `b1; 12'd1469: toneR = `b1;
                12'd1470: toneR = `b1; 12'd1471: toneR = `b1;

                12'd1472: toneR = `f1B; 12'd1473: toneR = `f1B;
                12'd1474: toneR = `f1B; 12'd1475: toneR = `f1B;
                12'd1476: toneR = `f1B; 12'd1477: toneR = `f1B;
                12'd1478: toneR = `f1B; 12'd1479: toneR = `f1B;
                12'd1480: toneR = `f1B; 12'd1481: toneR = `f1B;
                12'd1482: toneR = `f1B; 12'd1483: toneR = `f1B;
                12'd1484: toneR = `f1B; 12'd1485: toneR = `f1B;
                12'd1486: toneR = `f1B; 12'd1487: toneR = `f1B;
                12'd1488: toneR = `f1B; 12'd1489: toneR = `f1B;
                12'd1490: toneR = `f1B; 12'd1491: toneR = `f1B;
                12'd1492: toneR = `f1B; 12'd1493: toneR = `f1B;
                12'd1494: toneR = `f1B; 12'd1495: toneR = `f1B;
                12'd1496: toneR = `f1B; 12'd1497: toneR = `f1B;
                12'd1498: toneR = `f1B; 12'd1499: toneR = `f1B;
                12'd1500: toneR = `f1B; 12'd1501: toneR = `f1B;
                12'd1502: toneR = `f1B; 12'd1503: toneR = `f1B;

                12'd1504: toneR = `b1; 12'd1505: toneR = `b1;
                12'd1506: toneR = `b1; 12'd1507: toneR = `b1;
                12'd1508: toneR = `b1; 12'd1509: toneR = `b1;
                12'd1510: toneR = `b1; 12'd1511: toneR = `b1;
                12'd1512: toneR = `b1; 12'd1513: toneR = `b1;
                12'd1514: toneR = `b1; 12'd1515: toneR = `b1;
                12'd1516: toneR = `b1; 12'd1517: toneR = `b1;
                12'd1518: toneR = `b1; 12'd1519: toneR = `b1;
                12'd1520: toneR = `b1; 12'd1521: toneR = `b1;
                12'd1522: toneR = `b1; 12'd1523: toneR = `b1;
                12'd1524: toneR = `b1; 12'd1525: toneR = `b1;
                12'd1526: toneR = `b1; 12'd1527: toneR = `b1;
                12'd1528: toneR = `b1; 12'd1529: toneR = `b1;
                12'd1530: toneR = `b1; 12'd1531: toneR = `b1;
                12'd1532: toneR = `b1; 12'd1533: toneR = `b1;
                12'd1534: toneR = `b1; 12'd1535: toneR = `b1;

                12'd1536: toneR = `c2; 12'd1537: toneR = `c2;
                12'd1538: toneR = `c2; 12'd1539: toneR = `c2;
                12'd1540: toneR = `c2; 12'd1541: toneR = `c2;
                12'd1542: toneR = `c2; 12'd1543: toneR = `c2;
                12'd1544: toneR = `c2; 12'd1545: toneR = `c2;
                12'd1546: toneR = `c2; 12'd1547: toneR = `c2;
                12'd1548: toneR = `c2; 12'd1549: toneR = `c2;
                12'd1550: toneR = `c2; 12'd1551: toneR = `c2;
                12'd1552: toneR = `c2; 12'd1553: toneR = `c2;
                12'd1554: toneR = `c2; 12'd1555: toneR = `c2;
                12'd1556: toneR = `c2; 12'd1557: toneR = `c2;
                12'd1558: toneR = `c2; 12'd1559: toneR = `c2;
                12'd1560: toneR = `c2; 12'd1561: toneR = `c2;
                12'd1562: toneR = `c2; 12'd1563: toneR = `c2;
                12'd1564: toneR = `c2; 12'd1565: toneR = `c2;
                12'd1566: toneR = `c2; 12'd1567: toneR = `c2;
                12'd1568: toneR = `c2; 12'd1569: toneR = `c2;
                12'd1570: toneR = `c2; 12'd1571: toneR = `c2;
                12'd1572: toneR = `c2; 12'd1573: toneR = `c2;
                12'd1574: toneR = `c2; 12'd1575: toneR = `c2;
                12'd1576: toneR = `c2; 12'd1577: toneR = `c2;
                12'd1578: toneR = `c2; 12'd1579: toneR = `c2;
                12'd1580: toneR = `c2; 12'd1581: toneR = `c2;
                12'd1582: toneR = `c2; 12'd1583: toneR = `c2;
                12'd1584: toneR = `c2; 12'd1585: toneR = `c2;
                12'd1586: toneR = `c2; 12'd1587: toneR = `c2;
                12'd1588: toneR = `c2; 12'd1589: toneR = `c2;
                12'd1590: toneR = `c2; 12'd1591: toneR = `c2;
                12'd1592: toneR = `c2; 12'd1593: toneR = `c2;
                12'd1594: toneR = `c2; 12'd1595: toneR = `c2;
                12'd1596: toneR = `c2; 12'd1597: toneR = `c2;
                12'd1598: toneR = `c2; 12'd1599: toneR = `c2;

                12'd1600: toneR = `c1; 12'd1601: toneR = `c1;
                12'd1602: toneR = `c1; 12'd1603: toneR = `c1;
                12'd1604: toneR = `c1; 12'd1605: toneR = `c1;
                12'd1606: toneR = `c1; 12'd1607: toneR = `c1;

                12'd1608: toneR = `c1B; 12'd1609: toneR = `c1B;
                12'd1610: toneR = `c1B; 12'd1611: toneR = `c1B;
                12'd1612: toneR = `c1B; 12'd1613: toneR = `c1B;
                12'd1614: toneR = `c1B; 12'd1615: toneR = `c1B;

                12'd1616: toneR = `d1; 12'd1617: toneR = `d1;
                12'd1618: toneR = `d1; 12'd1619: toneR = `d1;
                12'd1620: toneR = `d1; 12'd1621: toneR = `d1;
                12'd1622: toneR = `d1; 12'd1623: toneR = `d1;

                12'd1624: toneR = `d1B; 12'd1625: toneR = `d1B;
                12'd1626: toneR = `d1B; 12'd1627: toneR = `d1B;
                12'd1628: toneR = `d1B; 12'd1629: toneR = `d1B;
                12'd1630: toneR = `d1B; 12'd1631: toneR = `d1B;

                12'd1632: toneR = `e1; 12'd1633: toneR = `e1;
                12'd1634: toneR = `e1; 12'd1635: toneR = `e1;
                12'd1636: toneR = `e1; 12'd1637: toneR = `e1;
                12'd1638: toneR = `e1; 12'd1639: toneR = `e1;

                12'd1640: toneR = `d1B; 12'd1641: toneR = `d1B;
                12'd1642: toneR = `d1B; 12'd1643: toneR = `d1B;
                12'd1644: toneR = `d1B; 12'd1645: toneR = `d1B;
                12'd1646: toneR = `d1B; 12'd1647: toneR = `d1B;

                12'd1648: toneR = `d1; 12'd1649: toneR = `d1;
                12'd1650: toneR = `d1; 12'd1651: toneR = `d1;
                12'd1652: toneR = `d1; 12'd1653: toneR = `d1;
                12'd1654: toneR = `d1; 12'd1655: toneR = `d1;

                12'd1656: toneR = `c1B; 12'd1657: toneR = `c1B;
                12'd1658: toneR = `c1B; 12'd1659: toneR = `c1B;
                12'd1660: toneR = `c1B; 12'd1661: toneR = `c1B;
                12'd1662: toneR = `c1B; 12'd1663: toneR = `c1B;

                12'd1664: toneR = `c1; 12'd1665: toneR = `c1;
                12'd1666: toneR = `c1; 12'd1667: toneR = `c1;
                12'd1668: toneR = `c1; 12'd1669: toneR = `c1;
                12'd1670: toneR = `c1; 12'd1671: toneR = `c1;

                12'd1672: toneR = `c1B; 12'd1673: toneR = `c1B;
                12'd1674: toneR = `c1B; 12'd1675: toneR = `c1B;
                12'd1676: toneR = `c1B; 12'd1677: toneR = `c1B;
                12'd1678: toneR = `c1B; 12'd1679: toneR = `c1B;

                12'd1680: toneR = `d1; 12'd1681: toneR = `d1;
                12'd1682: toneR = `d1; 12'd1683: toneR = `d1;
                12'd1684: toneR = `d1; 12'd1685: toneR = `d1;
                12'd1686: toneR = `d1; 12'd1687: toneR = `d1;

                12'd1688: toneR = `d1B; 12'd1689: toneR = `d1B;
                12'd1690: toneR = `d1B; 12'd1691: toneR = `d1B;
                12'd1692: toneR = `d1B; 12'd1693: toneR = `d1B;
                12'd1694: toneR = `d1B; 12'd1695: toneR = `d1B;

                12'd1696: toneR = `e1; 12'd1697: toneR = `e1;
                12'd1698: toneR = `e1; 12'd1699: toneR = `e1;
                12'd1700: toneR = `e1; 12'd1701: toneR = `e1;
                12'd1702: toneR = `e1; 12'd1703: toneR = `e1;

                12'd1704: toneR = `f1; 12'd1705: toneR = `f1;
                12'd1706: toneR = `f1; 12'd1707: toneR = `f1;
                12'd1708: toneR = `f1; 12'd1709: toneR = `f1;
                12'd1710: toneR = `f1; 12'd1711: toneR = `f1;

                12'd1712: toneR = `f1B; 12'd1713: toneR = `f1B;
                12'd1714: toneR = `f1B; 12'd1715: toneR = `f1B;
                12'd1716: toneR = `f1B; 12'd1717: toneR = `f1B;
                12'd1718: toneR = `f1B; 12'd1719: toneR = `f1B;

                12'd1720: toneR = `g1; 12'd1721: toneR = `g1;
                12'd1722: toneR = `g1; 12'd1723: toneR = `g1;
                12'd1724: toneR = `g1; 12'd1725: toneR = `g1;
                12'd1726: toneR = `g1; 12'd1727: toneR = `g1;

                12'd1728: toneR = `g1B; 12'd1729: toneR = `g1B;
                12'd1730: toneR = `g1B; 12'd1731: toneR = `g1B;
                12'd1732: toneR = `g1B; 12'd1733: toneR = `g1B;
                12'd1734: toneR = `g1B; 12'd1735: toneR = `g1B;

                12'd1736: toneR = `a1; 12'd1737: toneR = `a1;
                12'd1738: toneR = `a1; 12'd1739: toneR = `a1;
                12'd1740: toneR = `a1; 12'd1741: toneR = `a1;
                12'd1742: toneR = `a1; 12'd1743: toneR = `a1;

                12'd1744: toneR = `g1B; 12'd1745: toneR = `g1B;
                12'd1746: toneR = `g1B; 12'd1747: toneR = `g1B;
                12'd1748: toneR = `g1B; 12'd1749: toneR = `g1B;
                12'd1750: toneR = `g1B; 12'd1751: toneR = `g1B;

                12'd1752: toneR = `g1; 12'd1753: toneR = `g1;
                12'd1754: toneR = `g1; 12'd1755: toneR = `g1;
                12'd1756: toneR = `g1; 12'd1757: toneR = `g1;
                12'd1758: toneR = `g1; 12'd1759: toneR = `g1;

                12'd1760: toneR = `f1B; 12'd1761: toneR = `f1B;
                12'd1762: toneR = `f1B; 12'd1763: toneR = `f1B;
                12'd1764: toneR = `f1B; 12'd1765: toneR = `f1B;
                12'd1766: toneR = `f1B; 12'd1767: toneR = `f1B;

                12'd1768: toneR = `f1; 12'd1769: toneR = `f1;
                12'd1770: toneR = `f1; 12'd1771: toneR = `f1;
                12'd1772: toneR = `f1; 12'd1773: toneR = `f1;
                12'd1774: toneR = `f1; 12'd1775: toneR = `f1;

                12'd1776: toneR = `e1; 12'd1777: toneR = `e1;
                12'd1778: toneR = `e1; 12'd1779: toneR = `e1;
                12'd1780: toneR = `e1; 12'd1781: toneR = `e1;
                12'd1782: toneR = `e1; 12'd1783: toneR = `e1;

                12'd1784: toneR = `d1; 12'd1785: toneR = `d1;
                12'd1786: toneR = `d1; 12'd1787: toneR = `d1;
                12'd1788: toneR = `d1; 12'd1789: toneR = `d1;
                12'd1790: toneR = `d1; 12'd1791: toneR = `d1;

                12'd1792: toneR = `b1; 12'd1793: toneR = `b1;
                12'd1794: toneR = `b1; 12'd1795: toneR = `b1;
                12'd1796: toneR = `b1; 12'd1797: toneR = `b1;
                12'd1798: toneR = `b1; 12'd1799: toneR = `b1;
                12'd1800: toneR = `b1; 12'd1801: toneR = `b1;
                12'd1802: toneR = `b1; 12'd1803: toneR = `b1;
                12'd1804: toneR = `b1; 12'd1805: toneR = `b1;
                12'd1806: toneR = `b1; 12'd1807: toneR = `b1;
                12'd1808: toneR = `b1; 12'd1809: toneR = `b1;
                12'd1810: toneR = `b1; 12'd1811: toneR = `b1;
                12'd1812: toneR = `b1; 12'd1813: toneR = `b1;
                12'd1814: toneR = `b1; 12'd1815: toneR = `b1;
                12'd1816: toneR = `b1; 12'd1817: toneR = `b1;
                12'd1818: toneR = `b1; 12'd1819: toneR = `b1;
                12'd1820: toneR = `b1; 12'd1821: toneR = `b1;
                12'd1822: toneR = `b1; 12'd1823: toneR = `b1;
                12'd1824: toneR = `b1; 12'd1825: toneR = `b1;
                12'd1826: toneR = `b1; 12'd1827: toneR = `b1;
                12'd1828: toneR = `b1; 12'd1829: toneR = `b1;
                12'd1830: toneR = `b1; 12'd1831: toneR = `b1;
                12'd1832: toneR = `b1; 12'd1833: toneR = `b1;
                12'd1834: toneR = `b1; 12'd1835: toneR = `b1;
                12'd1836: toneR = `b1; 12'd1837: toneR = `b1;
                12'd1838: toneR = `b1; 12'd1839: toneR = `b1;

                12'd1840: toneR = `f1B; 12'd1841: toneR = `f1B;
                12'd1842: toneR = `f1B; 12'd1843: toneR = `f1B;
                12'd1844: toneR = `f1B; 12'd1845: toneR = `f1B;
                12'd1846: toneR = `f1B; 12'd1847: toneR = `f1B;
                12'd1848: toneR = `f1B; 12'd1849: toneR = `f1B;
                12'd1850: toneR = `f1B; 12'd1851: toneR = `f1B;
                12'd1852: toneR = `f1B; 12'd1853: toneR = `f1B;
                12'd1854: toneR = `f1B; 12'd1855: toneR = `f1B;
                12'd1856: toneR = `f1B; 12'd1857: toneR = `f1B;
                12'd1858: toneR = `f1B; 12'd1859: toneR = `f1B;
                12'd1860: toneR = `f1B; 12'd1861: toneR = `f1B;
                12'd1862: toneR = `f1B; 12'd1863: toneR = `f1B;
                12'd1864: toneR = `f1B; 12'd1865: toneR = `f1B;
                12'd1866: toneR = `f1B; 12'd1867: toneR = `f1B;
                12'd1868: toneR = `f1B; 12'd1869: toneR = `f1B;
                12'd1870: toneR = `f1B; 12'd1871: toneR = `f1B;
                12'd1872: toneR = `f1B; 12'd1873: toneR = `f1B;
                12'd1874: toneR = `f1B; 12'd1875: toneR = `f1B;
                12'd1876: toneR = `f1B; 12'd1877: toneR = `f1B;
                12'd1878: toneR = `f1B; 12'd1879: toneR = `f1B;
                12'd1880: toneR = `f1B; 12'd1881: toneR = `f1B;
                12'd1882: toneR = `f1B; 12'd1883: toneR = `f1B;
                12'd1884: toneR = `f1B; 12'd1885: toneR = `f1B;
                12'd1886: toneR = `f1B; 12'd1887: toneR = `f1B;
                12'd1888: toneR = `f1B; 12'd1889: toneR = `f1B;
                12'd1890: toneR = `f1B; 12'd1891: toneR = `f1B;
                12'd1892: toneR = `f1B; 12'd1893: toneR = `f1B;
                12'd1894: toneR = `f1B; 12'd1895: toneR = `f1B;
                12'd1896: toneR = `f1B; 12'd1897: toneR = `f1B;
                12'd1898: toneR = `f1B; 12'd1899: toneR = `f1B;
                12'd1900: toneR = `f1B; 12'd1901: toneR = `f1B;
                12'd1902: toneR = `f1B; 12'd1903: toneR = `f1B;
                12'd1904: toneR = `f1B; 12'd1905: toneR = `f1B;
                12'd1906: toneR = `f1B; 12'd1907: toneR = `f1B;
                12'd1908: toneR = `f1B; 12'd1909: toneR = `f1B;
                12'd1910: toneR = `f1B; 12'd1911: toneR = `f1B;
                12'd1912: toneR = `f1B; 12'd1913: toneR = `f1B;
                12'd1914: toneR = `f1B; 12'd1915: toneR = `f1B;
                12'd1916: toneR = `f1B; 12'd1917: toneR = `f1B;
                12'd1918: toneR = `f1B; 12'd1919: toneR = `f1B;

                12'd1920: toneR = `f1B; 12'd1921: toneR = `f1B;
                12'd1922: toneR = `f1B; 12'd1923: toneR = `f1B;
                12'd1924: toneR = `f1B; 12'd1925: toneR = `f1B;
                12'd1926: toneR = `f1B; 12'd1927: toneR = `f1B;
                12'd1928: toneR = `f1B; 12'd1929: toneR = `f1B;
                12'd1930: toneR = `f1B; 12'd1931: toneR = `f1B;
                12'd1932: toneR = `f1B; 12'd1933: toneR = `f1B;
                12'd1934: toneR = `f1B; 12'd1935: toneR = `f1B;
                12'd1936: toneR = `f1B; 12'd1937: toneR = `f1B;
                12'd1938: toneR = `f1B; 12'd1939: toneR = `f1B;
                12'd1940: toneR = `f1B; 12'd1941: toneR = `f1B;
                12'd1942: toneR = `f1B; 12'd1943: toneR = `f1B;
                12'd1944: toneR = `f1B; 12'd1945: toneR = `f1B;
                12'd1946: toneR = `f1B; 12'd1947: toneR = `f1B;
                12'd1948: toneR = `f1B; 12'd1949: toneR = `f1B;
                12'd1950: toneR = `f1B; 12'd1951: toneR = `f1B;

                12'd1952: toneR = `b1; 12'd1953: toneR = `b1;
                12'd1954: toneR = `b1; 12'd1955: toneR = `b1;
                12'd1956: toneR = `b1; 12'd1957: toneR = `b1;
                12'd1958: toneR = `b1; 12'd1959: toneR = `b1;
                12'd1960: toneR = `b1; 12'd1961: toneR = `b1;
                12'd1962: toneR = `b1; 12'd1963: toneR = `b1;
                12'd1964: toneR = `b1; 12'd1965: toneR = `b1;
                12'd1966: toneR = `b1; 12'd1967: toneR = `b1;
                12'd1968: toneR = `b1; 12'd1969: toneR = `b1;
                12'd1970: toneR = `b1; 12'd1971: toneR = `b1;
                12'd1972: toneR = `b1; 12'd1973: toneR = `b1;
                12'd1974: toneR = `b1; 12'd1975: toneR = `b1;
                12'd1976: toneR = `b1; 12'd1977: toneR = `b1;
                12'd1978: toneR = `b1; 12'd1979: toneR = `b1;
                12'd1980: toneR = `b1; 12'd1981: toneR = `b1;
                12'd1982: toneR = `b1; 12'd1983: toneR = `b1;

                12'd1984: toneR = `f1B; 12'd1985: toneR = `f1B;
                12'd1986: toneR = `f1B; 12'd1987: toneR = `f1B;
                12'd1988: toneR = `f1B; 12'd1989: toneR = `f1B;
                12'd1990: toneR = `f1B; 12'd1991: toneR = `f1B;
                12'd1992: toneR = `f1B; 12'd1993: toneR = `f1B;
                12'd1994: toneR = `f1B; 12'd1995: toneR = `f1B;
                12'd1996: toneR = `f1B; 12'd1997: toneR = `f1B;
                12'd1998: toneR = `f1B; 12'd1999: toneR = `f1B;
                12'd2000: toneR = `f1B; 12'd2001: toneR = `f1B;
                12'd2002: toneR = `f1B; 12'd2003: toneR = `f1B;
                12'd2004: toneR = `f1B; 12'd2005: toneR = `f1B;
                12'd2006: toneR = `f1B; 12'd2007: toneR = `f1B;
                12'd2008: toneR = `f1B; 12'd2009: toneR = `f1B;
                12'd2010: toneR = `f1B; 12'd2011: toneR = `f1B;
                12'd2012: toneR = `f1B; 12'd2013: toneR = `f1B;
                12'd2014: toneR = `f1B; 12'd2015: toneR = `f1B;

                12'd2016: toneR = `b1; 12'd2017: toneR = `b1;
                12'd2018: toneR = `b1; 12'd2019: toneR = `b1;
                12'd2020: toneR = `b1; 12'd2021: toneR = `b1;
                12'd2022: toneR = `b1; 12'd2023: toneR = `b1;
                12'd2024: toneR = `b1; 12'd2025: toneR = `b1;
                12'd2026: toneR = `b1; 12'd2027: toneR = `b1;
                12'd2028: toneR = `b1; 12'd2029: toneR = `b1;
                12'd2030: toneR = `b1; 12'd2031: toneR = `b1;
                12'd2032: toneR = `b1; 12'd2033: toneR = `b1;
                12'd2034: toneR = `b1; 12'd2035: toneR = `b1;
                12'd2036: toneR = `b1; 12'd2037: toneR = `b1;
                12'd2038: toneR = `b1; 12'd2039: toneR = `b1;
                12'd2040: toneR = `b1; 12'd2041: toneR = `b1;
                12'd2042: toneR = `b1; 12'd2043: toneR = `b1;
                12'd2044: toneR = `b1; 12'd2045: toneR = `b1;
                12'd2046: toneR = `b1; 12'd2047: toneR = `b1;

                12'd2048: toneR = `a1; 12'd2049: toneR = `a1;
                12'd2050: toneR = `a1; 12'd2051: toneR = `a1;
                12'd2052: toneR = `a1; 12'd2053: toneR = `a1;
                12'd2054: toneR = `a1; 12'd2055: toneR = `a1;
                12'd2056: toneR = `a1; 12'd2057: toneR = `a1;
                12'd2058: toneR = `a1; 12'd2059: toneR = `a1;
                12'd2060: toneR = `a1; 12'd2061: toneR = `a1;
                12'd2062: toneR = `a1; 12'd2063: toneR = `a1;
                12'd2064: toneR = `a1; 12'd2065: toneR = `a1;
                12'd2066: toneR = `a1; 12'd2067: toneR = `a1;
                12'd2068: toneR = `a1; 12'd2069: toneR = `a1;
                12'd2070: toneR = `a1; 12'd2071: toneR = `a1;
                12'd2072: toneR = `a1; 12'd2073: toneR = `a1;
                12'd2074: toneR = `a1; 12'd2075: toneR = `a1;
                12'd2076: toneR = `a1; 12'd2077: toneR = `a1;
                12'd2078: toneR = `a1; 12'd2079: toneR = `a1;
                12'd2080: toneR = `a1; 12'd2081: toneR = `a1;
                12'd2082: toneR = `a1; 12'd2083: toneR = `a1;
                12'd2084: toneR = `a1; 12'd2085: toneR = `a1;
                12'd2086: toneR = `a1; 12'd2087: toneR = `a1;
                12'd2088: toneR = `a1; 12'd2089: toneR = `a1;
                12'd2090: toneR = `a1; 12'd2091: toneR = `a1;
                12'd2092: toneR = `a1; 12'd2093: toneR = `a1;
                12'd2094: toneR = `a1; 12'd2095: toneR = `a1;
                12'd2096: toneR = `a1; 12'd2097: toneR = `a1;
                12'd2098: toneR = `a1; 12'd2099: toneR = `a1;
                12'd2100: toneR = `a1; 12'd2101: toneR = `a1;
                12'd2102: toneR = `a1; 12'd2103: toneR = `a1;
                12'd2104: toneR = `a1; 12'd2105: toneR = `a1;
                12'd2106: toneR = `a1; 12'd2107: toneR = `a1;
                12'd2108: toneR = `a1; 12'd2109: toneR = `a1;
                12'd2110: toneR = `a1; 12'd2111: toneR = `a1;
                12'd2112: toneR = `a1; 12'd2113: toneR = `a1;
                12'd2114: toneR = `a1; 12'd2115: toneR = `a1;
                12'd2116: toneR = `a1; 12'd2117: toneR = `a1;
                12'd2118: toneR = `a1; 12'd2119: toneR = `a1;
                12'd2120: toneR = `a1; 12'd2121: toneR = `a1;
                12'd2122: toneR = `a1; 12'd2123: toneR = `a1;
                12'd2124: toneR = `a1; 12'd2125: toneR = `a1;
                12'd2126: toneR = `a1; 12'd2127: toneR = `a1;
                12'd2128: toneR = `a1; 12'd2129: toneR = `a1;
                12'd2130: toneR = `a1; 12'd2131: toneR = `a1;
                12'd2132: toneR = `a1; 12'd2133: toneR = `a1;
                12'd2134: toneR = `a1; 12'd2135: toneR = `a1;
                12'd2136: toneR = `a1; 12'd2137: toneR = `a1;
                12'd2138: toneR = `a1; 12'd2139: toneR = `a1;
                12'd2140: toneR = `a1; 12'd2141: toneR = `a1;
                12'd2142: toneR = `a1; 12'd2143: toneR = `a1;
                12'd2144: toneR = `a1; 12'd2145: toneR = `a1;
                12'd2146: toneR = `a1; 12'd2147: toneR = `a1;
                12'd2148: toneR = `a1; 12'd2149: toneR = `a1;
                12'd2150: toneR = `a1; 12'd2151: toneR = `a1;
                12'd2152: toneR = `a1; 12'd2153: toneR = `a1;
                12'd2154: toneR = `a1; 12'd2155: toneR = `a1;
                12'd2156: toneR = `a1; 12'd2157: toneR = `a1;
                12'd2158: toneR = `a1; 12'd2159: toneR = `a1;
                12'd2160: toneR = `a1; 12'd2161: toneR = `a1;
                12'd2162: toneR = `a1; 12'd2163: toneR = `a1;
                12'd2164: toneR = `a1; 12'd2165: toneR = `a1;
                12'd2166: toneR = `a1; 12'd2167: toneR = `a1;
                12'd2168: toneR = `a1; 12'd2169: toneR = `a1;
                12'd2170: toneR = `a1; 12'd2171: toneR = `a1;
                12'd2172: toneR = `a1; 12'd2173: toneR = `a1;
                12'd2174: toneR = `a1; 12'd2175: toneR = `a1;
                12'd2176: toneR = `a1; 12'd2177: toneR = `a1;
                12'd2178: toneR = `a1; 12'd2179: toneR = `a1;
                12'd2180: toneR = `a1; 12'd2181: toneR = `a1;
                12'd2182: toneR = `a1; 12'd2183: toneR = `a1;
                12'd2184: toneR = `a1; 12'd2185: toneR = `a1;
                12'd2186: toneR = `a1; 12'd2187: toneR = `a1;
                12'd2188: toneR = `a1; 12'd2189: toneR = `a1;
                12'd2190: toneR = `a1; 12'd2191: toneR = `a1;
                12'd2192: toneR = `a1; 12'd2193: toneR = `a1;
                12'd2194: toneR = `a1; 12'd2195: toneR = `a1;
                12'd2196: toneR = `a1; 12'd2197: toneR = `a1;
                12'd2198: toneR = `a1; 12'd2199: toneR = `a1;
                12'd2200: toneR = `a1; 12'd2201: toneR = `a1;
                12'd2202: toneR = `a1; 12'd2203: toneR = `a1;
                12'd2204: toneR = `a1; 12'd2205: toneR = `a1;
                12'd2206: toneR = `a1; 12'd2207: toneR = `a1;
                12'd2208: toneR = `a1; 12'd2209: toneR = `a1;
                12'd2210: toneR = `a1; 12'd2211: toneR = `a1;
                12'd2212: toneR = `a1; 12'd2213: toneR = `a1;
                12'd2214: toneR = `a1; 12'd2215: toneR = `a1;
                12'd2216: toneR = `a1; 12'd2217: toneR = `a1;
                12'd2218: toneR = `a1; 12'd2219: toneR = `a1;
                12'd2220: toneR = `a1; 12'd2221: toneR = `a1;
                12'd2222: toneR = `a1; 12'd2223: toneR = `a1;
                12'd2224: toneR = `a1; 12'd2225: toneR = `a1;
                12'd2226: toneR = `a1; 12'd2227: toneR = `a1;
                12'd2228: toneR = `a1; 12'd2229: toneR = `a1;
                12'd2230: toneR = `a1; 12'd2231: toneR = `a1;
                12'd2232: toneR = `a1; 12'd2233: toneR = `a1;
                12'd2234: toneR = `a1; 12'd2235: toneR = `a1;
                12'd2236: toneR = `a1; 12'd2237: toneR = `a1;
                12'd2238: toneR = `a1; 12'd2239: toneR = `a1;
                12'd2240: toneR = `a1; 12'd2241: toneR = `a1;
                12'd2242: toneR = `a1; 12'd2243: toneR = `a1;
                12'd2244: toneR = `a1; 12'd2245: toneR = `a1;
                12'd2246: toneR = `a1; 12'd2247: toneR = `a1;
                12'd2248: toneR = `a1; 12'd2249: toneR = `a1;
                12'd2250: toneR = `a1; 12'd2251: toneR = `a1;
                12'd2252: toneR = `a1; 12'd2253: toneR = `a1;
                12'd2254: toneR = `a1; 12'd2255: toneR = `a1;
                12'd2256: toneR = `a1; 12'd2257: toneR = `a1;
                12'd2258: toneR = `a1; 12'd2259: toneR = `a1;
                12'd2260: toneR = `a1; 12'd2261: toneR = `a1;
                12'd2262: toneR = `a1; 12'd2263: toneR = `a1;
                12'd2264: toneR = `a1; 12'd2265: toneR = `a1;
                12'd2266: toneR = `a1; 12'd2267: toneR = `a1;
                12'd2268: toneR = `a1; 12'd2269: toneR = `a1;
                12'd2270: toneR = `a1; 12'd2271: toneR = `a1;
                12'd2272: toneR = `a1; 12'd2273: toneR = `a1;
                12'd2274: toneR = `a1; 12'd2275: toneR = `a1;
                12'd2276: toneR = `a1; 12'd2277: toneR = `a1;
                12'd2278: toneR = `a1; 12'd2279: toneR = `a1;
                12'd2280: toneR = `a1; 12'd2281: toneR = `a1;
                12'd2282: toneR = `a1; 12'd2283: toneR = `a1;
                12'd2284: toneR = `a1; 12'd2285: toneR = `a1;
                12'd2286: toneR = `a1; 12'd2287: toneR = `a1;
                12'd2288: toneR = `a1; 12'd2289: toneR = `a1;
                12'd2290: toneR = `a1; 12'd2291: toneR = `a1;
                12'd2292: toneR = `a1; 12'd2293: toneR = `a1;
                12'd2294: toneR = `a1; 12'd2295: toneR = `a1;
                12'd2296: toneR = `a1; 12'd2297: toneR = `a1;
                12'd2298: toneR = `a1; 12'd2299: toneR = `a1;
                12'd2300: toneR = `a1; 12'd2301: toneR = `a1;
                12'd2302: toneR = `a1; 12'd2303: toneR = `a1;

                12'd2304: toneR = `g1; 12'd2305: toneR = `g1;
                12'd2306: toneR = `g1; 12'd2307: toneR = `g1;
                12'd2308: toneR = `g1; 12'd2309: toneR = `g1;
                12'd2310: toneR = `g1; 12'd2311: toneR = `g1;
                12'd2312: toneR = `g1; 12'd2313: toneR = `g1;
                12'd2314: toneR = `g1; 12'd2315: toneR = `g1;
                12'd2316: toneR = `g1; 12'd2317: toneR = `g1;
                12'd2318: toneR = `g1; 12'd2319: toneR = `g1;
                12'd2320: toneR = `g1; 12'd2321: toneR = `g1;
                12'd2322: toneR = `g1; 12'd2323: toneR = `g1;
                12'd2324: toneR = `g1; 12'd2325: toneR = `g1;
                12'd2326: toneR = `g1; 12'd2327: toneR = `g1;
                12'd2328: toneR = `g1; 12'd2329: toneR = `g1;
                12'd2330: toneR = `g1; 12'd2331: toneR = `g1;
                12'd2332: toneR = `g1; 12'd2333: toneR = `g1;
                12'd2334: toneR = `g1; 12'd2335: toneR = `g1;
                12'd2336: toneR = `g1; 12'd2337: toneR = `g1;
                12'd2338: toneR = `g1; 12'd2339: toneR = `g1;
                12'd2340: toneR = `g1; 12'd2341: toneR = `g1;
                12'd2342: toneR = `g1; 12'd2343: toneR = `g1;
                12'd2344: toneR = `g1; 12'd2345: toneR = `g1;
                12'd2346: toneR = `g1; 12'd2347: toneR = `g1;
                12'd2348: toneR = `g1; 12'd2349: toneR = `g1;
                12'd2350: toneR = `g1; 12'd2351: toneR = `g1;
                12'd2352: toneR = `g1; 12'd2353: toneR = `g1;
                12'd2354: toneR = `g1; 12'd2355: toneR = `g1;
                12'd2356: toneR = `g1; 12'd2357: toneR = `g1;
                12'd2358: toneR = `g1; 12'd2359: toneR = `g1;
                12'd2360: toneR = `g1; 12'd2361: toneR = `g1;
                12'd2362: toneR = `g1; 12'd2363: toneR = `g1;
                12'd2364: toneR = `g1; 12'd2365: toneR = `g1;
                12'd2366: toneR = `g1; 12'd2367: toneR = `g1;
                12'd2368: toneR = `g1; 12'd2369: toneR = `g1;
                12'd2370: toneR = `g1; 12'd2371: toneR = `g1;
                12'd2372: toneR = `g1; 12'd2373: toneR = `g1;
                12'd2374: toneR = `g1; 12'd2375: toneR = `g1;
                12'd2376: toneR = `g1; 12'd2377: toneR = `g1;
                12'd2378: toneR = `g1; 12'd2379: toneR = `g1;
                12'd2380: toneR = `g1; 12'd2381: toneR = `g1;
                12'd2382: toneR = `g1; 12'd2383: toneR = `g1;
                12'd2384: toneR = `g1; 12'd2385: toneR = `g1;
                12'd2386: toneR = `g1; 12'd2387: toneR = `g1;
                12'd2388: toneR = `g1; 12'd2389: toneR = `g1;
                12'd2390: toneR = `g1; 12'd2391: toneR = `g1;
                12'd2392: toneR = `g1; 12'd2393: toneR = `g1;
                12'd2394: toneR = `g1; 12'd2395: toneR = `g1;
                12'd2396: toneR = `g1; 12'd2397: toneR = `g1;
                12'd2398: toneR = `g1; 12'd2399: toneR = `g1;
                12'd2400: toneR = `g1; 12'd2401: toneR = `g1;
                12'd2402: toneR = `g1; 12'd2403: toneR = `g1;
                12'd2404: toneR = `g1; 12'd2405: toneR = `g1;
                12'd2406: toneR = `g1; 12'd2407: toneR = `g1;
                12'd2408: toneR = `g1; 12'd2409: toneR = `g1;
                12'd2410: toneR = `g1; 12'd2411: toneR = `g1;
                12'd2412: toneR = `g1; 12'd2413: toneR = `g1;
                12'd2414: toneR = `g1; 12'd2415: toneR = `g1;
                12'd2416: toneR = `g1; 12'd2417: toneR = `g1;
                12'd2418: toneR = `g1; 12'd2419: toneR = `g1;
                12'd2420: toneR = `g1; 12'd2421: toneR = `g1;
                12'd2422: toneR = `g1; 12'd2423: toneR = `g1;
                12'd2424: toneR = `g1; 12'd2425: toneR = `g1;
                12'd2426: toneR = `g1; 12'd2427: toneR = `g1;
                12'd2428: toneR = `g1; 12'd2429: toneR = `g1;
                12'd2430: toneR = `g1; 12'd2431: toneR = `g1;

                12'd2432: toneR = `d2; 12'd2433: toneR = `d2;
                12'd2434: toneR = `d2; 12'd2435: toneR = `d2;
                12'd2436: toneR = `d2; 12'd2437: toneR = `d2;
                12'd2438: toneR = `d2; 12'd2439: toneR = `d2;
                12'd2440: toneR = `d2; 12'd2441: toneR = `d2;
                12'd2442: toneR = `d2; 12'd2443: toneR = `d2;
                12'd2444: toneR = `d2; 12'd2445: toneR = `d2;
                12'd2446: toneR = `d2; 12'd2447: toneR = `d2;
                12'd2448: toneR = `d2; 12'd2449: toneR = `d2;
                12'd2450: toneR = `d2; 12'd2451: toneR = `d2;
                12'd2452: toneR = `d2; 12'd2453: toneR = `d2;
                12'd2454: toneR = `d2; 12'd2455: toneR = `d2;
                12'd2456: toneR = `d2; 12'd2457: toneR = `d2;
                12'd2458: toneR = `d2; 12'd2459: toneR = `d2;
                12'd2460: toneR = `d2; 12'd2461: toneR = `d2;
                12'd2462: toneR = `d2; 12'd2463: toneR = `d2;
                12'd2464: toneR = `d2; 12'd2465: toneR = `d2;
                12'd2466: toneR = `d2; 12'd2467: toneR = `d2;
                12'd2468: toneR = `d2; 12'd2469: toneR = `d2;
                12'd2470: toneR = `d2; 12'd2471: toneR = `d2;
                12'd2472: toneR = `d2; 12'd2473: toneR = `d2;
                12'd2474: toneR = `d2; 12'd2475: toneR = `d2;
                12'd2476: toneR = `d2; 12'd2477: toneR = `d2;
                12'd2478: toneR = `d2; 12'd2479: toneR = `d2;
                12'd2480: toneR = `d2; 12'd2481: toneR = `d2;
                12'd2482: toneR = `d2; 12'd2483: toneR = `d2;
                12'd2484: toneR = `d2; 12'd2485: toneR = `d2;
                12'd2486: toneR = `d2; 12'd2487: toneR = `d2;
                12'd2488: toneR = `d2; 12'd2489: toneR = `d2;
                12'd2490: toneR = `d2; 12'd2491: toneR = `d2;
                12'd2492: toneR = `d2; 12'd2493: toneR = `d2;
                12'd2494: toneR = `d2; 12'd2495: toneR = `d2;

                12'd2496: toneR = `g1; 12'd2497: toneR = `g1;
                12'd2498: toneR = `g1; 12'd2499: toneR = `g1;
                12'd2500: toneR = `g1; 12'd2501: toneR = `g1;
                12'd2502: toneR = `g1; 12'd2503: toneR = `g1;
                12'd2504: toneR = `g1; 12'd2505: toneR = `g1;
                12'd2506: toneR = `g1; 12'd2507: toneR = `g1;
                12'd2508: toneR = `g1; 12'd2509: toneR = `g1;
                12'd2510: toneR = `g1; 12'd2511: toneR = `g1;
                12'd2512: toneR = `g1; 12'd2513: toneR = `g1;
                12'd2514: toneR = `g1; 12'd2515: toneR = `g1;
                12'd2516: toneR = `g1; 12'd2517: toneR = `g1;
                12'd2518: toneR = `g1; 12'd2519: toneR = `g1;
                12'd2520: toneR = `g1; 12'd2521: toneR = `g1;
                12'd2522: toneR = `g1; 12'd2523: toneR = `g1;
                12'd2524: toneR = `g1; 12'd2525: toneR = `g1;
                12'd2526: toneR = `g1; 12'd2527: toneR = `g1;
                12'd2528: toneR = `g1; 12'd2529: toneR = `g1;
                12'd2530: toneR = `g1; 12'd2531: toneR = `g1;
                12'd2532: toneR = `g1; 12'd2533: toneR = `g1;
                12'd2534: toneR = `g1; 12'd2535: toneR = `g1;
                12'd2536: toneR = `g1; 12'd2537: toneR = `g1;
                12'd2538: toneR = `g1; 12'd2539: toneR = `g1;
                12'd2540: toneR = `g1; 12'd2541: toneR = `g1;
                12'd2542: toneR = `g1; 12'd2543: toneR = `g1;
                12'd2544: toneR = `g1; 12'd2545: toneR = `g1;
                12'd2546: toneR = `g1; 12'd2547: toneR = `g1;
                12'd2548: toneR = `g1; 12'd2549: toneR = `g1;
                12'd2550: toneR = `g1; 12'd2551: toneR = `g1;
                12'd2552: toneR = `g1; 12'd2553: toneR = `g1;
                12'd2554: toneR = `g1; 12'd2555: toneR = `g1;
                12'd2556: toneR = `g1; 12'd2557: toneR = `g1;
                12'd2558: toneR = `g1; 12'd2559: toneR = `g1;

                12'd2560: toneR = `a1; 12'd2561: toneR = `a1;
                12'd2562: toneR = `a1; 12'd2563: toneR = `a1;
                12'd2564: toneR = `a1; 12'd2565: toneR = `a1;
                12'd2566: toneR = `a1; 12'd2567: toneR = `a1;
                12'd2568: toneR = `a1; 12'd2569: toneR = `a1;
                12'd2570: toneR = `a1; 12'd2571: toneR = `a1;
                12'd2572: toneR = `a1; 12'd2573: toneR = `a1;
                12'd2574: toneR = `a1; 12'd2575: toneR = `a1;
                12'd2576: toneR = `a1; 12'd2577: toneR = `a1;
                12'd2578: toneR = `a1; 12'd2579: toneR = `a1;
                12'd2580: toneR = `a1; 12'd2581: toneR = `a1;
                12'd2582: toneR = `a1; 12'd2583: toneR = `a1;
                12'd2584: toneR = `a1; 12'd2585: toneR = `a1;
                12'd2586: toneR = `a1; 12'd2587: toneR = `a1;
                12'd2588: toneR = `a1; 12'd2589: toneR = `a1;
                12'd2590: toneR = `a1; 12'd2591: toneR = `a1;

                12'd2592: toneR = `g0; 12'd2593: toneR = `g0;
                12'd2594: toneR = `g0; 12'd2595: toneR = `g0;
                12'd2596: toneR = `g0; 12'd2597: toneR = `g0;
                12'd2598: toneR = `g0; 12'd2599: toneR = `g0;

                12'd2600: toneR = `a0; 12'd2601: toneR = `a0;
                12'd2602: toneR = `a0; 12'd2603: toneR = `a0;
                12'd2604: toneR = `a0; 12'd2605: toneR = `a0;
                12'd2606: toneR = `a0; 12'd2607: toneR = `a0;

                12'd2608: toneR = `b0; 12'd2609: toneR = `b0;
                12'd2610: toneR = `b0; 12'd2611: toneR = `b0;
                12'd2612: toneR = `b0; 12'd2613: toneR = `b0;
                12'd2614: toneR = `b0; 12'd2615: toneR = `b0;

                12'd2616: toneR = `c1B; 12'd2617: toneR = `c1B;
                12'd2618: toneR = `c1B; 12'd2619: toneR = `c1B;
                12'd2620: toneR = `c1B; 12'd2621: toneR = `c1B;
                12'd2622: toneR = `c1B; 12'd2623: toneR = `c1B;

                12'd2624: toneR = `d1; 12'd2625: toneR = `d1;
                12'd2626: toneR = `d1; 12'd2627: toneR = `d1;
                12'd2628: toneR = `d1; 12'd2629: toneR = `d1;
                12'd2630: toneR = `d1; 12'd2631: toneR = `d1;
                12'd2632: toneR = `d1; 12'd2633: toneR = `d1;
                12'd2634: toneR = `d1; 12'd2635: toneR = `d1;
                12'd2636: toneR = `d1; 12'd2637: toneR = `d1;
                12'd2638: toneR = `d1; 12'd2639: toneR = `d1;
                12'd2640: toneR = `d1; 12'd2641: toneR = `d1;
                12'd2642: toneR = `d1; 12'd2643: toneR = `d1;
                12'd2644: toneR = `d1; 12'd2645: toneR = `d1;
                12'd2646: toneR = `d1; 12'd2647: toneR = `d1;
                12'd2648: toneR = `d1; 12'd2649: toneR = `d1;
                12'd2650: toneR = `d1; 12'd2651: toneR = `d1;
                12'd2652: toneR = `d1; 12'd2653: toneR = `d1;
                12'd2654: toneR = `d1; 12'd2655: toneR = `d1;

                12'd2656: toneR = `f0B; 12'd2657: toneR = `f0B;
                12'd2658: toneR = `f0B; 12'd2659: toneR = `f0B;
                12'd2660: toneR = `f0B; 12'd2661: toneR = `f0B;
                12'd2662: toneR = `f0B; 12'd2663: toneR = `f0B;

                12'd2664: toneR = `g0; 12'd2665: toneR = `g0;
                12'd2666: toneR = `g0; 12'd2667: toneR = `g0;
                12'd2668: toneR = `g0; 12'd2669: toneR = `g0;
                12'd2670: toneR = `g0; 12'd2671: toneR = `g0;

                12'd2672: toneR = `a0; 12'd2673: toneR = `a0;
                12'd2674: toneR = `a0; 12'd2675: toneR = `a0;
                12'd2676: toneR = `a0; 12'd2677: toneR = `a0;
                12'd2678: toneR = `a0; 12'd2679: toneR = `a0;

                12'd2680: toneR = `b0; 12'd2681: toneR = `b0;
                12'd2682: toneR = `b0; 12'd2683: toneR = `b0;
                12'd2684: toneR = `b0; 12'd2685: toneR = `b0;
                12'd2686: toneR = `b0; 12'd2687: toneR = `b0;

                12'd2688: toneR = `c1B; 12'd2689: toneR = `c1B;
                12'd2690: toneR = `c1B; 12'd2691: toneR = `c1B;
                12'd2692: toneR = `c1B; 12'd2693: toneR = `c1B;
                12'd2694: toneR = `c1B; 12'd2695: toneR = `c1B;
                12'd2696: toneR = `c1B; 12'd2697: toneR = `c1B;
                12'd2698: toneR = `c1B; 12'd2699: toneR = `c1B;
                12'd2700: toneR = `c1B; 12'd2701: toneR = `c1B;
                12'd2702: toneR = `c1B; 12'd2703: toneR = `c1B;
                12'd2704: toneR = `c1B; 12'd2705: toneR = `c1B;
                12'd2706: toneR = `c1B; 12'd2707: toneR = `c1B;
                12'd2708: toneR = `c1B; 12'd2709: toneR = `c1B;
                12'd2710: toneR = `c1B; 12'd2711: toneR = `c1B;
                12'd2712: toneR = `c1B; 12'd2713: toneR = `c1B;
                12'd2714: toneR = `c1B; 12'd2715: toneR = `c1B;
                12'd2716: toneR = `c1B; 12'd2717: toneR = `c1B;
                12'd2718: toneR = `c1B; 12'd2719: toneR = `c1B;

                12'd2720: toneR = `g0; 12'd2721: toneR = `g0;
                12'd2722: toneR = `g0; 12'd2723: toneR = `g0;
                12'd2724: toneR = `g0; 12'd2725: toneR = `g0;
                12'd2726: toneR = `g0; 12'd2727: toneR = `g0;

                12'd2728: toneR = `a0; 12'd2729: toneR = `a0;
                12'd2730: toneR = `a0; 12'd2731: toneR = `a0;
                12'd2732: toneR = `a0; 12'd2733: toneR = `a0;
                12'd2734: toneR = `a0; 12'd2735: toneR = `a0;

                12'd2736: toneR = `b0; 12'd2737: toneR = `b0;
                12'd2738: toneR = `b0; 12'd2739: toneR = `b0;
                12'd2740: toneR = `b0; 12'd2741: toneR = `b0;
                12'd2742: toneR = `b0; 12'd2743: toneR = `b0;

                12'd2744: toneR = `c1B; 12'd2745: toneR = `c1B;
                12'd2746: toneR = `c1B; 12'd2747: toneR = `c1B;
                12'd2748: toneR = `c1B; 12'd2749: toneR = `c1B;
                12'd2750: toneR = `c1B; 12'd2751: toneR = `c1B;

                12'd2752: toneR = `d1; 12'd2753: toneR = `d1;
                12'd2754: toneR = `d1; 12'd2755: toneR = `d1;
                12'd2756: toneR = `d1; 12'd2757: toneR = `d1;
                12'd2758: toneR = `d1; 12'd2759: toneR = `d1;
                12'd2760: toneR = `d1; 12'd2761: toneR = `d1;
                12'd2762: toneR = `d1; 12'd2763: toneR = `d1;
                12'd2764: toneR = `d1; 12'd2765: toneR = `d1;
                12'd2766: toneR = `d1; 12'd2767: toneR = `d1;
                12'd2768: toneR = `d1; 12'd2769: toneR = `d1;
                12'd2770: toneR = `d1; 12'd2771: toneR = `d1;
                12'd2772: toneR = `d1; 12'd2773: toneR = `d1;
                12'd2774: toneR = `d1; 12'd2775: toneR = `d1;
                12'd2776: toneR = `d1; 12'd2777: toneR = `d1;
                12'd2778: toneR = `d1; 12'd2779: toneR = `d1;
                12'd2780: toneR = `d1; 12'd2781: toneR = `d1;
                12'd2782: toneR = `d1; 12'd2783: toneR = `d1;

                12'd2784: toneR = `f0B; 12'd2785: toneR = `f0B;
                12'd2786: toneR = `f0B; 12'd2787: toneR = `f0B;
                12'd2788: toneR = `f0B; 12'd2789: toneR = `f0B;
                12'd2790: toneR = `f0B; 12'd2791: toneR = `f0B;

                12'd2792: toneR = `g0; 12'd2793: toneR = `g0;
                12'd2794: toneR = `g0; 12'd2795: toneR = `g0;
                12'd2796: toneR = `g0; 12'd2797: toneR = `g0;
                12'd2798: toneR = `g0; 12'd2799: toneR = `g0;

                12'd2800: toneR = `a0; 12'd2801: toneR = `a0;
                12'd2802: toneR = `a0; 12'd2803: toneR = `a0;
                12'd2804: toneR = `a0; 12'd2805: toneR = `a0;
                12'd2806: toneR = `a0; 12'd2807: toneR = `a0;

                12'd2808: toneR = `b0; 12'd2809: toneR = `b0;
                12'd2810: toneR = `b0; 12'd2811: toneR = `b0;
                12'd2812: toneR = `b0; 12'd2813: toneR = `b0;
                12'd2814: toneR = `b0; 12'd2815: toneR = `b0;

                12'd2816: toneR = `g1; 12'd2817: toneR = `g1;
                12'd2818: toneR = `g1; 12'd2819: toneR = `g1;
                12'd2820: toneR = `g1; 12'd2821: toneR = `g1;
                12'd2822: toneR = `g1; 12'd2823: toneR = `g1;
                12'd2824: toneR = `g1; 12'd2825: toneR = `g1;
                12'd2826: toneR = `g1; 12'd2827: toneR = `g1;
                12'd2828: toneR = `g1; 12'd2829: toneR = `g1;
                12'd2830: toneR = `g1; 12'd2831: toneR = `g1;
                12'd2832: toneR = `g1; 12'd2833: toneR = `g1;
                12'd2834: toneR = `g1; 12'd2835: toneR = `g1;
                12'd2836: toneR = `g1; 12'd2837: toneR = `g1;
                12'd2838: toneR = `g1; 12'd2839: toneR = `g1;
                12'd2840: toneR = `g1; 12'd2841: toneR = `g1;
                12'd2842: toneR = `g1; 12'd2843: toneR = `g1;
                12'd2844: toneR = `g1; 12'd2845: toneR = `g1;
                12'd2846: toneR = `g1; 12'd2847: toneR = `g1;
                12'd2848: toneR = `g1; 12'd2849: toneR = `g1;
                12'd2850: toneR = `g1; 12'd2851: toneR = `g1;
                12'd2852: toneR = `g1; 12'd2853: toneR = `g1;
                12'd2854: toneR = `g1; 12'd2855: toneR = `g1;
                12'd2856: toneR = `g1; 12'd2857: toneR = `g1;
                12'd2858: toneR = `g1; 12'd2859: toneR = `g1;
                12'd2860: toneR = `g1; 12'd2861: toneR = `g1;
                12'd2862: toneR = `g1; 12'd2863: toneR = `g1;
                12'd2864: toneR = `g1; 12'd2865: toneR = `g1;
                12'd2866: toneR = `g1; 12'd2867: toneR = `g1;
                12'd2868: toneR = `g1; 12'd2869: toneR = `g1;
                12'd2870: toneR = `g1; 12'd2871: toneR = `g1;
                12'd2872: toneR = `g1; 12'd2873: toneR = `g1;
                12'd2874: toneR = `g1; 12'd2875: toneR = `g1;
                12'd2876: toneR = `g1; 12'd2877: toneR = `g1;
                12'd2878: toneR = `g1; 12'd2879: toneR = `g1;
                12'd2880: toneR = `g1; 12'd2881: toneR = `g1;
                12'd2882: toneR = `g1; 12'd2883: toneR = `g1;
                12'd2884: toneR = `g1; 12'd2885: toneR = `g1;
                12'd2886: toneR = `g1; 12'd2887: toneR = `g1;
                12'd2888: toneR = `g1; 12'd2889: toneR = `g1;
                12'd2890: toneR = `g1; 12'd2891: toneR = `g1;
                12'd2892: toneR = `g1; 12'd2893: toneR = `g1;
                12'd2894: toneR = `g1; 12'd2895: toneR = `g1;
                12'd2896: toneR = `g1; 12'd2897: toneR = `g1;
                12'd2898: toneR = `g1; 12'd2899: toneR = `g1;
                12'd2900: toneR = `g1; 12'd2901: toneR = `g1;
                12'd2902: toneR = `g1; 12'd2903: toneR = `g1;
                12'd2904: toneR = `g1; 12'd2905: toneR = `g1;
                12'd2906: toneR = `g1; 12'd2907: toneR = `g1;
                12'd2908: toneR = `g1; 12'd2909: toneR = `g1;
                12'd2910: toneR = `g1; 12'd2911: toneR = `g1;
                12'd2912: toneR = `g1; 12'd2913: toneR = `g1;
                12'd2914: toneR = `g1; 12'd2915: toneR = `g1;
                12'd2916: toneR = `g1; 12'd2917: toneR = `g1;
                12'd2918: toneR = `g1; 12'd2919: toneR = `g1;
                12'd2920: toneR = `g1; 12'd2921: toneR = `g1;
                12'd2922: toneR = `g1; 12'd2923: toneR = `g1;
                12'd2924: toneR = `g1; 12'd2925: toneR = `g1;
                12'd2926: toneR = `g1; 12'd2927: toneR = `g1;
                12'd2928: toneR = `g1; 12'd2929: toneR = `g1;
                12'd2930: toneR = `g1; 12'd2931: toneR = `g1;
                12'd2932: toneR = `g1; 12'd2933: toneR = `g1;
                12'd2934: toneR = `g1; 12'd2935: toneR = `g1;
                12'd2936: toneR = `g1; 12'd2937: toneR = `g1;
                12'd2938: toneR = `g1; 12'd2939: toneR = `g1;
                12'd2940: toneR = `g1; 12'd2941: toneR = `g1;
                12'd2942: toneR = `g1; 12'd2943: toneR = `g1;

                12'd2944: toneR = `e2; 12'd2945: toneR = `e2;
                12'd2946: toneR = `e2; 12'd2947: toneR = `e2;
                12'd2948: toneR = `e2; 12'd2949: toneR = `e2;
                12'd2950: toneR = `e2; 12'd2951: toneR = `e2;
                12'd2952: toneR = `e2; 12'd2953: toneR = `e2;
                12'd2954: toneR = `e2; 12'd2955: toneR = `e2;
                12'd2956: toneR = `e2; 12'd2957: toneR = `e2;
                12'd2958: toneR = `e2; 12'd2959: toneR = `e2;
                12'd2960: toneR = `e2; 12'd2961: toneR = `e2;
                12'd2962: toneR = `e2; 12'd2963: toneR = `e2;
                12'd2964: toneR = `e2; 12'd2965: toneR = `e2;
                12'd2966: toneR = `e2; 12'd2967: toneR = `e2;
                12'd2968: toneR = `e2; 12'd2969: toneR = `e2;
                12'd2970: toneR = `e2; 12'd2971: toneR = `e2;
                12'd2972: toneR = `e2; 12'd2973: toneR = `e2;
                12'd2974: toneR = `e2; 12'd2975: toneR = `e2;
                12'd2976: toneR = `e2; 12'd2977: toneR = `e2;
                12'd2978: toneR = `e2; 12'd2979: toneR = `e2;
                12'd2980: toneR = `e2; 12'd2981: toneR = `e2;
                12'd2982: toneR = `e2; 12'd2983: toneR = `e2;
                12'd2984: toneR = `e2; 12'd2985: toneR = `e2;
                12'd2986: toneR = `e2; 12'd2987: toneR = `e2;
                12'd2988: toneR = `e2; 12'd2989: toneR = `e2;
                12'd2990: toneR = `e2; 12'd2991: toneR = `e2;
                12'd2992: toneR = `e2; 12'd2993: toneR = `e2;
                12'd2994: toneR = `e2; 12'd2995: toneR = `e2;
                12'd2996: toneR = `e2; 12'd2997: toneR = `e2;
                12'd2998: toneR = `e2; 12'd2999: toneR = `e2;
                12'd3000: toneR = `e2; 12'd3001: toneR = `e2;
                12'd3002: toneR = `e2; 12'd3003: toneR = `e2;
                12'd3004: toneR = `e2; 12'd3005: toneR = `e2;
                12'd3006: toneR = `e2; 12'd3007: toneR = `e2;

                12'd3008: toneR = `f2B; 12'd3009: toneR = `f2B;
                12'd3010: toneR = `f2B; 12'd3011: toneR = `f2B;
                12'd3012: toneR = `f2B; 12'd3013: toneR = `f2B;
                12'd3014: toneR = `f2B; 12'd3015: toneR = `f2B;
                12'd3016: toneR = `f2B; 12'd3017: toneR = `f2B;
                12'd3018: toneR = `f2B; 12'd3019: toneR = `f2B;
                12'd3020: toneR = `f2B; 12'd3021: toneR = `f2B;
                12'd3022: toneR = `f2B; 12'd3023: toneR = `f2B;
                12'd3024: toneR = `f2B; 12'd3025: toneR = `f2B;
                12'd3026: toneR = `f2B; 12'd3027: toneR = `f2B;
                12'd3028: toneR = `f2B; 12'd3029: toneR = `f2B;
                12'd3030: toneR = `f2B; 12'd3031: toneR = `f2B;
                12'd3032: toneR = `f2B; 12'd3033: toneR = `f2B;
                12'd3034: toneR = `f2B; 12'd3035: toneR = `f2B;
                12'd3036: toneR = `f2B; 12'd3037: toneR = `f2B;
                12'd3038: toneR = `f2B; 12'd3039: toneR = `f2B;
                12'd3040: toneR = `f2B; 12'd3041: toneR = `f2B;
                12'd3042: toneR = `f2B; 12'd3043: toneR = `f2B;
                12'd3044: toneR = `f2B; 12'd3045: toneR = `f2B;
                12'd3046: toneR = `f2B; 12'd3047: toneR = `f2B;
                12'd3048: toneR = `f2B; 12'd3049: toneR = `f2B;
                12'd3050: toneR = `f2B; 12'd3051: toneR = `f2B;
                12'd3052: toneR = `f2B; 12'd3053: toneR = `f2B;
                12'd3054: toneR = `f2B; 12'd3055: toneR = `f2B;
                12'd3056: toneR = `f2B; 12'd3057: toneR = `f2B;
                12'd3058: toneR = `f2B; 12'd3059: toneR = `f2B;
                12'd3060: toneR = `f2B; 12'd3061: toneR = `f2B;
                12'd3062: toneR = `f2B; 12'd3063: toneR = `f2B;
                12'd3064: toneR = `f2B; 12'd3065: toneR = `f2B;
                12'd3066: toneR = `f2B; 12'd3067: toneR = `f2B;
                12'd3068: toneR = `f2B; 12'd3069: toneR = `f2B;
                12'd3070: toneR = `f2B; 12'd3071: toneR = `f2B;

                12'd3072: toneR = `e2; 12'd3073: toneR = `e2;
                12'd3074: toneR = `e2; 12'd3075: toneR = `e2;
                12'd3076: toneR = `e2; 12'd3077: toneR = `e2;
                12'd3078: toneR = `e2; 12'd3079: toneR = `e2;
                12'd3080: toneR = `e2; 12'd3081: toneR = `e2;
                12'd3082: toneR = `e2; 12'd3083: toneR = `e2;
                12'd3084: toneR = `e2; 12'd3085: toneR = `e2;
                12'd3086: toneR = `e2; 12'd3087: toneR = `e2;
                12'd3088: toneR = `e2; 12'd3089: toneR = `e2;
                12'd3090: toneR = `e2; 12'd3091: toneR = `e2;
                12'd3092: toneR = `e2; 12'd3093: toneR = `e2;
                12'd3094: toneR = `e2; 12'd3095: toneR = `e2;
                12'd3096: toneR = `e2; 12'd3097: toneR = `e2;
                12'd3098: toneR = `e2; 12'd3099: toneR = `e2;
                12'd3100: toneR = `e2; 12'd3101: toneR = `e2;
                12'd3102: toneR = `e2; 12'd3103: toneR = `e2;
                12'd3104: toneR = `e2; 12'd3105: toneR = `e2;
                12'd3106: toneR = `e2; 12'd3107: toneR = `e2;
                12'd3108: toneR = `e2; 12'd3109: toneR = `e2;
                12'd3110: toneR = `e2; 12'd3111: toneR = `e2;
                12'd3112: toneR = `e2; 12'd3113: toneR = `e2;
                12'd3114: toneR = `e2; 12'd3115: toneR = `e2;
                12'd3116: toneR = `e2; 12'd3117: toneR = `e2;
                12'd3118: toneR = `e2; 12'd3119: toneR = `e2;
                12'd3120: toneR = `e2; 12'd3121: toneR = `e2;
                12'd3122: toneR = `e2; 12'd3123: toneR = `e2;
                12'd3124: toneR = `e2; 12'd3125: toneR = `e2;
                12'd3126: toneR = `e2; 12'd3127: toneR = `e2;
                12'd3128: toneR = `e2; 12'd3129: toneR = `e2;
                12'd3130: toneR = `e2; 12'd3131: toneR = `e2;
                12'd3132: toneR = `e2; 12'd3133: toneR = `e2;
                12'd3134: toneR = `e2; 12'd3135: toneR = `e2;
                12'd3136: toneR = `e2; 12'd3137: toneR = `e2;
                12'd3138: toneR = `e2; 12'd3139: toneR = `e2;
                12'd3140: toneR = `e2; 12'd3141: toneR = `e2;
                12'd3142: toneR = `e2; 12'd3143: toneR = `e2;
                12'd3144: toneR = `e2; 12'd3145: toneR = `e2;
                12'd3146: toneR = `e2; 12'd3147: toneR = `e2;
                12'd3148: toneR = `e2; 12'd3149: toneR = `e2;
                12'd3150: toneR = `e2; 12'd3151: toneR = `e2;
                12'd3152: toneR = `e2; 12'd3153: toneR = `e2;
                12'd3154: toneR = `e2; 12'd3155: toneR = `e2;
                12'd3156: toneR = `e2; 12'd3157: toneR = `e2;
                12'd3158: toneR = `e2; 12'd3159: toneR = `e2;
                12'd3160: toneR = `e2; 12'd3161: toneR = `e2;
                12'd3162: toneR = `e2; 12'd3163: toneR = `e2;
                12'd3164: toneR = `e2; 12'd3165: toneR = `e2;
                12'd3166: toneR = `e2; 12'd3167: toneR = `e2;
                12'd3168: toneR = `e2; 12'd3169: toneR = `e2;
                12'd3170: toneR = `e2; 12'd3171: toneR = `e2;
                12'd3172: toneR = `e2; 12'd3173: toneR = `e2;
                12'd3174: toneR = `e2; 12'd3175: toneR = `e2;
                12'd3176: toneR = `e2; 12'd3177: toneR = `e2;
                12'd3178: toneR = `e2; 12'd3179: toneR = `e2;
                12'd3180: toneR = `e2; 12'd3181: toneR = `e2;
                12'd3182: toneR = `e2; 12'd3183: toneR = `e2;
                12'd3184: toneR = `e2; 12'd3185: toneR = `e2;
                12'd3186: toneR = `e2; 12'd3187: toneR = `e2;
                12'd3188: toneR = `e2; 12'd3189: toneR = `e2;
                12'd3190: toneR = `e2; 12'd3191: toneR = `e2;
                12'd3192: toneR = `e2; 12'd3193: toneR = `e2;
                12'd3194: toneR = `e2; 12'd3195: toneR = `e2;
                12'd3196: toneR = `e2; 12'd3197: toneR = `e2;
                12'd3198: toneR = `e2; 12'd3199: toneR = `e2;

                12'd3200: toneR = `g2; 12'd3201: toneR = `g2;
                12'd3202: toneR = `g2; 12'd3203: toneR = `g2;
                12'd3204: toneR = `g2; 12'd3205: toneR = `g2;
                12'd3206: toneR = `g2; 12'd3207: toneR = `g2;
                12'd3208: toneR = `g2; 12'd3209: toneR = `g2;
                12'd3210: toneR = `g2; 12'd3211: toneR = `g2;
                12'd3212: toneR = `g2; 12'd3213: toneR = `g2;
                12'd3214: toneR = `g2; 12'd3215: toneR = `g2;
                12'd3216: toneR = `g2; 12'd3217: toneR = `g2;
                12'd3218: toneR = `g2; 12'd3219: toneR = `g2;
                12'd3220: toneR = `g2; 12'd3221: toneR = `g2;
                12'd3222: toneR = `g2; 12'd3223: toneR = `g2;
                12'd3224: toneR = `g2; 12'd3225: toneR = `g2;
                12'd3226: toneR = `g2; 12'd3227: toneR = `g2;
                12'd3228: toneR = `g2; 12'd3229: toneR = `g2;
                12'd3230: toneR = `g2; 12'd3231: toneR = `g2;

                12'd3232: toneR = `a2; 12'd3233: toneR = `a2;
                12'd3234: toneR = `a2; 12'd3235: toneR = `a2;
                12'd3236: toneR = `a2; 12'd3237: toneR = `a2;
                12'd3238: toneR = `a2; 12'd3239: toneR = `a2;
                12'd3240: toneR = `a2; 12'd3241: toneR = `a2;
                12'd3242: toneR = `a2; 12'd3243: toneR = `a2;
                12'd3244: toneR = `a2; 12'd3245: toneR = `a2;
                12'd3246: toneR = `a2; 12'd3247: toneR = `a2;

                12'd3248: toneR = `g2; 12'd3249: toneR = `g2;
                12'd3250: toneR = `g2; 12'd3251: toneR = `g2;
                12'd3252: toneR = `g2; 12'd3253: toneR = `g2;
                12'd3254: toneR = `g2; 12'd3255: toneR = `g2;
                12'd3256: toneR = `g2; 12'd3257: toneR = `g2;
                12'd3258: toneR = `g2; 12'd3259: toneR = `g2;
                12'd3260: toneR = `g2; 12'd3261: toneR = `g2;
                12'd3262: toneR = `g2; 12'd3263: toneR = `g2;

                12'd3264: toneR = `f2B; 12'd3265: toneR = `f2B;
                12'd3266: toneR = `f2B; 12'd3267: toneR = `f2B;
                12'd3268: toneR = `f2B; 12'd3269: toneR = `f2B;
                12'd3270: toneR = `f2B; 12'd3271: toneR = `f2B;
                12'd3272: toneR = `f2B; 12'd3273: toneR = `f2B;
                12'd3274: toneR = `f2B; 12'd3275: toneR = `f2B;
                12'd3276: toneR = `f2B; 12'd3277: toneR = `f2B;
                12'd3278: toneR = `f2B; 12'd3279: toneR = `f2B;

                12'd3280: toneR = `e2; 12'd3281: toneR = `e2;
                12'd3282: toneR = `e2; 12'd3283: toneR = `e2;
                12'd3284: toneR = `e2; 12'd3285: toneR = `e2;
                12'd3286: toneR = `e2; 12'd3287: toneR = `e2;
                12'd3288: toneR = `e2; 12'd3289: toneR = `e2;
                12'd3290: toneR = `e2; 12'd3291: toneR = `e2;
                12'd3292: toneR = `e2; 12'd3293: toneR = `e2;
                12'd3294: toneR = `e2; 12'd3295: toneR = `e2;   

                12'd3296: toneR = `d2; 12'd3297: toneR = `d2;
                12'd3298: toneR = `d2; 12'd3299: toneR = `d2;
                12'd3300: toneR = `d2; 12'd3301: toneR = `d2;
                12'd3302: toneR = `d2; 12'd3303: toneR = `d2;
                12'd3304: toneR = `d2; 12'd3305: toneR = `d2;
                12'd3306: toneR = `d2; 12'd3307: toneR = `d2;
                12'd3308: toneR = `d2; 12'd3309: toneR = `d2;
                12'd3310: toneR = `d2; 12'd3311: toneR = `d2;

                12'd3312: toneR = `e2; 12'd3313: toneR = `e2;
                12'd3314: toneR = `e2; 12'd3315: toneR = `e2;
                12'd3316: toneR = `e2; 12'd3317: toneR = `e2;
                12'd3318: toneR = `e2; 12'd3319: toneR = `e2;
                12'd3320: toneR = `e2; 12'd3321: toneR = `e2;
                12'd3322: toneR = `e2; 12'd3323: toneR = `e2;
                12'd3324: toneR = `e2; 12'd3325: toneR = `e2;
                12'd3326: toneR = `e2; 12'd3327: toneR = `e2;

                12'd3328: toneR = `f2B; 12'd3329: toneR = `f2B;
                12'd3330: toneR = `f2B; 12'd3331: toneR = `f2B;
                12'd3332: toneR = `f2B; 12'd3333: toneR = `f2B;
                12'd3334: toneR = `f2B; 12'd3335: toneR = `f2B;
                12'd3336: toneR = `f2B; 12'd3337: toneR = `f2B;
                12'd3338: toneR = `f2B; 12'd3339: toneR = `f2B;
                12'd3340: toneR = `f2B; 12'd3341: toneR = `f2B;
                12'd3342: toneR = `f2B; 12'd3343: toneR = `f2B;
                12'd3344: toneR = `f2B; 12'd3345: toneR = `f2B;
                12'd3346: toneR = `f2B; 12'd3347: toneR = `f2B;
                12'd3348: toneR = `f2B; 12'd3349: toneR = `f2B;
                12'd3350: toneR = `f2B; 12'd3351: toneR = `f2B;
                12'd3352: toneR = `f2B; 12'd3353: toneR = `f2B;
                12'd3354: toneR = `f2B; 12'd3355: toneR = `f2B;
                12'd3356: toneR = `f2B; 12'd3357: toneR = `f2B;
                12'd3358: toneR = `f2B; 12'd3359: toneR = `f2B;
                12'd3360: toneR = `f2B; 12'd3361: toneR = `f2B;
                12'd3362: toneR = `f2B; 12'd3363: toneR = `f2B;
                12'd3364: toneR = `f2B; 12'd3365: toneR = `f2B;
                12'd3366: toneR = `f2B; 12'd3367: toneR = `f2B;
                12'd3368: toneR = `f2B; 12'd3369: toneR = `f2B;
                12'd3370: toneR = `f2B; 12'd3371: toneR = `f2B;
                12'd3372: toneR = `f2B; 12'd3373: toneR = `f2B;
                12'd3374: toneR = `f2B; 12'd3375: toneR = `f2B;
                12'd3376: toneR = `f2B; 12'd3377: toneR = `f2B;
                12'd3378: toneR = `f2B; 12'd3379: toneR = `f2B;
                12'd3380: toneR = `f2B; 12'd3381: toneR = `f2B;
                12'd3382: toneR = `f2B; 12'd3383: toneR = `f2B;
                12'd3384: toneR = `f2B; 12'd3385: toneR = `f2B;
                12'd3386: toneR = `f2B; 12'd3387: toneR = `f2B;
                12'd3388: toneR = `f2B; 12'd3389: toneR = `f2B;
                12'd3390: toneR = `f2B; 12'd3391: toneR = `f2B;
                12'd3392: toneR = `f2B; 12'd3393: toneR = `f2B;
                12'd3394: toneR = `f2B; 12'd3395: toneR = `f2B;
                12'd3396: toneR = `f2B; 12'd3397: toneR = `f2B;
                12'd3398: toneR = `f2B; 12'd3399: toneR = `f2B;
                12'd3400: toneR = `f2B; 12'd3401: toneR = `f2B;
                12'd3402: toneR = `f2B; 12'd3403: toneR = `f2B;
                12'd3404: toneR = `f2B; 12'd3405: toneR = `f2B;
                12'd3406: toneR = `f2B; 12'd3407: toneR = `f2B;
                12'd3408: toneR = `f2B; 12'd3409: toneR = `f2B;
                12'd3410: toneR = `f2B; 12'd3411: toneR = `f2B;
                12'd3412: toneR = `f2B; 12'd3413: toneR = `f2B;
                12'd3414: toneR = `f2B; 12'd3415: toneR = `f2B;
                12'd3416: toneR = `f2B; 12'd3417: toneR = `f2B;
                12'd3418: toneR = `f2B; 12'd3419: toneR = `f2B;
                12'd3420: toneR = `f2B; 12'd3421: toneR = `f2B;
                12'd3422: toneR = `f2B; 12'd3423: toneR = `f2B;
                12'd3424: toneR = `f2B; 12'd3425: toneR = `f2B;
                12'd3426: toneR = `f2B; 12'd3427: toneR = `f2B;
                12'd3428: toneR = `f2B; 12'd3429: toneR = `f2B;
                12'd3430: toneR = `f2B; 12'd3431: toneR = `f2B;
                12'd3432: toneR = `f2B; 12'd3433: toneR = `f2B;
                12'd3434: toneR = `f2B; 12'd3435: toneR = `f2B;
                12'd3436: toneR = `f2B; 12'd3437: toneR = `f2B;
                12'd3438: toneR = `f2B; 12'd3439: toneR = `f2B;
                12'd3440: toneR = `f2B; 12'd3441: toneR = `f2B;
                12'd3442: toneR = `f2B; 12'd3443: toneR = `f2B;
                12'd3444: toneR = `f2B; 12'd3445: toneR = `f2B;
                12'd3446: toneR = `f2B; 12'd3447: toneR = `f2B;
                12'd3448: toneR = `f2B; 12'd3449: toneR = `f2B;
                12'd3450: toneR = `f2B; 12'd3451: toneR = `f2B;
                12'd3452: toneR = `f2B; 12'd3453: toneR = `f2B;
                12'd3454: toneR = `f2B; 12'd3455: toneR = `f2B;
                12'd3456: toneR = `f2B; 12'd3457: toneR = `f2B;
                12'd3458: toneR = `f2B; 12'd3459: toneR = `f2B;
                12'd3460: toneR = `f2B; 12'd3461: toneR = `f2B;
                12'd3462: toneR = `f2B; 12'd3463: toneR = `f2B;
                12'd3464: toneR = `f2B; 12'd3465: toneR = `f2B;
                12'd3466: toneR = `f2B; 12'd3467: toneR = `f2B;
                12'd3468: toneR = `f2B; 12'd3469: toneR = `f2B;
                12'd3470: toneR = `f2B; 12'd3471: toneR = `f2B;
                12'd3472: toneR = `f2B; 12'd3473: toneR = `f2B;
                12'd3474: toneR = `f2B; 12'd3475: toneR = `f2B;
                12'd3476: toneR = `f2B; 12'd3477: toneR = `f2B;
                12'd3478: toneR = `f2B; 12'd3479: toneR = `f2B;
                12'd3480: toneR = `f2B; 12'd3481: toneR = `f2B;
                12'd3482: toneR = `f2B; 12'd3483: toneR = `f2B;
                12'd3484: toneR = `f2B; 12'd3485: toneR = `f2B;
                12'd3486: toneR = `f2B; 12'd3487: toneR = `f2B;
                12'd3488: toneR = `f2B; 12'd3489: toneR = `f2B;
                12'd3490: toneR = `f2B; 12'd3491: toneR = `f2B;
                12'd3492: toneR = `f2B; 12'd3493: toneR = `f2B;
                12'd3494: toneR = `f2B; 12'd3495: toneR = `f2B;
                12'd3496: toneR = `f2B; 12'd3497: toneR = `f2B;
                12'd3498: toneR = `f2B; 12'd3499: toneR = `f2B;
                12'd3500: toneR = `f2B; 12'd3501: toneR = `f2B;
                12'd3502: toneR = `f2B; 12'd3503: toneR = `f2B;
                12'd3504: toneR = `f2B; 12'd3505: toneR = `f2B;
                12'd3506: toneR = `f2B; 12'd3507: toneR = `f2B;
                12'd3508: toneR = `f2B; 12'd3509: toneR = `f2B;
                12'd3510: toneR = `f2B; 12'd3511: toneR = `f2B;
                12'd3512: toneR = `f2B; 12'd3513: toneR = `f2B;
                12'd3514: toneR = `f2B; 12'd3515: toneR = `f2B;
                12'd3516: toneR = `f2B; 12'd3517: toneR = `f2B;
                12'd3518: toneR = `f2B; 12'd3519: toneR = `f2B;
                12'd3520: toneR = `f2B; 12'd3521: toneR = `f2B;
                12'd3522: toneR = `f2B; 12'd3523: toneR = `f2B;
                12'd3524: toneR = `f2B; 12'd3525: toneR = `f2B;
                12'd3526: toneR = `f2B; 12'd3527: toneR = `f2B;
                12'd3528: toneR = `f2B; 12'd3529: toneR = `f2B;
                12'd3530: toneR = `f2B; 12'd3531: toneR = `f2B;
                12'd3532: toneR = `f2B; 12'd3533: toneR = `f2B;
                12'd3534: toneR = `f2B; 12'd3535: toneR = `f2B;
                12'd3536: toneR = `f2B; 12'd3537: toneR = `f2B;
                12'd3538: toneR = `f2B; 12'd3539: toneR = `f2B;
                12'd3540: toneR = `f2B; 12'd3541: toneR = `f2B;
                12'd3542: toneR = `f2B; 12'd3543: toneR = `f2B;
                12'd3544: toneR = `f2B; 12'd3545: toneR = `f2B;
                12'd3546: toneR = `f2B; 12'd3547: toneR = `f2B;
                12'd3548: toneR = `f2B; 12'd3549: toneR = `f2B;
                12'd3550: toneR = `f2B; 12'd3551: toneR = `f2B;
                12'd3552: toneR = `f2B; 12'd3553: toneR = `f2B;
                12'd3554: toneR = `f2B; 12'd3555: toneR = `f2B;
                12'd3556: toneR = `f2B; 12'd3557: toneR = `f2B;
                12'd3558: toneR = `f2B; 12'd3559: toneR = `f2B;
                12'd3560: toneR = `f2B; 12'd3561: toneR = `f2B;
                12'd3562: toneR = `f2B; 12'd3563: toneR = `f2B;
                12'd3564: toneR = `f2B; 12'd3565: toneR = `f2B;
                12'd3566: toneR = `f2B; 12'd3567: toneR = `f2B;
                12'd3568: toneR = `f2B; 12'd3569: toneR = `f2B;
                12'd3570: toneR = `f2B; 12'd3571: toneR = `f2B;
                12'd3572: toneR = `f2B; 12'd3573: toneR = `f2B;
                12'd3574: toneR = `f2B; 12'd3575: toneR = `f2B;
                12'd3576: toneR = `f2B; 12'd3577: toneR = `f2B;
                12'd3578: toneR = `f2B; 12'd3579: toneR = `f2B;
                12'd3580: toneR = `f2B; 12'd3581: toneR = `f2B;
                12'd3582: toneR = `f2B; 12'd3583: toneR = `f2B;

                default: toneR = `sil;
            endcase
    end

    always @(*) begin
            case(ibeatNum)
                12'd0: toneL = `b0; 12'd1: toneL = `b0;
                12'd2: toneL = `b0; 12'd3: toneL = `b0;
                12'd4: toneL = `b0; 12'd5: toneL = `b0;
                12'd6: toneL = `b0; 12'd7: toneL = `b0;

                12'd8: toneL = `b0b; 12'd9: toneL = `b0b;
                12'd10: toneL = `b0b; 12'd11: toneL = `b0b;
                12'd12: toneL = `b0b; 12'd13: toneL = `b0b;
                12'd14: toneL = `b0b; 12'd15: toneL = `b0b;

                12'd16: toneL = `a0; 12'd17: toneL = `a0;
                12'd18: toneL = `a0; 12'd19: toneL = `a0;
                12'd20: toneL = `a0; 12'd21: toneL = `a0;
                12'd22: toneL = `a0; 12'd23: toneL = `a0;

                12'd24: toneL = `a0b; 12'd25: toneL = `a0b;
                12'd26: toneL = `a0b; 12'd27: toneL = `a0b;
                12'd28: toneL = `a0b; 12'd29: toneL = `a0b;
                12'd30: toneL = `a0b; 12'd31: toneL = `a0b;

                12'd32: toneL = `b0; 12'd33: toneL = `b0;
                12'd34: toneL = `b0; 12'd35: toneL = `b0;
                12'd36: toneL = `b0; 12'd37: toneL = `b0;
                12'd38: toneL = `b0; 12'd39: toneL = `b0;

                12'd40: toneL = `a0; 12'd41: toneL = `a0;
                12'd42: toneL = `a0; 12'd43: toneL = `a0;
                12'd44: toneL = `a0; 12'd45: toneL = `a0;
                12'd46: toneL = `a0; 12'd47: toneL = `a0;

                12'd48: toneL = `a0b; 12'd49: toneL = `a0b;
                12'd50: toneL = `a0b; 12'd51: toneL = `a0b;
                12'd52: toneL = `a0b; 12'd53: toneL = `a0b;
                12'd54: toneL = `a0b; 12'd55: toneL = `a0b;

                12'd56: toneL = `g0; 12'd57: toneL = `g0;
                12'd58: toneL = `g0; 12'd59: toneL = `g0;
                12'd60: toneL = `g0; 12'd61: toneL = `g0;
                12'd62: toneL = `g0; 12'd63: toneL = `g0;

                12'd64: toneL = `a0; 12'd65: toneL = `a0;
                12'd66: toneL = `a0; 12'd67: toneL = `a0;
                12'd68: toneL = `a0; 12'd69: toneL = `a0;
                12'd70: toneL = `a0; 12'd71: toneL = `a0;

                12'd72: toneL = `a0b; 12'd73: toneL = `a0b;
                12'd74: toneL = `a0b; 12'd75: toneL = `a0b;
                12'd76: toneL = `a0b; 12'd77: toneL = `a0b;
                12'd78: toneL = `a0b; 12'd79: toneL = `a0b;

                12'd80: toneL = `g0; 12'd81: toneL = `g0;
                12'd82: toneL = `g0; 12'd83: toneL = `g0;
                12'd84: toneL = `g0; 12'd85: toneL = `g0;
                12'd86: toneL = `g0; 12'd87: toneL = `g0;

                12'd88: toneL = `g0b; 12'd89: toneL = `g0b;
                12'd90: toneL = `g0b; 12'd91: toneL = `g0b;
                12'd92: toneL = `g0b; 12'd93: toneL = `g0b;
                12'd94: toneL = `g0b; 12'd95: toneL = `g0b;

                12'd96: toneL = `a0; 12'd97: toneL = `a0;
                12'd98: toneL = `a0; 12'd99: toneL = `a0;
                12'd100: toneL = `a0; 12'd101: toneL = `a0;
                12'd102: toneL = `a0; 12'd103: toneL = `a0;

                12'd104: toneL = `g0; 12'd105: toneL = `g0;
                12'd106: toneL = `g0; 12'd107: toneL = `g0;
                12'd108: toneL = `g0; 12'd109: toneL = `g0;
                12'd110: toneL = `g0; 12'd111: toneL = `g0;

                12'd112: toneL = `g0b; 12'd113: toneL = `g0b;
                12'd114: toneL = `g0b; 12'd115: toneL = `g0b;
                12'd116: toneL = `g0b; 12'd117: toneL = `g0b;
                12'd118: toneL = `g0b; 12'd119: toneL = `g0b;

                12'd120: toneL = `f0; 12'd121: toneL = `f0;
                12'd122: toneL = `f0; 12'd123: toneL = `f0;
                12'd124: toneL = `f0; 12'd125: toneL = `f0;
                12'd126: toneL = `f0; 12'd127: toneL = `f0;

                12'd128: toneL = `g0; 12'd129: toneL = `g0;
                12'd130: toneL = `g0; 12'd131: toneL = `g0;
                12'd132: toneL = `g0; 12'd133: toneL = `g0;
                12'd134: toneL = `g0; 12'd135: toneL = `g0;

                12'd136: toneL = `g0b; 12'd137: toneL = `g0b;
                12'd138: toneL = `g0b; 12'd139: toneL = `g0b;
                12'd140: toneL = `g0b; 12'd141: toneL = `g0b;
                12'd142: toneL = `g0b; 12'd143: toneL = `g0b;

                12'd144: toneL = `f0; 12'd145: toneL = `f0;
                12'd146: toneL = `f0; 12'd147: toneL = `f0;
                12'd148: toneL = `f0; 12'd149: toneL = `f0;
                12'd150: toneL = `f0; 12'd151: toneL = `f0;

                12'd152: toneL = `f0b; 12'd153: toneL = `f0b;
                12'd154: toneL = `f0b; 12'd155: toneL = `f0b;
                12'd156: toneL = `f0b; 12'd157: toneL = `f0b;
                12'd158: toneL = `f0b; 12'd159: toneL = `f0b;

                12'd160: toneL = `g0; 12'd161: toneL = `g0;
                12'd162: toneL = `g0; 12'd163: toneL = `g0;
                12'd164: toneL = `g0; 12'd165: toneL = `g0;
                12'd166: toneL = `g0; 12'd167: toneL = `g0;

                12'd168: toneL = `f0; 12'd169: toneL = `f0;
                12'd170: toneL = `f0; 12'd171: toneL = `f0;
                12'd172: toneL = `f0; 12'd173: toneL = `f0;
                12'd174: toneL = `f0; 12'd175: toneL = `f0;

                12'd176: toneL = `e0; 12'd177: toneL = `e0;
                12'd178: toneL = `e0; 12'd179: toneL = `e0;
                12'd180: toneL = `e0; 12'd181: toneL = `e0;
                12'd182: toneL = `e0; 12'd183: toneL = `e0;

                12'd184: toneL = `e0b; 12'd185: toneL = `e0b;
                12'd186: toneL = `e0b; 12'd187: toneL = `e0b;
                12'd188: toneL = `e0b; 12'd189: toneL = `e0b;
                12'd190: toneL = `e0b; 12'd191: toneL = `e0b;

                12'd192: toneL = `f0; 12'd193: toneL = `f0;
                12'd194: toneL = `f0; 12'd195: toneL = `f0;
                12'd196: toneL = `f0; 12'd197: toneL = `f0;
                12'd198: toneL = `f0; 12'd199: toneL = `f0;

                12'd208: toneL = `e0b; 12'd209: toneL = `e0b;
                12'd210: toneL = `e0b; 12'd211: toneL = `e0b;
                12'd212: toneL = `e0b; 12'd213: toneL = `e0b;
                12'd214: toneL = `e0b; 12'd215: toneL = `e0b;

                12'd216: toneL = `d0; 12'd217: toneL = `d0;
                12'd218: toneL = `d0; 12'd219: toneL = `d0;
                12'd220: toneL = `d0; 12'd221: toneL = `d0;
                12'd222: toneL = `d0; 12'd223: toneL = `d0;

                12'd224: toneL = `e0; 12'd225: toneL = `e0;
                12'd226: toneL = `e0; 12'd227: toneL = `e0;
                12'd228: toneL = `e0; 12'd229: toneL = `e0;
                12'd230: toneL = `e0; 12'd231: toneL = `e0;

                12'd232: toneL = `e0b; 12'd233: toneL = `e0b;
                12'd234: toneL = `e0b; 12'd235: toneL = `e0b;
                12'd236: toneL = `e0b; 12'd237: toneL = `e0b;
                12'd238: toneL = `e0b; 12'd239: toneL = `e0b;

                12'd240: toneL = `d0; 12'd241: toneL = `d0;
                12'd242: toneL = `d0; 12'd243: toneL = `d0;
                12'd244: toneL = `d0; 12'd245: toneL = `d0;
                12'd246: toneL = `d0; 12'd247: toneL = `d0;

                12'd248: toneL = `d0b; 12'd249: toneL = `d0b;
                12'd250: toneL = `d0b; 12'd251: toneL = `d0b;
                12'd252: toneL = `d0b; 12'd253: toneL = `d0b;
                12'd254: toneL = `d0b; 12'd255: toneL = `d0b;

                12'd256: toneL = `B; 12'd257: toneL = `B;
                12'd258: toneL = `B; 12'd259: toneL = `B;
                12'd260: toneL = `B; 12'd261: toneL = `B;
                12'd262: toneL = `B; 12'd263: toneL = `B;
                12'd264: toneL = `B; 12'd265: toneL = `B;
                12'd266: toneL = `B; 12'd267: toneL = `B;
                12'd268: toneL = `B; 12'd269: toneL = `B;
                12'd270: toneL = `B; 12'd271: toneL = `sil;

                12'd272: toneL = `B; 12'd273: toneL = `B;
                12'd274: toneL = `B; 12'd275: toneL = `B;
                12'd276: toneL = `B; 12'd277: toneL = `B;
                12'd278: toneL = `B; 12'd279: toneL = `B;
                12'd280: toneL = `B; 12'd281: toneL = `B;
                12'd282: toneL = `B; 12'd283: toneL = `B;
                12'd284: toneL = `B; 12'd285: toneL = `B;
                12'd286: toneL = `B; 12'd287: toneL = `B;

                12'd288: toneL = `d0; 12'd289: toneL = `d0;
                12'd290: toneL = `d0; 12'd291: toneL = `d0;
                12'd292: toneL = `d0; 12'd293: toneL = `d0;
                12'd294: toneL = `d0; 12'd295: toneL = `d0;
                12'd296: toneL = `d0; 12'd297: toneL = `d0;
                12'd298: toneL = `d0; 12'd299: toneL = `d0;
                12'd300: toneL = `d0; 12'd301: toneL = `d0;
                12'd302: toneL = `d0; 12'd303: toneL = `d0;

                12'd304: toneL = `e0; 12'd305: toneL = `e0;
                12'd306: toneL = `e0; 12'd307: toneL = `e0;
                12'd308: toneL = `e0; 12'd309: toneL = `e0;
                12'd310: toneL = `e0; 12'd311: toneL = `e0;
                12'd312: toneL = `e0; 12'd313: toneL = `e0;
                12'd314: toneL = `e0; 12'd315: toneL = `e0;
                12'd316: toneL = `e0; 12'd317: toneL = `e0;
                12'd318: toneL = `e0; 12'd319: toneL = `e0;

                12'd320: toneL = `B; 12'd321: toneL = `B;
                12'd322: toneL = `B; 12'd323: toneL = `B;
                12'd324: toneL = `B; 12'd325: toneL = `B;
                12'd326: toneL = `B; 12'd327: toneL = `B;
                12'd328: toneL = `B; 12'd329: toneL = `B;
                12'd330: toneL = `B; 12'd331: toneL = `B;
                12'd332: toneL = `B; 12'd333: toneL = `B;
                12'd334: toneL = `B; 12'd335: toneL = `B;

                12'd336: toneL = `f0; 12'd337: toneL = `f0;
                12'd338: toneL = `f0; 12'd339: toneL = `f0;
                12'd340: toneL = `f0; 12'd341: toneL = `f0;
                12'd342: toneL = `f0; 12'd343: toneL = `f0;
                12'd344: toneL = `f0; 12'd345: toneL = `f0;
                12'd346: toneL = `f0; 12'd347: toneL = `f0;
                12'd348: toneL = `f0; 12'd349: toneL = `f0;
                12'd350: toneL = `f0; 12'd351: toneL = `f0;

                12'd352: toneL = `e0; 12'd353: toneL = `e0;
                12'd354: toneL = `e0; 12'd355: toneL = `e0;
                12'd356: toneL = `e0; 12'd357: toneL = `e0;
                12'd358: toneL = `e0; 12'd359: toneL = `e0;
                12'd360: toneL = `e0; 12'd361: toneL = `e0;
                12'd362: toneL = `e0; 12'd363: toneL = `e0;
                12'd364: toneL = `e0; 12'd365: toneL = `e0;
                12'd366: toneL = `e0; 12'd367: toneL = `e0;

                12'd368: toneL = `d0; 12'd369: toneL = `d0;
                12'd370: toneL = `d0; 12'd371: toneL = `d0;
                12'd372: toneL = `d0; 12'd373: toneL = `d0;
                12'd374: toneL = `d0; 12'd375: toneL = `d0;
                12'd376: toneL = `d0; 12'd377: toneL = `d0;
                12'd378: toneL = `d0; 12'd379: toneL = `d0;
                12'd380: toneL = `d0; 12'd381: toneL = `d0;
                12'd382: toneL = `d0; 12'd383: toneL = `d0;

                12'd384: toneL = `B; 12'd385: toneL = `B;
                12'd386: toneL = `B; 12'd387: toneL = `B;
                12'd388: toneL = `B; 12'd389: toneL = `B;
                12'd390: toneL = `B; 12'd391: toneL = `B;
                12'd392: toneL = `B; 12'd393: toneL = `B;
                12'd394: toneL = `B; 12'd395: toneL = `B;
                12'd396: toneL = `B; 12'd397: toneL = `B;
                12'd398: toneL = `B; 12'd399: toneL = `sil;

                12'd400: toneL = `B; 12'd401: toneL = `B;
                12'd402: toneL = `B; 12'd403: toneL = `B;
                12'd404: toneL = `B; 12'd405: toneL = `B;
                12'd406: toneL = `B; 12'd407: toneL = `B;
                12'd408: toneL = `B; 12'd409: toneL = `B;
                12'd410: toneL = `B; 12'd411: toneL = `B;
                12'd412: toneL = `B; 12'd413: toneL = `B;
                12'd414: toneL = `B; 12'd415: toneL = `B;

                12'd416: toneL = `d0; 12'd417: toneL = `d0;
                12'd418: toneL = `d0; 12'd419: toneL = `d0;
                12'd420: toneL = `d0; 12'd421: toneL = `d0;
                12'd422: toneL = `d0; 12'd423: toneL = `d0;
                12'd424: toneL = `d0; 12'd425: toneL = `d0;
                12'd426: toneL = `d0; 12'd427: toneL = `d0;
                12'd428: toneL = `d0; 12'd429: toneL = `d0;
                12'd430: toneL = `d0; 12'd431: toneL = `d0;

                12'd432: toneL = `e0; 12'd433: toneL = `e0;
                12'd434: toneL = `e0; 12'd435: toneL = `e0;
                12'd436: toneL = `e0; 12'd437: toneL = `e0;
                12'd438: toneL = `e0; 12'd439: toneL = `e0;
                12'd440: toneL = `e0; 12'd441: toneL = `e0;
                12'd442: toneL = `e0; 12'd443: toneL = `e0;
                12'd444: toneL = `e0; 12'd445: toneL = `e0;
                12'd446: toneL = `e0; 12'd447: toneL = `e0;

                12'd448: toneL = `B; 12'd449: toneL = `B;
                12'd450: toneL = `B; 12'd451: toneL = `B;
                12'd452: toneL = `B; 12'd453: toneL = `B;
                12'd454: toneL = `B; 12'd455: toneL = `B;
                12'd456: toneL = `B; 12'd457: toneL = `B;
                12'd458: toneL = `B; 12'd459: toneL = `B;
                12'd460: toneL = `B; 12'd461: toneL = `B;
                12'd462: toneL = `B; 12'd463: toneL = `B;

                12'd464: toneL = `d0; 12'd465: toneL = `d0;
                12'd466: toneL = `d0; 12'd467: toneL = `d0;
                12'd468: toneL = `d0; 12'd469: toneL = `d0;
                12'd470: toneL = `d0; 12'd471: toneL = `d0;
                12'd472: toneL = `d0; 12'd473: toneL = `d0;
                12'd474: toneL = `d0; 12'd475: toneL = `d0;
                12'd476: toneL = `d0; 12'd477: toneL = `d0;
                12'd478: toneL = `d0; 12'd479: toneL = `d0;

                12'd480: toneL = `A; 12'd481: toneL = `A;
                12'd482: toneL = `A; 12'd483: toneL = `A;
                12'd484: toneL = `A; 12'd485: toneL = `A;
                12'd486: toneL = `A; 12'd487: toneL = `A;
                12'd488: toneL = `A; 12'd489: toneL = `A;
                12'd490: toneL = `A; 12'd491: toneL = `A;
                12'd492: toneL = `A; 12'd493: toneL = `A;
                12'd494: toneL = `A; 12'd495: toneL = `A;

                12'd496: toneL = `C; 12'd497: toneL = `C;
                12'd498: toneL = `C; 12'd499: toneL = `C;
                12'd500: toneL = `C; 12'd501: toneL = `C;
                12'd502: toneL = `C; 12'd503: toneL = `C;
                12'd504: toneL = `C; 12'd505: toneL = `C;
                12'd506: toneL = `C; 12'd507: toneL = `C;
                12'd508: toneL = `C; 12'd509: toneL = `C;
                12'd510: toneL = `C; 12'd511: toneL = `C;
                
                12'd512: toneL = `B; 12'd513: toneL = `B;
                12'd514: toneL = `B; 12'd515: toneL = `B;
                12'd516: toneL = `B; 12'd517: toneL = `B;
                12'd518: toneL = `B; 12'd519: toneL = `B;
                12'd520: toneL = `B; 12'd521: toneL = `B;
                12'd522: toneL = `B; 12'd523: toneL = `B;
                12'd524: toneL = `B; 12'd525: toneL = `B;
                12'd526: toneL = `B; 12'd527: toneL = `sil;  

                12'd528: toneL = `B; 12'd529: toneL = `B;
                12'd530: toneL = `B; 12'd531: toneL = `B;
                12'd532: toneL = `B; 12'd533: toneL = `B;
                12'd534: toneL = `B; 12'd535: toneL = `B;
                12'd536: toneL = `B; 12'd537: toneL = `B;
                12'd538: toneL = `B; 12'd539: toneL = `B;
                12'd540: toneL = `B; 12'd541: toneL = `B;
                12'd542: toneL = `B; 12'd543: toneL = `B;

                12'd544: toneL = `d0; 12'd545: toneL = `d0;
                12'd546: toneL = `d0; 12'd547: toneL = `d0;
                12'd548: toneL = `d0; 12'd549: toneL = `d0;
                12'd550: toneL = `d0; 12'd551: toneL = `d0;
                12'd552: toneL = `d0; 12'd553: toneL = `d0;
                12'd554: toneL = `d0; 12'd555: toneL = `d0;
                12'd556: toneL = `d0; 12'd557: toneL = `d0;
                12'd558: toneL = `d0; 12'd559: toneL = `d0;

                12'd560: toneL = `e0; 12'd561: toneL = `e0;
                12'd562: toneL = `e0; 12'd563: toneL = `e0;
                12'd564: toneL = `e0; 12'd565: toneL = `e0;
                12'd566: toneL = `e0; 12'd567: toneL = `e0;
                12'd568: toneL = `e0; 12'd569: toneL = `e0;
                12'd570: toneL = `e0; 12'd571: toneL = `e0;
                12'd572: toneL = `e0; 12'd573: toneL = `e0;
                12'd574: toneL = `e0; 12'd575: toneL = `e0;

                12'd576: toneL = `B; 12'd577: toneL = `B;
                12'd578: toneL = `B; 12'd579: toneL = `B;
                12'd580: toneL = `B; 12'd581: toneL = `B;
                12'd582: toneL = `B; 12'd583: toneL = `B;
                12'd584: toneL = `B; 12'd585: toneL = `B;
                12'd586: toneL = `B; 12'd587: toneL = `B;
                12'd588: toneL = `B; 12'd589: toneL = `B;
                12'd590: toneL = `B; 12'd591: toneL = `B;

                12'd592: toneL = `f0; 12'd593: toneL = `f0;
                12'd594: toneL = `f0; 12'd595: toneL = `f0;
                12'd596: toneL = `f0; 12'd597: toneL = `f0;
                12'd598: toneL = `f0; 12'd599: toneL = `f0;
                12'd600: toneL = `f0; 12'd601: toneL = `f0;
                12'd602: toneL = `f0; 12'd603: toneL = `f0;
                12'd604: toneL = `f0; 12'd605: toneL = `f0;
                12'd606: toneL = `f0; 12'd607: toneL = `f0;

                12'd608: toneL = `e0; 12'd609: toneL = `e0;
                12'd610: toneL = `e0; 12'd611: toneL = `e0;
                12'd612: toneL = `e0; 12'd613: toneL = `e0;
                12'd614: toneL = `e0; 12'd615: toneL = `e0;
                12'd616: toneL = `e0; 12'd617: toneL = `e0;
                12'd618: toneL = `e0; 12'd619: toneL = `e0;
                12'd620: toneL = `e0; 12'd621: toneL = `e0;
                12'd622: toneL = `e0; 12'd623: toneL = `e0;

                12'd624: toneL = `d0; 12'd625: toneL = `d0;
                12'd626: toneL = `d0; 12'd627: toneL = `d0;
                12'd628: toneL = `d0; 12'd629: toneL = `d0;
                12'd630: toneL = `d0; 12'd631: toneL = `d0;
                12'd632: toneL = `d0; 12'd633: toneL = `d0;
                12'd634: toneL = `d0; 12'd635: toneL = `d0;
                12'd636: toneL = `d0; 12'd637: toneL = `d0;
                12'd638: toneL = `d0; 12'd639: toneL = `d0;

                12'd640: toneL = `B; 12'd641: toneL = `B;
                12'd642: toneL = `B; 12'd643: toneL = `B;
                12'd644: toneL = `B; 12'd645: toneL = `B;
                12'd646: toneL = `B; 12'd647: toneL = `B;
                12'd648: toneL = `B; 12'd649: toneL = `B;
                12'd650: toneL = `B; 12'd651: toneL = `B;
                12'd652: toneL = `B; 12'd653: toneL = `B;
                12'd654: toneL = `B; 12'd655: toneL = `sil;

                12'd656: toneL = `B; 12'd657: toneL = `B;
                12'd658: toneL = `B; 12'd659: toneL = `B;
                12'd660: toneL = `B; 12'd661: toneL = `B;
                12'd662: toneL = `B; 12'd663: toneL = `B;
                12'd664: toneL = `B; 12'd665: toneL = `B;
                12'd666: toneL = `B; 12'd667: toneL = `B;
                12'd668: toneL = `B; 12'd669: toneL = `B;
                12'd670: toneL = `B; 12'd671: toneL = `B;

                12'd672: toneL = `d0; 12'd673: toneL = `d0;
                12'd674: toneL = `d0; 12'd675: toneL = `d0;
                12'd676: toneL = `d0; 12'd677: toneL = `d0;
                12'd678: toneL = `d0; 12'd679: toneL = `d0;
                12'd680: toneL = `d0; 12'd681: toneL = `d0;
                12'd682: toneL = `d0; 12'd683: toneL = `d0;
                12'd684: toneL = `d0; 12'd685: toneL = `d0;
                12'd686: toneL = `d0; 12'd687: toneL = `d0;

                12'd688: toneL = `e0; 12'd689: toneL = `e0;
                12'd690: toneL = `e0; 12'd691: toneL = `e0;
                12'd692: toneL = `e0; 12'd693: toneL = `e0;
                12'd694: toneL = `e0; 12'd695: toneL = `e0;
                12'd696: toneL = `e0; 12'd697: toneL = `e0;
                12'd698: toneL = `e0; 12'd699: toneL = `e0;
                12'd700: toneL = `e0; 12'd701: toneL = `e0;
                12'd702: toneL = `e0; 12'd703: toneL = `e0;

                12'd704: toneL = `B; 12'd705: toneL = `B;
                12'd706: toneL = `B; 12'd707: toneL = `B;
                12'd708: toneL = `B; 12'd709: toneL = `B;
                12'd710: toneL = `B; 12'd711: toneL = `B;
                12'd712: toneL = `B; 12'd713: toneL = `B;
                12'd714: toneL = `B; 12'd715: toneL = `B;
                12'd716: toneL = `B; 12'd717: toneL = `B;
                12'd718: toneL = `B; 12'd719: toneL = `B;

                12'd720: toneL = `d0; 12'd721: toneL = `d0;
                12'd722: toneL = `d0; 12'd723: toneL = `d0;
                12'd724: toneL = `d0; 12'd725: toneL = `d0;
                12'd726: toneL = `d0; 12'd727: toneL = `d0;
                12'd728: toneL = `d0; 12'd729: toneL = `d0;
                12'd730: toneL = `d0; 12'd731: toneL = `d0;
                12'd732: toneL = `d0; 12'd733: toneL = `d0;
                12'd734: toneL = `d0; 12'd735: toneL = `d0;

                12'd736: toneL = `A; 12'd737: toneL = `A;
                12'd738: toneL = `A; 12'd739: toneL = `A;
                12'd740: toneL = `A; 12'd741: toneL = `A;
                12'd742: toneL = `A; 12'd743: toneL = `A;
                12'd744: toneL = `A; 12'd745: toneL = `A;
                12'd746: toneL = `A; 12'd747: toneL = `A;
                12'd748: toneL = `A; 12'd749: toneL = `A;
                12'd750: toneL = `A; 12'd751: toneL = `A;

                12'd752: toneL = `C; 12'd753: toneL = `C;
                12'd754: toneL = `C; 12'd755: toneL = `C;
                12'd756: toneL = `C; 12'd757: toneL = `C;
                12'd758: toneL = `C; 12'd759: toneL = `C;
                12'd760: toneL = `C; 12'd761: toneL = `C;
                12'd762: toneL = `C; 12'd763: toneL = `C;
                12'd764: toneL = `C; 12'd765: toneL = `C;
                12'd766: toneL = `C; 12'd767: toneL = `C;

                12'd768: toneL = `B; 12'd769: toneL = `B;
                12'd770: toneL = `B; 12'd771: toneL = `B;
                12'd772: toneL = `B; 12'd773: toneL = `B;
                12'd774: toneL = `B; 12'd775: toneL = `B;
                12'd776: toneL = `B; 12'd777: toneL = `B;
                12'd778: toneL = `B; 12'd779: toneL = `B;
                12'd780: toneL = `B; 12'd781: toneL = `B;
                12'd782: toneL = `B; 12'd783: toneL = `sil;

                12'd784: toneL = `B; 12'd785: toneL = `B;
                12'd786: toneL = `B; 12'd787: toneL = `B;
                12'd788: toneL = `B; 12'd789: toneL = `B;
                12'd790: toneL = `B; 12'd791: toneL = `B;
                12'd792: toneL = `B; 12'd793: toneL = `B;
                12'd794: toneL = `B; 12'd795: toneL = `B;
                12'd796: toneL = `B; 12'd797: toneL = `B;
                12'd798: toneL = `B; 12'd799: toneL = `B;

                12'd800: toneL = `d0; 12'd801: toneL = `d0;
                12'd802: toneL = `d0; 12'd803: toneL = `d0;
                12'd804: toneL = `d0; 12'd805: toneL = `d0;
                12'd806: toneL = `d0; 12'd807: toneL = `d0;
                12'd808: toneL = `d0; 12'd809: toneL = `d0;
                12'd810: toneL = `d0; 12'd811: toneL = `d0;
                12'd812: toneL = `d0; 12'd813: toneL = `d0;
                12'd814: toneL = `d0; 12'd815: toneL = `d0;

                12'd816: toneL = `e0; 12'd817: toneL = `e0;
                12'd818: toneL = `e0; 12'd819: toneL = `e0;
                12'd820: toneL = `e0; 12'd821: toneL = `e0;
                12'd822: toneL = `e0; 12'd823: toneL = `e0;
                12'd824: toneL = `e0; 12'd825: toneL = `e0;
                12'd826: toneL = `e0; 12'd827: toneL = `e0;
                12'd828: toneL = `e0; 12'd829: toneL = `e0;
                12'd830: toneL = `e0; 12'd831: toneL = `e0;

                12'd832: toneL = `B; 12'd833: toneL = `B;
                12'd834: toneL = `B; 12'd835: toneL = `B;
                12'd836: toneL = `B; 12'd837: toneL = `B;
                12'd838: toneL = `B; 12'd839: toneL = `B;
                12'd840: toneL = `B; 12'd841: toneL = `B;
                12'd842: toneL = `B; 12'd843: toneL = `B;
                12'd844: toneL = `B; 12'd845: toneL = `B;
                12'd846: toneL = `B; 12'd847: toneL = `B;

                12'd848: toneL = `f0; 12'd849: toneL = `f0;
                12'd850: toneL = `f0; 12'd851: toneL = `f0;
                12'd852: toneL = `f0; 12'd853: toneL = `f0;
                12'd854: toneL = `f0; 12'd855: toneL = `f0;
                12'd856: toneL = `f0; 12'd857: toneL = `f0;
                12'd858: toneL = `f0; 12'd859: toneL = `f0;
                12'd860: toneL = `f0; 12'd861: toneL = `f0;
                12'd862: toneL = `f0; 12'd863: toneL = `f0;

                12'd864: toneL = `e0; 12'd865: toneL = `e0;
                12'd866: toneL = `e0; 12'd867: toneL = `e0;
                12'd868: toneL = `e0; 12'd869: toneL = `e0;
                12'd870: toneL = `e0; 12'd871: toneL = `e0;
                12'd872: toneL = `e0; 12'd873: toneL = `e0;
                12'd874: toneL = `e0; 12'd875: toneL = `e0;
                12'd876: toneL = `e0; 12'd877: toneL = `e0;
                12'd878: toneL = `e0; 12'd879: toneL = `e0;

                12'd880: toneL = `d0; 12'd881: toneL = `d0;
                12'd882: toneL = `d0; 12'd883: toneL = `d0;
                12'd884: toneL = `d0; 12'd885: toneL = `d0;
                12'd886: toneL = `d0; 12'd887: toneL = `d0;
                12'd888: toneL = `d0; 12'd889: toneL = `d0;
                12'd890: toneL = `d0; 12'd891: toneL = `d0;
                12'd892: toneL = `d0; 12'd893: toneL = `d0;
                12'd894: toneL = `d0; 12'd895: toneL = `d0;

                12'd896: toneL = `B; 12'd897: toneL = `B;
                12'd898: toneL = `B; 12'd899: toneL = `B;
                12'd900: toneL = `B; 12'd901: toneL = `B;
                12'd902: toneL = `B; 12'd903: toneL = `B;
                12'd904: toneL = `B; 12'd905: toneL = `B;
                12'd906: toneL = `B; 12'd907: toneL = `B;
                12'd908: toneL = `B; 12'd909: toneL = `B;
                12'd910: toneL = `B; 12'd911: toneL = `sil;

                12'd912: toneL = `B; 12'd913: toneL = `B;
                12'd914: toneL = `B; 12'd915: toneL = `B;
                12'd916: toneL = `B; 12'd917: toneL = `B;
                12'd918: toneL = `B; 12'd919: toneL = `B;
                12'd920: toneL = `B; 12'd921: toneL = `B;
                12'd922: toneL = `B; 12'd923: toneL = `B;
                12'd924: toneL = `B; 12'd925: toneL = `B;
                12'd926: toneL = `B; 12'd927: toneL = `B;

                12'd928: toneL = `d0; 12'd929: toneL = `d0;
                12'd930: toneL = `d0; 12'd931: toneL = `d0;
                12'd932: toneL = `d0; 12'd933: toneL = `d0;
                12'd934: toneL = `d0; 12'd935: toneL = `d0;
                12'd936: toneL = `d0; 12'd937: toneL = `d0;
                12'd938: toneL = `d0; 12'd939: toneL = `d0;
                12'd940: toneL = `d0; 12'd941: toneL = `d0;
                12'd942: toneL = `d0; 12'd943: toneL = `d0;

                12'd944: toneL = `e0; 12'd945: toneL = `e0;
                12'd946: toneL = `e0; 12'd947: toneL = `e0;
                12'd948: toneL = `e0; 12'd949: toneL = `e0;
                12'd950: toneL = `e0; 12'd951: toneL = `e0;
                12'd952: toneL = `e0; 12'd953: toneL = `e0;
                12'd954: toneL = `e0; 12'd955: toneL = `e0;
                12'd956: toneL = `e0; 12'd957: toneL = `e0;
                12'd958: toneL = `e0; 12'd959: toneL = `e0;

                12'd960: toneL = `B; 12'd961: toneL = `B;
                12'd962: toneL = `B; 12'd963: toneL = `B;
                12'd964: toneL = `B; 12'd965: toneL = `B;
                12'd966: toneL = `B; 12'd967: toneL = `B;
                12'd968: toneL = `B; 12'd969: toneL = `B;
                12'd970: toneL = `B; 12'd971: toneL = `B;
                12'd972: toneL = `B; 12'd973: toneL = `B;
                12'd974: toneL = `B; 12'd975: toneL = `B;

                12'd976: toneL = `d0; 12'd977: toneL = `d0;
                12'd978: toneL = `d0; 12'd979: toneL = `d0;
                12'd980: toneL = `d0; 12'd981: toneL = `d0;
                12'd982: toneL = `d0; 12'd983: toneL = `d0;
                12'd984: toneL = `d0; 12'd985: toneL = `d0;
                12'd986: toneL = `d0; 12'd987: toneL = `d0;
                12'd988: toneL = `d0; 12'd989: toneL = `d0;
                12'd990: toneL = `d0; 12'd991: toneL = `d0;

                12'd992: toneL = `A; 12'd993: toneL = `A;
                12'd994: toneL = `A; 12'd995: toneL = `A;
                12'd996: toneL = `A; 12'd997: toneL = `A;
                12'd998: toneL = `A; 12'd999: toneL = `A;
                12'd1000: toneL = `A; 12'd1001: toneL = `A;
                12'd1002: toneL = `A; 12'd1003: toneL = `A;
                12'd1004: toneL = `A; 12'd1005: toneL = `A;
                12'd1006: toneL = `A; 12'd1007: toneL = `A;

                12'd1008: toneL = `C; 12'd1009: toneL = `C;
                12'd1010: toneL = `C; 12'd1011: toneL = `C;
                12'd1012: toneL = `C; 12'd1013: toneL = `C;
                12'd1014: toneL = `C; 12'd1015: toneL = `C;
                12'd1016: toneL = `C; 12'd1017: toneL = `C;
                12'd1018: toneL = `C; 12'd1019: toneL = `C;
                12'd1020: toneL = `C; 12'd1021: toneL = `C;
                12'd1022: toneL = `C; 12'd1023: toneL = `C;

                12'd1024: toneL = `B; 12'd1025: toneL = `B;
                12'd1026: toneL = `B; 12'd1027: toneL = `B;
                12'd1028: toneL = `B; 12'd1029: toneL = `B;
                12'd1030: toneL = `B; 12'd1031: toneL = `B;
                12'd1032: toneL = `B; 12'd1033: toneL = `B;
                12'd1034: toneL = `B; 12'd1035: toneL = `B;
                12'd1036: toneL = `B; 12'd1037: toneL = `B;
                12'd1038: toneL = `B; 12'd1039: toneL = `sil;

                12'd1040: toneL = `B; 12'd1041: toneL = `B;
                12'd1042: toneL = `B; 12'd1043: toneL = `B;
                12'd1044: toneL = `B; 12'd1045: toneL = `B;
                12'd1046: toneL = `B; 12'd1047: toneL = `B;
                12'd1048: toneL = `B; 12'd1049: toneL = `B;
                12'd1050: toneL = `B; 12'd1051: toneL = `B;
                12'd1052: toneL = `B; 12'd1053: toneL = `B;
                12'd1054: toneL = `B; 12'd1055: toneL = `B;

                12'd1056: toneL = `d0; 12'd1057: toneL = `d0;
                12'd1058: toneL = `d0; 12'd1059: toneL = `d0;
                12'd1060: toneL = `d0; 12'd1061: toneL = `d0;
                12'd1062: toneL = `d0; 12'd1063: toneL = `d0;
                12'd1064: toneL = `d0; 12'd1065: toneL = `d0;
                12'd1066: toneL = `d0; 12'd1067: toneL = `d0;
                12'd1068: toneL = `d0; 12'd1069: toneL = `d0;
                12'd1070: toneL = `d0; 12'd1071: toneL = `d0;

                12'd1072: toneL = `e0; 12'd1073: toneL = `e0;
                12'd1074: toneL = `e0; 12'd1075: toneL = `e0;
                12'd1076: toneL = `e0; 12'd1077: toneL = `e0;
                12'd1078: toneL = `e0; 12'd1079: toneL = `e0;
                12'd1080: toneL = `e0; 12'd1081: toneL = `e0;
                12'd1082: toneL = `e0; 12'd1083: toneL = `e0;
                12'd1084: toneL = `e0; 12'd1085: toneL = `e0;
                12'd1086: toneL = `e0; 12'd1087: toneL = `e0;

                12'd1088: toneL = `B; 12'd1089: toneL = `B;
                12'd1090: toneL = `B; 12'd1091: toneL = `B;
                12'd1092: toneL = `B; 12'd1093: toneL = `B;
                12'd1094: toneL = `B; 12'd1095: toneL = `B;
                12'd1096: toneL = `B; 12'd1097: toneL = `B;
                12'd1098: toneL = `B; 12'd1099: toneL = `B;
                12'd1100: toneL = `B; 12'd1101: toneL = `B;
                12'd1102: toneL = `B; 12'd1103: toneL = `B;

                12'd1104: toneL = `f0; 12'd1105: toneL = `f0;
                12'd1106: toneL = `f0; 12'd1107: toneL = `f0;
                12'd1108: toneL = `f0; 12'd1109: toneL = `f0;
                12'd1110: toneL = `f0; 12'd1111: toneL = `f0;
                12'd1112: toneL = `f0; 12'd1113: toneL = `f0;
                12'd1114: toneL = `f0; 12'd1115: toneL = `f0;
                12'd1116: toneL = `f0; 12'd1117: toneL = `f0;
                12'd1118: toneL = `f0; 12'd1119: toneL = `f0;

                12'd1120: toneL = `e0; 12'd1121: toneL = `e0;
                12'd1122: toneL = `e0; 12'd1123: toneL = `e0;
                12'd1124: toneL = `e0; 12'd1125: toneL = `e0;
                12'd1126: toneL = `e0; 12'd1127: toneL = `e0;
                12'd1128: toneL = `e0; 12'd1129: toneL = `e0;
                12'd1130: toneL = `e0; 12'd1131: toneL = `e0;
                12'd1132: toneL = `e0; 12'd1133: toneL = `e0;
                12'd1134: toneL = `e0; 12'd1135: toneL = `e0;

                12'd1136: toneL = `d0; 12'd1137: toneL = `d0;
                12'd1138: toneL = `d0; 12'd1139: toneL = `d0;
                12'd1140: toneL = `d0; 12'd1141: toneL = `d0;
                12'd1142: toneL = `d0; 12'd1143: toneL = `d0;
                12'd1144: toneL = `d0; 12'd1145: toneL = `d0;
                12'd1146: toneL = `d0; 12'd1147: toneL = `d0;
                12'd1148: toneL = `d0; 12'd1149: toneL = `d0;
                12'd1150: toneL = `d0; 12'd1151: toneL = `d0;

                12'd1152: toneL = `B; 12'd1153: toneL = `B;
                12'd1154: toneL = `B; 12'd1155: toneL = `B;
                12'd1156: toneL = `B; 12'd1157: toneL = `B;
                12'd1158: toneL = `B; 12'd1159: toneL = `B;
                12'd1160: toneL = `B; 12'd1161: toneL = `B;
                12'd1162: toneL = `B; 12'd1163: toneL = `B;
                12'd1164: toneL = `B; 12'd1165: toneL = `B;
                12'd1166: toneL = `B; 12'd1167: toneL = `sil;

                12'd1168: toneL = `B; 12'd1169: toneL = `B;
                12'd1170: toneL = `B; 12'd1171: toneL = `B;
                12'd1172: toneL = `B; 12'd1173: toneL = `B;
                12'd1174: toneL = `B; 12'd1175: toneL = `B;
                12'd1176: toneL = `B; 12'd1177: toneL = `B;
                12'd1178: toneL = `B; 12'd1179: toneL = `B;
                12'd1180: toneL = `B; 12'd1181: toneL = `B;
                12'd1182: toneL = `B; 12'd1183: toneL = `B;

                12'd1184: toneL = `d0; 12'd1185: toneL = `d0;
                12'd1186: toneL = `d0; 12'd1187: toneL = `d0;
                12'd1188: toneL = `d0; 12'd1189: toneL = `d0;
                12'd1190: toneL = `d0; 12'd1191: toneL = `d0;
                12'd1192: toneL = `d0; 12'd1193: toneL = `d0;
                12'd1194: toneL = `d0; 12'd1195: toneL = `d0;
                12'd1196: toneL = `d0; 12'd1197: toneL = `d0;
                12'd1198: toneL = `d0; 12'd1199: toneL = `d0;

                12'd1200: toneL = `e0; 12'd1201: toneL = `e0;
                12'd1202: toneL = `e0; 12'd1203: toneL = `e0;
                12'd1204: toneL = `e0; 12'd1205: toneL = `e0;
                12'd1206: toneL = `e0; 12'd1207: toneL = `e0;
                12'd1208: toneL = `e0; 12'd1209: toneL = `e0;
                12'd1210: toneL = `e0; 12'd1211: toneL = `e0;
                12'd1212: toneL = `e0; 12'd1213: toneL = `e0;
                12'd1214: toneL = `e0; 12'd1215: toneL = `e0;

                12'd1216: toneL = `B; 12'd1217: toneL = `B;
                12'd1218: toneL = `B; 12'd1219: toneL = `B;
                12'd1220: toneL = `B; 12'd1221: toneL = `B;
                12'd1222: toneL = `B; 12'd1223: toneL = `B;
                12'd1224: toneL = `B; 12'd1225: toneL = `B;
                12'd1226: toneL = `B; 12'd1227: toneL = `B;
                12'd1228: toneL = `B; 12'd1229: toneL = `B;
                12'd1230: toneL = `B; 12'd1231: toneL = `B;

                12'd1232: toneL = `d0; 12'd1233: toneL = `d0;
                12'd1234: toneL = `d0; 12'd1235: toneL = `d0;
                12'd1236: toneL = `d0; 12'd1237: toneL = `d0;
                12'd1238: toneL = `d0; 12'd1239: toneL = `d0;
                12'd1240: toneL = `d0; 12'd1241: toneL = `d0;
                12'd1242: toneL = `d0; 12'd1243: toneL = `d0;
                12'd1244: toneL = `d0; 12'd1245: toneL = `d0;
                12'd1246: toneL = `d0; 12'd1247: toneL = `d0;

                12'd1248: toneL = `A; 12'd1249: toneL = `A;
                12'd1250: toneL = `A; 12'd1251: toneL = `A;
                12'd1252: toneL = `A; 12'd1253: toneL = `A;
                12'd1254: toneL = `A; 12'd1255: toneL = `A;
                12'd1256: toneL = `A; 12'd1257: toneL = `A;
                12'd1258: toneL = `A; 12'd1259: toneL = `A;
                12'd1260: toneL = `A; 12'd1261: toneL = `A;
                12'd1262: toneL = `A; 12'd1263: toneL = `A;

                12'd1264: toneL = `C; 12'd1265: toneL = `C;
                12'd1266: toneL = `C; 12'd1267: toneL = `C;
                12'd1268: toneL = `C; 12'd1269: toneL = `C;
                12'd1270: toneL = `C; 12'd1271: toneL = `C;
                12'd1272: toneL = `C; 12'd1273: toneL = `C;
                12'd1274: toneL = `C; 12'd1275: toneL = `C;
                12'd1276: toneL = `C; 12'd1277: toneL = `C;
                12'd1278: toneL = `C; 12'd1279: toneL = `C;

                12'd1280: toneL = `B; 12'd1281: toneL = `B;
                12'd1282: toneL = `B; 12'd1283: toneL = `B;
                12'd1284: toneL = `B; 12'd1285: toneL = `B;
                12'd1286: toneL = `B; 12'd1287: toneL = `B;
                12'd1288: toneL = `B; 12'd1289: toneL = `B;
                12'd1290: toneL = `B; 12'd1291: toneL = `B;
                12'd1292: toneL = `B; 12'd1293: toneL = `B;
                12'd1294: toneL = `B; 12'd1295: toneL = `B;

                12'd1296: toneL = `f0B; 12'd1297: toneL = `f0B;
                12'd1298: toneL = `f0B; 12'd1299: toneL = `f0B;
                12'd1300: toneL = `f0B; 12'd1301: toneL = `f0B;
                12'd1302: toneL = `f0B; 12'd1303: toneL = `f0B;
                12'd1304: toneL = `f0B; 12'd1305: toneL = `f0B;
                12'd1306: toneL = `f0B; 12'd1307: toneL = `f0B;
                12'd1308: toneL = `f0B; 12'd1309: toneL = `f0B;
                12'd1310: toneL = `f0B; 12'd1311: toneL = `f0B;

                12'd1312: toneL = `B; 12'd1313: toneL = `B;
                12'd1314: toneL = `B; 12'd1315: toneL = `B;
                12'd1316: toneL = `B; 12'd1317: toneL = `B;
                12'd1318: toneL = `B; 12'd1319: toneL = `B;
                12'd1320: toneL = `B; 12'd1321: toneL = `B;
                12'd1322: toneL = `B; 12'd1323: toneL = `B;
                12'd1324: toneL = `B; 12'd1325: toneL = `B;
                12'd1326: toneL = `B; 12'd1327: toneL = `B;

                12'd1328: toneL = `f0B; 12'd1329: toneL = `f0B;
                12'd1330: toneL = `f0B; 12'd1331: toneL = `f0B;
                12'd1332: toneL = `f0B; 12'd1333: toneL = `f0B;
                12'd1334: toneL = `f0B; 12'd1335: toneL = `f0B;
                12'd1336: toneL = `f0B; 12'd1337: toneL = `f0B;
                12'd1338: toneL = `f0B; 12'd1339: toneL = `f0B;
                12'd1340: toneL = `f0B; 12'd1341: toneL = `f0B;
                12'd1342: toneL = `f0B; 12'd1343: toneL = `f0B;

                12'd1344: toneL = `B; 12'd1345: toneL = `B;
                12'd1346: toneL = `B; 12'd1347: toneL = `B;
                12'd1348: toneL = `B; 12'd1349: toneL = `B;
                12'd1350: toneL = `B; 12'd1351: toneL = `B;
                12'd1352: toneL = `B; 12'd1353: toneL = `B;
                12'd1354: toneL = `B; 12'd1355: toneL = `B;
                12'd1356: toneL = `B; 12'd1357: toneL = `B;
                12'd1358: toneL = `B; 12'd1359: toneL = `B;

                12'd1360: toneL = `f0B; 12'd1361: toneL = `f0B;
                12'd1362: toneL = `f0B; 12'd1363: toneL = `f0B;
                12'd1364: toneL = `f0B; 12'd1365: toneL = `f0B;
                12'd1366: toneL = `f0B; 12'd1367: toneL = `f0B;
                12'd1368: toneL = `f0B; 12'd1369: toneL = `f0B;
                12'd1370: toneL = `f0B; 12'd1371: toneL = `f0B;
                12'd1372: toneL = `f0B; 12'd1373: toneL = `f0B;
                12'd1374: toneL = `f0B; 12'd1375: toneL = `f0B;

                12'd1376: toneL = `B; 12'd1377: toneL = `B;
                12'd1378: toneL = `B; 12'd1379: toneL = `B;
                12'd1380: toneL = `B; 12'd1381: toneL = `B;
                12'd1382: toneL = `B; 12'd1383: toneL = `B;
                12'd1384: toneL = `B; 12'd1385: toneL = `B;
                12'd1386: toneL = `B; 12'd1387: toneL = `B;
                12'd1388: toneL = `B; 12'd1389: toneL = `B;
                12'd1390: toneL = `B; 12'd1391: toneL = `B;

                12'd1392: toneL = `f0B; 12'd1393: toneL = `f0B;
                12'd1394: toneL = `f0B; 12'd1395: toneL = `f0B;
                12'd1396: toneL = `f0B; 12'd1397: toneL = `f0B;
                12'd1398: toneL = `f0B; 12'd1399: toneL = `f0B;
                12'd1400: toneL = `f0B; 12'd1401: toneL = `f0B;
                12'd1402: toneL = `f0B; 12'd1403: toneL = `f0B;
                12'd1404: toneL = `f0B; 12'd1405: toneL = `f0B;
                12'd1406: toneL = `f0B; 12'd1407: toneL = `f0B;

                12'd1408: toneL = `B; 12'd1409: toneL = `B;
                12'd1410: toneL = `B; 12'd1411: toneL = `B;
                12'd1412: toneL = `B; 12'd1413: toneL = `B;
                12'd1414: toneL = `B; 12'd1415: toneL = `B;
                12'd1416: toneL = `B; 12'd1417: toneL = `B;
                12'd1418: toneL = `B; 12'd1419: toneL = `B;
                12'd1420: toneL = `B; 12'd1421: toneL = `B;
                12'd1422: toneL = `B; 12'd1423: toneL = `B;

                12'd1424: toneL = `f0B; 12'd1425: toneL = `f0B;
                12'd1426: toneL = `f0B; 12'd1427: toneL = `f0B;
                12'd1428: toneL = `f0B; 12'd1429: toneL = `f0B;
                12'd1430: toneL = `f0B; 12'd1431: toneL = `f0B;
                12'd1432: toneL = `f0B; 12'd1433: toneL = `f0B;
                12'd1434: toneL = `f0B; 12'd1435: toneL = `f0B;
                12'd1436: toneL = `f0B; 12'd1437: toneL = `f0B;
                12'd1438: toneL = `f0B; 12'd1439: toneL = `f0B;

                12'd1440: toneL = `B; 12'd1441: toneL = `B;
                12'd1442: toneL = `B; 12'd1443: toneL = `B;
                12'd1444: toneL = `B; 12'd1445: toneL = `B;
                12'd1446: toneL = `B; 12'd1447: toneL = `B;
                12'd1448: toneL = `B; 12'd1449: toneL = `B;
                12'd1450: toneL = `B; 12'd1451: toneL = `B;
                12'd1452: toneL = `B; 12'd1453: toneL = `B;
                12'd1454: toneL = `B; 12'd1455: toneL = `B;

                12'd1456: toneL = `f0B; 12'd1457: toneL = `f0B;
                12'd1458: toneL = `f0B; 12'd1459: toneL = `f0B;
                12'd1460: toneL = `f0B; 12'd1461: toneL = `f0B;
                12'd1462: toneL = `f0B; 12'd1463: toneL = `f0B;
                12'd1464: toneL = `f0B; 12'd1465: toneL = `f0B;
                12'd1466: toneL = `f0B; 12'd1467: toneL = `f0B;
                12'd1468: toneL = `f0B; 12'd1469: toneL = `f0B;
                12'd1470: toneL = `f0B; 12'd1471: toneL = `f0B;

                12'd1472: toneL = `B; 12'd1473: toneL = `B;
                12'd1474: toneL = `B; 12'd1475: toneL = `B;
                12'd1476: toneL = `B; 12'd1477: toneL = `B;
                12'd1478: toneL = `B; 12'd1479: toneL = `B;
                12'd1480: toneL = `B; 12'd1481: toneL = `B;
                12'd1482: toneL = `B; 12'd1483: toneL = `B;
                12'd1484: toneL = `B; 12'd1485: toneL = `B;
                12'd1486: toneL = `B; 12'd1487: toneL = `B;

                12'd1488: toneL = `f0B; 12'd1489: toneL = `f0B;
                12'd1490: toneL = `f0B; 12'd1491: toneL = `f0B;
                12'd1492: toneL = `f0B; 12'd1493: toneL = `f0B;
                12'd1494: toneL = `f0B; 12'd1495: toneL = `f0B;
                12'd1496: toneL = `f0B; 12'd1497: toneL = `f0B;
                12'd1498: toneL = `f0B; 12'd1499: toneL = `f0B;
                12'd1500: toneL = `f0B; 12'd1501: toneL = `f0B;
                12'd1502: toneL = `f0B; 12'd1503: toneL = `f0B;

                12'd1504: toneL = `B; 12'd1505: toneL = `B;
                12'd1506: toneL = `B; 12'd1507: toneL = `B;
                12'd1508: toneL = `B; 12'd1509: toneL = `B;
                12'd1510: toneL = `B; 12'd1511: toneL = `B;
                12'd1512: toneL = `B; 12'd1513: toneL = `B;
                12'd1514: toneL = `B; 12'd1515: toneL = `B;
                12'd1516: toneL = `B; 12'd1517: toneL = `B;
                12'd1518: toneL = `B; 12'd1519: toneL = `B;

                12'd1520: toneL = `f0; 12'd1521: toneL = `f0;
                12'd1522: toneL = `f0; 12'd1523: toneL = `f0;
                12'd1524: toneL = `f0; 12'd1525: toneL = `f0;
                12'd1526: toneL = `f0; 12'd1527: toneL = `f0;
                12'd1528: toneL = `f0; 12'd1529: toneL = `f0;
                12'd1530: toneL = `f0; 12'd1531: toneL = `f0;
                12'd1532: toneL = `f0; 12'd1533: toneL = `f0;
                12'd1534: toneL = `f0; 12'd1535: toneL = `f0;

                12'd1536: toneL = `c0; 12'd1537: toneL = `c0;
                12'd1538: toneL = `c0; 12'd1539: toneL = `c0;
                12'd1540: toneL = `c0; 12'd1541: toneL = `c0;
                12'd1542: toneL = `c0; 12'd1543: toneL = `c0;
                12'd1544: toneL = `c0; 12'd1545: toneL = `c0;
                12'd1546: toneL = `c0; 12'd1547: toneL = `c0;
                12'd1548: toneL = `c0; 12'd1549: toneL = `c0;
                12'd1550: toneL = `c0; 12'd1551: toneL = `c0;

                12'd1552: toneL = `g0; 12'd1553: toneL = `g0;
                12'd1554: toneL = `g0; 12'd1555: toneL = `g0;
                12'd1556: toneL = `g0; 12'd1557: toneL = `g0;
                12'd1558: toneL = `g0; 12'd1559: toneL = `g0;
                12'd1560: toneL = `g0; 12'd1561: toneL = `g0;
                12'd1562: toneL = `g0; 12'd1563: toneL = `g0;
                12'd1564: toneL = `g0; 12'd1565: toneL = `g0;
                12'd1566: toneL = `g0; 12'd1567: toneL = `g0;

                12'd1568: toneL = `c0B; 12'd1569: toneL = `c0B;
                12'd1570: toneL = `c0B; 12'd1571: toneL = `c0B;
                12'd1572: toneL = `c0B; 12'd1573: toneL = `c0B;
                12'd1574: toneL = `c0B; 12'd1575: toneL = `c0B;
                12'd1576: toneL = `c0B; 12'd1577: toneL = `c0B;
                12'd1578: toneL = `c0B; 12'd1579: toneL = `c0B;
                12'd1580: toneL = `c0B; 12'd1581: toneL = `c0B;
                12'd1582: toneL = `c0B; 12'd1583: toneL = `c0B;

                12'd1584: toneL = `g0; 12'd1585: toneL = `g0;
                12'd1586: toneL = `g0; 12'd1587: toneL = `g0;
                12'd1588: toneL = `g0; 12'd1589: toneL = `g0;
                12'd1590: toneL = `g0; 12'd1591: toneL = `g0;
                12'd1592: toneL = `g0; 12'd1593: toneL = `g0;
                12'd1594: toneL = `g0; 12'd1595: toneL = `g0;
                12'd1596: toneL = `g0; 12'd1597: toneL = `g0;
                12'd1598: toneL = `g0; 12'd1599: toneL = `g0;

                12'd1600: toneL = `c0B; 12'd1601: toneL = `c0B;
                12'd1602: toneL = `c0B; 12'd1603: toneL = `c0B;
                12'd1604: toneL = `c0B; 12'd1605: toneL = `c0B;
                12'd1606: toneL = `c0B; 12'd1607: toneL = `c0B;
                12'd1608: toneL = `c0B; 12'd1609: toneL = `c0B;
                12'd1610: toneL = `c0B; 12'd1611: toneL = `c0B;
                12'd1612: toneL = `c0B; 12'd1613: toneL = `c0B;
                12'd1614: toneL = `c0B; 12'd1615: toneL = `c0B;

                12'd1616: toneL = `g0; 12'd1617: toneL = `g0;
                12'd1618: toneL = `g0; 12'd1619: toneL = `g0;
                12'd1620: toneL = `g0; 12'd1621: toneL = `g0;
                12'd1622: toneL = `g0; 12'd1623: toneL = `g0;
                12'd1624: toneL = `g0; 12'd1625: toneL = `g0;
                12'd1626: toneL = `g0; 12'd1627: toneL = `g0;
                12'd1628: toneL = `g0; 12'd1629: toneL = `g0;
                12'd1630: toneL = `g0; 12'd1631: toneL = `g0;

                12'd1632: toneL = `c0B; 12'd1633: toneL = `c0B;
                12'd1634: toneL = `c0B; 12'd1635: toneL = `c0B;
                12'd1636: toneL = `c0B; 12'd1637: toneL = `c0B;
                12'd1638: toneL = `c0B; 12'd1639: toneL = `c0B;
                12'd1640: toneL = `c0B; 12'd1641: toneL = `c0B;
                12'd1642: toneL = `c0B; 12'd1643: toneL = `c0B;
                12'd1644: toneL = `c0B; 12'd1645: toneL = `c0B;
                12'd1646: toneL = `c0B; 12'd1647: toneL = `c0B;

                12'd1648: toneL = `g0; 12'd1649: toneL = `g0;
                12'd1650: toneL = `g0; 12'd1651: toneL = `g0;
                12'd1652: toneL = `g0; 12'd1653: toneL = `g0;
                12'd1654: toneL = `g0; 12'd1655: toneL = `g0;
                12'd1656: toneL = `g0; 12'd1657: toneL = `g0;
                12'd1658: toneL = `g0; 12'd1659: toneL = `g0;
                12'd1660: toneL = `g0; 12'd1661: toneL = `g0;
                12'd1662: toneL = `g0; 12'd1663: toneL = `g0;

                12'd1664: toneL = `c0; 12'd1665: toneL = `c0;
                12'd1666: toneL = `c0; 12'd1667: toneL = `c0;
                12'd1668: toneL = `c0; 12'd1669: toneL = `c0;
                12'd1670: toneL = `c0; 12'd1671: toneL = `c0;
                12'd1672: toneL = `c0; 12'd1673: toneL = `c0;
                12'd1674: toneL = `c0; 12'd1675: toneL = `c0;
                12'd1676: toneL = `c0; 12'd1677: toneL = `c0;
                12'd1678: toneL = `c0; 12'd1679: toneL = `c0;

                12'd1680: toneL = `g0; 12'd1681: toneL = `g0;
                12'd1682: toneL = `g0; 12'd1683: toneL = `g0;
                12'd1684: toneL = `g0; 12'd1685: toneL = `g0;
                12'd1686: toneL = `g0; 12'd1687: toneL = `g0;
                12'd1688: toneL = `g0; 12'd1689: toneL = `g0;
                12'd1690: toneL = `g0; 12'd1691: toneL = `g0;
                12'd1692: toneL = `g0; 12'd1693: toneL = `g0;
                12'd1694: toneL = `g0; 12'd1695: toneL = `g0;

                12'd1696: toneL = `a0; 12'd1697: toneL = `a0;
                12'd1698: toneL = `a0; 12'd1699: toneL = `a0;
                12'd1700: toneL = `a0; 12'd1701: toneL = `a0;
                12'd1702: toneL = `a0; 12'd1703: toneL = `a0;
                12'd1704: toneL = `a0; 12'd1705: toneL = `a0;
                12'd1706: toneL = `a0; 12'd1707: toneL = `a0;
                12'd1708: toneL = `a0; 12'd1709: toneL = `a0;
                12'd1710: toneL = `a0; 12'd1711: toneL = `a0;

                12'd1712: toneL = `g0; 12'd1713: toneL = `g0;
                12'd1714: toneL = `g0; 12'd1715: toneL = `g0;
                12'd1716: toneL = `g0; 12'd1717: toneL = `g0;
                12'd1718: toneL = `g0; 12'd1719: toneL = `g0;
                12'd1720: toneL = `g0; 12'd1721: toneL = `g0;
                12'd1722: toneL = `g0; 12'd1723: toneL = `g0;
                12'd1724: toneL = `g0; 12'd1725: toneL = `g0;
                12'd1726: toneL = `g0; 12'd1727: toneL = `g0;

                12'd1728: toneL = `f0B; 12'd1729: toneL = `f0B;
                12'd1730: toneL = `f0B; 12'd1731: toneL = `f0B;
                12'd1732: toneL = `f0B; 12'd1733: toneL = `f0B;
                12'd1734: toneL = `f0B; 12'd1735: toneL = `f0B;
                12'd1736: toneL = `f0B; 12'd1737: toneL = `f0B;
                12'd1738: toneL = `f0B; 12'd1739: toneL = `f0B;
                12'd1740: toneL = `f0B; 12'd1741: toneL = `f0B;
                12'd1742: toneL = `f0B; 12'd1743: toneL = `f0B;

                12'd1744: toneL = `e0; 12'd1745: toneL = `e0;
                12'd1746: toneL = `e0; 12'd1747: toneL = `e0;
                12'd1748: toneL = `e0; 12'd1749: toneL = `e0;
                12'd1750: toneL = `e0; 12'd1751: toneL = `e0;
                12'd1752: toneL = `e0; 12'd1753: toneL = `e0;
                12'd1754: toneL = `e0; 12'd1755: toneL = `e0;
                12'd1756: toneL = `e0; 12'd1757: toneL = `e0;
                12'd1758: toneL = `e0; 12'd1759: toneL = `e0;

                12'd1760: toneL = `d0; 12'd1761: toneL = `d0;
                12'd1762: toneL = `d0; 12'd1763: toneL = `d0;
                12'd1764: toneL = `d0; 12'd1765: toneL = `d0;
                12'd1766: toneL = `d0; 12'd1767: toneL = `d0;
                12'd1768: toneL = `d0; 12'd1769: toneL = `d0;
                12'd1770: toneL = `d0; 12'd1771: toneL = `d0;
                12'd1772: toneL = `d0; 12'd1773: toneL = `d0;
                12'd1774: toneL = `d0; 12'd1775: toneL = `d0;

                12'd1776: toneL = `c0B; 12'd1777: toneL = `c0B;
                12'd1778: toneL = `c0B; 12'd1779: toneL = `c0B;
                12'd1780: toneL = `c0B; 12'd1781: toneL = `c0B;
                12'd1782: toneL = `c0B; 12'd1783: toneL = `c0B;
                12'd1784: toneL = `c0B; 12'd1785: toneL = `c0B;
                12'd1786: toneL = `c0B; 12'd1787: toneL = `c0B;
                12'd1788: toneL = `c0B; 12'd1789: toneL = `c0B;
                12'd1790: toneL = `c0B; 12'd1791: toneL = `c0B;

                12'd1792: toneL = `B; 12'd1793: toneL = `B;
                12'd1794: toneL = `B; 12'd1795: toneL = `B;
                12'd1796: toneL = `B; 12'd1797: toneL = `B;
                12'd1798: toneL = `B; 12'd1799: toneL = `B;
                12'd1800: toneL = `B; 12'd1801: toneL = `B;
                12'd1802: toneL = `B; 12'd1803: toneL = `B;
                12'd1804: toneL = `B; 12'd1805: toneL = `B;
                12'd1806: toneL = `B; 12'd1807: toneL = `B;

                12'd1808: toneL = `f0B; 12'd1809: toneL = `f0B;
                12'd1810: toneL = `f0B; 12'd1811: toneL = `f0B;
                12'd1812: toneL = `f0B; 12'd1813: toneL = `f0B;
                12'd1814: toneL = `f0B; 12'd1815: toneL = `f0B;
                12'd1816: toneL = `f0B; 12'd1817: toneL = `f0B;
                12'd1818: toneL = `f0B; 12'd1819: toneL = `f0B;
                12'd1820: toneL = `f0B; 12'd1821: toneL = `f0B;
                12'd1822: toneL = `f0B; 12'd1823: toneL = `f0B;

                12'd1824: toneL = `B; 12'd1825: toneL = `B;
                12'd1826: toneL = `B; 12'd1827: toneL = `B;
                12'd1828: toneL = `B; 12'd1829: toneL = `B;
                12'd1830: toneL = `B; 12'd1831: toneL = `B;
                12'd1832: toneL = `B; 12'd1833: toneL = `B;
                12'd1834: toneL = `B; 12'd1835: toneL = `B;
                12'd1836: toneL = `B; 12'd1837: toneL = `B;
                12'd1838: toneL = `B; 12'd1839: toneL = `B;

                12'd1840: toneL = `f0B; 12'd1841: toneL = `f0B;
                12'd1842: toneL = `f0B; 12'd1843: toneL = `f0B;
                12'd1844: toneL = `f0B; 12'd1845: toneL = `f0B;
                12'd1846: toneL = `f0B; 12'd1847: toneL = `f0B;
                12'd1848: toneL = `f0B; 12'd1849: toneL = `f0B;
                12'd1850: toneL = `f0B; 12'd1851: toneL = `f0B;
                12'd1852: toneL = `f0B; 12'd1853: toneL = `f0B;
                12'd1854: toneL = `f0B; 12'd1855: toneL = `f0B;

                12'd1856: toneL = `B; 12'd1857: toneL = `B;
                12'd1858: toneL = `B; 12'd1859: toneL = `B;
                12'd1860: toneL = `B; 12'd1861: toneL = `B;
                12'd1862: toneL = `B; 12'd1863: toneL = `B;
                12'd1864: toneL = `B; 12'd1865: toneL = `B;
                12'd1866: toneL = `B; 12'd1867: toneL = `B;
                12'd1868: toneL = `B; 12'd1869: toneL = `B;
                12'd1870: toneL = `B; 12'd1871: toneL = `B;

                12'd1872: toneL = `f0B; 12'd1873: toneL = `f0B;
                12'd1874: toneL = `f0B; 12'd1875: toneL = `f0B;
                12'd1876: toneL = `f0B; 12'd1877: toneL = `f0B;
                12'd1878: toneL = `f0B; 12'd1879: toneL = `f0B;
                12'd1880: toneL = `f0B; 12'd1881: toneL = `f0B;
                12'd1882: toneL = `f0B; 12'd1883: toneL = `f0B;
                12'd1884: toneL = `f0B; 12'd1885: toneL = `f0B;
                12'd1886: toneL = `f0B; 12'd1887: toneL = `f0B;

                12'd1888: toneL = `B; 12'd1889: toneL = `B;
                12'd1890: toneL = `B; 12'd1891: toneL = `B;
                12'd1892: toneL = `B; 12'd1893: toneL = `B;
                12'd1894: toneL = `B; 12'd1895: toneL = `B;
                12'd1896: toneL = `B; 12'd1897: toneL = `B;
                12'd1898: toneL = `B; 12'd1899: toneL = `B;
                12'd1900: toneL = `B; 12'd1901: toneL = `B;
                12'd1902: toneL = `B; 12'd1903: toneL = `B;

                12'd1904: toneL = `f0B; 12'd1905: toneL = `f0B;
                12'd1906: toneL = `f0B; 12'd1907: toneL = `f0B;
                12'd1908: toneL = `f0B; 12'd1909: toneL = `f0B;
                12'd1910: toneL = `f0B; 12'd1911: toneL = `f0B;
                12'd1912: toneL = `f0B; 12'd1913: toneL = `f0B;
                12'd1914: toneL = `f0B; 12'd1915: toneL = `f0B;
                12'd1916: toneL = `f0B; 12'd1917: toneL = `f0B;
                12'd1918: toneL = `f0B; 12'd1919: toneL = `f0B;

                12'd1920: toneL = `B; 12'd1921: toneL = `B;
                12'd1922: toneL = `B; 12'd1923: toneL = `B;
                12'd1924: toneL = `B; 12'd1925: toneL = `B;
                12'd1926: toneL = `B; 12'd1927: toneL = `B;
                12'd1928: toneL = `B; 12'd1929: toneL = `B;
                12'd1930: toneL = `B; 12'd1931: toneL = `B;
                12'd1932: toneL = `B; 12'd1933: toneL = `B;
                12'd1934: toneL = `B; 12'd1935: toneL = `B;

                12'd1936: toneL = `f0B; 12'd1937: toneL = `f0B;
                12'd1938: toneL = `f0B; 12'd1939: toneL = `f0B;
                12'd1940: toneL = `f0B; 12'd1941: toneL = `f0B;
                12'd1942: toneL = `f0B; 12'd1943: toneL = `f0B;
                12'd1944: toneL = `f0B; 12'd1945: toneL = `f0B;
                12'd1946: toneL = `f0B; 12'd1947: toneL = `f0B;
                12'd1948: toneL = `f0B; 12'd1949: toneL = `f0B;
                12'd1950: toneL = `f0B; 12'd1951: toneL = `f0B;

                12'd1952: toneL = `B; 12'd1953: toneL = `B;
                12'd1954: toneL = `B; 12'd1955: toneL = `B;
                12'd1956: toneL = `B; 12'd1957: toneL = `B;
                12'd1958: toneL = `B; 12'd1959: toneL = `B;
                12'd1960: toneL = `B; 12'd1961: toneL = `B;
                12'd1962: toneL = `B; 12'd1963: toneL = `B;
                12'd1964: toneL = `B; 12'd1965: toneL = `B;
                12'd1966: toneL = `B; 12'd1967: toneL = `B;

                12'd1968: toneL = `f0B; 12'd1969: toneL = `f0B;
                12'd1970: toneL = `f0B; 12'd1971: toneL = `f0B;
                12'd1972: toneL = `f0B; 12'd1973: toneL = `f0B;
                12'd1974: toneL = `f0B; 12'd1975: toneL = `f0B;
                12'd1976: toneL = `f0B; 12'd1977: toneL = `f0B;
                12'd1978: toneL = `f0B; 12'd1979: toneL = `f0B;
                12'd1980: toneL = `f0B; 12'd1981: toneL = `f0B;
                12'd1982: toneL = `f0B; 12'd1983: toneL = `f0B;

                12'd1984: toneL = `B; 12'd1985: toneL = `B;
                12'd1986: toneL = `B; 12'd1987: toneL = `B;
                12'd1988: toneL = `B; 12'd1989: toneL = `B;
                12'd1990: toneL = `B; 12'd1991: toneL = `B;
                12'd1992: toneL = `B; 12'd1993: toneL = `B;
                12'd1994: toneL = `B; 12'd1995: toneL = `B;
                12'd1996: toneL = `B; 12'd1997: toneL = `B;
                12'd1998: toneL = `B; 12'd1999: toneL = `B;

                12'd2000: toneL = `f0B; 12'd2001: toneL = `f0B;
                12'd2002: toneL = `f0B; 12'd2003: toneL = `f0B;
                12'd2004: toneL = `f0B; 12'd2005: toneL = `f0B;
                12'd2006: toneL = `f0B; 12'd2007: toneL = `f0B;
                12'd2008: toneL = `f0B; 12'd2009: toneL = `f0B;
                12'd2010: toneL = `f0B; 12'd2011: toneL = `f0B;
                12'd2012: toneL = `f0B; 12'd2013: toneL = `f0B;
                12'd2014: toneL = `f0B; 12'd2015: toneL = `f0B;

                12'd2016: toneL = `B; 12'd2017: toneL = `B;
                12'd2018: toneL = `B; 12'd2019: toneL = `B;
                12'd2020: toneL = `B; 12'd2021: toneL = `B;
                12'd2022: toneL = `B; 12'd2023: toneL = `B;
                12'd2024: toneL = `B; 12'd2025: toneL = `B;
                12'd2026: toneL = `B; 12'd2027: toneL = `B;
                12'd2028: toneL = `B; 12'd2029: toneL = `B;
                12'd2030: toneL = `B; 12'd2031: toneL = `B;

                12'd2032: toneL = `f0; 12'd2033: toneL = `f0;
                12'd2034: toneL = `f0; 12'd2035: toneL = `f0;
                12'd2036: toneL = `f0; 12'd2037: toneL = `f0;
                12'd2038: toneL = `f0; 12'd2039: toneL = `f0;
                12'd2040: toneL = `f0; 12'd2041: toneL = `f0;
                12'd2042: toneL = `f0; 12'd2043: toneL = `f0;
                12'd2044: toneL = `f0; 12'd2045: toneL = `f0;
                12'd2046: toneL = `f0; 12'd2047: toneL = `f0;

                12'd2048: toneL = `A; 12'd2049: toneL = `A;
                12'd2050: toneL = `A; 12'd2051: toneL = `A;
                12'd2052: toneL = `A; 12'd2053: toneL = `A;
                12'd2054: toneL = `A; 12'd2055: toneL = `A;
                12'd2056: toneL = `A; 12'd2057: toneL = `A;
                12'd2058: toneL = `A; 12'd2059: toneL = `A;
                12'd2060: toneL = `A; 12'd2061: toneL = `A;
                12'd2062: toneL = `A; 12'd2063: toneL = `A;

                12'd2064: toneL = `e0; 12'd2065: toneL = `e0;
                12'd2066: toneL = `e0; 12'd2067: toneL = `e0;
                12'd2068: toneL = `e0; 12'd2069: toneL = `e0;
                12'd2070: toneL = `e0; 12'd2071: toneL = `e0;
                12'd2072: toneL = `e0; 12'd2073: toneL = `e0;
                12'd2074: toneL = `e0; 12'd2075: toneL = `e0;
                12'd2076: toneL = `e0; 12'd2077: toneL = `e0;
                12'd2078: toneL = `e0; 12'd2079: toneL = `e0;

                12'd2080: toneL = `A; 12'd2081: toneL = `A;
                12'd2082: toneL = `A; 12'd2083: toneL = `A;
                12'd2084: toneL = `A; 12'd2085: toneL = `A;
                12'd2086: toneL = `A; 12'd2087: toneL = `A;
                12'd2088: toneL = `A; 12'd2089: toneL = `A;
                12'd2090: toneL = `A; 12'd2091: toneL = `A;
                12'd2092: toneL = `A; 12'd2093: toneL = `A;
                12'd2094: toneL = `A; 12'd2095: toneL = `A;

                12'd2096: toneL = `e0; 12'd2097: toneL = `e0;
                12'd2098: toneL = `e0; 12'd2099: toneL = `e0;
                12'd2100: toneL = `e0; 12'd2101: toneL = `e0;
                12'd2102: toneL = `e0; 12'd2103: toneL = `e0;
                12'd2104: toneL = `e0; 12'd2105: toneL = `e0;
                12'd2106: toneL = `e0; 12'd2107: toneL = `e0;
                12'd2108: toneL = `e0; 12'd2109: toneL = `e0;
                12'd2110: toneL = `e0; 12'd2111: toneL = `e0;

                12'd2112: toneL = `A; 12'd2113: toneL = `A;
                12'd2114: toneL = `A; 12'd2115: toneL = `A;
                12'd2116: toneL = `A; 12'd2117: toneL = `A;
                12'd2118: toneL = `A; 12'd2119: toneL = `A;
                12'd2120: toneL = `A; 12'd2121: toneL = `A;
                12'd2122: toneL = `A; 12'd2123: toneL = `A;
                12'd2124: toneL = `A; 12'd2125: toneL = `A;
                12'd2126: toneL = `A; 12'd2127: toneL = `A;

                12'd2128: toneL = `e0; 12'd2129: toneL = `e0;
                12'd2130: toneL = `e0; 12'd2131: toneL = `e0;
                12'd2132: toneL = `e0; 12'd2133: toneL = `e0;
                12'd2134: toneL = `e0; 12'd2135: toneL = `e0;
                12'd2136: toneL = `e0; 12'd2137: toneL = `e0;
                12'd2138: toneL = `e0; 12'd2139: toneL = `e0;
                12'd2140: toneL = `e0; 12'd2141: toneL = `e0;
                12'd2142: toneL = `e0; 12'd2143: toneL = `e0;

                12'd2144: toneL = `A; 12'd2145: toneL = `A;
                12'd2146: toneL = `A; 12'd2147: toneL = `A;
                12'd2148: toneL = `A; 12'd2149: toneL = `A;
                12'd2150: toneL = `A; 12'd2151: toneL = `A;
                12'd2152: toneL = `A; 12'd2153: toneL = `A;
                12'd2154: toneL = `A; 12'd2155: toneL = `A;
                12'd2156: toneL = `A; 12'd2157: toneL = `A;
                12'd2158: toneL = `A; 12'd2159: toneL = `A;

                12'd2160: toneL = `e0; 12'd2161: toneL = `e0;
                12'd2162: toneL = `e0; 12'd2163: toneL = `e0;
                12'd2164: toneL = `e0; 12'd2165: toneL = `e0;
                12'd2166: toneL = `e0; 12'd2167: toneL = `e0;
                12'd2168: toneL = `e0; 12'd2169: toneL = `e0;
                12'd2170: toneL = `e0; 12'd2171: toneL = `e0;
                12'd2172: toneL = `e0; 12'd2173: toneL = `e0;
                12'd2174: toneL = `e0; 12'd2175: toneL = `e0;

                12'd2176: toneL = `A; 12'd2177: toneL = `A;
                12'd2178: toneL = `A; 12'd2179: toneL = `A;
                12'd2180: toneL = `A; 12'd2181: toneL = `A;
                12'd2182: toneL = `A; 12'd2183: toneL = `A;
                12'd2184: toneL = `A; 12'd2185: toneL = `A;
                12'd2186: toneL = `A; 12'd2187: toneL = `A;
                12'd2188: toneL = `A; 12'd2189: toneL = `A;
                12'd2190: toneL = `A; 12'd2191: toneL = `A;

                12'd2192: toneL = `e0; 12'd2193: toneL = `e0;
                12'd2194: toneL = `e0; 12'd2195: toneL = `e0;
                12'd2196: toneL = `e0; 12'd2197: toneL = `e0;
                12'd2198: toneL = `e0; 12'd2199: toneL = `e0;
                12'd2200: toneL = `e0; 12'd2201: toneL = `e0;
                12'd2202: toneL = `e0; 12'd2203: toneL = `e0;
                12'd2204: toneL = `e0; 12'd2205: toneL = `e0;
                12'd2206: toneL = `e0; 12'd2207: toneL = `e0;

                12'd2208: toneL = `d0; 12'd2209: toneL = `d0;
                12'd2210: toneL = `d0; 12'd2211: toneL = `d0;
                12'd2212: toneL = `d0; 12'd2213: toneL = `d0;
                12'd2214: toneL = `d0; 12'd2215: toneL = `d0;
                12'd2216: toneL = `d0; 12'd2217: toneL = `d0;
                12'd2218: toneL = `d0; 12'd2219: toneL = `d0;
                12'd2220: toneL = `d0; 12'd2221: toneL = `d0;
                12'd2222: toneL = `d0; 12'd2223: toneL = `d0;

                12'd2224: toneL = `c0B; 12'd2225: toneL = `c0B;
                12'd2226: toneL = `c0B; 12'd2227: toneL = `c0B;
                12'd2228: toneL = `c0B; 12'd2229: toneL = `c0B;
                12'd2230: toneL = `c0B; 12'd2231: toneL = `c0B;
                12'd2232: toneL = `c0B; 12'd2233: toneL = `c0B;
                12'd2234: toneL = `c0B; 12'd2235: toneL = `c0B;
                12'd2236: toneL = `c0B; 12'd2237: toneL = `c0B;
                12'd2238: toneL = `c0B; 12'd2239: toneL = `c0B;

                12'd2240: toneL = `d0; 12'd2241: toneL = `d0;
                12'd2242: toneL = `d0; 12'd2243: toneL = `d0;
                12'd2244: toneL = `d0; 12'd2245: toneL = `d0;
                12'd2246: toneL = `d0; 12'd2247: toneL = `d0;
                12'd2248: toneL = `d0; 12'd2249: toneL = `d0;
                12'd2250: toneL = `d0; 12'd2251: toneL = `d0;
                12'd2252: toneL = `d0; 12'd2253: toneL = `d0;
                12'd2254: toneL = `d0; 12'd2255: toneL = `d0;

                12'd2256: toneL = `c0B; 12'd2257: toneL = `c0B;
                12'd2258: toneL = `c0B; 12'd2259: toneL = `c0B;
                12'd2260: toneL = `c0B; 12'd2261: toneL = `c0B;
                12'd2262: toneL = `c0B; 12'd2263: toneL = `c0B;
                12'd2264: toneL = `c0B; 12'd2265: toneL = `c0B;
                12'd2266: toneL = `c0B; 12'd2267: toneL = `c0B;
                12'd2268: toneL = `c0B; 12'd2269: toneL = `c0B;
                12'd2270: toneL = `c0B; 12'd2271: toneL = `c0B;

                12'd2272: toneL = `A; 12'd2273: toneL = `A;
                12'd2274: toneL = `A; 12'd2275: toneL = `A;
                12'd2276: toneL = `A; 12'd2277: toneL = `A;
                12'd2278: toneL = `A; 12'd2279: toneL = `A;
                12'd2280: toneL = `A; 12'd2281: toneL = `A;
                12'd2282: toneL = `A; 12'd2283: toneL = `A;
                12'd2284: toneL = `A; 12'd2285: toneL = `A;
                12'd2286: toneL = `A; 12'd2287: toneL = `A;

                12'd2288: toneL = `Ab; 12'd2289: toneL = `Ab;
                12'd2290: toneL = `Ab; 12'd2291: toneL = `Ab;
                12'd2292: toneL = `Ab; 12'd2293: toneL = `Ab;
                12'd2294: toneL = `Ab; 12'd2295: toneL = `Ab;
                12'd2296: toneL = `Ab; 12'd2297: toneL = `Ab;
                12'd2298: toneL = `Ab; 12'd2299: toneL = `Ab;
                12'd2300: toneL = `Ab; 12'd2301: toneL = `Ab;
                12'd2302: toneL = `Ab; 12'd2303: toneL = `Ab;

                12'd2304: toneL = `d1; 12'd2305: toneL = `d1;
                12'd2306: toneL = `d1; 12'd2307: toneL = `d1;
                12'd2308: toneL = `d1; 12'd2309: toneL = `d1;
                12'd2310: toneL = `d1; 12'd2311: toneL = `d1;
                12'd2312: toneL = `d1; 12'd2313: toneL = `d1;
                12'd2314: toneL = `d1; 12'd2315: toneL = `d1;
                12'd2316: toneL = `d1; 12'd2317: toneL = `d1;
                12'd2318: toneL = `d1; 12'd2319: toneL = `d1;

                12'd2320: toneL = `c1B; 12'd2321: toneL = `c1B;
                12'd2322: toneL = `c1B; 12'd2323: toneL = `c1B;
                12'd2324: toneL = `c1B; 12'd2325: toneL = `c1B;
                12'd2326: toneL = `c1B; 12'd2327: toneL = `c1B;
                12'd2328: toneL = `c1B; 12'd2329: toneL = `c1B;
                12'd2330: toneL = `c1B; 12'd2331: toneL = `c1B;
                12'd2332: toneL = `c1B; 12'd2333: toneL = `c1B;
                12'd2334: toneL = `c1B; 12'd2335: toneL = `c1B;

                12'd2336: toneL = `b0; 12'd2337: toneL = `b0;
                12'd2338: toneL = `b0; 12'd2339: toneL = `b0;
                12'd2340: toneL = `b0; 12'd2341: toneL = `b0;
                12'd2342: toneL = `b0; 12'd2343: toneL = `b0;
                12'd2344: toneL = `b0; 12'd2345: toneL = `b0;
                12'd2346: toneL = `b0; 12'd2347: toneL = `b0;
                12'd2348: toneL = `b0; 12'd2349: toneL = `b0;
                12'd2350: toneL = `b0; 12'd2351: toneL = `b0;       

                12'd2352: toneL = `a0; 12'd2353: toneL = `a0;
                12'd2354: toneL = `a0; 12'd2355: toneL = `a0;
                12'd2356: toneL = `a0; 12'd2357: toneL = `a0;
                12'd2358: toneL = `a0; 12'd2359: toneL = `a0;
                12'd2360: toneL = `a0; 12'd2361: toneL = `a0;
                12'd2362: toneL = `a0; 12'd2363: toneL = `a0;
                12'd2364: toneL = `a0; 12'd2365: toneL = `a0;
                12'd2366: toneL = `a0; 12'd2367: toneL = `a0;   

                12'd2368: toneL = `g0; 12'd2369: toneL = `g0;
                12'd2370: toneL = `g0; 12'd2371: toneL = `g0;
                12'd2372: toneL = `g0; 12'd2373: toneL = `g0;
                12'd2374: toneL = `g0; 12'd2375: toneL = `g0;
                12'd2376: toneL = `g0; 12'd2377: toneL = `g0;
                12'd2378: toneL = `g0; 12'd2379: toneL = `g0;
                12'd2380: toneL = `g0; 12'd2381: toneL = `g0;
                12'd2382: toneL = `g0; 12'd2383: toneL = `g0;
                12'd2384: toneL = `g0; 12'd2385: toneL = `g0;
                12'd2386: toneL = `g0; 12'd2387: toneL = `g0;
                12'd2388: toneL = `g0; 12'd2389: toneL = `g0;
                12'd2390: toneL = `g0; 12'd2391: toneL = `g0;
                12'd2392: toneL = `g0; 12'd2393: toneL = `g0;
                12'd2394: toneL = `g0; 12'd2395: toneL = `g0;
                12'd2396: toneL = `g0; 12'd2397: toneL = `g0;
                12'd2398: toneL = `g0; 12'd2399: toneL = `g0;

                12'd2400: toneL = `d1; 12'd2401: toneL = `d1;
                12'd2402: toneL = `d1; 12'd2403: toneL = `d1;
                12'd2404: toneL = `d1; 12'd2405: toneL = `d1;
                12'd2406: toneL = `d1; 12'd2407: toneL = `d1;
                12'd2408: toneL = `d1; 12'd2409: toneL = `d1;
                12'd2410: toneL = `d1; 12'd2411: toneL = `d1;
                12'd2412: toneL = `d1; 12'd2413: toneL = `d1;
                12'd2414: toneL = `d1; 12'd2415: toneL = `d1;

                12'd2416: toneL = `c1B; 12'd2417: toneL = `c1B;
                12'd2418: toneL = `c1B; 12'd2419: toneL = `c1B;
                12'd2420: toneL = `c1B; 12'd2421: toneL = `c1B;
                12'd2422: toneL = `c1B; 12'd2423: toneL = `c1B;
                12'd2424: toneL = `c1B; 12'd2425: toneL = `c1B;
                12'd2426: toneL = `c1B; 12'd2427: toneL = `c1B;
                12'd2428: toneL = `c1B; 12'd2429: toneL = `c1B;
                12'd2430: toneL = `c1B; 12'd2431: toneL = `c1B;

                12'd2432: toneL = `sil; 12'd2433: toneL = `sil;
                12'd2434: toneL = `sil; 12'd2435: toneL = `sil;
                12'd2436: toneL = `sil; 12'd2437: toneL = `sil;
                12'd2438: toneL = `sil; 12'd2439: toneL = `sil;
                12'd2440: toneL = `sil; 12'd2441: toneL = `sil;
                12'd2442: toneL = `sil; 12'd2443: toneL = `sil;
                12'd2444: toneL = `sil; 12'd2445: toneL = `sil;
                12'd2446: toneL = `sil; 12'd2447: toneL = `sil;

                12'd2448: toneL = `a0; 12'd2449: toneL = `a0;
                12'd2450: toneL = `a0; 12'd2451: toneL = `a0;
                12'd2452: toneL = `a0; 12'd2453: toneL = `a0;
                12'd2454: toneL = `a0; 12'd2455: toneL = `a0;
                12'd2456: toneL = `a0; 12'd2457: toneL = `a0;
                12'd2458: toneL = `a0; 12'd2459: toneL = `a0;
                12'd2460: toneL = `a0; 12'd2461: toneL = `a0;
                12'd2462: toneL = `a0; 12'd2463: toneL = `a0;

                12'd2464: toneL = `g0; 12'd2465: toneL = `g0;
                12'd2466: toneL = `g0; 12'd2467: toneL = `g0;
                12'd2468: toneL = `g0; 12'd2469: toneL = `g0;
                12'd2470: toneL = `g0; 12'd2471: toneL = `g0;
                12'd2472: toneL = `g0; 12'd2473: toneL = `g0;
                12'd2474: toneL = `g0; 12'd2475: toneL = `g0;
                12'd2476: toneL = `g0; 12'd2477: toneL = `g0;
                12'd2478: toneL = `g0; 12'd2479: toneL = `g0;
                12'd2480: toneL = `g0; 12'd2481: toneL = `g0;
                12'd2482: toneL = `g0; 12'd2483: toneL = `g0;
                12'd2484: toneL = `g0; 12'd2485: toneL = `g0;
                12'd2486: toneL = `g0; 12'd2487: toneL = `g0;
                12'd2488: toneL = `g0; 12'd2489: toneL = `g0;
                12'd2490: toneL = `g0; 12'd2491: toneL = `g0;
                12'd2492: toneL = `g0; 12'd2493: toneL = `g0;
                12'd2494: toneL = `g0; 12'd2495: toneL = `g0;

                12'd2496: toneL = `d1; 12'd2497: toneL = `d1;
                12'd2498: toneL = `d1; 12'd2499: toneL = `d1;
                12'd2500: toneL = `d1; 12'd2501: toneL = `d1;
                12'd2502: toneL = `d1; 12'd2503: toneL = `d1;
                12'd2504: toneL = `d1; 12'd2505: toneL = `d1;
                12'd2506: toneL = `d1; 12'd2507: toneL = `d1;
                12'd2508: toneL = `d1; 12'd2509: toneL = `d1;
                12'd2510: toneL = `d1; 12'd2511: toneL = `d1;

                12'd2512: toneL = `c1B; 12'd2513: toneL = `c1B;
                12'd2514: toneL = `c1B; 12'd2515: toneL = `c1B;
                12'd2516: toneL = `c1B; 12'd2517: toneL = `c1B;
                12'd2518: toneL = `c1B; 12'd2519: toneL = `c1B;
                12'd2520: toneL = `c1B; 12'd2521: toneL = `c1B;
                12'd2522: toneL = `c1B; 12'd2523: toneL = `c1B;
                12'd2524: toneL = `c1B; 12'd2525: toneL = `c1B;
                12'd2526: toneL = `c1B; 12'd2527: toneL = `c1B;

                12'd2528: toneL = `b0; 12'd2529: toneL = `b0;
                12'd2530: toneL = `b0; 12'd2531: toneL = `b0;
                12'd2532: toneL = `b0; 12'd2533: toneL = `b0;
                12'd2534: toneL = `b0; 12'd2535: toneL = `b0;
                12'd2536: toneL = `b0; 12'd2537: toneL = `b0;
                12'd2538: toneL = `b0; 12'd2539: toneL = `b0;
                12'd2540: toneL = `b0; 12'd2541: toneL = `b0;
                12'd2542: toneL = `b0; 12'd2543: toneL = `b0;

                12'd2544: toneL = `c1B; 12'd2545: toneL = `c1B;
                12'd2546: toneL = `c1B; 12'd2547: toneL = `c1B;
                12'd2548: toneL = `c1B; 12'd2549: toneL = `c1B;
                12'd2550: toneL = `c1B; 12'd2551: toneL = `c1B;
                12'd2552: toneL = `c1B; 12'd2553: toneL = `c1B;
                12'd2554: toneL = `c1B; 12'd2555: toneL = `c1B;
                12'd2556: toneL = `c1B; 12'd2557: toneL = `c1B;
                12'd2558: toneL = `c1B; 12'd2559: toneL = `c1B;

                12'd2560: toneL = `e1; 12'd2561: toneL = `e1;
                12'd2562: toneL = `e1; 12'd2563: toneL = `e1;
                12'd2564: toneL = `e1; 12'd2565: toneL = `e1;
                12'd2566: toneL = `e1; 12'd2567: toneL = `e1;
                12'd2568: toneL = `e1; 12'd2569: toneL = `e1;
                12'd2570: toneL = `e1; 12'd2571: toneL = `e1;
                12'd2572: toneL = `e1; 12'd2573: toneL = `e1;
                12'd2574: toneL = `e1; 12'd2575: toneL = `e1;
                12'd2576: toneL = `e1; 12'd2577: toneL = `e1;
                12'd2578: toneL = `e1; 12'd2579: toneL = `e1;
                12'd2580: toneL = `e1; 12'd2581: toneL = `e1;
                12'd2582: toneL = `e1; 12'd2583: toneL = `e1;
                12'd2584: toneL = `e1; 12'd2585: toneL = `e1;
                12'd2586: toneL = `e1; 12'd2587: toneL = `e1;
                12'd2588: toneL = `e1; 12'd2589: toneL = `e1;
                12'd2590: toneL = `e1; 12'd2591: toneL = `e1;

                12'd2592: toneL = `g0; 12'd2593: toneL = `g0;
                12'd2594: toneL = `g0; 12'd2595: toneL = `g0;
                12'd2596: toneL = `g0; 12'd2597: toneL = `g0;
                12'd2598: toneL = `g0; 12'd2599: toneL = `g0;

                12'd2600: toneL = `a0; 12'd2601: toneL = `a0;
                12'd2602: toneL = `a0; 12'd2603: toneL = `a0;
                12'd2604: toneL = `a0; 12'd2605: toneL = `a0;
                12'd2606: toneL = `a0; 12'd2607: toneL = `a0;

                12'd2608: toneL = `b0; 12'd2609: toneL = `b0;
                12'd2610: toneL = `b0; 12'd2611: toneL = `b0;
                12'd2612: toneL = `b0; 12'd2613: toneL = `b0;
                12'd2614: toneL = `b0; 12'd2615: toneL = `b0;

                12'd2616: toneL = `c1B; 12'd2617: toneL = `c1B;
                12'd2618: toneL = `c1B; 12'd2619: toneL = `c1B;
                12'd2620: toneL = `c1B; 12'd2621: toneL = `c1B;
                12'd2622: toneL = `c1B; 12'd2623: toneL = `c1B;

                12'd2624: toneL = `d1; 12'd2625: toneL = `d1;
                12'd2626: toneL = `d1; 12'd2627: toneL = `d1;
                12'd2628: toneL = `d1; 12'd2629: toneL = `d1;
                12'd2630: toneL = `d1; 12'd2631: toneL = `d1;
                12'd2632: toneL = `d1; 12'd2633: toneL = `d1;
                12'd2634: toneL = `d1; 12'd2635: toneL = `d1;
                12'd2636: toneL = `d1; 12'd2637: toneL = `d1;
                12'd2638: toneL = `d1; 12'd2639: toneL = `d1;
                12'd2640: toneL = `d1; 12'd2641: toneL = `d1;
                12'd2642: toneL = `d1; 12'd2643: toneL = `d1;
                12'd2644: toneL = `d1; 12'd2645: toneL = `d1;
                12'd2646: toneL = `d1; 12'd2647: toneL = `d1;
                12'd2648: toneL = `d1; 12'd2649: toneL = `d1;
                12'd2650: toneL = `d1; 12'd2651: toneL = `d1;
                12'd2652: toneL = `d1; 12'd2653: toneL = `d1;
                12'd2654: toneL = `d1; 12'd2655: toneL = `d1;

                12'd2656: toneL = `f0B; 12'd2657: toneL = `f0B;
                12'd2658: toneL = `f0B; 12'd2659: toneL = `f0B;
                12'd2660: toneL = `f0B; 12'd2661: toneL = `f0B;
                12'd2662: toneL = `f0B; 12'd2663: toneL = `f0B;

                12'd2664: toneL = `g0; 12'd2665: toneL = `g0;
                12'd2666: toneL = `g0; 12'd2667: toneL = `g0;
                12'd2668: toneL = `g0; 12'd2669: toneL = `g0;
                12'd2670: toneL = `g0; 12'd2671: toneL = `g0;

                12'd2672: toneL = `a0; 12'd2673: toneL = `a0;
                12'd2674: toneL = `a0; 12'd2675: toneL = `a0;
                12'd2676: toneL = `a0; 12'd2677: toneL = `a0;
                12'd2678: toneL = `a0; 12'd2679: toneL = `a0;

                12'd2680: toneL = `b0; 12'd2681: toneL = `b0;
                12'd2682: toneL = `b0; 12'd2683: toneL = `b0;
                12'd2684: toneL = `b0; 12'd2685: toneL = `b0;
                12'd2686: toneL = `b0; 12'd2687: toneL = `b0;

                12'd2688: toneL = `c1B; 12'd2689: toneL = `c1B;
                12'd2690: toneL = `c1B; 12'd2691: toneL = `c1B;
                12'd2692: toneL = `c1B; 12'd2693: toneL = `c1B;
                12'd2694: toneL = `c1B; 12'd2695: toneL = `c1B;
                12'd2696: toneL = `c1B; 12'd2697: toneL = `c1B;
                12'd2698: toneL = `c1B; 12'd2699: toneL = `c1B;
                12'd2700: toneL = `c1B; 12'd2701: toneL = `c1B;
                12'd2702: toneL = `c1B; 12'd2703: toneL = `c1B;
                12'd2704: toneL = `c1B; 12'd2705: toneL = `c1B;
                12'd2706: toneL = `c1B; 12'd2707: toneL = `c1B;
                12'd2708: toneL = `c1B; 12'd2709: toneL = `c1B;
                12'd2710: toneL = `c1B; 12'd2711: toneL = `c1B;
                12'd2712: toneL = `c1B; 12'd2713: toneL = `c1B;
                12'd2714: toneL = `c1B; 12'd2715: toneL = `c1B;
                12'd2716: toneL = `c1B; 12'd2717: toneL = `c1B;
                12'd2718: toneL = `c1B; 12'd2719: toneL = `c1B;

                12'd2720: toneL = `g0; 12'd2721: toneL = `g0;
                12'd2722: toneL = `g0; 12'd2723: toneL = `g0;
                12'd2724: toneL = `g0; 12'd2725: toneL = `g0;
                12'd2726: toneL = `g0; 12'd2727: toneL = `g0;

                12'd2728: toneL = `a0; 12'd2729: toneL = `a0;
                12'd2730: toneL = `a0; 12'd2731: toneL = `a0;
                12'd2732: toneL = `a0; 12'd2733: toneL = `a0;
                12'd2734: toneL = `a0; 12'd2735: toneL = `a0;

                12'd2736: toneL = `b0; 12'd2737: toneL = `b0;
                12'd2738: toneL = `b0; 12'd2739: toneL = `b0;
                12'd2740: toneL = `b0; 12'd2741: toneL = `b0;
                12'd2742: toneL = `b0; 12'd2743: toneL = `b0;

                12'd2744: toneL = `c1B; 12'd2745: toneL = `c1B;
                12'd2746: toneL = `c1B; 12'd2747: toneL = `c1B;
                12'd2748: toneL = `c1B; 12'd2749: toneL = `c1B;
                12'd2750: toneL = `c1B; 12'd2751: toneL = `c1B;

                12'd2752: toneL = `d1; 12'd2753: toneL = `d1;
                12'd2754: toneL = `d1; 12'd2755: toneL = `d1;
                12'd2756: toneL = `d1; 12'd2757: toneL = `d1;
                12'd2758: toneL = `d1; 12'd2759: toneL = `d1;
                12'd2760: toneL = `d1; 12'd2761: toneL = `d1;
                12'd2762: toneL = `d1; 12'd2763: toneL = `d1;
                12'd2764: toneL = `d1; 12'd2765: toneL = `d1;
                12'd2766: toneL = `d1; 12'd2767: toneL = `d1;
                12'd2768: toneL = `d1; 12'd2769: toneL = `d1;
                12'd2770: toneL = `d1; 12'd2771: toneL = `d1;
                12'd2772: toneL = `d1; 12'd2773: toneL = `d1;
                12'd2774: toneL = `d1; 12'd2775: toneL = `d1;
                12'd2776: toneL = `d1; 12'd2777: toneL = `d1;
                12'd2778: toneL = `d1; 12'd2779: toneL = `d1;
                12'd2780: toneL = `d1; 12'd2781: toneL = `d1;
                12'd2782: toneL = `d1; 12'd2783: toneL = `d1;

                12'd2784: toneL = `f0B; 12'd2785: toneL = `f0B;
                12'd2786: toneL = `f0B; 12'd2787: toneL = `f0B;
                12'd2788: toneL = `f0B; 12'd2789: toneL = `f0B;
                12'd2790: toneL = `f0B; 12'd2791: toneL = `f0B;

                12'd2792: toneL = `g0; 12'd2793: toneL = `g0;
                12'd2794: toneL = `g0; 12'd2795: toneL = `g0;
                12'd2796: toneL = `g0; 12'd2797: toneL = `g0;
                12'd2798: toneL = `g0; 12'd2799: toneL = `g0;

                12'd2800: toneL = `a0; 12'd2801: toneL = `a0;
                12'd2802: toneL = `a0; 12'd2803: toneL = `a0;
                12'd2804: toneL = `a0; 12'd2805: toneL = `a0;
                12'd2806: toneL = `a0; 12'd2807: toneL = `a0;

                12'd2808: toneL = `b0; 12'd2809: toneL = `b0;
                12'd2810: toneL = `b0; 12'd2811: toneL = `b0;
                12'd2812: toneL = `b0; 12'd2813: toneL = `b0;
                12'd2814: toneL = `b0; 12'd2815: toneL = `b0;

                12'd2816: toneL = `d1; 12'd2817: toneL = `d1;
                12'd2818: toneL = `d1; 12'd2819: toneL = `d1;
                12'd2820: toneL = `d1; 12'd2821: toneL = `d1;
                12'd2822: toneL = `d1; 12'd2823: toneL = `d1;
                12'd2824: toneL = `d1; 12'd2825: toneL = `d1;
                12'd2826: toneL = `d1; 12'd2827: toneL = `d1;
                12'd2828: toneL = `d1; 12'd2829: toneL = `d1;
                12'd2830: toneL = `d1; 12'd2831: toneL = `d1;

                12'd2832: toneL = `c1B; 12'd2833: toneL = `c1B;
                12'd2834: toneL = `c1B; 12'd2835: toneL = `c1B;
                12'd2836: toneL = `c1B; 12'd2837: toneL = `c1B;
                12'd2838: toneL = `c1B; 12'd2839: toneL = `c1B;
                12'd2840: toneL = `c1B; 12'd2841: toneL = `c1B;
                12'd2842: toneL = `c1B; 12'd2843: toneL = `c1B;
                12'd2844: toneL = `c1B; 12'd2845: toneL = `c1B;
                12'd2846: toneL = `c1B; 12'd2847: toneL = `c1B;

                12'd2848: toneL = `b0; 12'd2849: toneL = `b0;
                12'd2850: toneL = `b0; 12'd2851: toneL = `b0;
                12'd2852: toneL = `b0; 12'd2853: toneL = `b0;
                12'd2854: toneL = `b0; 12'd2855: toneL = `b0;
                12'd2856: toneL = `b0; 12'd2857: toneL = `b0;
                12'd2858: toneL = `b0; 12'd2859: toneL = `b0;
                12'd2860: toneL = `b0; 12'd2861: toneL = `b0;
                12'd2862: toneL = `b0; 12'd2863: toneL = `b0;

                12'd2864: toneL = `a0; 12'd2865: toneL = `a0;
                12'd2866: toneL = `a0; 12'd2867: toneL = `a0;
                12'd2868: toneL = `a0; 12'd2869: toneL = `a0;
                12'd2870: toneL = `a0; 12'd2871: toneL = `a0;
                12'd2872: toneL = `a0; 12'd2873: toneL = `a0;
                12'd2874: toneL = `a0; 12'd2875: toneL = `a0;
                12'd2876: toneL = `a0; 12'd2877: toneL = `a0;
                12'd2878: toneL = `a0; 12'd2879: toneL = `a0;

                12'd2880: toneL = `g0; 12'd2881: toneL = `g0;
                12'd2882: toneL = `g0; 12'd2883: toneL = `g0;
                12'd2884: toneL = `g0; 12'd2885: toneL = `g0;
                12'd2886: toneL = `g0; 12'd2887: toneL = `g0;
                12'd2888: toneL = `g0; 12'd2889: toneL = `g0;
                12'd2890: toneL = `g0; 12'd2891: toneL = `g0;
                12'd2892: toneL = `g0; 12'd2893: toneL = `g0;
                12'd2894: toneL = `g0; 12'd2895: toneL = `g0;
                12'd2896: toneL = `g0; 12'd2897: toneL = `g0;
                12'd2898: toneL = `g0; 12'd2899: toneL = `g0;
                12'd2900: toneL = `g0; 12'd2901: toneL = `g0;
                12'd2902: toneL = `g0; 12'd2903: toneL = `g0;
                12'd2904: toneL = `g0; 12'd2905: toneL = `g0;
                12'd2906: toneL = `g0; 12'd2907: toneL = `g0;
                12'd2908: toneL = `g0; 12'd2909: toneL = `g0;
                12'd2910: toneL = `g0; 12'd2911: toneL = `g0;

                12'd2912: toneL = `d1; 12'd2913: toneL = `d1;
                12'd2914: toneL = `d1; 12'd2915: toneL = `d1;
                12'd2916: toneL = `d1; 12'd2917: toneL = `d1;
                12'd2918: toneL = `d1; 12'd2919: toneL = `d1;
                12'd2920: toneL = `d1; 12'd2921: toneL = `d1;
                12'd2922: toneL = `d1; 12'd2923: toneL = `d1;
                12'd2924: toneL = `d1; 12'd2925: toneL = `d1;
                12'd2926: toneL = `d1; 12'd2927: toneL = `d1;

                12'd2928: toneL = `c1B; 12'd2929: toneL = `c1B;
                12'd2930: toneL = `c1B; 12'd2931: toneL = `c1B;
                12'd2932: toneL = `c1B; 12'd2933: toneL = `c1B;
                12'd2934: toneL = `c1B; 12'd2935: toneL = `c1B;
                12'd2936: toneL = `c1B; 12'd2937: toneL = `c1B;
                12'd2938: toneL = `c1B; 12'd2939: toneL = `c1B;
                12'd2940: toneL = `c1B; 12'd2941: toneL = `c1B;
                12'd2942: toneL = `c1B; 12'd2943: toneL = `c1B;

                12'd2944: toneL = `sil; 12'd2945: toneL = `sil;
                12'd2946: toneL = `sil; 12'd2947: toneL = `sil;
                12'd2948: toneL = `sil; 12'd2949: toneL = `sil;
                12'd2950: toneL = `sil; 12'd2951: toneL = `sil;
                12'd2952: toneL = `sil; 12'd2953: toneL = `sil;
                12'd2954: toneL = `sil; 12'd2955: toneL = `sil;
                12'd2956: toneL = `sil; 12'd2957: toneL = `sil;
                12'd2958: toneL = `sil; 12'd2959: toneL = `sil;

                12'd2960: toneL = `a0; 12'd2961: toneL = `a0;
                12'd2962: toneL = `a0; 12'd2963: toneL = `a0;
                12'd2964: toneL = `a0; 12'd2965: toneL = `a0;
                12'd2966: toneL = `a0; 12'd2967: toneL = `a0;
                12'd2968: toneL = `a0; 12'd2969: toneL = `a0;
                12'd2970: toneL = `a0; 12'd2971: toneL = `a0;
                12'd2972: toneL = `a0; 12'd2973: toneL = `a0;
                12'd2974: toneL = `a0; 12'd2975: toneL = `a0;

                12'd2976: toneL = `b0; 12'd2977: toneL = `b0;
                12'd2978: toneL = `b0; 12'd2979: toneL = `b0;
                12'd2980: toneL = `b0; 12'd2981: toneL = `b0;
                12'd2982: toneL = `b0; 12'd2983: toneL = `b0;
                12'd2984: toneL = `b0; 12'd2985: toneL = `b0;
                12'd2986: toneL = `b0; 12'd2987: toneL = `b0;
                12'd2988: toneL = `b0; 12'd2989: toneL = `b0;
                12'd2990: toneL = `b0; 12'd2991: toneL = `b0;

                12'd2992: toneL = `g0; 12'd2993: toneL = `g0;
                12'd2994: toneL = `g0; 12'd2995: toneL = `g0;
                12'd2996: toneL = `g0; 12'd2997: toneL = `g0;
                12'd2998: toneL = `g0; 12'd2999: toneL = `g0;
                12'd3000: toneL = `g0; 12'd3001: toneL = `g0;
                12'd3002: toneL = `g0; 12'd3003: toneL = `g0;
                12'd3004: toneL = `g0; 12'd3005: toneL = `g0;
                12'd3006: toneL = `g0; 12'd3007: toneL = `g0;

                12'd3008: toneL = `sil; 12'd3009: toneL = `sil;
                12'd3010: toneL = `sil; 12'd3011: toneL = `sil;
                12'd3012: toneL = `sil; 12'd3013: toneL = `sil;
                12'd3014: toneL = `sil; 12'd3015: toneL = `sil;
                12'd3016: toneL = `sil; 12'd3017: toneL = `sil;
                12'd3018: toneL = `sil; 12'd3019: toneL = `sil;
                12'd3020: toneL = `sil; 12'd3021: toneL = `sil;
                12'd3022: toneL = `sil; 12'd3023: toneL = `sil;

                12'd3024: toneL = `e1; 12'd3025: toneL = `e1;
                12'd3026: toneL = `e1; 12'd3027: toneL = `e1;
                12'd3028: toneL = `e1; 12'd3029: toneL = `e1;
                12'd3030: toneL = `e1; 12'd3031: toneL = `e1;
                12'd3032: toneL = `e1; 12'd3033: toneL = `e1;
                12'd3034: toneL = `e1; 12'd3035: toneL = `e1;
                12'd3036: toneL = `e1; 12'd3037: toneL = `e1;
                12'd3038: toneL = `e1; 12'd3039: toneL = `e1;

                12'd3040: toneL = `f1B; 12'd3041: toneL = `f1B;
                12'd3042: toneL = `f1B; 12'd3043: toneL = `f1B;
                12'd3044: toneL = `f1B; 12'd3045: toneL = `f1B;
                12'd3046: toneL = `f1B; 12'd3047: toneL = `f1B;
                12'd3048: toneL = `f1B; 12'd3049: toneL = `f1B;
                12'd3050: toneL = `f1B; 12'd3051: toneL = `f1B;
                12'd3052: toneL = `f1B; 12'd3053: toneL = `f1B;
                12'd3054: toneL = `f1B; 12'd3055: toneL = `f1B;

                12'd3056: toneL = `g1; 12'd3057: toneL = `g1;
                12'd3058: toneL = `g1; 12'd3059: toneL = `g1;
                12'd3060: toneL = `g1; 12'd3061: toneL = `g1;
                12'd3062: toneL = `g1; 12'd3063: toneL = `g1;
                12'd3064: toneL = `g1; 12'd3065: toneL = `g1;
                12'd3066: toneL = `g1; 12'd3067: toneL = `g1;
                12'd3068: toneL = `g1; 12'd3069: toneL = `g1;
                12'd3070: toneL = `g1; 12'd3071: toneL = `g1;

                12'd3072: toneL = `a1; 12'd3073: toneL = `a1;
                12'd3074: toneL = `a1; 12'd3075: toneL = `a1;
                12'd3076: toneL = `a1; 12'd3077: toneL = `a1;
                12'd3078: toneL = `a1; 12'd3079: toneL = `a1;
                12'd3080: toneL = `a1; 12'd3081: toneL = `a1;
                12'd3082: toneL = `a1; 12'd3083: toneL = `a1;
                12'd3084: toneL = `a1; 12'd3085: toneL = `a1;
                12'd3086: toneL = `a1; 12'd3087: toneL = `a1;

                12'd3088: toneL = `b1; 12'd3089: toneL = `b1;
                12'd3090: toneL = `b1; 12'd3091: toneL = `b1;
                12'd3092: toneL = `b1; 12'd3093: toneL = `b1;
                12'd3094: toneL = `b1; 12'd3095: toneL = `b1;
                12'd3096: toneL = `b1; 12'd3097: toneL = `b1;
                12'd3098: toneL = `b1; 12'd3099: toneL = `b1;
                12'd3100: toneL = `b1; 12'd3101: toneL = `b1;
                12'd3102: toneL = `b1; 12'd3103: toneL = `b1;

                12'd3104: toneL = `a1; 12'd3105: toneL = `a1;
                12'd3106: toneL = `a1; 12'd3107: toneL = `a1;
                12'd3108: toneL = `a1; 12'd3109: toneL = `a1;
                12'd3110: toneL = `a1; 12'd3111: toneL = `a1;
                12'd3112: toneL = `a1; 12'd3113: toneL = `a1;
                12'd3114: toneL = `a1; 12'd3115: toneL = `a1;
                12'd3116: toneL = `a1; 12'd3117: toneL = `a1;
                12'd3118: toneL = `a1; 12'd3119: toneL = `a1;

                12'd3120: toneL = `g1; 12'd3121: toneL = `g1;
                12'd3122: toneL = `g1; 12'd3123: toneL = `g1;
                12'd3124: toneL = `g1; 12'd3125: toneL = `g1;
                12'd3126: toneL = `g1; 12'd3127: toneL = `g1;
                12'd3128: toneL = `g1; 12'd3129: toneL = `g1;
                12'd3130: toneL = `g1; 12'd3131: toneL = `g1;
                12'd3132: toneL = `g1; 12'd3133: toneL = `g1;
                12'd3134: toneL = `g1; 12'd3135: toneL = `g1;

                12'd3136: toneL = `a1; 12'd3137: toneL = `a1;
                12'd3138: toneL = `a1; 12'd3139: toneL = `a1;
                12'd3140: toneL = `a1; 12'd3141: toneL = `a1;
                12'd3142: toneL = `a1; 12'd3143: toneL = `a1;
                12'd3144: toneL = `a1; 12'd3145: toneL = `a1;
                12'd3146: toneL = `a1; 12'd3147: toneL = `a1;
                12'd3148: toneL = `a1; 12'd3149: toneL = `a1;
                12'd3150: toneL = `a1; 12'd3151: toneL = `a1;

                12'd3152: toneL = `sil; 12'd3153: toneL = `sil;
                12'd3154: toneL = `sil; 12'd3155: toneL = `sil;
                12'd3156: toneL = `sil; 12'd3157: toneL = `sil;
                12'd3158: toneL = `sil; 12'd3159: toneL = `sil;
                12'd3160: toneL = `sil; 12'd3161: toneL = `sil;
                12'd3162: toneL = `sil; 12'd3163: toneL = `sil;
                12'd3164: toneL = `sil; 12'd3165: toneL = `sil;
                12'd3166: toneL = `sil; 12'd3167: toneL = `sil;

                12'd3168: toneL = `a1; 12'd3169: toneL = `a1;
                12'd3170: toneL = `a1; 12'd3171: toneL = `a1;
                12'd3172: toneL = `a1; 12'd3173: toneL = `a1;
                12'd3174: toneL = `a1; 12'd3175: toneL = `a1;
                12'd3176: toneL = `a1; 12'd3177: toneL = `a1;
                12'd3178: toneL = `a1; 12'd3179: toneL = `a1;
                12'd3180: toneL = `a1; 12'd3181: toneL = `a1;
                12'd3182: toneL = `a1; 12'd3183: toneL = `a1;

                12'd3184: toneL = `b1; 12'd3185: toneL = `b1;
                12'd3186: toneL = `b1; 12'd3187: toneL = `b1;
                12'd3188: toneL = `b1; 12'd3189: toneL = `b1;
                12'd3190: toneL = `b1; 12'd3191: toneL = `b1;
                12'd3192: toneL = `b1; 12'd3193: toneL = `b1;
                12'd3194: toneL = `b1; 12'd3195: toneL = `b1;
                12'd3196: toneL = `b1; 12'd3197: toneL = `b1;
                12'd3198: toneL = `b1; 12'd3199: toneL = `b1;

                12'd3200: toneL = `a1; 12'd3201: toneL = `a1;
                12'd3202: toneL = `a1; 12'd3203: toneL = `a1;
                12'd3204: toneL = `a1; 12'd3205: toneL = `a1;
                12'd3206: toneL = `a1; 12'd3207: toneL = `a1;
                12'd3208: toneL = `a1; 12'd3209: toneL = `a1;
                12'd3210: toneL = `a1; 12'd3211: toneL = `a1;
                12'd3212: toneL = `a1; 12'd3213: toneL = `a1;
                12'd3214: toneL = `a1; 12'd3215: toneL = `a1;

                12'd3216: toneL = `g1; 12'd3217: toneL = `g1;
                12'd3218: toneL = `g1; 12'd3219: toneL = `g1;
                12'd3220: toneL = `g1; 12'd3221: toneL = `g1;
                12'd3222: toneL = `g1; 12'd3223: toneL = `g1;
                12'd3224: toneL = `g1; 12'd3225: toneL = `g1;
                12'd3226: toneL = `g1; 12'd3227: toneL = `g1;
                12'd3228: toneL = `g1; 12'd3229: toneL = `g1;
                12'd3230: toneL = `g1; 12'd3231: toneL = `g1;

                12'd3232: toneL = `a1; 12'd3233: toneL = `a1;
                12'd3234: toneL = `a1; 12'd3235: toneL = `a1;
                12'd3236: toneL = `a1; 12'd3237: toneL = `a1;
                12'd3238: toneL = `a1; 12'd3239: toneL = `a1;
                12'd3240: toneL = `a1; 12'd3241: toneL = `a1;
                12'd3242: toneL = `a1; 12'd3243: toneL = `a1;
                12'd3244: toneL = `a1; 12'd3245: toneL = `a1;
                12'd3246: toneL = `a1; 12'd3247: toneL = `a1;

                12'd3248: toneL = `g1; 12'd3249: toneL = `g1;
                12'd3250: toneL = `g1; 12'd3251: toneL = `g1;
                12'd3252: toneL = `g1; 12'd3253: toneL = `g1;
                12'd3254: toneL = `g1; 12'd3255: toneL = `g1;
                12'd3256: toneL = `g1; 12'd3257: toneL = `g1;
                12'd3258: toneL = `g1; 12'd3259: toneL = `g1;
                12'd3260: toneL = `g1; 12'd3261: toneL = `g1;
                12'd3262: toneL = `g1; 12'd3263: toneL = `g1;

                12'd3264: toneL = `a1; 12'd3265: toneL = `a1;
                12'd3266: toneL = `a1; 12'd3267: toneL = `a1;
                12'd3268: toneL = `a1; 12'd3269: toneL = `a1;
                12'd3270: toneL = `a1; 12'd3271: toneL = `a1;
                12'd3272: toneL = `a1; 12'd3273: toneL = `a1;
                12'd3274: toneL = `a1; 12'd3275: toneL = `a1;
                12'd3276: toneL = `a1; 12'd3277: toneL = `a1;
                12'd3278: toneL = `a1; 12'd3279: toneL = `a1;

                12'd3280: toneL = `f1B; 12'd3281: toneL = `f1B;
                12'd3282: toneL = `f1B; 12'd3283: toneL = `f1B;
                12'd3284: toneL = `f1B; 12'd3285: toneL = `f1B;
                12'd3286: toneL = `f1B; 12'd3287: toneL = `f1B;
                12'd3288: toneL = `f1B; 12'd3289: toneL = `f1B;
                12'd3290: toneL = `f1B; 12'd3291: toneL = `f1B;
                12'd3292: toneL = `f1B; 12'd3293: toneL = `f1B;
                12'd3294: toneL = `f1B; 12'd3295: toneL = `f1B;

                12'd3296: toneL = `g1; 12'd3297: toneL = `g1;
                12'd3298: toneL = `g1; 12'd3299: toneL = `g1;
                12'd3300: toneL = `g1; 12'd3301: toneL = `g1;
                12'd3302: toneL = `g1; 12'd3303: toneL = `g1;
                12'd3304: toneL = `g1; 12'd3305: toneL = `g1;
                12'd3306: toneL = `g1; 12'd3307: toneL = `g1;
                12'd3308: toneL = `g1; 12'd3309: toneL = `g1;
                12'd3310: toneL = `g1; 12'd3311: toneL = `g1;

                12'd3312: toneL = `f1B; 12'd3313: toneL = `f1B;
                12'd3314: toneL = `f1B; 12'd3315: toneL = `f1B;
                12'd3316: toneL = `f1B; 12'd3317: toneL = `f1B;
                12'd3318: toneL = `f1B; 12'd3319: toneL = `f1B;
                12'd3320: toneL = `f1B; 12'd3321: toneL = `f1B;
                12'd3322: toneL = `f1B; 12'd3323: toneL = `f1B;
                12'd3324: toneL = `f1B; 12'd3325: toneL = `f1B;
                12'd3326: toneL = `f1B; 12'd3327: toneL = `f1B;

                12'd3328: toneL = `b1; 12'd3329: toneL = `b1;
                12'd3330: toneL = `b1; 12'd3331: toneL = `b1;
                12'd3332: toneL = `b1; 12'd3333: toneL = `b1;
                12'd3334: toneL = `b1; 12'd3335: toneL = `b1;
                12'd3336: toneL = `b1; 12'd3337: toneL = `b1;
                12'd3338: toneL = `b1; 12'd3339: toneL = `b1;
                12'd3340: toneL = `b1; 12'd3341: toneL = `b1;
                12'd3342: toneL = `b1; 12'd3343: toneL = `b1;
                12'd3344: toneL = `b1; 12'd3345: toneL = `b1;
                12'd3346: toneL = `b1; 12'd3347: toneL = `b1;
                12'd3348: toneL = `b1; 12'd3349: toneL = `b1;
                12'd3350: toneL = `b1; 12'd3351: toneL = `b1;
                12'd3352: toneL = `b1; 12'd3353: toneL = `b1;
                12'd3354: toneL = `b1; 12'd3355: toneL = `b1;
                12'd3356: toneL = `b1; 12'd3357: toneL = `b1;
                12'd3358: toneL = `b1; 12'd3359: toneL = `b1;
                12'd3360: toneL = `b1; 12'd3361: toneL = `b1;
                12'd3362: toneL = `b1; 12'd3363: toneL = `b1;
                12'd3364: toneL = `b1; 12'd3365: toneL = `b1;
                12'd3366: toneL = `b1; 12'd3367: toneL = `b1;
                12'd3368: toneL = `b1; 12'd3369: toneL = `b1;
                12'd3370: toneL = `b1; 12'd3371: toneL = `b1;
                12'd3372: toneL = `b1; 12'd3373: toneL = `b1;
                12'd3374: toneL = `b1; 12'd3375: toneL = `b1;
                12'd3376: toneL = `b1; 12'd3377: toneL = `b1;
                12'd3378: toneL = `b1; 12'd3379: toneL = `b1;
                12'd3380: toneL = `b1; 12'd3381: toneL = `b1;
                12'd3382: toneL = `b1; 12'd3383: toneL = `b1;
                12'd3384: toneL = `b1; 12'd3385: toneL = `b1;
                12'd3386: toneL = `b1; 12'd3387: toneL = `b1;
                12'd3388: toneL = `b1; 12'd3389: toneL = `b1;
                12'd3390: toneL = `b1; 12'd3391: toneL = `b1;
                12'd3392: toneL = `b1; 12'd3393: toneL = `b1;
                12'd3394: toneL = `b1; 12'd3395: toneL = `b1;
                12'd3396: toneL = `b1; 12'd3397: toneL = `b1;
                12'd3398: toneL = `b1; 12'd3399: toneL = `b1;
                12'd3400: toneL = `b1; 12'd3401: toneL = `b1;
                12'd3402: toneL = `b1; 12'd3403: toneL = `b1;
                12'd3404: toneL = `b1; 12'd3405: toneL = `b1;
                12'd3406: toneL = `b1; 12'd3407: toneL = `b1;
                12'd3408: toneL = `b1; 12'd3409: toneL = `b1;
                12'd3410: toneL = `b1; 12'd3411: toneL = `b1;
                12'd3412: toneL = `b1; 12'd3413: toneL = `b1;
                12'd3414: toneL = `b1; 12'd3415: toneL = `b1;
                12'd3416: toneL = `b1; 12'd3417: toneL = `b1;
                12'd3418: toneL = `b1; 12'd3419: toneL = `b1;
                12'd3420: toneL = `b1; 12'd3421: toneL = `b1;
                12'd3422: toneL = `b1; 12'd3423: toneL = `b1;
                12'd3424: toneL = `b1; 12'd3425: toneL = `b1;
                12'd3426: toneL = `b1; 12'd3427: toneL = `b1;
                12'd3428: toneL = `b1; 12'd3429: toneL = `b1;
                12'd3430: toneL = `b1; 12'd3431: toneL = `b1;
                12'd3432: toneL = `b1; 12'd3433: toneL = `b1;
                12'd3434: toneL = `b1; 12'd3435: toneL = `b1;
                12'd3436: toneL = `b1; 12'd3437: toneL = `b1;
                12'd3438: toneL = `b1; 12'd3439: toneL = `b1;
                12'd3440: toneL = `b1; 12'd3441: toneL = `b1;
                12'd3442: toneL = `b1; 12'd3443: toneL = `b1;
                12'd3444: toneL = `b1; 12'd3445: toneL = `b1;
                12'd3446: toneL = `b1; 12'd3447: toneL = `b1;
                12'd3448: toneL = `b1; 12'd3449: toneL = `b1;
                12'd3450: toneL = `b1; 12'd3451: toneL = `b1;
                12'd3452: toneL = `b1; 12'd3453: toneL = `b1;
                12'd3454: toneL = `b1; 12'd3455: toneL = `b1;
                12'd3456: toneL = `b1; 12'd3457: toneL = `b1;
                12'd3458: toneL = `b1; 12'd3459: toneL = `b1;
                12'd3460: toneL = `b1; 12'd3461: toneL = `b1;
                12'd3462: toneL = `b1; 12'd3463: toneL = `b1;
                12'd3464: toneL = `b1; 12'd3465: toneL = `b1;
                12'd3466: toneL = `b1; 12'd3467: toneL = `b1;
                12'd3468: toneL = `b1; 12'd3469: toneL = `b1;
                12'd3470: toneL = `b1; 12'd3471: toneL = `b1;
                12'd3472: toneL = `b1; 12'd3473: toneL = `b1;
                12'd3474: toneL = `b1; 12'd3475: toneL = `b1;
                12'd3476: toneL = `b1; 12'd3477: toneL = `b1;
                12'd3478: toneL = `b1; 12'd3479: toneL = `b1;
                12'd3480: toneL = `b1; 12'd3481: toneL = `b1;
                12'd3482: toneL = `b1; 12'd3483: toneL = `b1;
                12'd3484: toneL = `b1; 12'd3485: toneL = `b1;
                12'd3486: toneL = `b1; 12'd3487: toneL = `b1;
                12'd3488: toneL = `b1; 12'd3489: toneL = `b1;
                12'd3490: toneL = `b1; 12'd3491: toneL = `b1;
                12'd3492: toneL = `b1; 12'd3493: toneL = `b1;
                12'd3494: toneL = `b1; 12'd3495: toneL = `b1;
                12'd3496: toneL = `b1; 12'd3497: toneL = `b1;
                12'd3498: toneL = `b1; 12'd3499: toneL = `b1;
                12'd3500: toneL = `b1; 12'd3501: toneL = `b1;
                12'd3502: toneL = `b1; 12'd3503: toneL = `b1;
                12'd3504: toneL = `b1; 12'd3505: toneL = `b1;
                12'd3506: toneL = `b1; 12'd3507: toneL = `b1;
                12'd3508: toneL = `b1; 12'd3509: toneL = `b1;
                12'd3510: toneL = `b1; 12'd3511: toneL = `b1;
                12'd3512: toneL = `b1; 12'd3513: toneL = `b1;
                12'd3514: toneL = `b1; 12'd3515: toneL = `b1;
                12'd3516: toneL = `b1; 12'd3517: toneL = `b1;
                12'd3518: toneL = `b1; 12'd3519: toneL = `b1;
                12'd3520: toneL = `b1; 12'd3521: toneL = `b1;
                12'd3522: toneL = `b1; 12'd3523: toneL = `b1;
                12'd3524: toneL = `b1; 12'd3525: toneL = `b1;
                12'd3526: toneL = `b1; 12'd3527: toneL = `b1;
                12'd3528: toneL = `b1; 12'd3529: toneL = `b1;
                12'd3530: toneL = `b1; 12'd3531: toneL = `b1;
                12'd3532: toneL = `b1; 12'd3533: toneL = `b1;
                12'd3534: toneL = `b1; 12'd3535: toneL = `b1;
                12'd3536: toneL = `b1; 12'd3537: toneL = `b1;
                12'd3538: toneL = `b1; 12'd3539: toneL = `b1;
                12'd3540: toneL = `b1; 12'd3541: toneL = `b1;
                12'd3542: toneL = `b1; 12'd3543: toneL = `b1;
                12'd3544: toneL = `b1; 12'd3545: toneL = `b1;
                12'd3546: toneL = `b1; 12'd3547: toneL = `b1;
                12'd3548: toneL = `b1; 12'd3549: toneL = `b1;
                12'd3550: toneL = `b1; 12'd3551: toneL = `b1;
                12'd3552: toneL = `b1; 12'd3553: toneL = `b1;
                12'd3554: toneL = `b1; 12'd3555: toneL = `b1;
                12'd3556: toneL = `b1; 12'd3557: toneL = `b1;
                12'd3558: toneL = `b1; 12'd3559: toneL = `b1;
                12'd3560: toneL = `b1; 12'd3561: toneL = `b1;
                12'd3562: toneL = `b1; 12'd3563: toneL = `b1;
                12'd3564: toneL = `b1; 12'd3565: toneL = `b1;
                12'd3566: toneL = `b1; 12'd3567: toneL = `b1;
                12'd3568: toneL = `b1; 12'd3569: toneL = `b1;
                12'd3570: toneL = `b1; 12'd3571: toneL = `b1;
                12'd3572: toneL = `b1; 12'd3573: toneL = `b1;
                12'd3574: toneL = `b1; 12'd3575: toneL = `b1;
                12'd3576: toneL = `b1; 12'd3577: toneL = `b1;
                12'd3578: toneL = `b1; 12'd3579: toneL = `b1;
                12'd3580: toneL = `b1; 12'd3581: toneL = `b1;
                12'd3582: toneL = `b1; 12'd3583: toneL = `b1;

                default : toneL = `sil;
            endcase
    end
endmodule
