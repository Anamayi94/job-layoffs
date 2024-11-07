-- Data Cleaning

SELECT *
FROM layoffs;

-- 1. Remove duplicates if any
-- 2. Standardize the data
-- 3. Null/blank Values
-- 4. Remove unnessary columns or rows

-- create a staging
CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

-- insert columns and rowns into staging
INSERT layoffs_staging
SELECT *
FROM layoffs;

-- 1. IDENTIFYING DUPLICATES
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry,total_laid_off, percentage_laid_off, date) AS row_num
FROM layoffs_staging;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company,location, industry,total_laid_off, percentage_laid_off, date, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;
 -- to confirm duplicate 
 SELECT *
FROM layoffs_staging
WHERE company = 'Casper';
-- trying to delete the duplicate rows by updating the CTE
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company,location, industry,total_laid_off, percentage_laid_off, date, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
DELETE
FROM duplicate_cte
WHERE row_num > 1;

-- Since we cannot update a CTE we put it ito a staging2 database and delete the row_nums =2

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
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;


INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company,location, industry,total_laid_off, percentage_laid_off, date, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- to delete duplicates from staging2 table
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- TO CONFIRM IF THEY HAVE BEEN DELETED
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2
;



-- 2. STANDARDZING DATA

SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- TO STANDARDIZE CRYPTO INDUSTRY
SELECT DISTINCT industry
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- update all to 'Crypto'

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT country, trim(TRAILING '.' FROM country) as country_1
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country =  trim(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- changing date column FORMAT from text to date
SELECT `date`,
str_to_date(`date`, '%m/%d/%Y') 
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` =  str_to_date(`date`, '%m/%d/%Y');
-- to confirm if datatype has changed
SELECT `date`
FROM layoffs_staging2;

-- CHANGING TABLE DATATYPE
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT*
FROM layoffs_staging2;


-- 3. NULL AND BLANK VALUES

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry is null OR t1.industry = '')
AND t2.industry is not null;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry is null
AND t2.industry is not null;

SELECT *
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- deleting unnecessary rows and columns
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;

-- WE DONT NEED COLUMN ROW_NUM
ALTER TABLE layoffs_staging2
DROP row_num;