drop table if exists zepto;

create table zepto (
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

--data exploration

--count of rows
select count(*) from zepto;

--sample data
SELECT * FROM zepto
LIMIT 10;

--null values
SELECT * FROM zepto
WHERE name IS NULL
OR
category IS NULL
OR
mrp IS NULL
OR
discountPercent IS NULL
OR
discountedSellingPrice IS NULL
OR
weightInGms IS NULL
OR
availableQuantity IS NULL
OR
outOfStock IS NULL
OR
quantity IS NULL;

--different product categories
SELECT DISTINCT category
FROM zepto
ORDER BY category;

--products in stock vs out of stock
SELECT outOfStock, COUNT(sku_id)
FROM zepto
GROUP BY outOfStock;

--product names present multiple times
SELECT name, COUNT(sku_id) AS "Number of SKUs"
FROM zepto
GROUP BY name
HAVING count(sku_id) > 1
ORDER BY count(sku_id) DESC;

--data cleaning

--products with price = 0
SELECT * FROM zepto
WHERE mrp = 0 OR discountedSellingPrice = 0;

DELETE FROM zepto
WHERE mrp = 0;

--convert paise to rupees
UPDATE zepto
SET mrp = mrp / 100.0,
discountedSellingPrice = discountedSellingPrice / 100.0;

SELECT mrp, discountedSellingPrice FROM zepto;

--data analysis

-- Q1. Find the top 10 best-value products based on the discount percentage.
SELECT DISTINCT name, mrp, discountPercent
FROM zepto
ORDER BY discountPercent DESC
LIMIT 10;

--Q2.What are the Products with High MRP but Out of Stock

SELECT DISTINCT name,mrp
FROM zepto
WHERE outOfStock = TRUE and mrp > 300
ORDER BY mrp DESC;

--Q3.Calculate Estimated Revenue for each category
SELECT category,
SUM(discountedSellingPrice * availableQuantity) AS total_revenue
FROM zepto
GROUP BY category
ORDER BY total_revenue;

-- Q4. Find all products where MRP is greater than ₹500 and discount is less than 10%.
SELECT DISTINCT name, mrp, discountPercent
FROM zepto
WHERE mrp > 500 AND discountPercent < 10
ORDER BY mrp DESC, discountPercent DESC;

-- Q5. Identify the top 5 categories offering the highest average discount percentage.
SELECT category,
ROUND(AVG(discountPercent),2) AS avg_discount
FROM zepto
GROUP BY category
ORDER BY avg_discount DESC
LIMIT 5;

-- Q6. Find the price per gram for products above 100g and sort by best value.
SELECT DISTINCT name, weightInGms, discountedSellingPrice,
ROUND(discountedSellingPrice/weightInGms,2) AS price_per_gram
FROM zepto
WHERE weightInGms >= 100
ORDER BY price_per_gram;

--Q7.Group the products into categories like Low, Medium, Bulk.
SELECT DISTINCT name, weightInGms,
CASE WHEN weightInGms < 1000 THEN 'Low'
	WHEN weightInGms < 5000 THEN 'Medium'
	ELSE 'Bulk'
	END AS weight_category
FROM zepto;

--Q8.What is the Total Inventory Weight Per Category 
SELECT category,
SUM(weightInGms * availableQuantity) AS total_weight
FROM zepto
GROUP BY category
ORDER BY total_weight;

-- Q9. [Advanced] Find the top 3 most discounted products in each category using a CTE and Window Function.
WITH RankedDiscounts AS (
    SELECT name, category, discountPercent,
           DENSE_RANK() OVER(PARTITION BY category ORDER BY discountPercent DESC) as rank
    FROM zepto
)
SELECT name, category, discountPercent
FROM RankedDiscounts
WHERE rank <= 3;

-- Q10. [Advanced] Calculate the running total of expected revenue per category using Window Functions.
WITH CategoryRevenue AS (
    SELECT category,
           SUM(discountedSellingPrice * availableQuantity) as revenue
    FROM zepto
    GROUP BY category
)
SELECT category, revenue,
       SUM(revenue) OVER (ORDER BY revenue DESC) as running_total_revenue
FROM CategoryRevenue;

-- Q11. [Advanced] Analyze out-of-stock rate by weight categories using conditional aggregation.
WITH WeightCategorized AS (
    SELECT 
        CASE 
            WHEN weightInGms < 1000 THEN 'Low (<1kg)'
            WHEN weightInGms < 5000 THEN 'Medium (1kg-5kg)'
            ELSE 'Bulk (>5kg)'
        END AS weight_tier,
        outOfStock
    FROM zepto
)
SELECT weight_tier,
       COUNT(*) as total_items,
       SUM(CASE WHEN outOfStock = TRUE THEN 1 ELSE 0 END) as out_of_stock_items,
       ROUND((SUM(CASE WHEN outOfStock = TRUE THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) as out_of_stock_percentage
FROM WeightCategorized
GROUP BY weight_tier
ORDER BY out_of_stock_percentage DESC;