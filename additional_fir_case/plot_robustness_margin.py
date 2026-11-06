"""Draw all 15 corrected design/quota results without fitted or invented values."""
from pathlib import Path
import csv
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

ROOT = Path(__file__).resolve().parents[1]
rows = list(csv.DictReader((ROOT / 'data/robustness_study_corrected/robustness_results.csv').open()))
lookup = {(r['case_label'], int(r['quota_id']), r['method']): r for r in rows}
plt.rcParams.update({'font.family':'serif', 'font.serif':['Times New Roman'],
    'font.size':8, 'mathtext.fontset':'stix', 'pdf.fonttype':42, 'svg.fonttype':'none',
    'axes.linewidth':.6})
fig, ax = plt.subplots(figsize=(7.1,2.85))
fig.subplots_adjust(left=.30,right=.975,bottom=.19,top=.84)
colors = {'DP':'#0072B2', 'greedy':'#D55E00'}
markers = {'DP':'o', 'greedy':'^'}
labels=[]; exported=[]; passes={'DP':0,'greedy':0}
for ci, case in enumerate('ABCDE'):
    for quota in range(1,4):
        y=ci*3+quota-1
        pair=[lookup[case,quota,m] for m in ['DP','greedy']]
        margins=[float(r['stop_limit_db'])-float(r['stopband_peak_db']) for r in pair]
        ax.plot(margins,[y,y],color='.65',lw=.8,zorder=1)
        for r,margin in zip(pair,margins):
            m=r['method']; pb=float(r['passband_max_abs_db'])>.25
            assert bool(int(r['meets_spec'])) == (margin>=0 and not pb)
            passes[m]+=int(r['meets_spec'])
            # Hollow triangle leaves coincident DP circles visible.
            ax.plot(margin,y,marker=markers[m],ms=5.2 if m=='DP' else 6.2,
                markerfacecolor=colors[m] if m=='DP' else 'white',
                markeredgecolor=colors[m],mew=.9,linestyle='none',zorder=3 if m=='greedy' else 2)
            if pb:
                ax.annotate('*',(margin,y),xytext=(4,4 if m=='DP' else -5),textcoords='offset points',color=colors[m],fontsize=9)
            exported.append(dict(case=case,quota_id=quota,method=m,margin_db=margin,
                passband_max_abs_db=r['passband_max_abs_db'],meets_spec=r['meets_spec']))
        labels.append('['+', '.join(pair[0][k] for k in ['n16','n8','n4'])+']')
    r=pair[0]
    ax.text(-.34,ci*3+1,f"{case}: {r['n_taps']} taps\n{float(r['stop_limit_db']):.0f} dB limit",
        transform=ax.get_yaxis_transform(),ha='left',va='center',fontsize=8)
    if ci<4: ax.axhline(ci*3+2.5,color='.8',lw=.6)
assert passes=={'DP':2,'greedy':0}
ax.axvline(0,color='.2',lw=.9)
ax.set(xlim=(-20,3),ylim=(14.65,-.65),yticks=range(15),yticklabels=labels,
    xticks=[-20,-15,-10,-5,0],xlabel='Stopband specification margin (dB)')
ax.set_axisbelow(True); ax.grid(axis='x',color='.9',lw=.5)
ax.tick_params(axis='y',length=0,pad=6); ax.tick_params(axis='x',direction='in')
ax.text(.01,1.025,'Fails stopband limit',transform=ax.transAxes,ha='left')
ax.text(.99,1.025,'Meets limit',transform=ax.transAxes,ha='right')
handles=[Line2D([],[],marker=markers[m],color=colors[m],ls='none',
    markerfacecolor=colors[m] if m=='DP' else 'white',label='DP' if m=='DP' else 'Greedy') for m in colors]
fig.legend(handles=handles,loc='upper center',bbox_to_anchor=(.60,.99),ncol=2,frameon=False)
fig.text(.015,.025,'Quota counts are [16-bit, 8-bit, 4-bit].  * Passband deviation > 0.25 dB.',fontsize=7.5)
out=ROOT/'paper/figures'; out.mkdir(exist_ok=True)
for ext in ['pdf','svg','png']: fig.savefig(out/f'robustness_margin.{ext}',dpi=450)
with (out/'robustness_margin_data.csv').open('w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=exported[0].keys());w.writeheader();w.writerows(exported)
print('Verified 15 pairs; overall passes:',passes)
