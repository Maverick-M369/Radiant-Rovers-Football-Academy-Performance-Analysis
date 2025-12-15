Select *
From public."FA_P&E_TAB"


1. Total Matches & Unique Players.
SELECT
  COUNT(DISTINCT match_id) AS total_matches,
  COUNT(DISTINCT player_id) AS total_unique_players
FROM "FA_P&E_TAB";


2. Total goals, assists, shots in a date range.
SELECT
  SUM(goals) AS total_goals,
  SUM(assists) AS total_assists,
  SUM(shots_on_target) AS total_shots_on_target
FROM "FA_P&E_TAB"
WHERE match_date BETWEEN '2025-01-01' AND '2025-12-31'

3. Average Attendance per Match & Monthly Trend
-- avg Attendance per Match
SELECT
  AVG(attendance)::numeric(10,2) AS avg_attendance_per_match
FROM (
  SELECT match_id, AVG(attendance) AS attendance
  FROM "FA_P&E_TAB"
  GROUP BY match_id
);

-- Monthly Attendance Trend (Month-Year)
CREATE OR REPLACE VIEW v_attendance_monthly AS
SELECT
  to_char(match_date, 'YYYY-MM') AS year_month,
  COUNT(DISTINCT match_id) AS matches,
  AVG(attendance)::numeric(10,2) AS avg_attendance
FROM "FA_P&E_TAB"
GROUP BY year_month
ORDER BY year_month;


4. Active players per month
CREATE OR REPLACE VIEW v_active_players_monthly AS
SELECT
  to_char(match_date, 'YYYY-MM') AS year_month,
  COUNT(DISTINCT player_id) AS active_players
FROM "FA_P&E_TAB"
WHERE minutes_played > 0
GROUP BY year_month
ORDER BY year_month;


5. Top Scorers
CREATE OR REPLACE VIEW v_top_scorers AS
SELECT player_id, player_name,
       SUM(goals) AS total_goals,
       SUM(minutes_played) AS total_minutes,
       ROUND( (SUM(goals) / NULLIF(SUM(minutes_played),0)) * 90.0, 2) AS goals_per_90
FROM "FA_P&E_TAB"
GROUP BY player_id, player_name
ORDER BY total_goals DESC, goals_per_90 DESC
Limit 15;


6. Team Average Goals per 90 min
-- Player-level goals per 90 min already in v_top_scorers.
-- Team-level (academy average of players' Goals/90 min)
WITH player_stats AS (
    SELECT 
        player_id,
        (SUM(goals)::numeric / NULLIF(SUM(minutes_played),0)) * 90.0 AS g90
    FROM "FA_P&E_TAB"
    GROUP BY player_id
)
SELECT 
    ROUND(AVG(g90)::numeric, 2) AS avg_goals_per_90
FROM player_stats;

7. Average fitness/stamina/speed by month / position / age_group
CREATE OR REPLACE VIEW v_avg_physical_by_month AS
SELECT
  to_char(match_date, 'YYYY-MM') AS year_month,
  ROUND(AVG(fitness_score)::numeric,2) AS avg_fitness,
  ROUND(AVG(stamina)::numeric,2) AS avg_stamina,
  ROUND(AVG(speed)::numeric,2) AS avg_speed
FROM "FA_P&E_TAB"
GROUP BY year_month
ORDER BY year_month;

---- Average of Players fitness/stamina/speed by position 
CREATE OR REPLACE VIEW v_avg_physical_by_position AS
SELECT
  position,
  ROUND(AVG(fitness_score)::numeric,2) AS avg_fitness,
  ROUND(AVG(stamina)::numeric,2) AS avg_stamina,
  ROUND(AVG(speed)::numeric,2) AS avg_speed,
  COUNT(DISTINCT player_id) AS players
FROM "FA_P&E_TAB"
GROUP BY position
ORDER BY players DESC;


8. Minutes played distribution & utilization
-- total & avg minutes per player
CREATE OR REPLACE VIEW v_minutes_per_player AS
SELECT
  player_id, player_name,
  SUM(minutes_played) AS total_minutes,
  AVG(minutes_played)::numeric(10,2) AS avg_minutes_per_match,
  COUNT(DISTINCT match_id) AS matches_played
FROM "FA_P&E_TAB"
GROUP BY player_id, player_name
ORDER BY total_minutes DESC;


9. Discipline rate (cards per 90)
CREATE OR REPLACE VIEW v_cards_per_90 AS
SELECT
  player_id, player_name,
  SUM(yellow_card)::int AS total_yellow,
  SUM(red_card)::int AS total_red,
  SUM(minutes_played) AS total_minutes,
  ROUND( (SUM(yellow_card)::numeric / NULLIF(SUM(minutes_played),0)) * 90.0, 3) AS yellow_per_90,
  ROUND( (SUM(red_card)::numeric / NULLIF(SUM(minutes_played),0)) * 90.0, 3) AS red_per_90
FROM "FA_P&E_TAB"
GROUP BY player_id, player_name
ORDER BY yellow_per_90 DESC NULLS LAST;


10. Passing accuracy & conversion rate
-- Passing accuracy average (team)
SELECT ROUND(AVG(passing_accuracy)::numeric,2) AS avg_passing_accuracy
FROM "FA_P&E_TAB";

-- Conversion rate (goals divided by shots_on_target)
CREATE OR REPLACE VIEW v_conversion_rate AS
SELECT 
    player_id,
    player_name,
    SUM(goals)::int AS total_goals,
    SUM(shots_on_target)::int AS total_shots_on_target,
    COALESCE(
        ROUND( (SUM(goals)::numeric / NULLIF(SUM(shots_on_target),0)) * 100.0, 2),
        0
    ) AS conversion_pct
FROM "FA_P&E_TAB"
GROUP BY player_id, player_name
ORDER BY conversion_pct DESC NULLS LAST;


11. Goals Per 90 min
SELECT
    player_id,
    player_name,
    ROUND(
        (SUM(goals)::NUMERIC / NULLIF(SUM(minutes_played), 0)) * 90,
        2
    ) AS goals_per_90
FROM public."FA_P&E_TAB"
GROUP BY player_id, player_name
HAVING SUM(minutes_played) >= 90
ORDER BY goals_per_90 DESC;


12. Average goals per match (player-sum for 20 Matches)
SELECT
    ROUND(AVG(match_goals), 2) AS avg_goals_per_match
FROM (
    SELECT
        match_id,
        SUM(goals) AS match_goals
    FROM public."FA_P&E_TAB"
    GROUP BY match_id
) AS match_goal_totals;


13. Identification of top goal scorers
SELECT
    player_id,
    player_name,
    SUM(goals) AS total_goals
FROM public."FA_P&E_TAB"
GROUP BY player_id, player_name
ORDER BY total_goals DESC
LIMIT 10;

14. Goals-per-90 efficiency rankings
SELECT
    player_id,
    player_name,
    ROUND(
        (SUM(goals)::NUMERIC / NULLIF(SUM(minutes_played), 0)) * 90,
        2
    ) AS goals_per_90
FROM public."FA_P&E_TAB"
GROUP BY player_id, player_name
HAVING SUM(minutes_played) >= 90
ORDER BY goals_per_90 DESC;


15. Average Passing Accuracy by Playing Position
SELECT
    position,
    ROUND(AVG(passing_accuracy)::NUMERIC, 2) AS avg_passing_accuracy
FROM public."FA_P&E_TAB"
WHERE passing_accuracy IS NOT NULL
GROUP BY position
ORDER BY avg_passing_accuracy DESC;


16. Fitness Score Trend by Age
SELECT
    age,
    ROUND(AVG(fitness_score)::NUMERIC, 2) AS avg_fitness_score
FROM public."FA_P&E_TAB"
WHERE fitness_score IS NOT NULL
GROUP BY age
ORDER BY age;

---- Or Fitness Score Trend by age and position
SELECT
    age,
    position,
    ROUND(AVG(fitness_score)::NUMERIC, 2) AS avg_fitness_score
FROM public."FA_P&E_TAB"
WHERE fitness_score IS NOT NULL
GROUP BY age, position
ORDER BY age, position
limit 48;

17. Attendance-Based Consistency Indicators
SELECT
    player_id,
    player_name,
    ROUND(AVG(attendance), 2) AS avg_attendance
FROM public."FA_P&E_TAB"
GROUP BY player_id, player_name
ORDER BY avg_attendance DESC;


18. Top 10 most consistent players (attendance)
SELECT
    player_id,
    player_name,
    ROUND(AVG(attendance), 2) AS avg_attendance
FROM public."FA_P&E_TAB"
GROUP BY player_id, player_name
ORDER BY avg_attendance DESC
LIMIT 10;


19. Attendance vs performance (advanced insight)
SELECT
    player_id,
    player_name,
    ROUND(AVG(attendance), 2) AS avg_attendance,
    ROUND(AVG(fitness_score)::NUMERIC, 2) AS avg_fitness_score,
    SUM(goals) AS total_goals
FROM public."FA_P&E_TAB"
GROUP BY player_id, player_name
ORDER BY avg_attendance DESC;


20. Player aggregate VIEW
CREATE VIEW vw_player_performance_summary AS
SELECT
    player_id,
    player_name,
    position,
    age,
    SUM(goals) AS total_goals,
    SUM(minutes_played) AS total_minutes,
    ROUND(
        (SUM(goals)::NUMERIC / NULLIF(SUM(minutes_played), 0)) * 90,
        2
    ) AS goals_per_90,
    ROUND(AVG(passing_accuracy)::Numeric, 2) AS avg_passing_accuracy,
    ROUND(AVG(fitness_score)::Numeric, 2) AS avg_fitness_score,
    ROUND(AVG(attendance), 2) AS avg_attendance
FROM public."FA_P&E_TAB"
GROUP BY player_id, player_name, position, age;


