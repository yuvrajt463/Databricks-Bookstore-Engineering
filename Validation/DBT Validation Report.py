# Databricks notebook source
# MAGIC %md
# MAGIC # Strict dbt validation report
# MAGIC
# MAGIC This read-only report shows the latest persisted dbt results, order-source freshness, and safe stored failure records. It runs after the dbt task whether validation succeeds or fails.

# COMMAND ----------

import re

dbutils.widgets.text("catalog", spark.sql("SELECT current_catalog()").first()[0])
dbutils.widgets.text("source_schema", "bookstore_eng_pro")
dbutils.widgets.text("audit_schema", "bookstore_dbt_audit")


def validated_identifier(widget_name):
    value = dbutils.widgets.get(widget_name)
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", value):
        raise ValueError(f"Invalid SQL identifier supplied for {widget_name}")
    return value


catalog = validated_identifier("catalog")
source_schema = validated_identifier("source_schema")
audit_schema = validated_identifier("audit_schema")


def quoted(*parts):
    return ".".join(f"`{part}`" for part in parts)


audit_table = quoted(catalog, audit_schema, "ops_dbt_validation_results")
orders_table = quoted(catalog, source_schema, "orders_silver")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Latest dbt invocation

# COMMAND ----------

if spark.catalog.tableExists(f"{catalog}.{audit_schema}.ops_dbt_validation_results"):
    display(spark.sql(f"""
        WITH latest AS (
          SELECT invocation_id
          FROM {audit_table}
          GROUP BY invocation_id
          ORDER BY MAX(generated_at) DESC
          LIMIT 1
        )
        SELECT
          results.invocation_id,
          results.command,
          results.status,
          COUNT(*) AS nodes,
          SUM(results.failures) AS failures,
          ROUND(SUM(results.execution_seconds), 3) AS execution_seconds,
          MAX(results.generated_at) AS generated_at
        FROM {audit_table} AS results
        INNER JOIN latest USING (invocation_id)
        GROUP BY results.invocation_id, results.command, results.status
        ORDER BY results.command, results.status
    """))
else:
    print(f"No validation audit table exists at {catalog}.{audit_schema}.ops_dbt_validation_results.")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Failed validation nodes

# COMMAND ----------

if spark.catalog.tableExists(f"{catalog}.{audit_schema}.ops_dbt_validation_results"):
    display(spark.sql(f"""
        WITH latest AS (
          SELECT invocation_id
          FROM {audit_table}
          GROUP BY invocation_id
          ORDER BY MAX(generated_at) DESC
          LIMIT 1
        )
        SELECT
          results.node_id,
          results.resource_type,
          results.status,
          results.failures,
          results.message,
          results.generated_at
        FROM {audit_table} AS results
        INNER JOIN latest USING (invocation_id)
        WHERE results.status NOT IN ('success', 'pass')
        ORDER BY results.failures DESC, results.node_id
    """))

# COMMAND ----------

# MAGIC %md
# MAGIC ## Order-source freshness

# COMMAND ----------

if spark.catalog.tableExists(f"{catalog}.{source_schema}.orders_silver"):
    display(spark.sql(f"""
        SELECT
          MAX(_loaded_at) AS max_loaded_at,
          TIMESTAMPDIFF(MINUTE, MAX(_loaded_at), CURRENT_TIMESTAMP()) AS age_minutes,
          CASE
            WHEN MAX(_loaded_at) IS NULL THEN 'ERROR'
            WHEN TIMESTAMPDIFF(MINUTE, MAX(_loaded_at), CURRENT_TIMESTAMP()) > 30 THEN 'ERROR'
            WHEN TIMESTAMPDIFF(MINUTE, MAX(_loaded_at), CURRENT_TIMESTAMP()) > 15 THEN 'WARN'
            ELSE 'PASS'
          END AS freshness_status
        FROM {orders_table}
    """))
else:
    print(f"No order source exists at {catalog}.{source_schema}.orders_silver.")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Stored failure records
# MAGIC
# MAGIC Only business keys and stable reason codes are displayed. Results are limited to 100 rows per test table.

# COMMAND ----------

if spark.catalog.databaseExists(f"{catalog}.{audit_schema}"):
    failure_tables = [
        row.tableName
        for row in spark.sql(f"SHOW TABLES IN {quoted(catalog, audit_schema)}").collect()
        if row.tableName != "ops_dbt_validation_results"
    ]

    if not failure_tables:
        print("No stored failure tables were found.")

    displayed_failures = 0
    for table_name in sorted(failure_tables):
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", table_name):
            continue
        failure_table = quoted(catalog, audit_schema, table_name)
        if spark.sql(f"SELECT 1 FROM {failure_table} LIMIT 1").take(1):
            displayed_failures += 1
            print(f"Stored failures: {table_name}")
            display(spark.sql(f"SELECT * FROM {failure_table} LIMIT 100"))

    if failure_tables and displayed_failures == 0:
        print("Stored test tables exist, but none contain failing rows.")
else:
    print(f"No audit schema exists at {catalog}.{audit_schema}.")
