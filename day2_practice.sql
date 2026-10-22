CREATE DATABASE practice;
USE practice;

CREATE TABLE customers (
  customer_id INT PRIMARY KEY, name VARCHAR(50), city VARCHAR(50));
CREATE TABLE orders (
  order_id INT PRIMARY KEY, customer_id INT, order_date DATE,
  amount DECIMAL(10,2), status VARCHAR(20));

INSERT INTO customers VALUES
(1,'Aarav','Ahmedabad'),(2,'Meera','Mumbai'),(3,'Rohan','Delhi'),
(4,'Isha','Ahmedabad'),(5,'Kabir','Pune'),(6,'Nisha','Mumbai');

INSERT INTO orders VALUES
(101,1,'2026-01-05',2500,'Delivered'),(102,1,'2026-02-10',1800,'Delivered'),
(103,2,'2026-01-15',3200,'Cancelled'),(104,2,'2026-03-02',4100,'Delivered'),
(105,3,'2026-02-20',900,'Delivered'),(106,4,'2026-03-11',5200,'Delivered'),
(107,4,'2026-03-25',700,'Returned'),(108,1,'2026-04-01',3000,'Delivered'),
(109,5,'2026-04-12',1500,'Delivered'),(110,3,'2026-04-18',2200,'Delivered');

SELECT * 
FROM orders 
WHERE status = 'Delivered' AND amount > 2000 
ORDER BY order_date DESC;

SELECT status, COUNT(*) AS order_count, SUM(amount) AS total_amount 
FROM orders 
GROUP BY status;



SELECT * 
FROM customers 
WHERE city IN ('Ahmedabad', 'Mumbai');

SELECT c.name,c.city FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id;

SELECT c.name,c.city FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE order_id IS NULL;


SELECT c.city, SUM(o.amount) AS total_delivered_amount
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Delivered'
GROUP BY c.city
HAVING SUM(o.amount) > 5000;

SELECT c.customer_id, c.name, SUM(o.amount) AS total_spend
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
HAVING SUM(o.amount) > (
    SELECT AVG(cust_sum.total_spend)
    FROM (
        SELECT SUM(amount) AS total_spend
        FROM orders
        GROUP BY customer_id
    ) AS cust_sum
);

WITH CustomerDelivered AS (
    SELECT c.customer_id, c.name, SUM(o.amount) AS total_delivered_amount
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id, c.name
)
SELECT TOP 3 customer_id, name, total_delivered_amount
FROM CustomerDelivered
ORDER BY total_delivered_amount DESC;

SELECT order_id, customer_id, amount,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY amount DESC) AS order_rank
FROM orders;

SELECT order_id, customer_id, order_date, amount,
       SUM(amount) OVER (ORDER BY order_date, order_id) AS running_total
FROM orders
WHERE status = 'Delivered';


SELECT customer_id, order_id, order_date, amount,
       LAG(amount, 1, 0) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_amount
FROM orders;

WITH CustomerSpend AS (
    SELECT c.customer_id, c.name, SUM(o.amount) AS total_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.name
)
SELECT customer_id, name, total_spend,
       RANK() OVER (ORDER BY total_spend DESC) AS spend_rank,
       DENSE_RANK() OVER (ORDER BY total_spend DESC) AS spend_dense_rank
FROM CustomerSpend;

SELECT YEAR(order_date) AS order_year, 
       MONTH(order_date) AS order_month, 
       SUM(amount) AS total_delivered_revenue
FROM orders
WHERE status = 'Delivered'
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY order_year, order_month;


SELECT order_id, amount,
       CASE 
           WHEN amount < 1500 THEN 'Small'
           WHEN amount BETWEEN 1500 AND 3000 THEN 'Medium'
           ELSE 'Large'
       END AS order_size_label
FROM orders;




WITH MonthlyRevenue AS (
    SELECT FORMAT(order_date, 'yyyy-MM') AS order_month,
           SUM(amount) AS monthly_revenue
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY FORMAT(order_date, 'yyyy-MM')
)
SELECT order_month,
       monthly_revenue,
       LAG(monthly_revenue, 1) OVER (ORDER BY order_month) AS prev_month_revenue,
       monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY order_month) AS revenue_growth_amount,
       CAST(
           (monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY order_month)) * 100.0 
           / NULLIF(LAG(monthly_revenue, 1) OVER (ORDER BY order_month), 0) 
           AS DECIMAL(5,2)
       ) AS growth_percentage
FROM MonthlyRevenue;

