-- 1. Create the DataBase 
CREATE DATABASE IF NOT EXISTS Revenue_Intelligence;
USE Revenue_Intelligence;

-- 2. DROP the tables if already exist to avoid the error 
SET FOREIGN_KEY_CHECKS = 0 ; -- Temporarly disable checks to allow dropping 
DROP TABLE IF EXISTS Fact_Sales ;
DROP TABLE IF EXISTS Dim_users ; 
DROP TABLE IF EXISTS Dim_Products ; 
DROP TABLE IF EXISTS Dim_Channels ; 
SET FOREIGN_KEY_CHECKS = 1 ; -- RE-enable checks 

-- 3. Create the Tables for the Star SChema 
CREATE TABLE Dim_Users (
   User_Id INT PRIMARY KEY ,
   Region VARCHAR (50)
   );

CREATE TABLE Dim_Products (
   Product_Id INT AUTO_INCREMENT PRIMARY KEY ,
   Product_Category VARCHAR (100)
   );
   
CREATE TABLE Dim_Channels (
   Channel_Id INT AUTO_INCREMENT PRIMARY KEY ,
   Channel_Name VARCHAR (100)
   );
   
CREATE TABLE Fact_Sales(                  -- Heart of the Engine 
   Transaction_Id INT PRIMARY KEY ,
   User_Id INT , 
   Product_Id INT , 
   Channel_Id INT , 
   Order_Date DATE , 
   Revenue DECIMAL (10,2),
   -- THESE LINKS ENSURE DATA INTEGRITY 
   FOREIGN KEY (User_Id) REFERENCES Dim_Users(User_Id),
   FOREIGN KEY (Product_Id) REFERENCES Dim_Products(Product_Id),
   FOREIGN KEY (Channel_Id) REFERENCES Dim_Channels(Channel_Id)
);

SELECT COUNT(*) AS Total_Rows_Imported FROM Raw_Sales;

USE revenue_intelligence;
SHOW TABLES;

ALTER TABLE enterprise_revenue_25k RENAME TO Raw_Sales;
SELECT COUNT(*) AS Total_Rows_Imported FROM Raw_Sales ; 

-- Now, load it using GROUP BY to guarantee uniqueness for the Primary Key

INSERT INTO Dim_Users (User_ID, Region)
SELECT User_ID, MIN(Region) 
FROM Raw_Sales 
WHERE User_ID <= 4990
GROUP BY User_ID;

-- 2. Fill Dim_Products (Categories only)
INSERT INTO Dim_Products (Product_Category)
SELECT DISTINCT Product_Category 
FROM Raw_Sales;

-- 3. Fill Dim_Channels (Excluding 'Internal Test')
INSERT INTO Dim_Channels (Channel_Name)
SELECT DISTINCT Channel 
FROM Raw_Sales 
WHERE Channel != 'Internal Test';

-- 4. Fill Fact_Sales (The Heart of the Engine)
INSERT INTO Fact_Sales (Transaction_ID, User_ID, Product_ID, Channel_ID, Order_Date, Revenue)
SELECT 
    r.Transaction_ID,
    r.User_ID,
    p.Product_ID,
    c.Channel_ID,
    STR_TO_DATE(r.Order_Date, '%Y-%m-%d'), 
    r.Revenue
FROM Raw_Sales r
JOIN Dim_Products p ON r.Product_Category = p.Product_Category
JOIN Dim_Channels c ON r.Channel = c.Channel_Name
WHERE r.Revenue IS NOT NULL 
AND r.User_ID <= 4990
-- We use GROUP BY or DISTINCT here just in case of duplicate transaction IDs
GROUP BY r.Transaction_ID;

-- First, empty the Fact table to ensure no partial data remains
TRUNCATE TABLE Fact_Sales;

-- Now run the compliant script
INSERT INTO Fact_Sales (Transaction_ID, User_ID, Product_ID, Channel_ID, Order_Date, Revenue)
SELECT 
    r.Transaction_ID,
    ANY_VALUE(r.User_ID),
    ANY_VALUE(p.Product_ID),
    ANY_VALUE(c.Channel_ID),
    ANY_VALUE(STR_TO_DATE(r.Order_Date, '%Y-%m-%d')), 
    ANY_VALUE(r.Revenue)
FROM Raw_Sales r
JOIN Dim_Products p ON r.Product_Category = p.Product_Category
JOIN Dim_Channels c ON r.Channel = c.Channel_Name
WHERE r.Revenue IS NOT NULL 
AND r.User_ID <= 4990
GROUP BY r.Transaction_ID;

SELECT 'Users' AS TableName , COUNT(*) AS Row_Count FROM Dim_Users 
UNION ALL 
SELECT 'Products',COUNT(*) FROM Dim_products 
UNION ALL 
SELECT 'Channel',COUNT(*) FROM Dim_Channels 
UNION ALL 
SELECT 'Fact_Sales', COUNT(*) FROM Fact_Sales;

-- 1. The Marketing ROI (Return on Investment)

SELECT 
    c.Channel_Name,
    COUNT(f.Transaction_ID) AS Total_Orders,
    SUM(f.Revenue) AS Total_Revenue,
    ROUND(AVG(f.Revenue), 2) AS Average_Order_Value
FROM Fact_Sales f
JOIN Dim_Channels c ON f.Channel_ID = c.Channel_ID
GROUP BY c.Channel_Name
ORDER BY Total_Revenue DESC; 

-- 2. The Customer LifeCycle (Loyalty)

WITH Top_Whales AS (
    -- 1. Identify the Top 5 spenders
    SELECT 
        u.User_ID,
        u.Region,
        SUM(f.Revenue) AS LifeTime_Value,
        DENSE_RANK() OVER(ORDER BY SUM(f.Revenue) DESC) AS VIP_RANK
    FROM Fact_Sales f
    JOIN Dim_Users u ON f.User_ID = u.User_ID -- Fixed: Added 'u' alias here
    GROUP BY u.User_ID, u.Region
    LIMIT 5
),
Fav_Products AS (
    -- 2. Find the most frequent product for EVERY user
    SELECT 
        f.User_ID,
        p.Product_Category,
        COUNT(*) as Times_Bought,
        ROW_NUMBER() OVER(PARTITION BY f.User_ID ORDER BY COUNT(*) DESC) as Prod_Rank
    FROM Fact_Sales f
    JOIN Dim_Products p ON f.Product_ID = p.Product_ID
    GROUP BY f.User_ID, p.Product_Category
)
-- 3. Final Report
SELECT 
    w.VIP_RANK,
    w.User_ID,
    w.Region,
    w.LifeTime_Value,
    fp.Product_Category AS FAV_PROD
FROM Top_Whales w
JOIN Fav_Products fp ON w.User_ID = fp.User_ID -- Fixed: Corrected 'fp.UserId' to 'fp.User_ID'
WHERE fp.Prod_Rank = 1
ORDER BY w.VIP_RANK; 

-- Month over Month sales growth percentage (MOM) 

WITH Monthly_Totals AS (
   SELECT
      DATE_FORMAT(Order_Date , '%Y-%m') AS Sales_Month ,
      SUM(Revenue) AS Monthly_Revenue
FROM Fact_Sales
GROUP BY 1
)
SELECT 
   Sales_Month ,
   Monthly_Revenue,
   LAG(Monthly_Revenue)OVER(ORDER BY Sales_Month) AS Prev_Mon_Rev,
   ROUND(((Monthly_Revenue - LAG(Monthly_Revenue)OVER(ORDER BY Sales_Month))/LAG(Monthly_Revenue)OVER(ORDER BY Sales_Month)) * 100,2) AS Growth_Percentage 
FROM Monthly_Totals;

-- 4. Customer Retention Risk 

WITH Last_Seen AS (
    SELECT 
        User_ID,
        MAX(Order_Date) AS Last_Purchased_Date,
        SUM(Revenue) AS Total_Spent
    FROM Fact_Sales
    GROUP BY User_ID
)
SELECT 
    User_ID,
    Total_Spent,
    DATEDIFF((SELECT MAX(Order_Date) FROM Fact_Sales), Last_Purchased_Date) AS Days_Since_Last_Order,
    CASE 
        WHEN DATEDIFF((SELECT MAX(Order_Date) FROM Fact_Sales), Last_Purchased_Date) > 90 THEN 'CHURNED'
        WHEN DATEDIFF((SELECT MAX(Order_Date) FROM Fact_Sales), Last_Purchased_Date) > 60 THEN 'AT RISK'
        ELSE 'ACTIVE'
    END AS Retention_Risk
FROM Last_Seen 
WHERE DATEDIFF((SELECT MAX(Order_Date) FROM Fact_Sales), Last_Purchased_Date) > 60
ORDER BY Total_Spent DESC;  

