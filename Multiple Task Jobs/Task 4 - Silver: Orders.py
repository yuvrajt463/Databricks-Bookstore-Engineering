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

json_schema = "order_id STRING, order_timestamp Timestamp, customer_id STRING, quantity BIGINT, total BIGINT, books ARRAY<STRUCT<book_id STRING, quantity BIGINT, subtotal BIGINT>>"

# COMMAND ----------

deduped_df = (spark.readStream
                   .table("bronze")
                   .filter("topic = 'orders'")
                   .select(F.from_json(F.col("value").cast("string"), json_schema).alias("v"))
                   .select("v.*")
                   .withWatermark("order_timestamp", "30 seconds")
                   .dropDuplicates(["order_id", "order_timestamp"]))

# COMMAND ----------

def upsert_data(microBatchDF, batch):
    microBatchDF.createOrReplaceTempView("orders_microbatch")
    
    sql_query = """
      MERGE INTO orders_silver a
      USING orders_microbatch b
      ON a.order_id=b.order_id AND a.order_timestamp=b.order_timestamp
      WHEN NOT MATCHED THEN INSERT *
    """
    
    microBatchDF.sparkSession.sql(sql_query)
    #microBatchDF._jdf.sparkSession().sql(sql_query)

# COMMAND ----------

# MAGIC %sql
# MAGIC
# MAGIC CREATE TABLE IF NOT EXISTS orders_silver
# MAGIC (order_id STRING, order_timestamp Timestamp, customer_id STRING, quantity BIGINT, total BIGINT, books ARRAY<STRUCT<book_id STRING, quantity BIGINT, subtotal BIGINT>>)

# COMMAND ----------

query = (deduped_df.writeStream
                   .foreachBatch(upsert_data)
                   .option("checkpointLocation", f"{bookstore.checkpoint_path}/orders_silver")
                   .trigger(availableNow=True)
                   .start())

query.awaitTermination()
