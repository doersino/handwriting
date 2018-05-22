-- Hand writing recognition.
-- psql -d handwriting -f handwriting.sql -v pen='[{"x":1, "y":2},{"x":3, "y":4}]'

-- original example
--\set pen '[{"x":1, "y":2},{"x":2, "y":4}]'

-- A
\set pen '[ { "x": 38, "y": 147 }, { "x": 38, "y": 147 }, { "x": 38, "y": 145 }, { "x": 38, "y": 143 }, { "x": 38, "y": 140 }, { "x": 40, "y": 135 }, { "x": 43, "y": 130 }, { "x": 49, "y": 120 }, { "x": 53, "y": 113 }, { "x": 58, "y": 106 }, { "x": 62, "y": 97 }, { "x": 68, "y": 88 }, { "x": 74, "y": 79 }, { "x": 78, "y": 71 }, { "x": 82, "y": 62 }, { "x": 85, "y": 58 }, { "x": 87, "y": 53 }, { "x": 90, "y": 46 }, { "x": 92, "y": 43 }, { "x": 94, "y": 40 }, { "x": 96, "y": 37 }, { "x": 96, "y": 35 }, { "x": 97, "y": 34 }, { "x": 98, "y": 34 }, { "x": 98, "y": 34 }, { "x": 98, "y": 34 }, { "x": 98, "y": 35 }, { "x": 99, "y": 40 }, { "x": 100, "y": 45 }, { "x": 103, "y": 54 }, { "x": 107, "y": 64 }, { "x": 111, "y": 74 }, { "x": 118, "y": 87 }, { "x": 121, "y": 94 }, { "x": 123, "y": 102 }, { "x": 125, "y": 107 }, { "x": 126, "y": 112 }, { "x": 127, "y": 116 }, { "x": 128, "y": 119 }, { "x": 129, "y": 121 }, { "x": 129, "y": 123 }, { "x": 129, "y": 125 }, { "x": 129, "y": 126 }, { "x": 130, "y": 127 }, { "x": 130, "y": 128 }, { "x": 130, "y": 129 }, { "x": 131, "y": 130 }, { "x": 131, "y": 131 }, { "x": 131, "y": 132 }, { "x": 131, "y": 133 }, { "x": 131, "y": 134 }, { "x": 132, "y": 135 }, { "x": 132, "y": 135 }, { "x": 131, "y": 135 }, { "x": 128, "y": 133 }, { "x": 124, "y": 131 }, { "x": 120, "y": 129 }, { "x": 114, "y": 127 }, { "x": 110, "y": 125 }, { "x": 105, "y": 123 }, { "x": 101, "y": 121 }, { "x": 97, "y": 119 }, { "x": 92, "y": 117 }, { "x": 89, "y": 116 }, { "x": 86, "y": 114 }, { "x": 85, "y": 114 }, { "x": 81, "y": 113 }, { "x": 80, "y": 112 }, { "x": 78, "y": 111 }, { "x": 76, "y": 110 }, { "x": 75, "y": 110 }, { "x": 74, "y": 109 }, { "x": 72, "y": 109 }, { "x": 71, "y": 108 }, { "x": 70, "y": 108 }, { "x": 68, "y": 107 }, { "x": 67, "y": 107 }, { "x": 66, "y": 107 }, { "x": 65, "y": 106 }, { "x": 65, "y": 106 }, { "x": 65, "y": 106 } ]'

-- I
--\set pen '[ { "x": 77, "y": 47 }, { "x": 77, "y": 48 }, { "x": 77, "y": 51 }, { "x": 77, "y": 60 }, { "x": 77, "y": 79 }, { "x": 77, "y": 98 }, { "x": 77, "y": 115 }, { "x": 77, "y": 129 }, { "x": 77, "y": 138 }, { "x": 77, "y": 146 }, { "x": 77, "y": 151 }, { "x": 77, "y": 155 }, { "x": 77, "y": 157 }, { "x": 77, "y": 158 }, { "x": 78, "y": 159 }, { "x": 78, "y": 159 } ]'

-- J
--\set pen '[ { "x": 102, "y": 42 }, { "x": 102, "y": 42 }, { "x": 102, "y": 43 }, { "x": 102, "y": 45 }, { "x": 102, "y": 55 }, { "x": 102, "y": 64 }, { "x": 102, "y": 76 }, { "x": 102, "y": 87 }, { "x": 102, "y": 96 }, { "x": 102, "y": 103 }, { "x": 102, "y": 109 }, { "x": 101, "y": 115 }, { "x": 100, "y": 121 }, { "x": 99, "y": 126 }, { "x": 97, "y": 131 }, { "x": 96, "y": 136 }, { "x": 95, "y": 139 }, { "x": 91, "y": 144 }, { "x": 87, "y": 146 }, { "x": 84, "y": 147 }, { "x": 80, "y": 148 }, { "x": 74, "y": 148 }, { "x": 71, "y": 145 }, { "x": 68, "y": 139 }, { "x": 66, "y": 133 }, { "x": 64, "y": 127 }, { "x": 63, "y": 121 }, { "x": 63, "y": 117 }, { "x": 63, "y": 115 }, { "x": 63, "y": 113 } ]'

-- testing
--\set pen '[ { "x": 49, "y": 141 }, { "x": 49, "y": 140 }, { "x": 49, "y": 139 }, { "x": 49, "y": 134 }, { "x": 49, "y": 122 }, { "x": 48, "y": 112 }, { "x": 47, "y": 100 }, { "x": 46, "y": 93 }, { "x": 46, "y": 84 }, { "x": 45, "y": 76 }, { "x": 45, "y": 70 }, { "x": 45, "y": 66 }, { "x": 45, "y": 61 }, { "x": 45, "y": 57 }, { "x": 45, "y": 55 }, { "x": 45, "y": 54 }, { "x": 46, "y": 53 }, { "x": 46, "y": 49 }, { "x": 47, "y": 47 }, { "x": 49, "y": 43 }, { "x": 50, "y": 40 }, { "x": 51, "y": 37 }, { "x": 52, "y": 35 }, { "x": 54, "y": 34 }, { "x": 56, "y": 33 }, { "x": 59, "y": 31 }, { "x": 62, "y": 29 }, { "x": 64, "y": 28 }, { "x": 66, "y": 28 }, { "x": 69, "y": 28 }, { "x": 71, "y": 28 }, { "x": 75, "y": 28 }, { "x": 78, "y": 28 }, { "x": 81, "y": 30 }, { "x": 83, "y": 33 }, { "x": 85, "y": 38 }, { "x": 86, "y": 43 }, { "x": 86, "y": 51 }, { "x": 86, "y": 57 }, { "x": 85, "y": 64 }, { "x": 81, "y": 70 }, { "x": 75, "y": 75 }, { "x": 69, "y": 79 }, { "x": 64, "y": 82 }, { "x": 58, "y": 85 }, { "x": 54, "y": 88 }, { "x": 51, "y": 90 }, { "x": 49, "y": 91 }, { "x": 49, "y": 92 }, { "x": 48, "y": 92 }, { "x": 48, "y": 92 }, { "x": 48, "y": 92 }, { "x": 48, "y": 92 }, { "x": 48, "y": 91 }, { "x": 49, "y": 91 }, { "x": 53, "y": 90 }, { "x": 58, "y": 89 }, { "x": 64, "y": 89 }, { "x": 70, "y": 89 }, { "x": 77, "y": 89 }, { "x": 83, "y": 90 }, { "x": 86, "y": 92 }, { "x": 89, "y": 94 }, { "x": 91, "y": 96 }, { "x": 93, "y": 99 }, { "x": 94, "y": 102 }, { "x": 95, "y": 105 }, { "x": 96, "y": 109 }, { "x": 96, "y": 112 }, { "x": 96, "y": 115 }, { "x": 96, "y": 119 }, { "x": 94, "y": 125 }, { "x": 91, "y": 127 }, { "x": 88, "y": 131 }, { "x": 83, "y": 135 }, { "x": 80, "y": 136 }, { "x": 78, "y": 136 }, { "x": 74, "y": 136 }, { "x": 71, "y": 136 }, { "x": 67, "y": 136 }, { "x": 63, "y": 136 }, { "x": 60, "y": 136 }, { "x": 57, "y": 136 }, { "x": 56, "y": 136 }, { "x": 55, "y": 136 } ]'

-- hysteresis zones test
--\set pen '[ { "x": 46, "y": 162 }, { "x": 46, "y": 161 }, { "x": 47, "y": 161 }, { "x": 47, "y": 161 }, { "x": 47, "y": 161 }, { "x": 47, "y": 161 }, { "x": 48, "y": 161 }, { "x": 48, "y": 161 }, { "x": 48, "y": 161 }, { "x": 48, "y": 161 }, { "x": 48, "y": 160 }, { "x": 48, "y": 160 }, { "x": 49, "y": 160 }, { "x": 49, "y": 160 }, { "x": 49, "y": 160 }, { "x": 49, "y": 160 }, { "x": 50, "y": 160 }, { "x": 50, "y": 160 }, { "x": 50, "y": 160 }, { "x": 50, "y": 160 }, { "x": 51, "y": 160 }, { "x": 51, "y": 160 }, { "x": 51, "y": 159 }, { "x": 51, "y": 159 }, { "x": 51, "y": 159 }, { "x": 52, "y": 159 }, { "x": 52, "y": 158 }, { "x": 52, "y": 158 }, { "x": 53, "y": 158 }, { "x": 53, "y": 158 }, { "x": 53, "y": 158 }, { "x": 53, "y": 158 }, { "x": 53, "y": 157 }, { "x": 53, "y": 157 }, { "x": 53, "y": 157 }, { "x": 53, "y": 157 }, { "x": 53, "y": 156 }, { "x": 53, "y": 156 }, { "x": 53, "y": 156 }, { "x": 53, "y": 155 }, { "x": 53, "y": 155 }, { "x": 53, "y": 154 }, { "x": 53, "y": 154 }, { "x": 53, "y": 153 }, { "x": 53, "y": 153 }, { "x": 53, "y": 153 }, { "x": 53, "y": 152 }, { "x": 53, "y": 152 }, { "x": 54, "y": 152 }, { "x": 54, "y": 152 }, { "x": 56, "y": 151 }, { "x": 58, "y": 150 }, { "x": 58, "y": 150 }, { "x": 59, "y": 150 }, { "x": 59, "y": 150 }, { "x": 60, "y": 150 }, { "x": 60, "y": 150 }, { "x": 60, "y": 150 }, { "x": 60, "y": 149 }, { "x": 60, "y": 149 }, { "x": 61, "y": 149 }, { "x": 61, "y": 149 }, { "x": 61, "y": 149 }, { "x": 61, "y": 149 }, { "x": 61, "y": 149 }, { "x": 61, "y": 148 }, { "x": 61, "y": 148 }, { "x": 61, "y": 148 }, { "x": 60, "y": 148 }, { "x": 60, "y": 147 }, { "x": 60, "y": 147 }, { "x": 60, "y": 147 }, { "x": 60, "y": 147 }, { "x": 60, "y": 147 }, { "x": 60, "y": 146 }, { "x": 60, "y": 146 }, { "x": 60, "y": 146 }, { "x": 60, "y": 146 }, { "x": 60, "y": 145 }, { "x": 61, "y": 145 }, { "x": 62, "y": 144 }, { "x": 63, "y": 143 }, { "x": 64, "y": 143 }, { "x": 64, "y": 143 }, { "x": 64, "y": 142 }, { "x": 64, "y": 142 }, { "x": 65, "y": 142 }, { "x": 66, "y": 140 }, { "x": 67, "y": 140 }, { "x": 67, "y": 139 }, { "x": 68, "y": 139 }, { "x": 68, "y": 139 }, { "x": 68, "y": 138 }, { "x": 69, "y": 138 }, { "x": 69, "y": 138 }, { "x": 69, "y": 137 }, { "x": 69, "y": 137 }, { "x": 69, "y": 137 }, { "x": 69, "y": 137 }, { "x": 69, "y": 136 }, { "x": 69, "y": 136 }, { "x": 70, "y": 136 }, { "x": 70, "y": 136 }, { "x": 70, "y": 136 }, { "x": 71, "y": 135 }, { "x": 71, "y": 135 }, { "x": 71, "y": 135 }, { "x": 71, "y": 135 }, { "x": 71, "y": 134 }, { "x": 72, "y": 134 }, { "x": 73, "y": 133 }, { "x": 74, "y": 132 }, { "x": 75, "y": 131 }, { "x": 76, "y": 131 }, { "x": 76, "y": 131 }, { "x": 77, "y": 131 }, { "x": 77, "y": 130 }, { "x": 77, "y": 130 }, { "x": 77, "y": 129 }, { "x": 77, "y": 128 }, { "x": 78, "y": 127 }, { "x": 78, "y": 126 }, { "x": 79, "y": 126 }, { "x": 79, "y": 125 }, { "x": 79, "y": 125 }, { "x": 79, "y": 125 }, { "x": 81, "y": 125 }, { "x": 82, "y": 125 }, { "x": 83, "y": 125 }, { "x": 83, "y": 125 }, { "x": 84, "y": 125 }, { "x": 84, "y": 125 }, { "x": 84, "y": 125 }, { "x": 84, "y": 125 }, { "x": 85, "y": 124 }, { "x": 85, "y": 124 }, { "x": 85, "y": 124 } ]'

\set pen '[ { "x": 34, "y": 159 }, { "x": 34, "y": 159 }, { "x": 34, "y": 158 }, { "x": 34, "y": 157 }, { "x": 34, "y": 155 }, { "x": 36, "y": 151 }, { "x": 38, "y": 144 }, { "x": 40, "y": 138 }, { "x": 44, "y": 131 }, { "x": 46, "y": 125 }, { "x": 50, "y": 115 }, { "x": 55, "y": 102 }, { "x": 59, "y": 92 }, { "x": 64, "y": 80 }, { "x": 66, "y": 73 }, { "x": 70, "y": 64 }, { "x": 72, "y": 60 }, { "x": 74, "y": 57 }, { "x": 74, "y": 56 }, { "x": 75, "y": 54 }, { "x": 75, "y": 54 }, { "x": 75, "y": 54 }, { "x": 75, "y": 54 }, { "x": 75, "y": 54 }, { "x": 75, "y": 54 }, { "x": 75, "y": 56 }, { "x": 76, "y": 62 }, { "x": 78, "y": 76 }, { "x": 81, "y": 88 }, { "x": 83, "y": 96 }, { "x": 85, "y": 106 }, { "x": 87, "y": 114 }, { "x": 89, "y": 124 }, { "x": 91, "y": 131 }, { "x": 92, "y": 137 }, { "x": 93, "y": 140 }, { "x": 94, "y": 144 }, { "x": 95, "y": 146 }, { "x": 96, "y": 148 }, { "x": 96, "y": 150 }, { "x": 96, "y": 150 }, { "x": 96, "y": 151 }, { "x": 96, "y": 152 }, { "x": 96, "y": 152 }, { "x": 96, "y": 152 }, { "x": 96, "y": 152 }, { "x": 96, "y": 152 }, { "x": 96, "y": 151 }, { "x": 94, "y": 149 }, { "x": 91, "y": 146 }, { "x": 86, "y": 142 }, { "x": 77, "y": 135 }, { "x": 73, "y": 132 }, { "x": 65, "y": 127 }, { "x": 59, "y": 123 }, { "x": 56, "y": 120 }, { "x": 55, "y": 119 }, { "x": 52, "y": 117 }, { "x": 51, "y": 116 }, { "x": 50, "y": 116 }, { "x": 50, "y": 116 }, { "x": 50, "y": 116 }, { "x": 50, "y": 116 }, { "x": 50, "y": 116 }, { "x": 50, "y": 116 }, { "x": 50, "y": 115 } ]'

---------------------------------
-- TOGGLES, KNOBS AND SWITCHES --
---------------------------------

-- Height of canvas.
\set height 200

-- Weight of previously smoothed point (0 < n < 1).
\set smoothingfactor 0.75

-- Size of thinning box in px (roughly 10x the essay values).
\set thinningsize 5

-- Minimum angle for a corner to be recognized.
\set cornerangle 80

\timing on
\pset border 2

----------------------------------------
-- TYPES, FUNCTIONS AND LOOKUP TABLE  --
----------------------------------------

DROP TYPE IF EXISTS cardinal_direction;
CREATE TYPE cardinal_direction AS ENUM('▶', '▲', '◀', '▼');

CREATE OR REPLACE FUNCTION gridpos(width real, height real, xmin real, ymin real, x real, y real) RETURNS int AS $$
BEGIN
  RETURN greatest(0,
                  15 - ((floor(4 * (x-xmin)/(width + 1)) :: int)
                        + 4 * (floor(4 * (y-ymin)/(height + 1)) :: int)));
END
$$ LANGUAGE plpgsql;

-- TODO lookup


---------------------------------------------------------------
-- ONE QUERY TO RULE THEM ALL, ONE QUERY TO FIND THEM, --------
-- ONE QUERY TO BRING THEM ALL AND IN THE DARKNESS BIND THEM --
---------------------------------------------------------------

WITH RECURSIVE
tablet(pos, x, y) AS (
  -- Initial step: Convert JSON data into tabular representation of pen stroke.
  -- It would be kinda cool to use the built-in path type here (and line/point/
  -- box types throughout the rest of the query), but seems like there's no way
  -- to extract a path's constituent points (apart from parsing them from a
  -- textual representation, which seems silly), making it pretty useless here.
  SELECT ordinality AS pos, x, :'height' - y  -- Move origin from top left to bottom left.
  FROM   ROWS FROM(jsonb_to_recordset(:'pen') AS (x int, y int))
         WITH ORDINALITY
),
smooth(pos, x, y) AS (
  -- Smooth pen stroke to remove quantization jitter. Return doubles because the
  -- more idiomatic numeric type will feature unnecessarily many decimal places
  -- after a few iterations.
  SELECT pos, x :: real, y :: real
  FROM   tablet
  WHERE  pos = 1

    UNION ALL

  SELECT t.pos,
         (:'smoothingfactor' * s.x + (1.0 - :'smoothingfactor') * t.x) :: real AS x,
         (:'smoothingfactor' * s.y + (1.0 - :'smoothingfactor') * t.y) :: real AS y
  FROM   smooth s, tablet t
  WHERE  t.pos = s.pos + 1
),
thin(pos, x, y) AS (
  -- Thin stroke by removing all points within a certain distance from most
  -- recent already thinned point.
  SELECT *
  FROM   smooth
  WHERE  pos = 1

    UNION ALL

  SELECT *
  FROM   (  -- ORDER BY being illegal in the recursive part of a WITH RECURSIVE necessitates this ugly subquery hack.
    SELECT s.pos, s.x, s.y
    FROM   thin t, smooth s
    WHERE  s.pos > t.pos
    AND    |/ (s.x - t.x)^2 + (s.y - t.y)^2 >= :'thinningsize'
    --AND    (abs(s.x - t.x) >= :'thinningsize' OR abs(s.y - t.y) >= :'thinningsize')  -- Alternative, closer to the original specification, but "incorrect".
    ORDER BY s.pos
    LIMIT 1
  ) AS _
),
curve(pos, x, y, direction) AS (
  -- Compute angle (in integer degrees) between each adjacent pair of points.
  -- 0 degrees corresponds to both points lying on a horizontal line, with the
  -- newer point to the right of the older point. 90 degrees means that the
  -- newer point is directly above the older point. Remaining values follow the
  -- same pattern (think unit circle).
  SELECT pos, x, y,
         COALESCE(degrees(-atan2( y - lag(y) OVER (ORDER BY pos),
                                 -x + lag(x) OVER (ORDER BY pos))
                         ) + 180,
                  90)  -- First point corresponds to "up" direction,
                       -- matches essay implementation and avoids NULLs.
  FROM   thin
),
cardinal(pos, direction) AS (
  -- Compute cardinal direction for each point from angle. Note that this is
  -- done using a set of inequalities in the essay, which is computationally
  -- less expensive, but it really doesn't make a difference considering 50
  -- years' worth of Moore's law between the algorithm's conception and the time
  -- of this implementation.
  SELECT pos, (enum_range(NULL :: cardinal_direction))[(direction / 90) :: int + 1]
  FROM curve
),
--cardinal_hysteresis(pos, actual_direction, direction) AS (
--  -- Same as above, but featuring so-called hysteresis zones with a width of 8
--  -- degrees which keep the emitted cardinal direction from switching around
--  -- between two values for an around-45-degree stroke.
--  SELECT pos, direction, (enum_range(NULL :: cardinal_direction))[(direction / 90) :: int]
--  FROM curve
--  WHERE pos = 1
--
--    UNION ALL
--
--  SELECT * FROM
--    (SELECT c.pos,
--            CASE
--              WHEN abs(c.direction - c42.actual_direction) < 8
--              THEN c42.actual_direction
--              ELSE c.direction
--            END,
--            (enum_range(NULL :: cardinal_direction))[((
--              CASE
--                WHEN abs(c.direction - c42.actual_direction) < 8
--                THEN c42.actual_direction
--                ELSE c.direction
--              END) / 90) :: int]
--     FROM curve c, cardinal_hysteresis c42
--     WHERE c.pos > c42.pos
--     ORDER BY c.pos
--     LIMIT 1) AS _
--),
cardinal_change(pos, direction) AS (
  -- Only keep changes (meaning a new direction that occurs at least twice in
  -- succession) of the cardinal direction.
  SELECT pos, direction
  FROM   (SELECT pos, direction,  -- *,
                 COALESCE(lag(direction, 2) OVER win <> lag(direction) OVER win, true)
                 AND lag(direction) OVER win = direction
          FROM cardinal  -- cardinal_hysteresis
          WINDOW win AS (ORDER BY pos)) AS _(pos, direction, is_new)
  WHERE is_new
),
corner(pos, x, y, corner) AS (
  -- Detect corners: between two segments going in the same direction and two
  -- segments going into a wildly different direction, with an optional in-
  -- between "turn" segment with an arbitrary direction.
  SELECT pos, x, y, (
           lag(direction) OVER win = lag(direction, 2) OVER win  -- One-segment turn.
           AND lead(direction) OVER win = lead(direction, 2) OVER win
           AND abs(lag(direction) OVER win - lead(direction) OVER win) > :cornerangle / 16
         ) OR (
           direction = lag(direction) OVER win  -- Immediate direction change.
           AND lead(direction) OVER win = lead(direction, 2) OVER win
           AND abs(direction - lead(direction) OVER win) > :cornerangle / 16
         )
  FROM   (SELECT pos, x, y, (direction / 22.5) :: int AS direction
          FROM curve) AS _
  WINDOW win AS (ORDER BY pos)
),
--corner_hysteresis(pos, x, y, corner) AS (
--  -- Same as above, but utilizing a different approach and allowing slight
--  -- differences in the directions of each pair of pre- and post-corner
--  -- segments.
--  SELECT pos,
--         x,
--         y,
--         abs(corner[1] - corner[2]) <= 1 AND
--         abs(corner[array_length(corner, 1)] - corner[array_length(corner, 1) - 1]) <= 1 AND
--         abs(corner[2] - corner[array_length(corner, 1) - 1]) > :cornerangle / 16;  --, direction
--  FROM   (SELECT *,
--                 array_agg(direction) OVER (ORDER BY pos ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS corner
--          FROM (SELECT pos, x, y, (direction / 22.5) :: int AS direction
--                FROM curve) AS _
--          WINDOW win AS (ORDER BY pos)) AS _
--),
aabb(xmin, xmax, ymin, ymax, aspect, width, height, centerx, centery) AS (
  -- Define an axis-aligned bounding box (AABB) around the drawn letter and
  -- output some statistics.
  SELECT min(x),
         max(x),
         min(y),
         max(y),
         (max(y) - min(y)) / greatest(1, (max(x) - min(x))),  -- Prevent division by zero.
         max(x) - min(x),
         max(y) - min(y),
         min(x) + (max(x) - min(x)) / 2,
         min(y) + (max(y) - min(y)) / 2
  FROM smooth
),
start_grid(n) AS (
  -- Start point (pen-down position) as an area on a 4x4 grid.
  SELECT gridpos(a.width, a.height, a.xmin, a.ymin, s.x, s.y)
  FROM smooth s, aabb a
  ORDER BY pos
  LIMIT 1
),
stop_grid(n) AS (
  -- End point (pen-up position) as an area on a 4x4 grid.
  SELECT gridpos(a.width, a.height, a.xmin, a.ymin, s.x, s.y)
  FROM smooth s, aabb a
  ORDER BY pos DESC
  LIMIT 1
),
corner_grid(pos, n) AS (
  -- Corners as areas on a 4x4 grid.
  SELECT c.pos, gridpos(a.width, a.height, a.xmin, a.ymin, c.x, c.y)
  FROM corner c, aabb a
  WHERE c.corner
),
features(center, start, stop, directions, corners, width, height, aspect) AS (
  -- Assemble summary of the extracted features, ready for pattern-matching in
  -- the next step. This single-row table should contain all information
  -- required to identify the letter corresponding to the input pen stroke.
  SELECT point(centerx, centery),
         (TABLE start_grid),
         (TABLE stop_grid),
         (SELECT array_agg(c.direction ORDER BY c.pos)
          FROM   cardinal_change c),
         (SELECT array_agg(c.n ORDER BY c.pos)
          FROM   corner_grid c),
         a.width,
         a.height,
         a.aspect
  FROM aabb a
),
possible_characters(characters) AS (
  -- TODO nice result formatting ("i think you mean S, however it could also be 5, etc.")
  -- TODO maybe just lookup table with all the features (maybe upper/lower bounds for some of them, also need NULL or something for don't care), then last col => char. if nothing found, not recognized
  SELECT CASE
           WHEN next_step = NULL
           THEN possible_characters
           ELSE possible_characters  -- TODO
         END
  FROM features, (VALUES
                    ('{3}' :: int[], '{"I"}' :: char[], NULL),
                    ('{3,2}', '{"J"}', NULL),
                    ('{3,2,1}', '{"O", "J", "X", "U"}', NULL),
                    ('{3,2,1,0}', '{"X", "O", "U"}', 'disc0UX'),
                    ('{3,2,0,1}', '{"X"}', NULL),
                    ('{3,0}', '{"L"}', NULL),
                    ('{3,0,2}', '{"6"}', NULL),
                    ('{3,0,2,3}', '{"4"}', NULL),
                    ('{3,0,1}', '{"O", "U"}', 'discOU'),
                    ('{3,0,1,3}', '{"4", "Y"}', 'disc4Y'),
                    ('{3,0,1,2}', '{"6", "8", "O", "D", "4"}', 'disc680D4'),
                    ('{3,0,1,0}', '{"8"}', NULL),
                    ('{3,1}', '{"V"}', NULL),
                    ('{3,1,3}', '{"K"}', NULL),
                    ('{3,1,3,1}', '{"W"}', NULL),
                    ('{3,1,3,0}', '{"W", "K"}', 'discWK'),
                    ('{3,1,0,3}', '{"H"}', NULL),
                    ('{2,3}', '{"F"}', NULL),
                    ('{2,3,2}', '{"S"}', NULL),
                    ('{2,3,2,3}', '{"E"}', NULL),
                    ('{2,3,0,2}', '{"E", "6"}', 'discE6'),
                    ('{2,0,3,2}', '{"S", "8"}', 'discS8'),
                    ('{2,0,3,0}', '{"E"}', NULL),
                    ('{2,0,2}', '{"S"}', NULL),
                    ('{2,0,2,3}', '{"E"}', NULL),
                    ('{2,0,2,0}', '{"E"}', NULL),
                    ('{2,3,0}', '{"C"}', NULL),
                    ('{2,3,0,3}', '{"5", "8", "9", "S", "E"}', 'disc589SE'),
                    ('{2,3,0,1}', '{"6", "O", "C", "G", "9"}', 'disc6OCG9'),
                    ('{2,1,0,3}', '{"9", "8", "Q"}', 'disc98Q'),
                    ('{0,2,3}', '{"7"}', NULL),
                    ('{0,2,3,0}', '{"3", "2", "Z"}', 'disc32Z'),
                    ('{0,2,0,2}', '{"3"}', NULL),
                    ('{0,2,0}', '{"2", "Z"}', 'disc2Z'),
                    ('{0,2,0,3}', '{"3"}', NULL),
                    ('{0,3}', '{"7", "1"}', 'disc71'),
                    ('{0,3,2}', '{"7", "3"}', 'disc73'),
                    ('{0,3,2,3}', '{"2", "3"}', 'disc32'),
                    ('{0,3,2,1}', '{"O", "2", "3", "U", "X"}', 'disc023UX'),
                    ('{0,3,0,3}', '{"3"}', NULL),
                    ('{0,3,0}', '{"2", "Z"}', 'disc2Z'),
                    ('{0,3,2,0}', '{"3", "2", "Z"}', 'disc32Z'),
                    ('{1,3}', '{"1", "A"}', 'disc1A'),
                    ('{1,3,2}', '{"A"}', NULL),
                    ('{1,3,0}', '{"2"}', NULL),
                    ('{1,3,1}', '{"N", "A"}', 'discNA'),
                    ('{1,3,1,2}', '{"A"}', NULL),
                    ('{1,3,1,3}', '{"M", "N"}', 'discNM'),
                    ('{1,3,1,0}', '{"M", "N"}', 'discNM'),
                    ('{1,3,0,1}', '{"M", "N"}', 'discNM'),
                    ('{1,3,0,3}', '{"M", "N"}', 'discNM'),
                    ('{1,0,1}', '{"M", "N"}', 'discNM'),
                    ('{1,0,1,3}', '{"M", "N"}', 'discNM'),
                    ('{1,0,3,1}', '{"M", "N", "A"}', 'discNMA'),
                    ('{1,2,3,0}', '{"8", "9", "C", "G", "S", "6"}', 'disc89CGS6'),
                    ('{1,2,0}', '{"T"}', NULL),
                    ('{1,0,3,0}', '{"2", "3", "8", "B", "D", "P", "R"}', 'disc238BDPR'),
                    ('{1,0,3,2}', '{"2", "3", "8", "B", "D", "P", "R"}', 'disc238BDPR'),
                    ('{1,0,2,0}', '{"B"}', NULL),
                    ('{1,0}', '{"F"}', NULL)
                 ) AS map(first_four_directions, possible_characters, next_step)
  WHERE directions[1:4] = (SELECT array_agg((ENUM_RANGE(NULL::cardinal_direction))[s.t + 1])
                           FROM unnest(first_four_directions) s(t))
)

SELECT * FROM possible_characters;
