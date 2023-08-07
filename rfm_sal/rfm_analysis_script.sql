SELECT * FROM Sale.Superstore;

DESCRIBE Sale.Superstore;

SET sql_safe_updates = 0;

-- Update Order Date to proper format
UPDATE Sale.Superstore
SET Order_Date = CASE
	WHEN Order_Date LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(Order_Date, '%m/%d/%Y'), '%Y/%m/%d')
    ELSE NULL
END;

-- Convert text 'Order_Date' to date
ALTER TABLE Sale.Superstore
MODIFY COLUMN Order_Date DATE;

-- Update Ship Date to proper format
UPDATE Sale.Superstore
SET Ship_Date = CASE
	WHEN Ship_Date LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(Ship_Date, '%m/%d/%Y'), '%Y/%m/%d')
    ELSE NULL
END;

-- Convert text 'Order_Date' to date
ALTER TABLE Sale.Superstore
MODIFY COLUMN Ship_Date DATE;

-- Add Order_Year column
ALTER TABLE Sale.Superstore
ADD COLUMN Order_Year INT;

UPDATE Sale.Superstore
SET Order_Year = YEAR(Order_Date);

-- Add Order_Month column
ALTER TABLE Sale.Superstore
ADD COLUMN Order_Month INT;

UPDATE Sale.Superstore
SET Order_Month = MONTH(Order_Date);

-- Analysis Part

-- Checking unique values
SELECT MIN(Order_Date), MAX(Order_Date) FROM Sale.Superstore;
SELECT DISTINCT Segment FROM Sale.Superstore;
SELECT DISTINCT Country FROM Sale.Superstore;
SELECT DISTINCT Category FROM Sale.Superstore;
SELECT DISTINCT Sub_Category FROM Sale.Superstore;


-- 1. Group Sales by Category
SELECT Category, ROUND(SUM(Sales),0) AS Revenue
FROM Sale.Superstore
GROUP BY Category
ORDER BY Revenue DESC;

-- 2.Group Sales by Year
SELECT Order_Year, ROUND(SUM(Sales),0) Revenue
FROM Sale.Superstore
GROUP BY Order_Year
ORDER BY Revenue DESC;

-- 3. The best month for sales in specific year
-- 3.1 What is the best month for sales in 2014?
SELECT  Order_Year,
		Order_Month, 
		SUM(Sales) AS Revenue,
		COUNT(Order_ID) AS Frequency
FROM Sale.Superstore
WHERE Order_Year = 2014 -- Change year to see the rest
GROUP BY Order_Year,Order_Month
ORDER BY Frequency DESC;


-- 4. Who is the best customer?
-- Create RFM table
DROP TABLE IF EXISTS RFM;

CREATE TABLE RFM AS
WITH RFM AS
(
	SELECT Customer_Name, 
			SUM(Sales) AS MonetaryValue,
			AVG(Sales) AS AVGMonetaryValue,
			COUNT(Order_ID) AS Frequency,
			MAX(Order_Date) AS Last_order_date,
			(SELECT MAX(Order_Date) FROM Sale.Superstore) AS Max_order_date,
			DATEDIFF((SELECT MAX(Order_Date) FROM Sale.Superstore), MAX(Order_Date)) AS Recency
	FROM Sale.Superstore
	GROUP BY Customer_Name
),
RFM_calc AS 
(
	SELECT r.*,
		NTILE(4) OVER (ORDER BY Recency DESC) AS R_score,
		NTILE(4) OVER (ORDER BY Frequency) AS F_score,
		NTILE(4) OVER (ORDER BY MonetaryValue) AS M_score
	FROM RFM AS R
)
SELECT 
	c.*, R_score + F_score + M_score AS RFM_score,
	CONCAT(CAST(R_score AS CHAR), CAST(F_score AS CHAR), CAST(M_score AS CHAR)) AS RFM_overall
FROM RFM_calc AS C;

SELECT * FROM RFM;

-- Customer Segmentation
SELECT Customer_Name, R_score, F_score, M_score,
	CASE
            WHEN RFM_overall IN (111, 112, 113, 114, 121, 122, 123, 131, 132, 211, 212, 214, 141) THEN 'Lost_Customer'
            WHEN RFM_overall IN (124, 133, 134, 142, 143, 144, 241, 242, 243, 244, 334, 343, 344) THEN 'Slipping away, cannot lose'
            WHEN RFM_overall IN (311, 312, 314, 331, 411, 413, 412) THEN 'New customer'
            WHEN RFM_overall IN (213, 221, 222, 223, 224, 231, 232, 233, 234, 322) THEN 'Potential churners'
            WHEN RFM_overall IN (323, 333, 321, 324, 342, 421, 422, 332, 423, 424, 431, 432) THEN 'Active'
            WHEN RFM_overall IN (441, 442, 433, 434, 443, 444) THEN 'Loyal'
	END RFM_segment
FROM RFM;

--  Group customers into different recency segments
SELECT
    Recency_Last_Order,
    COUNT(Customer_Name) AS CustomerCount
FROM (
    SELECT
        Customer_Name,
        Last_Order_Date,
        Recency_Months,
        CASE
            WHEN Recency_Months >= 0 AND Recency_Months <= 5 THEN '0-5 months'
            WHEN Recency_Months > 5 AND Recency_Months <= 10 THEN '5-10 months'
            WHEN Recency_Months > 10 AND Recency_Months <= 15 THEN '10-15 months'
            WHEN Recency_Months > 15 AND Recency_Months <= 20 THEN '15-20 months'
            ELSE '20 months+'
        END AS Recency_Last_Order,
        CASE
            WHEN Recency_Months >= 0 AND Recency_Months <= 5 THEN 1
            WHEN Recency_Months > 5 AND Recency_Months <= 10 THEN 2
            WHEN Recency_Months > 10 AND Recency_Months <= 15 THEN 3
            WHEN Recency_Months > 15 AND Recency_Months <= 20 THEN 4
            ELSE 5
        END AS Recency_Group
    FROM (
        SELECT
            Customer_Name,
            MAX(Order_Date) AS Last_Order_Date,
            PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM '2017-12-30'), EXTRACT(YEAR_MONTH FROM MAX(Order_Date))) AS Recency_Months
        FROM Sale.Superstore
        GROUP BY Customer_Name
    ) AS Customer_Recency
) AS CM_Recency_Groups
GROUP BY Recency_Last_Order, Recency_Group
ORDER BY Recency_Group;


-- Create the frequency of orders for last 12 months
WITH Customer_Orders AS
(
    SELECT
        Customer_Name,
        COUNT(Order_ID) AS OrderCount
    FROM Sale.Superstore
    WHERE Order_Date >= DATE_SUB('2017-12-30', INTERVAL 12 MONTH)
    GROUP BY Customer_Name
),
Frequency_Order_Groups AS
(
    SELECT
        C.Customer_Name,
        C.OrderCount,
        CASE
            WHEN C.OrderCount >= 0 AND C.OrderCount < 1 THEN '0-1 orders'
            WHEN C.OrderCount >= 1 AND C.OrderCount < 2 THEN '1-2 orders'
            WHEN C.OrderCount >= 2 AND C.OrderCount < 5 THEN '2-5 orders'
            WHEN C.OrderCount >= 5 AND C.OrderCount < 10 THEN '5-10 orders'
            ELSE '10 orders+'
        END AS Frequency_Order
    FROM Customer_Orders AS C
)
SELECT
    Frequency_Order,
    COUNT(Customer_Name) AS CustomerCount
FROM Frequency_Order_Groups
GROUP BY Frequency_Order;


-- Create the monetary value for last 12 months
WITH Customer_Monetary AS
(
    SELECT
        Customer_Name,
        SUM(Sales) AS Sales
    FROM Sale.Superstore
    WHERE Order_Date >= DATE_SUB('2017-12-30', INTERVAL 12 MONTH)
    GROUP BY Customer_Name
),
Monetary_Calc AS
(
    SELECT
        CM.Customer_Name,
        CM.Sales,
        NTILE(5) OVER (ORDER BY CM.Sales) AS Monetary_Group
    FROM Customer_Monetary AS CM
)
SELECT
    CASE
        WHEN Sales >= 0 AND Sales < 150 THEN '> $150'
        WHEN Sales >= 150 AND Sales < 300 THEN '$150-$300'
        WHEN Sales >= 300 AND Sales < 600 THEN '$300-$600'
        WHEN Sales >= 600 AND Sales < 1500 THEN '$600-$1700'
        ELSE '$1700+'
    END AS MonetaryValue,
    COUNT(Customer_Name) AS CustomerCount
FROM Monetary_Calc
GROUP BY MonetaryValue;
