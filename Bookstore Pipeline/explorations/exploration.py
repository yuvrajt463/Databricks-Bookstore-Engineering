# Databricks notebook source
#spark.sql("USE CATALOG `<my-catalog>`")
spark.sql("USE SCHEMA `bookstore_etl`")

# COMMAND ----------

display(spark.sql("SELECT count(*) FROM bronze"))
