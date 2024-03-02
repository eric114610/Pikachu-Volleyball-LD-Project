module LFSR (
    input wire clk,
    input wire rst,
    output reg [3:0] random
);

    always @(posedge clk, posedge rst) begin
        if (rst == 1) begin
            random <= 4'b1000;
        end
        else begin
            random[2:0] <= random[3:1];
            random[3] <= random[1] ^ random[0];
        end
    end
    
endmodule