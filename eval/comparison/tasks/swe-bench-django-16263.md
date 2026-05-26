# SWE-bench Task: django__django-16263

## Starter Integrity
Base commit: `321ecb40f4da842926e1bc07e11df4aabe53ca4b`
Repo: django/django (Django 4.2)

## Issue: Strip unused annotations from count queries

The query below produces a SQL statement that includes the Count('chapters'), despite not being used in any filter operations.

```python
Book.objects.annotate(Count('chapters')).count()
```

It produces the same results as:

```python
Book.objects.count()
```

Django could be more intelligent about what annotations to include in the query produced by queryset.count(), stripping out any annotations that are not referenced by filters, other annotations or ordering. This should speed up calls to count() with complex annotations.

There seems to be precedent for this: select_related calls are ignored with count() queries.

## Hints

- Same can be done for exists()
- A WIP PR exists at https://github.com/django/django/pull/8928/files
- The key logic is in django/db/models/sql/query.py
- `Person.objects.annotate(full_name=Concat('first_name', Value(' '), 'last_name')).values('pk').count()` already produces an efficient query — the issue is that without .values(), annotations are included unnecessarily
- The behaviour shows that .values('pk').count() already strips annotations, so the mechanism exists — it just needs to be applied to .count() directly

## Acceptance Criteria

Fix the Django ORM so that:
1. Unused non-aggregate annotations are stripped from count() queries (no subquery needed)
2. Unused aliased aggregates (.alias()) are stripped from count() queries (no subquery needed)
3. Unreferenced aggregate annotations are stripped from the subquery SELECT (subquery still needed for GROUP BY)
4. Referenced annotations (used in filters, other aggregates) are kept
5. Existing Django test suites pass with no regressions

## Key Files

- `django/db/models/sql/query.py` — where count queries are built
- `django/db/models/expressions.py` — expression base classes
- `django/db/models/query_utils.py` — Q objects and reference resolution
- `django/db/models/sql/where.py` — WHERE clause tree

## Evaluation

After implementation, the test patch will be applied and these tests must pass:
- `test_non_aggregate_annotation_pruned`
- `test_unreferenced_aggregate_annotation_pruned`
- `test_unused_aliased_aggregate_pruned`
- `test_referenced_aggregate_annotation_kept` (regression test)

## Time Budget

Expected: 1-4 hours for an experienced developer.
