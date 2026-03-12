-- Exercise 10 
SELECT MAX(years_employed) FROM employees;

SELECT role, AVG(years_employed) FROM employees GROUP BY role;

SELECT building, SUM(years_employed) FROM employees GROUP BY building;

-- Exercise 11
SELECT COUNT(*) FROM employees WHERE role = 'Artist';

SELECT role, COUNT(*) FROM employees GROUP BY role;

SELECT role, SUM(years_employed) FROM employees WHERE role = 'Engineer';

-- Free SQL Exercise
-- Try It 1
select count ( distinct shape )   number_of_shapes,
       stddev ( distinct weight ) distinct_weight_stddev
from   bricks;

-- Try It 2
select colour,
       sum ( weight ) total_weight
from   bricks
group  by colour
having sum ( weight ) > 2;

-- Try It 3
select colour,
       shape,
       count (*) num_bricks
from   bricks
group  by rollup ( colour, shape );