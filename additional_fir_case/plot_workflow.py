"""Draw a vector overview of the allocation and validation workflow."""
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

out = Path(__file__).resolve().parents[1] / 'paper/figures'
out.mkdir(parents=True, exist_ok=True)
plt.rcParams.update({'font.family':'serif','font.serif':['Times New Roman','STIXGeneral'],
                     'font.size':8,'mathtext.fontset':'stix','pdf.fonttype':42,
                     'svg.fonttype':'none'})
fig, ax = plt.subplots(figsize=(3.5,3.55))
fig.subplots_adjust(left=.01,right=.99,bottom=.01,top=.99)
ax.set(xlim=(0,10),ylim=(0,10)); ax.axis('off')
def box(x,y,w,h,text,accent=False):
    ax.add_patch(FancyBboxPatch((x,y),w,h,boxstyle='round,pad=0.04,rounding_size=0.10',
        linewidth=.7,edgecolor='#0072B2' if accent else '.25',
        facecolor='#EDF5FA' if accent else 'white'))
    ax.text(x+w/2,y+h/2,text,ha='center',va='center',linespacing=1.3)
def arrow(a,b):
    ax.add_patch(FancyArrowPatch(a,b,arrowstyle='-|>',mutation_scale=8,
                               linewidth=.7,color='.25'))
box(.8,8.95,8.4,.82,'Fixed FIR coefficients + exact width counts\n'+r'$h_i,\quad(n_{16},n_8,n_4)$')
box(.8,7.65,8.4,.82,'Construct per-tap quantization costs\n'+r'$c_{i,w}=[h_i-Q(h_i,w)]^2$')
arrow((5,8.9),(5,8.52))
for x,w,t,a in [(.15,3.0,'Quota DP\nExact SSE optimum',True),
                (3.5,3.0,'Greedy\nUpgrade baseline',False),
                (6.85,3.0,'Assignment MILP\nExact cross-check',False)]:
    box(x,5.95,w,1.0,t,a)
ax.plot([1.65,8.35],[7.28,7.28],color='.25',lw=.7)
ax.plot([5,5],[7.61,7.28],color='.25',lw=.7)
for x in [1.65,5,8.35]: arrow((x,7.28),(x,7.0))
box(.8,4.35,8.4,1.0,'Software evaluation\nQuota validity, coefficient SSE, frequency response')
ax.plot([1.65,8.35],[5.55,5.55],color='.25',lw=.7)
for x in [1.65,5,8.35]: ax.plot([x,x],[5.91,5.55],color='.25',lw=.7)
arrow((5,5.55),(5,5.4))
box(.15,1.8,4.55,1.65,'8-tap case\nRTL simulation + routed resources\nUART board verification')
box(5.3,1.8,4.55,1.65,'48-tap case\nRTL simulation + routed resources\nNo board or power measurement')
ax.plot([2.43,7.57],[3.9,3.9],color='.25',lw=.7)
ax.plot([5,5],[4.31,3.9],color='.25',lw=.7)
for x in [2.43,7.57]: arrow((x,3.9),(x,3.5))
ax.text(5,.9,'Hardware checks use selected configurations;\nwidth counts are not measured resource budgets.',
        ha='center',va='center',fontsize=7.5,color='.25',linespacing=1.3)
for ext in ['pdf','svg','png']:
    fig.savefig(out/f'allocation_workflow.{ext}',dpi=450)
plt.close(fig)
print(out/'allocation_workflow.pdf')
