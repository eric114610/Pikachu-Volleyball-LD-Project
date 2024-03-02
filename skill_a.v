

module teleport (
    input clk,
    input rst,
    input signed [10:0] ball_pos_x,
    input signed [10:0] ball_pos_y,
    input [3:0] state,
    output valid,
    output reg signed [10:0] new_ball_x,
    output reg signed [10:0] new_ball_y
);

    wire [3:0] seed;
    LFSR lfsr1(.clk(clk15), .rst(rst), .random(seed));

    reg signed [10:0] next_ball_x;
    reg signed [10:0] next_ball_y;

    wire clk15;
    clock_divi #(15) clock_d(.clk(clk), .clk_div(clk15));

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            new_ball_x <= 0;
        end
        else begin
            if(state == 1) begin
                if(ball_pos_x <= 310) begin
                    new_ball_x <= seed*14 + 370 + ball_pos_x%14;
                end
                else begin
                    new_ball_x <= seed*14 + 60 + ball_pos_x%14;
                end
            end
            else begin
                new_ball_x <= 0;
            end
        end
        
    end
    
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            new_ball_y <= 0;
        end
        else begin
            if(state == 1) begin
                new_ball_y <= (15-seed)*6 + 200 + ball_pos_y%10;
            end
            else begin
                new_ball_y <= 0;
            end
        end
    
    end

endmodule