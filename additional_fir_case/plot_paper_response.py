"""Publication-sized vector frequency-response figure from saved coefficients.

Run from any directory. No MATLAB graphics or curve smoothing is used.
"""
from pathlib import Path
import csv
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
from scipy.signal import freqz

ROOT = Path(__file__).resolve().parent
OUT = ROOT.parent / 'paper' / 'figures'
OUT.mkdir(parents=True, exist_ok=True)
rows = np.loadtxt(ROOT / 'results_matlab/allocations.csv', delimiter=',', skiprows=1)
q = rows[rows[:, 0] == 1]
assert q.shape == (48, 11)
with (ROOT / 'results_matlab/method_metrics.csv').open() as f:
    metrics = {r['method']: r for r in csv.DictReader(f) if r['quota_id'] == '1'}

plt.rcParams.update({
    'font.family': 'serif', 'font.serif': ['Times New Roman', 'STIXGeneral'],
    'mathtext.fontset': 'stix', 'font.size': 8, 'axes.labelsize': 8,
    'xtick.labelsize': 7.5, 'ytick.labelsize': 7.5, 'legend.fontsize': 7.5,
    'axes.linewidth': .6, 'lines.linewidth': 1.0, 'pdf.fonttype': 42,
    'ps.fonttype': 42, 'svg.fonttype': 'none',
})
fig, axes = plt.subplots(2, 1, figsize=(3.5, 3.55))
fig.subplots_adjust(left=.16, right=.975, bottom=.12, top=.88, hspace=.51)
series = [('Floating-point', q[:, 2], '#505050', (0, (1, 1.7))),
          ('DP', q[:, 4], '#0072B2', '-'),
          ('Greedy', q[:, 6], '#D55E00', (0, (4, 2)))]
responses = {}
for label, coefficients, color, style in series:
    w, response = freqz(coefficients, worN=65536)
    f = w / np.pi
    db = 20 * np.log10(np.maximum(np.abs(response), np.finfo(float).tiny))
    responses[label] = (f, db, color)
    for ax, mask in zip(axes, [f <= .3, f >= .4]):
        ax.plot(f[mask], db[mask], color=color, linestyle=style, label=label)
    if label in metrics:
        peak = db[f >= .4].max()
        assert np.isclose(peak, float(metrics[label]['stopband_peak_db']), atol=1e-8)
        assert np.max(np.abs(db[f <= .3])) <= .25

axes[0].set(xlim=(0, .3), ylim=(-.3, .3), xticks=[0,.1,.2,.3],
            yticks=[-.25,0,.25], ylabel='Magnitude (dB)')
for y in [-.25, .25]:
    axes[0].axhline(y, color='0.4', linewidth=.7, linestyle=(0,(5,2,1,2)))
axes[0].text(.01,.83,'(a) Passband',transform=axes[0].transAxes, va='top')
axes[0].text(.98,.83,r'$\pm 0.25$ dB limit',transform=axes[0].transAxes,
             va='top',ha='right',fontsize=7)
axes[1].set(xlim=(.4,1), ylim=(-80,-25), xticks=[.4,.6,.8,1],
            yticks=[-80,-60,-40], ylabel='Magnitude (dB)')
axes[1].axhline(-40, color='0.25', linewidth=.8, linestyle=(0,(5,2,1,2)))
axes[1].text(.01,.08,'(b) Stopband',transform=axes[1].transAxes,
             va='bottom',bbox=dict(facecolor='white',edgecolor='none',pad=1))
axes[1].text(.98,.69,r'$-40$ dB limit',transform=axes[1].transAxes,
             ha='right',fontsize=7,bbox=dict(facecolor='white',edgecolor='none',pad=.5))
for label, textxy in [('Greedy',(.67,-31)),('DP',(.57,-51))]:
    f, db, color = responses[label]
    indices = np.flatnonzero(f >= .4)
    ix = indices[np.argmax(db[indices])]
    axes[1].plot(f[ix],db[ix],marker='o',markersize=3,color=color)
    axes[1].annotate(f'{label}: {db[ix]:.2f} dB', xy=(f[ix],db[ix]),
        xytext=textxy, fontsize=7, color=color,
        arrowprops=dict(arrowstyle='->',color=color,lw=.65),
        bbox=dict(facecolor='white',edgecolor='none',pad=1.1))
for ax in axes:
    ax.set_xlabel(r'Normalized frequency, $\omega/\pi$')
    ax.tick_params(direction='in', length=3, width=.6, top=True, right=True)
    ax.grid(axis='y',color='.9',linewidth=.45)
fig.legend(*axes[0].get_legend_handles_labels(),loc='upper center',
           bbox_to_anchor=(.55,.985),ncol=3,frameon=False,
           handlelength=2.2,columnspacing=1)
for ext in ['pdf','svg','png']:
    fig.savefig(OUT / f'frequency_response_quota1.{ext}', dpi=450)
print(OUT / 'frequency_response_quota1.pdf')
plt.close(fig)
