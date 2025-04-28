/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

SELECT
product_name || ', ' || product_size|| ' (' || product_qty_type || ')',
coalesce(product_size,'')AS[EMPTY] ,
coalesce(product_qty_type,'uNIT')AS [NULL]
FROM product


--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

 SELECT *
 FROM (
 SELECT 
 customer_id,market_date,
 row_number()OVER (PARTITION BY customer_id ORDER BY market_date) AS[ROWNUMBER],
dense_rank()OVER (PARTITION BY customer_id ORDER BY market_date) AS[DENSERANK]
  FROM customer_purchases 
 GROUP BY customer_id,market_date
 )


/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */


	  SELECT *
	 FROM (
	 SELECT
	 customer_id,market_date,
	 row_number()OVER (PARTITION BY customer_id ORDER BY market_date DESC) AS[ROWNUMBER],
	dense_rank()OVER (PARTITION BY customer_id ORDER BY market_date DESC) AS[DENSERANK]
	  FROM customer_purchases 
	 GROUP BY customer_id,market_date
	 )X
	 WHERE X.ROWNUMBER=1



/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

	 
	 SELECT *
	 FROM (
		 SELECT 
		 customer_id,market_date,product_id,count(product_id) as [totalboughtproducts],
		 row_number()OVER (PARTITION BY customer_id ORDER BY market_date DESC)AS[ROWNUMBER],
		dense_rank()OVER (PARTITION BY customer_id ORDER BY market_date DESC) AS[DENSERANK]
		 FROM customer_purchases 
		 GROUP BY product_id,market_date
		 )


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */
SELECT 
product_id,
product_name,
CASE WHEN
instr(product_name,'-')>0 THEN substr(product_name,instr(product_name,'-')+2)
ELSE 'NULL'
END AS [afterdash]

FROM product


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */
SELECT 
product_id,
product_name,product_size,
CASE WHEN
instr(product_name,'-')>0 THEN substr(product_name,instr(product_name,'-')+2)
ELSE 'NULL'
END AS [afterdash]
FROM product
where product_size REGEXP '\d'


-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */
1)	
CREATE TEMPORARY TABLE IF NOT EXISTS temp.totalsales2 AS
select market_date,sum(quantity * original_price) as [Total],count(quantity)
FROM
vendor_inventory
group by market_date,quantity
2)
CREATE TEMPORARY TABLE IF NOT EXISTS temp.totalsales11 AS
select rank() OVER(ORDER BY total DESC) as [RANK], market_date,total
FROM
totalsales2

3)
WITH BEST_DAY AS(
select *
FROM
totalsales11
ORDER BY rank ASC
LIMIT 1
),
WORST_DAY AS (
SELECT *
FROM 
totalsales11
ORDER BY RANK DESC
LIMIT 1
)
SELECT *
FROM BEST_DAY
UNION ALL 
SELECT *
FROM WORST_DAY


/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.
WE need to use product id, because not all products from products table have original price, original price only comes from ventor inventory and in that table not all producst wwere
 were sold
HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

	SELECT
	VI.vendor_id,VI.product_id,VI.original_price*5 as [costfor5products],C.customer_id,
	--,(5*original_price*cust) AS wow,
	V.vendor_name,P.product_name
	--row_number() over(PARTITION by VI.vendor_id order bY VI.product_id ASC) as [totalproducts]
	FROM
	vendor_inventory VI
	JOIN VENDOR V ON VI.vendor_id=V.vendor_id
	JOIN product P ON VI.product_id=P.product_id
	CROSS JOIN
	customer C
	GROUP BY VI.vendor_id,VI.product_id,c.customer_id,vi.original_price


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */



/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */



-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/



-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */




