CREATE DATABASE gms_project;

-- Combinning datasets --
CREATE TABLE gms_project.data_combined AS (
	SELECT * FROM gms_project.data_oct
    
    UNION ALL
    
    SELECT * FROM gms_project.data_nov
    
    UNION ALL
    
    SELECT * FROM gms_project.data_dec
);

-- DATA EXPLORATION--
SELECT * FROM gms_project.data_combined
LIMIT 5;

-- check COMPLETENESS (column: visitid): null?(0) duplicate?(956)
SELECT COUNT(*) as total_rows,
	   COUNT(visitid) as visitid_non_null
FROM gms_project.data_combined;


WITH duplicate_visitid AS (SELECT visitid,
	   COUNT(*) as total_rows
FROM gms_project.data_combined
GROUP BY 1
HAVING COUNT(*) > 1)
SELECT COUNT(*) FROM duplicate_visitid;

-- Create new identifier (concat fullvisitorid + visitid)
SELECT CONCAT(fullvisitorid, '-', visitid) AS unique_session_id,
       COUNT(*) as total_rows
FROM gms_project.data_combined
GROUP BY 1
HAVING COUNT(*) > 1
LIMIT 5;

-- Checking if the unique_session_id appears twice due to overnight session.
SET time_zone = '+00:00'; -- prevent it set to UTC+2 (based on server's current time zone)
SELECT 
	CONCAT(fullvisitorid,'-', visitid) AS unique_session_id,
    FROM_UNIXTIME(date)-INTERVAL 8 HOUR AS date,
    COUNT(*) as total_rows
FROM gms_project.data_combined
GROUP BY 1,2
HAVING unique_session_id = '4961200072408009421-1480578925'
LIMIT 5;
-- Therefor, true # of distinct sessions = count only distinct unique_session_id within a date
-- as it is comfirmed above that the dup unique_session_id is due to overnight sessions only.

-- BUSINESS INSIGHTS--

-- 1. Website Engagement by Day--
SELECT 
    date,
    COUNT(DISTINCT unique_session_id) AS sessions
FROM (
	SELECT
		DATE(FROM_UNIXTIME(date)) AS date,
	    CONCAT(fullvisitorid, '-', visitid) AS unique_session_id
	FROM gms_project.data_combined
	GROUP BY 1,2
) t1
GROUP BY 1
ORDER BY 1;

-- Check for the engagement within a week--
SELECT 
	DAYNAME(date) as weekday,
    COUNT(DISTINCT unique_session_id) AS sessions
FROM (
	SELECT
		DATE(FROM_UNIXTIME(date)) AS date,
        CONCAT(fullvisitorid, '-', visitid) AS unique_session_id
	FROM gms_project.data_combined
	GROUP BY 1,2
    ) t1
GROUP BY 1
ORDER BY 2 DESC;

-- 2.Conversion Rate by DAY, DEVICE
-- Website Engagement & Monetization by Day--
SELECT 
    DAYNAME(date) AS weekday,
    COUNT(DISTINCT unique_session_id) AS sessions,
    SUM(converted) AS conversions,
	((SUM(converted)/COUNT(DISTINCT unique_session_id))*100) AS conversion_rate
FROM (
		SELECT
			DATE(FROM_UNIXTIME(date)) AS date,
			CASE
				WHEN transactions >= 1 THEN 1
				ELSE 0 
			END AS converted,
			CONCAT(fullvisitorid, '-', visitid) AS unique_session_id
		FROM gms_project.data_combined
		GROUP BY 1,2,3
) t1
GROUP BY 1
ORDER BY 2 DESC;


-- Website Engagement & Monetization by Device--
SELECT 
	deviceCategory,
    COUNT(DISTINCT unique_session_id) AS sessions,
	((COUNT(DISTINCT unique_session_id)/SUM(COUNT(DISTINCT unique_session_id)) OVER ())*100) AS sessions_percentage, -- takes the counts from all groups and sums them up across the entire result set 
	SUM(transactionrevenue)/1e6 AS revenue,
	((SUM(transactionrevenue)/SUM(SUM(transactionrevenue)) OVER ())*100) AS revenue_percentage	
FROM (
		SELECT
			deviceCategory,
		    transactionrevenue,
			CONCAT(fullvisitorid, '-', visitid) AS unique_session_id
		FROM gms_project.data_combined
		GROUP BY 1,2,3    
) t1
GROUP BY 1;

-- Website Retention
SELECT
	  CASE
		    WHEN newVisits = 1 THEN 'New Visitor'
		    ELSE 'Returning Visitor'
	  END AS visitor_type,
	  COUNT(DISTINCT fullVisitorId) AS visitors,
    ((COUNT(DISTINCT fullVisitorId)/SUM(COUNT(DISTINCT fullVisitorId)) OVER ())*100) AS visitors_percentage
FROM gms_project.data_combined
GROUP BY 1;

-- Website Aquisition
SELECT
		COUNT(DISTINCT unique_session_id) AS sessions,
		SUM(bounces) AS bounces,
		((SUM(bounces)/COUNT(DISTINCT unique_session_id))*100) AS bounce_rate
FROM (
		SELECT
				bounces,
				CONCAT(fullvisitorid, '-', visitid) AS unique_session_id
		FROM gms_project.data_combined
		GROUP BY 1,2
) t1
ORDER BY 1 DESC;

-- Website Acquisition by Channel
SELECT
		channelGrouping,
		COUNT(DISTINCT unique_session_id) AS sessions,
		SUM(bounces) AS bounces,
		((SUM(bounces)/COUNT(DISTINCT unique_session_id))*100) AS bounce_rate
FROM (
		SELECT
				channelGrouping,
		    bounces,
				CONCAT(fullvisitorid, '-', visitid) AS unique_session_id
		FROM gms_project.data_combined
		GROUP BY 1,2,3
) t1
GROUP BY 1
ORDER BY 2 DESC;


-- Website Acquisition & Monetization by Channel
SELECT
		channelGrouping,
		COUNT(DISTINCT unique_session_id) AS sessions,
		SUM(bounces) AS bounces,
		((SUM(bounces)/COUNT(DISTINCT unique_session_id))) AS bounce_rate,
		(SUM(pageviews)/COUNT(DISTINCT unique_session_id)) AS avg_pagesonsite,
		(SUM(timeonsite)/COUNT(DISTINCT unique_session_id)) AS avg_timeonsite,
		SUM(CASE WHEN transactions >= 1 THEN 1 ELSE 0 END) AS conversions,
		((SUM(CASE WHEN transactions >= 1 THEN 1 ELSE 0 END)/COUNT(DISTINCT unique_session_id))) AS conversion_rate,
		SUM(transactionrevenue)/1e6 AS revenue
FROM (
		SELECT
			channelGrouping,
			bounces,
			pageviews,
			timeonsite,
			transactions,
			transactionrevenue,
			CONCAT(fullvisitorid, '-', visitid) AS unique_session_id
	FROM gms_project.data_combined
	GROUP BY 1,2,3,4,5,6,7
) t1
GROUP BY 1
ORDER BY 2 DESC;

SELECT
			channelGrouping,
			bounces,
			pageviews,
			timeonsite,
			transactions,
			transactionrevenue,
			CONCAT(fullvisitorid, '-', visitid) AS unique_session_id
FROM gms_project.data_combined
GROUP BY 1,2,3,4,5,6,7;

SELECT * FROM gms_project.data_combined
LIMIT 26;