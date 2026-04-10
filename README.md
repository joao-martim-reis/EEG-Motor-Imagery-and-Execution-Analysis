The dataset could be found here: https://www.physionet.org/content/eegmmidb/1.0.0/

## Overview
The study utilizes the **EEG Motor Movement/Imagery Dataset**[cite: 1, 112]. It focuses on distinguishing between two primary cognitive states:
* **Task 3:** Real motor execution, specifically moving the wrist[cite: 103].
* **Task 4:** Motor imagery, or thinking about moving the wrist[cite: 103].

The results indicate that brain patterns for real movement and its mental representation are highly similar, suggesting a significant overlap in the neural circuits involved[cite: 14, 23].

---

## Signal Processing Pipeline
The analysis was conducted using a systematic algorithm implemented in **MATLAB**[cite: 460]:

### 1. Pre-processing
* **Re-Referencing:** Applied **Common Average Reference (CAR)** to remove the DC component from the obtained data
* **Filtering:** * **High-pass filter (1 Hz):** Used a Butterworth IIR filter to define the lower edge frequency
    * **Notch filter (60 Hz):** An elliptical IIR filter used to attenuate electrical interference noise from the original acquisition site
    * **Band-pass filtering:** Segments the signal into five standard bands: Delta (0-4 Hz), Theta (4-8 Hz), Alpha (8-15 Hz), Beta (14-30 Hz), and Gamma (>30 Hz)

### 2. Feature Extraction
* **Power Spectral Density (PSD):** Calculated using **Welch’s Method** with a Hamming window and a 200-point overlap to ensure the analysis is less sensitive to local variations
* **Energy Ratios:** Calculated the ratio of energy in each band during Tasks 3 and 4 relative to the **Task 1 baseline**
* **Adaptive Thresholding:** Defined as the **mean of the ratio plus its standard deviation** to identify channels with significant energy increases

### 3. Visualization & Statistics
* **Topographic Mapping:** Utilized the **EEGLAB topoplot** function to visualize active brain regions and confirm electrode coordinates
* **Statistical Analysis:** Applied the **Mann-Whitney (ranksum) test** to compare distributions between bands and tasks, as it is robust against non-normal distributions and outliers
