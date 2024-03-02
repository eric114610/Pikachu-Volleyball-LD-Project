/*
用來計算碰撞之後的物理運算
x軸右為正 y軸下為正
chara 中心+-20
*/

module collide (
    input signed [10:0] chara_pos_x,
    input signed [10:0] chara_pos_y,
    input signed [10:0] ball_pos_x,
    input signed [10:0] ball_pos_y,
    input clk,
    input rst,
    //input en,
    output reg signed [9:0] new_ball_v_x,
    output reg signed [9:0] new_ball_v_y,
    output reg valid
);

    //0:球右上 1:球左上 2:球右下 3:球左下 4:default
    reg [2:0] dir;
    reg [2:0] next_dir;

    //0: default
    reg signed [20:0] distance;
    reg signed [20:0] distance_x;
    reg signed [20:0] distance_y;

    reg signed [20:0] next_ball_v_x;
    reg signed [20:0] next_ball_v_y;

    reg signed [9:0] tmp_new_ball_v_x;
    reg signed [9:0] tmp_new_ball_v_y;

    reg [2:0] incollide;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            dir <= 5;
        end 
        else begin
            dir <= next_dir;
        end       
    end

    always @(*) begin
        if(ball_pos_y <= chara_pos_y) begin
            if(ball_pos_x >= chara_pos_x) 
                next_dir = 0;
            else 
                next_dir = 1;
        end
        else begin
            if(ball_pos_x >= chara_pos_x) 
                next_dir = 2;
            else 
                next_dir = 3;
        end
    end


    always @(posedge clk, posedge rst) begin
        if(rst) begin
            distance_x <= 0;
            distance_y <= 0;
        end
        else begin
            case (dir)
                0: begin
                    distance_x <= ball_pos_x - chara_pos_x;
                    distance_y <= chara_pos_y - ball_pos_y;
                end
                1: begin
                    distance_x <= chara_pos_x - ball_pos_x;
                    distance_y <= chara_pos_y - ball_pos_y;
                end
                2: begin
                    distance_x <= ball_pos_x - chara_pos_x;
                    distance_y <= ball_pos_y - chara_pos_y;
                end
                3: begin
                    distance_x <= chara_pos_x - ball_pos_x;
                    distance_y <= ball_pos_y - chara_pos_y;
                end
                default: begin
                    distance_x <= 0;
                    distance_y <= 0;
                end
            endcase
        end
    end


    always @(posedge clk) begin
        if(distance_x > 100 || distance_y > 100) begin
            distance <= 0;
        end
        else if((dir == 2 || dir == 3) && (distance_x > 50 || distance_y > 50)) begin
            distance <= 0;
        end
        else begin
            distance <= distance_x*distance_x + distance_y*distance_y;
        end
    end



    always @(posedge clk, posedge rst) begin
        if(rst) begin
            new_ball_v_x <= 0;
            new_ball_v_y <= 0;
        end
        else begin
            case (dir)
                0: begin
                    if(tmp_new_ball_v_x <= 200)
                        new_ball_v_x <= tmp_new_ball_v_x;
                    else
                        new_ball_v_x <= 200;

                    if(tmp_new_ball_v_y <= 200)
                        new_ball_v_y <= -tmp_new_ball_v_y;
                    else
                        new_ball_v_y <= -200;
                end
                1: begin
                    if(tmp_new_ball_v_x <= 200)
                        new_ball_v_x <= -tmp_new_ball_v_x;
                    else
                        new_ball_v_x <= -200;

                    if(tmp_new_ball_v_y <= 200)
                        new_ball_v_y <= -tmp_new_ball_v_y;
                    else
                        new_ball_v_y <= -200;
                end
                2: begin
                    if(tmp_new_ball_v_x <= 200)
                        new_ball_v_x <= tmp_new_ball_v_x;
                    else
                        new_ball_v_x <= 200;
                    if(tmp_new_ball_v_y <= 200)
                        new_ball_v_y <= tmp_new_ball_v_y;
                    else
                        new_ball_v_y <= 200;
                end
                3: begin
                    if(tmp_new_ball_v_x <= 200)
                        new_ball_v_x <= -tmp_new_ball_v_x;
                    else
                        new_ball_v_x <= -200;
                    if(tmp_new_ball_v_y <= 200)
                        new_ball_v_y <= tmp_new_ball_v_y;
                    else
                        new_ball_v_y <= 200;
                end
                default: begin
                    new_ball_v_x <= 0;
                    new_ball_v_y <= 0;
                end
            endcase
        end
    end

    always @(*) begin
        if(distance > 7500 || distance == 0) begin
            next_ball_v_x = 0;
            next_ball_v_y = 0;
            tmp_new_ball_v_x = 0;
            tmp_new_ball_v_y = 0;
        end
        else begin
            
                next_ball_v_x = 400*distance_x/(distance_x+distance_y);
                next_ball_v_y = 200*distance_y/(distance_x+distance_y);
                tmp_new_ball_v_x = next_ball_v_x[9:0];
                tmp_new_ball_v_y = next_ball_v_y[9:0];

        end
    end

    reg [2:0] update;
    always @(posedge clk, posedge rst) begin
        if(rst)
            update <= 0;
        else begin
            if((distance <= 7500) && update[2] == 0) begin
                update[2] <= update[1];
                update[1] <= 1;
                update[0] <= 1;
            end
            else if((distance <= 7500) && update[2] == 1) begin
                update[2] <= update[1];
                update[1] <= 1;
                update[0] <= 0;
            end
            else begin
                update <= 0;     
            end
        end
    end



    always @(*) begin
        if(rst)
            valid = 0;
        else begin
            if(new_ball_v_x !=0 || new_ball_v_y!=0)
                valid = 1;
            else 
                valid = 0;
        end
    end
    
endmodule