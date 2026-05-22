--SQL Advance Case Study


--Q1--BEGIN 
	SELECT DISTINCT L.State 
	FROM Fact_Transactions F 
	JOIN Dim_Location L 
	ON F.IDLocation = L.IDLocation WHERE 
	YEAR(F.Date) >= 2005;
--Q1--END

--Q2--BEGIN
	SELECT TOP 1 L.State,
       SUM(F.Quantity) AS Total_Quantity
FROM Fact_Transactions AS F
JOIN Dim_Model AS M 
    ON F.IDModel = M.IDModel
JOIN Dim_Manufacturer MF 
    ON M.IDManufacturer = MF.IDManufacturer
JOIN Dim_Location L 
    ON F.IDLocation = L.IDLocation
WHERE MF.Manufacturer_Name = 'Samsung'
  AND L.Country = 'US'
GROUP BY L.State
ORDER BY Total_Quantity DESC;
--Q2--END

--Q3--BEGIN      
	SELECT M.Model_Name,
       L.State,
       L.ZipCode,
       COUNT(F.IDCustomer) AS Total_Transactions
FROM Fact_Transactions AS F
JOIN Dim_Model AS M 
    ON F.IDModel= M.IDModel
JOIN Dim_Location L 
    ON F.IDLocation = L.IDLocation
GROUP BY M.Model_Name, L.State, L.ZipCode;
--Q3--END

--Q4--BEGIN
SELECT TOP 1 Model_Name, Unit_price
FROM DIM_MODEL
ORDER BY Unit_price ASC;
--Q4--END

--Q5--BEGIN
SELECT DM.Model_Name, 
	AVG(FT.TotalPrice / FT.Quantity) AS Avg_Price 
FROM Fact_Transactions FT 
JOIN Dim_Model DM 
ON FT.IDModel = DM.IDModel 
WHERE DM.IDManufacturer IN 
	( SELECT TOP 5 DM2.IDManufacturer 
		FROM Fact_Transactions FT2 
		JOIN Dim_Model DM2 
		ON FT2.IDModel = DM2.IDModel 
		GROUP BY DM2.IDManufacturer
		ORDER BY SUM(FT2.Quantity) DESC )
		GROUP BY DM.Model_Name 
		ORDER BY Avg_Price;
--Q5--END

--Q6--BEGIN
SELECT DC.Customer_Name, 
	AVG(FT.TotalPrice) AS Avg_Amount 
FROM Fact_Transactions FT 
JOIN Dim_Customer DC 
ON FT.IDCustomer = DC.IDCustomer 
JOIN Dim_Date DD 
ON FT.Date = DD.[DATE] 
WHERE DD.[YEAR] = 2009 
GROUP BY DC.Customer_Name 
HAVING AVG(FT.TotalPrice) > 500;
--Q6--END
	
--Q7--BEGIN  
WITH RankedModels AS (
    SELECT top 5
        DD.[YEAR],
        FT.IDModel,
        COUNT(*) AS SalesCount,
        RANK() OVER (PARTITION BY DD.[YEAR] ORDER BY COUNT(*) DESC) AS RankByYear
    FROM FACT_TRANSACTIONS FT
    JOIN DIM_DATE DD ON FT.Date = DD.[DATE]
    GROUP BY DD.[YEAR], FT.IDModel
)
SELECT  DISTINCT DM.Model_Name
FROM RankedModels RM
JOIN DIM_MODEL DM ON RM.IDModel = DM.IDModel
WHERE RM.RankByYear <= 5
GROUP BY DM.Model_Name
HAVING COUNT(DISTINCT RM.[YEAR]) = 3;
 
--Q7--END	
--Q8--BEGIN
WITH RankedSales AS 
( SELECT DD.[YEAR], DMR.Manufacturer_Name, 
	SUM(FT.TotalPrice) AS Total_Sales, 
	RANK() OVER (PARTITION BY DD.[YEAR] ORDER BY SUM(FT.TotalPrice) DESC) AS Sales_Rank 
FROM Fact_Transactions FT 
JOIN Dim_Model DM 
ON FT.IDModel = DM.IDModel 
JOIN Dim_Manufacturer DMR 
ON DM.IDManufacturer = DMR.IDManufacturer 
JOIN Dim_Date DD 
ON FT.Date = DD.[DATE] 
GROUP BY DD.[YEAR], DMR.Manufacturer_Name ) SELECT YEAR, Manufacturer_Name, Total_Sales 
											FROM RankedSales 
											WHERE Sales_Rank = 2 AND YEAR IN (2009, 2010);
--Q8--END
--Q9--BEGIN
SELECT DISTINCT DMR.Manufacturer_Name 
FROM Fact_Transactions FT 
JOIN Dim_Model DM 
ON FT.IDModel = DM.IDModel 
JOIN Dim_Manufacturer DMR 
ON DM.IDManufacturer = DMR.IDManufacturer 
JOIN Dim_Date DD
ON FT.Date = DD.[DATE] 
WHERE DD.[YEAR] = 2010 
			AND DMR.IDManufacturer NOT IN 
			( SELECT DISTINCT DM2.IDManufacturer 
			FROM Fact_Transactions FT2 
			JOIN Dim_Model DM2 
			ON FT2.IDModel = DM2.IDModel 
			JOIN Dim_Date DD2 
			ON FT2.Date = DD2.[DATE] 
			WHERE DD2.[YEAR] = 2009 );
--Q9--END

--Q10--BEGIN
WITH top_c AS
(
SELECT TOP 5 IDCustomer
FROM FACT_TRANSACTIONS
GROUP BY IDCustomer
ORDER BY SUM(TotalPrice) DESC
)

SELECT c.Customer_Name, YEAR(d.[Date]) AS sale_year,
	AVG(f.TotalPrice) AS avg_spend, AVG(f.Quantity) AS avg_qty,
	SUM(f.TotalPrice) AS tot_spend, 
	100*(SUM(f.TotalPrice)-LAG(SUM(f.TotalPrice)) OVER(PARTITION BY Customer_Name ORDER BY YEAR(d.[Date])))/
	LAG(SUM(f.TotalPrice)) OVER(PARTITION BY Customer_Name ORDER BY YEAR(d.[Date])) AS perc_change
FROM FACT_TRANSACTIONS f
JOIN DIM_CUSTOMER c
ON f.IDCustomer=c.IDCustomer
JOIN DIM_DATE d
ON f.[Date]=d.[DATE]
WHERE f.IDCustomer IN (SELECT IDCustomer
						FROM top_c)
GROUP BY c.Customer_Name, YEAR(d.[Date]) 

--Q10--END



