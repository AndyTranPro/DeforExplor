/*
Steps to Complete

    Create a View called “forestation” by joining all three tables - forest_area,
     land_area and regions in the workspace.
    The forest_area and land_area tables join on both country_code AND year.
    The regions table joins these based on only country_code.

    In the ‘forestation’ View, include the following:
        All of the columns of the origin tables
        A new column that provides the percent of the land area that is designated as forest.

    Keep in mind that the column forest_area_sqkm in the forest_area table and the land_area_sqmi
    in the land_area table are in different units (square kilometers and square miles, respectively),
    so an adjustment will need to be made in the calculation you write (1 sq mi = 2.59 sq km).
*/

/*
create view forestation as
select
	fa.country_code,
    fa.year,
    fa.forest_area_sqkm,
    la.total_area_sq_mi,
    r.region,
    (fa.forest_area_sqkm / (la.total_area_sq_mi * 2.59)) * 100 as forest_percentage
from
	forest_area fa
join
	land_area la on fa.country_code = la.country_code and la.year = fa.year
join
	regions r on fa.country_code = r.country_code;
*/
DROP PROCEDURE IF EXISTS create_view_if_not_exists;

DELIMITER //

CREATE PROCEDURE create_view_if_not_exists()
BEGIN
    DECLARE view_exists INT DEFAULT 0;

    -- Check if the view exists
    SELECT COUNT(*)
    INTO view_exists
    FROM information_schema.tables
    WHERE table_schema = 'workshopdb' 
    AND table_name = 'forestation'
    AND table_type = 'VIEW';

    -- Create the view if it does not exist
    IF view_exists = 0 THEN
        create view forestation as
		select
			fa.country_code,
			fa.year,
            fa.country_name,
			fa.forest_area_sqkm,
			la.total_area_sq_mi,
			r.region,
			(fa.forest_area_sqkm / (la.total_area_sq_mi * 2.59)) * 100 as forest_percentage
		from
			forest_area fa
		join
			land_area la on fa.country_code = la.country_code and la.year = fa.year
		join
			regions r on fa.country_code = r.country_code;
    END IF;
END //
DELIMITER ;
-- Call the stored procedure
CALL create_view_if_not_exists();

/*
1. GLOBAL SITUATION

Instructions:

    Answering these questions will help you add information into the template.
    Use these questions as guides to write SQL queries.
    Use the output from the query to answer these questions.

1a. What was the total forest area (in sq km) of the world in 1990?
   Please keep in mind that you can use the country record denoted as “World" in the region table.

1b. What was the total forest area (in sq km) of the world in 2016?
   Please keep in mind that you can use the country record in the table is denoted as “World.”

*/
select country_name, year, forest_area_sqkm
from forestation
where country_name = 'World' and (year = '1990' or year = '2016')
order by year asc;
/*
1c. What was the change (in sq km) in the forest area of the world from 1990 to 2016?
*/
select (t1.forest_area_sqkm - t0.forest_area_sqkm) as forest_area_change_sqkm
from forestation as t1, forestation as t0
where (t1.year = '2016' and t1.country_name = 'World') and (t0.year = '1990' and t0.country_name = 'World');

/*
1d. What was the percent change in forest area of the world between 1990 and 2016?
*/
select (((t1.forest_area_sqkm / t0.forest_area_sqkm) - 1) * 100) as percent_change_sqkm
from forestation as t1, forestation as t0
where (t1.year = '2016' and t1.country_name = 'World') and (t0.year = '1990' and t0.country_name = 'World');

/*
1e. If you compare the amount of forest area lost between 1990 and 2016,
   to which country's total area in 2016 is it closest to?
*/
select country_name, (total_area_sq_mi * 2.59) as forest_area_sqkm
from forestation
where year = '2016' and (total_area_sq_mi * 2.59) between 1324449 - 50000 and 1324449 + 50000;

/*
2. REGIONAL OUTLOOK

2a. What was the percent forest of the entire world in 2016?
   Which region had the HIGHEST percent forest in 2016,
   and which had the LOWEST, to 2 decimal places?

2b. What was the percent forest of the entire world in 1990?
   Which region had the HIGHEST percent forest in 1990,
   and which had the LOWEST, to 2 decimal places?

2c. Based on the table you created, which regions of the world
    DECREASED in forest area from 1990 to 2016?
*/
select t0.region, t0.year, round(t0.forest_percentage, 2) as forest_percentage
from forestation t0
where t0.year = '2016' and t0.region = 'World';

-- Find the regions with the highest and lowest percent forest
WITH region_forest AS (
    SELECT 
        region,
        year,
        round((SUM(forest_area_sqkm) / SUM(total_area_sq_mi * 2.59)) * 100, 2) AS forest_cover
    FROM 
        forestation
    WHERE 
        year IN (1990, 2016)
    GROUP BY 
        region, year
)
SELECT 
    r1.region,
    r1.forest_cover AS forest_cover_1990,
    r2.forest_cover AS forest_cover_2016
FROM 
    region_forest r1
JOIN 
    region_forest r2 ON r1.region = r2.region AND r1.year = 1990 AND r2.year = 2016
ORDER BY 
    r2.forest_cover desc;

-- regions of the world DECREASED in forest area from 1990 to 2016
WITH region_forest AS (
    SELECT 
        region,
        year,
        round((SUM(forest_area_sqkm) / SUM(total_area_sq_mi * 2.59)) * 100, 2) AS forest_cover
    FROM 
        forestation
    WHERE 
        year IN (1990, 2016)
    GROUP BY 
        region, year
)
SELECT 
    r1.region,
    r1.forest_cover AS forest_cover_1990,
    r2.forest_cover AS forest_cover_2016
FROM 
    region_forest r1
JOIN 
    region_forest r2 ON r1.region = r2.region AND r1.year = 1990 AND r2.year = 2016
WHERE 
	r1.forest_cover > r2.forest_cover
ORDER BY 
    r2.forest_cover desc;


/*
3. COUNTRY-LEVEL DETAIL
A.	SUCCESS STORIES
*/


/*
Which 5 countries saw the largest absolute decrease in forest area from 1990 to 2016?
What was the sqkm change for each?
*/
-- regions of the world DECREASED in forest area from 1990 to 2016
WITH country_forest AS (
    SELECT 
        country_name,
        year,
        forest_area_sqkm as forest_area
    FROM 
        forestation
    WHERE 
        year IN (1990, 2016) AND country_name != 'World'
)
SELECT 
    r1.country_name,
    round((r2.forest_area - r1.forest_area), 2) as change_forest_area
FROM 
    country_forest r1
JOIN 
    country_forest r2 ON r1.country_name = r2.country_name AND r1.year = 1990 AND r2.year = 2016
ORDER BY 
    change_forest_area asc
LIMIT 5;


/*
Which 5 countries saw the largest percent decrease in forest area from 1990 to 2016?
What was the percent change to 2 decimal places for each?
*/
WITH country_forest AS (
    SELECT 
        country_name,
        year,
        forest_area_sqkm as forest_area
    FROM 
        forestation
    WHERE 
        year IN (1990, 2016) AND country_name != 'World'
)
SELECT 
    r1.country_name,
    round(((r2.forest_area / r1.forest_area) - 1) * 100, 2) as percent_change_forest_area
FROM 
    country_forest r1
JOIN 
    country_forest r2 ON r1.country_name = r2.country_name AND r1.year = 1990 AND r2.year = 2016
ORDER BY 
    percent_change_forest_area asc
LIMIT 5;


/*
Country with largest percent change in forest area from 1990 to 2016
*/
WITH country_forest AS (
    SELECT 
        country_name,
        year,
        forest_area_sqkm as forest_area
    FROM 
        forestation
    WHERE 
        year IN (1990, 2016) AND country_name != 'World'
)
SELECT 
    r1.country_name,
    round(((r2.forest_area / r1.forest_area) - 1) * 100, 2) as percent_change_forest_area
FROM 
    country_forest r1
JOIN 
    country_forest r2 ON r1.country_name = r2.country_name AND r1.year = 1990 AND r2.year = 2016
ORDER BY 
    percent_change_forest_area desc
LIMIT 1;

/*
c. If countries were grouped by percent forestation in quartiles,
which group had the most countries in it in 2016?
*/
WITH percent_forest AS (
    SELECT 
        country_name,
        forest_percentage AS percent_forest
    FROM 
        forestation
    WHERE 
        year = 2016
        AND country_name != 'World'
),
quartiles AS (
    SELECT 
        country_name,
        percent_forest,
        CASE 
            WHEN percent_forest <= 25 THEN 1
            WHEN percent_forest <= 50 THEN 2
            WHEN percent_forest <= 75 THEN 3
            ELSE 4
        END AS quartile
    FROM 
        percent_forest
)
SELECT 
    quartile AS percentile,
    COUNT(country_name) AS count
FROM 
    quartiles
GROUP BY 
    quartile
ORDER BY 
    quartile;

/*
d. List all of the countries that were in the 4th quartile (percent forest > 75%) in 2016.
*/
WITH percent_forest AS (
    SELECT 
        country_name,
        forest_percentage AS percent_forest
    FROM 
        forestation
    WHERE 
        year = 2016
        AND country_name != 'World'
),
quartiles AS (
    SELECT 
        country_name,
        percent_forest,
        CASE 
            WHEN percent_forest <= 25 THEN 1
            WHEN percent_forest <= 50 THEN 2
            WHEN percent_forest <= 75 THEN 3
            ELSE 4
        END AS quartile
    FROM 
        percent_forest
)
select
    q.country_name,
    f.region,
    round(f.forest_percentage, 2) as forest_percent
from
	quartiles q
join forestation f on q.country_name = f.country_name and f.year = 2016
where
	quartile = 4
order by
	forest_percent desc;
/*
e. How many countries had a percent forestation higher than the United States in 2016?
*/
WITH us_percent_forest AS (
    SELECT 
        country_name,
        forest_percentage AS percent_forest
    FROM 
        forestation
    WHERE 
        year = 2016
        AND country_name = 'United States'
)
select
	count(f.country_name) as num_countries
from
	us_percent_forest
join
	forestation f on f.country_name != 'World' and f.year = 2016
where
	f.forest_percentage > percent_forest;

