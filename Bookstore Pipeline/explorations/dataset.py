# Databricks notebook source
# MAGIC %run ../../Copy-Datasets

# COMMAND ----------

print(bookstore.dataset_path)

# COMMAND ----------

bookstore.load_pipeline_data()
