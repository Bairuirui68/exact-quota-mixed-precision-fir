`timescale 1ns/1ps
module fir48_dp_direct(input wire clk,rst,en,
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
localparam signed [3:0] C_0=4'h0;
wire signed [19:0] raw_0;
assign raw_0=$signed(taps[0])*C_0;
wire signed [37:0] extended_0=raw_0;
reg signed [37:0] product_0;
always @(posedge clk) begin
 if(rst) product_0<=38'sd0;
 else product_0<=extended_0<<<12;
end
localparam signed [15:0] C_1=16'hff89;
wire signed [31:0] raw_1;
assign raw_1=$signed(taps[1])*C_1;
wire signed [37:0] extended_1=raw_1;
reg signed [37:0] product_1;
always @(posedge clk) begin
 if(rst) product_1<=38'sd0;
 else product_1<=extended_1<<<0;
end
localparam signed [15:0] C_2=16'hff7b;
wire signed [31:0] raw_2;
assign raw_2=$signed(taps[2])*C_2;
wire signed [37:0] extended_2=raw_2;
reg signed [37:0] product_2;
always @(posedge clk) begin
 if(rst) product_2<=38'sd0;
 else product_2<=extended_2<<<0;
end
localparam signed [3:0] C_3=4'h0;
wire signed [19:0] raw_3;
assign raw_3=$signed(taps[3])*C_3;
wire signed [37:0] extended_3=raw_3;
reg signed [37:0] product_3;
always @(posedge clk) begin
 if(rst) product_3<=38'sd0;
 else product_3<=extended_3<<<12;
end
localparam signed [15:0] C_4=16'h7d;
wire signed [31:0] raw_4;
assign raw_4=$signed(taps[4])*C_4;
wire signed [37:0] extended_4=raw_4;
reg signed [37:0] product_4;
always @(posedge clk) begin
 if(rst) product_4<=38'sd0;
 else product_4<=extended_4<<<0;
end
localparam signed [15:0] C_5=16'hc3;
wire signed [31:0] raw_5;
assign raw_5=$signed(taps[5])*C_5;
wire signed [37:0] extended_5=raw_5;
reg signed [37:0] product_5;
always @(posedge clk) begin
 if(rst) product_5<=38'sd0;
 else product_5<=extended_5<<<0;
end
localparam signed [3:0] C_6=4'h0;
wire signed [19:0] raw_6;
assign raw_6=$signed(taps[6])*C_6;
wire signed [37:0] extended_6=raw_6;
reg signed [37:0] product_6;
always @(posedge clk) begin
 if(rst) product_6<=38'sd0;
 else product_6<=extended_6<<<12;
end
localparam signed [7:0] C_7=8'hff;
wire signed [23:0] raw_7;
assign raw_7=$signed(taps[7])*C_7;
wire signed [37:0] extended_7=raw_7;
reg signed [37:0] product_7;
always @(posedge clk) begin
 if(rst) product_7<=38'sd0;
 else product_7<=extended_7<<<8;
end
localparam signed [15:0] C_8=16'hfecb;
wire signed [31:0] raw_8;
assign raw_8=$signed(taps[8])*C_8;
wire signed [37:0] extended_8=raw_8;
reg signed [37:0] product_8;
always @(posedge clk) begin
 if(rst) product_8<=38'sd0;
 else product_8<=extended_8<<<0;
end
localparam signed [3:0] C_9=4'h0;
wire signed [19:0] raw_9;
assign raw_9=$signed(taps[9])*C_9;
wire signed [37:0] extended_9=raw_9;
reg signed [37:0] product_9;
always @(posedge clk) begin
 if(rst) product_9<=38'sd0;
 else product_9<=extended_9<<<12;
end
localparam signed [15:0] C_10=16'h191;
wire signed [31:0] raw_10;
assign raw_10=$signed(taps[10])*C_10;
wire signed [37:0] extended_10=raw_10;
reg signed [37:0] product_10;
always @(posedge clk) begin
 if(rst) product_10<=38'sd0;
 else product_10<=extended_10<<<0;
end
localparam signed [7:0] C_11=8'h2;
wire signed [23:0] raw_11;
assign raw_11=$signed(taps[11])*C_11;
wire signed [37:0] extended_11=raw_11;
reg signed [37:0] product_11;
always @(posedge clk) begin
 if(rst) product_11<=38'sd0;
 else product_11<=extended_11<<<8;
end
localparam signed [3:0] C_12=4'h0;
wire signed [19:0] raw_12;
assign raw_12=$signed(taps[12])*C_12;
wire signed [37:0] extended_12=raw_12;
reg signed [37:0] product_12;
always @(posedge clk) begin
 if(rst) product_12<=38'sd0;
 else product_12<=extended_12<<<12;
end
localparam signed [15:0] C_13=16'hfd5f;
wire signed [31:0] raw_13;
assign raw_13=$signed(taps[13])*C_13;
wire signed [37:0] extended_13=raw_13;
reg signed [37:0] product_13;
always @(posedge clk) begin
 if(rst) product_13<=38'sd0;
 else product_13<=extended_13<<<0;
end
localparam signed [15:0] C_14=16'hfd59;
wire signed [31:0] raw_14;
assign raw_14=$signed(taps[14])*C_14;
wire signed [37:0] extended_14=raw_14;
reg signed [37:0] product_14;
always @(posedge clk) begin
 if(rst) product_14<=38'sd0;
 else product_14<=extended_14<<<0;
end
localparam signed [15:0] C_15=16'hb4;
wire signed [31:0] raw_15;
assign raw_15=$signed(taps[15])*C_15;
wire signed [37:0] extended_15=raw_15;
reg signed [37:0] product_15;
always @(posedge clk) begin
 if(rst) product_15<=38'sd0;
 else product_15<=extended_15<<<0;
end
localparam signed [15:0] C_16=16'h477;
wire signed [31:0] raw_16;
assign raw_16=$signed(taps[16])*C_16;
wire signed [37:0] extended_16=raw_16;
reg signed [37:0] product_16;
always @(posedge clk) begin
 if(rst) product_16<=38'sd0;
 else product_16<=extended_16<<<0;
end
localparam signed [7:0] C_17=8'h4;
wire signed [23:0] raw_17;
assign raw_17=$signed(taps[17])*C_17;
wire signed [37:0] extended_17=raw_17;
reg signed [37:0] product_17;
always @(posedge clk) begin
 if(rst) product_17<=38'sd0;
 else product_17<=extended_17<<<8;
end
localparam signed [7:0] C_18=8'hfe;
wire signed [23:0] raw_18;
assign raw_18=$signed(taps[18])*C_18;
wire signed [37:0] extended_18=raw_18;
reg signed [37:0] product_18;
always @(posedge clk) begin
 if(rst) product_18<=38'sd0;
 else product_18<=extended_18<<<8;
end
localparam signed [15:0] C_19=16'hf78f;
wire signed [31:0] raw_19;
assign raw_19=$signed(taps[19])*C_19;
wire signed [37:0] extended_19=raw_19;
reg signed [37:0] product_19;
always @(posedge clk) begin
 if(rst) product_19<=38'sd0;
 else product_19<=extended_19<<<0;
end
localparam signed [7:0] C_20=8'hf9;
wire signed [23:0] raw_20;
assign raw_20=$signed(taps[20])*C_20;
wire signed [37:0] extended_20=raw_20;
reg signed [37:0] product_20;
always @(posedge clk) begin
 if(rst) product_20<=38'sd0;
 else product_20<=extended_20<<<8;
end
localparam signed [15:0] C_21=16'h68f;
wire signed [31:0] raw_21;
assign raw_21=$signed(taps[21])*C_21;
wire signed [37:0] extended_21=raw_21;
reg signed [37:0] product_21;
always @(posedge clk) begin
 if(rst) product_21<=38'sd0;
 else product_21<=extended_21<<<0;
end
localparam signed [7:0] C_22=8'h1b;
wire signed [23:0] raw_22;
assign raw_22=$signed(taps[22])*C_22;
wire signed [37:0] extended_22=raw_22;
reg signed [37:0] product_22;
always @(posedge clk) begin
 if(rst) product_22<=38'sd0;
 else product_22<=extended_22<<<8;
end
localparam signed [7:0] C_23=8'h2a;
wire signed [23:0] raw_23;
assign raw_23=$signed(taps[23])*C_23;
wire signed [37:0] extended_23=raw_23;
reg signed [37:0] product_23;
always @(posedge clk) begin
 if(rst) product_23<=38'sd0;
 else product_23<=extended_23<<<8;
end
localparam signed [7:0] C_24=8'h2a;
wire signed [23:0] raw_24;
assign raw_24=$signed(taps[24])*C_24;
wire signed [37:0] extended_24=raw_24;
reg signed [37:0] product_24;
always @(posedge clk) begin
 if(rst) product_24<=38'sd0;
 else product_24<=extended_24<<<8;
end
localparam signed [7:0] C_25=8'h1b;
wire signed [23:0] raw_25;
assign raw_25=$signed(taps[25])*C_25;
wire signed [37:0] extended_25=raw_25;
reg signed [37:0] product_25;
always @(posedge clk) begin
 if(rst) product_25<=38'sd0;
 else product_25<=extended_25<<<8;
end
localparam signed [15:0] C_26=16'h68f;
wire signed [31:0] raw_26;
assign raw_26=$signed(taps[26])*C_26;
wire signed [37:0] extended_26=raw_26;
reg signed [37:0] product_26;
always @(posedge clk) begin
 if(rst) product_26<=38'sd0;
 else product_26<=extended_26<<<0;
end
localparam signed [7:0] C_27=8'hf9;
wire signed [23:0] raw_27;
assign raw_27=$signed(taps[27])*C_27;
wire signed [37:0] extended_27=raw_27;
reg signed [37:0] product_27;
always @(posedge clk) begin
 if(rst) product_27<=38'sd0;
 else product_27<=extended_27<<<8;
end
localparam signed [15:0] C_28=16'hf78f;
wire signed [31:0] raw_28;
assign raw_28=$signed(taps[28])*C_28;
wire signed [37:0] extended_28=raw_28;
reg signed [37:0] product_28;
always @(posedge clk) begin
 if(rst) product_28<=38'sd0;
 else product_28<=extended_28<<<0;
end
localparam signed [7:0] C_29=8'hfe;
wire signed [23:0] raw_29;
assign raw_29=$signed(taps[29])*C_29;
wire signed [37:0] extended_29=raw_29;
reg signed [37:0] product_29;
always @(posedge clk) begin
 if(rst) product_29<=38'sd0;
 else product_29<=extended_29<<<8;
end
localparam signed [7:0] C_30=8'h4;
wire signed [23:0] raw_30;
assign raw_30=$signed(taps[30])*C_30;
wire signed [37:0] extended_30=raw_30;
reg signed [37:0] product_30;
always @(posedge clk) begin
 if(rst) product_30<=38'sd0;
 else product_30<=extended_30<<<8;
end
localparam signed [15:0] C_31=16'h477;
wire signed [31:0] raw_31;
assign raw_31=$signed(taps[31])*C_31;
wire signed [37:0] extended_31=raw_31;
reg signed [37:0] product_31;
always @(posedge clk) begin
 if(rst) product_31<=38'sd0;
 else product_31<=extended_31<<<0;
end
localparam signed [15:0] C_32=16'hb4;
wire signed [31:0] raw_32;
assign raw_32=$signed(taps[32])*C_32;
wire signed [37:0] extended_32=raw_32;
reg signed [37:0] product_32;
always @(posedge clk) begin
 if(rst) product_32<=38'sd0;
 else product_32<=extended_32<<<0;
end
localparam signed [15:0] C_33=16'hfd59;
wire signed [31:0] raw_33;
assign raw_33=$signed(taps[33])*C_33;
wire signed [37:0] extended_33=raw_33;
reg signed [37:0] product_33;
always @(posedge clk) begin
 if(rst) product_33<=38'sd0;
 else product_33<=extended_33<<<0;
end
localparam signed [15:0] C_34=16'hfd5f;
wire signed [31:0] raw_34;
assign raw_34=$signed(taps[34])*C_34;
wire signed [37:0] extended_34=raw_34;
reg signed [37:0] product_34;
always @(posedge clk) begin
 if(rst) product_34<=38'sd0;
 else product_34<=extended_34<<<0;
end
localparam signed [3:0] C_35=4'h0;
wire signed [19:0] raw_35;
assign raw_35=$signed(taps[35])*C_35;
wire signed [37:0] extended_35=raw_35;
reg signed [37:0] product_35;
always @(posedge clk) begin
 if(rst) product_35<=38'sd0;
 else product_35<=extended_35<<<12;
end
localparam signed [7:0] C_36=8'h2;
wire signed [23:0] raw_36;
assign raw_36=$signed(taps[36])*C_36;
wire signed [37:0] extended_36=raw_36;
reg signed [37:0] product_36;
always @(posedge clk) begin
 if(rst) product_36<=38'sd0;
 else product_36<=extended_36<<<8;
end
localparam signed [15:0] C_37=16'h191;
wire signed [31:0] raw_37;
assign raw_37=$signed(taps[37])*C_37;
wire signed [37:0] extended_37=raw_37;
reg signed [37:0] product_37;
always @(posedge clk) begin
 if(rst) product_37<=38'sd0;
 else product_37<=extended_37<<<0;
end
localparam signed [3:0] C_38=4'h0;
wire signed [19:0] raw_38;
assign raw_38=$signed(taps[38])*C_38;
wire signed [37:0] extended_38=raw_38;
reg signed [37:0] product_38;
always @(posedge clk) begin
 if(rst) product_38<=38'sd0;
 else product_38<=extended_38<<<12;
end
localparam signed [15:0] C_39=16'hfecb;
wire signed [31:0] raw_39;
assign raw_39=$signed(taps[39])*C_39;
wire signed [37:0] extended_39=raw_39;
reg signed [37:0] product_39;
always @(posedge clk) begin
 if(rst) product_39<=38'sd0;
 else product_39<=extended_39<<<0;
end
localparam signed [7:0] C_40=8'hff;
wire signed [23:0] raw_40;
assign raw_40=$signed(taps[40])*C_40;
wire signed [37:0] extended_40=raw_40;
reg signed [37:0] product_40;
always @(posedge clk) begin
 if(rst) product_40<=38'sd0;
 else product_40<=extended_40<<<8;
end
localparam signed [3:0] C_41=4'h0;
wire signed [19:0] raw_41;
assign raw_41=$signed(taps[41])*C_41;
wire signed [37:0] extended_41=raw_41;
reg signed [37:0] product_41;
always @(posedge clk) begin
 if(rst) product_41<=38'sd0;
 else product_41<=extended_41<<<12;
end
localparam signed [15:0] C_42=16'hc3;
wire signed [31:0] raw_42;
assign raw_42=$signed(taps[42])*C_42;
wire signed [37:0] extended_42=raw_42;
reg signed [37:0] product_42;
always @(posedge clk) begin
 if(rst) product_42<=38'sd0;
 else product_42<=extended_42<<<0;
end
localparam signed [15:0] C_43=16'h7d;
wire signed [31:0] raw_43;
assign raw_43=$signed(taps[43])*C_43;
wire signed [37:0] extended_43=raw_43;
reg signed [37:0] product_43;
always @(posedge clk) begin
 if(rst) product_43<=38'sd0;
 else product_43<=extended_43<<<0;
end
localparam signed [7:0] C_44=8'h0;
wire signed [23:0] raw_44;
assign raw_44=$signed(taps[44])*C_44;
wire signed [37:0] extended_44=raw_44;
reg signed [37:0] product_44;
always @(posedge clk) begin
 if(rst) product_44<=38'sd0;
 else product_44<=extended_44<<<8;
end
localparam signed [15:0] C_45=16'hff7b;
wire signed [31:0] raw_45;
assign raw_45=$signed(taps[45])*C_45;
wire signed [37:0] extended_45=raw_45;
reg signed [37:0] product_45;
always @(posedge clk) begin
 if(rst) product_45<=38'sd0;
 else product_45<=extended_45<<<0;
end
localparam signed [15:0] C_46=16'hff89;
wire signed [31:0] raw_46;
assign raw_46=$signed(taps[46])*C_46;
wire signed [37:0] extended_46=raw_46;
reg signed [37:0] product_46;
always @(posedge clk) begin
 if(rst) product_46<=38'sd0;
 else product_46<=extended_46<<<0;
end
localparam signed [7:0] C_47=8'h0;
wire signed [23:0] raw_47;
assign raw_47=$signed(taps[47])*C_47;
wire signed [37:0] extended_47=raw_47;
reg signed [37:0] product_47;
always @(posedge clk) begin
 if(rst) product_47<=38'sd0;
 else product_47<=extended_47<<<8;
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
 else sum_1_12<=product_24+product_25;
end
reg signed [37:0] sum_1_13;
always @(posedge clk) begin
 if(rst) sum_1_13<=38'sd0;
 else sum_1_13<=product_26+product_27;
end
reg signed [37:0] sum_1_14;
always @(posedge clk) begin
 if(rst) sum_1_14<=38'sd0;
 else sum_1_14<=product_28+product_29;
end
reg signed [37:0] sum_1_15;
always @(posedge clk) begin
 if(rst) sum_1_15<=38'sd0;
 else sum_1_15<=product_30+product_31;
end
reg signed [37:0] sum_1_16;
always @(posedge clk) begin
 if(rst) sum_1_16<=38'sd0;
 else sum_1_16<=product_32+product_33;
end
reg signed [37:0] sum_1_17;
always @(posedge clk) begin
 if(rst) sum_1_17<=38'sd0;
 else sum_1_17<=product_34+product_35;
end
reg signed [37:0] sum_1_18;
always @(posedge clk) begin
 if(rst) sum_1_18<=38'sd0;
 else sum_1_18<=product_36+product_37;
end
reg signed [37:0] sum_1_19;
always @(posedge clk) begin
 if(rst) sum_1_19<=38'sd0;
 else sum_1_19<=product_38+product_39;
end
reg signed [37:0] sum_1_20;
always @(posedge clk) begin
 if(rst) sum_1_20<=38'sd0;
 else sum_1_20<=product_40+product_41;
end
reg signed [37:0] sum_1_21;
always @(posedge clk) begin
 if(rst) sum_1_21<=38'sd0;
 else sum_1_21<=product_42+product_43;
end
reg signed [37:0] sum_1_22;
always @(posedge clk) begin
 if(rst) sum_1_22<=38'sd0;
 else sum_1_22<=product_44+product_45;
end
reg signed [37:0] sum_1_23;
always @(posedge clk) begin
 if(rst) sum_1_23<=38'sd0;
 else sum_1_23<=product_46+product_47;
end
reg signed [37:0] sum_1_24;
always @(posedge clk) begin
 if(rst) sum_1_24<=38'sd0;
 else sum_1_24<=38'sd0+38'sd0;
end
reg signed [37:0] sum_1_25;
always @(posedge clk) begin
 if(rst) sum_1_25<=38'sd0;
 else sum_1_25<=38'sd0+38'sd0;
end
reg signed [37:0] sum_1_26;
always @(posedge clk) begin
 if(rst) sum_1_26<=38'sd0;
 else sum_1_26<=38'sd0+38'sd0;
end
reg signed [37:0] sum_1_27;
always @(posedge clk) begin
 if(rst) sum_1_27<=38'sd0;
 else sum_1_27<=38'sd0+38'sd0;
end
reg signed [37:0] sum_1_28;
always @(posedge clk) begin
 if(rst) sum_1_28<=38'sd0;
 else sum_1_28<=38'sd0+38'sd0;
end
reg signed [37:0] sum_1_29;
always @(posedge clk) begin
 if(rst) sum_1_29<=38'sd0;
 else sum_1_29<=38'sd0+38'sd0;
end
reg signed [37:0] sum_1_30;
always @(posedge clk) begin
 if(rst) sum_1_30<=38'sd0;
 else sum_1_30<=38'sd0+38'sd0;
end
reg signed [37:0] sum_1_31;
always @(posedge clk) begin
 if(rst) sum_1_31<=38'sd0;
 else sum_1_31<=38'sd0+38'sd0;
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
reg signed [37:0] sum_2_8;
always @(posedge clk) begin
 if(rst) sum_2_8<=38'sd0;
 else sum_2_8<=sum_1_16+sum_1_17;
end
reg signed [37:0] sum_2_9;
always @(posedge clk) begin
 if(rst) sum_2_9<=38'sd0;
 else sum_2_9<=sum_1_18+sum_1_19;
end
reg signed [37:0] sum_2_10;
always @(posedge clk) begin
 if(rst) sum_2_10<=38'sd0;
 else sum_2_10<=sum_1_20+sum_1_21;
end
reg signed [37:0] sum_2_11;
always @(posedge clk) begin
 if(rst) sum_2_11<=38'sd0;
 else sum_2_11<=sum_1_22+sum_1_23;
end
reg signed [37:0] sum_2_12;
always @(posedge clk) begin
 if(rst) sum_2_12<=38'sd0;
 else sum_2_12<=sum_1_24+sum_1_25;
end
reg signed [37:0] sum_2_13;
always @(posedge clk) begin
 if(rst) sum_2_13<=38'sd0;
 else sum_2_13<=sum_1_26+sum_1_27;
end
reg signed [37:0] sum_2_14;
always @(posedge clk) begin
 if(rst) sum_2_14<=38'sd0;
 else sum_2_14<=sum_1_28+sum_1_29;
end
reg signed [37:0] sum_2_15;
always @(posedge clk) begin
 if(rst) sum_2_15<=38'sd0;
 else sum_2_15<=sum_1_30+sum_1_31;
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
reg signed [37:0] sum_3_4;
always @(posedge clk) begin
 if(rst) sum_3_4<=38'sd0;
 else sum_3_4<=sum_2_8+sum_2_9;
end
reg signed [37:0] sum_3_5;
always @(posedge clk) begin
 if(rst) sum_3_5<=38'sd0;
 else sum_3_5<=sum_2_10+sum_2_11;
end
reg signed [37:0] sum_3_6;
always @(posedge clk) begin
 if(rst) sum_3_6<=38'sd0;
 else sum_3_6<=sum_2_12+sum_2_13;
end
reg signed [37:0] sum_3_7;
always @(posedge clk) begin
 if(rst) sum_3_7<=38'sd0;
 else sum_3_7<=sum_2_14+sum_2_15;
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
reg signed [37:0] sum_4_2;
always @(posedge clk) begin
 if(rst) sum_4_2<=38'sd0;
 else sum_4_2<=sum_3_4+sum_3_5;
end
reg signed [37:0] sum_4_3;
always @(posedge clk) begin
 if(rst) sum_4_3<=38'sd0;
 else sum_4_3<=sum_3_6+sum_3_7;
end
reg signed [37:0] sum_5_0;
always @(posedge clk) begin
 if(rst) sum_5_0<=38'sd0;
 else sum_5_0<=sum_4_0+sum_4_1;
end
reg signed [37:0] sum_5_1;
always @(posedge clk) begin
 if(rst) sum_5_1<=38'sd0;
 else sum_5_1<=sum_4_2+sum_4_3;
end
reg signed [37:0] sum_6_0;
always @(posedge clk) begin
 if(rst) sum_6_0<=38'sd0;
 else sum_6_0<=sum_5_0+sum_5_1;
end
assign data_out=sum_6_0;
assign valid_out=valid_pipe[7];
endmodule
