-- Hand writing recognition scheme modeled after an interactive essay:
-- https://jackschaedler.github.io/handwriting-recognition/
--
-- Setup:
-- Create a databased "handwriting". Run the setup script:
-- $ psql -d handwriting -f handwriting_setup.sql
--
-- Usage:
-- Now use the enclosed HTML file to generate a pen stroke, then run the
-- following (on PostgreSQL 10 or newer), replacing the "PEN_STROKE" placeholder
-- with the generated pen stroke:
-- $ psql -d handwriting -f handwriting.sql -v pen='PEN_STROKE'
--
-- Example (the letter A):
--\set pen '[ { "x": 37, "y": 31 }, { "x": 37, "y": 31 }, { "x": 37, "y": 34 }, { "x": 37, "y": 39 }, { "x": 38, "y": 43 }, { "x": 41, "y": 57 }, { "x": 44, "y": 66 }, { "x": 48, "y": 76 }, { "x": 52, "y": 86 }, { "x": 54, "y": 92 }, { "x": 56, "y": 96 }, { "x": 58, "y": 99 }, { "x": 59, "y": 101 }, { "x": 59, "y": 102 }, { "x": 60, "y": 102 }, { "x": 60, "y": 102 }, { "x": 60, "y": 101 }, { "x": 60, "y": 98 }, { "x": 61, "y": 90 }, { "x": 64, "y": 80 }, { "x": 65, "y": 73 }, { "x": 67, "y": 66 }, { "x": 69, "y": 60 }, { "x": 71, "y": 52 }, { "x": 72, "y": 49 }, { "x": 72, "y": 46 }, { "x": 73, "y": 44 }, { "x": 74, "y": 42 }, { "x": 74, "y": 41 }, { "x": 74, "y": 40 }, { "x": 74, "y": 40 }, { "x": 74, "y": 39 }, { "x": 74, "y": 39 }, { "x": 74, "y": 39 }, { "x": 74, "y": 39 }, { "x": 74, "y": 39 }, { "x": 74, "y": 39 }, { "x": 72, "y": 40 }, { "x": 67, "y": 43 }, { "x": 63, "y": 45 }, { "x": 60, "y": 47 }, { "x": 58, "y": 49 }, { "x": 56, "y": 50 }, { "x": 54, "y": 52 }, { "x": 52, "y": 52 }, { "x": 51, "y": 53 }, { "x": 50, "y": 54 }, { "x": 50, "y": 54 }, { "x": 50, "y": 54 }, { "x": 49, "y": 54 }, { "x": 49, "y": 54 }, { "x": 49, "y": 54 }, { "x": 49, "y": 54 }, { "x": 49, "y": 55 }, { "x": 49, "y": 55 }, { "x": 49, "y": 55 }, { "x": 48, "y": 55 }, { "x": 48, "y": 55 }, { "x": 48, "y": 55 }, { "x": 47, "y": 56 }, { "x": 46, "y": 56 }, { "x": 46, "y": 56 }, { "x": 46, "y": 56 }, { "x": 46, "y": 56 } ]'


---------------------------------
-- TOGGLES, KNOBS AND SWITCHES --
---------------------------------

-- Weight of previously smoothed point (0 < n < 1).
\set smoothingfactor 0.75

-- Size of thinning box in px (roughly 10x the essay values).
\set thinningsize 5

-- Minimum angle for a corner to be recognized.
\set cornerangle 90

-- Ask psql to put on some makeup.
\timing on
\pset border 2


----------------------------------------
-- TYPES, FUNCTIONS AND LOOKUP TABLES --
----------------------------------------

-- Include setup file.
--\i 'handwriting_setup.sql'


---------------------------------------------------------------
-- ONE QUERY TO RULE THEM ALL, ONE QUERY TO FIND THEM, --------
-- ONE QUERY TO BRING THEM ALL AND IN THE DARKNESS BIND THEM --
---------------------------------------------------------------

--EXPLAIN ANALYZE
WITH RECURSIVE
tablet(pos, x, y) AS (
  -- Initial step: Convert JSON data into tabular representation of pen stroke.
  -- It would be kinda cool to use the built-in path type here (and line/point/
  -- box types throughout the rest of the query), but seems like there's no way
  -- to extract a path's constituent points (apart from parsing them from a
  -- textual representation, which seems silly), making it pretty useless here.
  SELECT ordinality AS pos, x, y
  FROM   ROWS FROM(jsonb_to_recordset(:'pen') AS (x int, y int)) WITH ORDINALITY
),
smooth(pos, x, y) AS (
  -- Smooth pen stroke to remove quantization jitter. Return reals because the
  -- more idiomatic numeric type will feature unnecessarily many decimal places
  -- after a few iterations.
  SELECT pos, x :: real, y :: real
  FROM   tablet
  WHERE  pos = 1

    UNION ALL

  SELECT t.pos,
         (:smoothingfactor * s.x + (1.0 - :smoothingfactor) * t.x) :: real AS x,
         (:smoothingfactor * s.y + (1.0 - :smoothingfactor) * t.y) :: real AS y
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
  FROM   (  -- ORDER BY being illegal in the recursive part of a WITH RECURSIVE
            -- necessitates this ugly subquery hack.
    SELECT s.pos, s.x, s.y
    FROM   thin t, smooth s
    WHERE  s.pos > t.pos
    AND    :thinningsize < |/ (s.x - t.x)^2 + (s.y - t.y)^2
    -- Alternative, closer to the original specification, but less ideal: square
    -- instead of circle, pruning too many points for diagonal strokes.
    --AND    (abs(s.x - t.x) >= :thinningsize OR abs(s.y - t.y) >= :thinningsize)
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
  SELECT pos,
         (enum_range(NULL :: cardinal_direction))[(direction / 90) :: int % 4 + 1]
  FROM   curve
),
--cardinal_hysteresis(pos, actual_direction, direction) AS (
--  -- Same as above, but featuring so-called hysteresis zones with a width of 8
--  -- degrees which keep the emitted cardinal direction from switching around
--  -- between two values for an around-45-degree stroke. Outdated, needs minor
--  -- adjustments before use.
--  SELECT pos, direction, (enum_range(NULL :: cardinal_direction))[(direction / 90) :: int % 4 + 1]
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
--              END) / 90) :: int % 4 + 1]
--     FROM   curve c, cardinal_hysteresis c42
--     WHERE  c.pos > c42.pos
--     ORDER BY c.pos
--     LIMIT 1) AS _
--),
cardinal_change(pos, direction) AS (
  -- Only keep changes (meaning a new direction that occurs at least twice in
  -- succession) of the cardinal direction.
  SELECT pos, direction
  FROM   (SELECT pos, direction,
                 COALESCE(lag(direction, 2) OVER win <> lag(direction) OVER win,
                          true)  -- Prevent NULLs from escaping this term.
                 AND lag(direction) OVER win = direction
          FROM cardinal
          WINDOW win AS (ORDER BY pos)) AS _(pos, direction, is_new)
  WHERE  is_new
),
corner(pos, x, y) AS (
  -- Detect corners: between two segments going in the same direction and two
  -- segments going into a wildly different direction, with an optional in-
  -- between "turn" segment with an arbitrary direction.
  SELECT pos, x, y
  FROM   (SELECT pos, x, y, (
                   angdiff(lag(direction) OVER win, direction) < 22.5
                   AND angdiff(direction, lead(direction) OVER win) > :cornerangle
                   AND angdiff(lead(direction) OVER win, lead(direction, 2) OVER win) < 22.5
                 ) OR (  -- Immediate direction change OR one-segment turn.
                   angdiff(lag(direction, 2) OVER win, lag(direction) OVER win) < 22.5
                   AND angdiff(lag(direction) OVER win, lead(direction) OVER win) > :cornerangle
                   AND angdiff(lead(direction) OVER win, lead(direction, 2) OVER win) < 22.5
                 ) AS is_corner
          FROM   curve
          WINDOW win AS (ORDER BY pos)) AS _(pos, x, y, is_corner)
  WHERE  is_corner
),
--corner_hysteresis(pos, x, y, corner) AS (
--  -- Same as above, but utilizing a different approach and allowing slight
--  -- differences in the directions of each pair of pre- and post-corner
--  -- segments. Outdated, needs minor adjustments before use.
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
         (max(y) - min(y)) / greatest(1, (max(x) - min(x))),  -- Prevent n/0.
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
  -- End point (pen-up position) as an area on a 4x4 grid. Called "stop"
  -- throughout this query because "end" is a reserved keyword.
  SELECT gridpos(a.width, a.height, a.xmin, a.ymin, s.x, s.y)
  FROM   smooth s, aabb a
  ORDER BY pos DESC
  LIMIT 1
),
corner_grid(pos, n) AS (
  -- Corners as areas on a 4x4 grid. Use DISTINCT to get rid of sequential
  -- duplicates that arise due to the two OR'd corner conditions (one-segment
  -- turn OR immediate direction change). This also gets rid of non-sequential
  -- duplicates, but that didn't turn out to be an issue, so I saw no need to
  -- implement a conceptually-cleaner-but-more-verbose approach.
  SELECT DISTINCT ON (gridpos)
         c.pos, gridpos(a.width, a.height, a.xmin, a.ymin, c.x, c.y)
  FROM   corner c, aabb a
),
features(directions, start, stop, corners, width, height, aspect, center) AS (
  -- Assemble summary of the extracted features, ready for pattern-matching in
  -- the next step. This single-row table should contain all information
  -- required to identify the character corresponding to the input pen stroke.
  -- In truth, not all features (width, height, center) are all that useful when
  -- it comes to recognizing capital characters, but extracting them here
  -- doesn't cost much and allows for future expansion.
  SELECT (SELECT array_agg(c.direction ORDER BY c.pos)
          FROM   cardinal_change c),
         (TABLE start_grid),
         (TABLE stop_grid),
         (SELECT COALESCE(array_agg(c.n ORDER BY c.pos), '{}')
          FROM   corner_grid c),
         a.width,
         a.height,
         a.aspect,
         point(centerx, centery)
  FROM   aabb a
),
candidate_characters(candidate_character) AS (
  -- Consult first lookup table, yielding one or more potential character
  -- matching the first four cardinal directions of the pen stroke.
  SELECT candidate_character
  FROM   features, lookup1
  WHERE  directions[1:4] = first_four_directions
),
characters(character, features_used) AS (
  SELECT character, (  CASE WHEN l.start          IS NULL THEN 0 ELSE 1 END
                     + CASE WHEN l.stop           IS NULL THEN 0 ELSE 1 END
                     + CASE WHEN l.corners        IS NULL THEN 0 ELSE 1 END
                     + CASE WHEN l.last_direction IS NULL THEN 0 ELSE 1 END
                     + CASE WHEN l.aspect_range   IS NULL THEN 0 ELSE 1 END) AS features_used
  FROM   features f, candidate_characters p, lookup2 l
  WHERE  p.candidate_character = l.character
  --AND    COALESCE(f.start = l.start,                                              true)
  --AND    COALESCE(f.stop = l.stop,                                                true)
  --AND    COALESCE(f.corners = l.corners,                                          true)
  --AND    COALESCE(f.directions[array_length(f.directions, 1)] = l.last_direction, true)
  --AND    COALESCE(l.aspect_range @> f.aspect :: numeric,                          true)
  AND    (l.start IS NULL          OR f.start = l.start)
  AND    (l.stop IS NULL           OR f.stop = l.stop)
  AND    (l.corners IS NULL        OR f.corners = l.corners)
  AND    (l.last_direction IS NULL OR f.directions[array_length(f.directions, 1)] = l.last_direction)
  AND    (l.aspect_range IS NULL   OR l.aspect_range @> f.aspect :: numeric)
),
character(character) AS (
  -- Narrow list of potential characters down to just one.
  SELECT character
  FROM characters c
  ORDER BY (SELECT COUNT(*) FROM characters d WHERE d.character = c.character) DESC,
           features_used DESC,
           character
  LIMIT 1
)--,
--debug AS (
--  -- Ugh, figuring out how to properly add double quotes around array elements
--  -- in the tuple output took way too long.
--  SELECT (TABLE candidate_characters) AS candidate_characters,
--         (SELECT character FROM character) AS character,
--         *,
--         '(''{' || (SELECT string_agg(quote_ident(unnest :: text), ',' ORDER BY ordinality)
--                    FROM candidate_characters, unnest(candidate_characters) WITH ORDINALITY)
--                || '}'', '''
--                || COALESCE((SELECT character FROM character), '?') :: text
--                || ''', '
--                || start
--                || ', '
--                || stop
--                || ', '
--                || ''''
--                || corners :: text
--                || ''', '''
--                || directions[array_length(directions, 1)]
--                || ''', numrange('
--                || aspect
--                || ','
--                || aspect
--                || '))'   AS tuple
--  FROM features
--),
--prettyprint AS (
--  -- Not actually very pretty.
--  SELECT candidate_characters, COALESCE(character, '?') AS character
--  FROM candidate_characters, character
--)
TABLE character;



-- Here be dragons.
