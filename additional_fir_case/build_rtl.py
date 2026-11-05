"""Generate isolated folded/direct 48-tap RTL and independent reference vectors."""
import csv
import hashlib
import json
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "rtl"
OUT.mkdir(exist_ok=True)
with (ROOT / "results_matlab/allocations.csv").open(newline="") as f:
    rows = [r for r in csv.DictReader(f) if r["quota_id"] == "1"]
assert len(rows) == 48
configs = {}
for name in ("dp", "greedy"):
    widths = [int(r[f"{name}_width"]) for r in rows]
    values = [round(float(r[f"{name}_coefficient"])*2**(w-1))
              for r,w in zip(rows,widths)]
    configs[name] = widths,values
for name,width in (("all16",16),("all8",8)):
    def matlab_round(x):
        return int(abs(x)+0.5)*(-1 if x<0 else 1)
    configs[name] = [width]*48,[
        matlab_round(float(r["ideal_coefficient"])*2**(width-1)) for r in rows]
for widths,values in configs.values():
    aligned = [v<<(16-w) for w,v in zip(widths,values)]
    assert aligned == aligned[::-1]
    assert all(-2**(w-1)<=v<2**(w-1) for w,v in zip(widths,values))
tops = []
for name,(widths,values) in configs.items():
    for folded in (True,False):
        top = f"fir48_{name}_{'folded' if folded else 'direct'}"
        tops.append(top)
        terms,leaves = (24,32) if folded else (48,64)
        levels = leaves.bit_length()-1
        lines = [
            "~BT~timescale 1ns/1ps",
            f"module {top}(input wire clk,rst,en,",
            "input wire signed [15:0] data_in,",
            "output wire signed [37:0] data_out,output wire valid_out);",
            "// Eight pipeline stages: accepted edge t -> valid edge t+7.",
            "// Input has 14 fractional bits; aligned output has 29.",
            "reg signed [15:0] taps[0:47];",
            "reg [7:0] valid_pipe; integer i;",
            "always @(posedge clk) begin",
            " if(rst) begin",
            "  for(i=0;i<48;i=i+1) taps[i]<=16'sd0;",
            "  valid_pipe<=8'd0;",
            " end else begin",
            "  valid_pipe<={valid_pipe[6:0],en};",
            "  if(en) begin",
            "   taps[0]<=data_in;",
            "   for(i=1;i<48;i=i+1) taps[i]<=taps[i-1];",
            "  end",
            " end",
            "end",
        ]
        for k in range(terms):
            w,v = widths[k],values[k]
            operand = f"pair_{k}" if folded else f"taps[{k}]"
            raw_width = (17 if folded else 16)+w
            if folded:
                lines += [
                    f"reg signed [16:0] pair_{k};",
                    "always @(posedge clk) begin",
                    f" if(rst) pair_{k}<=17'sd0;",
                    f" else pair_{k}<=$signed({{taps[{k}][15],taps[{k}]}})"
                    f"+$signed({{taps[{47-k}][15],taps[{47-k}]}});",
                    "end",
                ]
            lines += [
                f"localparam signed [{w-1}:0] C_{k}={w}'h{v&((1<<w)-1):x};",
                f"wire signed [{raw_width-1}:0] raw_{k};",
                f"assign raw_{k}=$signed({operand})*C_{k};",
                f"wire signed [37:0] extended_{k}=raw_{k};",
                f"reg signed [37:0] product_{k};",
                "always @(posedge clk) begin",
                f" if(rst) product_{k}<=38'sd0;",
                f" else product_{k}<=extended_{k}<<<{16-w};",
                "end",
            ]
        for level in range(1,levels+1):
            for k in range(leaves>>level):
                operands = []
                for child in (2*k,2*k+1):
                    operands.append(
                        f"product_{child}" if level==1 and child<terms else
                        "38'sd0" if level==1 else f"sum_{level-1}_{child}")
                lines += [f"reg signed [37:0] sum_{level}_{k};",
                          "always @(posedge clk) begin",
                          f" if(rst) sum_{level}_{k}<=38'sd0;",
                          f" else sum_{level}_{k}<={operands[0]}+{operands[1]};",
                          "end"]
        lines += [f"assign data_out=sum_{levels}_0;",
                  "assign valid_out=valid_pipe[7];","endmodule"]
        (OUT/f"{top}.v").write_text("\n".join(lines).replace("~BT~",chr(96))+"\n")

# Independent full convolution (48 terms), not the folded arithmetic.
rng = random.Random(20261105)
cycles = []
for t in range(2500):
    rst = int(t<4 or t in (177,178,1001,2003))
    en = int(t>=4 and (t<110 or rng.random()>0.25))
    if t<52:
        value = 32767 if t==4 else 0
    elif t<110:
        value = -32768 if t%2 else 32767
    else:
        value = rng.randint(-32768,32767)
    if t>=2470:
        en = 0
    cycles.append((rst,en,value))
stim = [(r<<17)|(e<<16)|(v&65535) for r,e,v in cycles]
(OUT/"stimulus.hex").write_text("".join(f"{v:05x}\n" for v in stim))
for name,(widths,values) in configs.items():
    aligned = [v<<(16-w) for w,v in zip(widths,values)]
    history = [0]*48
    pending = deque([(0,0)]*7)
    expected = []
    for rst,en,value in cycles:
        if rst:
            history = [0]*48
            pending = deque([(0,0)]*7)
            valid,result = 0,0
        else:
            if en:
                history = [value]+history[:-1]
            now = sum(x*c for x,c in zip(history,aligned))
            assert -(1<<37)<=now<(1<<37)
            pending.append((en,now))
            valid,result = pending.popleft()
        expected.append((valid<<38)|(result&((1<<38)-1)))
    (OUT/f"expected_{name}.hex").write_text(
        "".join(f"{v:010x}\n" for v in expected))
    valid_count = sum(v>>38 for v in expected)
tb = ["~BT~timescale 1ns/1ps","module tb_fir48;",
      "reg clk=0; always #5 clk=~clk;","reg rst=1,en=0;",
      "reg signed [15:0] data_in=0;","reg [17:0] stimulus[0:2499];",
      "integer t,checks=0;"]
for name in configs:
    tb.append(f"reg [38:0] expected_{name}[0:2499];")
for top in tops:
    tb += [f"wire signed [37:0] y_{top}; wire v_{top};",
           f"{top} dut_{top}(.clk(clk),.rst(rst),.en(en),.data_in(data_in),"
           f".data_out(y_{top}),.valid_out(v_{top}));"]
tb += ["initial begin",'$readmemh("stimulus.hex",stimulus);']
for name in configs:
    tb.append(f'$readmemh("expected_{name}.hex",expected_{name});')
tb += ["for(t=0;t<2500;t=t+1) begin"," @(negedge clk);",
       " {rst,en,data_in}=stimulus[t];"," @(posedge clk); #1;"]
for top in tops:
    name = top.split("_")[1]
    tb += [f" if(v_{top}!==expected_{name}[t][38])",
           f'  $fatal(1,"valid mismatch {top} cycle %0d",t);',
           f" if(expected_{name}[t][38]) begin",
           f"  if(y_{top}!==expected_{name}[t][37:0])",
           f'   $fatal(1,"data mismatch {top} cycle %0d",t);',
           "  checks=checks+1;"," end"]
tb += ["end",f"if(checks!={valid_count*len(tops)}) "
       '$fatal(1,"unexpected check count");',
       '$display("FIR48 ALL TESTS PASSED: %0d valid-output comparisons",checks);',
       "$finish;","end","endmodule"]
(OUT/"tb_fir48.sv").write_text("\n".join(tb).replace("~BT~",chr(96))+"\n")
manifest = {"cycles":2500,"tops":tops,"valid_outputs_per_top":valid_count,
            "mixed_quota":[24,16,8],"output_bits":38,"fraction_bits":29,
            "folding_condition":"Aligned coefficient values symmetric; zero coefficient width labels can differ.",
            "latency_edge_difference":7,"measured_hardware":False,
            "hashes":{p.name:hashlib.sha256(p.read_bytes()).hexdigest()
                      for p in sorted(OUT.iterdir())
                      if p.is_file() and p.name!="manifest.json"}}
(OUT/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n")
print(f"Generated {len(tops)} tops; {valid_count} expected valid outputs/top.")
