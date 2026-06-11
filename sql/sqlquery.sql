WITH season_runs AS (
    SELECT
        season,
        batter,
        SUM(batsman_runs)  AS total_runs,
        COUNT(*)           AS balls_faced,
        ROUND(
            CAST(SUM(batsman_runs) AS FLOAT) / NULLIF(COUNT(*), 0) * 100, 2
        )                  AS strike_rate,
        RANK() OVER (
            PARTITION BY season
            ORDER BY SUM(batsman_runs) DESC
        ) AS rnk
    FROM deliveries
    GROUP BY season, batter
)
SELECT
    season,
    batter        AS top_batsman,
    total_runs,
    balls_faced,
    strike_rate
FROM season_runs
WHERE rnk = 1
ORDER BY season;





WITH season_totals AS (
    SELECT
        season,
        SUM(total_runs)  AS total_runs
    FROM deliveries
    GROUP BY season
)
SELECT
    season,
    total_runs,
    LAG(total_runs) OVER (ORDER BY season)  AS prev_season_runs,
    ROUND(
        (CAST(total_runs AS FLOAT)
         - LAG(total_runs) OVER (ORDER BY season))
        * 100.0
        / NULLIF(LAG(total_runs) OVER (ORDER BY season), 0),
        2
    ) AS yoy_growth_pct
FROM season_totals
ORDER BY season;










WITH death_stats AS (
    SELECT
        bowler,
        SUM(total_runs)                               AS runs_conceded,
        SUM(CASE WHEN extras_type NOT IN ('wides','noballs')
                 OR extras_type IS NULL THEN 1 ELSE 0 END) AS legal_balls,
        SUM(CASE WHEN player_dismissed <> 'not_out'
                 THEN 1 ELSE 0 END)                   AS wickets
    FROM deliveries
    WHERE phase = 'Death'
    GROUP BY bowler
    HAVING SUM(CASE WHEN extras_type NOT IN ('wides','noballs')
                    OR extras_type IS NULL THEN 1 ELSE 0 END) >= 120
)
SELECT
    bowler,
    runs_conceded,
    ROUND(CAST(legal_balls AS FLOAT) / 6, 1)         AS overs_bowled,
    wickets,
    ROUND(
        CAST(runs_conceded AS FLOAT)
        / NULLIF(CAST(legal_balls AS FLOAT) / 6, 0),
        2
    ) AS economy_rate
FROM death_stats
WHERE ROUND(
        CAST(runs_conceded AS FLOAT)
        / NULLIF(CAST(legal_balls AS FLOAT) / 6, 0),
        2
      ) < 8.5
ORDER BY economy_rate;









SELECT
    toss_decision,
    COUNT(*)                                           AS total_matches,
    SUM(CASE WHEN toss_winner = winner THEN 1 ELSE 0 END) AS toss_wins,
    ROUND(
        CAST(SUM(CASE WHEN toss_winner = winner THEN 1 ELSE 0 END) AS FLOAT)
        / COUNT(*) * 100, 2
    ) AS win_pct
FROM matches
GROUP BY toss_decision
ORDER BY win_pct DESC;









WITH team_season_runs AS (
    SELECT
        batting_team,
        season,
        SUM(batsman_runs) AS season_runs
    FROM deliveries
    GROUP BY batting_team, season
)
SELECT
    batting_team,
    season,
    season_runs,
    SUM(season_runs) OVER (
        PARTITION BY batting_team
        ORDER BY season
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_runs
FROM team_season_runs
ORDER BY batting_team, season;











SELECT
    phase,
    SUM(total_runs)                             AS total_runs,
    SUM(CASE WHEN player_dismissed <> 'not_out'
             THEN 1 ELSE 0 END)                 AS total_wickets,
    COUNT(*)                                    AS total_balls,
    ROUND(
        CAST(SUM(total_runs) AS FLOAT)
        / NULLIF(COUNT(*), 0) * 6, 2
    )                                           AS run_rate,
    ROUND(
        CAST(SUM(CASE WHEN player_dismissed <> 'not_out'
                      THEN 1 ELSE 0 END) AS FLOAT)
        / NULLIF(COUNT(*), 0) * 6, 4
    )                                           AS wickets_per_over,
    ROUND(
        CAST(SUM(total_runs) AS FLOAT)
        / NULLIF(SUM(CASE WHEN player_dismissed <> 'not_out'
                          THEN 1 ELSE 0 END), 0),
        2
    )                                           AS runs_per_wicket
FROM deliveries
GROUP BY phase
ORDER BY
    CASE phase
        WHEN 'Powerplay' THEN 1
        WHEN 'Middle'    THEN 2
        WHEN 'Death'     THEN 3
    END;
