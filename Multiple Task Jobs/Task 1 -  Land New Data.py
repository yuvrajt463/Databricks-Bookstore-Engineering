# Databricks notebook source
# MAGIC %run ../Copy-Datasets

# COMMAND ----------

# %run ../Copy-Datasets

current_catalog = spark.sql("SELECT current_catalog()").collect()[0][0]
dataset_bookstore = f"/Volumes/{current_catalog}/bookstore_eng_pro/dataset"
checkpoint_path = f"/Volumes/{current_catalog}/bookstore_eng_pro/checkpoints"
print(dataset_bookstore)

# COMMAND ----------

spark.conf.set("spark.databricks.delta.optimizeWrite.enabled", True)
spark.conf.set("spark.databricks.delta.autoCompact.enabled", True)

# COMMAND ----------

dbutils.widgets.text("number_of_files", "1")
num_files = int(dbutils.widgets.get("number_of_files"))

# COMMAND ----------

bookstore.load_new_data(num_files)
