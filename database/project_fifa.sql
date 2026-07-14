-- =====================================================
-- World Cup Player Analytics Database
-- Jack Williams wrote the original database design and SQL.
-- Joshua Cochran made a few small changes so the script would run correctly.
--
-- This script assumes that the CSV has already been imported into:
-- worldcup.fifa_world_cup_2026_player_performance
-- =====================================================

USE worldcup;

-- =====================================================
-- Clear out tables from an earlier or incomplete run
-- Added by Joshua Cochran
-- The original imported CSV table is left alone.
-- =====================================================
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS scouting_notes;
DROP TABLE IF EXISTS player_tournament_stats;
DROP TABLE IF EXISTS player_match_stats;
DROP TABLE IF EXISTS matches;
DROP TABLE IF EXISTS stadiums;
DROP TABLE IF EXISTS players;
DROP TABLE IF EXISTS teams;
SET FOREIGN_KEY_CHECKS = 1;

-- author:Jack Williams
-- create table players
CREATE TABLE players (
  player_id VARCHAR(50) PRIMARY KEY,
  player_name VARCHAR(100),
  age INT,
  nationality VARCHAR(50),
  team VARCHAR(50),
  jersey_number INT,
  position VARCHAR(20),
  height_cm INT,
  weight_kg INT,
  preferred_foot VARCHAR(5),
  club_name VARCHAR(30),
  market_value_eur INT
);

-- author:Jack Williams
-- create table matches
-- Updated by Joshua Cochran:
-- These fields can be different depending on which team's player the row belongs to,
-- so they fit better in player_match_stats than in matches.
CREATE TABLE matches (
  match_id VARCHAR(50) PRIMARY KEY,
  match_date DATE,
  stadium VARCHAR(50),
  city VARCHAR(30),
  tournament_stage VARCHAR(50)
);

-- author:Jack Williams
-- create table player match stats
CREATE TABLE player_match_stats (
  id INT AUTO_INCREMENT PRIMARY KEY,
  player_id VARCHAR(50),
  match_id VARCHAR(50),
  opponent_team VARCHAR(50),
  match_result VARCHAR(20),
  goals_team INT,
  goals_opponent INT,
  minutes_played INT,
  goals INT, assists INT, shots INT, shots_on_target INT,
  expected_goals_xg DOUBLE, expected_assists_xa DOUBLE,
  key_passes INT, successful_passes INT, total_passes INT, pass_accuracy DOUBLE,
  dribbles_attempted INT, successful_dribbles INT,
  crosses INT, successful_crosses INT,
  tackles INT, interceptions INT, clearances INT, blocks INT,
  aerial_duels_won INT, aerial_duels_lost INT,
  recoveries INT, defensive_actions INT,
  fouls_committed INT, fouls_suffered INT,
  yellow_cards INT, red_cards INT, offsides INT,
  saves INT, save_percentage DOUBLE, punches INT,
  clean_sheet INT, goals_conceded INT, penalty_saves INT,
  distance_covered_km DOUBLE, sprint_distance_km DOUBLE, top_speed_kmh DOUBLE,
  accelerations INT, decelerations INT, stamina_score DOUBLE,
  player_rating DOUBLE, performance_score DOUBLE,
  offensive_contribution DOUBLE, defensive_contribution DOUBLE,
  possession_impact DOUBLE, pressure_resistance DOUBLE,
  creativity_score DOUBLE, consistency_score DOUBLE, clutch_performance_score DOUBLE,
  FOREIGN KEY (player_id) REFERENCES players(player_id),
  FOREIGN KEY (match_id) REFERENCES matches(match_id)
);

-- author:Jack Williams
-- create player tournament stats table
CREATE TABLE player_tournament_stats (
  id INT AUTO_INCREMENT PRIMARY KEY,
  player_id VARCHAR(50),
  total_goals_tournament INT,
  total_assists_tournament INT,
  total_minutes_tournament INT,
  player_of_match_awards INT,
  tournament_rating DOUBLE,
  FOREIGN KEY (player_id) REFERENCES players(player_id)
);

-- author:Jack Williams
-- inserting data into players
INSERT INTO players
SELECT DISTINCT player_id, player_name, age, nationality, team, jersey_number,
       position, height_cm, weight_kg, preferred_foot, club_name, market_value_eur
FROM fifa_world_cup_2026_player_performance;

-- =====================================================
-- Queries Jack used to check the match data
-- Author: Jack Williams
-- These were kept so the data issue and design decision are easy to follow.
-- =====================================================
SELECT match_id, COUNT(*) AS cnt
FROM fifa_world_cup_2026_player_performance
GROUP BY match_id
HAVING cnt > 1
LIMIT 20;

SELECT DISTINCT match_id, match_date, stadium, city, opponent_team,
       tournament_stage, match_result, goals_team, goals_opponent
FROM fifa_world_cup_2026_player_performance
WHERE match_id = 'M00001';

SELECT match_id,
       COUNT(DISTINCT CONCAT(match_date, stadium, opponent_team,
                             match_result, goals_team, goals_opponent)) AS distinct_versions
FROM fifa_world_cup_2026_player_performance
GROUP BY match_id
HAVING distinct_versions > 1;

SELECT COUNT(*) AS num_problem_match_ids
FROM (
  SELECT match_id
  FROM fifa_world_cup_2026_player_performance
  GROUP BY match_id
  HAVING COUNT(DISTINCT CONCAT(match_date, stadium, opponent_team,
                               match_result, goals_team, goals_opponent)) > 1
) t;

-- Updated by Joshua Cochran:
-- The M00001B change was removed. After checking the data, the different versions
-- turned out to be the same match shown from each team's point of view, not two
-- separate matches that needed different IDs.

-- author:Jack Williams
-- inserting data into matches and player_match_stats tables
-- Updated by Joshua Cochran:
-- Grouping by match_id gives us one row per match using only values that stay
-- the same for the whole match.
INSERT INTO matches (
  match_id, match_date, stadium, city, tournament_stage
)
SELECT
  match_id,
  MIN(match_date),
  MIN(stadium),
  MIN(city),
  MIN(tournament_stage)
FROM fifa_world_cup_2026_player_performance
GROUP BY match_id;

INSERT INTO player_match_stats (
  player_id, match_id, opponent_team, match_result, goals_team, goals_opponent,
  minutes_played, goals, assists, shots, shots_on_target,
  expected_goals_xg, expected_assists_xa,
  key_passes, successful_passes, total_passes, pass_accuracy,
  dribbles_attempted, successful_dribbles,
  crosses, successful_crosses,
  tackles, interceptions, clearances, blocks,
  aerial_duels_won, aerial_duels_lost,
  recoveries, defensive_actions,
  fouls_committed, fouls_suffered,
  yellow_cards, red_cards, offsides,
  saves, save_percentage, punches,
  clean_sheet, goals_conceded, penalty_saves,
  distance_covered_km, sprint_distance_km, top_speed_kmh,
  accelerations, decelerations, stamina_score,
  player_rating, performance_score,
  offensive_contribution, defensive_contribution,
  possession_impact, pressure_resistance,
  creativity_score, consistency_score, clutch_performance_score
)
SELECT
  player_id, match_id, opponent_team, match_result, goals_team, goals_opponent,
  minutes_played, goals, assists, shots, shots_on_target,
  expected_goals_xg, expected_assists_xa,
  key_passes, successful_passes, total_passes, pass_accuracy,
  dribbles_attempted, successful_dribbles,
  crosses, successful_crosses,
  tackles, interceptions, clearances, blocks,
  aerial_duels_won, aerial_duels_lost,
  recoveries, defensive_actions,
  fouls_committed, fouls_suffered,
  yellow_cards, red_cards, offsides,
  saves, save_percentage, punches,
  clean_sheet, goals_conceded, penalty_saves,
  distance_covered_km, sprint_distance_km, top_speed_kmh,
  accelerations, decelerations, stamina_score,
  player_rating, performance_score,
  offensive_contribution, defensive_contribution,
  possession_impact, pressure_resistance,
  creativity_score, consistency_score, clutch_performance_score
FROM fifa_world_cup_2026_player_performance;

-- author:Jack Williams
-- inserting data into player_tournament_stats table
-- Updated by Joshua Cochran:
-- Using GROUP BY here keeps one tournament summary row for each player.
INSERT INTO player_tournament_stats (
  player_id, total_goals_tournament, total_assists_tournament,
  total_minutes_tournament, player_of_match_awards, tournament_rating
)
SELECT
  player_id,
  MAX(total_goals_tournament),
  MAX(total_assists_tournament),
  MAX(total_minutes_tournament),
  MAX(player_of_match_awards),
  MAX(tournament_rating)
FROM fifa_world_cup_2026_player_performance
GROUP BY player_id;

-- author:Jack Williams
-- creating table scouting_notes
-- Updated by Joshua Cochran:
-- Our MySQL version would not accept CURRENT_DATE as the default for a DATE column,
-- so this uses CURRENT_TIMESTAMP instead.
CREATE TABLE scouting_notes (
  note_id INT AUTO_INCREMENT PRIMARY KEY,
  player_id VARCHAR(50) NOT NULL,
  note_text TEXT,
  priority VARCHAR(25),
  created_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (player_id) REFERENCES players(player_id)
);

-- author:Jack Williams
-- creating table teams
CREATE TABLE teams (
  team_id INT AUTO_INCREMENT PRIMARY KEY,
  team_name VARCHAR(100) NOT NULL UNIQUE
);

-- author:Jack Williams
-- creating table stadiums
CREATE TABLE stadiums (
  stadium_id INT AUTO_INCREMENT PRIMARY KEY,
  stadium_name VARCHAR(100) NOT NULL,
  city VARCHAR(100)
);

-- author:Jack Williams
-- adding teams into teams table
INSERT INTO teams (team_name)
SELECT DISTINCT team_name
FROM (
  SELECT team AS team_name
  FROM fifa_world_cup_2026_player_performance
  UNION
  SELECT opponent_team AS team_name
  FROM fifa_world_cup_2026_player_performance
) t
WHERE team_name IS NOT NULL;

-- author:Jack Williams
-- adding stadium name and city into stadiums table
INSERT INTO stadiums (stadium_name, city)
SELECT DISTINCT stadium, city
FROM matches;

-- author:Jack Williams
-- adding stadium_id column into matches table
ALTER TABLE matches ADD COLUMN stadium_id INT;

-- author:Jack Williams
-- syncing stadium_id between matches and stadiums tables
SET SQL_SAFE_UPDATES = 0;
UPDATE matches m
JOIN stadiums s
  ON m.stadium = s.stadium_name
 AND m.city = s.city
SET m.stadium_id = s.stadium_id;
SET SQL_SAFE_UPDATES = 1;

-- author:Jack Williams
-- adding foreign key reference to matches table
ALTER TABLE matches
ADD CONSTRAINT fk_stadium
FOREIGN KEY (stadium_id) REFERENCES stadiums(stadium_id);

-- author:Jack Williams
-- adding team_id in players table
ALTER TABLE players ADD COLUMN team_id INT;

-- author:Jack Williams
-- syncing team_id between teams and players tables
SET SQL_SAFE_UPDATES = 0;
UPDATE players p
JOIN teams t
  ON p.team = t.team_name
SET p.team_id = t.team_id;
SET SQL_SAFE_UPDATES = 1;

-- author:Jack Williams
-- adding foreign key reference to players table
ALTER TABLE players
ADD CONSTRAINT fk_team
FOREIGN KEY (team_id) REFERENCES teams(team_id);

-- =====================================================
-- Final checks
-- Added by Joshua Cochran
-- These queries confirm that each table was created and populated.
-- =====================================================
SHOW TABLES;

SELECT COUNT(*) AS players FROM players;
SELECT COUNT(*) AS matches FROM matches;
SELECT COUNT(*) AS player_match_stats FROM player_match_stats;
SELECT COUNT(*) AS player_tournament_stats FROM player_tournament_stats;
SELECT COUNT(*) AS teams FROM teams;
SELECT COUNT(*) AS stadiums FROM stadiums;
