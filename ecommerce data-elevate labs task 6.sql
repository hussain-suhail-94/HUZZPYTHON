COPY data("InvoiceNo", "StockCode", "Description", "Quantity", "InvoiceDate", "UnitPrice", "CustomerID", "Country")
FROM 'E:\\data.csv'
DELIMITER ',' CSV HEADER;

DROP TABLE data;

CREATE TABLE data (
    "InvoiceNo" TEXT,
    "StockCode" TEXT,
    "Description" TEXT,
    "Quantity" INTEGER,
    "InvoiceDate" TIMESTAMP,
    "UnitPrice" NUMERIC,
    "CustomerID" TEXT,
    "Country" TEXT
);
DROP TABLE data;

CREATE TABLE data (
    "InvoiceNo" TEXT,
    "StockCode" TEXT,
    "Description" TEXT,
    "Quantity" INTEGER,
    "InvoiceDate" TEXT, -- ← change from TIMESTAMP to TEXT
    "UnitPrice" NUMERIC,
    "CustomerID" TEXT,
    "Country" TEXT
);

COPY data("InvoiceNo", "StockCode", "Description", "Quantity", 
          "InvoiceDate", "UnitPrice", "CustomerID", "Country")
FROM 'E:\\data.csv'
DELIMITER ',' 
CSV HEADER
ENCODING 'WIN1252';

select * from data
--Total Quantity Sold by Year
SET datestyle = 'MDY';

SELECT EXTRACT(YEAR FROM "InvoiceDate"::timestamp) AS year,
       SUM("Quantity") AS total_quantity
FROM data
GROUP BY year
ORDER BY year;

--Total Quantity Sold by Month (All Years)
SET datestyle = 'MDY';

SELECT EXTRACT(MONTH FROM "InvoiceDate"::timestamp) AS month,
       SUM("Quantity") AS total_quantity
FROM data
GROUP BY month
ORDER BY month;

--Monthly Sales Trend (Year + Month)
SET datestyle = 'MDY';
SELECT EXTRACT(YEAR FROM "InvoiceDate"::timestamp) AS year,
       EXTRACT(MONTH FROM "InvoiceDate"::timestamp) AS month,
       SUM("Quantity") AS total_quantity
FROM data
GROUP BY year, month
ORDER BY year, month;

--Number of Unique Invoices per Month (Sales Volume)
SET datestyle = 'MDY';
SELECT EXTRACT(YEAR FROM "InvoiceDate"::timestamp) AS year,
       EXTRACT(MONTH FROM "InvoiceDate"::timestamp) AS month,
       COUNT(DISTINCT "InvoiceNo") AS total_invoices
FROM data
GROUP BY year, month
ORDER BY year, month;

--Total Revenue (Quantity × UnitPrice) per Month
SELECT EXTRACT(YEAR FROM "InvoiceDate") AS year,
       EXTRACT(MONTH FROM "InvoiceDate") AS month,
       SUM("Quantity" * "UnitPrice") AS total_revenue
FROM data
GROUP BY year, month
ORDER BY year, month;

--Top 5 Months with Highest Revenue
SET datestyle = 'MDY';
SELECT EXTRACT(YEAR FROM "InvoiceDate"::timestamp) AS year,
       EXTRACT(MONTH FROM "InvoiceDate"::timestamp) AS month,
       SUM("Quantity" * "UnitPrice") AS total_revenue
FROM data
GROUP BY year, month
ORDER BY total_revenue DESC
LIMIT 5;

--Top 10 Most Sold Products (by Quantity)
SELECT "Description",
       SUM("Quantity") AS total_quantity
FROM data
GROUP BY "Description"
ORDER BY total_quantity DESC
LIMIT 10;

-- Sales by Country
SELECT "Country",
       SUM("Quantity" * "UnitPrice") AS total_revenue
FROM data
GROUP BY "Country"
ORDER BY total_revenue DESC;

--Hourly Sales Trend (Customer behavior by time of day)
SELECT EXTRACT(HOUR FROM "InvoiceDate"::timestamp) AS hour,
       SUM("Quantity") AS total_quantity
FROM data
GROUP BY hour
ORDER BY hour;

