-- Exercise 6
SELECT title, domestic_sales, international_sales 
FROM movies 
INNER JOIN boxoffice ON movies.id = boxoffice.movie_id;

SELECT title, domestic_sales, international_sales 
FROM movies 
INNER JOIN boxoffice ON movies.id = boxoffice.movie_id
WHERE international_sales > domestic_sales;

SELECT title, rating 
FROM movies 
INNER JOIN boxoffice ON movies.id = boxoffice.movie_id
ORDER BY rating DESC;

-- Exercise 7
SELECT DISTINCT building FROM employees;

SELECT * FROM buildings;

SELECT DISTINCT building_name, role 
FROM buildings 
LEFT JOIN employees ON buildings.building_name = employees.building;

-- Page With No Likes
SELECT pages.page_id
FROM pages
LEFT JOIN page_likes ON pages.page_id = page_likes.page_id
WHERE page_likes.page_id IS NULL
ORDER BY pages.page_id ASC;