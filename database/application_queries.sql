-- =========================================================
-- WORLD CUP PLAYER ANALYTICS
-- Application Queries
-- Author: Joshua Cochran
--
-- These are the main SQL queries used by my Flask application
-- for the dashboard, player pages, charts, and scouting notes.
-- =========================================================


-- =========================================================
-- 1. DASHBOARD SUMMARY COUNTS
-- Author: Joshua Cochran
-- Gets the totals shown on the dashboard.
-- =========================================================

SELECT
    (SELECT COUNT(*) FROM players) AS total_players,
    (SELECT COUNT(*) FROM teams) AS total_teams,
    (SELECT COUNT(*) FROM matches) AS total_matches;


-- =========================================================
-- 2. TOP 10 TEAMS BY TOTAL GOALS
-- Author: Joshua Cochran
-- Shows the top scoring teams on the dashboard.
-- =========================================================

SELECT
    t.team_name,
    SUM(pms.goals) AS total_goals
FROM player_match_stats AS pms
JOIN players AS p
    ON pms.player_id = p.player_id
JOIN teams AS t
    ON p.team_id = t.team_id
GROUP BY
    t.team_id,
    t.team_name
ORDER BY
    total_goals DESC
LIMIT 10;


-- =========================================================
-- 3. AVERAGE PLAYER RATING BY POSITION
-- Author: Joshua Cochran
-- Calculates the average rating for each position.
-- =========================================================

SELECT
    p.position,
    ROUND(AVG(pms.player_rating), 2) AS average_player_rating
FROM player_match_stats AS pms
JOIN players AS p
    ON pms.player_id = p.player_id
GROUP BY
    p.position
ORDER BY
    average_player_rating DESC;


-- =========================================================
-- 4. MARKET VALUE VS TOURNAMENT RATING
-- Author: Joshua Cochran
-- Used to compare player value with tournament rating.
-- =========================================================

SELECT
    p.player_id,
    p.player_name,
    t.team_name,
    p.position,
    p.market_value_eur,
    pts.tournament_rating
FROM players AS p
JOIN teams AS t
    ON p.team_id = t.team_id
JOIN player_tournament_stats AS pts
    ON p.player_id = pts.player_id
WHERE
    pts.tournament_rating > 0
ORDER BY
    p.market_value_eur DESC;


-- =========================================================
-- 5. DISPLAY ALL PLAYERS
-- Author: Joshua Cochran
-- Displays the player list on the search page.
-- =========================================================

SELECT
    p.player_id,
    p.player_name,
    t.team_name,
    p.position,
    p.age,
    pts.tournament_rating
FROM players AS p
JOIN teams AS t
    ON p.team_id = t.team_id
LEFT JOIN player_tournament_stats AS pts
    ON p.player_id = pts.player_id
ORDER BY
    pts.tournament_rating DESC,
    p.player_name
LIMIT 50;


-- =========================================================
-- 6. SEARCH PLAYERS BY NAME
-- Author: Joshua Cochran
-- Example search. Flask replaces "Rodri" with whatever the
-- user types into the search box.
-- =========================================================

SELECT
    p.player_id,
    p.player_name,
    t.team_name,
    p.position,
    p.age,
    pts.tournament_rating
FROM players AS p
JOIN teams AS t
    ON p.team_id = t.team_id
LEFT JOIN player_tournament_stats AS pts
    ON p.player_id = pts.player_id
WHERE
    p.player_name LIKE '%Rodri%'
ORDER BY
    pts.tournament_rating DESC,
    p.player_name;


-- =========================================================
-- 7. FILTER PLAYERS BY POSITION
-- Author: Joshua Cochran
-- Filters the player list by position.
-- =========================================================

SELECT
    p.player_id,
    p.player_name,
    t.team_name,
    p.position,
    p.age,
    pts.tournament_rating
FROM players AS p
JOIN teams AS t
    ON p.team_id = t.team_id
LEFT JOIN player_tournament_stats AS pts
    ON p.player_id = pts.player_id
WHERE
    p.position = 'Forward'
ORDER BY
    pts.tournament_rating DESC,
    p.player_name;


-- =========================================================
-- 8. PLAYER PROFILE INFORMATION
-- Author: Joshua Cochran
-- Loads all the information for one player.
-- =========================================================

SELECT
    p.player_id,
    p.player_name,
    p.age,
    p.nationality,
    t.team_name,
    p.jersey_number,
    p.position,
    p.height_cm,
    p.weight_kg,
    p.preferred_foot,
    p.club_name,
    p.market_value_eur,
    pts.total_goals_tournament,
    pts.total_assists_tournament,
    pts.total_minutes_tournament,
    pts.player_of_match_awards,
    pts.tournament_rating
FROM players AS p
JOIN teams AS t
    ON p.team_id = t.team_id
LEFT JOIN player_tournament_stats AS pts
    ON p.player_id = pts.player_id
WHERE
    p.player_id = 'P00055';


-- =========================================================
-- 9. PLAYER PERFORMANCE SUMMARY
-- Author: Joshua Cochran
-- Creates the summary stats shown at the top of a player's page.
-- =========================================================

SELECT
    p.player_id,
    p.player_name,
    COUNT(DISTINCT pms.match_id) AS total_matches,
    SUM(pms.goals) AS total_goals,
    SUM(pms.assists) AS total_assists,
    SUM(pms.minutes_played) AS total_minutes,
    ROUND(AVG(pms.player_rating), 2) AS average_rating
FROM players AS p
JOIN player_match_stats AS pms
    ON p.player_id = pms.player_id
WHERE
    p.player_id = 'P00055'
GROUP BY
    p.player_id,
    p.player_name;


-- =========================================================
-- 10. PLAYER MATCH HISTORY
-- Author: Joshua Cochran
-- Pulls every match the selected player appeared in.
-- =========================================================

SELECT
    pms.match_id,
    m.match_date,
    m.opponent_team,
    m.tournament_stage,
    pms.minutes_played,
    pms.goals,
    pms.assists,
    pms.player_rating
FROM player_match_stats AS pms
JOIN matches AS m
    ON pms.match_id = m.match_id
WHERE
    pms.player_id = 'P00055'
ORDER BY
    m.match_date,
    pms.match_id;


-- =========================================================
-- 11. TOP 10 GOAL SCORERS
-- Author: Joshua Cochran
-- Finds the players with the most goals.
-- =========================================================

SELECT
    p.player_id,
    p.player_name,
    t.team_name,
    SUM(pms.goals) AS total_goals
FROM player_match_stats AS pms
JOIN players AS p
    ON pms.player_id = p.player_id
JOIN teams AS t
    ON p.team_id = t.team_id
GROUP BY
    p.player_id,
    p.player_name,
    t.team_name
ORDER BY
    total_goals DESC
LIMIT 10;


-- =========================================================
-- 12. TEAM PERFORMANCE SUMMARY
-- Author: Joshua Cochran
-- Team summary statistics.
-- =========================================================

SELECT
    t.team_name,
    COUNT(DISTINCT p.player_id) AS total_players,
    SUM(pms.goals) AS total_goals,
    SUM(pms.assists) AS total_assists,
    ROUND(AVG(pms.player_rating), 2) AS average_rating
FROM teams AS t
JOIN players AS p
    ON t.team_id = p.team_id
JOIN player_match_stats AS pms
    ON p.player_id = pms.player_id
GROUP BY
    t.team_id,
    t.team_name
ORDER BY
    average_rating DESC;


-- =========================================================
-- 13. STADIUM MATCH COUNTS
-- Author: Joshua Cochran
-- Counts how many matches were played at each stadium.
-- =========================================================

SELECT
    s.stadium_name,
    s.city,
    COUNT(DISTINCT m.match_id) AS total_matches
FROM stadiums AS s
JOIN matches AS m
    ON s.stadium_id = m.stadium_id
GROUP BY
    s.stadium_id,
    s.stadium_name,
    s.city
ORDER BY
    total_matches DESC;


-- =========================================================
-- 14. READ ALL SCOUTING NOTES
-- Author: Joshua Cochran
-- Shows every scouting note that has been created.
-- =========================================================

SELECT
    sn.note_id,
    sn.player_id,
    p.player_name,
    t.team_name,
    p.position,
    sn.priority,
    sn.note_text,
    sn.created_date
FROM scouting_notes AS sn
JOIN players AS p
    ON sn.player_id = p.player_id
JOIN teams AS t
    ON p.team_id = t.team_id
ORDER BY
    sn.created_date DESC,
    sn.note_id DESC;


-- =========================================================
-- 15. CREATE A SCOUTING NOTE
-- Author: Joshua Cochran
-- Adds a new scouting note.
-- =========================================================

INSERT INTO scouting_notes (
    player_id,
    note_text,
    priority
)
VALUES (
    'P00055',
    'Strong performance and consistent positioning.',
    'High'
);


-- =========================================================
-- 16. UPDATE A SCOUTING NOTE
-- Author: Joshua Cochran
-- Updates an existing scouting note.
-- =========================================================

UPDATE scouting_notes
SET
    note_text = 'Updated scouting observation after reviewing match history.',
    priority = 'Medium'
WHERE
    note_id = 1;


-- =========================================================
-- 17. DELETE A SCOUTING NOTE
-- Author: Joshua Cochran
-- Deletes a scouting note.
-- =========================================================

DELETE FROM scouting_notes
WHERE note_id = 1;