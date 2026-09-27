DROP TABLE IF EXISTS match_stats, ranking, match, tournament, player CASCADE;

CREATE TABLE player (
    player_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    hand TEXT CHECK (hand IN ('R', 'L', 'U', 'A')),
    birth_date DATE,
    country_code CHAR(3),
    height_cm INT CHECK (height_cm BETWEEN 140 AND 230)
);

CREATE TABLE tournament (
    tourney_id TEXT PRIMARY KEY,
    tourney_name VARCHAR(100) NOT NULL,
    surface TEXT CHECK (surface IN ('Hard', 'Clay', 'Grass', 'Carpet')),
    tourney_start_date DATE NOT NULL,
    tourney_draw_size INT CHECK (tourney_draw_size > 0),
    tourney_level TEXT CHECK (tourney_level IN ('G', 'M', 'A', 'F', 'D', 'O'))
);

CREATE TABLE match (
    match_id INT NOT NULL,
    tourney_id TEXT NOT NULL,
    PRIMARY KEY (match_id, tourney_id),
    FOREIGN KEY (tourney_id) REFERENCES tournament(tourney_id),
    round TEXT CHECK (round IN ('R128', 'R64', 'R32', 'R16', 'QF', 'SF', 'F', 'RR', 'BR', 'ER')),
    score VARCHAR(50),
    best_of INT CHECK (best_of IN (1, 3, 5)),
    match_time_minutes INT CHECK (match_time_minutes > 0)
);

CREATE TABLE match_stats (
    match_id INT NOT NULL,
    tourney_id TEXT NOT NULL,
    player_id INT NOT NULL,
    PRIMARY KEY (match_id, tourney_id, player_id),
    FOREIGN KEY (match_id, tourney_id) REFERENCES match(match_id, tourney_id),
    FOREIGN KEY (player_id) REFERENCES player(player_id),
    is_winner BOOLEAN NOT NULL,
    aces INT CHECK (aces >= 0),
    serve_points INT CHECK (serve_points >= 0),
    double_faults INT CHECK (double_faults >= 0),
    first_serve_in INT CHECK (first_serve_in >= 0),
    first_serve_won INT CHECK (first_serve_won >= 0),
    second_serve_won INT CHECK (second_serve_won >= 0),
    service_games INT CHECK (service_games >= 0),
    break_points_saved INT CHECK (break_points_saved >= 0),
    break_points_faced INT CHECK (break_points_faced >= 0),
    rank_pos INT CHECK (rank_pos > 0),
    rank_points INT CHECK (rank_points >= 0),
    player_entry TEXT CHECK (player_entry IN ('WC', 'Q', 'LL', 'SE', 'ALT', 'UP', 'ITF', 'NG', 'PR')),
    player_seed INT CHECK (player_seed > 0)
);

CREATE TABLE ranking (
    ranking_date DATE NOT NULL,
    player_id INT REFERENCES player(player_id),
    rank_pos INT CHECK (rank_pos > 0),
    rank_points INT CHECK (rank_points >= 0),
    PRIMARY KEY (ranking_date, player_id)
);

CREATE UNIQUE INDEX one_winner_per_match 
ON match_stats (match_id, tourney_id) WHERE is_winner;