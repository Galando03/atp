# Working notes

Chronological log of findings and decisions. Raw material for the README.

## Data sourcing
- Jeff Sackmann's `tennis_atp` repo (the canonical source) is no longer public on
  GitHub. His profile now shows only `tennis_MatchChartingProject`. He has publicly
  warned about license violations, which may explain the removal.
- First substitute: TennisMyLife (stats.tennismylife.org), ATP matches 1967-2026 in
  Sackmann's format. Abandoned it — their player IDs are alphanumeric (`B0BI`) while
  Sackmann's rankings use numeric IDs, so no clean join.
- Settled on the `tennis-sackmann-archive` mirror: original format, numeric IDs across
  matches/rankings/players, current through May 2026. Verified ID compatibility by
  tracing Alcaraz across all three files.

## Load
- Staged everything as TEXT so the load couldn't fail, then transformed in SQL.
- `\copy` converts empty CSV fields to NULL, not empty strings. Every blank in staging
  is NULL. This made my first `CASE WHEN hand = ''` a no-op.
- Loaded `atp_rankings_70s.csv` twice by accident. Caught it with a uniqueness check:
  41,452 rows in the table vs 20,726 in the file. Truncate + single reload fixed it.
  Only possible because staging is disposable and the pipeline re-runs from source.

## Key verification (all evidence-based, queries in 03_profiling.sql)
- `tourney_id` never spans multiple years → PK of `tournament`
- No tournament has >1 surface → `surface` belongs on `tournament`, not `match`
- `(tourney_id, match_num)` unique across 199,389 rows → PK of `match`
- `player_id` unique across 66,912 rows → PK of `player`
- Zero orphaned `winner_id`/`loser_id` → foreign keys work with no stub rows
- `(ranking_date, player)` NOT unique → 780 violations, see below

## Rankings duplicates
780 duplicate `(ranking_date, player)` pairs remain after the reload.
- 181 byte-identical → collapsed with `SELECT DISTINCT`
- 599 conflicting (same player/date, different rank and points) → excluded
- Example: player 206904 has two coherent parallel series across 12 consecutive weeks,
  one tracking 646→651→655 with points 35→45, the other frozen at 1 point with rank
  drifting 1966→1996. Not noise — two records. Cause not identified.
- Chose exclusion over a tie-break rule. 599/1.7M = 0.035%. A rule I couldn't justify
  would be worse than a documented gap. Revisit with more time.

## Value domains (from profiling, not documentation)
- `surface`: Hard, Clay, Grass, Carpet, NULL (2,990 rows). Carpet was phased out ~2009.
- `hand`: R, L, U, A. 48,620 are U — most players in the file appeared once and were
  never recorded. 16 NULLs folded into U.
- `tourney_level`: A, G, M, D, F, O (Olympics). No S or C in this dataset.
- `entry`: Q, WC, LL, PR, SE, ALT, NG, ITF, UP. 88% of rows are blank (direct acceptance).
- `round`: standard draw rounds plus RR, BR (bronze medal), ER.

## ER rounds
`ER` = Entry Round, from the ATP's 2007 round-robin format experiment. 13 events were
scheduled to trial it; 5 used it before it was abandoned on 21 March 2007 after
controversy at Las Vegas. Adelaide ran a 32-player hybrid where 16 lower-ranked players
played a single-elimination round to produce 8 who joined the 16 seeds in groups of 3.
The ER matches in this data are from Adelaide, Delray Beach, Las Vegas, and Buenos Aires.
Viña del Mar used the pure 24-player format with no entry round. These are legitimate
main-draw matches, not qualifying.

## Serve statistics coverage
Zero through 1989. 60 matches in 1990. 3,233 of 3,727 in 1991. Hard discontinuity —
1991 is when the ATP began tracking match stats. Even post-1991 coverage is ~88%, so
serve-stat queries need explicit NULL handling, not just a year filter.
2020 has 1,462 matches vs ~2,900 in neighbouring years (COVID).

## Data corrections applied in the transform
- **Heights**: 8 players with impossible values (3, 13, 15, 15, 15, 71, 71, 132 cm).
  None reconstructable. Two 71s looked like inches, but Shandarov is 185cm per Wikipedia
  (71in = 180cm) so the theory didn't hold. All 8 nullified. 62,751 of 66,912 players
  have no height at all — any height analysis covers ~6% of the file.
- **Dates of birth**: 102 with zero month and day (`19870000`). Nullified. 18,639 have
  none at all.
- **Walkovers**: 1,301 matches. 1,240 already had NULL minutes, 59 had 0, and 2 had
  positive values that I verified were errors. All set to NULL so walkovers are uniform
  and don't distort duration averages. The W/O remains identifiable in the score.
- **Score `6-36-3`**: a two-set score with the space lost. Corrected to `6-3 6-3`.
- **Unknown players**: player_id 199999 = "U Unknown". 3 matches have it on both sides —
  excluded, since a match needs two distinct players and they break the PK. 87 matches
  have it on one side only — kept, since they're still real results for the known player.
- **Negative break points**: 2 matches from tournament 1991-329 (Lendl/Courier and
  Edberg/Lendl) where the loser's `bpsaved` is exactly the negative of the winner's.
  Systematic processing error in the source, not random. Both break-point columns
  nullified on the loser side rather than reconstructed.

## Method note
I found the negative break-point values by *removing* a `>= 0` guard from the transform,
not by adding one. A guard would have silently nullified them and I'd never have known
the rows existed. Guards encode confirmed findings; constraints catch what you haven't
thought of.

## Known limitations
- No per-match dates. `tourney_date` is the tournament start, repeated on every match,
  so a first-round match and a final two weeks later carry the same date. Chronological
  ordering within a tournament needs `round` or `match_num`.
- Rankings excluded 599 conflicting pairs.
- Best-of-1 matches include experimental formats (first-to-31 points at Long Island,
  first-to-10 at Woodside, single sets at Denver). Any query parsing `score` will choke
  on these — filter to `best_of IN (3,5)`.
- Earliest match is 1967-12-28, before the Open Era (April 1968).

## Open / next
- Recount affected players in the remaining 780 duplicate pairs (the "120" figure was
  measured before the reload and is stale).
- Phase 3: 8-10 analytical queries.
- Compare source `winner_rank` against rank derived from the `ranking` table — gives the
  rankings data a real role and validates both.