TRUNCATE match_stats, ranking, match, tournament, player;

INSERT INTO player (player_id, first_name, last_name, hand, birth_date, country_code, height_cm)
SELECT
    player_id::INT,
    name_first,
    name_last,
    COALESCE(NULLIF(hand, ''), 'U'),
    CASE WHEN dob ~ '^\d{8}$' AND dob NOT LIKE '%0000' THEN TO_DATE(dob, 'YYYYMMDD') END,
    ioc,
    CASE WHEN NULLIF(height,'')::INT BETWEEN 140 AND 230 THEN NULLIF(height,'')::INT END
FROM stg_players;

INSERT INTO tournament (tourney_id, tourney_name, surface, tourney_start_date, tourney_draw_size, tourney_level)
SELECT DISTINCT
    tourney_id,
    tourney_name,
    surface,
    CASE WHEN tourney_date ~ '^\d{8}$' THEN TO_DATE(tourney_date, 'YYYYMMDD') END,
    CASE WHEN NULLIF(draw_size,'')::INT > 0 THEN NULLIF(draw_size,'')::INT END,
    tourney_level
FROM stg_matches;

INSERT INTO match (match_id, tourney_id, round, score, best_of, match_time_minutes)
SELECT 
    match_num::INT,
    tourney_id,
    round,
    CASE
        WHEN score = '6-36-3' THEN '6-3 6-3'
        ELSE score END,
    best_of::INT,
    CASE 
        WHEN score ILIKE '%W/O%' THEN NULL
        WHEN NULLIF(minutes,'')::INT > 0 THEN NULLIF(minutes,'')::INT END
FROM stg_matches;

INSERT INTO match_stats (match_id, tourney_id, player_id, is_winner, aces, serve_points, double_faults, first_serve_in, first_serve_won, second_serve_won, service_games, break_points_saved, break_points_faced, rank_pos, rank_points, player_entry, player_seed)
SELECT
    match_num::INT,
    tourney_id,
    winner_id::INT,
    TRUE,
    NULLIF(w_ace,'')::INT,
    NULLIF(w_svpt,'')::INT,
    NULLIF(w_df,'')::INT,
    NULLIF(w_1stIn,'')::INT,
    NULLIF(w_1stWon,'')::INT,
    NULLIF(w_2ndWon,'')::INT,
    NULLIF(w_SvGms,'')::INT,
    NULLIF(w_bpSaved,'')::INT,
    NULLIF(w_bpFaced,'')::INT,
    NULLIF(winner_rank,'')::INT,
    NULLIF(winner_rank_points,'')::INT,
    CASE UPPER(NULLIF(winner_entry,''))
        WHEN 'L' THEN 'LL'
        WHEN 'W' THEN 'WC'
        WHEN 'S' THEN 'SE'
        ELSE UPPER(NULLIF(winner_entry,''))
    END,
    NULLIF(winner_seed,'')::INT
FROM stg_matches
    WHERE winner_id <> loser_id
UNION ALL
SELECT
    match_num::INT,
    tourney_id,
    loser_id::INT,
    FALSE,
    NULLIF(l_ace,'')::INT,
    NULLIF(l_svpt,'')::INT,
    NULLIF(l_df,'')::INT,
    NULLIF(l_1stIn,'')::INT,
    NULLIF(l_1stWon,'')::INT,
    NULLIF(l_2ndWon,'')::INT,
    NULLIF(l_SvGms,'')::INT,
    CASE WHEN NULLIF(l_bpSaved,'')::INT >= 0 THEN NULLIF(l_bpSaved,'')::INT END,
    CASE WHEN NULLIF(l_bpSaved,'')::INT >= 0 THEN NULLIF(l_bpFaced,'')::INT END,
    NULLIF(loser_rank,'')::INT,
    NULLIF(loser_rank_points,'')::INT,
    CASE UPPER(NULLIF(loser_entry,''))
        WHEN 'L' THEN 'LL'
        WHEN 'W' THEN 'WC'
        WHEN 'S' THEN 'SE'
        ELSE UPPER(NULLIF(loser_entry,''))
    END,
    NULLIF(loser_seed,'')::INT
FROM stg_matches
WHERE winner_id <> loser_id;

INSERT INTO ranking (ranking_date, player_id, rank_pos, rank_points)
WITH bad_pairs AS (
    SELECT ranking_date, player
    FROM stg_rankings
    GROUP BY ranking_date, player
    HAVING COUNT(DISTINCT (rank, points)) > 1
)
SELECT DISTINCT
    TO_DATE(s.ranking_date, 'YYYYMMDD'),
    s.player::INT,
    s.rank::INT,
    s.points::INT
FROM stg_rankings s
LEFT JOIN bad_pairs b
  ON b.ranking_date = s.ranking_date AND b.player = s.player
WHERE b.player IS NULL;
        
