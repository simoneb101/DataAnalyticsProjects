# Ingestion Notebook Summary

The notebook in `ingestion/omahaWeatherPipelineDataGeneration.ipynb` prepares raw data for the sales-weather pipeline.

It does the following:
- Installs and updates required Python packages (Open-Meteo client, pandas, SQLAlchemy, psycopg2, dotenv, and related dependencies).
- Loads PostgreSQL credentials from `.env`, creates a SQLAlchemy engine, and provides a helper class to write DataFrames to Postgres tables.
- Pulls Omaha-area GIS reference points from `data/omaha_metro_gis_reference_dataset.xlsx`.
- Calls the Open-Meteo API for each latitude/longitude pair to fetch hourly weather (temperature, precipitation probability) and daily min/max temperatures for a 14-day forecast.
- Merges hourly and daily weather fields, joins weather back to GIS metadata, and writes the result to `raw.raw_gis_weather`.
- Loads messy drink sales data from `data/omaha_dirty_drink_sales_500k.csv`, creates a synthetic `sales_id`, and writes it to `raw.raw_sales`.

By default, the two ingestion functions are defined but commented out at the bottom of the notebook, so they run only when manually uncommented.
