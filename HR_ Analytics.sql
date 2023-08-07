SELECT * FROM project.hr;

DESCRIBE project.hr;

-- Update Date of Birth to proper format
UPDATE project.hr
SET DOB = CASE
    WHEN DOB LIKE '%/%' THEN
        DATE_FORMAT(
            STR_TO_DATE(DOB, '%m/%d/%Y'),
            CONCAT(
                IF(YEAR(STR_TO_DATE(DOB, '%m/%d/%Y')) > YEAR(CURDATE()), 
                YEAR(STR_TO_DATE(DOB, '%m/%d/%Y')) - 100, 
                YEAR(STR_TO_DATE(DOB, '%m/%d/%Y'))),
                '/%m/%d'
            )
        )
    ELSE NULL
END;

-- Convert text 'DOB' to date
ALTER TABLE project.hr
MODIFY COLUMN DOB DATE;


-- Update Date of Hire to proper format
UPDATE project.hr
SET DateofHire = CASE
    WHEN DateofHire LIKE '%/%' THEN
        DATE_FORMAT(
            STR_TO_DATE(DateofHire, '%m/%d/%Y'),
            CONCAT(
                IF(YEAR(STR_TO_DATE(DateofHire, '%m/%d/%Y')) > YEAR(CURDATE()), 
                YEAR(STR_TO_DATE(DateofHire, '%m/%d/%Y')) - 100, 
                YEAR(STR_TO_DATE(DateofHire, '%m/%d/%Y'))),
                '/%m/%d'
            )
        )
    ELSE NULL
END;

-- Convert text 'DateofHire' to date
ALTER TABLE project.hr
MODIFY COLUMN DateofHire DATE;


-- Update Date of Termination to proper format
UPDATE project.hr
SET DateofTermination = CASE
    WHEN DateofTermination LIKE '%/%' THEN
        DATE_FORMAT(
            STR_TO_DATE(DateofTermination, '%m/%d/%Y'),
            CONCAT(
                IF(YEAR(STR_TO_DATE(DateofTermination, '%m/%d/%Y')) > YEAR(CURDATE()), 
                YEAR(STR_TO_DATE(DateofTermination, '%m/%d/%Y')) - 100, 
                YEAR(STR_TO_DATE(DateofTermination, '%m/%d/%Y'))),
                '/%m/%d'
            )
        )
    ELSE NULL
END;

-- Convert text 'DateofTermination' to date
ALTER TABLE project.hr
MODIFY COLUMN DateofTermination DATE;

-- Update Last Performance Review Date  to proper format
UPDATE project.hr
SET LastPerformanceReview_Date = CASE
    WHEN LastPerformanceReview_Date LIKE '%/%' THEN
        DATE_FORMAT(
            STR_TO_DATE(LastPerformanceReview_Date, '%m/%d/%Y'),
            CONCAT(
                IF(YEAR(STR_TO_DATE(LastPerformanceReview_Date, '%m/%d/%Y')) > YEAR(CURDATE()), 
                YEAR(STR_TO_DATE(LastPerformanceReview_Date, '%m/%d/%Y')) - 100, 
                YEAR(STR_TO_DATE(LastPerformanceReview_Date, '%m/%d/%Y'))),
                '/%m/%d'
            )
        )
    ELSE NULL
END;

-- Convert text 'LastPerformanceReview_Date' to date
ALTER TABLE project.hr
MODIFY COLUMN LastPerformanceReview_Date DATE;

-- Add Age column
ALTER TABLE project.hr ADD COLUMN Age INT;

UPDATE project.hr
SET Age = TIMESTAMPDIFF(YEAR, DOB, CURDATE());

-- Analytics Part

-- 1. What is  distribution of job titles across the company?
-- Total employees
SELECT Position, count(*) AS Count
FROM project.hr
GROUP BY Position
ORDER BY count(*) DESC;

-- Active employees
SELECT Position, count(*) AS Count
FROM project.hr
WHERE DateofTermination IS NULL
GROUP BY Position
ORDER BY count(*) DESC;

-- 2.What is the gender distribution of employees in the company?
SELECT Sex, 
	   COUNT(*) AS SexCount,
	   CONCAT(ROUND((COUNT(*) / (SELECT COUNT(*) FROM project.hr WHERE DateofTermination IS NULL)) * 100, 0), '%') AS Percentage
FROM project.hr
WHERE DateofTermination IS NULL
GROUP BY Sex;

-- 3. How does the gender distribution vary across department?
SELECT Department, Sex, COUNT(*) AS EmpCount
FROM project.hr
WHERE DateofTermination IS NULL
GROUP BY Department, Sex
ORDER BY Department;


-- 4. What is th ethnicity distribution of employees in the company?
SELECT RaceDesc AS Race, 
	   COUNT(*) AS RaceCount,
	   CONCAT(ROUND((COUNT(*) / (SELECT COUNT(*) FROM project.hr WHERE DateofTermination IS NULL)) * 100, 0), '%') AS Percentage
FROM project.hr
WHERE DateofTermination IS NULL
GROUP BY RaceDesc
ORDER BY count(*) DESC;

-- 5. What is distribution of employee across location?
-- Employee by state
SELECT State, COUNT(*) AS EmpCount
FROM project.hr
WHERE DateofTermination IS NULL
GROUP BY State;

-- 6. What is the age distribution of employees?
-- Age group
SELECT min(age) AS Youngest,
	   max(age) AS Oldest
FROM project.hr
WHERE DateofTermination IS NULL;

SELECT
    CASE 
        WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) BETWEEN 25 AND 34 THEN '25-34'
        WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) BETWEEN 35 AND 44 THEN '35-44'
        WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) BETWEEN 45 AND 54 THEN '45-54'
        WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END AS Age_group,
    COUNT(*) AS Count
FROM project.hr
WHERE DateofTermination IS NULL
GROUP BY Age_group
ORDER BY Age_group;

-- 7. What is the average length of employment for employee who have been terminated? 
-- Average length termination
SELECT 
	ROUND(AVG(DATEDIFF(DateofTermination, DateofHire))/365,0) AS  avg_length_employment
FROM project.hr
WHERE DateofTermination IS NOT NULL;

-- 8. Which departmet has the higher turnover rate?
-- Termination rate
SELECT Department,
	COUNT(*) AS TotalCount,
    COUNT(CASE
		   WHEN DateofTermination IS NOT NULL AND DateofTermination <= CURDATE() THEN 1
		   END) AS Terminated_count,
    ROUND((COUNT(CASE
				  WHEN DateofTermination IS NOT NULL AND DateofTermination <= CURDATE() THEN 1
				  END)/COUNT(*))*100,2) AS Termination_rate
	FROM project.hr
    GROUP BY Department
    ORDER BY Termination_rate DESC;
    
-- 9.What is Reasons for turning over?
-- Turnover Reason
SELECT TermReason, 
       COUNT(*) AS Count,
       CONCAT(ROUND((COUNT(*) / (SELECT COUNT(*) FROM project.hr WHERE TermReason NOT IN ('N/A-StillEmployed'))) * 100, 2), '%') AS Percentage
FROM project.hr
WHERE TermReason NOT IN ('N/A-StillEmployed')
GROUP BY TermReason
ORDER BY Count DESC;    
    

-- 10. How has the company employee count changed overtime base on hire and terminationdate?
-- Count changed
SELECT Year,
		Hires,
        Terminations,
        Hires-Terminations AS Net_change,
        ROUND((Terminations/Hires)*100,2) AS Change_percentage
	FROM(
			SELECT YEAR(DateofHire) AS year,
            COUNT(*) AS Hires,
            SUM(CASE
					WHEN DateofTermination IS NOT NULL AND DateofTermination <= CURDATE() THEN 1
				END) AS Terminations
			FROM project.hr
            GROUP BY YEAR(DateofHire)) AS Subquery
GROUP BY Year
ORDER BY Year;

-- 11. What is the tenure distribution for each department?
SELECT Department, ROUND(AVG(DATEDIFF(DateofTermination, DateofHire)/365),0) AS Avg_tenure
FROM project.hr
WHERE DateofTermination IS NOT NULL AND DateofTermination <= CURDATE()
GROUP BY Department;
	
-- 12. What are the working years of the employee?
-- Year of work
SELECT
  CASE
    WHEN TIMESTAMPDIFF(YEAR, DateofHire, CURDATE()) < 1 THEN 'Less than 1 year'
    WHEN TIMESTAMPDIFF(YEAR, DateofHire, CURDATE()) = 1 THEN '1 year'
    ELSE CONCAT(TIMESTAMPDIFF(YEAR, DateofHire, CURDATE()), ' years')
  END AS Years_of_work,
  COUNT(*) AS EmpCount
FROM project.hr
WHERE DateofTermination IS NULL
GROUP BY Years_of_work
ORDER BY MIN(TIMESTAMPDIFF(YEAR, DateofHire, CURDATE()));


