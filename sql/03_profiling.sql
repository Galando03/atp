-- This query looks if a tournament has a distinct tourney_id for each year or if it shares the same one.
-- If a tournament has the same tourney_id for multiple years, it will be returned in the result set.
/*
\echo '=== Q1: Does any tourney_id span multiple years? ==='
SELECT tourney_id, COUNT(DISTINCT LEFT(tourney_date, 4)) AS n
FROM stg_matches
GROUP BY tourney_id
HAVING COUNT(DISTINCT LEFT(tourney_date, 4)) > 1;

\echo '=== Q2: Does any tourney_id have matches on different surfaces? ==='
-- This query looks if the same tournament can be played in different surfaces.
-- If a tournament has matches on different surfaces, it will be returned in the result set.
SELECT tourney_id, COUNT(DISTINCT surface) AS n
FROM stg_matches
GROUP BY tourney_id
HAVING COUNT(DISTINCT surface) > 1;

\echo '=== Q3: Is every tourney_id and match_num unique? ==='
-- This query looks if a tournament has a unique match_num for each match.
-- If a tournament has the same match_num for multiple matches, it will be returned in the result set.
SELECT tourney_id, match_num, COUNT(*) AS n
FROM stg_matches
GROUP BY tourney_id, match_num
HAVING COUNT(*) > 1;

--\echo '=== Q4: Is every ranking_date, player pair unique? ==='
-- This query looks if a player holds one rank per week.
-- If a player has multiple ranks for the same week, it will be returned in the result set.
/*SELECT ranking_date, player, COUNT(*) AS n
FROM stg_rankings
GROUP BY ranking_date, player
HAVING COUNT(*) > 1;*/

\echo '=== Q5: Is every player_id unique? ==='
-- This query looks if a player_id is unique in the rankings table.
-- If a player_id is not unique, it will be returned in the result set.
SELECT player_id, COUNT(*) AS n
FROM stg_players
GROUP BY player_id
HAVING COUNT(*) > 1;


/*
WITH dupes AS (
    SELECT ranking_date, player FROM stg_rankings
    GROUP BY ranking_date, player HAVING COUNT(*) > 1
)
SELECT r.ranking_date, r.rank, r.player, r.points 
FROM stg_rankings r
JOIN dupes d ON r.ranking_date = d.ranking_date AND r.player = d.player
ORDER BY r.rank, r.ranking_date;

WITH dupes AS (
  SELECT ranking_date, player
  FROM stg_rankings
  GROUP BY ranking_date, player HAVING COUNT(*) > 1
)
SELECT
  COUNT(*) FILTER (WHERE n_distinct_rows = 1) AS identical,
  COUNT(*) FILTER (WHERE n_distinct_rows > 1) AS conflicting
FROM (
  SELECT d.ranking_date, d.player,
         COUNT(DISTINCT (r.rank, r.points)) AS n_distinct_rows
  FROM dupes d
  JOIN stg_rankings r USING (ranking_date, player)
  GROUP BY 1,2
) x;*/

/*
SELECT DISTINCT surface FROM stg_matches;
SELECT DISTINCT tourney_level FROM stg_matches;
SELECT DISTINCT hand FROM stg_players;

SELECT DISTINCT loser_entry FROM stg_matches;
SELECT DISTINCT winner_entry FROM stg_matches;
*
SELECT entry, COUNT(*)
FROM (
  SELECT winner_entry AS entry FROM stg_matches
  UNION ALL
  SELECT loser_entry FROM stg_matches
) e
GROUP BY entry
ORDER BY COUNT(*) DESC;


SELECT tourney_name, LEFT(tourney_date,4) AS yr, winner_name, loser_name, winner_entry, loser_entry
FROM stg_matches
WHERE winner_entry IN ('S','L','W','UP') OR loser_entry IN ('S','L','W','UP');

*/


SELECT DISTINCT round FROM stg_matches;
SELECT DISTINCT best_of FROM stg_matches;
SELECT tourney_name, score, round FROM stg_matches
WHERE best_of = '1';

SELECT * FROM stg_matches
WHERE round = 'ER';
SELECT name_first, name_last, height FROM stg_players
WHERE height IS NULL;
SELECT DISTINCT height FROM stg_players;



SELECT height, COUNT(*) FROM stg_players
WHERE NULLIF(height,'')::INT < 140
GROUP BY height ORDER BY height;

SELECT player_id, name_first, name_last, height, dob, ioc
FROM stg_players
WHERE NULLIF(height,'')::INT < 140
LIMIT 20;

SELECT MAX(LENGTH(name_first)), MAX(LENGTH(name_last)) FROM stg_players;
SELECT MAX(LENGTH(tourney_name)), MAX(LENGTH(score)) FROM stg_matches;
SELECT 
  COUNT(*) FILTER (WHERE name_first IS NULL) AS nulls,
  COUNT(*) FILTER (WHERE name_first = '') AS empties
FROM stg_players;
SELECT 
  COUNT(*) FILTER (WHERE hand IS NULL) AS hand_null,
  COUNT(*) FILTER (WHERE hand = '') AS hand_empty,
  COUNT(*) FILTER (WHERE height IS NULL) AS ht_null,
  COUNT(*) FILTER (WHERE height = '') AS ht_empty,
  COUNT(*) FILTER (WHERE dob IS NULL) AS dob_null,
  COUNT(*) FILTER (WHERE dob = '') AS dob_empty,
  COUNT(*) FILTER (WHERE name_last IS NULL) AS ln_null,
  COUNT(*) FILTER (WHERE name_last = '') AS ln_empty
FROM stg_players;

SELECT 
  COUNT(*) FILTER (WHERE dob LIKE '%0000') AS both_zero,
  COUNT(*) FILTER (WHERE SUBSTRING(dob,5,2) = '00' AND SUBSTRING(dob,7,2) <> '00') AS month_zero_only,
  COUNT(*) FILTER (WHERE SUBSTRING(dob,5,2) <> '00' AND SUBSTRING(dob,7,2) = '00') AS day_zero_only
FROM stg_players WHERE dob ~ '^\d{8}$';
*/

SELECT 
  COUNT(*) FILTER (WHERE tourney_name IS NULL) AS name_null,
  COUNT(*) FILTER (WHERE tourney_date IS NULL) AS date_null,
  COUNT(*) FILTER (WHERE tourney_id IS NULL) AS id_null,
  COUNT(*) FILTER (WHERE winner_id IS NULL) AS winner_null,
  COUNT(*) FILTER (WHERE loser_id IS NULL) AS loser_null
FROM stg_matches;

SELECT 
  MIN(NULLIF(draw_size,'')::INT) AS min_draw,
  MIN(NULLIF(minutes,'')::INT) AS min_minutes,
  MIN(NULLIF(winner_seed,'')::INT) AS min_seed,
  MIN(NULLIF(winner_rank,'')::INT) AS min_rank
FROM stg_matches;

SELECT COUNT(*) FROM stg_matches WHERE NULLIF(minutes,'')::INT = 0;

SELECT tourney_name, LEFT(tourney_date,4) AS yr, winner_name, loser_name, score, minutes
FROM stg_matches WHERE NULLIF(minutes,'')::INT = 0 LIMIT 10;