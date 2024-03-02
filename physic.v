/*
處理所有物理運算
輸出角色及球的位置
30fps
球邊界 up:40 down:400 left:38 right:602-10
角色邊界 up:50 down:390 left:45 right:595
vx單位 per frame
vy單位 /10 per frame
*/

module physic (
    input clk,
    input fps30,
    input rst,
    input [3:0] state,
    input winner,
    input [2:0] chara_a,
    input [2:0] chara_b,
    input wire [511:0] key_down,
	input wire [8:0] last_change,
	input wire been_ready,
    output reg [10:0] chara_a_x,
    output reg [10:0] chara_a_y,
    output reg [10:0] chara_b_x,
    output reg [10:0] chara_b_y,
    output reg [10:0] ball_x,
    output reg [10:0] ball_y,
    output reg [1:0] touch_ground,
    output [3:0] bar_a,
    output [3:0] bar_b
);

    parameter INIT = 0;
    parameter GAME = 1;
    parameter P1_WIN = 2;
    parameter P2_WIN = 3;
    parameter FINISH = 4;
    parameter LOADING = 5;
    parameter CHOOSE = 6;

    reg en_clk;
    always @(*) begin
        if(state == GAME)
            en_clk = clk;
        else
            en_clk = 0;
    end

    reg signed [9:0] chara_a_v_x;
    reg signed [9:0] chara_a_v_y;
    reg signed [9:0] chara_b_v_x;
    reg signed [9:0] chara_b_v_y;

    reg signed [9:0] next_chara_a_v_x;
    reg signed [9:0] next_chara_a_v_y;
    reg signed [9:0] next_chara_b_v_x;
    reg signed [9:0] next_chara_b_v_y;

    reg signed [10:0] chara_a_pos_x;
    reg signed [10:0] chara_a_pos_y;
    reg signed [10:0] chara_b_pos_x;
    reg signed [10:0] chara_b_pos_y;

    reg signed [10:0] next_chara_a_pos_x;
    reg signed [10:0] next_chara_a_pos_y;
    reg signed [10:0] next_chara_b_pos_x;
    reg signed [10:0] next_chara_b_pos_y;

    reg signed [10:0] chara_a_weight;
    reg signed [10:0] chara_b_weight;

    reg signed [10:0] ball_pos_x;
    reg signed [10:0] ball_pos_y;
    reg signed [10:0] next_ball_pos_x;
    reg signed [10:0] next_ball_pos_y;

    reg signed [9:0] ball_v_x;
    reg signed [9:0] ball_v_y;
    reg signed [9:0] next_ball_v_x;
    reg signed [9:0] next_ball_v_y;

    reg signed [10:0] col_chara_a_pos_x;
    reg signed [10:0] col_chara_b_pos_x;

    always @(*) begin
        case (chara_a)
            0: col_chara_a_pos_x = chara_a_pos_x+20;
            1: col_chara_a_pos_x = chara_a_pos_x+10;
            2: col_chara_a_pos_x = chara_a_pos_x;
            3: col_chara_a_pos_x = chara_a_pos_x+20;
            4: col_chara_a_pos_x = chara_a_pos_x;
            default: col_chara_a_pos_x = chara_a_pos_x+20;
        endcase

        case (chara_b)
            0: col_chara_b_pos_x = chara_b_pos_x-20;
            1: col_chara_b_pos_x = chara_b_pos_x-10;
            2: col_chara_b_pos_x = chara_b_pos_x;
            3: col_chara_b_pos_x = chara_b_pos_x-20;
            4: col_chara_b_pos_x = chara_b_pos_x;
            default: col_chara_b_pos_x = chara_b_pos_x-20;
        endcase

    end


    wire signed [9:0] new_ball_v_x1;
    wire signed [9:0] new_ball_v_y1;
    wire valid1;

    wire signed [9:0] new_ball_v_x2;
    wire signed [9:0] new_ball_v_y2;
    wire valid2;

    collide chara_aa(.chara_pos_x(col_chara_a_pos_x), .chara_pos_y(chara_a_pos_y), 
    .ball_pos_x(ball_pos_x), .ball_pos_y(ball_pos_y),
    .clk(clk), .rst(rst), //.en(1),
    .new_ball_v_x(new_ball_v_x1), .new_ball_v_y(new_ball_v_y1),
    .valid(valid1)
    );

    collide chara_bb(.chara_pos_x(col_chara_b_pos_x), .chara_pos_y(chara_b_pos_y), 
    .ball_pos_x(ball_pos_x), .ball_pos_y(ball_pos_y),
    .clk(clk), .rst(rst), //.en(1),
    .new_ball_v_x(new_ball_v_x2), .new_ball_v_y(new_ball_v_y2),
    .valid(valid2)
    );


    wire signed [9:0] new_ball_v_x3;
    wire signed [9:0] new_ball_v_y3;
    wire valid3;
    wire [1:0] net_case;

    border border1(.ball_pos_x(ball_pos_x), .ball_pos_y(ball_pos_y),
    .ball_v_x(ball_v_x), .ball_v_y(ball_v_y),
    .clk(clk), .rst(rst),
    .new_ball_v_x(new_ball_v_x3), .new_ball_v_y(new_ball_v_y3),
    .valid(valid3), .net_case(net_case)
    );


    wire inrange1;
    wire inrange2;

    inrange in1(.clk(clk), .rst(rst), .ball_pos_x(ball_pos_x), .ball_pos_y(ball_pos_y), 
    .chara_pos_x(chara_a_pos_x), .chara_pos_y(chara_a_pos_y), .inrange(inrange1)
    );

    inrange in2(.clk(clk), .rst(rst), .ball_pos_x(ball_pos_x), .ball_pos_y(ball_pos_y), 
    .chara_pos_x(chara_b_pos_x), .chara_pos_y(chara_b_pos_y), .inrange(inrange2)
    );

    wire signed [10:0] tele_ball_x;
    wire signed [10:0] tele_ball_y;
    reg skilled_a;
    reg skilled_b;

    teleport tele1(.clk(clk), .rst(rst), .ball_pos_x(ball_pos_x), .ball_pos_y(ball_pos_y),
    .state(state), .valid(tele_valid),
    .new_ball_x(tele_ball_x), .new_ball_y(tele_ball_y)
    );


    reg [3:0] bar_a;
    reg [3:0] bar_b;
    reg [3:0] next_bar_a;
    reg [3:0] next_bar_b;

    reg [9:0] bar_timer;
    wire [9:0] next_bar_timer;
    reg bar_add;
    reg pre_bar_add;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            bar_add <= 0;
            pre_bar_add <= 0;
        end
        else begin
            if(bar_timer == 60 && pre_bar_add == 0) begin
                bar_add <= 1;
                pre_bar_add <= 1;
            end
            else if(bar_timer == 60 && pre_bar_add == 1) begin
                bar_add <= 0;
                pre_bar_add <= 1;
            end
            else begin
                bar_add <= 0;
                pre_bar_add <= 0;
            end
        end
    end


    always @(posedge fps30, posedge rst) begin
        if(rst) begin
            bar_timer <= 0;
        end
        else begin
            if(state == GAME) begin
                if(bar_timer == 60) begin
                    bar_timer <= 0;
                end
                else begin
                    bar_timer <= next_bar_timer;
                end
            end
            else begin
                bar_timer <= 0;
            end
        end
    end
    assign next_bar_timer = bar_timer+1;


    always @(posedge fps30, posedge rst) begin
        if(rst) begin
            bar_a <= 0;
            bar_b <= 0;
        end
        else begin
            if(state == FINISH || state == INIT) begin
                bar_a <= 0;
                bar_b <= 0;
            end
            else if(skilled_a || skilled2_a) begin
                bar_a <= 0;
                bar_b <= bar_b;
            end
            else if(skilled_b || skilled2_b)begin
                bar_a <= bar_a;
                bar_b <= 0;
            end
            else begin
                if(pre_bar_add == 1) begin
                    if(bar_a == 7) begin
                        bar_a <= 7;
                    end
                    else begin
                        bar_a <= bar_a+1;
                    end
                end
                if(pre_bar_add == 1) begin
                    if(bar_b == 7) begin
                        bar_b <= 7;
                    end
                    else begin
                        bar_b <= bar_b+1;
                    end
                end
            end
        end
    end


    reg [8:0] skillb_a_timer;
    reg [8:0] skillb_b_timer;
    wire [8:0] next_skillb_a_timer = skillb_a_timer+1;
    wire [8:0] next_skillb_b_timer = skillb_b_timer+1;;
    reg inskill_a;
    reg inskill_b;
    reg skilled2_a;
    reg skilled2_b;


    always @(*) begin
        if(key_down[KEY_CODES[9]] == 1 && state == GAME && bar_a == 7 && ball_pos_x < 310 && chara_a == 3 && inskill_a == 0 && inskill_b == 0) begin
            skilled2_a = 1;
            skilled2_b = 0;
        end
        else if(key_down[KEY_CODES[4]] == 1 && state == GAME && bar_b == 7 && ball_pos_x > 310 && chara_b == 3 && inskill_a == 0 && inskill_b == 0) begin
            skilled2_a = 0;
            skilled2_b = 1;
        end
        else begin
            skilled2_a = 0;
            skilled2_b = 0;
        end
    end

    always @(posedge fps30, posedge rst) begin
        if(rst) begin
            skillb_a_timer <= 0;
            inskill_a <= 0;
        end
        else begin
            if(skilled2_a) begin
                skillb_a_timer <= 1;
                inskill_a <= 0;
            end
            else if(skillb_a_timer != 0) begin
                inskill_a <= 1;
                if(skillb_a_timer == 90) begin
                    skillb_a_timer <= 0;
                end
                else begin
                    skillb_a_timer <= next_skillb_a_timer;
                end
            end
            else begin
                skillb_a_timer <= 0;
                inskill_a <= 0;
            end
        end
    end


    always @(posedge fps30, posedge rst) begin
        if(rst) begin
            skillb_b_timer <= 0;
            inskill_b <= 0;
        end
        else begin
            if(skilled2_b) begin
                skillb_b_timer <= 1;
                inskill_b <= 0;
            end
            else if(skillb_b_timer != 0) begin
                inskill_b <= 1;
                if(skillb_b_timer == 90) begin
                    skillb_b_timer <= 0;
                end
                else begin
                    skillb_b_timer <= next_skillb_b_timer;
                end
            end
            else begin
                inskill_b <= 0;
                skillb_b_timer <= 0;
            end
        end
    end



    reg [3:0] key_num;
    parameter [8:0] KEY_CODES [0:9] = {
		9'b0_0001_1101,	// W => 1D
		9'b0_0001_1100,	// A => 1C
		9'b0_0001_1011,	// S => 1B
		9'b0_0010_0011,	// D => 23
		9'b0_0101_1010,	// Enter => 5A
        9'b0_0111_0101, // 上 => E075
        9'b0_0110_1011, // 左 => E06B
        9'b0_0111_0010, // 下 => E072
        9'b1_0111_0100, // 右 => E074
        9'b0_0001_1010  // Z => 1A
	};

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


    reg [5:0] a_counter;
    wire [5:0] next_a_counter;
    wire a_valid = (a_counter == 14);

    always @(posedge fps30, posedge rst) begin
        if(rst) begin
            a_counter <= 0;
        end
        else begin
            if(a_counter==14)
                a_counter <= 0;
            else
                a_counter <= next_a_counter;
        end
    end
    assign next_a_counter = a_counter+1;
    


    always @(posedge clk, posedge rst) begin
        if(rst) begin
            chara_a_weight <= 0;
            chara_b_weight <= 0;
        end
        else begin
            case (chara_a)
                0: chara_a_weight <= 0;
                1: chara_a_weight <= -10;
                2: chara_a_weight <= 10;
                3: chara_a_weight <= 0;
                4: chara_a_weight <= 0;
                default: chara_a_weight <= 0;
            endcase

            case (chara_b)
                0: chara_b_weight <= 0;
                1: chara_b_weight <= -10;
                2: chara_b_weight <= 10;
                3: chara_b_weight <= 0;
                4: chara_b_weight <= 0;
                default: chara_b_weight <= 0;
            endcase
        end
    end


    always @(*) begin
        chara_a_x = chara_a_pos_x;
        chara_a_y = chara_a_pos_y;
        chara_b_x = chara_b_pos_x;
        chara_b_y = chara_b_pos_y;
        ball_x = ball_pos_x;
        ball_y = ball_pos_y;
    end


    always @(posedge fps30, posedge rst) begin
        if(rst) begin
            chara_a_pos_x <= 150;
            chara_a_pos_y <= 390;
        end
        else begin
            if(state == GAME) begin
                chara_a_pos_x <= next_chara_a_pos_x;
                chara_a_pos_y <= next_chara_a_pos_y;
            end
            else begin
                chara_a_pos_x <= 150;
                chara_a_pos_y <= 390;
            end
        end
    end

    always @(*) begin
        next_chara_a_pos_x = chara_a_pos_x;
        next_chara_a_pos_y = chara_a_pos_y;
        if(chara_a_v_x!=0) begin
            if(chara_a_v_x>0) begin
                if(chara_a_pos_x + chara_a_v_x/10 < 250)
                    next_chara_a_pos_x = chara_a_pos_x + chara_a_v_x/10;
                else
                    next_chara_a_pos_x = 250;
            end
            else begin
                if(chara_a_pos_x + chara_a_v_x/10 > 48)
                    next_chara_a_pos_x = chara_a_pos_x + chara_a_v_x/10;
                else
                    next_chara_a_pos_x = 48;
            end
            
        end
        if(chara_a_v_y!=0) begin
            if(chara_a_v_y>0) begin
                if(chara_a_pos_y + chara_a_v_y/10 < 390)
                    next_chara_a_pos_y = chara_a_pos_y + chara_a_v_y;
                else
                    next_chara_a_pos_y = 390;
            end
            else begin
                if(chara_a_pos_y + chara_a_v_y/10 > 50)
                    next_chara_a_pos_y = chara_a_pos_y + chara_a_v_y;
                else
                    next_chara_a_pos_y = 50;
            end
        end
    end


    always @(posedge fps30, posedge rst) begin
        if(rst) begin
            chara_b_pos_x <= 480;
            chara_b_pos_y <= 390;
        end
        else begin
            if(state == GAME) begin
                chara_b_pos_x <= next_chara_b_pos_x;
                chara_b_pos_y <= next_chara_b_pos_y;
            end
            else begin
                chara_b_pos_x <= 480;
                chara_b_pos_y <= 390;
            end
        end
    end

    always @(*) begin
        next_chara_b_pos_x = chara_b_pos_x;
        next_chara_b_pos_y = chara_b_pos_y;
        if(chara_b_v_x!=0) begin
            if(chara_b_v_x>0) begin
                if(chara_b_pos_x + chara_b_v_x/10 < 582)
                    next_chara_b_pos_x = chara_b_pos_x + chara_b_v_x/10;
                else
                    next_chara_b_pos_x = 582;
            end
            else begin
                if(chara_b_pos_x + chara_b_v_x/10 > 370)
                    next_chara_b_pos_x = chara_b_pos_x + chara_b_v_x/10;
                else
                    next_chara_b_pos_x =370;
            end
            
        end
        if(chara_b_v_y!=0) begin
            if(chara_b_v_y>0) begin
                if(chara_b_pos_y + chara_b_v_y/10 < 390)
                    next_chara_b_pos_y = chara_b_pos_y + chara_b_v_y;
                else
                    next_chara_b_pos_y = 390;
            end
            else begin
                if(chara_b_pos_y + chara_b_v_y/10 > 50)
                    next_chara_b_pos_y = chara_b_pos_y + chara_b_v_y;
                else
                    next_chara_b_pos_y = 50;
            end
        end
    end



    always @(posedge fps30, posedge rst) begin
        if(rst) begin
            chara_a_v_x <= 0;
            chara_a_v_y <= 0;
        end
        else begin
            if(state == GAME) begin
                chara_a_v_x <= next_chara_a_v_x;
                chara_a_v_y <= next_chara_a_v_y;
            end
            else begin
                chara_a_v_x <= 0;
                chara_a_v_y <= 0;
            end
        end
    end

    always @(*) begin
        if(inskill_a) begin
            next_chara_a_v_x = 0;
            next_chara_a_v_y = 0;
        end
        else if(key_down[KEY_CODES[0]] == 1) begin
            next_chara_a_v_x = 0;

            if(chara_a_pos_y == 390)
                next_chara_a_v_y = -30 + chara_a_weight/3;
            else begin
                if(chara_a_v_y < 30) 
                    next_chara_a_v_y = chara_a_v_y + 2;
                else 
                    next_chara_a_v_y = chara_a_v_y;
            end

            if(key_down[KEY_CODES[1]] == 1) begin
                if(chara_a_pos_x > 48)
                    next_chara_a_v_x = -40 + chara_a_weight;
            end
            else if(key_down[KEY_CODES[3]] == 1) begin
                if(chara_a_pos_x < 250)
                    next_chara_a_v_x = 40 - chara_a_weight;
            end
            else begin
                next_chara_a_v_x = 0;
            end
        end
        else begin
            next_chara_a_v_x = 0;
            if(key_down[KEY_CODES[1]] == 1) begin
                if(chara_a_pos_x > 48)
                    next_chara_a_v_x = -40 + chara_a_weight;
                if(chara_a_v_y < 30) 
                    next_chara_a_v_y = chara_a_v_y + 2;
                else if(chara_a_pos_y == 390)
                    next_chara_a_v_y = 0;
                else 
                    next_chara_a_v_y = chara_a_v_y;
            end
            else if(key_down[KEY_CODES[3]] == 1) begin
                if(chara_a_pos_x < 250)
                    next_chara_a_v_x = 40 - chara_a_weight;
                if(chara_a_v_y < 30) 
                    next_chara_a_v_y = chara_a_v_y + 2;
                else if(chara_a_pos_y == 390)
                    next_chara_a_v_y = 0;
                else 
                    next_chara_a_v_y = chara_a_v_y;
            end

            else begin
                next_chara_a_v_x = 0;
                if(chara_a_v_y < 30) 
                    next_chara_a_v_y = chara_a_v_y + 2;
                else if(chara_a_pos_y == 390)
                    next_chara_a_v_y = 0;
                else 
                    next_chara_a_v_y = chara_a_v_y;
            end
        end
    end



    always @(posedge fps30, posedge rst) begin
        if(rst) begin
            chara_b_v_x <= 0;
            chara_b_v_y <= 0;
        end
        else begin
            if(state == GAME) begin
                chara_b_v_x <= next_chara_b_v_x;
                chara_b_v_y <= next_chara_b_v_y;
            end
            else begin
                chara_b_v_x <= 0;
                chara_b_v_y <= 0;
            end
        end
    end

    always @(*) begin
        if(inskill_b) begin
            next_chara_b_v_x = 0;
            next_chara_b_v_y = 0;
        end
        else if(key_down[KEY_CODES[5]] == 1) begin
            next_chara_b_v_x = 0;

            if(chara_b_pos_y == 390)
                next_chara_b_v_y = -30 + chara_b_weight/3;
            else begin
                if(chara_b_v_y < 30) 
                    next_chara_b_v_y = chara_b_v_y + 2;
                else 
                    next_chara_b_v_y = chara_b_v_y;
            end

            if(key_down[KEY_CODES[6]] == 1) begin
                if(chara_b_pos_x > 370)
                    next_chara_b_v_x = -40 + chara_b_weight;
            end
            else if(key_down[KEY_CODES[8]] == 1) begin
                if(chara_b_pos_x < 582)
                    next_chara_b_v_x = 40 - chara_b_weight;
            end
            else begin
                next_chara_b_v_x = 0;
            end
        end
        else begin
            next_chara_b_v_x = 0;
            if(key_down[KEY_CODES[6]] == 1) begin
                if(chara_b_pos_x > 370)
                    next_chara_b_v_x = -40 + chara_b_weight;
                if(chara_b_v_y < 30) 
                    next_chara_b_v_y = chara_b_v_y + 2;
                else if(chara_b_pos_y == 390)
                    next_chara_b_v_y = 0;
                else 
                    next_chara_b_v_y = chara_b_v_y;
            end
            else if(key_down[KEY_CODES[8]] == 1) begin
                if(chara_b_pos_x < 582)
                    next_chara_b_v_x = 40 - chara_b_weight;
                if(chara_b_v_y < 30) 
                    next_chara_b_v_y = chara_b_v_y + 2;
                else if(chara_b_pos_y == 390)
                    next_chara_b_v_y = 0;
                else 
                    next_chara_b_v_y = chara_b_v_y;
            end
            
            else begin
                next_chara_b_v_x = 0;
                if(chara_b_v_y < 30) 
                    next_chara_b_v_y = chara_b_v_y + 2;
                else if(chara_b_pos_y == 390)
                    next_chara_b_v_y = 0;
                else 
                    next_chara_b_v_y = chara_b_v_y;
            end
        end
    end


    always @(posedge fps30) begin
        if(state == GAME) begin
            if(ball_pos_y == 400) begin
                if(ball_pos_x < 320) 
                    touch_ground <= 1;
                else
                    touch_ground <= 2;
            end
            else begin
                touch_ground <= 0;
        end
        end
        else begin
            touch_ground <= 0;
        end
    end


    always @(posedge fps30, posedge rst) begin
        if(rst) begin
            ball_pos_x <= 160;
            ball_pos_y <= 60;
        end
        else begin
            if(state == GAME) begin
                ball_pos_x <= next_ball_pos_x;
                ball_pos_y <= next_ball_pos_y;
            end
            else begin
                if(winner == 1)
                    ball_pos_x <= 160;
                else
                    ball_pos_x <= 480;

                ball_pos_y <= 60;
            end
        end
    end

    always @(*) begin
        skilled_a = 0;
        skilled_b = 0;
        if(key_down[KEY_CODES[9]] == 1 && state == GAME && bar_a == 7 && ball_pos_x < 310 && chara_a == 4) begin
            next_ball_pos_x = tele_ball_x;
            next_ball_pos_y = tele_ball_y;
            skilled_a = 1;
        end
        else if(key_down[KEY_CODES[4]] == 1 && state == GAME && bar_b == 7 && ball_pos_x > 310 && chara_b == 4) begin
            next_ball_pos_x = tele_ball_x;
            next_ball_pos_y = tele_ball_y;
            skilled_b = 1;
        end
        else begin

        if(ball_pos_x + ball_v_x/10 <= 38) begin
            next_ball_pos_x = 38;
        end
        else if(ball_pos_x + ball_v_x/10 >= 592) begin
            next_ball_pos_x = 592;
        end
        else if(ball_pos_x + ball_v_x/10 >= 285 && ball_pos_x <= 285 && ball_pos_y >= 270) begin //+ ball_v_y >= 270
            next_ball_pos_x = 285;
        end
        else if(ball_pos_x + ball_v_x/10 <= 335 && ball_pos_x >= 335 && ball_pos_y >= 270) begin
            next_ball_pos_x = 335;
        end

        else begin
                next_ball_pos_x = ball_pos_x + ball_v_x/10;
        end

        if(ball_pos_y + ball_v_y/10 <= 38) begin
            next_ball_pos_y = 38;
        end
        else if(ball_pos_y + ball_v_y/10 >= 400) begin
            next_ball_pos_y = 400;
        end
        else if(ball_pos_x + ball_v_x/10 >= 295 && ball_pos_x + ball_v_x/10 <= 325) begin
            if(ball_pos_y + ball_v_y/10 >= 270) begin
                next_ball_pos_y = ball_pos_y + ball_v_y/10;
            end
            
            else
                next_ball_pos_y = ball_pos_y + ball_v_y/10;
        end
        else begin
                next_ball_pos_y = ball_pos_y + ball_v_y/10;
        end

        end
    end



    always @(posedge fps30, posedge rst) begin
        if(rst) begin
            ball_v_x <= 0;
            ball_v_y <= 0;
        end
        else begin
            if(state == GAME) begin
                ball_v_x <= next_ball_v_x;
                ball_v_y <= next_ball_v_y;
            end
            else begin
                ball_v_x <= 0;
                ball_v_y <= 0;
            end
        end
    end

    always @(*) begin
        if(key_down[KEY_CODES[9]] == 1 && bar_a == 7 && ball_pos_x < 310 && chara_a == 4) begin //inrange1
            next_ball_v_x = 0;
            next_ball_v_y = 0;
        end
        else if(key_down[KEY_CODES[4]] == 1 && bar_b == 7 && ball_pos_x > 310 && chara_b == 4) begin //inrange2
            next_ball_v_x = 0;
            next_ball_v_y = 0;
        end
        else if(inskill_a == 1) begin 

            if(key_down[KEY_CODES[0]] == 1) begin
                next_ball_v_y = -50;
                next_ball_v_x = 0;
            end
            else if(key_down[KEY_CODES[1]] == 1) begin
                next_ball_v_y = 0;
                next_ball_v_x = -50;
            end
            else if(key_down[KEY_CODES[3]] == 1) begin
                next_ball_v_y = 0;
                next_ball_v_x = 50;
            end
            else begin
                next_ball_v_y = 0;
                next_ball_v_x = 0;
            end

        end
        else if(inskill_b == 1) begin 

            if(key_down[KEY_CODES[5]] == 1) begin
                next_ball_v_y = -50;
                next_ball_v_x = 0;
            end
            else if(key_down[KEY_CODES[6]] == 1) begin
                next_ball_v_y = 0;
                next_ball_v_x = -50;
            end
            else if(key_down[KEY_CODES[8]] == 1) begin
                next_ball_v_y = 0;
                next_ball_v_x = 50;
            end
            else begin
                next_ball_v_y = 0;
                next_ball_v_x = 0;
            end

        end
        else begin
            if(ball_pos_y==400) begin
                next_ball_v_x = 0;
                next_ball_v_y = 0;
            end
            else begin
                if(valid1) begin
                    if(valid3 && net_case==0) begin
                        if(ball_pos_y < chara_a_pos_y) begin
                            next_ball_v_x = 50;
                            next_ball_v_y = -100;
                        end
                        else begin
                            next_ball_v_x = -50;
                            next_ball_v_y = 100;
                        end
                    end
                    else if(valid3 && net_case!=0) begin
                        case (net_case)
                            1: begin
                                next_ball_v_x = -50;
                                next_ball_v_y = -100;
                            end
                            2: begin
                                next_ball_v_x = new_ball_v_x1;
                                next_ball_v_y = new_ball_v_y1;
                            end
                            3: begin
                                next_ball_v_x = new_ball_v_x1;
                                next_ball_v_y = new_ball_v_y1;
                            end
                            default: begin
                                next_ball_v_x = new_ball_v_x1;
                                next_ball_v_y = new_ball_v_y1;
                            end
                        endcase
                    end
                    else begin
                        next_ball_v_x = new_ball_v_x1;
                        next_ball_v_y = new_ball_v_y1;
                    end
                end
                else if(valid2) begin
                    if(valid3 && net_case==0) begin
                        if(ball_pos_y < chara_b_pos_y) begin
                            next_ball_v_x = 50;
                            next_ball_v_y = -100;
                        end
                        else begin
                            next_ball_v_x = -50;
                            next_ball_v_y = 100;
                        end
                    end
                    else if(valid3 && net_case!=0) begin
                        case (net_case)
                            1: begin
                                next_ball_v_x = new_ball_v_x2;
                                next_ball_v_y = new_ball_v_y2;
                            end
                            2: begin
                                next_ball_v_x = 50;
                                next_ball_v_y = -100;
                            end
                            3: begin
                                next_ball_v_x = new_ball_v_x2;
                                next_ball_v_y = new_ball_v_y2;
                            end
                            default: begin
                                next_ball_v_x = new_ball_v_x2;
                                next_ball_v_y = new_ball_v_y2;
                            end
                        endcase
                    end
                    else begin
                        next_ball_v_x = new_ball_v_x2;
                        next_ball_v_y = new_ball_v_y2;
                    end
                end
                else if(valid3) begin
                    next_ball_v_x = new_ball_v_x3;
                    next_ball_v_y = new_ball_v_y3;
                end
                else begin
                    
                        if(ball_v_x > 40) begin
                            next_ball_v_x = ball_v_x - 2;
                            if(ball_v_y < 150) 
                                next_ball_v_y = ball_v_y + 5;
                            else if(chara_b_pos_y == 400)
                                next_ball_v_y = 0;
                            else 
                                next_ball_v_y = ball_v_y;
                        end
                        else if(ball_v_x < -40) begin
                            next_ball_v_x = ball_v_x + 2;
                            if(ball_v_y < 150) 
                                next_ball_v_y = ball_v_y + 5;
                            else if(chara_b_pos_y == 400)
                                next_ball_v_y = 0;
                            else 
                                next_ball_v_y = ball_v_y;
                        end
                        else begin
                            next_ball_v_x = ball_v_x;
                            if(ball_v_y < 150) 
                                next_ball_v_y = ball_v_y + 5;
                            else if(ball_pos_y == 400)
                                next_ball_v_y = 0;
                            else 
                                next_ball_v_y = ball_v_y;
                        end

                    
                end
            end
        end
    end
    
endmodule