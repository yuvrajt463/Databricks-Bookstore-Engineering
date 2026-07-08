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

def process_books_sales():
    
    orders_df = (spark.readStream.table("orders_silver")
                        .withColumn("book", F.explode("books"))
                )

    books_df = spark.read.table("current_books")

    query = (orders_df
                  .join(books_df, orders_df.book.book_id == books_df.book_id, "inner")
                  .writeStream
                     .outputMode("append")
                     .option("checkpointLocation", f"{bookstore.checkpoint_path}/books_sales")
                     .trigger(availableNow=True)
                     .table("books_sales")
    )

    query.awaitTermination()
    
process_books_sales()
