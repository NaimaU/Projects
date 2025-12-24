-- Exploratory Data Analysis

SELECT *
FROM layoffs_staging2;

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- Companies that laid off all employees
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- Industries of companies that laid off all employees
SELECT industry, SUM(total_laid_off) as laid_off_sum
FROM layoffs_staging2
WHERE percentage_laid_off = 1
GROUP BY industry
ORDER BY laid_off_sum DESC;

-- SUM of total laid off per company
SELECT company, SUM(total_laid_off) as laid_off_sum
FROM layoffs_staging2
GROUP BY company
ORDER BY laid_off_sum DESC;

SELECT DISTINCT company
FROM layoffs_staging2;

-- SUM of total laid off per industry
SELECT industry, SUM(total_laid_off) as laid_off_sum
FROM layoffs_staging2
GROUP BY industry
ORDER BY laid_off_sum DESC;

-- Max percent layoff per company
SELECT company, MAX(percentage_laid_off) as max_perc
FROM layoffs_staging2
GROUP BY company
HAVING max_perc < 1
ORDER BY max_perc DESC;

SELECT * 
FROM layoffs_staging2
WHERE company = 'Amazon';

-- What day had the most total layoffs? Percentage laid off?
SELECT `date`, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY `date`
ORDER BY 2 DESC;

SELECT DISTINCT `date`, 
	SUM(total_laid_off) OVER(PARTITION BY `date`)
FROM layoffs_staging2
ORDER BY 2 DESC;

SELECT `date`, AVG(percentage_laid_off)
FROM layoffs_staging2
GROUP BY `date`
ORDER BY 2 DESC;

-- What month has the most total layoffs? Highest average layoff percentage?
SELECT MONTH(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY MONTH(`date`)
ORDER BY 2 DESC;

SELECT MONTH(`date`), ROUND(AVG(percentage_laid_off),2)
FROM layoffs_staging2
GROUP BY MONTH(`date`)
ORDER BY 2 DESC;

-- Range of dates within the dataset (2020 to 2023 - during the COVID pandemic)
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- Countries with highest average layoff percentage
SELECT country, AVG(percentage_laid_off) as laid_off_perc
FROM layoffs_staging2
GROUP BY country
ORDER BY laid_off_perc DESC;

-- Countries with highest layoff ratio (sum/count)
SELECT country, SUM(total_laid_off) / COUNT(total_laid_off) as laid_off_ratio
FROM layoffs_staging2
GROUP BY country
ORDER BY laid_off_ratio DESC;

SELECT *
FROM layoffs_staging2
WHERE country = 'Netherlands';

-- Sum of total layoffs grouped by month + year
SELECT CONCAT(MONTH(`date`),'/',YEAR(date)) as month_year, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY month_year
ORDER BY 2 DESC;

SELECT `date`, CONCAT(MONTH(`date`),'/',YEAR(date))
FROM layoffs_staging2
ORDER BY 2;

-- Rolling total layoffs (per day)
SELECT DISTINCT `date`,
	SUM(total_laid_off) OVER (PARTITION BY `date`) AS indiv_total,
	SUM(total_laid_off) OVER (ORDER BY `date`) AS rolling_total
FROM layoffs_staging2
WHERE `date` IS NOT NULL
AND total_laid_off IS NOT NULL;

SELECT SUM(total_laid_off)
FROM layoffs_staging2;

-- Rolling total layoffs (per month + year)
SELECT DISTINCT CONCAT(MONTH(`date`),'/',YEAR(`date`)) as month_year,
	SUM(total_laid_off) OVER (ORDER BY YEAR(`date`), MONTH(`date`)) AS rolling_total
FROM layoffs_staging2
WHERE `date` IS NOT NULL;

-- group by (indiv totals)
SELECT SUBSTRING(`date`,1,7) AS month_year, SUM(total_laid_off) AS indiv_total
FROM layoffs_staging2
WHERE `date` IS NOT NULL
GROUP BY month_year
ORDER BY month_year;

-- window function
SELECT DISTINCT SUBSTRING(`date`,1,7) AS month_year, 
	SUM(total_laid_off) OVER(ORDER BY SUBSTRING(`date`,1,7)) AS rolling_total
FROM layoffs_staging2
WHERE `date` IS NOT NULL
ORDER BY month_year;

-- using CTE
WITH rolling_total_cte AS 
(
    SELECT SUBSTRING(`date`,1,7) AS month_year, SUM(total_laid_off) AS indiv_total
	FROM layoffs_staging2
	WHERE `date` IS NOT NULL
	GROUP BY month_year
	ORDER BY month_year
) 
SELECT month_year, indiv_total, SUM(indiv_total) OVER(ORDER BY month_year) as rolling_total
FROM rolling_total_cte;


-- Major company layoffs per year
SELECT company, YEAR(`date`), SUM(total_laid_off) as laid_off_sum
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY laid_off_sum DESC;

SELECT *
FROM layoffs_staging2;

-- rank (per company) of layoffs per year. Ordered by laid_off_sum
WITH laid_off_per_company_cte AS
(
	SELECT company, 
		YEAR(`date`), 
		SUM(total_laid_off) as laid_off_sum
	FROM layoffs_staging2
	GROUP BY company, YEAR(`date`)
	ORDER BY laid_off_sum DESC
)
SELECT *, RANK() OVER(PARTITION BY company ORDER BY laid_off_sum DESC) as rank_company
FROM laid_off_per_company_cte
ORDER BY laid_off_sum DESC;


-- rank of layoffs per year (top 5). Ordered by year
WITH laid_off_per_company_cte AS
(
	SELECT company, 
		YEAR(`date`) as years, 
		SUM(total_laid_off) as laid_off_sum
	FROM layoffs_staging2
	GROUP BY company, YEAR(`date`)
), 
company_year_rank_cte AS
(
	SELECT *, RANK() OVER(PARTITION BY years ORDER BY laid_off_sum DESC) as rank_company
	FROM laid_off_per_company_cte
	WHERE laid_off_sum IS NOT NULL
		AND years IS NOT NULL
)
SELECT *
FROM company_year_rank_cte
WHERE rank_company <= 5;
        
        
        
        
        