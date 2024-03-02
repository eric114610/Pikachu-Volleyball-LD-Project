/*
負責處理邊界反彈
輸出加速度
*/

module border (
    input signed [10:0] ball_pos_x,
    input signed [10:0] ball_pos_y,
    input signed [9:0] ball_v_x,
    input signed [9:0] ball_v_y,
    input clk,
    input rst,
    output reg signed [9:0] new_ball_v_x,
    output reg signed [9:0] new_ball_v_y,
    output reg valid,
    output reg [1:0] net_case
);

    reg signed [9:0] next_ball_v_x;
    reg signed [9:0] next_ball_v_y;


    always @(posedge clk, posedge rst) begin
        if(rst) begin
            net_case <= 0;
        end
        else begin
            if(ball_pos_x >= 285 && ball_pos_x <= 295 && ball_pos_y >= 270) begin
                net_case <= 1;
            end
            else if(ball_pos_x <= 335 && ball_pos_x >= 325 && ball_pos_y >= 270) begin
                net_case <= 2;
            end
            else if(ball_pos_x >= 295 && ball_pos_x <= 325 && ball_pos_y >= 270) begin// && ball_pos_y >= 260
                net_case <= 3;
            end
            else begin
                net_case <= 0;
            end
        end
    end


    always @(posedge clk, posedge rst) begin
        if(rst) begin
            new_ball_v_x <= 0;
            new_ball_v_y <= 0;
        end
        else begin
            new_ball_v_x <= next_ball_v_x;
            new_ball_v_y <= next_ball_v_y;
        end
    end

    always @(*) begin
        if(ball_pos_y <= 38) begin
            
            if(ball_v_y < -10)
                next_ball_v_y = -ball_v_y;
            else if(ball_v_y >= -10 && ball_v_y <= 10)
                next_ball_v_y = 20;
            else
                next_ball_v_y = ball_v_y;

            if(ball_pos_x <= 38) begin
                if(ball_v_x < -10)
                    next_ball_v_x = -ball_v_x;
                else if(ball_v_x >= -10 && ball_v_x <= 10)
                    next_ball_v_x = 20;
                else
                    next_ball_v_x = ball_v_x;
                
            end
            else if(ball_pos_x >= 592) begin
                if(ball_v_x > 10)
                    next_ball_v_x = -ball_v_x;
                else if(ball_v_x >= -10 && ball_v_x <= 10)
                    next_ball_v_x = -20;
                else
                    next_ball_v_x = ball_v_x;
                
            end
            else
                next_ball_v_x = ball_v_x;
        end
        else begin
            if(ball_pos_x <= 38) begin
                if(ball_v_x < -10)
                    next_ball_v_x = -ball_v_x;
                else if(ball_v_x >= -10 && ball_v_x <= 10)
                    next_ball_v_x = 20;
                else
                    next_ball_v_x = ball_v_x;
                next_ball_v_y = ball_v_y;
            end
            else if(ball_pos_x >= 592) begin
                if(ball_v_x > 10)
                    next_ball_v_x = -ball_v_x;
                else if(ball_v_x >= -10 && ball_v_x <= 10)
                    next_ball_v_x = -20;
                else
                    next_ball_v_x = ball_v_x;
                next_ball_v_y = ball_v_y;
            end
            else begin
                if(ball_pos_x >= 285 && ball_pos_x <= 295 && ball_pos_y >= 270) begin
                    if(ball_v_x > 10)
                        next_ball_v_x = -ball_v_x;
                    else if(ball_v_x >= -10 && ball_v_x <= 10)
                        next_ball_v_x = -20;
                    else
                        next_ball_v_x = ball_v_x;
                    next_ball_v_y = ball_v_y;
                end
                else if(ball_pos_x <= 335 && ball_pos_x >= 325 && ball_pos_y >= 270) begin
                    if(ball_v_x < -10)
                        next_ball_v_x = -ball_v_x;
                    else if(ball_v_x >= -10 && ball_v_x <= 10)
                        next_ball_v_x = 20;
                    else
                        next_ball_v_x = ball_v_x;
                    next_ball_v_y = ball_v_y;
                end
                else if(ball_pos_x >= 295 && ball_pos_x <= 325 && ball_pos_y >= 270) begin
                    if(ball_v_y > 10)
                        next_ball_v_y = -ball_v_y;
                    else if(ball_v_y >= -10 && ball_v_y <= 10)
                        next_ball_v_y = -20;
                    else
                        next_ball_v_y = ball_v_y;
                    next_ball_v_x = ball_v_x;
                end
                else begin
                    next_ball_v_x = 0;
                    next_ball_v_y = 0;
                end
            end
        end
        
    end

    always @(*) begin
        if(new_ball_v_x!=0 || new_ball_v_y!=0)
            valid = 1;
        else begin
            valid = 0;
        end
    end


    
    
endmodule