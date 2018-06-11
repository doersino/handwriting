-- Hand writing recognition scheme modeled after an interactive essay:
-- https://jackschaedler.github.io/handwriting-recognition/
--
-- Usage:
-- Create a databased "handwriting", use the enclosed HTML file to generate a
-- pen stroke, then run the following on PostgreSQL 10 or newer, replacing the
-- "PEN_STROKE" placeholder with the generated pen stroke:
-- psql -d handwriting -f handwriting.sql -v pen='PEN_STROKE'

-- Original example.
--\set pen '[{"x":1, "y":2},{"x":2, "y":4}]'

-- A.
--\set pen '[ { "x": 37, "y": 31 }, { "x": 37, "y": 31 }, { "x": 37, "y": 34 }, { "x": 37, "y": 39 }, { "x": 38, "y": 43 }, { "x": 41, "y": 57 }, { "x": 44, "y": 66 }, { "x": 48, "y": 76 }, { "x": 52, "y": 86 }, { "x": 54, "y": 92 }, { "x": 56, "y": 96 }, { "x": 58, "y": 99 }, { "x": 59, "y": 101 }, { "x": 59, "y": 102 }, { "x": 60, "y": 102 }, { "x": 60, "y": 102 }, { "x": 60, "y": 101 }, { "x": 60, "y": 98 }, { "x": 61, "y": 90 }, { "x": 64, "y": 80 }, { "x": 65, "y": 73 }, { "x": 67, "y": 66 }, { "x": 69, "y": 60 }, { "x": 71, "y": 52 }, { "x": 72, "y": 49 }, { "x": 72, "y": 46 }, { "x": 73, "y": 44 }, { "x": 74, "y": 42 }, { "x": 74, "y": 41 }, { "x": 74, "y": 40 }, { "x": 74, "y": 40 }, { "x": 74, "y": 39 }, { "x": 74, "y": 39 }, { "x": 74, "y": 39 }, { "x": 74, "y": 39 }, { "x": 74, "y": 39 }, { "x": 74, "y": 39 }, { "x": 72, "y": 40 }, { "x": 67, "y": 43 }, { "x": 63, "y": 45 }, { "x": 60, "y": 47 }, { "x": 58, "y": 49 }, { "x": 56, "y": 50 }, { "x": 54, "y": 52 }, { "x": 52, "y": 52 }, { "x": 51, "y": 53 }, { "x": 50, "y": 54 }, { "x": 50, "y": 54 }, { "x": 50, "y": 54 }, { "x": 49, "y": 54 }, { "x": 49, "y": 54 }, { "x": 49, "y": 54 }, { "x": 49, "y": 54 }, { "x": 49, "y": 55 }, { "x": 49, "y": 55 }, { "x": 49, "y": 55 }, { "x": 48, "y": 55 }, { "x": 48, "y": 55 }, { "x": 48, "y": 55 }, { "x": 47, "y": 56 }, { "x": 46, "y": 56 }, { "x": 46, "y": 56 }, { "x": 46, "y": 56 }, { "x": 46, "y": 56 } ]'

-- S.
--\set pen '[ { "x": 127, "y": 115 }, { "x": 127, "y": 115 }, { "x": 126, "y": 115 }, { "x": 124, "y": 115 }, { "x": 120, "y": 115 }, { "x": 116, "y": 115 }, { "x": 112, "y": 115 }, { "x": 108, "y": 115 }, { "x": 104, "y": 114 }, { "x": 101, "y": 112 }, { "x": 98, "y": 110 }, { "x": 96, "y": 107 }, { "x": 94, "y": 104 }, { "x": 93, "y": 102 }, { "x": 92, "y": 98 }, { "x": 91, "y": 96 }, { "x": 91, "y": 93 }, { "x": 91, "y": 90 }, { "x": 94, "y": 87 }, { "x": 96, "y": 84 }, { "x": 99, "y": 82 }, { "x": 102, "y": 81 }, { "x": 106, "y": 80 }, { "x": 108, "y": 79 }, { "x": 115, "y": 76 }, { "x": 120, "y": 73 }, { "x": 124, "y": 71 }, { "x": 128, "y": 69 }, { "x": 130, "y": 68 }, { "x": 133, "y": 65 }, { "x": 135, "y": 63 }, { "x": 136, "y": 60 }, { "x": 137, "y": 57 }, { "x": 138, "y": 53 }, { "x": 138, "y": 49 }, { "x": 138, "y": 46 }, { "x": 137, "y": 43 }, { "x": 132, "y": 40 }, { "x": 126, "y": 37 }, { "x": 116, "y": 36 }, { "x": 106, "y": 34 }, { "x": 100, "y": 34 }, { "x": 92, "y": 34 }, { "x": 90, "y": 35 }, { "x": 87, "y": 36 } ]'


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

DROP TYPE IF EXISTS cardinal_direction CASCADE;
CREATE TYPE cardinal_direction AS ENUM('▶', '▲', '◀', '▼');

-- Compute absolute difference between two angles (which is trivial in most
-- cases but not when the two angles cross 0, e.g. when alpha = 350 and beta =
-- 10) given in degrees using the formula atan2(sin(a-b), cos(a-b)) as per
-- https://stackoverflow.com/a/2007279.
CREATE OR REPLACE FUNCTION angdiff(alpha double precision,
                                   beta double precision) RETURNS double precision AS $$
BEGIN
  RETURN abs(degrees(atan2(sin(radians(alpha - beta)),
                           cos(radians(alpha - beta)))));
END
$$ LANGUAGE plpgsql;

-- Compute position on 4x4 grid from an (x,y) coordinate pair. Used during
-- assembly of features table.
CREATE OR REPLACE FUNCTION gridpos(width real, height real,
                                   xmin real, ymin real,
                                   x real, y real) RETURNS int AS $$
BEGIN
  RETURN greatest(0,
                  15 - (      (floor(4 * (x-xmin)/(width + 1)) :: int)
                        + 4 * (floor(4 * (y-ymin)/(height + 1)) :: int)));
END
$$ LANGUAGE plpgsql;

-- Initial lookup table: Maps an array of up to four starting directions of a
-- stroke to a set of potential characters. Largely taken from the essay
-- implementation with some minor improvements.
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
  ('{"▼","◀","▶"}',     '{"X"}'),
  ('{"▼","◀","▶","▲"}', '{"X"}'),
  ('{"▼","▶"}',         '{"L"}'),
  ('{"▼","▶","◀"}',     '{"6"}'),
  ('{"▼","▶","◀","▼"}', '{"4"}'),
  ('{"▼","▶","▲"}',     '{"O","U"}'),
  ('{"▼","▶","▲","▼"}', '{"4","Y"}'),
  ('{"▼","▶","▲","◀"}', '{"6","8","O","D","4"}'),
  ('{"▼","▶","▲","▶"}', '{"8"}'),
  ('{"▼","▲"}',         '{"V","U"}'),
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
  ('{"◀","▼","▶","▼"}', '{"5","8","S","E"}'),
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
  ('{"▲"}',             '{"I"}'),
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
  ('{"▲","▶","▼"}',     '{"D"}'),
  ('{"▲","▶","▼","▲"}', '{"M","N","A"}'),
  ('{"▲","◀","▼","▶"}', '{"8","9","C","G","S","6"}'),  -- HERE
  ('{"▲","◀","▶"}',     '{"T"}'),
  ('{"▲","▶","▼","▶"}', '{"2","3","8","B","D","P","R"}'),
  ('{"▲","▶","▼","◀"}', '{"2","3","8","B","D","P","R"}'),
  ('{"▲","▶","◀","▶"}', '{"B"}'),
  ('{"▲","▶"}',         '{"F"}');

-- Final lookup table: Narrows result of initial lookup down based on extracted
-- features. Not taken from the essay implementation.
DROP TABLE IF EXISTS lookup2;
CREATE TABLE lookup2 (
  potential_characters char[],
  character            char,
  start                int,
  stop                 int,
  corners              int[],
  last_direction       cardinal_direction,
  aspect_range         numrange
);
INSERT INTO lookup2(potential_characters, character)
  -- All single-character patterns from initial lookup table.
  SELECT DISTINCT ON (potential_characters[1]) potential_characters,
                                               potential_characters[1]
  FROM   lookup1
  WHERE  array_length(potential_characters, 1) = 1;
INSERT INTO lookup2 VALUES
  ('{"O","J","X","U"}', 'O', 0, 0, NULL, NULL, NULL),
  ('{"O","J","X","U"}', 'O', 1, 1, NULL, NULL, NULL),
  ('{"O","J","X","U"}', 'O', 2, 2, NULL, NULL, NULL),
  ('{"O","J","X","U"}', 'O', 3, 3, NULL, NULL, NULL),
  ('{"O","J","X","U"}', 'J', NULL, 11, NULL, NULL, NULL),
  ('{"O","J","X","U"}', 'J', NULL, 15, NULL, NULL, NULL),
  ('{"O","J","X","U"}', 'X', 3, 0, '{12,15}', NULL, NULL),
  ('{"O","J","X","U"}', 'X', 3, 0, '{12}', NULL, NULL),
  ('{"O","J","X","U"}', 'X', 3, 0, '{15}', NULL, NULL),
  ('{"O","J","X","U"}', 'U', 0, 3, NULL, NULL, NULL),
  ('{"X","O","U"}', 'X', 3, 0, '{12,15}', NULL, NULL),
  ('{"X","O","U"}', 'X', 3, 0, '{12}', NULL, NULL),
  ('{"X","O","U"}', 'X', 3, 0, '{15}', NULL, NULL),
  ('{"X","O","U"}', 'O', 0, 0, NULL, NULL, NULL),
  ('{"X","O","U"}', 'O', 1, 1, NULL, NULL, NULL),
  ('{"X","O","U"}', 'O', 2, 2, NULL, NULL, NULL),
  ('{"X","O","U"}', 'O', 3, 3, NULL, NULL, NULL),
  ('{"X","O","U"}', 'U', 0, 3, NULL, NULL, NULL),
  ('{"O","U"}', 'O', 0, 0, NULL, NULL, NULL),
  ('{"O","U"}', 'O', 1, 1, NULL, NULL, NULL),
  ('{"O","U"}', 'O', 2, 2, NULL, NULL, NULL),
  ('{"O","U"}', 'O', 3, 3, NULL, NULL, NULL),
  ('{"O","U"}', 'U', 3, 0, NULL, NULL, NULL),
  ('{"4","Y"}', '4', NULL, 12, NULL, NULL, NULL),  -- TODO last dir down?
  ('{"4","Y"}', '4', NULL, 13, NULL, NULL, NULL),  -- TODO last dir down?
  ('{"4","Y"}', 'Y', NULL, 14, NULL, NULL, NULL),
  ('{"4","Y"}', 'Y', NULL, 15, NULL, NULL, NULL),
  ('{"4","Y"}', 'Y', NULL, 11, NULL, NULL, NULL),
  ('{"6","8","O","D","4"}', '6', 0, 6, NULL, NULL, NULL),
  ('{"6","8","O","D","4"}', '6', 0, 7, NULL, NULL, NULL),
  ('{"6","8","O","D","4"}', '6', 0, 11, NULL, NULL, NULL),
  ('{"6","8","O","D","4"}', '6', 1, 6, NULL, NULL, NULL),
  ('{"6","8","O","D","4"}', '6', 1, 7, NULL, NULL, NULL),
  ('{"6","8","O","D","4"}', '6', 1, 11, NULL, NULL, NULL),
  ('{"6","8","O","D","4"}', '8', 5, 5, NULL, NULL, NULL),
  ('{"6","8","O","D","4"}', '8', 6, 6, NULL, NULL, NULL),
  ('{"6","8","O","D","4"}', '8', 9, 9, NULL, NULL, NULL),
  ('{"6","8","O","D","4"}', '8', 10, 10, NULL, NULL, NULL),
  ('{"6","8","O","D","4"}', 'O', 0, 0, '{}', NULL, NULL),
  ('{"6","8","O","D","4"}', 'O', 1, 1, NULL, NULL, NULL),
  ('{"6","8","O","D","4"}', 'O', 2, 2, NULL, NULL, NULL),
  ('{"6","8","O","D","4"}', 'O', 3, 3, NULL, NULL, NULL),
  ('{"6","8","O","D","4"}', 'D', 0, 0, '{15}', NULL, NULL),
  ('{"6","8","O","D","4"}', '4', NULL, 12, NULL, NULL, NULL),
  ('{"6","8","O","D","4"}', '4', NULL, 13, NULL, NULL, NULL),
  ('{"V","U"}', 'V', NULL, NULL, '{13}', NULL, NULL),
  ('{"V","U"}', 'V', NULL, NULL, '{14}', NULL, NULL),
  ('{"V","U"}', 'U', NULL, NULL, '{}', NULL, NULL),
  ('{"W","K"}', 'W', NULL, 0, NULL, NULL, NULL),
  ('{"W","K"}', 'K', NULL, 12, NULL, NULL, NULL),
  ('{"E","6"}', 'E', NULL, 12, NULL, NULL, NULL),
  ('{"E","6"}', 'E', NULL, 13, NULL, NULL, NULL),
  ('{"E","6"}', '6', NULL, 6, NULL, NULL, NULL),
  ('{"E","6"}', '6', NULL, 7, NULL, NULL, NULL),
  ('{"E","6"}', '6', NULL, 11, NULL, NULL, NULL),
  ('{"S","8"}', 'S', NULL, 15, NULL, NULL, NULL),
  ('{"S","8"}', 'S', NULL, 14, NULL, NULL, NULL),
  ('{"S","8"}', '8', NULL, 0, NULL, NULL, NULL),
  ('{"S","8"}', '8', NULL, 1, NULL, NULL, NULL),
  ('{"S","8"}', '8', NULL, 2, NULL, NULL, NULL),
  ('{"5","8","S","E"}', '5', 0, NULL, '{3,7}', NULL, NULL),
  ('{"5","8","S","E"}', '5', 0, NULL, '{3,11}', NULL, NULL),
  ('{"5","8","S","E"}', '5', 0, NULL, '{3}', NULL, NULL),
  ('{"5","8","S","E"}', '5', 0, NULL, '{7}', NULL, NULL),
  ('{"5","8","S","E"}', '5', 0, NULL, '{11}', NULL, NULL),
  ('{"5","8","S","E"}', '8', 0, 0, NULL, NULL, NULL),
  ('{"5","8","S","E"}', '8', 1, 1, NULL, NULL, NULL),
  ('{"5","8","S","E"}', '8', 4, 4, NULL, NULL, NULL),
  ('{"5","8","S","E"}', 'S', NULL, 15, NULL, NULL, NULL),
  ('{"5","8","S","E"}', 'S', NULL, 14, NULL, NULL, NULL),
  ('{"5","8","S","E"}', 'E', NULL, 12, NULL, NULL, NULL),
  ('{"5","8","S","E"}', 'E', NULL, 13, NULL, NULL, NULL),
  ('{"6","O","C","G","9"}', '6', 0, 11, '{}', NULL, NULL),
  ('{"6","O","C","G","9"}', '6', 0, 10, '{}', NULL, NULL),
  ('{"6","O","C","G","9"}', 'O', 0, 0, NULL, NULL, NULL),
  ('{"6","O","C","G","9"}', 'O', 1, 1, NULL, NULL, NULL),
  ('{"6","O","C","G","9"}', 'O', 4, 4, NULL, NULL, NULL),
  ('{"6","O","C","G","9"}', 'O', 0, 1, NULL, NULL, NULL),
  ('{"6","O","C","G","9"}', 'O', 1, 0, NULL, NULL, NULL),
  ('{"6","O","C","G","9"}', 'C', 0, 12, NULL, NULL, NULL),
  ('{"6","O","C","G","9"}', 'C', 0, 8, NULL, NULL, NULL),
  ('{"6","O","C","G","9"}', 'C', 4, 8, NULL, NULL, NULL),
  ('{"6","O","C","G","9"}', 'C', 4, 12, NULL, NULL, NULL),
  ('{"6","O","C","G","9"}', 'C', 8, 12, NULL, NULL, NULL),
  ('{"6","O","C","G","9"}', 'G', 0, 9, NULL, NULL, NULL),
  ('{"6","O","C","G","9"}', 'G', 0, 5, NULL, NULL, NULL),
  ('{"9","8","Q"}', '9', 4, 15, NULL, NULL, NULL),
  ('{"9","8","Q"}', '9', 8, 15, NULL, NULL, NULL),
  ('{"9","8","Q"}', '8', 4, 4, NULL, NULL, NULL),
  ('{"9","8","Q"}', '8', 4, 8, NULL, NULL, NULL),
  ('{"9","8","Q"}', '8', 8, 8, NULL, NULL, NULL),
  ('{"9","8","Q"}', '8', 9, 8, NULL, NULL, NULL),
  ('{"9","8","Q"}', '8', 9, 9, NULL, NULL, NULL),
  ('{"9","8","Q"}', 'Q', 13, 12, NULL, NULL, NULL),
  ('{"9","8","Q"}', 'Q', 12, 12, NULL, NULL, NULL),
  ('{"9","8","Q"}', 'Q', 14, 12, NULL, NULL, NULL),
  ('{"9","8","Q"}', 'Q', 14, 13, NULL, NULL, NULL),
  ('{"3","2","Z"}', '3', 3, 15, NULL, NULL, NULL),
  ('{"3","2","Z"}', '3', 3, 14, NULL, NULL, NULL),
  ('{"3","2","Z"}', '2', 3, 12, '{15}', NULL, NULL),
  ('{"3","2","Z"}', '2', 3, 12, '{14}', NULL, NULL),
  ('{"3","2","Z"}', '2', 3, 13, '{15}', NULL, NULL),
  ('{"3","2","Z"}', '2', 3, 13, '{14}', NULL, NULL),
  ('{"3","2","Z"}', '2', 2, 12, '{15}', NULL, NULL),
  ('{"3","2","Z"}', '2', 2, 12, '{14}', NULL, NULL),
  ('{"3","2","Z"}', '2', 2, 13, '{15}', NULL, NULL),
  ('{"3","2","Z"}', '2', 2, 13, '{14}', NULL, NULL),
  ('{"3","2","Z"}', '2', 3, 12, '{15,14}', NULL, NULL),
  ('{"3","2","Z"}', '2', 3, 13, '{15,14}', NULL, NULL),
  ('{"3","2","Z"}', '2', 2, 12, '{15,14}', NULL, NULL),
  ('{"3","2","Z"}', '2', 2, 13, '{15,14}', NULL, NULL),
  ('{"3","2","Z"}', 'Z', NULL, NULL, '{0,15}', NULL, NULL),
  ('{"3","2","Z"}', 'Z', NULL, NULL, '{1,15}', NULL, NULL),
  ('{"3","2","Z"}', 'Z', NULL, NULL, '{0,14}', NULL, NULL),
  ('{"3","2","Z"}', 'Z', NULL, NULL, '{1,14}', NULL, NULL),
  ('{"3","2","Z"}', 'Z', NULL, NULL, '{1,14,13}', NULL, NULL),
  ('{"3","2","Z"}', 'Z', NULL, NULL, '{0,5,15}', NULL, NULL),
  ('{"2","Z"}', '2', NULL, NULL, '{14}', NULL, NULL),
  ('{"2","Z"}', '2', NULL, NULL, '{15}', NULL, NULL),
  ('{"2","Z"}', '2', NULL, NULL, '{15,14}', NULL, NULL),
  ('{"2","Z"}', 'Z', NULL, NULL, '{0,15}', NULL, NULL),
  ('{"2","Z"}', 'Z', NULL, NULL, '{1,15}', NULL, NULL),
  ('{"2","Z"}', 'Z', NULL, NULL, '{0,14}', NULL, NULL),
  ('{"2","Z"}', 'Z', NULL, NULL, '{1,14}', NULL, NULL),
  ('{"2","Z"}', 'Z', NULL, NULL, '{1,14,13}', NULL, NULL),
  ('{"2","Z"}', 'Z', NULL, NULL, '{0,5,15}', NULL, NULL),
  ('{"7","1"}', '7', NULL, NULL, NULL, NULL, numrange(0,1.8)),
  ('{"7","1"}', '1', NULL, NULL, NULL, NULL, numrange(1.8,1000)),
  ('{"7","3"}', '7', NULL, NULL, '{0}', NULL, NULL),
  ('{"7","3"}', '7', NULL, NULL, '{4}', NULL, NULL),
  ('{"7","3"}', '3', NULL, NULL, '{}', NULL, NULL),
  ('{"2","3"}', '2', NULL, 12, NULL, NULL, NULL),
  ('{"2","3"}', '2', NULL, 13, NULL, NULL, NULL),
  ('{"2","3"}', '3', NULL, 14, NULL, NULL, NULL),
  ('{"2","3"}', '3', NULL, 15, NULL, NULL, NULL),
  ('{"O","2","3","U","X"}', 'O', 3, 3, NULL, NULL, NULL),
  ('{"O","2","3","U","X"}', 'O', 2, 2, NULL, NULL, NULL),
  ('{"O","2","3","U","X"}', 'O', 1, 1, NULL, NULL, NULL),
  ('{"O","2","3","U","X"}', '2', NULL, NULL, '{14}', NULL, NULL),
  ('{"O","2","3","U","X"}', '2', NULL, NULL, '{15}', NULL, NULL),
  ('{"O","2","3","U","X"}', '3', 3, 15, NULL, NULL, NULL),
  ('{"O","2","3","U","X"}', '3', 3, 14, NULL, NULL, NULL),
  ('{"O","2","3","U","X"}', 'U', 0, 3, '{}', NULL, NULL),
  ('{"O","2","3","U","X"}', 'X', 0, 3, '{12,15}', NULL, NULL),
  ('{"O","2","3","U","X"}', 'X', 0, 3, '{12}', NULL, NULL),
  ('{"O","2","3","U","X"}', 'X', 0, 3, '{15}', NULL, NULL),
  ('{"1","A"}', '1', NULL, NULL, NULL, NULL, numrange(1.6,1000)),
  ('{"1","A"}', 'A', NULL, NULL, NULL, NULL, numrange(0,1.6)),
  ('{"N","A"}', 'N', NULL, 0, NULL, NULL, NULL),
  ('{"N","A"}', 'N', NULL, 1, NULL, NULL, NULL),
  ('{"N","A"}', 'N', NULL, 4, NULL, NULL, NULL),
  ('{"N","A"}', 'A', NULL, 10, NULL, NULL, NULL),
  ('{"N","A"}', 'A', NULL, 11, NULL, NULL, NULL),
  ('{"N","A"}', 'A', NULL, 6, NULL, NULL, NULL),
  ('{"N","A"}', 'A', NULL, 7, NULL, NULL, NULL),
  ('{"N","A"}', 'A', NULL, 9, NULL, NULL, NULL),
  ('{"M","N"}', 'M', NULL, 12, NULL, NULL, NULL),
  ('{"M","N"}', 'N', NULL, 0, NULL, NULL, NULL),
  ('{"M","N"}', 'N', NULL, 1, NULL, NULL, NULL),
  ('{"M","N","A"}', 'M', NULL, 12, NULL, NULL, NULL),
  ('{"M","N","A"}', 'N', NULL, 0, NULL, NULL, NULL),
  ('{"M","N","A"}', 'N', NULL, 1, NULL, NULL, NULL),
  ('{"M","N","A"}', 'A', NULL, 10, NULL, NULL, NULL),
  ('{"M","N","A"}', 'A', NULL, 6, NULL, NULL, NULL),
  ('{"M","N","A"}', 'A', NULL, 7, NULL, NULL, NULL),
  ('{"M","N","A"}', 'A', NULL, 9, NULL, NULL, NULL),




  ('{}', 'N', NULL, 0, NULL, NULL, NULL),

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
--  -- between two values for an around-45-degree stroke. Outdated.
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
                   angdiff(lag(direction) OVER win, lag(direction, 2) OVER win) <= 22.5
                   AND angdiff(lead(direction) OVER win, lead(direction, 2) OVER win) <= 22.5
                   AND angdiff(lag(direction) OVER win, lead(direction) OVER win)
                       > :cornerangle
                 ) OR (  -- One-segment turn OR immediate direction change.
                   angdiff(direction, lag(direction) OVER win) <= 22.5
                   AND angdiff(lead(direction) OVER win, lead(direction, 2) OVER win) <= 22.5
                   AND angdiff(direction, lead(direction) OVER win)
                       > :cornerangle
                 ) AS is_corner
          FROM   curve
          WINDOW win AS (ORDER BY pos)) AS _(pos, x, y, is_corner)
  WHERE  is_corner
),
--corner_hysteresis(pos, x, y, corner) AS (
--  -- Same as above, but utilizing a different approach and allowing slight
--  -- differences in the directions of each pair of pre- and post-corner
--  -- segments. Outdated.
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
  -- End point (pen-up position) as an area on a 4x4 grid.
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
potential_characters(potential_characters) AS (  -- TODO rename to "candidates"?
  -- Consult first lookup table, yielding one or more potential character
  -- matching the first four cardinal directions of the pen stroke.
  SELECT potential_characters
  FROM   features, lookup1
  WHERE  directions[1:4] = first_four_directions
),
character(character) AS (
  -- Narrow list of potential characters down to just one.
  SELECT character
  FROM   features f, potential_characters p, lookup2 l
  WHERE  p.potential_characters = l.potential_characters  -- TODO explicit JOIN? rename things?
  AND    COALESCE(f.start = l.start, true)
  AND    COALESCE(f.stop = l.stop, true)
  AND    COALESCE(f.corners = l.corners, true)
  AND    COALESCE(f.directions[array_length(f.directions, 1)] = l.last_direction, true)
  AND    COALESCE(l.aspect_range @> f.aspect :: numeric, true)
),
debug(output) AS (
  -- Ugh, figuring out how to properly add double quotes around array elements
  -- in the tuple output took ages.
  SELECT (TABLE potential_characters) AS potential_characters,
         (SELECT array_agg(character) FROM character) AS character,  -- TODO remove array_agg
         *,
         '(''{' || (SELECT string_agg(quote_ident(unnest :: text), ',' ORDER BY ordinality)
                    FROM potential_characters, unnest(potential_characters) WITH ORDINALITY)
                || '}'', '''
                || COALESCE((SELECT character FROM character), '?') :: text
                || ''', '
                || start
                || ', '
                || stop
                || ', '
                || ''''
                || corners :: text
                || ''', '''
                || directions[array_length(directions, 1)]
                || ''', numrange('
                || aspect
                || ','
                || aspect
                || '))'   AS tuple
  FROM features
)
TABLE debug;

-- Here be dragons.
