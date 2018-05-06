-- Hand writing recognition.
-- psql -d handwriting -f handwriting.sql -v mouse='[{"x":1, "y":2},{"x":3, "y":4}]'

-- TODO commentary in one big comment parallel/to the right of the code

--\set mouse '[{"x":1, "y":2},{"x":2, "y":4}]'
-- TODO multiply x, y with -1 to match normal math-style diagrams? need to change things up below accordingly
\set mouse '[ { "x": 38, "y": 147 }, { "x": 38, "y": 147 }, { "x": 38, "y": 145 }, { "x": 38, "y": 143 }, { "x": 38, "y": 140 }, { "x": 40, "y": 135 }, { "x": 43, "y": 130 }, { "x": 49, "y": 120 }, { "x": 53, "y": 113 }, { "x": 58, "y": 106 }, { "x": 62, "y": 97 }, { "x": 68, "y": 88 }, { "x": 74, "y": 79 }, { "x": 78, "y": 71 }, { "x": 82, "y": 62 }, { "x": 85, "y": 58 }, { "x": 87, "y": 53 }, { "x": 90, "y": 46 }, { "x": 92, "y": 43 }, { "x": 94, "y": 40 }, { "x": 96, "y": 37 }, { "x": 96, "y": 35 }, { "x": 97, "y": 34 }, { "x": 98, "y": 34 }, { "x": 98, "y": 34 }, { "x": 98, "y": 34 }, { "x": 98, "y": 35 }, { "x": 99, "y": 40 }, { "x": 100, "y": 45 }, { "x": 103, "y": 54 }, { "x": 107, "y": 64 }, { "x": 111, "y": 74 }, { "x": 118, "y": 87 }, { "x": 121, "y": 94 }, { "x": 123, "y": 102 }, { "x": 125, "y": 107 }, { "x": 126, "y": 112 }, { "x": 127, "y": 116 }, { "x": 128, "y": 119 }, { "x": 129, "y": 121 }, { "x": 129, "y": 123 }, { "x": 129, "y": 125 }, { "x": 129, "y": 126 }, { "x": 130, "y": 127 }, { "x": 130, "y": 128 }, { "x": 130, "y": 129 }, { "x": 131, "y": 130 }, { "x": 131, "y": 131 }, { "x": 131, "y": 132 }, { "x": 131, "y": 133 }, { "x": 131, "y": 134 }, { "x": 132, "y": 135 }, { "x": 132, "y": 135 }, { "x": 131, "y": 135 }, { "x": 128, "y": 133 }, { "x": 124, "y": 131 }, { "x": 120, "y": 129 }, { "x": 114, "y": 127 }, { "x": 110, "y": 125 }, { "x": 105, "y": 123 }, { "x": 101, "y": 121 }, { "x": 97, "y": 119 }, { "x": 92, "y": 117 }, { "x": 89, "y": 116 }, { "x": 86, "y": 114 }, { "x": 85, "y": 114 }, { "x": 81, "y": 113 }, { "x": 80, "y": 112 }, { "x": 78, "y": 111 }, { "x": 76, "y": 110 }, { "x": 75, "y": 110 }, { "x": 74, "y": 109 }, { "x": 72, "y": 109 }, { "x": 71, "y": 108 }, { "x": 70, "y": 108 }, { "x": 68, "y": 107 }, { "x": 67, "y": 107 }, { "x": 66, "y": 107 }, { "x": 65, "y": 106 }, { "x": 65, "y": 106 }, { "x": 65, "y": 106 } ]'

--------------------------
-- TOGGLES AND SWITCHES --
--------------------------

-- width and height of canvas
\set width 200
\set height 200

\set smoothingfactor 0.75

-- TODO 10x the essay version, i think
\set thinningsize 5

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
-- TODO 16direction first (self-join, use tan on axis line lengths, get angle, use case to subdivide into 16 dirs), then from that infer 4direction
curve4(pos, x, y, direction) AS ( -- TODO apply to every point or every thinned point?
  -- TODO put the following into a subquery and go from there? or scrap this approach and go with a self-join?
  -- TODO or scrap it and go with a self-written window function f(x,y) that assumes it receives two rows
  --SELECT pos, x, y,
  --       json_agg(x) OVER (ROWS BETWEEN 1 PRECEDING AND 0 FOLLOWING),
  --       json_agg(y) OVER (ROWS BETWEEN 1 PRECEDING AND 0 FOLLOWING)
  --FROM   thin
  -- TODO really need x and y as return values here?
  -- TODO USE THE BLOODY LAG FUNCTION HERE
                                                                        -- div by 22.5 to get 16direction
  --SELECT t1.pos, t1.x, t1.y, (-degrees(atan2(t2.y - t1.y, t2.x - t1.x))/(360/4)) :: int + 2  -- angle you have to go to get from current to next point
  --FROM   thin t1, LATERAL (SELECT t2.pos, t2.x, t2.y
  --                         FROM   thin t2
  --                         WHERE  t2.pos > t1.pos
  --                         ORDER BY t2.pos
  --                         LIMIT 1) AS t2(pos, x, y)
  SELECT pos, x, y, ((-degrees(atan2(y - lag(y) OVER (ORDER BY pos), lag(x) OVER (ORDER BY pos) - x))/(360/4)) :: int + 2) % 4
  FROM   thin
  -- TODO if 4, need to go back to 0 => mod
),
curve4dedup(pos, x, y, direction) AS (
  -- culling of all curve directions that are repeats (ignore first one, it's always pointing up anyway)
  SELECT c1.*, temp.t  -- TODO this should actually be two entries further down
  FROM curve4 c1, LATERAL (SELECT c2.direction, lead(c2.direction) OVER (ORDER BY c2.pos)
                           FROM   curve4 c2
                           WHERE  c2.pos > c1.pos
                           ORDER BY c2.pos
                           LIMIT 1) AS temp(t,s)
  WHERE temp.t <> COALESCE(c1.direction, -1)
  AND   temp.t = temp.s
),
curve16(pos, x, y, direction) AS (
  --SELECT t1.pos, t1.x, t1.y, (-degrees(atan2(t2.y - t1.y, t2.x - t1.x))/(360/16)) :: int
  --FROM   thin t1, LATERAL (SELECT t2.pos, t2.x, t2.y
  --                         FROM   thin t2
  --                         WHERE  t2.pos > t1.pos
  --                         ORDER BY t2.pos
  --                         LIMIT 1) AS t2(pos, x, y)
  -- TODO change to match curve4?
  SELECT pos, x, y, floor(-degrees(atan2(lead(y) OVER (ORDER BY pos) - y, lead(x) OVER (ORDER BY pos) - x))/(360/16)) :: int + 8
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
  -- TODO might use first_value and nth value etc here with something like (ORDER BY m.x ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
),
aabb(xmin, xmax, ymin, ymax, aspect, width, height, centerx, centery) AS (
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
  -- TODO not working yet
  SELECT (floor(4 * (s.x-a.xmin)/a.width) :: int + 1), (floor(4 * (s.y-a.ymin)/a.height) :: int + 1)
  FROM start s, aabb a
),
features(center, start, endd, directions, corners, width, height, aspect) AS (
  -- TODO assemble size and position features as described
  -- TODO curve4, corners, subdivision into 16 rectangles, projection of corners into those, start, end
  -- TODO left, right, upper, lower bounds easily achieved using max/min on unthinned line
  SELECT NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
),
character(x) AS (
  -- TODO table lookup for character recognition
  SELECT NULL
)

SELECT * FROM curve4;
