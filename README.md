# james-etal-2026-lock-release

This repository contains the data used in the research paper:

> James C. B. G, Jellinek A. M. and Topf H. S. **How source momentum and particle loading shape deep-sea mining collector vehicle discharges.** *Submitted to Elementa: Science of the Anthropocene.*

## Repository organization

```
james-etal-2026-lock-release
│
├───analysis/
│   ├───matlab/             # pre-processing scripts to extract data from side-view videos
│   │   └─── *.m
│   └───python/             # further processing and analysis scripts to convert *.csv to *.npy and calculate mean shape
│       └─── *.py 
│
├───data/
│   ├───datafiles/          # .npy experiment files
│       └─── *.np
│   └───metadata/           # .csv files for own experiments and literature comparisons
│       └─── *.csv
│
└───paper/
    ├───figure_scripts/     # scripts that read data/ and write to figures/
    │   └─── *.ipynb
    └───figures/            # output figures
        └─── *.png
```

## Data organization

The CSV file `data/metadata/experiments_summary.csv` offers a summary of all runs and corresponding experimental parameters.

The folder `data/datafiles` contains 51 `.npy` files containing processed data from each lock release experiment captured via side-view video. 
Raw videos were processed in MATLAB to extract time-evolving front position, area, and height profiles.
A second processing stage computes the mean and standard deviation of the current shape across time.
 
Each file is a NumPy object array containing a single Python dictionary with the following fields:
 
#### Time series
 
- **`time_s`** — Time vector, in seconds.
- **`front_m`** — Streamwise position of the current front, in meters.
- **`area_m2`** — Cross-sectional area of the current, in m².
- **`height_m`** `(n_time, n_x)` — Height of the current at each time step and spatial position, in meters.
 
#### Computing mean shape (1D, length `n_x`)
 
- **`xcenters`** — Streamwise positions of spatial grid cell centers (pixels) in meters
- **`height_stack`** `(n_frames, n_x)` — Stacked height profiles used to compute the shape statistics. Contains NaN values where data is absent. `n_frames` may differ from `n_time` as it represents a subset of time steps. In meters.
- **`av_shape`** — Time-averaged height profile (mean shape) of the current as a function of streamwise position, in meters
- **`av_shape_std`** — Standard deviation of the height profile across time at each streamwise position, in meters
 
---

## Getting Started

### Prerequisites
This repository uses [Git LFS](https://git-lfs.com/) to store `.npy` data files.
Before cloning, install Git LFS:

- **Mac:** `brew install git-lfs`
- **Linux:** `sudo apt install git-lfs` (or equivalent)
- **Windows:** Download from https://git-lfs.com/

Then enable it once:
```bash
git lfs install
```

### Cloning and pulling .npy files
```bash
git clone https://github.com/CaraBGJames/james-etal-2026-lock-release.git
cd james-etal-2026-lock-release
git lfs pull 
```

### Environment
```bash
conda env create -f environment.yml
conda activate env-james2026lock
```
 
### Loading the Data
 
```python
import numpy as np
 
data = np.load('filename.npy', allow_pickle=True).item()
 
time    = np.abs(data['time_s'])       # (n_time,)
front   = np.abs(data['front_m'])      # (n_time,)
area    = np.abs(data['area_m2'])      # (n_time,)
height  = np.abs(data['height_m'])     # (n_time, n_x)
x       = np.abs(data['xcenters'])     # (n_x,)
av      = np.abs(data['av_shape'])     # (n_x,)
av_std  = np.abs(data['av_shape_std']) # (n_x,)
stack   = np.abs(data['height_stack']) # (n_frames, n_x)
```
 