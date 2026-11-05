`timescale 1ns/1ps
module fir48_dp_folded(input wire clk,rst,en,
input wire signed [15:0] data_in,
output wire signed [37:0] data_out,output wire valid_out);
// Eight pipeline stages: accepted edge t -> valid edge t+7.
// Input has 14 fractional bits; aligned output has 29.
reg signed [15:0] taps[0:47];
reg [7:0] valid_pipe; integer i;
always @(posedge clk) begin
 if(rst) begin
  for(i=0;i<48;i=i+1) taps[i]<=16'sd0;
  valid_pipe<=8'd0;
 end else begin
  valid_pipe<={valid_pipe[6:0],en};
  if(en) begin
   taps[0]<=data_in;
   for(i=1;i<48;i=i+1) taps[i]<=taps[i-1];
  end
 end
end
reg signed [16:0] pair_0;
always @(posedge clk) begin
 if(rst) pair_0<=17'sd0;
 else pair_0<=$signed({taps[0][15],taps[0]})+$signed({taps[47][15],taps[47]});
end
localparam signed [3:0] C_0=4'h0;
wire signed [20:0] raw_0;
assign raw_0=$signed(pair_0)*C_0;
wire signed [37:0] extended_0=raw_0;
reg signed [37:0] product_0;
always @(posedge clk) begin
 if(rst) product_0<=38'sd0;
 else product_0<=extended_0<<<12;
end
reg signed [16:0] pair_1;
always @(posedge clk) begin
 if(rst) pair_1<=17'sd0;
 else pair_1<=$signed({taps[1][15],taps[1]})+$signed({taps[46][15],taps[46]});
end
localparam signed [15:0] C_1=16'hff89;
wire signed [32:0] raw_1;
assign raw_1=$signed(pair_1)*C_1;
wire signed [37:0] extended_1=raw_1;
reg signed [37:0] product_1;
always @(posedge clk) begin
 if(rst) product_1<=38'sd0;
 else product_1<=extended_1<<<0;
end
reg signed [16:0] pair_2;
always @(posedge clk) begin
 if(rst) pair_2<=17'sd0;
 else pair_2<=$signed({taps[2][15],taps[2]})+$signed({taps[45][15],taps[45]});
end
localparam signed [15:0] C_2=16'hff7b;
wire signed [32:0] raw_2;
assign raw_2=$signed(pair_2)*C_2;
wire signed [37:0] extended_2=raw_2;
reg signed [37:0] product_2;
always @(posedge clk) begin
 if(rst) product_2<=38'sd0;
 else product_2<=extended_2<<<0;
end
reg signed [16:0] pair_3;
always @(posedge clk) begin
 if(rst) pair_3<=17'sd0;
 else pair_3<=$signed({taps[3][15],taps[3]})+$signed({taps[44][15],taps[44]});
end
localparam signed [3:0] C_3=4'h0;
wire signed [20:0] raw_3;
assign raw_3=$signed(pair_3)*C_3;
wire signed [37:0] extended_3=raw_3;
reg signed [37:0] product_3;
always @(posedge clk) begin
 if(rst) product_3<=38'sd0;
 else product_3<=extended_3<<<12;
end
reg signed [16:0] pair_4;
always @(posedge clk) begin
 if(rst) pair_4<=17'sd0;
 else pair_4<=$signed({taps[4][15],taps[4]})+$signed({taps[43][15],taps[43]});
end
localparam signed [15:0] C_4=16'h7d;
wire signed [32:0] raw_4;
assign raw_4=$signed(pair_4)*C_4;
wire signed [37:0] extended_4=raw_4;
reg signed [37:0] product_4;
always @(posedge clk) begin
 if(rst) product_4<=38'sd0;
 else product_4<=extended_4<<<0;
end
reg signed [16:0] pair_5;
always @(posedge clk) begin
 if(rst) pair_5<=17'sd0;
 else pair_5<=$signed({taps[5][15],taps[5]})+$signed({taps[42][15],taps[42]});
end
localparam signed [15:0] C_5=16'hc3;
wire signed [32:0] raw_5;
assign raw_5=$signed(pair_5)*C_5;
wire signed [37:0] extended_5=raw_5;
reg signed [37:0] product_5;
always @(posedge clk) begin
 if(rst) product_5<=38'sd0;
 else product_5<=extended_5<<<0;
end
reg signed [16:0] pair_6;
always @(posedge clk) begin
 if(rst) pair_6<=17'sd0;
 else pair_6<=$signed({taps[6][15],taps[6]})+$signed({taps[41][15],taps[41]});
end
localparam signed [3:0] C_6=4'h0;
wire signed [20:0] raw_6;
assign raw_6=$signed(pair_6)*C_6;
wire signed [37:0] extended_6=raw_6;
reg signed [37:0] product_6;
always @(posedge clk) begin
 if(rst) product_6<=38'sd0;
 else product_6<=extended_6<<<12;
end
reg signed [16:0] pair_7;
always @(posedge clk) begin
 if(rst) pair_7<=17'sd0;
 else pair_7<=$signed({taps[7][15],taps[7]})+$signed({taps[40][15],taps[40]});
end
localparam signed [7:0] C_7=8'hff;
wire signed [24:0] raw_7;
assign raw_7=$signed(pair_7)*C_7;
wire signed [37:0] extended_7=raw_7;
reg signed [37:0] product_7;
always @(posedge clk) begin
 if(rst) product_7<=38'sd0;
 else product_7<=extended_7<<<8;
end
reg signed [16:0] pair_8;
always @(posedge clk) begin
 if(rst) pair_8<=17'sd0;
 else pair_8<=$signed({taps[8][15],taps[8]})+$signed({taps[39][15],taps[39]});
end
localparam signed [15:0] C_8=16'hfecb;
wire signed [32:0] raw_8;
assign raw_8=$signed(pair_8)*C_8;
wire signed [37:0] extended_8=raw_8;
reg signed [37:0] product_8;
always @(posedge clk) begin
 if(rst) product_8<=38'sd0;
 else product_8<=extended_8<<<0;
end
reg signed [16:0] pair_9;
always @(posedge clk) begin
 if(rst) pair_9<=17'sd0;
 else pair_9<=$signed({taps[9][15],taps[9]})+$signed({taps[38][15],taps[38]});
end
localparam signed [3:0] C_9=4'h0;
wire signed [20:0] raw_9;
assign raw_9=$signed(pair_9)*C_9;
wire signed [37:0] extended_9=raw_9;
reg signed [37:0] product_9;
always @(posedge clk) begin
 if(rst) product_9<=38'sd0;
 else product_9<=extended_9<<<12;
end
reg signed [16:0] pair_10;
always @(posedge clk) begin
 if(rst) pair_10<=17'sd0;
 else pair_10<=$signed({taps[10][15],taps[10]})+$signed({taps[37][15],taps[37]});
end
localparam signed [15:0] C_10=16'h191;
wire signed [32:0] raw_10;
assign raw_10=$signed(pair_10)*C_10;
wire signed [37:0] extended_10=raw_10;
reg signed [37:0] product_10;
always @(posedge clk) begin
 if(rst) product_10<=38'sd0;
 else product_10<=extended_10<<<0;
end
reg signed [16:0] pair_11;
always @(posedge clk) begin
 if(rst) pair_11<=17'sd0;
 else pair_11<=$signed({taps[11][15],taps[11]})+$signed({taps[36][15],taps[36]});
end
localparam signed [7:0] C_11=8'h2;
wire signed [24:0] raw_11;
assign raw_11=$signed(pair_11)*C_11;
wire signed [37:0] extended_11=raw_11;
reg signed [37:0] product_11;
always @(posedge clk) begin
 if(rst) product_11<=38'sd0;
 else product_11<=extended_11<<<8;
end
reg signed [16:0] pair_12;
always @(posedge clk) begin
 if(rst) pair_12<=17'sd0;
 else pair_12<=$signed({taps[12][15],taps[12]})+$signed({taps[35][15],taps[35]});
end
localparam signed [3:0] C_12=4'h0;
wire signed [20:0] raw_12;
assign raw_12=$signed(pair_12)*C_12;
wire signed [37:0] extended_12=raw_12;
reg signed [37:0] product_12;
always @(posedge clk) begin
 if(rst) product_12<=38'sd0;
 else product_12<=extended_12<<<12;
end
reg signed [16:0] pair_13;
always @(posedge clk) begin
 if(rst) pair_13<=17'sd0;
 else pair_13<=$signed({taps[13][15],taps[13]})+$signed({taps[34][15],taps[34]});
end
localparam signed [15:0] C_13=16'hfd5f;
wire signed [32:0] raw_13;
assign raw_13=$signed(pair_13)*C_13;
wire signed [37:0] extended_13=raw_13;
reg signed [37:0] product_13;
always @(posedge clk) begin
 if(rst) product_13<=38'sd0;
 else product_13<=extended_13<<<0;
end
reg signed [16:0] pair_14;
always @(posedge clk) begin
 if(rst) pair_14<=17'sd0;
 else pair_14<=$signed({taps[14][15],taps[14]})+$signed({taps[33][15],taps[33]});
end
localparam signed [15:0] C_14=16'hfd59;
wire signed [32:0] raw_14;
assign raw_14=$signed(pair_14)*C_14;
wire signed [37:0] extended_14=raw_14;
reg signed [37:0] product_14;
always @(posedge clk) begin
 if(rst) product_14<=38'sd0;
 else product_14<=extended_14<<<0;
end
reg signed [16:0] pair_15;
always @(posedge clk) begin
 if(rst) pair_15<=17'sd0;
 else pair_15<=$signed({taps[15][15],taps[15]})+$signed({taps[32][15],taps[32]});
end
localparam signed [15:0] C_15=16'hb4;
wire signed [32:0] raw_15;
assign raw_15=$signed(pair_15)*C_15;
wire signed [37:0] extended_15=raw_15;
reg signed [37:0] product_15;
always @(posedge clk) begin
 if(rst) product_15<=38'sd0;
 else product_15<=extended_15<<<0;
end
reg signed [16:0] pair_16;
always @(posedge clk) begin
 if(rst) pair_16<=17'sd0;
 else pair_16<=$signed({taps[16][15],taps[16]})+$signed({taps[31][15],taps[31]});
end
localparam signed [15:0] C_16=16'h477;
wire signed [32:0] raw_16;
assign raw_16=$signed(pair_16)*C_16;
wire signed [37:0] extended_16=raw_16;
reg signed [37:0] product_16;
always @(posedge clk) begin
 if(rst) product_16<=38'sd0;
 else product_16<=extended_16<<<0;
end
reg signed [16:0] pair_17;
always @(posedge clk) begin
 if(rst) pair_17<=17'sd0;
 else pair_17<=$signed({taps[17][15],taps[17]})+$signed({taps[30][15],taps[30]});
end
localparam signed [7:0] C_17=8'h4;
wire signed [24:0] raw_17;
assign raw_17=$signed(pair_17)*C_17;
wire signed [37:0] extended_17=raw_17;
reg signed [37:0] product_17;
always @(posedge clk) begin
 if(rst) product_17<=38'sd0;
 else product_17<=extended_17<<<8;
end
reg signed [16:0] pair_18;
always @(posedge clk) begin
 if(rst) pair_18<=17'sd0;
 else pair_18<=$signed({taps[18][15],taps[18]})+$signed({taps[29][15],taps[29]});
end
localparam signed [7:0] C_18=8'hfe;
wire signed [24:0] raw_18;
assign raw_18=$signed(pair_18)*C_18;
wire signed [37:0] extended_18=raw_18;
reg signed [37:0] product_18;
always @(posedge clk) begin
 if(rst) product_18<=38'sd0;
 else product_18<=extended_18<<<8;
end
reg signed [16:0] pair_19;
always @(posedge clk) begin
 if(rst) pair_19<=17'sd0;
 else pair_19<=$signed({taps[19][15],taps[19]})+$signed({taps[28][15],taps[28]});
end
localparam signed [15:0] C_19=16'hf78f;
wire signed [32:0] raw_19;
assign raw_19=$signed(pair_19)*C_19;
wire signed [37:0] extended_19=raw_19;
reg signed [37:0] product_19;
always @(posedge clk) begin
 if(rst) product_19<=38'sd0;
 else product_19<=extended_19<<<0;
end
reg signed [16:0] pair_20;
always @(posedge clk) begin
 if(rst) pair_20<=17'sd0;
 else pair_20<=$signed({taps[20][15],taps[20]})+$signed({taps[27][15],taps[27]});
end
localparam signed [7:0] C_20=8'hf9;
wire signed [24:0] raw_20;
assign raw_20=$signed(pair_20)*C_20;
wire signed [37:0] extended_20=raw_20;
reg signed [37:0] product_20;
always @(posedge clk) begin
 if(rst) product_20<=38'sd0;
 else product_20<=extended_20<<<8;
end
reg signed [16:0] pair_21;
always @(posedge clk) begin
 if(rst) pair_21<=17'sd0;
 else pair_21<=$signed({taps[21][15],taps[21]})+$signed({taps[26][15],taps[26]});
end
localparam signed [15:0] C_21=16'h68f;
wire signed [32:0] raw_21;
assign raw_21=$signed(pair_21)*C_21;
wire signed [37:0] extended_21=raw_21;
reg signed [37:0] product_21;
always @(posedge clk) begin
 if(rst) product_21<=38'sd0;
 else product_21<=extended_21<<<0;
end
reg signed [16:0] pair_22;
always @(posedge clk) begin
 if(rst) pair_22<=17'sd0;
 else pair_22<=$signed({taps[22][15],taps[22]})+$signed({taps[25][15],taps[25]});
end
localparam signed [7:0] C_22=8'h1b;
wire signed [24:0] raw_22;
assign raw_22=$signed(pair_22)*C_22;
wire signed [37:0] extended_22=raw_22;
reg signed [37:0] product_22;
always @(posedge clk) begin
 if(rst) product_22<=38'sd0;
 else product_22<=extended_22<<<8;
end
reg signed [16:0] pair_23;
always @(posedge clk) begin
 if(rst) pair_23<=17'sd0;
 else pair_23<=$signed({taps[23][15],taps[23]})+$signed({taps[24][15],taps[24]});
end
localparam signed [7:0] C_23=8'h2a;
wire signed [24:0] raw_23;
assign raw_23=$signed(pair_23)*C_23;
wire signed [37:0] extended_23=raw_23;
reg signed [37:0] product_23;
always @(posedge clk) begin
 if(rst) product_23<=38'sd0;
 else product_23<=extended_23<<<8;
end
reg signed [37:0] sum_1_0;
always @(posedge clk) begin
 if(rst) sum_1_0<=38'sd0;
 else sum_1_0<=product_0+product_1;
end
reg signed [37:0] sum_1_1;
always @(posedge clk) begin
 if(rst) sum_1_1<=38'sd0;
 else sum_1_1<=product_2+product_3;
end
reg signed [37:0] sum_1_2;
always @(posedge clk) begin
 if(rst) sum_1_2<=38'sd0;
 else sum_1_2<=product_4+product_5;
end
reg signed [37:0] sum_1_3;
always @(posedge clk) begin
 if(rst) sum_1_3<=38'sd0;
 else sum_1_3<=product_6+product_7;
end
reg signed [37:0] sum_1_4;
always @(posedge clk) begin
 if(rst) sum_1_4<=38'sd0;
 else sum_1_4<=product_8+product_9;
end
reg signed [37:0] sum_1_5;
always @(posedge clk) begin
 if(rst) sum_1_5<=38'sd0;
 else sum_1_5<=product_10+product_11;
end
reg signed [37:0] sum_1_6;
always @(posedge clk) begin
 if(rst) sum_1_6<=38'sd0;
 else sum_1_6<=product_12+product_13;
end
reg signed [37:0] sum_1_7;
always @(posedge clk) begin
 if(rst) sum_1_7<=38'sd0;
 else sum_1_7<=product_14+product_15;
end
reg signed [37:0] sum_1_8;
always @(posedge clk) begin
 if(rst) sum_1_8<=38'sd0;
 else sum_1_8<=product_16+product_17;
end
reg signed [37:0] sum_1_9;
always @(posedge clk) begin
 if(rst) sum_1_9<=38'sd0;
 else sum_1_9<=product_18+product_19;
end
reg signed [37:0] sum_1_10;
always @(posedge clk) begin
 if(rst) sum_1_10<=38'sd0;
 else sum_1_10<=product_20+product_21;
end
reg signed [37:0] sum_1_11;
always @(posedge clk) begin
 if(rst) sum_1_11<=38'sd0;
 else sum_1_11<=product_22+product_23;
end
reg signed [37:0] sum_1_12;
always @(posedge clk) begin
 if(rst) sum_1_12<=38'sd0;
 else sum_1_12<=38'sd0+38'sd0;
end
reg signed [37:0] sum_1_13;
always @(posedge clk) begin
 if(rst) sum_1_13<=38'sd0;
 else sum_1_13<=38'sd0+38'sd0;
end
reg signed [37:0] sum_1_14;
always @(posedge clk) begin
 if(rst) sum_1_14<=38'sd0;
 else sum_1_14<=38'sd0+38'sd0;
end
reg signed [37:0] sum_1_15;
always @(posedge clk) begin
 if(rst) sum_1_15<=38'sd0;
 else sum_1_15<=38'sd0+38'sd0;
end
reg signed [37:0] sum_2_0;
always @(posedge clk) begin
 if(rst) sum_2_0<=38'sd0;
 else sum_2_0<=sum_1_0+sum_1_1;
end
reg signed [37:0] sum_2_1;
always @(posedge clk) begin
 if(rst) sum_2_1<=38'sd0;
 else sum_2_1<=sum_1_2+sum_1_3;
end
reg signed [37:0] sum_2_2;
always @(posedge clk) begin
 if(rst) sum_2_2<=38'sd0;
 else sum_2_2<=sum_1_4+sum_1_5;
end
reg signed [37:0] sum_2_3;
always @(posedge clk) begin
 if(rst) sum_2_3<=38'sd0;
 else sum_2_3<=sum_1_6+sum_1_7;
end
reg signed [37:0] sum_2_4;
always @(posedge clk) begin
 if(rst) sum_2_4<=38'sd0;
 else sum_2_4<=sum_1_8+sum_1_9;
end
reg signed [37:0] sum_2_5;
always @(posedge clk) begin
 if(rst) sum_2_5<=38'sd0;
 else sum_2_5<=sum_1_10+sum_1_11;
end
reg signed [37:0] sum_2_6;
always @(posedge clk) begin
 if(rst) sum_2_6<=38'sd0;
 else sum_2_6<=sum_1_12+sum_1_13;
end
reg signed [37:0] sum_2_7;
always @(posedge clk) begin
 if(rst) sum_2_7<=38'sd0;
 else sum_2_7<=sum_1_14+sum_1_15;
end
reg signed [37:0] sum_3_0;
always @(posedge clk) begin
 if(rst) sum_3_0<=38'sd0;
 else sum_3_0<=sum_2_0+sum_2_1;
end
reg signed [37:0] sum_3_1;
always @(posedge clk) begin
 if(rst) sum_3_1<=38'sd0;
 else sum_3_1<=sum_2_2+sum_2_3;
end
reg signed [37:0] sum_3_2;
always @(posedge clk) begin
 if(rst) sum_3_2<=38'sd0;
 else sum_3_2<=sum_2_4+sum_2_5;
end
reg signed [37:0] sum_3_3;
always @(posedge clk) begin
 if(rst) sum_3_3<=38'sd0;
 else sum_3_3<=sum_2_6+sum_2_7;
end
reg signed [37:0] sum_4_0;
always @(posedge clk) begin
 if(rst) sum_4_0<=38'sd0;
 else sum_4_0<=sum_3_0+sum_3_1;
end
reg signed [37:0] sum_4_1;
always @(posedge clk) begin
 if(rst) sum_4_1<=38'sd0;
 else sum_4_1<=sum_3_2+sum_3_3;
end
reg signed [37:0] sum_5_0;
always @(posedge clk) begin
 if(rst) sum_5_0<=38'sd0;
 else sum_5_0<=sum_4_0+sum_4_1;
end
assign data_out=sum_5_0;
assign valid_out=valid_pipe[7];
endmodule
