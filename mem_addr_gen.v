/*
角色寬96,高96 -> 97,97
球76,76 -> 77,77
雲160,80
else 40,40
FAC background
*/
module mem_addr_gen(
    input clk,
    input rst,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    input [2:0] chara_a,
    input [2:0] chara_b,
    input signed [10:0] chara_a_x,
    input signed [10:0] chara_a_y,
    input signed [10:0] chara_b_x,
    input signed [10:0] chara_b_y,
    input signed [10:0] ball_x,
    input signed [10:0] ball_y,
    input chara_pic,
    input [3:0] P1_point,
    input [3:0] P2_point,
    input [7:0] load_clk,
    input [3:0] state,
    output reg [16:0] pixel_addr,
    output reg [16:0] pixel_addr2,
    output reg isball,
    output reg ischara_a,
    output reg ischara_b,
    output reg ispoll
    );

    parameter INIT = 0;
    parameter GAME = 1;
    parameter P1_WIN = 2;
    parameter P2_WIN = 3;
    parameter FINISH = 4;
    parameter LOADING = 5;
    parameter CHOOSE = 6;

    reg isnum1;
    reg isnum2;
    reg isnum3;
    reg isnum4;

    reg isready;
    reg isgo;

    reg isP;
    reg is1;
    reg is2;
    reg iswin;

    reg isselect;

    reg ispoke1;
    reg ispoke2;
    reg [2:0] poke_state;

    reg istitle;
    reg ispress;
    reg isenter;

    reg isscore;

    wire p1_10 = P1_point/10;
    wire [3:0] p1_1 = P1_point%10;
    wire p2_10 = P2_point/10;
    wire [3:0] p2_1 = P2_point%10;

    reg [3:0] pos [15:0];
    reg position;
    integer i;
    reg signed [6:0] dis_a_x;
    reg signed [6:0] dis_a_y;
    reg signed [6:0] dis_b_x;
    reg signed [6:0] dis_b_y;
    reg signed [10:0] dis_ball_x;
    reg signed [10:0] dis_ball_y;


    
    always @(*) begin
        if(v_cnt >= ball_y - 28 && v_cnt <= ball_y + 28 && (state == GAME || state == LOADING)) begin
            if(h_cnt >= ball_x - 28 && h_cnt <= ball_x + 28) begin
                dis_ball_x = ball_x - h_cnt;
                dis_ball_y = ball_y - v_cnt;
                if(dis_ball_x*dis_ball_x + dis_ball_y*dis_ball_y <= 800)
                    isball = 1;
                else 
                    isball = 0;
            end
            else begin
                isball = 0;
                dis_ball_x = 0;
                dis_ball_y = 0;
            end
        end
        else begin
            isball = 0;
            dis_ball_x = 0;
            dis_ball_y = 0;
        end
    end

    always @(*) begin
        if(v_cnt >= chara_a_y - 48 && v_cnt <= chara_a_y + 48) begin
            if(h_cnt >= chara_a_x - 48 && h_cnt <= chara_a_x + 48) begin
                if(state == GAME || state == P1_WIN || state == P2_WIN || state == CHOOSE || (state == LOADING && poke_state == 4)) begin
                    ischara_a = 1;
                    dis_a_x = chara_a_x - h_cnt;
                    dis_a_y = chara_a_y - v_cnt +1;
                end
                else begin
                    ischara_a = 0;
                    dis_a_x = 0;
                    dis_a_y = 0;
                end
            end
            else begin
                ischara_a = 0;
                dis_a_x = 0;
                dis_a_y = 0;
            end
        end
        else begin
            ischara_a = 0;
            dis_a_x = 0;
            dis_a_y = 0;
        end
    end

    always @(*) begin
        if(v_cnt >= chara_b_y - 48 && v_cnt <= chara_b_y + 48) begin
            if(h_cnt >= chara_b_x - 48 && h_cnt <= chara_b_x + 48) begin
                if(state == GAME || state == P1_WIN || state == P2_WIN || state == CHOOSE || (state == LOADING && poke_state == 4)) begin
                    ischara_b = 1;
                    dis_b_x = chara_b_x - h_cnt;
                    dis_b_y = chara_b_y - v_cnt +1;
                end
                else begin
                    ischara_b = 0;
                    dis_b_x = 0;
                    dis_b_y = 0;
                end
            end
            else begin
                ischara_b = 0;
                dis_b_x = 0;
                dis_b_y = 0;
            end
        end
        else begin
            ischara_b = 0;
            dis_b_x = 0;
            dis_b_y = 0;
        end
    end

    //left shift 10
    always @(*) begin
        if(v_cnt >= 280 && v_cnt <= 438) begin
            if(h_cnt >= 300 && h_cnt <= 320-1) begin
                ispoll = 1;
            end
            else begin
                ispoll = 0;
            end
        end
        else begin
            ispoll = 0;
        end
    end


    always @(*) begin
        if(v_cnt >= 20 && v_cnt < 100 && state != GAME && state != LOADING) begin
            isnum1=0;
            isnum2=0;
            isnum3=0;
            isnum4=0;
            if(h_cnt >= 80 && h_cnt < 126) begin
                isnum1 = 1;
            end
            else if(h_cnt >= 126 && h_cnt < 172) begin
                isnum2 = 1;
            end
            else if(h_cnt >= 450 && h_cnt < 496) begin
                isnum3 = 1;
            end
            else if(h_cnt >= 496 && h_cnt < 542) begin
                isnum4 = 1;
            end
        end
        else begin
            isnum1=0;
            isnum2=0;
            isnum3=0;
            isnum4=0;
        end
    end


    always @(*) begin
        if(state == LOADING && v_cnt >= 100 && v_cnt < 160) begin
            if(h_cnt >= 190 && h_cnt < 430 && load_clk < 60) begin
                isready = 1;
                isgo = 0;
            end
            else if(h_cnt >= 210 && h_cnt < 410 && load_clk >= 60) begin
                isready = 0;
                isgo = 1;
            end
            else begin
                isready = 0;
                isgo = 0;
            end
        end
        else begin
            isready = 0;
            isgo = 0;
        end
    end


    always @(*) begin
        if(state == P1_WIN) begin
            if(h_cnt >= 316  && h_cnt < 362 && v_cnt >= 100 && v_cnt < 180) begin
                is1 = 1;
                is2 = 0;
            end
            else begin
                is1 = 0;
                is2 = 0;
            end
        end
        else if(state == P2_WIN) begin
            if(h_cnt >= 316  && h_cnt < 362 && v_cnt >= 100 && v_cnt < 180) begin
                is1 = 0;
                is2 = 1;
            end
            else begin
                is1 = 0;
                is2 = 0;
            end
        end
        else if(state == FINISH) begin
            if(P1_point >= 5) begin
                if(h_cnt >= 316  && h_cnt < 362 && v_cnt >= 100 && v_cnt < 180) begin
                    is1 = 1;
                    is2 = 0;
                end
                else begin
                    is1 = 0;
                    is2 = 0;
                end
            end
            else if(P2_point >= 5) begin
                if(h_cnt >= 316  && h_cnt < 362 && v_cnt >= 100 && v_cnt < 180) begin
                    is1 = 0;
                    is2 = 1;
                end
                else begin
                    is1 = 0;
                    is2 = 0;
                end
            end
            else begin
                is1 = 0;
                is2 = 0;
            end
        end
        else begin
            is1 = 0;
            is2 = 0;
        end
    end


    
    always @(*) begin
        if(state == P1_WIN || state == P2_WIN) begin
            if(h_cnt >= 260  && h_cnt < 305 && v_cnt >= 100 && v_cnt < 180) begin
                isP = 1;
                isscore = 0;
                iswin = 0;
            end
            else if((v_cnt>>1) >= 95 && (v_cnt>>1) < 125 && (h_cnt>>1) >= 95 && (h_cnt>>1) < 215) begin
                isscore = 1;
                isP = 0;
                iswin = 0;
            end
            else begin
                isP = 0;
                iswin = 0;
                isscore = 0;
            end
        end
        else if(state == FINISH) begin
            if(h_cnt >= 260  && h_cnt < 305 && v_cnt >= 100 && v_cnt < 180) begin
                isP = 1;
                isscore = 0;
                iswin = 0;
            end
            else if((v_cnt>>1) >= 95 && (v_cnt>>1) < 125 && (h_cnt>>1) >= 95 && (h_cnt>>1) < 215) begin
                isscore = 0;
                isP = 0;
                iswin = 1;
            end
            else begin
                isP = 0;
                iswin = 0;
                isscore = 0;
            end
        end
        else begin
            isP = 0;
            iswin = 0;
            isscore = 0;
        end
    end


    always @(*) begin
        if(state == CHOOSE) begin
            if((h_cnt>>1) >= 95 && (h_cnt>>1) < 215 && (v_cnt>>1) >= 50 && (v_cnt>>1) < 80) begin
                isselect = 1;
            end
            else begin
                isselect = 0;
            end
        end
        else begin
            isselect = 0;
        end
    end


    always @(*) begin
        if(state == LOADING) begin
            if(load_clk < 15) begin
                poke_state = 0;
            end
            else if(load_clk < 30) begin
                poke_state = 1;
            end
            else if(load_clk < 45) begin
                poke_state = 2;
            end
            else if(load_clk < 60) begin
                poke_state = 3;
            end
            else begin
                poke_state = 4;
            end
        end
        else begin
            poke_state = 0;
        end
    end


    always @(*) begin
        if(state == LOADING) begin
            if(h_cnt >= 110 && h_cnt < 150 && v_cnt >= 400 && v_cnt < 440) begin
                ispoke1 = 1;
                ispoke2 = 0;
            end
            else if(h_cnt >= 440 && h_cnt < 480 && v_cnt >= 400 && v_cnt < 440) begin
                ispoke1 = 0;
                ispoke2 = 1;
            end
            else begin
                ispoke1 = 0;
                ispoke2 = 0;
            end
        end
        else begin
            ispoke1 = 0;
            ispoke2 = 0;
        end
    end


    always @(*) begin
        if(v_cnt >= 100 && v_cnt < 220 && state == INIT) begin
            istitle = 0;
            if(h_cnt >= 150 && h_cnt < 470) begin
                istitle = 1;
            end
        end
        else begin
            istitle = 0;
        end
    end
    //154
    always @(*) begin
        if(v_cnt >= 320 && v_cnt < 380 && state == INIT) begin
            ispress = 0;
            if(h_cnt >= 156 && h_cnt < 276) begin
                ispress = 1;
            end
        end
        else begin
            ispress = 0;
        end
    end

    always @(*) begin
        if(v_cnt >= 320 && v_cnt < 380 && state == INIT) begin
            isenter = 0;
            if(h_cnt >= 296 && h_cnt < 464) begin
                isenter = 1;
            end
        end
        else begin
            isenter = 0;
        end
    end


    //圖往右放2格(640*480)
    //ball not right
    always @(*) begin
        if(istitle) begin
            // 0-160,200-260
            pixel_addr = (((h_cnt>>1) - 75) + 320*((v_cnt>>1) - 50 + 100));
        end
        else if(ispress) begin
            //330,200 shrink
            pixel_addr = (((h_cnt>>2) - 78/2 + 165) + 320*((v_cnt>>2) - 160/2 + 100));
        end
        else if(isenter) begin
            // 400,200 shrink
            pixel_addr = (((h_cnt>>2) - 296/4 + 200) + 320*((v_cnt>>2) - 160/2 + 100));
        end
        else if (state == INIT) begin
            pixel_addr = 0;
        end
        else if(isball) begin
            //500,400
            pixel_addr = ((268-dis_ball_x/2)+320*(218-dis_ball_y/2)); 
        end
        else if(ischara_a) begin
            if(chara_pic == 0) begin
                case (chara_a)
                    0: pixel_addr = ((24+dis_a_x/2)+320*(24-dis_a_y/2)); 
                    1: pixel_addr = ((74+dis_a_x/2)+320*(24-dis_a_y/2)); 
                    2: pixel_addr = ((124+dis_a_x/2)+320*(24-dis_a_y/2)); 
                    3: pixel_addr = ((174+dis_a_x/2)+320*(24-dis_a_y/2)); 
                    4: pixel_addr = ((224+dis_a_x/2)+320*(24-dis_a_y/2)); 
                    default: pixel_addr = ((24+dis_a_x/2)+320*(24-dis_a_y/2)); 
                endcase
            end
            else begin
                case (chara_a)
                    0: pixel_addr = ((24+dis_a_x/2)+320*(74-dis_a_y/2)); 
                    1: pixel_addr = ((74+dis_a_x/2)+320*(74-dis_a_y/2)); 
                    2: pixel_addr = ((124+dis_a_x/2)+320*(74-dis_a_y/2)); 
                    3: pixel_addr = ((174+dis_a_x/2)+320*(74-dis_a_y/2)); 
                    4: pixel_addr = ((224+dis_a_x/2)+320*(74-dis_a_y/2)); 
                    default: pixel_addr = ((24+dis_a_x/2)+320*(74-dis_a_y/2)); 
                endcase
            end
            
        end
        else if(ischara_b) begin
            if(chara_pic == 0) begin
                case (chara_b)
                    0: pixel_addr = ((24-dis_b_x/2)+320*(24-dis_b_y/2)); 
                    1: pixel_addr = ((74-dis_b_x/2)+320*(24-dis_b_y/2)); 
                    2: pixel_addr = ((124-dis_b_x/2)+320*(24-dis_b_y/2)); 
                    3: pixel_addr = ((174-dis_b_x/2)+320*(24-dis_b_y/2)); 
                    4: pixel_addr = ((224-dis_b_x/2)+320*(24-dis_b_y/2)); 
                    default: pixel_addr = ((24-dis_b_x/2)+320*(24-dis_b_y/2)); 
                endcase
            end
            else begin
                case (chara_b)
                    0: pixel_addr = ((24-dis_b_x/2)+320*(74-dis_b_y/2)); 
                    1: pixel_addr = ((74-dis_b_x/2)+320*(74-dis_b_y/2)); 
                    2: pixel_addr = ((124-dis_b_x/2)+320*(74-dis_b_y/2)); 
                    3: pixel_addr = ((174-dis_b_x/2)+320*(74-dis_b_y/2)); 
                    4: pixel_addr = ((224-dis_b_x/2)+320*(74-dis_b_y/2)); 
                    default: pixel_addr = ((24-dis_b_x/2)+320*(74-dis_b_y/2)); 
                endcase
            end
            
        end
        else if(ispoll) begin
            //620,200
            pixel_addr = (((h_cnt>>1) - 150 + 310) + 320*((v_cnt>>1) - 140 + 100));
        end
        
        else if(isnum1) begin
            pixel_addr = (((h_cnt>>1) - 40 + p1_10*25) + 320*((v_cnt>>1) - 10 + 200));
        end
        else if(isnum2) begin
            pixel_addr = (((h_cnt>>1) - 63 + p1_1*25) + 320*((v_cnt>>1) - 10 + 200));
        end
        else if(isnum3) begin
            pixel_addr = (((h_cnt>>1) - 225 + p2_10*25) + 320*((v_cnt>>1) - 10 + 200));
        end
        else if(isnum4) begin
            pixel_addr = (((h_cnt>>1) - 248 + p2_1*25) + 320*((v_cnt>>1) - 10 + 200));
        end
        else if(isready) begin
            //330,280 shrink
            pixel_addr = (((h_cnt>>2) - 95/2 + 165) + 320*((v_cnt>>2) - 25 + 140));
        end
        else if(isgo) begin
            //460,280 shrink
            pixel_addr = (((h_cnt>>2) - 105/2 + 230) + 320*((v_cnt>>2) - 25 + 140));
        end
        else if(is1) begin
            //530,190 shrink
            pixel_addr = (((h_cnt>>2) - 79 + 265) + 320*((v_cnt>>2) - 25 + 95));
        end
        else if(is2) begin
            //560,190 shrink
            pixel_addr = (((h_cnt>>2) - 79 + 280) + 320*((v_cnt>>2) - 25 + 95));
        end
        else if(isP) begin
            //500,190 shrink
            pixel_addr = (((h_cnt>>2) - 65 + 250) + 320*((v_cnt>>2) - 25 + 95));
        end
        else if(iswin) begin
            //460,240 shrink
            pixel_addr = (((h_cnt>>2) - 95/2 + 230) + 320*((v_cnt>>2) - 95/2 + 120));
        end
        else if(isselect) begin
            //330,240 shrink
            pixel_addr = (((h_cnt>>2) - 95/2 + 165) + 320*((v_cnt>>2) - 50/2 + 120));
        end
        else if(ispoke1) begin
            //0,350 
            case (poke_state)
                0: pixel_addr = (((h_cnt>>1) - 55 + 0) + 320*((v_cnt>>1) - 200 + 175));
                1: pixel_addr = (((h_cnt>>1) - 55 + 25) + 320*((v_cnt>>1) - 200 + 175));
                2: pixel_addr = (((h_cnt>>1) - 55 + 50) + 320*((v_cnt>>1) - 200 + 175));
                3: pixel_addr = (((h_cnt>>1) - 55 + 75) + 320*((v_cnt>>1) - 200 + 175));
                4: pixel_addr = 0;
                default: pixel_addr = (((h_cnt>>1) - 55 + 0) + 320*((v_cnt>>1) - 200 + 175));
            endcase
        end
        else if(ispoke2) begin
            //0,350
            case (poke_state)
                0: pixel_addr = (((h_cnt>>1) - 220 + 0) + 320*((v_cnt>>1) - 200 + 175));
                1: pixel_addr = (((h_cnt>>1) - 220 + 25) + 320*((v_cnt>>1) - 200 + 175));
                2: pixel_addr = (((h_cnt>>1) - 220 + 50) + 320*((v_cnt>>1) - 200 + 175));
                3: pixel_addr = (((h_cnt>>1) - 220 + 75) + 320*((v_cnt>>1) - 200 + 175));
                4: pixel_addr = 0;
                default: pixel_addr = (((h_cnt>>1) - 220 + 0) + 320*((v_cnt>>1) - 200 + 175));
            endcase
            //pixel_addr = (((h_cnt>>1) - 55 + 0) + 320*((v_cnt>>1) - 200 + 175));
        end
        else if(isscore) begin
            //330,320 shrink
            pixel_addr = (((h_cnt>>2) - 95/2 + 165) + 320*((v_cnt>>2) - 95/2 + 160));
        end
        else begin
            pixel_addr = 0;
            
        end

        
        if (state == INIT) begin
            pixel_addr2 = (3 + 320*220);
        end
        else begin
            if(v_cnt>=440) begin
                //500,160
                pixel_addr2 = (((h_cnt>>1) % 20 + 250)+320*(((v_cnt>>1)-220) % 10 + 80));
            end 
            else if(v_cnt>=400) begin
                //560,0
                pixel_addr2 = (((h_cnt>>1) % 40 + 280)+320*(((v_cnt>>1)-200) % 20 + 0));
            end
            else if(v_cnt>=340) begin
                //500,100
                pixel_addr2 = (((h_cnt>>1) % 20 + 250)+320*(((v_cnt>>1)-170) % 20 + 50));
            end
            else if(v_cnt>=320) begin
                //600,160
                pixel_addr2 = (((h_cnt>>1) % 20 + 300)+320*(((v_cnt>>1)-160) % 10 + 80));
            end
            else begin
                //600,100
                pixel_addr2 = (((h_cnt>>1) % 20 + 300)+320*((v_cnt>>1) % 20 + 50));
            end
        end

        //pixel_addr = ((h_cnt>>1)+320*(v_cnt>>1)+ position*320 ); 
    end

    

    wire [3:0] curr;
    assign curr = h_cnt/160 + v_cnt/120*4;
    wire [7:0] curr_x;
    wire [5:0] curr_y;
    assign curr_x = (h_cnt>>1) % 80;
    assign curr_y = (v_cnt>>1) % 60;
    

    
endmodule