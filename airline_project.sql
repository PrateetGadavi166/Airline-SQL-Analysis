CREATE database aviation_project;
use aviation_project;
CREATE table city_traffic (
	id int auto_increment primary key,
    year int,
    month int,
    city1 varchar(50),
    city2 varchar(50),
    pax_to_city2 float,
    pax_from_city2 float,
    freight_to_city2 float,
    freight_from_city2 float,
    mail_to_city2 float,
    mail_from_city2 float
);
CREATE TABLE airline_stats (
	id int auto_increment primary key,
    type varchar(50),
    airline varchar(100),
    month int,
    year int,
    aircraft_number int,
    aircraft_hours float,
    aircraft_kilometer float,
    passenger_number FLOAT,
    passenger_kilometers FLOAT,
    seat_kilometers FLOAT,
    passenger_load_factor FLOAT,
    freight FLOAT,
    mail FLOAT,
    total_cargo FLOAT,
    passenger_tonne_km FLOAT,
    mail_tonne_km FLOAT,
    freight_tonne_km FLOAT,
    total_tonne_km FLOAT,
    available_tonne_km FLOAT,
    weight_load_factor float
);
select
	count(*)
from airline_stats;
select
	count(*)
from city_traffic;
SELECT * FROM city_traffic ORDER BY id DESC LIMIT 10;

-- Total passengers per year from both directions
select	
	year,
    format(sum(pax_to_city2 + pax_from_city2),0) as total_passenger
from city_traffic
group by 1
order by 1;

-- Top 5 busiest city pair by total passengers
select
	city1,
    city2,
    format(sum(pax_to_city2 + pax_from_city2),0) as total_passenger
from city_traffic
group by 1,2
order by sum(pax_to_city2 + pax_from_city2) desc
limit 5;

-- Top 5 airline with highest average passenger load factor
select
	airline,
    format(avg(passenger_load_factor),2) as avg_load_factor
from airline_stats
group by 1
order by avg(passenger_load_factor) desc
limit 5;

-- Year-wise total freight carried by all airlines
SELECT 
    year, 
    FORMAT(SUM(freight), 0) AS total_freight_tonnes
FROM airline_stats
GROUP BY year
ORDER BY year;

-- Year-on-Year % growth in total freight
SELECT
	year,
    format(sum(freight),0) as total_freight,
    FORMAT(
    (SUM(freight) - LAG(SUM(freight)) OVER (ORDER BY year)) 
    / LAG(SUM(freight)) OVER (ORDER BY year) * 100, 2) AS yoy_growth_percent
FROM airline_stats
group by 1
order by 1;

-- Most connected city
SELECT 
    city,
    COUNT(*) AS total_appearances
FROM (
    SELECT city1 AS city FROM city_traffic
    UNION ALL
    SELECT city2 AS city FROM city_traffic
) AS all_cities
GROUP BY city
ORDER BY total_appearances DESC
LIMIT 10;

-- Top freight city pair
SELECT
	city1,
    city2,
    format(sum(freight_to_city2 + freight_from_city2),2) as total_freight
FROM city_traffic
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 5;

-- Passenger volume by month
SELECT 
    month, 
    FORMAT(SUM(pax_to_city2 + pax_from_city2), 0) AS total_passengers
FROM city_traffic
GROUP BY 1
ORDER BY 1;

CREATE OR REPLACE VIEW airline_totals AS
SELECT 
    airline,
    SUM(passenger_number) AS total_passengers,
    SUM(freight) AS total_freight,
    SUM(mail) AS total_mail
FROM 
    airline_stats
GROUP BY 
    airline;

WITH avg_load AS (
    SELECT 
        airline, 
        ROUND(AVG(passenger_load_factor), 2) AS avg_load_factor
    FROM 
        airline_stats
    GROUP BY airline
)

SELECT 
    at.airline,
    FORMAT(at.total_passengers, 0) AS total_passengers,
    FORMAT(at.total_freight, 0) AS total_freight,
    FORMAT(at.total_mail, 0) AS total_mail,
    avg_load.avg_load_factor,
     ROUND(
        at.total_freight / NULLIF((at.total_freight + at.total_mail), 0) * 100, 2
    ) AS freight_percent,
    ROUND(
        at.total_mail / NULLIF((at.total_freight + at.total_mail), 0) * 100, 2
    ) AS mail_percent
FROM 
    airline_totals at
JOIN 
    avg_load ON at.airline = avg_load.airline
ORDER BY 
    at.total_passengers DESC
LIMIT 10;

-- Detect which cities only appear as city1, never as city2
SELECT DISTINCT city1
FROM city_traffic
WHERE city1 NOT IN (
    SELECT DISTINCT city2 FROM city_traffic
);
SELECT DISTINCT city2
FROM city_traffic
WHERE city2 NOT IN (
    SELECT DISTINCT city1 FROM city_traffic
);

-- YOY passenger growth
WITH yearly_pax AS (
  SELECT 
    year, 
    SUM(passenger_number) AS total_passengers
  FROM airline_stats
  GROUP BY year
)
SELECT 
  year,
  FORMAT(total_passengers, 0) AS total_passengers,
  ROUND(
    (total_passengers - LAG(total_passengers) OVER (ORDER BY year)) 
    / NULLIF(LAG(total_passengers) OVER (ORDER BY year), 0) * 100, 2
  ) AS yoy_growth_percent
FROM yearly_pax;
