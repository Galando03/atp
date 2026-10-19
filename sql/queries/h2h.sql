-- Head-to-head query for ATP players
-- This query retrieves the head-to-head statistics between pairs of players in ATP matches, it does not count matches where either player is a walkover.
SELECT CONCAT_WS(' ', p1.first_name, p1.last_name) AS player_a, CONCAT_WS(' ', p2.first_name, p2.last_name) AS player_b, COUNT(*) AS total_matches, COUNT(*) FILTER (WHERE a.is_winner) AS a_wins, COUNT(*) FILTER (WHERE b.is_winner) AS b_wins FROM match_stats a
INNER JOIN match_stats b ON a.match_id = b.match_id AND a.tourney_id = b.tourney_id AND a.player_id < b.player_id
JOIN match m ON a.match_id = m.match_id AND a.tourney_id = m.tourney_id
JOIN player p1 ON a.player_id = p1.player_id
JOIN player p2 ON b.player_id = p2.player_id
WHERE COALESCE(m.score, '') NOT ILIKE '%W/O%'
GROUP BY p1.player_id, p2.player_id
HAVING COUNT(*) > 15
ORDER BY total_matches DESC
;