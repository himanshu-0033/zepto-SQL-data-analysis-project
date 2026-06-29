# Zepto SQL Data Analysis Project

SQL + Python data analysis on an e-commerce inventory dataset from [Zepto](https://www.zeptonow.com/). Picked this dataset because I wanted to work with real messy product data and write actual business queries, not just textbook stuff.

Did the whole thing end to end — set up the database, explored and cleaned the data, wrote a bunch of analysis queries in SQL, and made some charts in a Jupyter notebook.

## What's in here

- Database setup and CSV import into PostgreSQL
- EDA — nulls, categories, stock status, duplicate SKUs
- Data cleaning — removed bad rows, converted prices from paise to rupees
- SQL queries for business insights (discounts, revenue, pricing, stock analysis)
- Some advanced stuff — CTEs, `DENSE_RANK()`, running totals, conditional aggregation
- Visualizations in Python (Pandas + Matplotlib + Seaborn)

## Tech Stack

- PostgreSQL, pgAdmin
- SQL (joins, CTEs, window functions, CASE, aggregations)
- Python 3, Pandas, Matplotlib, Seaborn
- Jupyter Notebook

## Dataset

From [Kaggle](https://www.kaggle.com/datasets/palvinder2006/zepto-inventory-dataset/data?select=zepto_v2.csv) — originally scraped from Zepto's app. Each row is one SKU. Same product shows up multiple times with different sizes/weights/discounts, which is normal for e-commerce catalogs.

**Columns:**

| Column | What it is |
|--------|-----------|
| `sku_id` | Unique ID for each entry |
| `name` | Product name |
| `category` | Category (Fruits, Snacks, Beverages etc.) |
| `mrp` | MRP in paise (converted to ₹ during cleaning) |
| `discountPercent` | Discount % on MRP |
| `discountedSellingPrice` | Price after discount, also in paise originally |
| `availableQuantity` | How many units are in stock |
| `weightInGms` | Weight in grams |
| `outOfStock` | True/false |
| `quantity` | Units per pack |

## How the project is structured

### 1. Table setup

```sql
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
```

Imported the CSV through pgAdmin. You can also use `\copy`:

```sql
\copy zepto(category,name,mrp,discountPercent,availableQuantity,
         discountedSellingPrice,weightInGms,outOfStock,quantity)
FROM 'zepto_v2.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');
```

> I got a UTF-8 encoding error the first time — re-saving the CSV as "CSV UTF-8" from Excel sorted it out.

### 2. Exploration

Checked total rows, looked at sample data, found nulls, listed all categories, compared in-stock vs out-of-stock counts, and found products that appear as multiple SKUs.

### 3. Cleaning

- Dropped rows where MRP was 0 (doesn't make sense)
- Divided `mrp` and `discountedSellingPrice` by 100 to convert paise → rupees

### 4. Business queries

Wrote queries for:
- Top 10 highest-discount products
- Out-of-stock items with high MRP
- Revenue estimate per category
- Products above ₹500 MRP with < 10% discount
- Categories with best average discounts
- Price per gram (to compare value across pack sizes)
- Grouping products by weight (Low / Medium / Bulk)
- Total inventory weight per category

### 5. Advanced queries

- Top 3 most discounted per category using CTE + `DENSE_RANK()`
- Running total of revenue across categories with `SUM() OVER()`
- Out-of-stock % by weight tier using conditional aggregation

## What I found

- Around 3,731 usable products after cleaning
- Snacks and branded foods have way more SKUs than other categories
- Discounts are mostly small — under 10% for most products
- Premium items (MRP > ₹500) almost never get big discounts
- A few categories have significantly higher out-of-stock rates than others

## How to run this

1. Clone it:
   ```bash
   git clone https://github.com/himanshu-0033/zepto-SQL-data-analysis-project.git
   cd zepto-SQL-data-analysis-project
   ```

2. Database:
   - Create a PostgreSQL database
   - Run `Zepto_SQL_data_analysis.sql`
   - Import `zepto_v2.csv`

3. Notebook:
   ```bash
   pip install pandas matplotlib seaborn jupyter
   jupyter notebook Zepto_Data_Analysis.ipynb
   ```

## License

MIT

## Author

**Himanshu Malik** — IIT Kharagpur

[LinkedIn](https://www.linkedin.com/in/himanshu-malik) · [GitHub](https://github.com/himanshu-0033)
