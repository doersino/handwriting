-- Hand writing recognition.
-- psql -d handwriting -f handwriting.sql -v mouse='[{"x":1, "y":2},{"x":3, "y":4}]'

-- TODO commentary in one big comment parallel/to the right of the code

-- original example
--\set mouse '[{"x":1, "y":2},{"x":2, "y":4}]'

-- A
--\set mouse '[ { "x": 38, "y": 147 }, { "x": 38, "y": 147 }, { "x": 38, "y": 145 }, { "x": 38, "y": 143 }, { "x": 38, "y": 140 }, { "x": 40, "y": 135 }, { "x": 43, "y": 130 }, { "x": 49, "y": 120 }, { "x": 53, "y": 113 }, { "x": 58, "y": 106 }, { "x": 62, "y": 97 }, { "x": 68, "y": 88 }, { "x": 74, "y": 79 }, { "x": 78, "y": 71 }, { "x": 82, "y": 62 }, { "x": 85, "y": 58 }, { "x": 87, "y": 53 }, { "x": 90, "y": 46 }, { "x": 92, "y": 43 }, { "x": 94, "y": 40 }, { "x": 96, "y": 37 }, { "x": 96, "y": 35 }, { "x": 97, "y": 34 }, { "x": 98, "y": 34 }, { "x": 98, "y": 34 }, { "x": 98, "y": 34 }, { "x": 98, "y": 35 }, { "x": 99, "y": 40 }, { "x": 100, "y": 45 }, { "x": 103, "y": 54 }, { "x": 107, "y": 64 }, { "x": 111, "y": 74 }, { "x": 118, "y": 87 }, { "x": 121, "y": 94 }, { "x": 123, "y": 102 }, { "x": 125, "y": 107 }, { "x": 126, "y": 112 }, { "x": 127, "y": 116 }, { "x": 128, "y": 119 }, { "x": 129, "y": 121 }, { "x": 129, "y": 123 }, { "x": 129, "y": 125 }, { "x": 129, "y": 126 }, { "x": 130, "y": 127 }, { "x": 130, "y": 128 }, { "x": 130, "y": 129 }, { "x": 131, "y": 130 }, { "x": 131, "y": 131 }, { "x": 131, "y": 132 }, { "x": 131, "y": 133 }, { "x": 131, "y": 134 }, { "x": 132, "y": 135 }, { "x": 132, "y": 135 }, { "x": 131, "y": 135 }, { "x": 128, "y": 133 }, { "x": 124, "y": 131 }, { "x": 120, "y": 129 }, { "x": 114, "y": 127 }, { "x": 110, "y": 125 }, { "x": 105, "y": 123 }, { "x": 101, "y": 121 }, { "x": 97, "y": 119 }, { "x": 92, "y": 117 }, { "x": 89, "y": 116 }, { "x": 86, "y": 114 }, { "x": 85, "y": 114 }, { "x": 81, "y": 113 }, { "x": 80, "y": 112 }, { "x": 78, "y": 111 }, { "x": 76, "y": 110 }, { "x": 75, "y": 110 }, { "x": 74, "y": 109 }, { "x": 72, "y": 109 }, { "x": 71, "y": 108 }, { "x": 70, "y": 108 }, { "x": 68, "y": 107 }, { "x": 67, "y": 107 }, { "x": 66, "y": 107 }, { "x": 65, "y": 106 }, { "x": 65, "y": 106 }, { "x": 65, "y": 106 } ]'

-- I
--\set mouse '[ { "x": 77, "y": 47 }, { "x": 77, "y": 48 }, { "x": 77, "y": 51 }, { "x": 77, "y": 60 }, { "x": 77, "y": 79 }, { "x": 77, "y": 98 }, { "x": 77, "y": 115 }, { "x": 77, "y": 129 }, { "x": 77, "y": 138 }, { "x": 77, "y": 146 }, { "x": 77, "y": 151 }, { "x": 77, "y": 155 }, { "x": 77, "y": 157 }, { "x": 77, "y": 158 }, { "x": 78, "y": 159 }, { "x": 78, "y": 159 } ]'

-- J
--\set mouse '[ { "x": 102, "y": 42 }, { "x": 102, "y": 42 }, { "x": 102, "y": 43 }, { "x": 102, "y": 45 }, { "x": 102, "y": 55 }, { "x": 102, "y": 64 }, { "x": 102, "y": 76 }, { "x": 102, "y": 87 }, { "x": 102, "y": 96 }, { "x": 102, "y": 103 }, { "x": 102, "y": 109 }, { "x": 101, "y": 115 }, { "x": 100, "y": 121 }, { "x": 99, "y": 126 }, { "x": 97, "y": 131 }, { "x": 96, "y": 136 }, { "x": 95, "y": 139 }, { "x": 91, "y": 144 }, { "x": 87, "y": 146 }, { "x": 84, "y": 147 }, { "x": 80, "y": 148 }, { "x": 74, "y": 148 }, { "x": 71, "y": 145 }, { "x": 68, "y": 139 }, { "x": 66, "y": 133 }, { "x": 64, "y": 127 }, { "x": 63, "y": 121 }, { "x": 63, "y": 117 }, { "x": 63, "y": 115 }, { "x": 63, "y": 113 } ]'

-- testing
\set mouse '[ { "x": 49, "y": 141 }, { "x": 49, "y": 140 }, { "x": 49, "y": 139 }, { "x": 49, "y": 134 }, { "x": 49, "y": 122 }, { "x": 48, "y": 112 }, { "x": 47, "y": 100 }, { "x": 46, "y": 93 }, { "x": 46, "y": 84 }, { "x": 45, "y": 76 }, { "x": 45, "y": 70 }, { "x": 45, "y": 66 }, { "x": 45, "y": 61 }, { "x": 45, "y": 57 }, { "x": 45, "y": 55 }, { "x": 45, "y": 54 }, { "x": 46, "y": 53 }, { "x": 46, "y": 49 }, { "x": 47, "y": 47 }, { "x": 49, "y": 43 }, { "x": 50, "y": 40 }, { "x": 51, "y": 37 }, { "x": 52, "y": 35 }, { "x": 54, "y": 34 }, { "x": 56, "y": 33 }, { "x": 59, "y": 31 }, { "x": 62, "y": 29 }, { "x": 64, "y": 28 }, { "x": 66, "y": 28 }, { "x": 69, "y": 28 }, { "x": 71, "y": 28 }, { "x": 75, "y": 28 }, { "x": 78, "y": 28 }, { "x": 81, "y": 30 }, { "x": 83, "y": 33 }, { "x": 85, "y": 38 }, { "x": 86, "y": 43 }, { "x": 86, "y": 51 }, { "x": 86, "y": 57 }, { "x": 85, "y": 64 }, { "x": 81, "y": 70 }, { "x": 75, "y": 75 }, { "x": 69, "y": 79 }, { "x": 64, "y": 82 }, { "x": 58, "y": 85 }, { "x": 54, "y": 88 }, { "x": 51, "y": 90 }, { "x": 49, "y": 91 }, { "x": 49, "y": 92 }, { "x": 48, "y": 92 }, { "x": 48, "y": 92 }, { "x": 48, "y": 92 }, { "x": 48, "y": 92 }, { "x": 48, "y": 91 }, { "x": 49, "y": 91 }, { "x": 53, "y": 90 }, { "x": 58, "y": 89 }, { "x": 64, "y": 89 }, { "x": 70, "y": 89 }, { "x": 77, "y": 89 }, { "x": 83, "y": 90 }, { "x": 86, "y": 92 }, { "x": 89, "y": 94 }, { "x": 91, "y": 96 }, { "x": 93, "y": 99 }, { "x": 94, "y": 102 }, { "x": 95, "y": 105 }, { "x": 96, "y": 109 }, { "x": 96, "y": 112 }, { "x": 96, "y": 115 }, { "x": 96, "y": 119 }, { "x": 94, "y": 125 }, { "x": 91, "y": 127 }, { "x": 88, "y": 131 }, { "x": 83, "y": 135 }, { "x": 80, "y": 136 }, { "x": 78, "y": 136 }, { "x": 74, "y": 136 }, { "x": 71, "y": 136 }, { "x": 67, "y": 136 }, { "x": 63, "y": 136 }, { "x": 60, "y": 136 }, { "x": 57, "y": 136 }, { "x": 56, "y": 136 }, { "x": 55, "y": 136 } ]'

-- hysteresis zones test
--\set mouse '[ { "x": 46, "y": 162 }, { "x": 46, "y": 161 }, { "x": 47, "y": 161 }, { "x": 47, "y": 161 }, { "x": 47, "y": 161 }, { "x": 47, "y": 161 }, { "x": 48, "y": 161 }, { "x": 48, "y": 161 }, { "x": 48, "y": 161 }, { "x": 48, "y": 161 }, { "x": 48, "y": 160 }, { "x": 48, "y": 160 }, { "x": 49, "y": 160 }, { "x": 49, "y": 160 }, { "x": 49, "y": 160 }, { "x": 49, "y": 160 }, { "x": 50, "y": 160 }, { "x": 50, "y": 160 }, { "x": 50, "y": 160 }, { "x": 50, "y": 160 }, { "x": 51, "y": 160 }, { "x": 51, "y": 160 }, { "x": 51, "y": 159 }, { "x": 51, "y": 159 }, { "x": 51, "y": 159 }, { "x": 52, "y": 159 }, { "x": 52, "y": 158 }, { "x": 52, "y": 158 }, { "x": 53, "y": 158 }, { "x": 53, "y": 158 }, { "x": 53, "y": 158 }, { "x": 53, "y": 158 }, { "x": 53, "y": 157 }, { "x": 53, "y": 157 }, { "x": 53, "y": 157 }, { "x": 53, "y": 157 }, { "x": 53, "y": 156 }, { "x": 53, "y": 156 }, { "x": 53, "y": 156 }, { "x": 53, "y": 155 }, { "x": 53, "y": 155 }, { "x": 53, "y": 154 }, { "x": 53, "y": 154 }, { "x": 53, "y": 153 }, { "x": 53, "y": 153 }, { "x": 53, "y": 153 }, { "x": 53, "y": 152 }, { "x": 53, "y": 152 }, { "x": 54, "y": 152 }, { "x": 54, "y": 152 }, { "x": 56, "y": 151 }, { "x": 58, "y": 150 }, { "x": 58, "y": 150 }, { "x": 59, "y": 150 }, { "x": 59, "y": 150 }, { "x": 60, "y": 150 }, { "x": 60, "y": 150 }, { "x": 60, "y": 150 }, { "x": 60, "y": 149 }, { "x": 60, "y": 149 }, { "x": 61, "y": 149 }, { "x": 61, "y": 149 }, { "x": 61, "y": 149 }, { "x": 61, "y": 149 }, { "x": 61, "y": 149 }, { "x": 61, "y": 148 }, { "x": 61, "y": 148 }, { "x": 61, "y": 148 }, { "x": 60, "y": 148 }, { "x": 60, "y": 147 }, { "x": 60, "y": 147 }, { "x": 60, "y": 147 }, { "x": 60, "y": 147 }, { "x": 60, "y": 147 }, { "x": 60, "y": 146 }, { "x": 60, "y": 146 }, { "x": 60, "y": 146 }, { "x": 60, "y": 146 }, { "x": 60, "y": 145 }, { "x": 61, "y": 145 }, { "x": 62, "y": 144 }, { "x": 63, "y": 143 }, { "x": 64, "y": 143 }, { "x": 64, "y": 143 }, { "x": 64, "y": 142 }, { "x": 64, "y": 142 }, { "x": 65, "y": 142 }, { "x": 66, "y": 140 }, { "x": 67, "y": 140 }, { "x": 67, "y": 139 }, { "x": 68, "y": 139 }, { "x": 68, "y": 139 }, { "x": 68, "y": 138 }, { "x": 69, "y": 138 }, { "x": 69, "y": 138 }, { "x": 69, "y": 137 }, { "x": 69, "y": 137 }, { "x": 69, "y": 137 }, { "x": 69, "y": 137 }, { "x": 69, "y": 136 }, { "x": 69, "y": 136 }, { "x": 70, "y": 136 }, { "x": 70, "y": 136 }, { "x": 70, "y": 136 }, { "x": 71, "y": 135 }, { "x": 71, "y": 135 }, { "x": 71, "y": 135 }, { "x": 71, "y": 135 }, { "x": 71, "y": 134 }, { "x": 72, "y": 134 }, { "x": 73, "y": 133 }, { "x": 74, "y": 132 }, { "x": 75, "y": 131 }, { "x": 76, "y": 131 }, { "x": 76, "y": 131 }, { "x": 77, "y": 131 }, { "x": 77, "y": 130 }, { "x": 77, "y": 130 }, { "x": 77, "y": 129 }, { "x": 77, "y": 128 }, { "x": 78, "y": 127 }, { "x": 78, "y": 126 }, { "x": 79, "y": 126 }, { "x": 79, "y": 125 }, { "x": 79, "y": 125 }, { "x": 79, "y": 125 }, { "x": 81, "y": 125 }, { "x": 82, "y": 125 }, { "x": 83, "y": 125 }, { "x": 83, "y": 125 }, { "x": 84, "y": 125 }, { "x": 84, "y": 125 }, { "x": 84, "y": 125 }, { "x": 84, "y": 125 }, { "x": 85, "y": 124 }, { "x": 85, "y": 124 }, { "x": 85, "y": 124 } ]'

---------------------------------
-- TOGGLES, KNOBS AND SWITCHES --
---------------------------------

-- height of canvas
\set height 201

-- weight of previously smoothed point (0 < n < 1)
\set smoothingfactor 0.75

-- size of thinning box in px, roughly 10x the essay values
\set thinningsize 5

-- minimum angle for a corner to be recognized
\set cornerangle 80

------------------------------
-- BEHOLD, THE MIGHTY QUERY --
------------------------------

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
  SELECT *
  FROM   smooth
  WHERE  pos = 1

    UNION ALL

  SELECT *
  FROM   (  -- subquery cause no order by in recursive part => check again if that's really necessary
    SELECT s.pos, s.x, s.y
    FROM   thin t, smooth s
    WHERE  s.pos > t.pos
    --AND    |/ (s.x - t.x)^2 + (s.y - t.y)^2 >= :'thinningsize'  -- euclidean distance, TODO if using point datatype, could use "<->" infix op
    AND    (abs(s.x - t.x) >= :'thinningsize' OR abs(s.y - t.y) >= :'thinningsize')
    ORDER BY s.pos
    LIMIT 1
  ) AS _
),
curve(pos, x, y, direction) AS (
  SELECT pos, x, y,
         degrees(-atan2(y - lag(y) OVER (ORDER BY pos),
                  lag(x) OVER (ORDER BY pos) - x)
                 ) + 180 -- TODO coalesce so it's pointing up for the first one?
  FROM   thin
),
-- TODO use curve table
curve4(pos, x, y, direction) AS (
  -- TODO custom data type for direction? https://www.postgresql.org/docs/9.1/static/datatype-enum.html and https://stackoverflow.com/questions/1827122/converting-an-integer-to-enum-in-postgresql?noredirect=1&lq=1
  -- TODO do we really need x and y as return values here? no!
  -- TODO in the original memorandum, this is done using a set of inequalities – ask benjamin whether to replicate or not!
  -- order of subtraction reversed between y and x to match drawing
  SELECT pos, x, y,
         ((-(atan2(y - lag(y) OVER (ORDER BY pos),
                   lag(x) OVER (ORDER BY pos) - x)
                  )/(2*pi()/4)) :: int + 4/2) % 4
  FROM   thin
),
curve42(pos, x, y, direction, direction4) AS (
  -- with hysteresis zones, see page 26 of pdf -- worth it? ask benjamin
  SELECT pos, x, y, direction, (direction/90) :: int
  FROM curve
  WHERE pos = 1

    UNION ALL

  SELECT * FROM
    (SELECT c.pos, c.x, c.y,
            CASE
              WHEN abs(c.direction - c42.direction) < 8
              THEN c42.direction
              ELSE c.direction
            END,
            CASE
              WHEN abs(c.direction - c42.direction) < 8
              THEN (c42.direction/90) :: int % 4
              ELSE (c.direction/90) :: int % 4
            END
    FROM curve c, curve42 c42
    WHERE c.pos > c42.pos
    ORDER BY c.pos
    LIMIT 1) AS _
),
curve4dedup(pos, x, y, direction) AS (
  SELECT pos, x, y, direction
  FROM   (SELECT *,
                 COALESCE(lag(direction, 2) OVER win, -1) <> lag(direction) OVER win
                 AND lag(direction) OVER win = direction
          FROM curve4
          WINDOW win AS (ORDER BY pos)) AS _(pos, x, y, direction, isnew)
  WHERE isnew
),
-- TODO use curve table, maybe just emit rounded degrees? would make corner bit simpler
curve16(pos, x, y, direction) AS (
  SELECT pos, x, y,
         ((-(atan2(y - lag(y) OVER (ORDER BY pos),
                   lag(x) OVER (ORDER BY pos) - x)
                  )/(2*pi()/16)) :: int + 16/2) % 16
  FROM   thin
),
corner(pos, x, y, direction, corner) AS (
  -- TODO page 27 or memorandum pdf: a corner is detected whenever the pen moves in the same (+-1!) 16-direction for at least two segments, changes direction by at least 90deg, and then proceeds along the new direction (+-1) for at least two segments, either immediately or through a one-segment turn
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
  -- TODO write two custom aggregates taking five/four values with cardinality/row_number(), returning bool?
),
aabb(xmin, xmax, ymin, ymax, aspect, width, height, centerx, centery) AS (
  -- note that width, height, center not in inches, but in px
  -- TODO ask benjamin if i could use a box here, and later on width etc. also: use point datatype in general?
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
  SELECT x, y
  FROM   smooth
  ORDER BY pos
  LIMIT 1
),
-- TODO rename endd into something non-ridiculous
endd(x, y) AS (
  SELECT x, y
  FROM   smooth
  ORDER BY pos DESC
  LIMIT 1
),
startgrid(n) AS (
  SELECT 15 - ((floor(4 * (s.x-a.xmin)/a.width) :: int) + (floor(4 * (s.y-a.ymin)/a.height) :: int) * 4)
  FROM start s, aabb a

  -- TODO why does following give different result? data types?
  --FROM smooth s, aabb a
  --ORDER BY pos DESC
  --LIMIT 1
  --FROM (VALUES (1,25,25), (2,75,25), (3,25,75), (4,75,75), (5,51,51), (6,111,34)) AS s(pos,x,y),
  --     (VALUES (0, 0, 201, 201)) AS a(xmin, ymin, width, height)
  --ORDER BY s.pos
),
endgrid(n) AS (
  SELECT 15 - ((floor(4 * (e.x-a.xmin)/a.width) :: int) + (floor(4 * (e.y-a.ymin)/a.height) :: int) * 4)
  FROM endd e, aabb a
),
cornergrid(pos, n) AS (
  --SELECT c.pos, (floor(4 * (a.xmax - c.x)/a.width) :: int) + (floor(4 * (a.ymax - c.y)/a.height) :: int) * 4
  SELECT c.pos, 15 - ((floor(4 * (c.x-a.xmin)/a.width) :: int) + (floor(4 * (c.y-a.ymin)/a.height) :: int) * 4)
  FROM corner c, aabb a
  WHERE c.corner
),
features(center, start, endd, directions, corners, width, height, aspect) AS (
  -- TODO assemble size and position features as described
  -- TODO curve4dedup, corners, subdivision into 16 rectangles, projection of corners into those, start, end
  -- TODO left, right, upper, lower bounds easily achieved using max/min on unthinned line
  SELECT point(centerx, centery),
         (TABLE startgrid),
         (TABLE endgrid),
         (SELECT array_agg(c.direction ORDER BY c.pos)
          FROM   curve4dedup c),
         (SELECT array_agg(c.n ORDER BY c.pos)
          FROM   cornergrid c),
         a.width,
         a.height,
         a.aspect
  FROM aabb a
),
possible_characters(character) AS (
  -- TODO nice result formatting ("i think you mean S, however it could also be 5, etc.")
  -- TODO ask benjamin: should i come up with my completely own rules or adapt the ones from essay, maybe with some improvements?
  -- TODO maybe just lookup table with all the features (maybe upper/lower bounds for some of them, also need NULL or something for don't care), then last col => char. if nothing found, not recognized
  SELECT CASE
           WHEN next_step = NULL
           THEN possible_characters
           ELSE possible_characters
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
  WHERE directions[1:4] = first_four_directions
)

SELECT * FROM startgrid;
