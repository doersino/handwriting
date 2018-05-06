-- Hand writing recognition.
-- psql -d handwriting -f handwriting.sql -v mouse='[{"x":1, "y":2},{"x":3, "y":4}]'

-- TODO commentary in one big comment parallel/to the right of the code

--\set mouse '[{"x":1, "y":2},{"x":2, "y":4}]'
-- TODO multiply x, y with -1 to match normal math-style diagrams? need to change things up below accordingly
\set mouse '[ { "x": 38, "y": 147 }, { "x": 38, "y": 147 }, { "x": 38, "y": 145 }, { "x": 38, "y": 143 }, { "x": 38, "y": 140 }, { "x": 40, "y": 135 }, { "x": 43, "y": 130 }, { "x": 49, "y": 120 }, { "x": 53, "y": 113 }, { "x": 58, "y": 106 }, { "x": 62, "y": 97 }, { "x": 68, "y": 88 }, { "x": 74, "y": 79 }, { "x": 78, "y": 71 }, { "x": 82, "y": 62 }, { "x": 85, "y": 58 }, { "x": 87, "y": 53 }, { "x": 90, "y": 46 }, { "x": 92, "y": 43 }, { "x": 94, "y": 40 }, { "x": 96, "y": 37 }, { "x": 96, "y": 35 }, { "x": 97, "y": 34 }, { "x": 98, "y": 34 }, { "x": 98, "y": 34 }, { "x": 98, "y": 34 }, { "x": 98, "y": 35 }, { "x": 99, "y": 40 }, { "x": 100, "y": 45 }, { "x": 103, "y": 54 }, { "x": 107, "y": 64 }, { "x": 111, "y": 74 }, { "x": 118, "y": 87 }, { "x": 121, "y": 94 }, { "x": 123, "y": 102 }, { "x": 125, "y": 107 }, { "x": 126, "y": 112 }, { "x": 127, "y": 116 }, { "x": 128, "y": 119 }, { "x": 129, "y": 121 }, { "x": 129, "y": 123 }, { "x": 129, "y": 125 }, { "x": 129, "y": 126 }, { "x": 130, "y": 127 }, { "x": 130, "y": 128 }, { "x": 130, "y": 129 }, { "x": 131, "y": 130 }, { "x": 131, "y": 131 }, { "x": 131, "y": 132 }, { "x": 131, "y": 133 }, { "x": 131, "y": 134 }, { "x": 132, "y": 135 }, { "x": 132, "y": 135 }, { "x": 131, "y": 135 }, { "x": 128, "y": 133 }, { "x": 124, "y": 131 }, { "x": 120, "y": 129 }, { "x": 114, "y": 127 }, { "x": 110, "y": 125 }, { "x": 105, "y": 123 }, { "x": 101, "y": 121 }, { "x": 97, "y": 119 }, { "x": 92, "y": 117 }, { "x": 89, "y": 116 }, { "x": 86, "y": 114 }, { "x": 85, "y": 114 }, { "x": 81, "y": 113 }, { "x": 80, "y": 112 }, { "x": 78, "y": 111 }, { "x": 76, "y": 110 }, { "x": 75, "y": 110 }, { "x": 74, "y": 109 }, { "x": 72, "y": 109 }, { "x": 71, "y": 108 }, { "x": 70, "y": 108 }, { "x": 68, "y": 107 }, { "x": 67, "y": 107 }, { "x": 66, "y": 107 }, { "x": 65, "y": 106 }, { "x": 65, "y": 106 }, { "x": 65, "y": 106 } ]'

---------------------------------
-- TOGGLES, KNOBS AND SWITCHES --
---------------------------------

-- width and height of canvas
\set width 201
\set height 201

-- weight of previously smoothed point (0 < n < 1)
\set smoothingfactor 0.75

-- roughly 10x the essay values
\set thinningsize 5

-- minimum angle for a corner to be recognized
\set cornerangle 80

-----------
-- QUERY --
-----------

-- Tabular representation (pos|x|y) of mouse stroke
WITH RECURSIVE
tablet(pos, x, y) AS (
  SELECT ordinality AS pos, x, :'height' - y  -- move origin from top left to bottom left
  FROM   ROWS FROM(jsonb_to_recordset(:'mouse') AS (x int, y int))
         WITH ORDINALITY
),
smooth(pos, x, y) AS (
  SELECT pos, x :: double precision, y :: double precision  -- because numeric leads to unnecessarily many decimal places
  FROM   tablet
  WHERE  pos = 1

    UNION ALL

  SELECT t.pos,
         :'smoothingfactor' * s.x + (1.0 - :'smoothingfactor') * t.x AS x,
         :'smoothingfactor' * s.y + (1.0 - :'smoothingfactor') * t.y AS y
  FROM   smooth s, tablet t
  WHERE  t.pos = s.pos + 1
),
thin(pos, x, y) AS (
  SELECT pos, x, y
  FROM   smooth
  WHERE  pos = 1

    UNION ALL

  -- TODO retry: recursively access the most recent thinned point while windowing from that pos to end in smooth and selecting the first one not in square (or circle) (i.e. everything outside square, sorted/with ordinality and order by, limit 1,,, or just min pos?)
  SELECT pos, x, y
  FROM   (  -- TODO subquery cause no order by in recursive part => check again if that's really necessary
    SELECT s.pos, s.x, s.y
    FROM   thin t, smooth s
    WHERE  s.pos > t.pos
    AND    abs(s.x - t.x) >= :'thinningsize'
    AND    abs(s.y - t.y) >= :'thinningsize'
    ORDER BY s.pos  -- TODO or, instead of order by limit: min(s.pos) in select
    LIMIT 1
  ) AS temp -- TODO note that from here, pos has gaps
),
curve4(pos, x, y, direction) AS (
  -- TODO do we really need x and y as return values here?
  -- order of subtraction reversed between y and x to match drawing
  -- TODO below line should be a function?
  SELECT pos, x, y, ((-degrees(atan2(y - lag(y) OVER (ORDER BY pos), lag(x) OVER (ORDER BY pos) - x))/(360/4)) :: int + 2) % 4
  FROM   thin
),
curve4dedup(pos, x, y, direction) AS (
  -- culling of all curve directions that are repeats (ignore first one, it's always pointing up anyway)
  -- TODO make nicer
  SELECT c1.*, nexts.next  -- TODO this should actually be two entries further down
  FROM curve4 c1, LATERAL (SELECT c2.direction, lead(c2.direction) OVER (ORDER BY c2.pos)
                           FROM   curve4 c2
                           WHERE  c2.pos > c1.pos
                           ORDER BY c2.pos
                           LIMIT 1) AS nexts(next,afternext)
  WHERE nexts.next <> COALESCE(c1.direction, -1)
  AND   nexts.next = nexts.afternext
),
curve4dedup2(pos, x, y, direction) AS (
  SELECT pos, x, y, direction
  FROM   (SELECT *, COALESCE(lag(direction, 2) OVER win, -1) <> lag(direction) OVER win AND lag(direction) OVER win = direction
          FROM curve4
          WINDOW win AS (ORDER BY pos)) AS dedup(pos, x, y, direction, nodup)
  WHERE nodup
),
curve16(pos, x, y, direction) AS (
  -- TODO do we really need x and y as return values here?
  SELECT pos, x, y, ((-degrees(atan2(y - lag(y) OVER (ORDER BY pos), lag(x) OVER (ORDER BY pos) - x))/(360/16)) :: int + 8) % 16
  FROM   thin
),
corner(pos, x, y, direction, corner) AS (
  SELECT pos, x, y, direction,
         CASE
           WHEN lag(direction) OVER win = lag(direction, 2) OVER win -- one-segment turn
            AND lead(direction) OVER win = lead(direction, 2) OVER win
            AND abs(lag(direction) OVER win - lead(direction) OVER win) > :cornerangle / 16
           THEN true
           WHEN direction = lag(direction) OVER win  -- immediate direction change
            AND lead(direction) OVER win = lead(direction, 2) OVER win
            AND abs(direction - lead(direction) OVER win) > :cornerangle / 16
           THEN true
          ELSE false END
  FROM   curve16
  WINDOW win AS (ORDER BY pos)
  -- TODO might use first_value and nth value etc here with something like (ORDER BY m.x ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING), use case when 5/4 = count(*) over window to handle edge cases
  -- TODO don't really need to return anything but pos here
  -- TODO write two custom aggregates taking five/four values with cardinality/row_number(), returning bool
),
aabb(xmin, xmax, ymin, ymax, aspect, width, height, centerx, centery) AS (
  -- note that width, height, center not in inches, but in px
  SELECT min(x),
         max(x),
         min(y),
         max(y),
         (max(y)-min(y)) / (max(x)-min(x)),
         max(x)-min(x),
         max(y)-min(y),
         min(x)+(max(x)-min(x))/2,
         min(y)+(max(y)-min(y))/2
  FROM smooth
),
start(x, y) AS (
  SELECT x, y  -- TODO self-join here with order by pos1 desc, pos2 asc to do both in one query?
  FROM   smooth
  ORDER BY pos
  LIMIT 1
),
endd(x, y) AS (
  SELECT x, y
  FROM   smooth
  ORDER BY pos DESC
  LIMIT 1
),
startgrid(n) AS (
  -- TODO below line should be a function?
  SELECT (floor(4 * (s.x-a.xmin)/a.width) :: int) + (floor(4 * (s.y-a.ymin)/a.height) :: int) * 4
  FROM start s, aabb a
  --FROM (VALUES (1,25,25), (2,75,25), (3,25,75), (4,75,75), (5,51,51), (6,111,34)) AS s(pos,x,y),
  --     (VALUES (0, 0, 201, 201)) AS a(xmin, ymin, width, height)
  --ORDER BY s.pos
),
endgrid(n) AS (
  SELECT (floor(4 * (e.x-a.xmin)/a.width) :: int) + (floor(4 * (e.y-a.ymin)/a.height) :: int) * 4
  FROM endd e, aabb a
),
cornergrid(n) AS (
  SELECT (floor(4 * (c.x-a.xmin)/a.width) :: int) + (floor(4 * (c.y-a.ymin)/a.height) :: int) * 4
  FROM corner c, aabb a
  WHERE c.corner
),
features(center, start, endd, directions, corners, width, height, aspect) AS (
  -- TODO assemble size and position features as described
  -- TODO curve4, corners, subdivision into 16 rectangles, projection of corners into those, start, end
  -- TODO left, right, upper, lower bounds easily achieved using max/min on unthinned line
  SELECT NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
),
character(x) AS (
  -- TODO table (schema: direction, possible_chars) lookup for character recognition
  -- TODO nice result formatting ("i think you mean S, however it could also be 5, etc.")
  SELECT NULL
)

SELECT * FROM curve4dedup2;
