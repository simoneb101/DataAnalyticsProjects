# Healthcare Analysis

`healthcare_analysis.ipynb` is an exploratory data analysis notebook that cleans healthcare admissions data and visualizes billing and patient-stay trends.

## Dataset

- Source: `.../health_kaggle_data_realistic.csv`
- Volume: 55,500 records
- Original fields: 15 columns
- Admission date range: 2019-05-08 to 2024-05-07

## Notebook Workflow

1. Loads libraries (`pandas`, `numpy`, `matplotlib`, `seaborn`, `plotly`).
2. Reads the dataset.
3. Cleans patient name fields by splitting `Name` into `First Name` and `Last Name`.
4. Converts admission/discharge columns to datetime.
5. Creates engineered fields:
   - `Admission Duration Days`
   - `Hospital with Room Number`
   - `Admission Year`
6. Builds grouped summaries and Plotly charts for:
   - Total billing by hospital and doctor
   - Patient count by blood type
   - Admissions by year
   - Total admission duration by blood type
   - Average admission duration by age
7. Exports a processed CSV to:
   `...\health_kaggle_data.csv`

## Key Findings (From Notebook Logic)

- Typical length of stay is stable around two weeks:
  - Mean: 15.51 days
  - Median: 15 days
- Blood-type distribution is balanced across all 8 blood groups (each near ~6.9K records).
- Admissions are highest from 2020 to 2023 (about 11K each year), with lower counts in 2019 and 2024 because those years are partial in this dataset range.
- Total stay days by blood type are close, with `B+` highest and `O+` lowest, suggesting no large blood-type-driven gap in aggregate stay burden.
- Highest combined billing totals appear in specific hospital-doctor pairs (top pair slightly above 104K in billing amount).
- Average stay by age varies modestly; most ages cluster near the overall mean, with a few outlier ages showing longer/shorter averages.

## Notes

- The notebook is code-focused and currently has little markdown narration.
- Charts are interactive Plotly visualizations rendered inline.
