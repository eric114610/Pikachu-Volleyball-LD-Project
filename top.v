

module top (
    input clk,
    input rst,
    inout wire PS2_DATA,
    inout wire PS2_CLK,
    input _volUP,
    input _volDOWN,
    input _higherOCT,
    input _lowerOCT,
    input [15:0] sw,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output hsync,
    output vsync,
    output audio_mclk, 
    output audio_lrck, 
    output audio_sck, 
    output audio_sdin,
    output reg [15:0] LED
);

    wire signed [10:0] chara_a_x;
    wire signed [10:0] chara_a_y;
    wire signed [10:0] chara_b_x;
    wire signed [10:0] chara_b_y;
    wire signed [10:0] ball_x;
    wire signed [10:0] ball_y;
    wire [1:0] touch_ground;

    parameter INIT = 0;
    parameter GAME = 1;
    parameter P1_WIN = 2;
    parameter P2_WIN = 3;
    parameter FINISH = 4;
    parameter LOADING = 5;
    parameter CHOOSE = 6;

    reg [3:0] state;
    reg [3:0] next_state;

    //
    reg [2:0] chara_a;
    reg [2:0] next_chara_a;
    reg [2:0] chara_b;
    reg [2:0] next_chara_b;

    //0~15
    reg [3:0] P1_point;
    reg [3:0] P2_point;
    reg [3:0] next_P1_point;
    reg [3:0] next_P2_point;

    reg winner=1;
    reg next_winner;

    integer i;

    wire clk22;
    wire clk25M;
    clock_divider clock_div(.clk(clk), .clk1(clk25M), .clk22(clk22));
    
    reg [21:0] fps_count;
    wire fps30 = (fps_count == 3333330);
    wire [21:0] next_fps_count = fps_count+1;
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            fps_count <= 0;
        end
        else begin
            if(fps_count == 3333330) begin
                fps_count <= 0;
            end
            else begin
                fps_count <= next_fps_count;
            end
        end
    end

    wire [511:0] key_down;
	wire [8:0] last_change;
	wire been_ready;
    KeyboardDecoder key_de (
		.key_down(key_down),
		.last_change(last_change),
		.key_valid(been_ready),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);
    //modify
    reg [3:0] key_num;
    parameter [8:0] KEY_CODES [0:9] = {
		9'b0_0001_1101,	// W => 1D
		9'b0_0001_1100,	// A => 1C
		9'b0_0001_1011,	// S => 1B
		9'b0_0010_0011,	// D => 23
		9'b0_0101_1010,	// Enter => 5A
        9'b0_0111_0101, // 上 => E075
        9'b0_0110_1011, // 左 => E06B
        9'b1_0111_0010, // 下 => E072
        9'b1_0111_0100, // 右 => E074
        9'b0_0001_1010  // Z => 1A
	};
    //modify
    always @ (*) begin
		case (last_change)
			KEY_CODES[00] : key_num = 0;
			KEY_CODES[01] : key_num = 1;
			KEY_CODES[02] : key_num = 2;
			KEY_CODES[03] : key_num = 3;
			KEY_CODES[04] : key_num = 4;
            default: key_num = 6;
		endcase
	end


    wire [9:0] h_cnt;
    wire [9:0] v_cnt;
    wire valid;
    vga_controller vga1(.pclk(clk25M), .reset(rst), .hsync(hsync), .vsync(vsync),
    .valid(valid), .h_cnt(h_cnt), .v_cnt(v_cnt)
    );

    //modify
    reg chara_pic;
    
    wire [16:0] pixel_addr;
    wire [16:0] pixel_addr2;
    wire isball;
    wire ischara_a;
    wire ischara_b;
    wire ispoll;
    mem_addr_gen mem1(.clk(clk25M), .rst(rst), .h_cnt(h_cnt), .v_cnt(v_cnt), 
    .chara_a(chara_a), .chara_b(chara_b), .chara_a_x(chara_a_x), .chara_a_y(chara_a_y),
    .chara_b_x(chara_b_x), .chara_b_y(chara_b_y), .ball_x(ball_x), 
    .ball_y(ball_y), .chara_pic(chara_pic), .P1_point(P1_point), .P2_point(P2_point),
    .state(state), .load_clk(load_clk),
    .pixel_addr(pixel_addr), .pixel_addr2(pixel_addr2), .isball(isball), 
    .ischara_a(ischara_a), .ischara_b(ischara_b), .ispoll(ispoll)
    );

    wire [11:0] data;
    wire [11:0] pixel;
    wire [11:0] data2;
    wire [11:0] pixel2;
    blk_mem_gen_0 blk_mem_gen_0_inst(
      .clka(clk25M),
      .wea(0),
      .addra(pixel_addr),
      .dina(data[11:0]),
      .douta(pixel),
      .clkb(clk25M),
      .web(0),
      .addrb(pixel_addr2),
      .dinb(data2[11:0]),
      .doutb(pixel2)
    ); 

    
    wire isback = (pixel == 12'hFAC || pixel == 12'hFAD || pixel == 12'hFAE || pixel == 12'hFAB  || pixel == 12'hFBC || pixel == 12'hFBD || pixel == 12'hFBE );

    assign {vgaRed,vgaGreen,vgaBlue} = (valid==1) ? (isback ? pixel2 : pixel) : 12'h0;



    // music modules

    wire volUP_de;
    wire volDOWN_de;
    wire higherOCT_de;
    wire lowerOCT_de;
    wire volUP_1;
    wire volDOWN_1;
    wire higherOCT_1;
    wire lowerOCT_1;

    debounce de1(.clk(clk), .pb(_volUP), .pb_debounced(volUP_de));
    OnePulse on1(.signal(volUP_de), .clock(clk), .signal_single_pulse(volUP_1));
    debounce de2(.clk(clk), .pb(_volDOWN), .pb_debounced(volDOWN_de));
    OnePulse on2(.signal(volDOWN_de), .clock(clk), .signal_single_pulse(volDOWN_1));
    debounce de3(.clk(clk), .pb(_higherOCT), .pb_debounced(higherOCT_de));
    OnePulse on3(.signal(higherOCT_de), .clock(clk), .signal_single_pulse(higherOCT_1));
    debounce de4(.clk(clk), .pb(_lowerOCT), .pb_debounced(lowerOCT_de));
    OnePulse on4(.signal(lowerOCT_de), .clock(clk), .signal_single_pulse(lowerOCT_1));


    wire [15:0] audio_in_left, audio_in_right;
    wire [11:0] ibeatNum;               // Beat counter
    wire [31:0] freqL, freqR;           // Raw frequency, produced by music module
    wire [21:0] freq_outL, freq_outR;

    wire clkDiv20;
    clock_divi #(.n(20)) clock_22(.clk(clk), .clk_div(clkDiv20));


    reg [2:0] volume;
    reg [2:0] next_volume;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            volume <= 3;
        end
        else begin
            volume <= next_volume;
        end
    end

    always @(*) begin
        if(volDOWN_1) begin
            if(volume!=1) begin
                next_volume = volume-1;
            end
            else begin
                next_volume = volume;
            end
        end
        else if(volUP_1) begin
            if(volume!=5) begin
                next_volume = volume+1;
            end
            else begin
                next_volume = volume;
            end
        end
        else begin
            next_volume = volume;
        end
    end


    //modify
    player_control  playerCtrl_00 ( 
        .clk(clkDiv20),
        .reset(rst),
        .state(state),
        .ibeat(ibeatNum)
    );
    //modify
    music_example music_00 (
        .ibeatNum(ibeatNum),
        .toneL(freqL),
        .toneR(freqR)
    );

    assign freq_outL = 50000000 / freqL;
    assign freq_outR = 50000000 / freqR;

    //modify
    note_gen noteGen_00(
        .clk(clk), 
        .rst(rst), 
        .volume(volume),
        .note_div_left(freq_outL), 
        .note_div_right(freq_outR), 
        .audio_left(audio_in_left),     // left sound audio
        .audio_right(audio_in_right)    // right sound audio
    );

    speaker_control sc(
        .clk(clk), 
        .rst(rst), 
        .audio_in_left(audio_in_left),      // left channel audio data input
        .audio_in_right(audio_in_right),    // right channel audio data input
        .audio_mclk(audio_mclk),            // master clock
        .audio_lrck(audio_lrck),            // left-right clock
        .audio_sck(audio_sck),              // serial clock
        .audio_sdin(audio_sdin)             // serial audio data input
    );


    wire [3:0] bar_a;
    wire [3:0] bar_b;

    physic phy1(.clk(clk), .fps30(fps30), .rst(rst), .state(state), .winner(winner),
    .chara_a(chara_a), .chara_b(chara_b),
    .key_down(key_down), .last_change(last_change),//.last_change(last_pressed), 
    .been_ready(been_ready), .chara_a_x(chara_a_x), .chara_a_y(chara_a_y),
    .chara_b_x(chara_b_x), .chara_b_y(chara_b_y),
    .ball_x(ball_x), .ball_y(ball_y), .touch_ground(touch_ground),
    .bar_a(bar_a), .bar_b(bar_b)
    );
    


    reg [7:0] animation_clk;
    reg [7:0] load_clk;
    wire [7:0] next_animation_clk = animation_clk+1;
    wire [7:0] next_load_clk = load_clk+1;

    always @(posedge fps30, posedge rst) begin
        if(rst) begin
            animation_clk <= 0;
            load_clk <= 0;
        end
        else begin
            if(state == LOADING) begin
                animation_clk <= 0;
                if(load_clk == 90) begin
                    load_clk <= 0;
                end
                else begin
                    load_clk <= next_load_clk;
                end
            end
            else if(state == P1_WIN || state == P2_WIN) begin
                load_clk <= 0;
                if(animation_clk == 90) begin
                    animation_clk <= 0;
                end
                else begin
                    animation_clk <= next_animation_clk;
                end
            end
            else begin
                load_clk <= 0;
                animation_clk <= 0;
            end
        end
    end


    reg [5:0] a_counter;
    wire [5:0] next_a_counter;
    wire a_valid = (a_counter == 14);

    always @(posedge fps30, posedge rst) begin
        if(rst) begin
            a_counter <= 0;
        end
        else begin
            if(state == GAME) begin
                if(a_counter==14)
                    a_counter <= 0;
                else
                    a_counter <= next_a_counter;
            end
            else begin
                a_counter <= 0;
            end
        end
    end
    assign next_a_counter = a_counter+1;


    reg a_clk;

    always @(*) begin
        if(state == GAME)
            a_clk <= a_valid;
        else
            a_clk <= 0;
    end

    always @(posedge a_clk, posedge rst) begin
        if(rst)
            chara_pic <= 0;
        else
            chara_pic <= ~chara_pic;
    end


    always @(posedge clk, posedge rst) begin
        if(rst) begin
            state <= INIT;
        end
        else begin
           state <= next_state; 
        end
    end

    always @(*) begin
        case (state)
            INIT: begin
                if(been_ready && key_down[last_change] == 1 && key_num == 4) begin
                    next_state = CHOOSE;
                end
                else begin
                    next_state = state;
                end
            end 
            GAME: begin
                if(touch_ground == 1) begin
                    next_state = P2_WIN;
                end
                else if(touch_ground == 2) begin
                    next_state = P1_WIN;
                end
                else begin
                    next_state = state;
                end
            end
            P1_WIN: begin
                if(animation_clk == 90) begin
                    if(P1_point >= 5) begin
                        next_state = FINISH;
                    end
                    else begin
                        next_state = CHOOSE;
                    end
                end
                else begin
                    next_state = state;
                end
            end
            P2_WIN: begin
                if(animation_clk == 90) begin
                    if(P2_point >= 5) begin
                        next_state = FINISH;
                    end
                    else begin
                        next_state = CHOOSE;
                    end
                end
                else begin
                    next_state = state;
                end
            end
            FINISH: begin
                if(been_ready && key_down[last_change] == 1 && key_num == 4) begin
                    next_state = INIT;
                end
                else begin
                    next_state = state;
                end
            end
            LOADING: begin
                if(load_clk == 90) begin
                    next_state = GAME;
                end
                else begin
                    next_state = state;
                end
            end
            CHOOSE: begin
                if(been_ready && key_down[last_change] == 1 && key_num == 4) begin
                    next_state = LOADING;
                end
                else begin
                    next_state = state;
                end
            end
            default: begin
                next_state = state;
            end
        endcase
    end


    always @(posedge clk, posedge rst) begin
        if(rst) begin
            P1_point <= 0;
            P2_point <= 0;
            winner <= 1;
        end
        else begin
            P1_point <= next_P1_point;
            P2_point <= next_P2_point;
            winner <= next_winner;
        end
    end

    always @(*) begin
        case (state)
            GAME: begin
                if(touch_ground == 1) begin
                    next_P1_point = P1_point;
                    next_P2_point = P2_point+1;
                    next_winner = 0;
                end
                else if(touch_ground == 2) begin
                    next_P1_point = P1_point+1;
                    next_P2_point = P2_point;
                    next_winner = 1;
                end
                else begin
                    next_P1_point = P1_point;
                    next_P2_point = P2_point;
                    next_winner = winner;
                end
            end
            INIT: begin
                next_P1_point = 0;
                next_P2_point = 0;
                next_winner = 1;
            end
            default: begin
                next_P1_point = P1_point;
                next_P2_point = P2_point;
                next_winner = winner;
            end
        endcase
    end


    always @(posedge fps30, posedge rst) begin
        if(rst) begin
            chara_a <= 0;
            chara_b <= 0;
        end
        else begin
            chara_a <= next_chara_a;
            chara_b <= next_chara_b;
        end
    end

    always @(*) begin
        case (state)
            CHOOSE: begin
                if(sw[15] == 1) 
                    next_chara_a = 0;
                else if(sw[14] == 1)
                    next_chara_a = 1;
                else if(sw[13] == 1)
                    next_chara_a = 2;
                else if(sw[12] == 1)
                    next_chara_a = 3;
                else if(sw[11] == 1)
                    next_chara_a = 4;
                else
                    next_chara_a = chara_a;

                if(sw[0] == 1) 
                    next_chara_b = 0;
                else if(sw[1] == 1)
                    next_chara_b = 1;
                else if(sw[2] == 1)
                    next_chara_b = 2;
                else if(sw[3] == 1)
                    next_chara_b = 3;
                else if(sw[4] == 1)
                    next_chara_b = 4;
                else
                    next_chara_b = chara_b;
            end
            INIT: begin
                next_chara_a = 0;
                next_chara_b = 0;
            end
            default: begin
                next_chara_a = chara_a;
                next_chara_b = chara_b;
            end
        endcase
    end



    always @(*) begin
        for(i=0; i<16; i=i+1) begin
            LED[i] <= 0;
        end
        
    
        for(i=0; i<7; i=i+1) begin
            if(bar_b>i) LED[i] <= 1;
            else LED[i] <= 0;
        end

        if(bar_a>0) LED[15] <= 1;
        if(bar_a>1) LED[14] <= 1;
        if(bar_a>2) LED[13] <= 1;
        if(bar_a>3) LED[12] <= 1;
        if(bar_a>4) LED[11] <= 1;
        if(bar_a>5) LED[10] <= 1;
        if(bar_a>6) LED[9] <= 1;
    end



endmodule