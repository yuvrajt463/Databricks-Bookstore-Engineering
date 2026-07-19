# Bookstore dbt validation

This dbt project validates the declarative Databricks Silver tables and builds a small, governed Gold layer. It is designed to run as the `strict_dbt_validation` task defined by the repository's Databricks bundle.

## Inputs

- `orders_silver`
- `customers_silver`
- `books_silver`

The sources are read from the catalog selected by the dbt target and the schema supplied through the `source_schema` variable.

## Outputs

- `fct_order_line`: one row per order-array position, priced from the book version valid at order time.
- `agg_author_daily`: daily author sales metrics derived from the validated fact.
- `ops_dbt_validation_results`: sanitized execution results in the audit schema.

## Databricks commands

The native dbt task runs these commands in order:

```text
dbt deps
dbt parse --warn-error --no-partial-parse
dbt source freshness --select source:bookstore_silver --warn-error
dbt test --select source:bookstore_silver --fail-fast
dbt build --select tag:gold_validation --fail-fast --warn-error
```

Any freshness warning, source failure, unit-test failure, contract violation, or Gold data-test failure returns a nonzero status and blocks downstream publication.

For local development, copy `profiles.example.yml` outside the repository, export the referenced environment variables, and pass its directory with `--profiles-dir`. Never commit credentials or a populated profile.
