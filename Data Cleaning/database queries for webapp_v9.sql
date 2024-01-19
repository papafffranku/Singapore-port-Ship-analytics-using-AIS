-- ### SQL QUERIES ###

--table schema test
SELECT * FROM 


-- test lower and upper bounds of AIS coordinates (-179.51315, 181, -84.23562, 91)
SELECT MIN(t.lon), MAX(t.lon), MIN(t.lat) ,MAX(t.lat)
FROM type1_2_3 as t

-- how many messages in the overlap of mmsi 
-- 784105
SELECT count(*)
FROM type1_2_3 t1
WHERE mmsi = ANY (SELECT mmsi FROM type5)

-- 545085
SELECT count(*)
FROM type5
WHERE mmsi = ANY (SELECT mmsi FROM type1_2_3)


-- (1) How many distinct ships are licensed in which countries
-- ## query joins fact table with country codes by MID column

-- ## query overlap of 2 tables: type1 and type 5 
SELECT c.country_name as country, count(DISTINCT t1.mmsi) as count
FROM country_code c,
(SELECT DISTINCT mmsi FROM type1_2_3) as t1,
(SELECT DISTINCT mmsi, MID FROM type5) as t5
WHERE t1.mmsi = t5.mmsi
AND c.MID = t5.MID 
GROUP BY c.country_name
ORDER BY count DESC


-- (2) For the whole month of September, how many trips with destination outside Singapore have been completed? 
-- Please give the %-shares by destination countries for at least 60/70% of trips. Remaining share is just “Other”.

-- distinct ship
SELECT c.country_name as country, count(DISTINCT t1.mmsi) as count
FROM country_code as c,
(SELECT DISTINCT mmsi FROM type1_2_3) as t1,
(SELECT DISTINCT mmsi, destination_country FROM type5) as t5
WHERE t1.mmsi = t5.mmsi
AND LOWER(t5.destination_country) = LOWER(c.country_name)
GROUP BY country
ORDER BY count DESC

-- (3) For the whole month of September and for distinct MMSI, 
-- what is the share of Cargo, Tanker, Fishing, and Passenger ships? 
-- If there any other significant ship type? Remaining ones fall under ‘Other’.

-- query optimisaion (final)
SELECT CASE 
WHEN code = 30 THEN 'Fishing'
WHEN code BETWEEN 60 AND 69 THEN 'Passenger'
WHEN code BETWEEN 70 AND 79 THEN 'Cargo'
WHEN code BETWEEN 80 AND 89 THEN 'Tanker'
ELSE 'Others' END AS bins, count(mmsi) as count
FROM (
SELECT DISTINCT t1.mmsi as mmsi, sc.code as code 
FROM ship_dimension as s, shipcode as sc,
(SELECT DISTINCT mmsi FROM type1_2_3) as t1,
(SELECT DISTINCT mmsi FROM type5) as t5
WHERE t1.mmsi = s.mmsi
AND t1.mmsi = t5.mmsi
AND s.shiptype = sc.code
	) t 
GROUP BY bins
ORDER BY count DESC

-- (4) Calculate the number of ships in Singaporean ports per day for the whole month. 
-- For each day, give the share of ship type. 
-- On average, how many ships are in the port in the top 10% busiest days vs. top 25% vs. the mid 50% vs the bottom 25%.

-- ## CASE WHEN  base query for ship count and type per day
SELECT DATE(t1.time) as date, CASE WHEN sc.description LIKE '%Cargo%' THEN 'Cargo'
 WHEN sc.description LIKE '%Tanker%' THEN 'Tanker' ELSE 'Others' END as type, count(DISTINCT t1.mmsi) as count
FROM ship_dimension as s, shipcode as sc,
(SELECT DISTINCT mmsi, time, lon, lat FROM type1_2_3) as t1,
(SELECT DISTINCT mmsi FROM type5) as t5
WHERE t1.mmsi = s.mmsi
AND t1.mmsi = t5.mmsi
AND s.shiptype = sc.code
AND ((t1.lon BETWEEN 103.838022 AND 103.852221 -- tanjong pagar
AND t1.lat BETWEEN 1.257772 AND 1.269024) -- tanjong pagar
OR (t1.lon BETWEEN 103.8225-0.01 AND 103.8225+0.01 -- keppel harbour
AND t1.lat BETWEEN 1.2612-0.01 AND 1.2612+0.01) -- keppel harbour
OR (t1.lon BETWEEN 103.8380-0.01 AND 103.8380+0.01  -- keppel terminal
AND t1.lat BETWEEN 1.2690-0.01 AND 1.2690+0.01) -- keppel terminal
OR (t1.lon BETWEEN 103.8347-0.02 AND 103.8347+0.02 -- marina
AND t1.lat BETWEEN 1.2664-0.02 AND 1.2664+0.02) -- marina
OR (t1.lon BETWEEN 103.7752-0.01 AND 103.7752+0.01 -- ppt1
AND t1.lat BETWEEN 1.2739-0.01 AND 1.2739+0.01) -- ppt1
OR (t1.lon BETWEEN 103.7800-0.01 AND 103.7800+0.01 -- ppt2
AND t1.lat BETWEEN 1.2744-0.01 AND 1.2744+0.01) -- ppt2
OR (t1.lon BETWEEN 103.7848-0.01 AND 103.7848+0.01 -- ppt3
AND t1.lat BETWEEN 1.2749-0.01 AND 1.2749+0.01) -- ppt3
OR (t1.lon BETWEEN 103.7896-0.01 AND 103.7896+0.01 -- ppt4
AND t1.lat BETWEEN 1.2754-0.01 AND 1.2754+0.01) -- ppt4
OR (t1.lon BETWEEN 103.7944-0.01 AND 103.7944+0.01 -- ppt5
AND t1.lat BETWEEN 1.2759-0.01 AND 1.2759+0.01) -- ppt5
OR (t1.lon BETWEEN 103.7992-0.01 AND 103.7992+0.01 -- ppt6
AND t1.lat BETWEEN 1.2764-0.01 AND 1.2764+0.01) -- ppt6
OR (t1.lon BETWEEN 103.61191878972717-0.01 AND 103.61191878972717+0.01 -- tuas
AND t1.lat BETWEEN 1.244386225597597-0.01 AND 1.244386225597597+0.01)) -- tuas
GROUP BY date, type
ORDER BY date, type, count DESC

-- on average how many ships are in the port (top 10 % - 3 days, top 25% - 8 days)
SELECT avg(count) FROM (
SELECT DATE(t1.time) as date, count(DISTINCT t1.mmsi) as count
FROM ship_dimension as s, shipcode as sc,
(SELECT DISTINCT mmsi, time, lon, lat FROM type1_2_3) as t1,
(SELECT DISTINCT mmsi FROM type5) as t5
WHERE t1.mmsi = s.mmsi
AND t1.mmsi = t5.mmsi
AND s.shiptype = sc.code
AND ((t1.lon BETWEEN 103.838022 AND 103.852221 -- tanjong pagar
AND t1.lat BETWEEN 1.257772 AND 1.269024) -- tanjong pagar
OR (t1.lon BETWEEN 103.8225-0.01 AND 103.8225+0.01 -- keppel harbour
AND t1.lat BETWEEN 1.2612-0.01 AND 1.2612+0.01) -- keppel harbour
OR (t1.lon BETWEEN 103.8380-0.01 AND 103.8380+0.01  -- keppel terminal
AND t1.lat BETWEEN 1.2690-0.01 AND 1.2690+0.01) -- keppel terminal
OR (t1.lon BETWEEN 103.8347-0.02 AND 103.8347+0.02 -- marina
AND t1.lat BETWEEN 1.2664-0.02 AND 1.2664+0.02) -- marina
OR (t1.lon BETWEEN 103.7752-0.01 AND 103.7752+0.01 -- ppt1
AND t1.lat BETWEEN 1.2739-0.01 AND 1.2739+0.01) -- ppt1
OR (t1.lon BETWEEN 103.7800-0.01 AND 103.7800+0.01 -- ppt2
AND t1.lat BETWEEN 1.2744-0.01 AND 1.2744+0.01) -- ppt2
OR (t1.lon BETWEEN 103.7848-0.01 AND 103.7848+0.01 -- ppt3
AND t1.lat BETWEEN 1.2749-0.01 AND 1.2749+0.01) -- ppt3
OR (t1.lon BETWEEN 103.7896-0.01 AND 103.7896+0.01 -- ppt4
AND t1.lat BETWEEN 1.2754-0.01 AND 1.2754+0.01) -- ppt4
OR (t1.lon BETWEEN 103.7944-0.01 AND 103.7944+0.01 -- ppt5
AND t1.lat BETWEEN 1.2759-0.01 AND 1.2759+0.01) -- ppt5
OR (t1.lon BETWEEN 103.7992-0.01 AND 103.7992+0.01 -- ppt6
AND t1.lat BETWEEN 1.2764-0.01 AND 1.2764+0.01) -- ppt6
OR (t1.lon BETWEEN 103.61191878972717-0.01 AND 103.61191878972717+0.01 -- tuas
AND t1.lat BETWEEN 1.244386225597597-0.01 AND 1.244386225597597+0.01)) -- tuas
GROUP BY date 
LIMIT 3 ) as t

-- (5a) For one specific day (out of a specific week), how many distinct ships of which ship type are there?

SELECT DATE(t1.time) as date, CASE WHEN sc.description LIKE '%Cargo%' THEN 'Cargo'
 WHEN sc.description LIKE '%Tanker%' THEN 'Tanker' ELSE 'Others' END as type, count(DISTINCT t1.mmsi) as count
FROM ship_dimension as s, shipcode as sc,
(SELECT DISTINCT mmsi, time, lon, lat FROM type1_2_3) as t1,
(SELECT DISTINCT mmsi FROM type5) as t5
WHERE t1.mmsi = s.mmsi
AND t1.mmsi = t5.mmsi
AND s.shiptype = sc.code
AND DATE(t1.time) BETWEEN '1/9/23' and '3/9/23' -- sample input 
-- AND DATE(t1.time) BETWEEN {date_start} and {date_end} -- user date input
AND ((t1.lon BETWEEN 103.838022 AND 103.852221 -- tanjong pagar
AND t1.lat BETWEEN 1.257772 AND 1.269024) -- tanjong pagar
OR (t1.lon BETWEEN 103.8225-0.01 AND 103.8225+0.01 -- keppel harbour
AND t1.lat BETWEEN 1.2612-0.01 AND 1.2612+0.01) -- keppel harbour
OR (t1.lon BETWEEN 103.8380-0.01 AND 103.8380+0.01  -- keppel terminal
AND t1.lat BETWEEN 1.2690-0.01 AND 1.2690+0.01) -- keppel terminal
OR (t1.lon BETWEEN 103.8347-0.02 AND 103.8347+0.02 -- marina
AND t1.lat BETWEEN 1.2664-0.02 AND 1.2664+0.02) -- marina
OR (t1.lon BETWEEN 103.7752-0.01 AND 103.7752+0.01 -- ppt1
AND t1.lat BETWEEN 1.2739-0.01 AND 1.2739+0.01) -- ppt1
OR (t1.lon BETWEEN 103.7800-0.01 AND 103.7800+0.01 -- ppt2
AND t1.lat BETWEEN 1.2744-0.01 AND 1.2744+0.01) -- ppt2
OR (t1.lon BETWEEN 103.7848-0.01 AND 103.7848+0.01 -- ppt3
AND t1.lat BETWEEN 1.2749-0.01 AND 1.2749+0.01) -- ppt3
OR (t1.lon BETWEEN 103.7896-0.01 AND 103.7896+0.01 -- ppt4
AND t1.lat BETWEEN 1.2754-0.01 AND 1.2754+0.01) -- ppt4
OR (t1.lon BETWEEN 103.7944-0.01 AND 103.7944+0.01 -- ppt5
AND t1.lat BETWEEN 1.2759-0.01 AND 1.2759+0.01) -- ppt5
OR (t1.lon BETWEEN 103.7992-0.01 AND 103.7992+0.01 -- ppt6
AND t1.lat BETWEEN 1.2764-0.01 AND 1.2764+0.01) -- ppt6
OR (t1.lon BETWEEN 103.61191878972717-0.01 AND 103.61191878972717+0.01 -- tuas
AND t1.lat BETWEEN 1.244386225597597-0.01 AND 1.244386225597597+0.01)) -- tuas
GROUP BY date, type
ORDER BY date, type, count DESC

-- (5b) For one specific day (out of a specific week), how ships per navigation status are there?
-- Comment on (5): Both should result in the same absolute number of ships per day. 
-- If not, we need to decide which query to keep.

SELECT DATE(t1.time) as date, ns.description as status, count(DISTINCT t1.mmsi) as count
FROM ship_dimension as s, navigation as ns,
(SELECT DISTINCT mmsi, time, status, lat, lon FROM type1_2_3) as t1,
(SELECT DISTINCT mmsi FROM type5) as t5
WHERE t1.mmsi = s.mmsi
AND t1.mmsi = t5.mmsi
AND ns.code = t1.status 
AND DATE(t1.time) BETWEEN '1/9/23' and '3/9/23' -- sample input
-- AND DATE(type1.time) BETWEEN {date_start} and {date_end} -- user date input
AND ((t1.lon BETWEEN 103.838022 AND 103.852221 -- tanjong pagar
AND t1.lat BETWEEN 1.257772 AND 1.269024) -- tanjong pagar
OR (t1.lon BETWEEN 103.8225-0.01 AND 103.8225+0.01 -- keppel harbour
AND t1.lat BETWEEN 1.2612-0.01 AND 1.2612+0.01) -- keppel harbour
OR (t1.lon BETWEEN 103.8380-0.01 AND 103.8380+0.01  -- keppel terminal
AND t1.lat BETWEEN 1.2690-0.01 AND 1.2690+0.01) -- keppel terminal
OR (t1.lon BETWEEN 103.8347-0.02 AND 103.8347+0.02 -- marina
AND t1.lat BETWEEN 1.2664-0.02 AND 1.2664+0.02) -- marina
OR (t1.lon BETWEEN 103.7752-0.01 AND 103.7752+0.01 -- ppt1
AND t1.lat BETWEEN 1.2739-0.01 AND 1.2739+0.01) -- ppt1
OR (t1.lon BETWEEN 103.7800-0.01 AND 103.7800+0.01 -- ppt2
AND t1.lat BETWEEN 1.2744-0.01 AND 1.2744+0.01) -- ppt2
OR (t1.lon BETWEEN 103.7848-0.01 AND 103.7848+0.01 -- ppt3
AND t1.lat BETWEEN 1.2749-0.01 AND 1.2749+0.01) -- ppt3
OR (t1.lon BETWEEN 103.7896-0.01 AND 103.7896+0.01 -- ppt4
AND t1.lat BETWEEN 1.2754-0.01 AND 1.2754+0.01) -- ppt4
OR (t1.lon BETWEEN 103.7944-0.01 AND 103.7944+0.01 -- ppt5
AND t1.lat BETWEEN 1.2759-0.01 AND 1.2759+0.01) -- ppt5
OR (t1.lon BETWEEN 103.7992-0.01 AND 103.7992+0.01 -- ppt6
AND t1.lat BETWEEN 1.2764-0.01 AND 1.2764+0.01) -- ppt6
OR (t1.lon BETWEEN 103.61191878972717-0.01 AND 103.61191878972717+0.01 -- tuas
AND t1.lat BETWEEN 1.244386225597597-0.01 AND 1.244386225597597+0.01)) -- tuas
GROUP BY date, ns.description 
ORDER BY date, ns.description, count DESC

-- (6) How many ships of which ship type are in the port each day?
-- (6a) Comparing the absolute number of ships with the average number of ships during the top 10% busiest days, 
-- what is the % difference between that specific day and the top 10%?

--  6a the same as 4. both ask for top vs average number of ships in the port
-- pls perform the comparison manually first

-- (7a) What are the tide heights for per day?
SELECT day as date, height, high_low 
FROM tide
WHERE day IS NOT NULL
ORDER BY date ASC

-- (7b) What is the average windspeed per day?
SELECT date_time, wind_speed
FROM weather
ORDER BY date_time ASC

-- (7c) What is the average visibility per day?
SELECT date_time, visibility
FROM weather
ORDER BY date_time ASC

-- (7d) What is the average sea pressure per day?
SELECT date_time, sea_level_pressure
FROM weather
ORDER BY date_time ASC