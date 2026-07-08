# Databricks notebook source
# MAGIC
# MAGIC %run ../Copy-Datasets
# MAGIC

# COMMAND ----------


# %run ../Copy-Datasets

current_catalog = spark.sql("SELECT current_catalog()").collect()[0][0]
dataset_bookstore = f"/Volumes/{current_catalog}/bookstore_eng_pro/dataset"
checkpoint_path = f"/Volumes/{current_catalog}/bookstore_eng_pro/checkpoints"
print(dataset_bookstore)

# COMMAND ----------

# MAGIC %sql
# MAGIC
# MAGIC CREATE VIEW IF NOT EXISTS countries_stats_vw AS (
# MAGIC   SELECT country, date_trunc("DD", order_timestamp) order_date, count(order_id) orders_count, sum(quantity) books_count
# MAGIC   FROM customers_orders
# MAGIC   GROUP BY country, date_trunc("DD", order_timestamp)
# MAGIC )
