`timescale 1ns/1ps
module tb_fir48;
reg clk=0; always #5 clk=~clk;
reg rst=1,en=0;
reg signed [15:0] data_in=0;
reg [17:0] stimulus[0:2499];
integer t,checks=0;
reg [38:0] expected_dp[0:2499];
reg [38:0] expected_greedy[0:2499];
reg [38:0] expected_all16[0:2499];
reg [38:0] expected_all8[0:2499];
wire signed [37:0] y_fir48_dp_folded; wire v_fir48_dp_folded;
fir48_dp_folded dut_fir48_dp_folded(.clk(clk),.rst(rst),.en(en),.data_in(data_in),.data_out(y_fir48_dp_folded),.valid_out(v_fir48_dp_folded));
wire signed [37:0] y_fir48_dp_direct; wire v_fir48_dp_direct;
fir48_dp_direct dut_fir48_dp_direct(.clk(clk),.rst(rst),.en(en),.data_in(data_in),.data_out(y_fir48_dp_direct),.valid_out(v_fir48_dp_direct));
wire signed [37:0] y_fir48_greedy_folded; wire v_fir48_greedy_folded;
fir48_greedy_folded dut_fir48_greedy_folded(.clk(clk),.rst(rst),.en(en),.data_in(data_in),.data_out(y_fir48_greedy_folded),.valid_out(v_fir48_greedy_folded));
wire signed [37:0] y_fir48_greedy_direct; wire v_fir48_greedy_direct;
fir48_greedy_direct dut_fir48_greedy_direct(.clk(clk),.rst(rst),.en(en),.data_in(data_in),.data_out(y_fir48_greedy_direct),.valid_out(v_fir48_greedy_direct));
wire signed [37:0] y_fir48_all16_folded; wire v_fir48_all16_folded;
fir48_all16_folded dut_fir48_all16_folded(.clk(clk),.rst(rst),.en(en),.data_in(data_in),.data_out(y_fir48_all16_folded),.valid_out(v_fir48_all16_folded));
wire signed [37:0] y_fir48_all16_direct; wire v_fir48_all16_direct;
fir48_all16_direct dut_fir48_all16_direct(.clk(clk),.rst(rst),.en(en),.data_in(data_in),.data_out(y_fir48_all16_direct),.valid_out(v_fir48_all16_direct));
wire signed [37:0] y_fir48_all8_folded; wire v_fir48_all8_folded;
fir48_all8_folded dut_fir48_all8_folded(.clk(clk),.rst(rst),.en(en),.data_in(data_in),.data_out(y_fir48_all8_folded),.valid_out(v_fir48_all8_folded));
wire signed [37:0] y_fir48_all8_direct; wire v_fir48_all8_direct;
fir48_all8_direct dut_fir48_all8_direct(.clk(clk),.rst(rst),.en(en),.data_in(data_in),.data_out(y_fir48_all8_direct),.valid_out(v_fir48_all8_direct));
initial begin
$readmemh("stimulus.hex",stimulus);
$readmemh("expected_dp.hex",expected_dp);
$readmemh("expected_greedy.hex",expected_greedy);
$readmemh("expected_all16.hex",expected_all16);
$readmemh("expected_all8.hex",expected_all8);
for(t=0;t<2500;t=t+1) begin
 @(negedge clk);
 {rst,en,data_in}=stimulus[t];
 @(posedge clk); #1;
 if(v_fir48_dp_folded!==expected_dp[t][38])
  $fatal(1,"valid mismatch fir48_dp_folded cycle %0d",t);
 if(expected_dp[t][38]) begin
  if(y_fir48_dp_folded!==expected_dp[t][37:0])
   $fatal(1,"data mismatch fir48_dp_folded cycle %0d",t);
  checks=checks+1;
 end
 if(v_fir48_dp_direct!==expected_dp[t][38])
  $fatal(1,"valid mismatch fir48_dp_direct cycle %0d",t);
 if(expected_dp[t][38]) begin
  if(y_fir48_dp_direct!==expected_dp[t][37:0])
   $fatal(1,"data mismatch fir48_dp_direct cycle %0d",t);
  checks=checks+1;
 end
 if(v_fir48_greedy_folded!==expected_greedy[t][38])
  $fatal(1,"valid mismatch fir48_greedy_folded cycle %0d",t);
 if(expected_greedy[t][38]) begin
  if(y_fir48_greedy_folded!==expected_greedy[t][37:0])
   $fatal(1,"data mismatch fir48_greedy_folded cycle %0d",t);
  checks=checks+1;
 end
 if(v_fir48_greedy_direct!==expected_greedy[t][38])
  $fatal(1,"valid mismatch fir48_greedy_direct cycle %0d",t);
 if(expected_greedy[t][38]) begin
  if(y_fir48_greedy_direct!==expected_greedy[t][37:0])
   $fatal(1,"data mismatch fir48_greedy_direct cycle %0d",t);
  checks=checks+1;
 end
 if(v_fir48_all16_folded!==expected_all16[t][38])
  $fatal(1,"valid mismatch fir48_all16_folded cycle %0d",t);
 if(expected_all16[t][38]) begin
  if(y_fir48_all16_folded!==expected_all16[t][37:0])
   $fatal(1,"data mismatch fir48_all16_folded cycle %0d",t);
  checks=checks+1;
 end
 if(v_fir48_all16_direct!==expected_all16[t][38])
  $fatal(1,"valid mismatch fir48_all16_direct cycle %0d",t);
 if(expected_all16[t][38]) begin
  if(y_fir48_all16_direct!==expected_all16[t][37:0])
   $fatal(1,"data mismatch fir48_all16_direct cycle %0d",t);
  checks=checks+1;
 end
 if(v_fir48_all8_folded!==expected_all8[t][38])
  $fatal(1,"valid mismatch fir48_all8_folded cycle %0d",t);
 if(expected_all8[t][38]) begin
  if(y_fir48_all8_folded!==expected_all8[t][37:0])
   $fatal(1,"data mismatch fir48_all8_folded cycle %0d",t);
  checks=checks+1;
 end
 if(v_fir48_all8_direct!==expected_all8[t][38])
  $fatal(1,"valid mismatch fir48_all8_direct cycle %0d",t);
 if(expected_all8[t][38]) begin
  if(y_fir48_all8_direct!==expected_all8[t][37:0])
   $fatal(1,"data mismatch fir48_all8_direct cycle %0d",t);
  checks=checks+1;
 end
end
if(checks!=14888) $fatal(1,"unexpected check count");
$display("FIR48 ALL TESTS PASSED: %0d valid-output comparisons",checks);
$finish;
end
endmodule
