# ATP Tennis SQL Portfolio

A normalized PostgreSQL database built from 59 years of ATP tour-level match results,
with an evidence-driven schema design and a fully reproducible load pipeline.

**Status:** schema and load complete. Analytical queries, index tuning, and charts in progress.

## What this project is

Nearly 200,000 professional tennis matches from 1968 to 2026, loaded from CSV into a
five-table relational schema. Every design decision — primary keys, nullability, CHECK
constraints — was made by querying the raw data first rather than assuming. The queries
that produced each decision are in `sql/03_profiling.sql`.

## Data source

Jeff Sackmann's ATP dataset, via a public archive mirror. The canonical
`JeffSackmann/tennis_atp` repository is no longer available on GitHub; the mirror
preserves the original format and numeric player IDs.

Data is **not** included in this repository. It is licensed
[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) — attribution
required, non-commercial use only. See *Reproducing* below to fetch it.

Snapshot used: matches through 2026-05-25.

## Schema

Five tables. The central design decision is `match_stats`.

| Table | Grain | Key |
|---|---|---|
| `player` | one row per player | `player_id` |
| `tournament` | one row per tournament | `tourney_id` |
| `match` | one row per match | `(match_id, tourney_id)` |
| `match_stats` | **one row per player per match** | `(match_id, tourney_id, player_id)` |
| `ranking` | one row per player per week | `(ranking_date, player_id)` |

### Why `match_stats` exists

The source stores matches in winner/loser wide format: one row per match with mirrored
`w_ace`/`l_ace`, `winner_rank`/`loser_rank` columns. That shape makes every
player-centric question awkward — "Federer's record on clay" requires checking both
whether he won and whether he lost, then unioning the halves.

Pivoting to one row per player per match turns head-to-head records, win streaks, and
surface splits into ordinary `GROUP BY` aggregation. The cost is doubled row count
(~399k rows) and needing a self-join on the match key to answer "who played whom."

"Exactly one winner per match" can't be expressed as a CHECK constraint, since CHECKs
can't span rows. It's enforced with a partial unique index:

```sql
CREATE UNIQUE INDEX one_winner_per_match
ON match_stats (match_id, tourney_id) WHERE is_winner;
```

## Pipeline

Raw CSVs → staging (all TEXT) → clean typed tables.

Every column lands in staging as `TEXT` so the load cannot fail on malformed values.
Casting, null handling, and corrections all happen in SQL during the transform, where
they are visible, auditable code rather than one-off commands. This is the ELT pattern
that tools like dbt are built around.

The practical payoff: when a raw date is `20240101` or a height is `3`, you can query
the problem and see how widespread it is before deciding what to do. Loading straight
into a typed schema surfaces one error message at a time with no sense of scale.

Scripts run in order:

| File | Purpose |
|---|---|
| `sql/01_staging.sql` | three all-TEXT staging tables |
| `sql/02_schema.sql` | five clean tables, keys, constraints, partial index |
| `sql/03_profiling.sql` | the queries behind every schema decision |
| `sql/04_transform.sql` | staging → clean, with all corrections |

`02_schema.sql` and `04_transform.sql` are idempotent — safe to re-run at any point.

## Data quality findings

Selected findings from profiling. Full log in [NOTES.md](NOTES.md).

**Serve statistics begin in 1991.** Coverage is zero through 1989, 60 matches in 1990,
then 3,233 of 3,727 in 1991 — the year the ATP began tracking match stats. Coverage
remains ~88% after that, so serve-stat queries need explicit NULL handling rather than
a year filter alone.

**`ER` is a round from a five-week experiment.** The ATP trialled a round-robin format
in early 2007 and abandoned it in March. `ER` (Entry Round) was the preliminary
elimination round; it appears at four tournaments and nowhere else in 59 years.

**Two matches have negative break-point counts.** Both from the same 1991 tournament,
both with the loser's value exactly the negative of the winner's — a systematic
processing error, not random corruption. Found by *removing* a defensive guard from the
transform so the CHECK constraint could fire.

**599 conflicting rankings rows were excluded.** Some players have two parallel,
internally coherent ranking series on the same dates. Rather than invent a tie-break
rule, they are excluded and documented: 0.035% of the rankings table.

**Eight players have impossible heights** (3 to 132 cm). Two looked like inches rather
than centimetres, but external verification was inconsistent, so all eight were
nullified rather than corrected on a guess.

## Reproducing

Requires PostgreSQL 15+ and Git.

```bash
createdb tennis
git clone <archive-url> sackman
```

Then, from psql: