# Machine-Learning Surrogate Platform for the Pig Head FEM

A Windows application for predicting finite element model (FEM) brain response outputs from impact kinematics using trained machine-learning surrogate models.

The current release supports the **pig head impact model**.

The MATLAB models are the **source of truth**. The optimized Python application runs the same numerical workflow in NumPy, and predicted values are checked against MATLAB reference outputs before a build is shipped.

## Download

This app has two parts, downloaded separately:

1. **The app itself** — download `FEMML_Surrogate.exe` from the
   [latest release](https://github.com/memar-lab/Surrogate-Pig-Head-FEM-ML/releases/latest).
   (It is not included in the repository ZIP because of its file size.)
2. **Supporting files** — click the green **Code** button on the repository page →
   **Download ZIP**. This gives you `run_batch.bat`, `Templates/`, and `ExampleBatchFolder/`.

Put all of them — the `.exe` and the unzipped files — in the same folder on your system:

```text
FEMML_Surrogate.exe
run_batch.bat
Templates/
ExampleBatchFolder/
```

---

## Contents

- [Download](#download)
- [Overview](#overview)
- [What you need installed](#what-you-need-installed)
- [Model Outputs](#model-outputs)
- [Scientific references](#scientific-references)
- [Running the app](#running-the-app)
- [First launch and warm-up behavior](#first-launch-and-warm-up-behavior)
- [Input options and units](#input-options-and-units)
- [Input templates and example files](#input-templates-and-example-files)
- [GUI workflow](#gui-workflow)
- [Batch mode](#batch-mode)
- [Batch input rules](#batch-input-rules)
- [Batch outputs](#batch-outputs)
- [Injury threshold rule](#injury-threshold-rule)
- [How the prediction pipeline works](#how-the-prediction-pipeline-works)
- [Model validation and MATLAB consistency](#model-validation-and-matlab-consistency)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Overview

This platform provides two ways to run the FEM-ML surrogate model:

1. **GUI mode**  
   The user double-clicks the Windows executable and runs one simulation through an interactive graphical interface.

2. **Batch mode**  
   The user runs predictions for a folder of CSV input files at once using `run_batch.bat`. Batch mode does not require clicking through the GUI.

The workflow is:

```text
User impact input
   ↓
Impact profile processing
   ↓
Angular velocity trace
   ↓
Feature extraction
   ↓
Model selection and model loading
   ↓
Input normalization
   ↓
Machine-learning surrogate prediction
   ↓
Inverse PCA
   ↓
Overall outputs + spatial outputs
   ↓
Exported result files
```

All supported input types are converted into an angular velocity trace before feature extraction.

---

## What you need installed

### For normal use

- **Windows**. The packaged application is built as a Windows executable.
- The compiled application file:

```text
FEMML_Surrogate.exe
```

### For source/build workflows

- **Python 3.10 or newer**, available on `PATH`.
- Python packages:
  - `pyinstaller`
  - `numpy`
  - `matplotlib`
  - `pillow`

The build script installs the required Python packages.

### For MATLAB model export only

- **MATLAB with MATLAB Compiler**.

You only need MATLAB when re-exporting or regenerating model assets from MATLAB. If the required model assets already exist, MATLAB is not needed to build or run the Windows executable.

---

## Model Outputs

The platform predicts four main outputs:

| Output | Description | Output type |
|---|---|---|
| `MPS95` | 95th percentile maximum principal strain | Overall scalar |
| `MAS95` | 95th percentile maximum axonal strain | Overall scalar |
| Spatial MPS | MPS value for each brain element | Spatial vector/table |
| Spatial MAS | MAS value for each fiber beam | Spatial vector/table |

The GUI can display spatial MPS and MAS views when graphical visualization is enabled.

Batch mode exports numerical outputs and intentionally skips 3D graphical views.

---

## Scientific references

### Overall MPS95 and MAS95

The platform uses injury thresholds of **0.30 for MPS95** and **0.13 for MAS95**. These thresholds were identified for traumatic axonal injury prediction in the pig brain model.

1. Hajiaghamemar, M., Wu, T., Panzer, M.B. and Margulies, S.S., 2020. *Embedded axonal fiber tracts improve finite element model predictions of traumatic brain injury*. **Biomechanics and Modeling in Mechanobiology**, 19(3), pp. 1109–1130.

2. Wu, T., Hajiaghamemar, M., Giudice, J.S., Alshareef, A., Margulies, S.S. and Panzer, M.B., 2021. *Evaluation of tissue-level brain injury metrics using species-specific simulations*. **Journal of Neurotrauma**, 38(13), pp. 1879–1888.

### Spatial MPS and MAS

Spatial MPS and MAS outputs are based on the multiscale white-matter-tract embedded FEM framework.

3. Hajiaghamemar, M. and Margulies, S.S., 2021. *Multi-scale white matter tract embedded brain finite element model predicts the location of traumatic diffuse axonal injury*. **Journal of Neurotrauma**, 38(1), pp. 144–157.

---

## Running the app

To launch the graphical application:

1. Locate:

```text
FEMML_Surrogate.exe
```

2. Double-click the executable.

3. Wait for the GUI to open.

4. Enter the simulation inputs and run prediction.

This is a single-file executable. It unpacks its libraries into a temporary folder each time it starts, so startup may take a few seconds.


---

## First launch and warm-up behavior

The first launch performs a one-time model warm-up. This makes the first prediction faster after the application opens.

After warm-up, the app writes this marker file:

```text
%LOCALAPPDATA%\FEMML_Surrogate\first_run_done.flag
```

Every launch after that skips the warm-up and opens directly into the app.

To force the first-run behavior again, delete:

```text
%LOCALAPPDATA%\FEMML_Surrogate\first_run_done.flag
```

Then launch `FEMML_Surrogate.exe` again.

---

## Input options and units

The platform supports three input types. For one GUI run, select one input type. For one batch run, every CSV file in the input folder must use the same input type.

### 1. VelocityTrace

Use this option when the input file already contains angular velocity.

Required CSV columns:

```text
time_(s)
Angular_velocity_(rad/s)
```

Example:

```csv
time_(s),Angular_velocity_(rad/s)
0,0
0.001,15
0.002,30
0.003,45
```

The backend reads the trace directly as angular velocity.

---

### 2. AccelerationTrace

Use this option when the input file contains angular acceleration.

Required CSV columns:

```text
time_(s)
Angular_Acceleration_(rad/s2)
```

Example:

```csv
time_(s),Angular_Acceleration_(rad/s2)
0,0
0.001,50000
0.002,100000
0.003,50000
```

The app converts acceleration into velocity before feature extraction.

---

### 3. PeakValues

Use this option when the input is only peak angular acceleration and peak angular velocity.

Required CSV columns for batch mode:

```text
Peak_Acceleration_(rad/s2)
Peak_Velocity_(rad/s)
```

Example:

```csv
Peak_Acceleration_(rad/s2),Peak_Velocity_(rad/s)
150000,100
```

Units:

| Quantity | Unit |
|---|---|
| Peak acceleration | `rad/s2` |
| Peak velocity | `rad/s` |

For peak-value input, the app generates an idealized sinusoidal acceleration profile and the analytical velocity profile.

The pulse duration is:

```text
T = pi * peakVelocity / alphaMax
```

where:

```text
alphaMax = peak acceleration in rad/s2
```

During the pulse:

```text
alpha(t) = alphaMax * sin(2*pi*t/T)
omega(t) = (alphaMax*T/(2*pi)) * (1 - cos(2*pi*t/T))
```

The time step is:

```text
dt = 1e-5 s
```

The full generated trace duration is:

```text
total duration = T + 0.020 s
```

After the pulse, acceleration and velocity are set to zero for the extra 20 ms.

---

## Input templates and example files

The release includes a `Templates` folder for creating new input CSV files. This folder contains blank CSV templates for the supported input types:

```text
Templates/
├── AngularVelocityTrace_Template.csv
├── AngularAccelerationTrace_Template.csv
└── PeakValues_Template.csv
```

Use these templates when preparing your own GUI or batch input files. Keep the column names exactly as shown in the templates because the app reads the CSV files using these expected column names.

The release also includes an `ExampleBatchFolder` folder with a few example input traces/files. This folder is provided so users can quickly test batch mode before preparing their own data:

```text
ExampleBatchFolder/
├── example input CSV files
└── ...
```

For a first batch-mode test, select `ExampleBatchFolder` as the CSV input folder when `run_batch.bat` asks for the input folder path. After confirming that the batch run works, create your own input folder using the files in `Templates` as the starting point.

---

## GUI workflow

### Step 1. Launch the app

Double-click:

```text
FEMML_Surrogate.exe
```

### Step 2. Select species

The current active species is:

```text
Pig
```

Other species may appear in future versions after trained models are added.

### Step 3. Enter simulation settings

In the GUI, enter or select:

- Simulation ID
- Input type
- Input CSV file or peak values
- Impact direction
- Model architecture
- Visualization option

Supported impact directions:

```text
Axial
Sagittal
Coronal
```

`Multi-Direction` is reserved for future development. Current models are not trained for multi-direction prediction.

Supported model architectures:

```text
DNN
Lasso
Ridge
Random Forest - Linear
Random Forest - Curvature
```

### Step 4. Generate trace preview

Click:

```text
Generate Trace
```

The app converts the selected input into the angular velocity trace and displays the trace preview.

### Step 5. Run prediction

Click:

```text
Run Prediction
```

The app will:

1. Read input settings.
2. Generate or load the angular velocity trace.
3. Extract 15 kinematic features.
4. Load the selected surrogate models.
5. Predict MPS95, MAS95, spatial MPS, and spatial MAS.
6. Export the numerical result files.
7. Display the Run/Results page.
8. Export a screenshot of the Run/Results page.

---

## Batch mode

Batch mode runs predictions for a whole folder of CSV input files without opening the GUI workflow.

Use batch mode when all simulations share the same:

- input type,
- impact direction,
- model architecture.

Batch mode writes the same numerical CSV outputs as the GUI and also writes a summary CSV for the whole run. It does not draw or export the 3D views.

### How to run batch mode

1. Put `run_batch.bat`, `Templates`, and `ExampleBatchFolder` in the same folder as:

```text
FEMML_Surrogate.exe
```

2. Double-click:

```text
run_batch.bat
```

3. A command prompt window opens and asks for:

```text
CSV input folder
Input type
Impact direction
Model architecture
Results output folder
```

For a quick test, use the included `ExampleBatchFolder` as the CSV input folder.

The batch prompt looks like this:

```text
===================================================
FEM-ML Surrogate Initialization Pipeline
Press Ctrl + C at any time to forcefully abort execution.
===================================================

Define path to CSV input folder ...

Select Input Type:
[1] VelocityTrace
[2] AccelerationTrace
[3] PeakValues
[Q] Quit

Select Impact Direction:
[1] Axial
[2] Sagittal
[3] Coronal
[Q] Quit

Select Model Architecture:
[1] DNN
[2] Lasso
[3] Ridge
[4] Random Forest - Linear
[5] Random Forest - Curvature
[Q] Quit

Define results output folder ...
```

4. After the selections are entered, the batch file launches:

```text
FEMML_Surrogate.exe --batch --input <INPUT_FOLDER> --type <TYPE> --direction <DIRECTION> --model <MODEL> --out <OUTPUT_FOLDER>
```

5. A progress bar is shown in the command window.

6. When the run completes, open the selected output folder.

---

## Batch input rules

### Rule 1. Do not mix input types

Every file in one batch run must use the same input type.

Do not mix velocity traces, acceleration traces, and peak-value files in one folder.

Allowed:

```text
BatchPeakInputs/
├── SIM_001.csv
├── SIM_002.csv
└── SIM_003.csv
```

Not allowed:

```text
MixedBatchInputs/
├── SIM_001_velocity.csv
├── SIM_002_acceleration.csv
└── SIM_003_peak.csv
```

If different input types are needed, run separate batches.

### Rule 2. Filename becomes SimulationID

Each CSV filename without `.csv` becomes the `SimulationID`.

Example:

```text
SIM_001.csv -> SIM_001
PigCase12.csv -> PigCase12
```

### Rule 3. Template files are skipped

Files with `template` in the filename are skipped.

Examples that will be skipped:

```text
PeakValues_Template.csv
AngularVelocityTrace_Template.csv
AngularAccelerationTrace_Template.csv
```

### Rule 4. One row for PeakValues

For `PeakValues`, each CSV should contain exactly one simulation input row.

Example:

```csv
Peak_Acceleration_(rad/s2),Peak_Velocity_(rad/s)
150000,100
```

---

## Batch outputs

Batch mode writes outputs to the selected output folder.

If the selected output folder is:

```text
OUT
```

then batch mode writes:

```text
OUT\_BatchSummaries\BatchSummary_date_time.csv
OUT\batch_log.txt
```

For each successful simulation, batch mode also writes the numerical prediction outputs. Depending on the current package configuration, these are written either directly under the output folder or under a simulation-specific subfolder.

Expected per-simulation numerical outputs:

```text
<SimulationID>_OverallPredictions.csv
<SimulationID>_SpatialMPS.csv
<SimulationID>_SpatialMAS.csv
<SimulationID>_PredictionResults.*
```

Batch mode does not draw the 3D views and does not export GUI screenshots.

The batch summary includes one row per input file and is the first file to check after a batch run.

Typical summary columns:

```text
SimulationID
InputFile
Status
ErrorMessage
MPS95
MAS95
MPS95_InjuryFlag
MAS95_InjuryFlag
OutputFolder
OverallCSV
SpatialMPS_CSV
SpatialMAS_CSV
```

If one simulation fails, the batch continues to the next file. The failed row is marked with `Failed`, and the reason is written in `ErrorMessage`.

---

## Injury threshold rule

The platform flags injury-level response using equal-to-or-above-threshold logic:

```text
MPS95_InjuryFlag = MPS95 >= 0.30
MAS95_InjuryFlag = MAS95 >= 0.13
```

Rule:

```text
value < threshold  -> below threshold
value >= threshold -> injury flag is true
```

The GUI reports an injury-level response if either MPS95 or MAS95 is flagged.

---

## How the prediction pipeline works

### 1. Impact profile processing

The app accepts one of three input types:

```text
VelocityTrace
AccelerationTrace
PeakValues
```

All are converted into:

```text
velocityTrace[:, 0] = time in seconds
velocityTrace[:, 1] = angular velocity in rad/s
```

### 2. Feature extraction

The velocity trace is converted into 15 kinematic features:

```text
BRIC
RIC
BrIC
RVCI
ang_vel_max
ang_acc_max
Time_to_Peak_Vel
Time_from_Peak_Vel
Total_Curve_Duration
max_vel_squared
max_vel_cubed
max_ang_squared
max_ang_cubed
Area_under_Velocity
max_Jerk
```

### 3. Model prediction

The selected model family is used to predict:

```text
Overall MPS95
Overall MAS95
Spatial MPS
Spatial MAS
```

The model uses saved scaling values, PCA information, and trained model parameters exported from MATLAB.

### 4. Output reconstruction

Spatial predictions are reconstructed into full spatial output vectors using the saved PCA reconstruction information and output-scaling parameters.

### 5. Export

The app exports overall and spatial prediction files and, in GUI mode, optional graphical previews.

---


## Troubleshooting

### The app takes a few seconds to open

This is expected for the single-file executable. It unpacks dependencies into a temporary folder at startup.

### The first launch takes longer than later launches

The first launch performs model warm-up. After that, the app writes:

```text
%LOCALAPPDATA%\FEMML_Surrogate\first_run_done.flag
```

Later launches skip the warm-up.

### I want to repeat the first-run warm-up behavior

Delete:

```text
%LOCALAPPDATA%\FEMML_Surrogate\first_run_done.flag
```

Then launch the app again.

### Batch mode opens but does not find the executable

Make sure `run_batch.bat` is in the same folder as:

```text
FEMML_Surrogate.exe
```

### Batch mode runs but no files are processed

Check that:

- the input folder path is correct,
- the folder contains `.csv` files,
- filenames do not include `template`,
- all files match the selected input type.

### A batch simulation failed but the batch continued

This is expected. Open the batch summary CSV and check the `ErrorMessage` column.

### PeakValues results look wrong

Check the units:

```text
Peak_Acceleration_(rad/s2)
Peak_Velocity_(rad/s)
```

Do not enter peak acceleration in `krad/s2`.

---

## Suggested citation text

If this platform is used in a project, cite the model-output references listed above and any future paper or repository citation associated with this codebase.

...
