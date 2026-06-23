# Current State: fixture (restructured — present but unrecognized headers)

## Project Situation

This file is NON-EMPTY but uses headers the dashboard does not recognize. The parser must NOT
silently render "(section absent)" as if the file were missing — it must show a DISTINCT
unrecognized-structure marker so a restructured doc never looks like an absent one (the #1
dead-instrument guard).

## Where We Are Now

More non-empty content under an unrecognized header.
