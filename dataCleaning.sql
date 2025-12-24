-- Data Cleaning

SELECT *
FROM layoffs;

-- 1. Remove duplicates
-- 2. Standardize data
-- 3. Null or blank values
-- 4. Remove unnecessary columns and rows

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

-- INSERT layoffs_staging
-- SELECT *
-- FROM layoffs;

--------------------------------------------------------------------------------------------------------------
-- 1. Remove duplicates

-- Find duplicates
WITH duplicate_row_cte AS (
	SELECT *,
	ROW_NUMBER() OVER 
		(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
	FROM layoffs_staging
)
SELECT *
FROM duplicate_row_cte
WHERE row_num > 1;

SELECT * 
FROM layoffs_staging
WHERE company = '100 Thieves';


-- Using MYSQL, thus can't delete from CTE directly. Also has no unique (primary key) column
-- Workaround: creating table copy with row_num
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
	SELECT *,
	ROW_NUMBER() OVER 
		(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
	FROM layoffs_staging
;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;


--------------------------------------------------------------------------------------------------------------
-- 2. Standardize data

-- Trim company name whitespace
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);


-- Combine similar industries (crypto)
SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';


-- Remove trailing characters from country (United States)
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE country LIKE "United S%"
ORDER BY company;

UPDATE layoffs_staging2
SET country = 'United States.'
WHERE country LIKE "United S%";

-- Alternatively, to remove trailing '.'
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);


-- Date column: from text -> date format
SELECT `date`, str_to_date(`date`, "%m/%d/%Y")
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = str_to_date(`date`, "%m/%d/%Y");

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` date;

SELECT * 
FROM layoffs_staging2;


--------------------------------------------------------------------------------------------------------------
-- 3. Null or blank values

-- Populate missing industries 
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL
	OR industry = '';
    
SELECT * 
FROM layoffs_staging2
WHERE company = 'Airbnb';

SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE t1.industry <> t2.industry;

SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
	AND t2.industry IS NOT NULL
	AND t2.industry <> '';
    
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
	AND t2.industry IS NOT NULL
	AND t2.industry <> '';

SELECT * 
FROM layoffs_staging2
WHERE company = "Bally's Interactive";


--------------------------------------------------------------------------------------------------------------
-- 4. Remove unnecessary columns and rows

-- Removing rows without laid off info (total or percentage)
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL
-- AND funds_raised_millions IS NULL
;

DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL
-- AND funds_raised_millions IS NULL
;

-- Removing extra row_num column
SELECT *
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;




