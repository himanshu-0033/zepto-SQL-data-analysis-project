-- Zepto inventory data analysis
-- Using PostgreSQL

DROP TABLE IF EXISTS zepto;

CREATE TABLE zepto (
    sku_id SERIAL PRIMARY KEY,
    category VARCHAR(120),
    name VARCHAR(150) NOT NULL,
    mrp NUMERIC(8,2),
    discountPercent NUMERIC(5,2),
    availableQuantity INTEGER,
    discountedSellingPrice NUMERIC(8,2),
    weightInGms INTEGER,
    outOfStock BOOLEAN,
    quantity INTEGER
);

-- import zepto_v2.csv using pgAdmin's import feature
-- or use \copy if import doesn't work:
--
-- \copy zepto(category,name,mrp,discountPercent,availableQuantity,
--          discountedSellingPrice,weightInGms,outOfStock,quantity)
-- FROM 'zepto_v2.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');


------- EXPLORATION -------

-- total rows
SELECT COUNT(*) FROM zepto;

-- sample data
SELECT * FROM zepto
LIMIT 10;

-- null check
SELECT * FROM zepto
WHERE name IS NULL
   OR category IS NULL
   OR mrp IS NULL
   OR discountPercent IS NULL
   OR discountedSellingPrice IS NULL
   OR weightInGms IS NULL
   OR availableQuantity IS NULL
   OR outOfStock IS NULL
   OR quantity IS NULL;

-- distinct categories
SELECT DISTINCT category
FROM zepto
ORDER BY category;

-- stock status
SELECT outOfStock, COUNT(sku_id)
FROM zepto
GROUP BY outOfStock;

-- products with multiple SKUs (same product, different sizes/weights)
SELECT name, COUNT(sku_id) AS num_skus
FROM zepto
GROUP BY name
HAVING COUNT(sku_id) > 1
ORDER BY COUNT(sku_id) DESC;


------- CLEANING -------

-- found some products with mrp = 0, removing them
SELECT * FROM zepto
WHERE mrp = 0 OR discountedSellingPrice = 0;

DELETE FROM zepto
WHERE mrp = 0;

-- prices are in paise, need to convert to rupees
UPDATE zepto
SET mrp = mrp / 100.0,
    discountedSellingPrice = discountedSellingPrice / 100.0;

-- check if conversion worked
SELECT mrp, discountedSellingPrice FROM zepto
LIMIT 10;


------- ANALYSIS -------

-- Q1: top 10 products by discount
SELECT DISTINCT name, mrp, discountPercent
FROM zepto
ORDER BY discountPercent DESC
LIMIT 10;

-- Q2: expensive items that are out of stock
SELECT DISTINCT name, mrp
FROM zepto
WHERE outOfStock = TRUE AND mrp > 300
ORDER BY mrp DESC;

-- Q3: revenue estimate per category
SELECT category,
       SUM(discountedSellingPrice * availableQuantity) AS estimated_revenue
FROM zepto
GROUP BY category
ORDER BY estimated_revenue;

-- Q4: products above 500 with almost no discount
SELECT DISTINCT name, mrp, discountPercent
FROM zepto
WHERE mrp > 500 AND discountPercent < 10
ORDER BY mrp DESC, discountPercent DESC;

-- Q5: top 5 categories by avg discount
SELECT category,
       ROUND(AVG(discountPercent), 2) AS avg_discount
FROM zepto
GROUP BY category
ORDER BY avg_discount DESC
LIMIT 5;

-- Q6: price per gram for products 100g+
SELECT DISTINCT name, weightInGms, discountedSellingPrice,
       ROUND(discountedSellingPrice / weightInGms, 2) AS price_per_gram
FROM zepto
WHERE weightInGms >= 100
ORDER BY price_per_gram;

-- Q7: weight-based grouping
SELECT DISTINCT name, weightInGms,
       CASE
           WHEN weightInGms < 1000 THEN 'Low'
           WHEN weightInGms < 5000 THEN 'Medium'
           ELSE 'Bulk'
       END AS weight_tier
FROM zepto;

-- Q8: total inventory weight per category
SELECT category,
       SUM(weightInGms * availableQuantity) AS total_weight_gms
FROM zepto
GROUP BY category
ORDER BY total_weight_gms;


------- ADVANCED -------

-- Q9: top 3 most discounted in each category (CTE + window function)
WITH ranked_discounts AS (
    SELECT name, category, discountPercent,
           DENSE_RANK() OVER (PARTITION BY category ORDER BY discountPercent DESC) AS discount_rank
    FROM zepto
)
SELECT name, category, discountPercent
FROM ranked_discounts
WHERE discount_rank <= 3;

-- Q10: cumulative revenue across categories
WITH category_revenue AS (
    SELECT category,
           SUM(discountedSellingPrice * availableQuantity) AS revenue
    FROM zepto
    GROUP BY category
)
SELECT category, revenue,
       SUM(revenue) OVER (ORDER BY revenue DESC) AS running_total
FROM category_revenue;

-- Q11: out-of-stock rate by weight tier
WITH weight_categorized AS (
    SELECT
        CASE
            WHEN weightInGms < 1000 THEN 'Low (<1kg)'
            WHEN weightInGms < 5000 THEN 'Medium (1-5kg)'
            ELSE 'Bulk (>5kg)'
        END AS weight_tier,
        outOfStock
    FROM zepto
)
SELECT weight_tier,
       COUNT(*) AS total_items,
       SUM(CASE WHEN outOfStock = TRUE THEN 1 ELSE 0 END) AS oos_count,
       ROUND((SUM(CASE WHEN outOfStock = TRUE THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) AS oos_pct
FROM weight_categorized
GROUP BY weight_tier
ORDER BY oos_pct DESC;