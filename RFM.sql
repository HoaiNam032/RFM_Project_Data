
select CustomerID ,GMV ,DATEDIFF(day, max(Purchase_Date), '2022-09-01') as recency ,
		round(1.0* count(ct.CustomerID)/DATEDIFF(year, created_date, '2022-09-01'),2) as Frequency, 
		round(1.0* sum(GMV)/DATEDIFF(year, created_date, '2022-09-01'),2) as Monetary,
		ROW_NUMBER() over (order by  DATEDIFF(day, max(Purchase_Date), '2022-09-01')) as rn_recency,
		ROW_NUMBER() over (order by round(1.0* count(ct.CustomerID)/DATEDIFF(year, created_date, '2022-09-01'),2)) as rn_frequency,
		ROW_NUMBER() over (order by round(1.0* sum(GMV)/DATEDIFF(year, created_date, '2022-09-01'),2)) as rn_monetary
into ##calculation
from Customer_Transaction ct 
join Customer_Registered cr on ct.CustomerID = cr.ID 
where CustomerID != 0
group by CustomerID, created_date, GMV

select *, CASE 
	when recency < (select recency from ##calculation
								   where rn_recency = (
								   select cast(count(DISTINCT(CustomerID))*0.25 as int) FROM ##calculation)) then '4'
	when recency >= (select recency from ##calculation
									where rn_recency = (
								    select cast(count(DISTINCT(CustomerID))*0.25 as int) FROM ##calculation))
	and recency < (select recency from ##calculation
									where rn_recency = (
								    select cast(count(DISTINCT(CustomerID))*0.5 as int) FROM ##calculation)) then '3'
	when recency >= (select recency from ##calculation
									where rn_recency = (
								    select cast(count(DISTINCT(CustomerID))*0.5 as int) FROM ##calculation))
	and recency < (select recency from ##calculation
									where rn_recency = (
								    select cast(count(DISTINCT(CustomerID))*0.75 as int) FROM ##calculation)) then '2'  
	else '1' end as R,
	
	CASE 
	when Frequency < (select Frequency from ##calculation
								   where rn_frequency = (
								   select cast(count(DISTINCT(CustomerID))*0.25 as int) FROM ##calculation)) then '1'
	when Frequency >= (select Frequency from ##calculation
									where rn_frequency = (
								    select cast(count(DISTINCT(CustomerID))*0.25 as int) FROM ##calculation))
	and Frequency < (select Frequency from ##calculation
									where rn_frequency = (
								    select cast(count(DISTINCT(CustomerID))*0.5 as int) FROM ##calculation)) then '2'
	when Frequency >= (select Frequency from ##calculation
									where rn_frequency = (
								    select cast(count(DISTINCT(CustomerID))*0.5 as int) FROM ##calculation))
	and Frequency < (select Frequency from ##calculation
									where rn_frequency = (
								    select cast(count(DISTINCT(CustomerID))*0.75 as int) FROM ##calculation)) then '3'  
	else '4' end as F,
	
	CASE 
	when Monetary < (select Monetary from ##calculation
								   where rn_monetary = (
								   select cast(count(DISTINCT(CustomerID))*0.25 as int) FROM ##calculation)) then '1'
	when Monetary >= (select Monetary from ##calculation
									where rn_monetary = (
								    select cast(count(DISTINCT(CustomerID))*0.25 as int) FROM ##calculation))
	and Monetary < (select Monetary from ##calculation
									where rn_monetary = (
								    select cast(count(DISTINCT(CustomerID))*0.5 as int) FROM ##calculation)) then '2'
	when Monetary >= (select Monetary from ##calculation
									where rn_monetary = (
								    select cast(count(DISTINCT(CustomerID))*0.5 as int) FROM ##calculation))
	and Monetary < (select Monetary from ##calculation
									where rn_monetary = (
								    select cast(count(DISTINCT(CustomerID))*0.75 as int) FROM ##calculation)) then '3'  
	else '4' end as M
into ##RFM
from ##calculation



SELECT *, CONCAT(R, F, M) as RFM,
CASE
 WHEN CONCAT(R, F, M) IN ('444', '443', '434', '433', '344', '343') THEN 'VIP'
 WHEN CONCAT(R, F, M) IN ('442', '441', '432', '423', '342', '334', '333', '332', '331', '324', '323', '322', '244', '243', '234' ) THEN 'TRUNG THANH'
 WHEN CONCAT(R, F, M) IN ('431', '424', '422', '421', '414', '413', '412', '411', '341', '321', '314', '313', '312', '311') THEN 'TIEM NANG'
 ELSE 'VANGLAI'
END AS seg
FROM ##RFM

SELECT CONCAT(R, F, M) AS RFM, COUNT(*) AS RFM_Count
FROM ##RFM
GROUP BY CONCAT(R, F, M)
ORDER BY RFM_Count DESC

SELECT COUNT(DISTINCT CustomerID) AS Total_Customers
FROM Customer_Transaction;
--942339

SELECT 
 percentile_cont(0.25) WITHIN GROUP (ORDER BY recency) OVER () AS quartile_1,
 percentile_cont(0.50) WITHIN GROUP (ORDER BY recency) OVER () AS quartile_2,
 percentile_cont(0.75) WITHIN GROUP (ORDER BY recency) OVER () AS quartile_3,
 MIN(recency) OVER () AS min_recency,
 MAX(recency) OVER () AS max_recency
FROM ##calculation;

SELECT 
 percentile_cont(0.25) WITHIN GROUP (ORDER BY Frequency) OVER () AS quartile_1,
 percentile_cont(0.50) WITHIN GROUP (ORDER BY Frequency) OVER () AS quartile_2,
 percentile_cont(0.75) WITHIN GROUP (ORDER BY Frequency) OVER () AS quartile_3,
 min (Frequency) OVER () as min_frequency,
 max (Frequency) OVER () as max_frequency
FROM ##calculation;


SELECT 
 percentile_cont(0.25) WITHIN GROUP (ORDER BY Monetary) OVER () AS quartile_1,
 percentile_cont(0.50) WITHIN GROUP (ORDER BY Monetary) OVER () AS quartile_2,
 percentile_cont(0.75) WITHIN GROUP (ORDER BY Monetary) OVER () AS quartile_3,
 min (Monetary) OVER () as min_montery,
 max (Monetary) OVER () as max_montery
FROM ##calculation;

--42,290
SELECT COUNT(*) AS total_customers
FROM ##RFM
WHERE recency >= 92


--31,647
SELECT COUNT(*) AS total_customers
FROM ##RFM
WHERE recency >= 62 AND recency <= 91;

--42,205
SELECT COUNT(*) AS total_customers
FROM ##RFM
WHERE recency >= 31 AND recency <= 61;

--481
SELECT COUNT(*) AS total_customers
FROM ##RFM
WHERE recency >=1 AND recency <= 30;

SELECT COUNT(DISTINCT CustomerID) AS Total_Customers
FROM Customer_Transaction;
--942339

SELECT COUNT(*) AS valid_recency_customers
FROM ##RFM
WHERE recency IS NOT NULL AND recency >= 1 AND recency <= 92;
--116,623

SELECT COUNT(DISTINCT CustomerID) AS Total_Customers
FROM Customer_Transaction;
--942,339

SELECT COUNT(*) AS not_in_groups_customers
FROM ##RFM
WHERE recency IS NULL OR recency < 1 OR recency > 92;
-- 0

SELECT COUNT(DISTINCT CustomerID) AS distinct_customers_in_rfm
FROM ##RFM;
--114,081



SELECT TOP 5 CustomerID, recency, Frequency, Monetary, R,F,M
FROM ##RFM
WHERE CONCAT(R, F, M) = '444'
ORDER BY recency DESC, Frequency ASC, Monetary ASC;




SELECT COUNT(*) AS New_Customers, 
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM ##RFM), 2) AS Percentage
FROM ##RFM
WHERE recency <= 30;

SELECT CASE 
         WHEN recency <= 7 THEN 'Dưới 1 tuần'
         WHEN recency <= 14 THEN '1-2 tuần'
         WHEN recency <= 30 THEN '2-4 tuần'
         ELSE 'More than 1 month'
       END AS Recency_Range, 
       COUNT(*) AS Total_Customers,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM ##RFM), 2) AS Percentage
FROM ##RFM
GROUP BY CASE 
            WHEN recency <= 7 THEN 'Dưới 1 tuần'
            WHEN recency <= 14 THEN '1-2 tuần'
            WHEN recency <= 30 THEN '2-4 tuần'
            ELSE 'Hơn 1 tháng'
         END
ORDER BY Total_Customers DESC;

SELECT Top 10 CustomerID, recency, Frequency, Monetary, R,F,M
FROM ##RFM
WHERE Frequency <= (SELECT AVG(Frequency) FROM ##RFM) AND Monetary > (SELECT AVG(Monetary) FROM ##RFM)
ORDER BY Monetary DESC;































