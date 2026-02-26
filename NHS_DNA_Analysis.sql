/* PROJECT: NHS DNA & Health Inequality Analysis
AUTHOR: Toheeb
TOOLS: SQLite / DB Browser
DESCRIPTION: Cleaning messy primary care data and identifying financial loss in deprived cohorts.
*/

-- 1. DATA CLEANING (Handling NULLs)
UPDATE Appointments SET Condition = 'None' WHERE Condition IS NULL OR Condition = '';
UPDATE Appointments SET Age = 52 WHERE Age IS NULL; -- Using Median Imputation
UPDATE Appointments SET IMD_Quintile = 1 WHERE IMD_Quintile IS NULL; -- Conservative risk approach

-- 2. FEATURE ENGINEERING
-- Converting attendance text to a numeric flag for Power BI calculations
ALTER TABLE Appointments ADD COLUMN DNA_Flag INT;
UPDATE Appointments SET DNA_Flag = CASE WHEN Attended = 'No' THEN 1 ELSE 0 END;

-- 3. OVERALLL DNA RATE (All Cohorts)
SELECT 
    COUNT(*) AS Total_Appointments,
    SUM(CASE WHEN Attended = 'No' THEN 1 ELSE 0 END) AS Total_Missed,
    ROUND(AVG(CASE WHEN Attended = 'No' THEN 1.0 ELSE 0 END) * 100, 1) AS DNA_Rate_Percent
FROM Appointments;

-- 4. RELATIVE RISK CALCULATION
SELECT 
    IMD_Quintile,
    ROUND(AVG(DNA_Flag) * 100, 1) AS DNA_Rate_Percent
FROM Appointments
GROUP BY IMD_Quintile
ORDER BY IMD_Quintile;

-- 5. STRATEGIC INSIGHT QUERY
-- Calculating total loss and DNA rates for the high-priority group (IMD 1 & 2)
SELECT 
    GP_Practice,
    SUM(DNA_Flag) AS Total_Missed_Appts,
    SUM(DNA_Flag) * 30 AS Revenue_Loss_GBP,
    ROUND(AVG(DNA_Flag) * 100, 1) AS DNA_Rate_Percent
FROM Appointments
WHERE IMD_Quintile IN (1, 2)
GROUP BY GP_Practice
ORDER BY Total_Missed_Appts DESC;

