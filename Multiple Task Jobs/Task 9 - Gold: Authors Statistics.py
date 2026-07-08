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

from pyspark.sql import functions as F

# COMMAND ----------

query = (spark.readStream
                 .table("books_sales")
                 .withWatermark("order_timestamp", "10 minutes")
                 .groupBy(
                     F.window("order_timestamp", "5 minutes").alias("time"),
                     "author")
                 .agg(
                     F.count("order_id").alias("orders_count"),
                     F.avg("quantity").alias ("avg_quantity"))
              .writeStream
                 .option("checkpointLocation", f"{bookstore.checkpoint_path}/authors_stats")
                 .trigger(availableNow=True)
                 .table("authors_stats")
            )

query.awaitTermination()
