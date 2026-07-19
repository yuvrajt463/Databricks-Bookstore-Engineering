{% macro persist_validation_results(results) %}
    {% if execute and target.database %}
        {% set audit_schema = var('audit_schema', 'bookstore_dbt_audit') %}
        {% set audit_relation = adapter.quote(target.database) ~ '.' ~ adapter.quote(audit_schema) ~ '.' ~ adapter.quote('ops_dbt_validation_results') %}
        {% set command_name = invocation_args_dict.get('which', 'unknown') | replace("'", "''") %}

        {% do run_query('create schema if not exists ' ~ adapter.quote(target.database) ~ '.' ~ adapter.quote(audit_schema)) %}
        {% do run_query(
            'create table if not exists ' ~ audit_relation ~ ' ('
            ~ 'invocation_id string, command string, node_id string, resource_type string, '
            ~ 'status string, failures bigint, execution_seconds double, generated_at timestamp, message string'
            ~ ') using delta'
        ) %}

        {% for result in results %}
            {% set node_id = result.node.unique_id | replace("'", "''") %}
            {% set resource_type = result.node.resource_type | string | replace("'", "''") %}
            {% set status = result.status | string | replace("'", "''") %}
            {% set failure_count = result.failures if result.failures is not none else 0 %}
            {% set safe_message = ('dbt ' ~ resource_type ~ ' completed with status ' ~ status) | replace("'", "''") %}
            {% set insert_sql %}
                insert into {{ audit_relation }}
                values (
                    '{{ invocation_id }}',
                    '{{ command_name }}',
                    '{{ node_id }}',
                    '{{ resource_type }}',
                    '{{ status }}',
                    {{ failure_count | int }},
                    {{ result.execution_time | float }},
                    current_timestamp(),
                    '{{ safe_message }}'
                )
            {% endset %}
            {% do run_query(insert_sql) %}
        {% endfor %}
    {% endif %}
{% endmacro %}
