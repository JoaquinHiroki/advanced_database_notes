-- Exercise 10 
SELECT MAX(years_employed) FROM employees;

SELECT role, AVG(years_employed) FROM employees GROUP BY role;

SELECT building, SUM(years_employed) FROM employees GROUP BY building;

-- Exercise 11
SELECT COUNT(*) FROM employees WHERE role = 'Artist';

SELECT role, COUNT(*) FROM employees GROUP BY role;

SELECT role, SUM(years_employed) FROM employees WHERE role = 'Engineer';
