CREATE DATABASE ENERGYDB;
USE ENERGYDB;

-- 1. COUNTRY TABLE

CREATE TABLE COUNTRY(CID VARCHAR(10) PRIMARY KEY,
COUNTRY VARCHAR(100) UNIQUE);

SELECT * FROM COUNTRY;

CREATE TABLE EMISSION_3(
COUNTRY VARCHAR(100),
ENERGY_TYPE VARCHAR(50),
YEAR INT,
EMISSION INT,
PER_CAPITA_EMISSION DOUBLE,
FOREIGN KEY (COUNTRY) REFERENCES COUNTRY(COUNTRY));

SELECT * FROM EMISSION_3;

-- 3. POPULATION TABLE

CREATE TABLE population (
    countries VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (countries) REFERENCES country(Country)
);

SELECT * FROM POPULATION;

-- 4. PRODUCTION TABLE

CREATE TABLE PRODUCTION(
     COUNTRY VARCHAR(100),
     ENERGY VARCHAR(50),
     YEAR INT,
     PRODUCTION INT,
     VALUE DOUBLE,
     FOREIGN KEY (COUNTRY) REFERENCES COUNTRY(COUNTRY));
     
SELECT * FROM PRODUCTION;

-- 5. GDP_3 TABLE

CREATE TABLE gdp_3(
     COUNTRY VARCHAR(100),
     YEAR INT,
     VALUE DOUBLE,
     FOREIGN KEY (COUNTRY) REFERENCES COUNTRY (COUNTRY));
     
SELECT * FROM GDP_3;

-- 6. CONSUMPTION TABLE

CREATE TABLE CONSUMPTION(
     COUNTRY VARCHAR(100),
     ENERGY VARCHAR(50),
     YEAR INT,
     CONSUMPTION INT,
     FOREIGN KEY (COUNTRY) REFERENCES COUNTRY(COUNTRY));

SELECT * FROM CONSUMPTION;

-- 1. WHAT IS THE TOTAL EMISSION PER COUNTRY FOR THE MOST RECENT YEAR AVAILABLE ?

SELECT COUNTRY,YEAR ,SUM(EMISSION) AS TOTAL_EMISSION
FROM EMISSION_3
WHERE YEAR - (SELECT MAX(YEAR) FROM EMISSION_3)
GROUP BY COUNTRY, YEAR
ORDER BY TOTAL_EMISSION DESC;

-- 2 . WHAT ARE THE TOP 5 COUNTRIES BY GDP IN THE MOST RECENT YEAR ? 

SELECT COUNTRY, YEAR, VALUE AS GDP
FROM gdp_3
WHERE YEAR = (SELECT MAX(YEAR) FROM gdp_3)
LIMIT 5;

-- 3. WHICH ENERGY TYPES CONTRIBUTE MOST TO EMISSION ACROESS ALL COUNTRIES ?

SELECT ENERGY_TYPE, SUM(EMISSION) AS TOTAL_EMISSION
FROM EMISSION_3 
GROUP BY ENERGY_TYPE
ORDER BY TOTAL_EMISSION DESC;

-- 4. HOW HAVE GLOBAL EMISSIONS CHANGES YEAR OVER YEAR ?

SELECT YEAR, SUM(EMISSION) AS GLOBAL_EMISSION
FROM EMISSION_3
GROUP BY year
ORDER BY YEAR;

-- 5. WHAT IS THE TREND IN GDP FOR EACH COUNTRY OVER THE GIVEN YEARS ?

SELECT COUNTRY , YEAR, VALUE AS GDP
FROM gdp_3
ORDER BY COUNTRY, YEAR;

-- 6. HOW HAS POPULATION GROWTH AFFECTED TOTAL EMISSIONS IN EACH COUNTRY ?

SELECT 
    e.country, 
    e.year, 
    SUM(e.emission) AS total_emission, 
    SUM(p.Value) AS total_population
FROM emission_3 e
JOIN population p ON e.country = p.countries AND e.year = p.year
GROUP BY e.country, e.year
ORDER BY e.country, e.year;

-- 7. what is the average yearly change in emissions per capita for each country ?

SELECT country,
       AVG(PER_CAPITA_EMISSION) AS AVG_PER_CAPITA_EMISSION
FROM emission_3 
GROUP BY country
ORDER BY AVG_PER_CAPITA_EMISSION DESC;

-- 8. WHAT IS THE EMISSION-TO-GDP RATIO FOR EACH COUNTRY BY YEAR ?

SELECT e.country ,e.year,
        SUM(e.emission) / g.value AS emission_to_gdp_ratio
FROM emission_3 e
JOIN gdp_3 g ON e.country = g.country AND e.year = g.year
GROUP BY e.country,e.year,g.value        
ORDER BY e.year;

-- 9. HOW DOES ENERGY PRODUCTION PER CAPITA VARY ACROSS COUNTRIES ?

SELECT 
  p.countries,
  ROUND(SUM(p1.production * 1.0) / NULLIF(SUM(p.value), 0), 4) AS production_percapita
FROM population AS p
JOIN production AS p1 
  ON p.countries = p1.country 
 AND p.year = p1.year
GROUP BY p.countries
ORDER BY production_percapita DESC;

-- 10.  What is the correlation between GDP growth and energy production growth?

SELECT g.Country, g.year, g.Value AS GDP, 
       p.production
FROM gdp_3 g
JOIN (
    SELECT country, year, SUM(production) AS production
    FROM production
    GROUP BY country, year
) p ON g.Country = p.country AND g.year = p.year
ORDER BY g.Country, g.year;

-- 11 .What are the top 10 countries by population and how do their emissions compare?

SELECT 
  p.countries, 
  p.year, 
  SUM(p.Value) AS population, 
  SUM(e.emission) AS total_emission
FROM population p
JOIN emission_3 e ON p.countries = e.country AND p.year = e.year
WHERE p.year = (
  SELECT MAX(p2.year)
  FROM population p2
  JOIN emission_3 e2 ON p2.countries = e2.country AND p2.year = e2.year
)
GROUP BY p.countries, p.year
ORDER BY population DESC
LIMIT 10;

-- 12. What is the global average GDP, emission, and population by year?

SELECT 
    g.year,
    AVG(g.Value) AS avg_gdp,
    (SELECT AVG(e.emission) FROM emission_3 e WHERE e.year = g.year) AS avg_emission,
    (SELECT AVG(p.Value) FROM population p WHERE p.year = g.year) AS avg_population
FROM gdp_3 g
GROUP BY g.year
ORDER BY g.year;

-- Which countries have the highest energy consumption relative to GDP?

SELECT 
    c.country,
    SUM(c.consumption) AS total_consumption,
    g.value AS gdp,
    SUM(c.consumption) / g.value AS consumption_to_gdp
FROM consumption c
JOIN gdp_3 g 
    ON c.country = g.country 
   AND c.year = g.year
GROUP BY c.country, g.value
ORDER BY consumption_to_gdp DESC;

-- Which countries have improved (reduced) their per capita emissions the most over the last decade?

-- Latest year
SET @latest = (SELECT MAX(year) FROM emission_3);

-- Earliest year
SET @earliest = (SELECT MIN(year) FROM emission_3);

SELECT 
    e1.country,
    e2.per_capita_emission AS earliest_value,
    e1.per_capita_emission AS latest_value,
    (e2.per_capita_emission - e1.per_capita_emission) AS improvement
FROM emission_3 e1
JOIN emission_3 e2 
    ON e1.country = e2.country
WHERE e1.year = @latest
  AND e2.year = @earliest
ORDER BY improvement DESC;

-- What is the global share (%) of emissions by country?

SELECT 
    country,
    SUM(emission) AS total_emission,
    SUM(emission) * 100.0 / 
        (SELECT SUM(emission) FROM emission_3) AS global_share_percent
FROM emission_3
GROUP BY country
ORDER BY global_share_percent DESC;
