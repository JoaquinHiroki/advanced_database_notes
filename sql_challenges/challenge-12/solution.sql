-- PART A: KPI CONTRACTS — ALL EXERCISES
-- Exercise 1 Team Velocity

-- 1. How fast does each team deliver completed work over time?
-- 2. Velocity = completed tasks per team member per week, join teams users (team_id) tasks (assigned_to), tasks.status = completed only
-- 3. Team with 0 completed tasks, velocity = 0, not NULL, team with 1 member vs 5 members, unfair if unnormalized we expose both
-- 4. Completed tasks per member per week
-- 5. Counting all tasks, not just completed, rewards task creation, not delivery

WITH team_stats AS (
    SELECT
        t.id                                         AS team_id,
        t.name                                       AS team_name,
        COUNT(DISTINCT u.id)                         AS member_count,
        COUNT(ts.id)                                 AS completed_tasks,
        GREATEST(
            ROUND((SYSDATE - MIN(ts.created_at)) / 7, 2),
            1   -- floor at 1 week so we never divide by zero
        )                                            AS weeks_active
    FROM   teams t
    LEFT   JOIN users  u  ON u.team_id    = t.id
    LEFT   JOIN tasks  ts ON ts.assigned_to = u.id
                          AND ts.status    = 'completed'
    GROUP  BY t.id, t.name
),
overall AS (
    SELECT
        SUM(completed_tasks)                         AS total_completed,
        SUM(member_count)                            AS total_members,
        SUM(weeks_active)                            AS total_weeks,
        ROUND(
            SUM(completed_tasks)
            / NULLIF(SUM(member_count), 0)
            / AVG(weeks_active),
        2)                                           AS overall_velocity
    FROM   team_stats
)
SELECT
    s.team_name,
    s.member_count,
    s.completed_tasks,
    ROUND(s.completed_tasks / s.weeks_active, 1)                       AS tasks_per_week_raw,
    ROUND(s.completed_tasks / NULLIF(s.member_count,0) / s.weeks_active, 2) AS tasks_per_member_per_week,
    o.overall_velocity,
    CASE
        WHEN ROUND(s.completed_tasks / NULLIF(s.member_count,0) / s.weeks_active, 2)
             < o.overall_velocity
        THEN 'BELOW AVERAGE'
        ELSE 'AT OR ABOVE AVERAGE'
    END                                                                 AS velocity_flag
FROM   team_stats s
CROSS  JOIN overall o
ORDER  BY tasks_per_member_per_week DESC;


-- Exercise 2 OnTime Delivery Rate
-- 1. What percentage of committed tasks do we actually deliver on or before their deadline?
-- 2. OnTime rate = tasks completed on or before due_date / all completed tasks
-- 3. Task completed at 23:59 on due_date ON TIME, task completed at 00:01 next day
-- 4. Percentage 0–100, 1 decimal place + average lateness in hours
-- 5. Including cancelled tasks in the denominator deflates the rate unfairly including tasks with no due_date hides that many tasks have no commitment

SELECT
    priority,
    COUNT(*)                                                    AS delivered_tasks,
    SUM(CASE
            WHEN completed_at <= CAST(due_date AS TIMESTAMP) + INTERVAL '1' DAY
            THEN 1 ELSE 0
        END)                                                    AS on_time_count,
    ROUND(
        SUM(CASE
                WHEN completed_at <= CAST(due_date AS TIMESTAMP) + INTERVAL '1' DAY
                THEN 1 ELSE 0
            END) * 100.0
        / NULLIF(COUNT(*), 0),
    1)                                                          AS on_time_pct,
    -- Average lateness in hours for tasks that WERE late
    ROUND(AVG(
        CASE
            WHEN completed_at > CAST(due_date AS TIMESTAMP) + INTERVAL '1' DAY
            THEN (
                EXTRACT(DAY  FROM (completed_at - CAST(due_date AS TIMESTAMP))) * 24
              + EXTRACT(HOUR FROM (completed_at - CAST(due_date AS TIMESTAMP)))
              + EXTRACT(MINUTE FROM (completed_at - CAST(due_date AS TIMESTAMP))) / 60
            )
        END
    ), 1)                                                       AS avg_lateness_hours
FROM   tasks
WHERE  status    = 'completed'
  AND  completed_at IS NOT NULL
  AND  due_date  IS NOT NULL
GROUP  BY priority
ORDER  BY CASE priority
              WHEN 'critical' THEN 1
              WHEN 'high'     THEN 2
              WHEN 'medium'   THEN 3
              WHEN 'low'      THEN 4
          END;


-- Exercise 3 Tasks per Team 
-- 1. What is the current workload distribution across teams, and which teams are overloaded vs. underutilized right now?
-- 2. Three columns per team:
-- total_tasks COUNT of all tasks ever assigned to users in that team
-- active_tasks tasks with status IN ('open','in_progress','blocked')
-- completion_rate completed / (total - cancelled) × 100
-- join teams users (team_id) to tasks (assigned_to) via LEFT JOIN chain
-- Health score Overloaded if active > 10, Healthy if 5–10 Underutilized if < 5
-- 3. Teams with no tasks appear with zeros 
-- 4. Count integer for tasks; percentage for completion_rate
-- 5. Original query counted completed+cancelled as workload a team that finished everything looks as busy as one that is currently overwhelmed

SELECT
    t.name                                          AS team_name,
    COUNT(ts.id)                                    AS total_tasks,
    SUM(CASE WHEN ts.status IN ('open','in_progress','blocked') THEN 1 ELSE 0 END)
                                                    AS active_tasks,
    ROUND(
        SUM(CASE WHEN ts.status = 'completed' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(
            SUM(CASE WHEN ts.status != 'cancelled' THEN 1 ELSE 0 END),
          0),
    1)                                              AS completion_rate_pct,
    CASE
        WHEN SUM(CASE WHEN ts.status IN ('open','in_progress','blocked') THEN 1 ELSE 0 END) > 10
        THEN 'Overloaded'
        WHEN SUM(CASE WHEN ts.status IN ('open','in_progress','blocked') THEN 1 ELSE 0 END) >= 5
        THEN 'Healthy'
        ELSE 'Underutilized'
    END                                             AS health_score
FROM   teams t
LEFT   JOIN users u  ON u.team_id    = t.id
LEFT   JOIN tasks ts ON ts.assigned_to = u.id
GROUP  BY t.id, t.name
ORDER  BY active_tasks DESC;

-- Exercise 4 Average Resolution Time by Priority

-- 1. Are we resolving critical issues faster than low priority ones, and are we meeting our SLA targets for each priority level?
-- 2. Resolution time = hours from created_at to completed_at grouped by priority. SLA targets: critical 24h, high= 2h, medium 168h,low 336h
-- 3. Priority with only 1 completed task → average is that single value, flagged as LOW SAMPLE so readers don't overtrust it
-- 4. Hours for all time columns, categorical for SLA status
-- 5. Averaging critical and low tasks together masks that your critical SLA is being blown while low tasks are fine

SELECT
    priority,
    COUNT(*)                                        AS sample_count,
    CASE WHEN COUNT(*) < 3 THEN 'LOW SAMPLE' ELSE 'OK' END
                                                    AS sample_warning,
    ROUND(AVG(
        EXTRACT(DAY    FROM (completed_at - created_at)) * 24
      + EXTRACT(HOUR   FROM (completed_at - created_at))
      + EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1)                                           AS avg_resolution_hours,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY
        EXTRACT(DAY    FROM (completed_at - created_at)) * 24
      + EXTRACT(HOUR   FROM (completed_at - created_at))
      + EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1)                                           AS median_resolution_hours,
    ROUND(MIN(
        EXTRACT(DAY    FROM (completed_at - created_at)) * 24
      + EXTRACT(HOUR   FROM (completed_at - created_at))
      + EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1)                                           AS fastest_hours,
    ROUND(MAX(
        EXTRACT(DAY    FROM (completed_at - created_at)) * 24
      + EXTRACT(HOUR   FROM (completed_at - created_at))
      + EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1)                                           AS slowest_hours,
    CASE priority
        WHEN 'critical' THEN 24
        WHEN 'high'     THEN 72
        WHEN 'medium'   THEN 168
        WHEN 'low'      THEN 336
    END                                             AS sla_target_hours,
    CASE
        WHEN AVG(
            EXTRACT(DAY    FROM (completed_at - created_at)) * 24
          + EXTRACT(HOUR   FROM (completed_at - created_at))
          + EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
        ) <=
        CASE priority
            WHEN 'critical' THEN 24
            WHEN 'high'     THEN 72
            WHEN 'medium'   THEN 168
            WHEN 'low'      THEN 336
        END
        THEN 'MET'
        ELSE 'MISSED'
    END                                             AS sla_status
FROM   tasks
WHERE  status       = 'completed'
  AND  completed_at IS NOT NULL
GROUP  BY priority
ORDER  BY CASE priority
              WHEN 'critical' THEN 1
              WHEN 'high'     THEN 2
              WHEN 'medium'   THEN 3
              WHEN 'low'      THEN 4
          END;

-- Exercise 5 Overdue Tasks
-- 1. Which tasks are past their deadline, how late are they, who owns them and how severe is the business impact by priority?
-- 2. Severity tiers:
--CRITICAL priority='critical' AND days_overdue > 0
--HIGH: priority= 'high' AND days_overdue > 2
--MEDIUM: priority= 'medium' AND days_overdue > 5
--LOW: everything else overdue
-- 3.: NULL due_date excluded 
-- 4. days_overdue (integer); severity (categorical label); avg days (decimal)
-- 5. A single COUNT hides that one critical task 1 day late is a 5 alarm fire while ten low priority tasks 2 days late may be acceptable



-- ------------------------------------------------------------
-- EXERCISE 6: Productivity Score (Bad KPI Fix)
-- ------------------------------------------------------------
-- 1. BUSINESS QUESTION:
--    Which individual contributors are delivering the most high-value work
--    relative to the time they have been active?
--
-- 2. EXACT DEFINITION:
--    Score = SUM(priority_weight) for completed tasks / active_days
--    Priority weights: critical=4, high=3, medium=2, low=1
--    active_days = TRUNC(SYSDATE) - TRUNC(MIN(created_at)), floored at 1
--    Filter: status = 'completed' AND completed_at IS NOT NULL
--    Left join so users with 0 completions still appear (score = 0)
--
-- 3. EDGE CASES:
--    - User with no completed tasks → weighted_score = 0, not NULL (LEFT JOIN + NVL)
--    - User assigned tasks but all cancelled → score = 0 (excluded by filter)
--    - New user (joined today) → active_days floored at 1
--    - NULL priority → falls into ELSE 1 weight (defensive default)
--
-- 4. UNIT: Weighted points per active day (decimal, 2 places)
--
-- 5. WHAT WOULD MAKE IT MISLEADING:
--    - Original counted ALL tasks regardless of status — rewarded task hoarding
--    - Priority weights are subjective; changing them changes rankings
--    - Does not account for task complexity beyond priority label
--    - A user who only does critical tasks for one week scores extremely high
--      vs. a reliable generalist over months — depends on business values

-- ------------------------------------------------------------
-- EXERCISE 7: Team Efficiency (Bad KPI Fix)
-- ------------------------------------------------------------
-- 1. BUSINESS QUESTION:
--    What fraction of the work each team starts do they actually finish?
--
-- 2. EXACT DEFINITION:
--    Efficiency = completed_tasks / non_cancelled_tasks × 100
--    non_cancelled = COUNT where status != 'cancelled'
--    Join: teams → users (team_id) → tasks (assigned_to) via LEFT JOIN
--
-- 3. EDGE CASES:
--    - Team with all cancelled tasks → denominator = 0; NULLIF prevents divide-by-zero
--    - Team with no tasks → efficiency = NULL (displayed as such; no false 0%)
--    - Unassigned tasks → not attributed to any team
--
-- 4. UNIT: Percentage (0–100, 1 decimal place)
--
-- 5. WHAT WOULD MAKE IT MISLEADING:
--    - Original used AVG(task_id) — a primary key has no business meaning;
--      higher IDs just mean newer tasks, not better performance
--    - Not excluding cancelled tasks from the denominator punishes teams that
--      correctly cancel irrelevant work

-- ------------------------------------------------------------
-- EXERCISE 8: Urgency Index (Bad KPI Fix)
-- ------------------------------------------------------------
-- 1. BUSINESS QUESTION:
--    Which open tasks should be worked on first, combining deadline proximity
--    with business priority?
--
-- 2. EXACT DEFINITION:
--    urgency_index = (priority_weight × 10) - days_until_due
--    priority_weight: critical=4, high=3, medium=2, low=1
--    days_until_due = TRUNC(due_date) - TRUNC(SYSDATE)
--      → negative value means already overdue (increases urgency correctly)
--    Filter: status NOT IN ('completed','cancelled') AND due_date IS NOT NULL
--    Higher score = act sooner
--
-- 3. EDGE CASES:
--    - NULL due_date → excluded (no deadline = no urgency calculation)
--    - Overdue task → days_until_due is negative → urgency_index is higher (correct)
--    - Two tasks same priority, one overdue → overdue ranks higher (correct)
--    - NULL priority → excluded from CASE; assign default weight 1 defensively
--
-- 4. UNIT: Dimensionless score (integer); higher = more urgent
--
-- 5. WHAT WOULD MAKE IT MISLEADING:
--    - Original tried priority (VARCHAR) × 10 → ORA-01722 invalid number
--    - Original added a NUMBER to a DATE → Oracle returns a DATE, not a score
--    - Weight multiplier (×10) vs. day offset is arbitrary; a task due in 11 days
--      with priority=high (score=19) ranks below a critical task due in 39 days (score=1)
--      — the scale may need tuning per business context

-- EXERCISE 5: Improved "Overdue Tasks" — Detailed Report + Summary

SELECT
    ts.title,
    u.full_name                                     AS assignee,
    t.name                                          AS team,
    ts.priority,
    ts.due_date,
    TRUNC(SYSDATE) - ts.due_date                    AS days_overdue,
    CASE
        WHEN ts.priority = 'critical'
         AND (TRUNC(SYSDATE) - ts.due_date) > 0        THEN 'CRITICAL'
        WHEN ts.priority = 'high'
         AND (TRUNC(SYSDATE) - ts.due_date) > 2        THEN 'HIGH'
        WHEN ts.priority = 'medium'
         AND (TRUNC(SYSDATE) - ts.due_date) > 5        THEN 'MEDIUM'
        ELSE 'LOW'
    END                                             AS severity
FROM   tasks ts
JOIN   users u ON u.id       = ts.assigned_to
JOIN   teams t ON t.id       = u.team_id
WHERE  ts.due_date IS NOT NULL
  AND  ts.due_date < TRUNC(SYSDATE)
  AND  ts.status NOT IN ('completed', 'cancelled')

UNION ALL

SELECT
    'SUMMARY — ' || severity_group                  AS title,
    NULL                                            AS assignee,
    NULL                                            AS team,
    NULL                                            AS priority,
    NULL                                            AS due_date,
    ROUND(AVG(days_ov))                             AS days_overdue,
    severity_group                                  AS severity
FROM (
    SELECT
        TRUNC(SYSDATE) - ts2.due_date               AS days_ov,
        CASE
            WHEN ts2.priority = 'critical'
             AND (TRUNC(SYSDATE) - ts2.due_date) > 0    THEN 'CRITICAL'
            WHEN ts2.priority = 'high'
             AND (TRUNC(SYSDATE) - ts2.due_date) > 2    THEN 'HIGH'
            WHEN ts2.priority = 'medium'
             AND (TRUNC(SYSDATE) - ts2.due_date) > 5    THEN 'MEDIUM'
            ELSE 'LOW'
        END                                         AS severity_group
    FROM   tasks ts2
    WHERE  ts2.due_date IS NOT NULL
      AND  ts2.due_date < TRUNC(SYSDATE)
      AND  ts2.status NOT IN ('completed', 'cancelled')
)
GROUP  BY severity_group

ORDER  BY
    CASE severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH'     THEN 2
        WHEN 'MEDIUM'   THEN 3
        ELSE 4
    END,
    days_overdue DESC;


-- ============================================================
-- EXERCISE 6: Fix "Productivity Score"
-- ============================================================
--
-- PROBLEM: The original counts ALL tasks assigned to a user regardless
-- of status. Assigning yourself 20 tasks and completing 0 gives a score
-- of 20. It rewards task hoarding, not delivery. It also ignores task
-- complexity (a critical bug vs. a typo fix count equally).
--
-- REWRITE: Completed tasks per active day, weighted by priority.
-- Priority weights: critical=4, high=3, medium=2, low=1.
-- "Active day" = days since user's first assigned task (minimum 1).
-- This rewards users who close high-priority work consistently.

SELECT
    u.full_name,
    COUNT(ts.id)                                    AS completed_tasks,
    SUM(
        CASE ts.priority
            WHEN 'critical' THEN 4
            WHEN 'high'     THEN 3
            WHEN 'medium'   THEN 2
            WHEN 'low'      THEN 1
            ELSE 1
        END
    )                                               AS weighted_score,
    GREATEST(TRUNC(SYSDATE) - TRUNC(MIN(ts.created_at)), 1)
                                                    AS active_days,
    ROUND(
        SUM(
            CASE ts.priority
                WHEN 'critical' THEN 4
                WHEN 'high'     THEN 3
                WHEN 'medium'   THEN 2
                WHEN 'low'      THEN 1
                ELSE 1
            END
        ) * 1.0
        / GREATEST(TRUNC(SYSDATE) - TRUNC(MIN(ts.created_at)), 1),
    2)                                              AS weighted_score_per_day
FROM   users u
LEFT   JOIN tasks ts ON ts.assigned_to = u.id
                    AND ts.status      = 'completed'
                    AND ts.completed_at IS NOT NULL
GROUP  BY u.id, u.full_name
ORDER  BY weighted_score_per_day DESC NULLS LAST;


-- ============================================================
-- EXERCISE 7: Fix "Team Efficiency"
-- ============================================================
--
-- PROBLEM: AVG(ts.id) is averaging the primary key — an auto-increment
-- integer that has no business meaning whatsoever. A "higher average ID"
-- just means the team was assigned newer (later-created) tasks, not that
-- they are more efficient. It is pure nonsense as a metric.
--
-- REWRITE: Ratio of completed tasks to total non-cancelled tasks per team.
-- This measures what fraction of the work a team actually finishes.

SELECT
    t.name                                          AS team_name,
    COUNT(ts.id)                                    AS total_tasks,
    SUM(CASE WHEN ts.status = 'completed'  THEN 1 ELSE 0 END)
                                                    AS completed_tasks,
    SUM(CASE WHEN ts.status != 'cancelled' THEN 1 ELSE 0 END)
                                                    AS non_cancelled_tasks,
    ROUND(
        SUM(CASE WHEN ts.status = 'completed' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(SUM(CASE WHEN ts.status != 'cancelled' THEN 1 ELSE 0 END), 0),
    1)                                              AS efficiency_pct
FROM   teams t
LEFT   JOIN users u  ON u.team_id     = t.id
LEFT   JOIN tasks ts ON ts.assigned_to = u.id
GROUP  BY t.id, t.name
ORDER  BY efficiency_pct DESC NULLS LAST;


-- ============================================================
-- EXERCISE 8: Fix "Urgency Index"
-- ============================================================
--
-- PROBLEM 1: priority is VARCHAR2 — multiplying a string by 10 raises
--            ORA-01722 (invalid number). Oracle does NOT implicitly
--            cast 'high' to a number.
-- PROBLEM 2: Adding a NUMBER to a DATE in Oracle yields a DATE
--            (Oracle interprets the number as days). So even if priority
--            were numeric, priority * 10 + due_date would be a date, not
--            a useful score.
-- PROBLEM 3: Even if it ran, the result would be meaningless: a date
--            + 40 has no urgency semantics.
--
-- REWRITE: Numeric priority weight minus days until due (negative = overdue).
-- Score = priority_weight * 10 - days_until_due
-- Higher score = more urgent (overdue critical tasks score highest).

SELECT
    title,
    priority,
    due_date,
    TRUNC(due_date) - TRUNC(SYSDATE)                AS days_until_due,
    CASE priority
        WHEN 'critical' THEN 4
        WHEN 'high'     THEN 3
        WHEN 'medium'   THEN 2
        WHEN 'low'      THEN 1
        ELSE 1
    END * 10
    - (TRUNC(due_date) - TRUNC(SYSDATE))            AS urgency_index
FROM   tasks
WHERE  status NOT IN ('completed', 'cancelled')
  AND  due_date IS NOT NULL
ORDER  BY urgency_index DESC;


-- ============================================================
-- PART D BONUS: Single-Query Dashboard
-- ============================================================

WITH base AS (
    -- Enrich every task with derived columns used across multiple metrics
    SELECT
        ts.*,
        -- Resolution hours (only meaningful for completed tasks)
        CASE WHEN ts.status = 'completed' AND ts.completed_at IS NOT NULL
             THEN EXTRACT(DAY    FROM (ts.completed_at - ts.created_at)) * 24
                + EXTRACT(HOUR   FROM (ts.completed_at - ts.created_at))
                + EXTRACT(MINUTE FROM (ts.completed_at - ts.created_at)) / 60
        END                                         AS resolution_hours,
        -- Days overdue (positive = overdue, only for non-closed tasks)
        CASE WHEN ts.due_date IS NOT NULL
              AND ts.due_date < TRUNC(SYSDATE)
              AND ts.status NOT IN ('completed','cancelled')
             THEN TRUNC(SYSDATE) - ts.due_date
        END                                         AS days_overdue,
        u.team_id
    FROM   tasks ts
    LEFT   JOIN users u ON u.id = ts.assigned_to
),
metrics AS (
    SELECT
        COUNT(*)                                                       AS total_tasks,
        SUM(CASE WHEN status = 'completed'                  THEN 1 ELSE 0 END)
                                                                       AS completed_tasks,
        SUM(CASE WHEN status IN ('open','in_progress','blocked') THEN 1 ELSE 0 END)
                                                                       AS active_tasks,
        SUM(CASE WHEN days_overdue IS NOT NULL               THEN 1 ELSE 0 END)
                                                                       AS overdue_tasks,
        ROUND(
            SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) * 100.0
            / NULLIF(COUNT(*), 0),
        1)                                                             AS completion_rate_pct,
        ROUND(AVG(resolution_hours), 1)                                AS avg_resolution_hours,
        ROUND(AVG(days_overdue), 1)                                    AS avg_days_overdue
    FROM   base
),
active_by_priority AS (
    SELECT priority, COUNT(*) AS cnt
    FROM   base
    WHERE  status IN ('open','in_progress','blocked')
    GROUP  BY priority
    ORDER  BY cnt DESC
    FETCH  FIRST 1 ROW ONLY
),
active_by_team AS (
    SELECT t.name AS team_name, COUNT(*) AS cnt
    FROM   base b
    JOIN   teams t ON t.id = b.team_id
    WHERE  b.status IN ('open','in_progress','blocked')
    GROUP  BY t.id, t.name
    ORDER  BY cnt DESC
    FETCH  FIRST 1 ROW ONLY
)
SELECT
    m.total_tasks,
    m.completed_tasks,
    m.active_tasks,
    m.overdue_tasks,
    m.completion_rate_pct,
    m.avg_resolution_hours,
    m.avg_days_overdue,
    p.priority                                      AS most_common_priority,
    bt.team_name                                    AS busiest_team
FROM   metrics m
CROSS  JOIN active_by_priority p
CROSS  JOIN active_by_team     bt;
