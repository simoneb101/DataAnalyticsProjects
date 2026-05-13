# Databricks notebook source
# MAGIC %md
# MAGIC # DBA 101 Part 2 — Practical Exam: Build a Data Pipeline
# MAGIC **DBA 101 Part 2**
# MAGIC
# MAGIC You are a data engineer at Cosmic Coffee Co. Your job is to build a complete
# MAGIC **medallion architecture pipeline** — from raw data to business-ready analytics.
# MAGIC
# MAGIC | Part | Task |
# MAGIC |------|------|
# MAGIC | 1 | Bronze Layer: Ingest & preserve raw data |
# MAGIC | 2 | Silver Layer: Clean, enrich, validate |
# MAGIC | 3 | Gold Layer: Business analytics |
# MAGIC | 4 | Architecture Short Answer |
# MAGIC
# MAGIC **Instructions:**
# MAGIC - Replace the `___` placeholders with your code
# MAGIC - Type written answers in the provided markdown cells
# MAGIC - Run each cell to verify your work before moving on
# MAGIC - You may use Databricks documentation but not external help or AI tools
# MAGIC - **Do NOT modify** cells marked "DO NOT MODIFY"

# COMMAND ----------

spark.sql("USE CATALOG workspace")

# COMMAND ----------

# MAGIC %md
# MAGIC ---
# MAGIC ## Setup: Generate Source Data (DO NOT MODIFY)
# MAGIC ---
# MAGIC
# MAGIC Run the cell below to create the raw data that simulates what you would receive
# MAGIC from Cosmic Coffee's systems. This data is intentionally messy — just like real data.

# COMMAND ----------

# -- DO NOT MODIFY THIS CELL --

from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, StringType
from pyspark.sql import functions as F

spark = SparkSession.builder.getOrCreate()

# === RAW ORDER EVENTS (simulating what Bronze would ingest) ===
raw_order_data = [
    ("ORD-001", "2026-03-01 08:15:00", "STR-001", "PROD-001", "2", "9.50", "completed"),
    ("ORD-002", "2026-03-01 08:22:00", "STR-001", "PROD-003", "1", "4.75", "completed"),
    ("ORD-003", "2026-03-01 09:10:00", "STR-002", "PROD-002", "3", "16.50", "completed"),
    ("ORD-004", "2026-03-01 10:05:00", "STR-003", "PROD-001", "1", "4.75", "completed"),
    ("ORD-005", "2026-03-01 11:30:00", "STR-001", "PROD-004", "2", "11.00", "completed"),
    ("ORD-006", "2026-03-02 07:45:00", "STR-002", "PROD-001", "1", "4.75", "completed"),
    ("ORD-007", "2026-03-02 08:00:00", "STR-003", "PROD-005", "1", "5.25", "completed"),
    ("ORD-008", "2026-03-02 09:30:00", "STR-001", "PROD-002", "2", "11.00", "completed"),
    ("ORD-009", "2026-03-02 10:15:00", "STR-002", "PROD-003", "1", "4.75", "completed"),
    ("ORD-010", "2026-03-02 14:00:00", "STR-003", "PROD-004", "3", "16.50", "completed"),
    ("ORD-011", "2026-03-03 08:00:00", "STR-001", "PROD-001", "1", "4.75", "completed"),
    ("ORD-012", "2026-03-03 08:45:00", "STR-002", "PROD-005", "2", "10.50", "completed"),
    ("ORD-013", "2026-03-03 10:00:00", "STR-003", "PROD-002", "1", "5.50", "completed"),
    ("ORD-014", "2026-03-03 11:15:00", "STR-001", "PROD-003", "1", "4.75", "completed"),
    ("ORD-015", "2026-03-03 13:00:00", "STR-002", "PROD-001", "2", "9.50", "completed"),
    # --- Messy data below (quality issues for students to handle) ---
    ("ORD-016", "2026-03-04 08:30:00", "STR-001", "PROD-001", "1", "invalid_price", "completed"),
    ("ORD-017", "not_a_timestamp", "STR-002", "PROD-003", "1", "4.75", "completed"),
    ("ORD-018", "2026-03-04 09:00:00", "STR-999", "PROD-002", "2", "11.00", "completed"),
    ("ORD-019", "2026-03-04 10:00:00", "STR-001", "PROD-001", "-3", "-14.25", "completed"),
    ("ORD-020", "2026-03-04 11:00:00", "STR-003", None, "1", "5.25", "completed"),
    ("ORD-011", "2026-03-03 08:00:00", "STR-001", "PROD-001", "1", "4.75", "completed"),  # duplicate of ORD-011
    ("ORD-021", "2026-03-04 12:00:00", None, "PROD-004", "2", "11.00", "completed"),
    ("ORD-022", "2026-03-04 14:00:00", "STR-002", "PROD-005", "1", "5.25", "COMPLETED"),
    ("ORD-023", "2026-03-05 08:00:00", "STR-001", "PROD-001", "2", "9.50", "completed"),
    ("ORD-024", "2026-03-05 09:30:00", "STR-003", "PROD-002", "1", "5.50", "completed"),
    ("ORD-025", "2026-03-05 10:45:00", "STR-002", "PROD-003", "3", "14.25", "completed"),
]

raw_order_schema = StructType([
    StructField("order_id", StringType()),
    StructField("order_timestamp", StringType()),
    StructField("store_id", StringType()),
    StructField("product_id", StringType()),
    StructField("quantity", StringType()),
    StructField("total_amount", StringType()),
    StructField("status", StringType()),
])

raw_orders_df = spark.createDataFrame(raw_order_data, raw_order_schema)
raw_orders_df.createOrReplaceTempView("raw_orders")

# === DIMENSION TABLES (these simulate the "static" side of a stream-static join) ===
stores_data = [
    ("STR-001", "Downtown", "Austin", "South"),
    ("STR-002", "Eastside", "Austin", "South"),
    ("STR-003", "Lakeway", "Lakeway", "Central"),
]

products_data = [
    ("PROD-001", "Nebula Latte", "coffee", 4.75),
    ("PROD-002", "Starlight Mocha", "coffee", 5.50),
    ("PROD-003", "Cosmic Cold Brew", "coffee", 4.75),
    ("PROD-004", "Supernova Chai", "tea", 5.50),
    ("PROD-005", "Milky Way Matcha", "tea", 5.25),
]

stores_df = spark.createDataFrame(stores_data, ["store_id", "store_name", "city", "region"])
products_df = spark.createDataFrame(products_data, ["product_id", "product_name", "category", "unit_price"])

stores_df.write.format("delta").mode("overwrite").saveAsTable("exam_stores")
products_df.write.format("delta").mode("overwrite").saveAsTable("exam_products")

print(f"Raw orders: {raw_orders_df.count()} rows")
raw_orders_df.show(truncate=False)
print("\nStores dimension:")
stores_df.show(truncate=False)
print("\nProducts dimension:")
products_df.show(truncate=False)

# COMMAND ----------

# MAGIC %md
# MAGIC ---
# MAGIC # Part 1: Bronze Layer
# MAGIC ---
# MAGIC
# MAGIC In a real pipeline, Bronze data would arrive via `spark.readStream` from a source like
# MAGIC Kafka or Auto Loader. Here, we simulate by saving the raw data as-is to a Delta table.
# MAGIC
# MAGIC The key principle of Bronze: **preserve everything, transform nothing.**

# COMMAND ----------

# MAGIC %md
# MAGIC ### 1a: Save raw data as a Bronze Delta table
# MAGIC
# MAGIC Save `raw_orders_df` as a Delta table called `exam_bronze_orders`.
# MAGIC Add one column: `ingestion_timestamp` set to the current timestamp (`F.current_timestamp()`).
# MAGIC
# MAGIC Do NOT clean, cast, or filter anything — Bronze preserves raw data exactly as received.

# COMMAND ----------

raw_orders_df = raw_orders_df.withColumn('ingestion_timestamp', F.current_timestamp())

raw_orders_df.write.format('delta').mode('overwrite').saveAsTable('exam_bronze_orders')

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Verify your Bronze table (DO NOT MODIFY)
# MAGIC SELECT * FROM exam_bronze_orders ORDER BY order_id LIMIT 10

# COMMAND ----------

# MAGIC %md
# MAGIC ### 1b: Short answer
# MAGIC
# MAGIC 1. Why does the Bronze layer keep data in its raw form without any cleaning or type casting?
# MAGIC 2. In a streaming pipeline, what Spark method would you use instead of `spark.read` to ingest data into Bronze continuously?

# COMMAND ----------

# MAGIC %md
# MAGIC **Your Answers:**
# MAGIC
# MAGIC 1. The bronze layer is an as-is raw data load because it is good for re-tracebility and auditability as well. Making it easy to revert back to previous states and debug issues with source data.
# MAGIC
# MAGIC 2. You would use spark.readStream to open a continuous stream.

# COMMAND ----------

# MAGIC %md
# MAGIC ---
# MAGIC # Part 2: Silver Layer
# MAGIC ---
# MAGIC
# MAGIC Silver is where you clean, validate, and enrich the data. In a streaming pipeline,
# MAGIC this is where you would use **stream-static joins** to enrich events with dimension data.

# COMMAND ----------

# MAGIC %md
# MAGIC ### 2a: Cast types and standardize
# MAGIC
# MAGIC Read from your Bronze table and apply these transformations:
# MAGIC - Deduplicate by `order_id` (keep first occurrence)
# MAGIC - Cast `order_timestamp` to timestamp type (invalid values become null)
# MAGIC - Cast `quantity` to integer (invalid values become null)
# MAGIC - Cast `total_amount` to double (invalid values become null)
# MAGIC - Standardize `status` to lowercase
# MAGIC
# MAGIC *Hint: Use `F.expr("try_cast(column AS type)")` to cast safely — invalid values become null instead of throwing an error.*
# MAGIC
# MAGIC Save the result as `cleaned_df`.

# COMMAND ----------

cleaned_df = (
    spark.table("exam_bronze_orders").drop_duplicates(['order_id']).withColumn('order_timestamp', F.expr("try_cast(order_timestamp AS timestamp)")).withColumn('quantity', F.expr("try_cast(quantity AS int)")).withColumn('total_amount', F.expr("try_cast(total_amount AS double)")).withColumn('status', F.lower(F.col('status')))
)

cleaned_df.show(truncate=False)
print(f"Cleaned rows: {cleaned_df.count()}")

# COMMAND ----------

# MAGIC %md
# MAGIC ### 2b: Apply quality checks
# MAGIC
# MAGIC Filter `cleaned_df` to keep only rows that pass ALL of these checks:
# MAGIC - `order_timestamp` is not null
# MAGIC - `store_id` is not null
# MAGIC - `product_id` is not null
# MAGIC - `quantity` is not null and greater than 0
# MAGIC - `total_amount` is not null and greater than 0
# MAGIC
# MAGIC Save valid rows as `valid_df` and rejected rows as `rejected_df`.

# COMMAND ----------

valid_df = (cleaned_df.filter((F.col('order_timestamp').isNotNull() & F.col('store_id').isNotNull() & F.col('product_id').isNotNull() & (F.col('quantity').isNotNull() & (F.col('quantity') > 0)) & (F.col('total_amount').isNotNull() & (F.col('total_amount') > 0)))))
rejected_df = (cleaned_df.filter(~(F.col('order_timestamp').isNotNull() & F.col('store_id').isNotNull() & F.col('product_id').isNotNull() & (F.col('quantity').isNotNull() & (F.col('quantity') > 0)) & (F.col('total_amount').isNotNull() & (F.col('total_amount') > 0)))))

print(f"Valid: {valid_df.count()}, Rejected: {rejected_df.count()}")
print("\nRejected rows:")
rejected_df.show(truncate=False)

# COMMAND ----------

# MAGIC %md
# MAGIC ### 2c: Enrich with dimension tables (stream-static join pattern)
# MAGIC
# MAGIC Join `valid_df` with:
# MAGIC 1. The `exam_stores` table to add `store_name`, `city`, and `region`
# MAGIC 2. The `exam_products` table to add `product_name` and `category`
# MAGIC
# MAGIC Use **inner joins** (this also filters out orders with invalid store_id or product_id
# MAGIC that don't match any dimension row, like STR-999).
# MAGIC
# MAGIC Save the result as a Delta table called `exam_silver_orders`.
# MAGIC
# MAGIC *Note: In a streaming pipeline, this is exactly where a stream-static join would go —
# MAGIC the orders stream joined with the static stores and products tables.*

# COMMAND ----------

v = valid_df.alias('v')
s = spark.table("exam_stores").alias('s')
p = spark.table("exam_products").alias('p')

silver_df = (
    v.join(
        s,
        F.col("v.store_id") == F.col("s.store_id"),
        "inner"
    )
    .join(
        p,
        F.col("v.product_id") == F.col("p.product_id"),
        "inner"
    )
    .select(
        "v.*",
        F.col("s.store_name"),
        F.col("s.city"),
        F.col("s.region"),
        F.col("p.product_name"),
        F.col("p.category")
    )
)

silver_df.write.format('delta').mode('overwrite').saveAsTable('exam_silver_orders') # Save as Delta table "exam_silver_orders"

silver_df.show(truncate=False)
print(f"Silver rows: {silver_df.count()}")

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Verify Silver table (DO NOT MODIFY)
# MAGIC SELECT order_id, order_timestamp, store_name, product_name, category, quantity, total_amount, region
# MAGIC FROM exam_silver_orders
# MAGIC ORDER BY order_timestamp
# MAGIC LIMIT 10

# COMMAND ----------

# MAGIC %md
# MAGIC ### 2d: Data quality report
# MAGIC
# MAGIC Write code that produces a summary showing:
# MAGIC - Total Bronze rows (from `exam_bronze_orders`)
# MAGIC - Total Silver rows (from `exam_silver_orders`)
# MAGIC - Rows lost (Bronze - Silver)
# MAGIC - Survival rate as a percentage (Silver / Bronze * 100)

# COMMAND ----------

bronze_df = spark.table('exam_bronze_orders')
silver_df = spark.table('exam_silver_orders')

total_bronze = bronze_df.count()
total_silver = silver_df.count()

rows_lost = total_bronze - total_silver

survival_rate = round((total_silver/total_bronze)*100, 2)

print(f"Total bronze: {total_bronze}\nTotal silver: {total_silver}\nRows Lost: {rows_lost}\nSurvival Rate: {survival_rate}")

# COMMAND ----------

# MAGIC %md
# MAGIC ---
# MAGIC # Part 3: Gold Layer
# MAGIC ---
# MAGIC
# MAGIC Gold tables are business-ready aggregates. Each Gold table answers a specific question.
# MAGIC Analysts query Gold with plain SQL — no pipeline knowledge needed.

# COMMAND ----------

# MAGIC %md
# MAGIC ### 3a: Daily revenue by store (aggregation + SQL)
# MAGIC
# MAGIC Using **SQL**, query `exam_silver_orders` to produce a table showing:
# MAGIC - `store_name`
# MAGIC - `order_date` (just the date part of `order_timestamp`, use `DATE(order_timestamp)`)
# MAGIC - `daily_revenue` (sum of `total_amount`)
# MAGIC - `daily_orders` (count of orders)
# MAGIC
# MAGIC Order by `store_name`, then `order_date`.
# MAGIC
# MAGIC Save the result as a Delta table called `exam_gold_daily_revenue`.

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE OR REPLACE TABLE exam_gold_daily_revenue AS
# MAGIC select store_name, to_date(order_timestamp) as order_date, sum(total_amount) as daily_revenue, count(order_id) as daily_orders from exam_silver_orders group by store_name, order_date order by store_name, order_date

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Verify (DO NOT MODIFY)
# MAGIC SELECT * FROM exam_gold_daily_revenue ORDER BY store_name, order_date

# COMMAND ----------

# MAGIC %md
# MAGIC ### 3b: Store ranking with window function (DataFrame API)
# MAGIC
# MAGIC Using the **DataFrame API**, calculate:
# MAGIC 1. Total revenue per store (across all days)
# MAGIC 2. Each store's percentage of overall revenue (rounded to 1 decimal)
# MAGIC 3. Rank stores by total revenue (highest = rank 1)
# MAGIC
# MAGIC Your result should have columns: `store_name`, `total_revenue`, `pct_of_total`, `revenue_rank`

# COMMAND ----------

from pyspark.sql import Window

silver = spark.table("exam_silver_orders")

windowSpec = Window.orderBy(F.desc('total_revenue'))
grouped_df = silver.groupby('store_name').agg(F.sum('total_amount').alias('total_revenue'))
total_revenue = grouped_df.agg(F.sum("total_revenue")).collect()[0][0]

result_df = grouped_df.withColumn(
    "pct_of_total", F.round((F.col("total_revenue") / total_revenue) * 100, 2)
).withColumn("revenue_rank", F.rank().over(windowSpec))

result_df.show()


# COMMAND ----------

# MAGIC %md
# MAGIC ### 3c: Top product per store with window function
# MAGIC
# MAGIC Using **either SQL or the DataFrame API**, find each store's best-selling product
# MAGIC (by total revenue). Your result should show:
# MAGIC - `store_name`
# MAGIC - `product_name`
# MAGIC - `product_revenue` (total revenue for that product at that store)
# MAGIC - `product_rank` (rank within each store, highest revenue = 1)
# MAGIC
# MAGIC **Only show rank 1** (the top product per store).
# MAGIC
# MAGIC *Hint: Use `RANK() OVER (PARTITION BY store_name ORDER BY ... DESC)` or the equivalent DataFrame window.*

# COMMAND ----------

# MAGIC %sql
# MAGIC select store_name, product_name, sum(total_amount) as product_revenue, rank() over (partition by store_name order by sum(total_amount) desc) as product_rank from exam_silver_orders group by store_name, product_name order by product_rank

# COMMAND ----------

# MAGIC %md
# MAGIC ---
# MAGIC # Part 4: Architecture & Design Short Answer
# MAGIC ---
# MAGIC
# MAGIC Answer each question in 2-4 sentences.

# COMMAND ----------

# MAGIC %md
# MAGIC ### 4a
# MAGIC
# MAGIC In Part 2c, you joined orders with the stores and products dimension tables using
# MAGIC regular batch joins. If this pipeline were running as a **Spark Structured Streaming**
# MAGIC job, what would this type of join be called? Would the join syntax change?

# COMMAND ----------

# MAGIC %md
# MAGIC **Your Answer:**
# MAGIC
# MAGIC The streaming to streaming join would be used instead, this can potentially cause memory overflow if not managed properly. The syntax is slightly different you will have to define a watermark first then set the time range between streams.

# COMMAND ----------

# MAGIC %md
# MAGIC ### 4b
# MAGIC
# MAGIC You built three layers: Bronze, Silver, Gold. Suppose you discover a bug in your
# MAGIC Silver cleaning logic (e.g., you accidentally filtered out valid orders).
# MAGIC Explain how the medallion architecture helps you recover from this mistake.

# COMMAND ----------

# MAGIC %md
# MAGIC **Your Answer:**
# MAGIC
# MAGIC Since the bronze layer contains your data un-manipulated, you can re-run the silver layer without filtering out valid orders. The bronze layer is there so you can revert back to the data when it was unprocessed or re-process it.

# COMMAND ----------

# MAGIC %md
# MAGIC ### 4c
# MAGIC
# MAGIC If Cosmic Coffee's order data were stored in **MongoDB** instead of a Delta table,
# MAGIC what MongoDB aggregation stage would you use to combine the orders collection
# MAGIC with a stores collection (similar to what you did in Part 2c)?
# MAGIC Name the stage and one key parameter it requires.

# COMMAND ----------

# MAGIC %md
# MAGIC **Your Answer:**
# MAGIC You would use $lookup in the agg stage to join two documents together. Then use the (from) parameter to join to a specific collection.

# COMMAND ----------

# MAGIC %md
# MAGIC ### 4d
# MAGIC
# MAGIC Explain what a **checkpoint** does in Spark Structured Streaming and why it is
# MAGIC required for every streaming write. What guarantee does it provide?

# COMMAND ----------

# MAGIC %md
# MAGIC **Your Answer:**
# MAGIC
# MAGIC Enables restarts and fault tolerance in an event something happens during a streaming event. This stores metadata about events to traceback progress. Provides processing guarantees.

# COMMAND ----------

# MAGIC %md
# MAGIC ### 4e
# MAGIC
# MAGIC Cosmic Coffee is growing fast and now has 1,000,000 temperature sensor readings per month
# MAGIC from their espresso machines, stored in MongoDB. A data engineer suggests using the
# MAGIC **Bucket Pattern** instead of storing one document per reading.
# MAGIC Explain what the Bucket Pattern does and why it would help here.

# COMMAND ----------

# MAGIC %md
# MAGIC **Your Answer:**
# MAGIC
# MAGIC This will group the data by a related element such as timestamp or date. This is more scalable than the document store pattern. Making it easier to query data based on things like average temperature per day.

# COMMAND ----------

# MAGIC %md
# MAGIC ---
# MAGIC ## End of Practical Exam
# MAGIC
# MAGIC **Checklist before submitting:**
# MAGIC - [ ] Part 1: Bronze table `exam_bronze_orders` created with `ingestion_timestamp`
# MAGIC - [ ] Part 2: Silver table `exam_silver_orders` created with enriched, clean data
# MAGIC - [ ] Part 3: Gold table `exam_gold_daily_revenue` created; store ranking and top products computed
# MAGIC - [ ] Part 4: All five short-answer questions answered
# MAGIC - [ ] All cells run without errors