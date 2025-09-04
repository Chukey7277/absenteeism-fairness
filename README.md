# Absenteeism Prediction — Fairness & Bias

## Project Overview

This project analyzes fairness in predicting absenteeism at work using the UCI **Absenteeism at Work** dataset.
We focus on fairness by **Age group** (`age_ge_40`: 0 = <40, 1 = ≥40).

The notebook performs:

* A **pre-training bias audit** of the dataset
* Trains a simple, interpretable **logistic regression** baseline
* Applies **fairness mitigations** (feature elimination, reweighting, calibration + threshold tuning)
* Compares **utility** and **fairness** before vs after mitigation, with tables and plots

Fairness is assessed using **Statistical Parity Difference (SPD)**, **Equal Opportunity Difference (EOD)**, and **FPR\_diff** (false-positive rate gap).

---

## Project Structure

```
absenteeism-fairness/
├─ data/
│  └─ Absenteeism_at_work.xls
├─ notebooks/
│  └─ HAI_Assignment_2.ipynb
├─ report/
│  └─ report.tex
├─ requirements.txt
├─ Dockerfile
└─ README.md
```

---

## Data

* **File:** `data/Absenteeism_at_work.csv` 
* **Target variable (constructed):** `heavy_absent = 1` if `Absenteeism time in hours ≥ 75th percentile`, else `0`
* **Protected attribute:** `age_ge_40` (0 = younger than 40, 1 = 40 and older)
* **Source:** UCI ML Repository — *Absenteeism at Work*

> **Leakage control:** the raw continuous label column is **not** used as a feature.

---

## What the Notebook Does

**Bias Audit (before modeling)**

* Representation of `age_ge_40` and base rates `P(Y=1|A)`
* Intersectional checks (e.g., with Education)
* Missingness / duplicates (none material)
* **Proxy audit**: features like **Service time**, **BMI**, **Reason for absence** carry age signal

**Modeling**

* Logistic Regression in a scikit-learn `Pipeline`

  * Categorical: impute most frequent → One-Hot (drop first)
  * Numeric: median impute → standardize
  * Train/test split: 80/20, stratified by label

**Mitigations**

* **Feature Elimination:** drop **Age** from features (keep for fairness slicing)
* **Reweighting (A×Y):** balance training mass across 4 group×label cells
* **Calibration + Threshold Tuning:** isotonic calibration and a **single global threshold** chosen to reduce |EOD| and |FPR\_diff| with minimal F1 loss

**Evaluation**

* **Utility:** Accuracy, Precision, Recall, F1, ROC-AUC
* **Fairness:** SPD, EOD (TPR gap), **FPR\_diff** (FPR gap)
* **Artifacts saved to:** `absenteeism_report_outputs/`

---

## Results 

### Overall Utility (test set)

| Model                 |  Accuracy | Precision |   Recall  |     F1    |  ROC-AUC  |
| --------------------- | :-------: | :-------: | :-------: | :-------: | :-------: |
| Baseline              |   0.878   |   0.821   |   0.852   |   0.836   |   0.916   |
| Drop(Age)             |   0.858   |   0.800   |   0.815   |   0.807   |   0.915   |
| Reweighted\@Drop(Age) |   0.865   |   0.774   |   0.889   |   0.828   |   0.922   |
| Rew\@Drop(Age)@0.47   |   0.872   |   0.778   |   0.907   |   0.838   |   0.922   |
| **Rew+Cal\@0.48**     | **0.878** |   0.790   | **0.907** | **0.845** | **0.926** |

### Fairness Deltas (A=1 minus A=0)

| Model                 |     SPD    |    EOD    | FPR\_diff |
| --------------------- | :--------: | :-------: | :-------: |
| Baseline              |   -0.063   |   -0.131  |   0.089   |
| Drop(Age)             |   -0.020   |   -0.083  |   0.122   |
| Reweighted\@Drop(Age) |   -0.053   |   -0.071  |   0.075   |
| Rew\@Drop(Age)@0.47   |   -0.029   |   0.012   |   0.075   |
| **Rew+Cal\@0.48**     | **-0.053** | **0.012** | **0.042** |

**Story in one line:** with simple mitigations we **maintain Accuracy**, **increase F1/Recall**, push **EOD ≈ 0** (near equal opportunity), and **cut FPR gap by >50%** vs baseline.

---

## Environment

* **Python:** 3.12
* **Key libs:** `pandas 2.2.2`, `numpy 1.26.4`, `scikit-learn 1.4.2`, `matplotlib 3.8.4`, `seaborn 0.13.2`
* **Excel engines:** `xlrd 1.2.0` (for `.xls`), `openpyxl 3.1.5` (for `.xlsx`)
* Fully reproducible via **Docker**.

---

## Quick Start (Local)


### Run the notebook

Open `notebooks/HAI_Assignment_2.ipynb` (JupyterLab/VS Code) and execute top-to-bottom.

> Ensure the dataset path in the notebook is:
>
> ```python
> path = "data/Absenteeism_at_work.csv"
> df = pd.read_excel(path)  # xlrd==1.2.0 handles .xls
> ```

Artifacts will appear in `absenteeism_report_outputs/`.

---

## Quick Start (Docker)

### 1) Build the Docker image

```bash
docker build -t absenteeism-fairness .
```

### 2) Run JupyterLab in the container

* **macOS/Linux**

  ```bash
  docker run --rm -it -p 8888:8888 -v "$PWD:/work" absenteeism-fairness
  ```
* **Windows (PowerShell)**

  ```powershell
  docker run --rm -it -p 8888:8888 `
    -v "C:\Users\<you>\absenteeism-fairness:/work" `
    absenteeism-fairness
  ```
* **Windows (CMD)**

  ```cmd
  docker run --rm -it -p 8888:8888 -v "%cd%:/work" absenteeism-fairness
  ```

Open **[http://localhost:8888/lab](http://localhost:8888/lab)** and load `notebooks/HAI_Assignment_2.ipynb`.

> If port `8888` is busy, use `-p 8890:8888` and open `http://localhost:8890`.

---

## Prebuilt Docker Image

If you publish to Docker Hub, users can pull and run directly :

```bash
docker pull tseangchukey/absenteeism-fairness:latest
docker run --rm -it -p 8888:8888 -v "$PWD:/work" tseangchukey/absenteeism-fairness:latest
```

*Security note:* The image disables Jupyter tokens for local use; use on trusted networks.

---



## Reproducibility Checklist

* Deterministic splits (`random_state=42`)
* Pinned dependencies (`requirements.txt`) and Dockerfile

---

## Troubleshooting

* **“invalid reference format” (Windows):** Quote the `-v` path (see examples).
* **Jupyter “running as root” error:** Our Dockerfile runs as non-root; if you changed it, add `--allow-root` to the `jupyter lab` command.
* **`.xls` read error:** Ensure `xlrd==1.2.0` is installed (rebuild Docker if you changed deps).
* **Port busy:** Use `-p 8890:8888`.
* **Files not visible in Jupyter:** Check the volume mount path; your project should appear under `/work` inside the container.



---


