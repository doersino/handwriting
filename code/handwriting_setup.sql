-- The four cardinal directions.
DROP TYPE IF EXISTS cardinal_direction CASCADE;
CREATE TYPE cardinal_direction AS ENUM('▶', '▲', '◀', '▼');

-- Compute absolute difference between two angles (which is trivial in most
-- cases but not when the two angles cross 0, e.g. when alpha = 350 and beta =
-- 10) given in degrees using the formula atan2(sin(a-b), cos(a-b)) as per
-- https://stackoverflow.com/a/2007279.
DROP FUNCTION IF EXISTS angdiff;
CREATE OR REPLACE FUNCTION angdiff(alpha double precision,
                                   beta double precision) RETURNS real AS $$
  SELECT abs(degrees(atan2(sin(radians(alpha - beta)),
                           cos(radians(alpha - beta))))) :: real;
$$ LANGUAGE SQL IMMUTABLE;

-- Compute position on 4x4 grid from an (x,y) coordinate pair. Used during
-- assembly of features table.
DROP FUNCTION IF EXISTS gridpos;
CREATE OR REPLACE FUNCTION gridpos(width real, height real,
                                   xmin real, ymin real,
                                   x real, y real) RETURNS int AS $$
  SELECT greatest(0,
                  15 - (      (floor(4 * (x - xmin) / (width  + 1)) :: int)
                        + 4 * (floor(4 * (y - ymin) / (height + 1)) :: int)));
$$ LANGUAGE SQL IMMUTABLE;

-- Initial lookup table: Maps an array of up to four starting directions of a
-- stroke to a set of potential characters. Largely taken from the essay
-- implementation with some minor improvements.
DROP TABLE IF EXISTS lookup1;
CREATE TABLE lookup1 (
  first_four_directions cardinal_direction[],
  candidate_characters  char[]
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
  ('{"◀","▶","▼"}',     '{"T"}'),
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
  ('{"▲","▼","◀","▲"}', '{"A"}'),
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
  ('{"▲","◀","▼","▶"}', '{"8","9","C","G","S","6"}'),
  ('{"▲","◀","▶"}',     '{"T"}'),
  ('{"▲","▶","▼","▶"}', '{"2","3","8","B","D","P","R"}'),
  ('{"▲","▶","▼","◀"}', '{"2","3","8","B","D","P","R"}'),
  ('{"▲","▶","◀","▶"}', '{"B"}'),
  ('{"▲","▶"}',         '{"F"}'),
  ('{"▲","▶","◀"}',     '{"D"}'),
  ('{"▲","▶","◀","▲"}', '{"F"}');

-- Final lookup table: Narrows result of initial lookup down based on extracted
-- features. Not taken from the essay implementation.
DROP TABLE IF EXISTS lookup2;
CREATE TABLE lookup2 (
  candidate_characters char[],
  character            char,
  start                int,
  stop                 int,
  corners              int[],
  last_direction       cardinal_direction,
  aspect_range         numrange
);
INSERT INTO lookup2(candidate_characters, character)
  -- All single-character patterns from initial lookup table.
  SELECT DISTINCT ON (candidate_characters[1]) candidate_characters,
                                               candidate_characters[1]
  FROM   lookup1
  WHERE  array_length(candidate_characters, 1) = 1;
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
  ('{"O","U"}', 'U', 3, 4, NULL, NULL, NULL),
  ('{"O","U"}', 'U', 7, 0, NULL, NULL, NULL),
  ('{"4","Y"}', '4', NULL, 12, NULL, NULL, NULL),
  ('{"4","Y"}', '4', NULL, 13, NULL, NULL, NULL),
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
  ('{"V","U"}', 'V', NULL, NULL, '{13,12}', NULL, NULL),
  ('{"V","U"}', 'V', NULL, NULL, '{13,14}', NULL, NULL),
  ('{"V","U"}', 'V', NULL, NULL, '{12}', NULL, NULL),
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
  ('{"5","8","S","E"}', '5', 0, NULL, '{7,8}', NULL, NULL),
  ('{"5","8","S","E"}', '5', 0, NULL, '{7,9}', NULL, NULL),
  ('{"5","8","S","E"}', '5', 0, NULL, '{11}', NULL, NULL),
  ('{"5","8","S","E"}', '5', 0, NULL, '{11,12}', NULL, NULL),
  ('{"5","8","S","E"}', '8', 0, 0, NULL, NULL, NULL),
  ('{"5","8","S","E"}', '8', 1, 1, NULL, NULL, NULL),
  ('{"5","8","S","E"}', '8', 4, 4, NULL, NULL, NULL),
  ('{"5","8","S","E"}', 'S', NULL, 15, '{}', NULL, NULL),
  ('{"5","8","S","E"}', 'S', NULL, 14, '{}', NULL, NULL),
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
  ('{"6","O","C","G","9"}', 'G', 0, 10, NULL, NULL, NULL),
  ('{"6","O","C","G","9"}', 'G', 0, 5, NULL, NULL, NULL),
  ('{"6","O","C","G","9"}', '9', 0, 14, NULL, NULL, NULL),
  ('{"6","O","C","G","9"}', '9', 0, 15, NULL, NULL, NULL),
  ('{"6","O","C","G","9"}', '9', 1, 11, NULL, NULL, NULL),
  ('{"6","O","C","G","9"}', '9', 1, 14, NULL, NULL, NULL),
  ('{"6","O","C","G","9"}', '9', 1, 15, NULL, NULL, NULL),
  ('{"6","O","C","G","9"}', '9', 1, 11, NULL, NULL, NULL),
  ('{"9","8","Q"}', '9', 4, 15, NULL, NULL, NULL),
  ('{"9","8","Q"}', '9', 8, 15, NULL, NULL, NULL),
  ('{"9","8","Q"}', '8', 4, 4, NULL, NULL, NULL),
  ('{"9","8","Q"}', '8', 4, 8, NULL, NULL, NULL),
  ('{"9","8","Q"}', '8', 8, 8, NULL, NULL, NULL),
  ('{"9","8","Q"}', '8', 9, 8, NULL, NULL, NULL),
  ('{"9","8","Q"}', '8', 9, 9, NULL, NULL, NULL),
  ('{"9","8","Q"}', '8', 9, 10, NULL, NULL, NULL),
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
  ('{"O","2","3","U","X"}', 'X', 0, 1, '{15}', NULL, NULL),
  ('{"O","2","3","U","X"}', 'X', 0, 1, '{12,14}', NULL, NULL),
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
  ('{"8","9","C","G","S","6"}', '8', 9, 9, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', '8', 8, 8, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', '9', 8, 11, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', '9', 8, 14, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', '9', 8, 15, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', '9', 9, 11, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', '9', 9, 14, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', '9', 9, 15, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', 'C', 0, 12, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', 'C', 0, 8, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', 'C', 4, 8, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', 'C', 4, 12, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', 'C', 8, 12, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', 'C', 0, 13, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', 'G', 0, 9, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', 'G', 0, 5, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', 'G', 4, 9, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', 'G', 4, 5, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', 'G', 4, 14, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', 'G', 4, 13, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', 'S', 4, 11, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', 'S', 4, 15, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', '6', 0, 11, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', '6', 0, 10, NULL, NULL, NULL),
  ('{"8","9","C","G","S","6"}', '6', 4, 10, NULL, NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', '2', NULL, NULL, '{14}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', '2', NULL, NULL, '{15}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', '3', 3, 15, NULL, NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', '3', 3, 14, NULL, NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', '3', 2, 15, NULL, NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', '8', 10, 11, NULL, NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', '8', 10, 10, NULL, NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', '8', 9, 10, NULL, NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', '8', 11, 10, NULL, NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{3,7}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{1,7}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{3,11}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{7}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{6}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{11}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{11}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{3,6,5}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{3,0,6}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{1,7,6}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{3,0,7,6}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{3,7,10,12}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{3,7,10}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{0,7,6}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{3,7,12}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{7,6}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{3,6,12}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{3,6}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{3,11,10}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{3,10}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{3,11}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{3,10,9}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{3,7,6}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 15, '{3,6,10}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{3,7}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{1,7}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{3,11}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{7}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{6}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{11}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{3,6,5}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{3,0,6}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{1,7,6}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{3,0,7,6}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{3,7,10,12}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{3,7,10}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{3,7,12}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{7,6}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{3,6,12}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{3,6}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{3,11,10}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{3,10}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{3,11}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{3,10,9}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{3,7,6}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{3,6,10}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'B', 15, 14, '{3,1,7,6,12}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'D', 15, 15, '{3}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'D', 15, 14, '{3}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'D', 15, 13, '{3}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'D', 15, 15, '{}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'D', 15, 14, '{}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'D', 15, 13, '{}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'P', 15, 11, '{}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'P', 15, 11, '{3}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'P', 15, 11, '{3,4}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'P', 15, 11, '{3,0}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'P', 15, 6, '{}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'P', 15, 6, '{3}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'P', 15, 6, '{3,4}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'P', 15, 6, '{3,0}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'R', 15, 12, '{}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'R', 15, 12, '{7}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'R', 15, 12, '{3,7}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'R', 15, 12, '{3,4,7}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'R', 15, 12, '{3,0,7}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'R', 15, 12, '{7,10}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'R', 15, 12, '{3,7,10}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'R', 15, 12, '{3,4,7,10}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'R', 15, 12, '{3,0,7,10}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'R', 15, 12, '{3,7,10}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'R', 15, 12, '{3,10}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'R', 15, 12, '{6}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'R', 15, 12, '{10}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'R', 15, 12, '{11}', NULL, NULL),
  ('{"2","3","8","B","D","P","R"}', 'R', 15, 12, '{4,7,6}', NULL, NULL);