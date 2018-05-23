-- Hand writing recognition scheme modeled after an interactive essay:
-- https://jackschaedler.github.io/handwriting-recognition/
--
-- Usage:
-- Create a databased "handwriting", then use the enclosed HTML file to generate
-- a pen stroke, then run the following on PostgreSQL 10 or newer, replacing the
-- "PEN_STROKE" placeholder with the generated pen stroke:
-- psql -d handwriting -f handwriting.sql -v pen='PEN_STROKE'

-- Original example.
--\set pen '[{"x":1, "y":2},{"x":2, "y":4}]'

-- A
--\set pen '[ { "x": 37, "y": 31 }, { "x": 37, "y": 31 }, { "x": 37, "y": 34 }, { "x": 37, "y": 39 }, { "x": 38, "y": 43 }, { "x": 41, "y": 57 }, { "x": 44, "y": 66 }, { "x": 48, "y": 76 }, { "x": 52, "y": 86 }, { "x": 54, "y": 92 }, { "x": 56, "y": 96 }, { "x": 58, "y": 99 }, { "x": 59, "y": 101 }, { "x": 59, "y": 102 }, { "x": 60, "y": 102 }, { "x": 60, "y": 102 }, { "x": 60, "y": 101 }, { "x": 60, "y": 98 }, { "x": 61, "y": 90 }, { "x": 64, "y": 80 }, { "x": 65, "y": 73 }, { "x": 67, "y": 66 }, { "x": 69, "y": 60 }, { "x": 71, "y": 52 }, { "x": 72, "y": 49 }, { "x": 72, "y": 46 }, { "x": 73, "y": 44 }, { "x": 74, "y": 42 }, { "x": 74, "y": 41 }, { "x": 74, "y": 40 }, { "x": 74, "y": 40 }, { "x": 74, "y": 39 }, { "x": 74, "y": 39 }, { "x": 74, "y": 39 }, { "x": 74, "y": 39 }, { "x": 74, "y": 39 }, { "x": 74, "y": 39 }, { "x": 72, "y": 40 }, { "x": 67, "y": 43 }, { "x": 63, "y": 45 }, { "x": 60, "y": 47 }, { "x": 58, "y": 49 }, { "x": 56, "y": 50 }, { "x": 54, "y": 52 }, { "x": 52, "y": 52 }, { "x": 51, "y": 53 }, { "x": 50, "y": 54 }, { "x": 50, "y": 54 }, { "x": 50, "y": 54 }, { "x": 49, "y": 54 }, { "x": 49, "y": 54 }, { "x": 49, "y": 54 }, { "x": 49, "y": 54 }, { "x": 49, "y": 55 }, { "x": 49, "y": 55 }, { "x": 49, "y": 55 }, { "x": 48, "y": 55 }, { "x": 48, "y": 55 }, { "x": 48, "y": 55 }, { "x": 47, "y": 56 }, { "x": 46, "y": 56 }, { "x": 46, "y": 56 }, { "x": 46, "y": 56 }, { "x": 46, "y": 56 } ]'

---------------------------------
-- TOGGLES, KNOBS AND SWITCHES --
---------------------------------

-- Weight of previously smoothed point (0 < n < 1).
\set smoothingfactor 0.75

-- Size of thinning box in px (roughly 10x the essay values).
\set thinningsize 5

-- Minimum angle for a corner to be recognized.
\set cornerangle 80

-- Make things a bit nicer.
\timing on
\pset border 2


----------------------------------------
-- TYPES, FUNCTIONS AND LOOKUP TABLES --
----------------------------------------

DROP TYPE IF EXISTS cardinal_direction CASCADE;
CREATE TYPE cardinal_direction AS ENUM('▶', '▲', '◀', '▼');

-- Compute position on 4x4 grid from an (x,y) coordinate pair. Used during
-- assembly of features table.
CREATE OR REPLACE FUNCTION gridpos(width real, height real, xmin real, ymin real, x real, y real) RETURNS int AS $$
BEGIN
  RETURN greatest(0,
                  15 - ((floor(4 * (x-xmin)/(width + 1)) :: int)
                        + 4 * (floor(4 * (y-ymin)/(height + 1)) :: int)));
END
$$ LANGUAGE plpgsql;

-- Initial lookup table: Maps an array of up to four starting directions of a
-- stroke to a set of potential characters.
DROP TABLE IF EXISTS lookup1;
CREATE TABLE lookup1 (
  first_four_directions cardinal_direction[],
  potential_characters  char[]
);
INSERT INTO lookup1 VALUES
  ('{"▼"}',             '{"I"}'),
  ('{"▼","◀"}',         '{"J"}'),
  ('{"▼","◀","▲"}',     '{"O","J","X","U"}'),
  ('{"▼","◀","▲","▶"}', '{"X","O","U"}'),
  ('{"▼","◀","▶","▲"}', '{"X"}'),
  ('{"▼","▶"}',         '{"L"}'),
  ('{"▼","▶","◀"}',     '{"6"}'),
  ('{"▼","▶","◀","▼"}', '{"4"}'),
  ('{"▼","▶","▲"}',     '{"O","U"}'),
  ('{"▼","▶","▲","▼"}', '{"4","Y"}'),
  ('{"▼","▶","▲","◀"}', '{"6","8","O","D","4"}'),
  ('{"▼","▶","▲","▶"}', '{"8"}'),
  ('{"▼","▲"}',         '{"V"}'),
  ('{"▼","▲","▼"}',     '{"K"}'),
  ('{"▼","▲","▼","▲"}', '{"W"}'),
  ('{"▼","▲","▼","▶"}', '{"W","K"}'),
  ('{"▼","▲","▶","▼"}', '{"H"}'),
  ('{"◀","▼"}',         '{"F"}'),
  ('{"◀","▼","◀"}',     '{"S"}'),
  ('{"◀","▼","◀","▼"}', '{"E"}'),
  ('{"◀","▼","▶","◀"}', '{"E","6"}'),
  ('{"◀","▶","▼","◀"}', '{"S","8"}'),
  ('{"◀","▶","▼","▶"}', '{"E"}'),
  ('{"◀","▶","◀"}',     '{"S"}'),
  ('{"◀","▶","◀","▼"}', '{"E"}'),
  ('{"◀","▶","◀","▶"}', '{"E"}'),
  ('{"◀","▼","▶"}',     '{"C"}'),
  ('{"◀","▼","▶","▼"}', '{"5","8","9","S","E"}'),
  ('{"◀","▼","▶","▲"}', '{"6","O","C","G","9"}'),
  ('{"◀","▲","▶","▼"}', '{"9","8","Q"}'),
  ('{"▶","◀","▼"}',     '{"7"}'),
  ('{"▶","◀","▼","▶"}', '{"3","2","Z"}'),
  ('{"▶","◀","▶","◀"}', '{"3"}'),
  ('{"▶","◀","▶"}',     '{"2","Z"}'),
  ('{"▶","◀","▶","▼"}', '{"3"}'),
  ('{"▶","▼"}',         '{"7","1"}'),
  ('{"▶","▼","◀"}',     '{"7","3"}'),
  ('{"▶","▼","◀","▼"}', '{"2","3"}'),
  ('{"▶","▼","◀","▲"}', '{"O","2","3","U","X"}'),
  ('{"▶","▼","▶","▼"}', '{"3"}'),
  ('{"▶","▼","▶"}',     '{"2","Z"}'),
  ('{"▶","▼","◀","▶"}', '{"3","2","Z"}'),
  ('{"▲","▼"}',         '{"1","A"}'),
  ('{"▲","▼","◀"}',     '{"A"}'),
  ('{"▲","▼","▶"}',     '{"2"}'),
  ('{"▲","▼","▲"}',     '{"N","A"}'),
  ('{"▲","▼","▲","◀"}', '{"A"}'),
  ('{"▲","▼","▲","▼"}', '{"M","N"}'),
  ('{"▲","▼","▲","▶"}', '{"M","N"}'),
  ('{"▲","▼","▶","▲"}', '{"M","N"}'),
  ('{"▲","▼","▶","▼"}', '{"M","N"}'),
  ('{"▲","▶","▲"}',     '{"M","N"}'),
  ('{"▲","▶","▲","▼"}', '{"M","N"}'),
  ('{"▲","▶","▼","▲"}', '{"M","N","A"}'),
  ('{"▲","◀","▼","▶"}', '{"8","9","C","G","S","6"}'),
  ('{"▲","◀","▶"}',     '{"T"}'),
  ('{"▲","▶","▼","▶"}', '{"2","3","8","B","D","P","R"}'),
  ('{"▲","▶","▼","◀"}', '{"2","3","8","B","D","P","R"}'),
  ('{"▲","▶","◀","▶"}', '{"B"}'),
  ('{"▲","▶"}',         '{"F"}');

-- Final lookup table: Narrows result of initial lookup down based on extracted
-- features.
DROP TABLE IF EXISTS lookup2;
CREATE TABLE lookup2 (
  potential_characters char[],
  character char,
  start int,
  stop int,
  corners int[],
  aspect_range numrange
);
INSERT INTO lookup2  -- All single-character patterns from initial lookup table.
  SELECT DISTINCT ON (potential_characters[1]) potential_characters,
                                               potential_characters[1],
                                               NULL,
                                               NULL,
                                               NULL,
                                               NULL
  FROM   lookup1
  WHERE  array_length(potential_characters, 1) = 1;
INSERT INTO lookup2 VALUES
  ('{"W","K"}', 'W', NULL, 0, NULL, NULL),
  ('{"W","K"}', 'K', NULL, 12, NULL, NULL),
  ('{"M","N"}', 'M', NULL, 12, NULL, NULL),
  ('{"M","N"}', 'N', NULL, 0, NULL, NULL),
  ('{"O","U"}', 'O', 3, 3, NULL, NULL),
  ('{"O","U"}', 'U', 3, 0, NULL, NULL);  -- TODO more!

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
  SELECT ordinality AS pos, x, y
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
  FROM   curve
),
--cardinal_hysteresis(pos, actual_direction, direction) AS (
--  -- Same as above, but featuring so-called hysteresis zones with a width of 8
--  -- degrees which keep the emitted cardinal direction from switching around
--  -- between two values for an around-45-degree stroke.
--  SELECT pos, direction, (enum_range(NULL :: cardinal_direction))[(direction / 90) :: int]
--  FROM   curve
--  WHERE  pos = 1
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
--     FROM   curve c, cardinal_hysteresis c42
--     WHERE  c.pos > c42.pos
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
  WHERE  is_new
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
         )  -- Would be nice to do this in the WHERE clause, but that's illegal.
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
  -- Define an axis-aligned bounding box (AABB) around the drawn character and
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
  FROM   smooth
),
start_grid(n) AS (
  -- Start point (pen-down position) as an area on a 4x4 grid.
  SELECT gridpos(a.width, a.height, a.xmin, a.ymin, s.x, s.y)
  FROM   smooth s, aabb a
  ORDER BY pos
  LIMIT 1
),
stop_grid(n) AS (
  -- End point (pen-up position) as an area on a 4x4 grid.
  SELECT gridpos(a.width, a.height, a.xmin, a.ymin, s.x, s.y)
  FROM   smooth s, aabb a
  ORDER BY pos DESC
  LIMIT 1
),
corner_grid(pos, n) AS (
  -- Corners as areas on a 4x4 grid.
  SELECT c.pos, gridpos(a.width, a.height, a.xmin, a.ymin, c.x, c.y)
  FROM   corner c, aabb a
  WHERE  c.corner  -- TODO move this into corner cte
),
features(center, start, stop, directions, corners, width, height, aspect) AS (
  -- Assemble summary of the extracted features, ready for pattern-matching in
  -- the next step. This single-row table should contain all information
  -- required to identify the character corresponding to the input pen stroke.
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
  FROM   aabb a
),
potential_characters(characters) AS (
  -- TODO nice result formatting ("i think you mean S, however it could also be 5, etc.")
  -- TODO maybe just lookup table with all the features (maybe upper/lower bounds for some of them, also need NULL or something for don't care), then last col => char. if nothing found, not recognized
  SELECT potential_characters
  FROM   features, lookup1
  WHERE  directions[1:4] = first_four_directions
),
character(character) AS (
  SELECT character
  FROM   features f, potential_characters p, lookup2 l
  WHERE  p.characters = l.potential_characters  -- TODO explicit JOIN, rename things
  AND    COALESCE(f.start = l.start, true)
  AND    COALESCE(f.stop = l.stop, true)
  --AND    COALESCE(f.start = f.stop AND f.start = l.start AND l.stop = -1, true)  -- Closed strokes, e.g. O, D, 0
  AND    COALESCE(f.corners = l.corners, true)
  AND    COALESCE(l.aspect_range @> f.aspect :: numeric, true)
),
prettyprint(output) AS (
  SELECT 'Based on the first four cardinal directions of your stroke, I was able to narrow the potential characters down to ' || potential_characters || ', and based on the remaining extracted features, I think it is ' || character || '. How did I do?'
  FROM   potential_characters, character
)

SELECT * FROM character;
