-------------------------------------------------------------------------------
-- WINDOW FUNCTIONS
-------------------------------------------------------------------------------

-- Use database pda_sql
USE pda_sql2;
GO

----------------------------------------------------------------------------
-- LEVEL 1: CALCULATING SUMMARY WITH OVER()
---------------------------------------------------------------------------------

-- 1. Calculate the total cumulative sales (Sales) over time (OrderDate) from the EcomSales table.
-- Display OrderDate, Sales, and CumulativeSales (cumulative total).
-- Sort the results by OrderDate.
SELECT 
OrderDate, Sales,
SUM(Sales) OVER(ORDER BY OrderDate) AS "CumulativeSales"
FROM EcomSales es 
ORDER BY OrderDate

-- 2. Calculate the average revenue (AVG Sales) of each customer (CustomerID) without combining the products.
-- - Display CustomerID, Sales, and AvgCustomerSales (average revenue of that customer).
SELECT 
CustomerID, es.Sales, 
AVG(es.Sales) OVER (PARTITION BY CustomerID)  AS "AvgCustomerSales"
FROM EcomSales es 

-- 3. Find the largest order value (MAX Sales) in each region (RegionCode).
-- - Display RegionCode, Sales, and MaxRegionSales.
SELECT 
r.RegionCode, es.Sales, 
MAX(Sales) OVER (PARTITION BY r.RegionCode) AS "MaxRegionSales"
FROM Region r 
JOIN EcomSales es ON es.RegionCode = r.RegionCode

-------------------------------------------------------------------------------
-- LEVEL 2: RANKING FUNCTIONS
-------------------------------------------------------------------------------

-- Requirements:
-- 1. Rank products (ProductCode) by revenue (Sales) from high to low.
-- Display ProductCode, Sales, and Rank (using RANK()).
-- Products with the same revenue have the same rank and skip the next rank.
SELECT
ProductCode, Sales,
RANK() OVER(ORDER BY Sales DESC) AS "Rank"
FROM Ecomsales
ORDER BY Sales DESC

-- 2. Rank customers (CustomerID) by profit (Profit) from high to low.
-- - Display CustomerID, Profit, and DenseRank (using DENSE_RANK()).
-- - Products with the same profit have the same rank but do not skip to the next rank.

SELECT 
    CustomerID,
    Profit,
    DENSE_RANK() OVER (ORDER BY Profit DESC) AS "DenseRank"
FROM EcomSales
ORDER BY Profit DESC

-- 3. Number the orders (OrderID) by customer (CustomerID) in RowNum.
-- Display CustomerID, OrderID, OrderDate, and RowNum (using ROW_NUMBER()).
SELECT 
CustomerID, OrderID, OrderDate, 
ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY OrderDate) AS "RowNum"
FROM EcomSales es 

-------------------------------------------------------------------------------
-- LEVEL 3: VALUE FUNCTIONS
-------------------------------------------------------------------------------

-- 1. Calculate the difference in sales between the current order and the previous order of the same customer.
-- Display CustomerID, OrderDate, Sales, and SalesDifference.
-- Use LAG().
SELECT
CustomerID, OrderDate, Sales
, LAG (Sales) OVER(PARTITION BY CustomerID ORDER by OrderDate) AS "PreviousSales"
, Sales - LAG (Sales) OVER(PARTITION BY CustomerID) AS "SalesDifference"
FROM EcomSales es 

-- 2. Find the revenue of the next order (NextOrderSales) of the same customer.
-- Display CustomerID, OrderDate, Sales, and NextOrderSales.
-- Use LEAD()
SELECT
CustomerID, OrderDate, Sales
, LEAD (Sales) OVER(PARTITION BY CustomerID ORDER by OrderDate ASC) AS "NextOrderSales"
FROM EcomSales es 

-- 3. Find the revenue of the first order (FirstOrderSales) of each customer.
-- - Display CustomerID, OrderDate, Sales, and FirstOrderSales.
-- - Use FIRST_VALUE().
SELECT 
CustomerID, OrderDate, Sales
, FIRST_VALUE(Sales) OVER(PARTITION BY CustomerID ORDER BY OrderDate) AS "FirstOrderSales"
FROM EcomSales es 

-------------------------------------------------------------------------------
-- LEVEL 4: ADVANCED ANALYTICS
-------------------------------------------------------------------------------

-- 1. Calculate the revenue contribution ratio (%) of each product in total revenue.
-- - Display ProductCode, Sales, and SalesPercentage.
-- Use SUM() OVER().
SELECT 
    ProductCode,
    Sales,
    SUM(Sales) OVER() AS "TotalSales",
    -- 100.00 * (Sales / SUM(Sales) OVER ()) AS "SalesPercentage"
    CASE 
        WHEN SUM(Sales) OVER () = 0 THEN 0
        ELSE (CAST(Sales AS DECIMAL(10, 2)) / SUM(Sales) OVER () * 100)
    END AS SalesPercentage
FROM EcomSales;

-- 2. Calculate the 3-month moving average of sales.
-- - Display OrderDate, Sales, and MovingAvg.
-- - Use AVG() with ROWS BETWEEN.
SELECT 
    OrderDate,
    Sales,
    AVG(Sales) OVER (ORDER BY OrderDate ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS MovingAvg
FROM EcomSales es
ORDER BY OrderDate

-- 3. Group customers into 4 groups (quartiles) based on total revenue.
-- - Display CustomerID, TotalSales, and RevenueQuartile.
-- - Use NTILE(4).
WITH CustomerTotals AS (
    SELECT 
        CustomerID,
        SUM(Sales) AS TotalSales
    FROM dbo.EcomSales
    GROUP BY CustomerID
)
SELECT 
    CustomerID,
    TotalSales,
    NTILE(4) OVER (ORDER BY TotalSales) AS RevenueQuartile
FROM CustomerTotals
ORDER BY TotalSales DESC;