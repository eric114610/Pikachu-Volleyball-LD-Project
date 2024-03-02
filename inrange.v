

module inrange (
    input clk,
    input rst,
    input signed [10:0] ball_pos_x,
    input signed [10:0] ball_pos_y,
    input signed [10:0] chara_pos_x,
    input signed [10:0] chara_pos_y,
    output reg inrange
);

    reg signed [20:0] distance;

    always @(*) begin
        if(ball_pos_x >= chara_pos_x) begin
            if(ball_pos_y >= chara_pos_y) begin
                if(ball_pos_x - chara_pos_x > 110 || ball_pos_y - chara_pos_y > 110)
                    distance = 0;
                else
                    distance = (ball_pos_x - chara_pos_x) * (ball_pos_y - chara_pos_y);
            end
            else begin
                if(ball_pos_x - chara_pos_x > 110 || chara_pos_y - ball_pos_y > 110)
                    distance = 0;
                else
                    distance = (ball_pos_x - chara_pos_x) * (chara_pos_y - ball_pos_y);
            end
        end
        else begin
            if(ball_pos_y >= chara_pos_y) begin
                if(chara_pos_x - ball_pos_x > 110 || ball_pos_y - chara_pos_y > 110)
                    distance = 0;
                else
                    distance = (chara_pos_x - ball_pos_x) * (ball_pos_y - chara_pos_y);
            end
            else begin
                if(chara_pos_x - ball_pos_x > 110 || chara_pos_y - ball_pos_y > 110)
                    distance = 0;
                else
                    distance = (chara_pos_x - ball_pos_x) * (ball_pos_y - chara_pos_y);
            end
        end
    end


    always @(posedge clk, posedge rst) begin
        if(rst) begin
            inrange <= 0;
        end
        else begin
            if(distance >= 10 && distance <= 12000)
                inrange <= 1;
            else 
                inrange <= 0;
        end
    end
    
endmodule