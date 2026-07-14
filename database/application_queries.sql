-- =========================================================
-- WORLD CUP PLAYER ANALYTICS
-- APPLICATION QUERIES
-- Author: Joshua Cochran
--
-- These queries support the Flask dashboard, player search,
-- player detail pages, visualizations, and scouting notes.
-- =========================================================


-- =========================================================
-- 1. DASHBOARD SUMMARY COUNTS
-- Author: Joshua Cochran
-- Returns the total number of players, teams, and matches.
-- =========================================================

SELECT
    (SELECT COUNT(*) FROM players) AS total_players,
    (SELECT COUNT(*) FROM teams) AS total_teams,
    (SELECT COUNT(*) FROM matches) AS total_matches;


-- =========================================================
-- 2. TOP 10 TEAMS BY TOTAL GOALS
-- Author: Joshua Cochran
-- Used for the dashboard team-goals bar chart.
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
-- Used for the dashboard position-rating chart.
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
-- 4. MARKET VALUE VS. TOURNAMENT RATING
-- Author: Joshua Cochran
-- Used for the interactive dashboard scatter plot.
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
-- Returns one row per player for the player search page.
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
-- Replace 'Rodri' with a value supplied by the Flask form.
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
-- Replace 'Forward' with a value supplied by the Flask form.
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
-- Replace P00055 with the selected player ID.
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
-- Calculates summary cards for the player detail page.
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
-- Used for the table and performance chart on player pages.
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
-- Identifies the highest-scoring players in the dataset.
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
-- Provides team-level statistics for a future team page.
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
-- Returns the number of matches associated with each stadium.
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
-- Displays existing notes with player information.
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
-- Demonstrates the Create portion of CRUD.
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
-- Demonstrates the Update portion of CRUD.
-- Replace note_id 1 with an existing note ID.
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
-- Demonstrates the Delete portion of CRUD.
-- Replace note_id 1 with the note that should be deleted.
-- =========================================================

DELETE FROM scouting_notes
WHERE note_id = 1;