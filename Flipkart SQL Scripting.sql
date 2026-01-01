-- creating database flipkard

create database flipkart;
use flipkart;
--                                               TASK 1
-- inserting all the tables
select *from deliveryagents;
select *from orders;
select *from routes;
select *from shipment;
select *from warehouses;
-- all the files are inserted

-- Identify and delete duplicate Order_ID records.

SELECT order_id, COUNT(*) 
FROM orders 
GROUP BY order_id 
HAVING COUNT(*) > 1;
-- there are no dulicate order_id

-- Replace null Traffic_Delay_Min with the average delay for that route.

select *from shipment;

SELECT AVG(Delay_Minutes) AS Average_Delay
FROM shipment	
WHERE Delay_Minutes IS NOT NULL;

UPDATE shipment
SET Delay_Minutes = 60
WHERE Delay_Minutes = 0;

update shipment set Delay_Reason= 'Avg delay' WHERE Delay_Reason= 'None';

select * from shipment;

-- Convert all date columns into YYYY-MM-DD format using SQL functions

-- 						FOR SHIPMENT

select*from orders; -- change Order_Date, Expected_Delivery_Date, Actual_Delivery_Date
select*from shipment; -- change Checkpoint_Time
--                         FOR SHIPMENT
	SELECT Checkpoint_Time
	FROM shipment
	WHERE STR_TO_DATE(Checkpoint_Time, '%d-%m-%Y %H.%i') IS NULL;
	
	UPDATE shipment
	SET Checkpoint_Time = STR_TO_DATE(Checkpoint_Time, '%d-%m-%Y %H.%i')
	WHERE STR_TO_DATE(Checkpoint_Time, '%d-%m-%Y %H.%i') IS NOT NULL;

	ALTER TABLE shipment
	MODIFY Checkpoint_Time DATETIME;

--                     FOR ORDERS

SELECT Order_Date
	FROM orders
	WHERE STR_TO_DATE(Order_Date,'%d-%m-%Y %H.%i') is null;

UPDATE   orders
	SET Order_Date= STR_TO_DATE(Order_Date, '%d-%m-%Y %H.%i')
	WHERE STR_TO_DATE(Order_Date, '%d-%m-%Y %H.%i') IS NOT NULL;

ALTER TABLE  orders
	MODIFY Order_Date DATETIME;

select * from orders;

SELECT Expected_Delivery_Date
	FROM orders
	WHERE STR_TO_DATE(Expected_Delivery_Date,'%d-%m-%Y %H.%i') is null;

UPDATE   orders
	SET Expected_Delivery_Date= STR_TO_DATE(Expected_Delivery_Date, '%d-%m-%Y %H.%i')
	WHERE STR_TO_DATE(Expected_Delivery_Date, '%d-%m-%Y %H.%i') IS NOT NULL;

ALTER TABLE  orders
	MODIFY Expected_Delivery_Date DATETIME;

select * from orders;


SELECT Actual_Delivery_Date
	FROM orders
	WHERE STR_TO_DATE(Actual_Delivery_Date,'%d-%m-%Y %H.%i') is null;

UPDATE   orders
	SET Actual_Delivery_Date= STR_TO_DATE(Actual_Delivery_Date, '%d-%m-%Y %H.%i')
	WHERE STR_TO_DATE(Actual_Delivery_Date, '%d-%m-%Y %H.%i') IS NOT NULL;

ALTER TABLE  orders
	MODIFY Actual_Delivery_Date DATETIME;

select * from orders;

-- Ensure that no Actual_Delivery_Date is before Order_Date (flag such records)

select * from orders;

SELECT 
  Order_Date,
  Actual_Delivery_Date,
  CASE 
    WHEN Actual_Delivery_Date < Order_Date THEN 'Invalid'
    ELSE 'Valid'
  END AS Delivery_Date_Validation
FROM orders;

ALTER TABLE orders
ADD COLUMN Delivery_Date_Validation VARCHAR(10) 
GENERATED ALWAYS AS (
  CASE 
    WHEN Actual_Delivery_Date < Order_Date THEN 'Invalid'
    ELSE 'Valid'
  END
);

ALTER TABLE  orders
ADD CONSTRAINT Valid_Delivery_Date 
CHECK (Actual_Delivery_Date >= Order_Date);

select * from orders;


--                                                    TASK 2

-- Calculate delivery delay (in days) for each order
select * from orders ;

SELECT 
  Order_ID,
  Expected_Delivery_Date,
  Actual_Delivery_Date,
  DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) AS Delivery_Delay
FROM orders;

-- Find Top 10 delayed routes based on average delay days.

select * from routes;

SELECT 
  Route_ID,
  (AVG(Average_Travel_Time_Min + Traffic_Delay_Min) / 1440.0) AS Average_Delay_Days
FROM routes
GROUP BY Route_ID
ORDER BY Average_Delay_Days DESC
LIMIT 10;


-- Use window functions to rank all orders by delay within each warehouse.

SELECT 
  Order_ID,
  Warehouse_ID,
  DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) AS Delay_Days,
  DENSE_RANK() OVER (PARTITION BY Warehouse_ID ORDER BY DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date)desc ) AS Delay_Rank
FROM orders 
WHERE Actual_Delivery_Date IS NOT NULL;



--                                                TASK 3

-- For each route, calculate Average delivery time (in days),Average traffic delay,
-- Distance-to-time efficiency ratio: Distance_KM / Average_Travel_Time_Min.

select * from deliveryagents;

-- Average delivery time (in days)


SELECT 
  Route_ID,
  (Average_Travel_Time_Min + Traffic_Delay_Min) / 1440.0 AS Average_Delivery_Time_Days
FROM routes;



SELECT 
  Route_ID,
  FLOOR(Average_Delivery_Time_Days) AS days,
  FLOOR((Average_Delivery_Time_Days - FLOOR(Average_Delivery_Time_Days)) * 24) AS hours,
  ROUND(((Average_Delivery_Time_Days - FLOOR(Average_Delivery_Time_Days)) * 24 - FLOOR((Average_Delivery_Time_Days - FLOOR(Average_Delivery_Time_Days)) * 24)) * 60) AS minutes
FROM (
  SELECT 
    Route_ID,
    (Average_Travel_Time_Min + Traffic_Delay_Min) / 1440.0 AS Average_Delivery_Time_Days
  FROM routes
) AS subquery;


-- Average traffic delay.

select * from routes ;

select avg(Traffic_Delay_Min) as "Average Traffic Delay" from routes;

-- Distance-to-time efficiency ratio: Distance_KM / Average_Travel_Time_Min.

select Route_ID, sum(Distance_KM)/ sum(Average_Travel_Time_Min) as Distance_to_time_efficiency_ratio from routes 
group by Route_ID order by Distance_to_time_efficiency_ratio desc;

-- Identify 3 routes with the worst efficiency ratio.

SELECT
    Route_ID,
    SUM(Distance_KM),
    SUM(Average_Travel_Time_Min),
    (SUM(Distance_KM) / SUM(Average_Travel_Time_Min)) AS Worst_Route
FROM
    routes
GROUP BY
    Route_ID
ORDER BY
    Worst_Route DESC
LIMIT 3;

--  Find routes with >20% delayed shipments.

WITH shipment_delays AS (
    -- Identify if each shipment has any delays
    SELECT 
        Tracking_ID,
        Order_ID,
        MAX(CASE WHEN Delay_Minutes > 0 THEN 1 ELSE 0 END) AS is_delayed,
        SUM(COALESCE(Delay_Minutes, 0)) AS Total_Delay_Minutes
    FROM shipment
    GROUP BY Tracking_ID, Order_ID
),
route_delay_stats AS (
    -- Calculate delay statistics per route
    SELECT 
        r.Route_ID,
        r.Start_Location,
        r.End_Location,
        r.Distance_KM,
        r.Average_Travel_Time_Min,
        COUNT(DISTINCT o.Order_ID) AS Total_Shipments,
        SUM(sd.is_delayed) AS Delayed_Shipments,
        ROUND(100.0 * SUM(sd.is_delayed) / COUNT(DISTINCT o.Order_ID), 2) AS Delay_Percentage,
        ROUND(AVG(sd.total_delay_minutes), 2) AS Avg_Delay_Minutes
    FROM routes r
    INNER JOIN orders o ON r.Route_ID = o.Route_ID
    INNER JOIN shipment_delays sd ON o.Order_ID = sd.Order_ID
    GROUP BY r.Route_ID, r.Start_Location, r.End_Location, r.Distance_KM, r.Average_Travel_Time_Min
)
SELECT 
    Route_ID,
    Start_Location,
    End_Location,
    Distance_KM,
    Average_Travel_Time_Min,
    Total_Shipments,
    Delayed_Shipments,
    Delay_Percentage,
    Avg_Delay_Minutes
FROM route_delay_stats
WHERE delay_percentage > 0.2
ORDER BY delay_percentage DESC, total_shipments DESC;


select * from routes;

-- Recommend potential routes for optimization.

-- Routes RT_08 (Pune)  and RT_15  (Hyderabad) seem to be the main trouble spots, with  delays of about 90 and 87 minutes.   
--  It might help to look into traffic patterns or try  alternate routes  to ease congestion and  speed things up.   

--                                                 			TASK 4

-- ● Find the top 3 warehouses with the highest average processing time.

SELECT* FROM warehouses;

SELECT * FROM warehouses order by Average_Processing_Time_Min DESC limit 3;

--  Calculate total vs. delayed shipments for each warehouse.

SELECT 
  o.Warehouse_ID, 
  COUNT(DISTINCT o.Order_ID) AS Total_Shipments, 
  SUM(CASE WHEN s.Delay_Minutes > 0 THEN 1 ELSE 0 END) AS Delayed_Shipments, 
  (SUM(CASE WHEN s.Delay_Minutes > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT o.Order_ID)) AS Delay_Percentage
FROM 
  orders o
JOIN 
  shipment s ON o.Order_ID = s.Order_ID
GROUP BY 
  o.Warehouse_ID
ORDER BY 
  Delay_Percentage DESC;


-- Use CTEs to find bottleneck warehouses where processing time > global average.

WITH WarehouseStats AS (
    -- CTE #1: Calculate avg processing time per warehouse
    SELECT 
        Warehouse_ID,
        AVG(Average_Processing_Time_Min) AS Avg_Processing_Time
    FROM warehouses
    GROUP BY Warehouse_ID
),
GlobalAvg AS (
    -- CTE #2: Calculate the global avg processing time
    SELECT AVG(Average_Processing_Time_Min) AS Global_Avg_Time
    FROM warehouses
)

-- Final Select: Compare and filter bottlenecks
SELECT 
    w.Warehouse_ID,
    w.Avg_Processing_Time,
    g.Global_Avg_Time
FROM WarehouseStats w
CROSS JOIN GlobalAvg g
WHERE w.Avg_Processing_Time > g.Global_Avg_Time;

--  Rank warehouses based on on-time delivery percentage.

SELECT* FROM warehouses;
SELECT* FROM deliveryagents;

WITH Warehouse_Delivery_Stats AS (
    SELECT 
        w.Warehouse_ID,
        w.Warehouse_Name,
        w.City,
        w.Processing_Capacity,
        w.Average_Processing_Time_Min,
        COUNT(o.Order_ID) AS Total_Orders,
        SUM(CASE 
            WHEN o.Actual_Delivery_Date <= o.Expected_Delivery_Date THEN 1 
            ELSE 0 
        END) AS On_Time_Deliveries,
        SUM(CASE 
            WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date THEN 1 
            ELSE 0 
        END) AS delayed_Deliveries,
        SUM(CASE 
            WHEN o.Actual_Delivery_Date IS NULL THEN 1 
            ELSE 0 
        END) AS Pending_Deliveries,
        ROUND(100.0 * SUM(CASE 
            WHEN o.Actual_Delivery_Date <= o.Expected_Delivery_Date THEN 1 
            ELSE 0 
        END) / COUNT(o.Order_ID), 2) AS On_Time_Delivery_Percentage
    FROM warehouses w
    LEFT JOIN orders o ON w.Warehouse_ID = o.Warehouse_ID
    GROUP BY w.Warehouse_ID, w.Warehouse_Name, w.City, w.Processing_Capacity, w.Average_Processing_Time_Min
)
SELECT 
    RANK() OVER (ORDER BY On_Time_Delivery_Percentage DESC, total_orders DESC) AS warehouse_rank,
    Warehouse_ID,
    Warehouse_Name,
    Processing_Capacity,
    Average_Processing_Time_Min,
    On_Time_delivery_Percentage
FROM Warehouse_Delivery_Stats
WHERE Total_Orders > 0  -- Only include warehouses with orders
ORDER BY Warehouse_Rank;

--         										TASK 5

-- Rank agents (per route) by on-time delivery percentage

select * from deliveryagents;

select Agent_ID,Agent_Name, rank() over(order by On_Time_Delivery_Percentage desc) as Rank_By_Agent from deliveryagents;

-- Find agents with on-time % < 80%.

SELECT 
  Agent_ID, 
  Agent_Name,
  Route_ID,
  Rank_By_Agent
FROM (
  SELECT 
    Agent_ID, On_Time_Delivery_Percentage,
    Agent_Name, 
    Route_ID,
    PERCENT_RANK() OVER (ORDER BY On_Time_Delivery_Percentage DESC) AS Percent_Rank_By_Agent,
    DENSE_RANK() OVER (ORDER BY On_Time_Delivery_Percentage DESC) AS Rank_By_Agent
  FROM deliveryagents
) AS subquery
WHERE Percent_Rank_By_Agent <= 0.8;

--  Compare average speed of top 5 vs bottom 5 agents using subquerie

SELECT 
    'Top 5 Agents' AS Category,
    AVG(Avg_Speed_KMPH) AS Average_Speed
FROM
    (SELECT 
        Agent_ID, Avg_Speed_KMPH
    FROM
        deliveryagents
    ORDER BY Avg_Speed_KMPH DESC
    LIMIT 5) AS top_agents 
UNION ALL SELECT 
    'Bottom 5 Agents' AS Category,
    round(AVG(Avg_Speed_KMPH),2) AS Average_Speed
FROM
    (SELECT 
        Agent_ID, Avg_Speed_KMPH
    FROM
        deliveryagents
    ORDER BY Avg_Speed_KMPH ASC
    LIMIT 5) AS bottom_agents;

--  Suggest training or workload balancing strategies for low performers

-- Some agents with low on-time  deliveries might just  need extra help with  routes and time planning.     
-- A short  refresher on handling traffic  and managing deliveries could make a big difference.    
-- Pairing them with top performers can help them learn  faster.
--  It may also help  to share the tougher routes more evenly  and give a bit more time for busy areas. 
-- Regular check-ins and feedback will keep everyone  on track and improving.  

-- 												TASK 6

-- For each order, list the last checkpoint and time.

select Tracking_ID, Order_ID, Checkpoint_Time as Last_Checkpoint_Time from shipment;

--  Find the most common delay reasons (excluding None).

select distinct(Delay_Reason) from shipment orderby ;

SELECT 
  Delay_Reason,
  COUNT(*) AS Count_Delay_Reason,
  RANK() OVER (ORDER BY COUNT(*) DESC) AS 'Rank'
FROM shipment
GROUP BY Delay_Reason;

--  Identify orders with >2 delayed checkpoints

SELECT 
  Order_ID,
  COUNT(Tracking_ID) AS delayed_checkpoints
FROM shipment
WHERE Delay_Minutes > 0
GROUP BY Order_ID
HAVING COUNT(Tracking_ID) > 2;


--											TASK 7

-- Average Delivery Delay per Region (Start_Location). -- select * from orders;

select Start_Location,End_Location,round(avg(Traffic_Delay_Min+Average_Travel_Time_Min),2) as 'Avrage_Delivery_Delay' from routes 
group by Start_Location,End_Location ;

-- On-Time Delivery % = (Total On-Time Deliveries / Total Deliveries) * 100.

SELECT 
  (SUM(CASE WHEN Actual_Delivery_Date <= Expected_Delivery_Date THEN 1 ELSE 0 END) / 
   COUNT(Order_ID)) * 100 AS 'On Time Delivery Percentage'
FROM orders;

-- Average Traffic Delay per Route.

select Route_ID,round(avg(Traffic_Delay_Min),2) as 'Average_Traffic_Delay'  from routes group by Route_ID;





