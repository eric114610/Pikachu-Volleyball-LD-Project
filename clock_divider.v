module clock_divider(clk1, clk, clk22);
input clk;
output clk1;
output clk22;
reg [21:0] num;
wire [21:0] next_num;

always @(posedge clk) begin
  num <= next_num;
end

assign next_num = num + 1'b1;
assign clk1 = num[1];
assign clk22 = num[21];
endmodule

module clock_divi #(
    parameter n = 27
)(
    input wire  clk,
    output wire clk_div  
);

    reg [n-1:0] num;
    wire [n-1:0] next_num;

    always @(posedge clk) begin
        num <= next_num;
    end

    assign next_num = num + 1;
    assign clk_div = num[n-1];
endmodule