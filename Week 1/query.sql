---- Each of the following case study questions can be answered using a single SQL statement:
SELECT *
FROM dannys_diner.sales;

----1 What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(m.price) total_amount
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 2;

----2 How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date)
FROM dannys_diner.sales
GROUP BY 1;

----3 What was the first item from the menu purchased by each customer?

WITH customer_first AS(
	SELECT *
	FROM(
		SELECT *,
				ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) rw
		FROM dannys_diner.sales) T1
	WHERE rw = 1)
	
SELECT cf.customer_id, m.product_name
FROM customer_first cf
LEFT JOIN dannys_diner.menu m
ON cf.product_id = m.product_id;

----4 What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT m.product_name, COUNT(*) freq
FROM dannys_diner.sales S
LEFT JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY 1
LIMIT 1;

----5 Which item was the most popular for each customer?
WITH ff AS(
	SELECT s.customer_id, m.product_name,  COUNT(*)
	FROM dannys_diner.sales s
	LEFT JOIN dannys_diner.menu m
	ON s.product_id = m.product_id
	GROUP BY 1,2),
	ff_2 AS(
	SELECT *,
	MAX(count) OVER(PARTITION BY customer_id),
	CASE
		WHEN count = MAX(count) OVER(PARTITION BY customer_id) THEN 'Favorite'
		ELSE 'Not'
	END AS Test
	FROM ff)
	
SELECT customer_id, product_name, count AS freq
FROM ff_2
WHERE test = 'Favorite';

----6 Which item was purchased first by the customer after they became a member?

SELECT cust_id, order_date, join_date, product_name
FROM(
	SELECT m.customer_id as cust_id,*,
		ROW_NUMBER() OVER(PARTITION BY m.customer_id ORDER BY order_date) rn
	FROM dannys_diner.sales s
	JOIN dannys_diner.members m
	on s.customer_id = m.customer_id
	JOIN dannys_diner.menu me
	ON s.product_id = me.product_id
	WHERE s.order_date > m.join_date) T1
WHERE rn = 1

----7 Which item was purchased just before the customer became a member?

WITH t1 AS(
	SELECT m.customer_id cust_id, *,
		RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC)
	FROM dannys_diner.sales s
	JOIN dannys_diner.members m
	on s.customer_id = m.customer_id
	JOIN dannys_diner.menu me
	ON s.product_id = me.product_id
	WHERE s.order_date < m.join_date)
	
SELECT cust_id, order_date, join_date, product_name
FROM t1
WHERE rank = 1

----8 What is the total items and amount spent for each member before they became a member?

SELECT m.customer_id, COUNT(*) total_items, SUM(price) total_amount
FROM dannys_diner.sales s
JOIN dannys_diner.members m
on s.customer_id = m.customer_id
JOIN dannys_diner.menu me
ON s.product_id = me.product_id
WHERE s.order_date < m.join_date
GROUP BY m.customer_id
ORDER BY 1

----9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier -
----  how many points would each customer have?

SELECT customer_id, SUM(POINTS)
FROM(
	SELECT *,
		CASE 
			WHEN me.product_name = 'sushi' THEN me.price * 10 * 2
			ELSE me.price * 10
			END AS points
	FROM dannys_diner.sales sa
	LEFT JOIN dannys_diner.menu me
	ON sa.product_id = me.product_id)T1
GROUP BY 1
ORDER BY 2


----10 In the first week after a customer joins the program (including their join date)
---- they earn 2x points on all items, not just sushi 
---- - how many points do customer A and B have at the end of January?

WITH main_table AS(
	SELECT m.customer_id, s.order_date, s.product_id, m.join_date, me.product_name, me.price
	FROM dannys_diner.sales s
	JOIN dannys_diner.members m
	on s.customer_id = m.customer_id
	JOIN dannys_diner.menu me
	ON s.product_id = me.product_id
	WHERE s.order_date >= m.join_date),
	
	conditions AS(
	SELECT *,
	CASE 
		WHEN order_date BETWEEN join_date AND join_date + 7 THEN price * 10 * 2
		ELSE price * 10
		END AS points
	FROM main_table
	WHERE DATE_PART('month', order_date) = 1)
	
SELECT customer_id, SUM(points)
FROM conditions
GROUP BY 1;

---- Bonus Questions

with cust_data AS(
	SELECT ds.customer_id,
		ds.order_date,
		dme.product_name,
		dme.price,
		CASE
			WHEN ds.order_date >= dm.join_date THEN 'Y'
			ELSE 'N'
			END AS member
	FROM dannys_diner.sales ds
	LEFT JOIN dannys_diner.members dm
	ON ds.customer_id = dm.customer_id
	JOIN dannys_diner.menu dme
	ON ds.product_id = dme.product_id
	ORDER BY 1,2),
	
	rank_members AS(
		SELECT *,
			RANK() OVER(PARTITION BY customer_id ORDER BY order_date)	
		FROM cust_data
		WHERE member = 'Y'
	),
	
	rank_non_members AS(
		SELECT *, 0 as rank	
		FROM cust_data
		WHERE member = 'N'
	),
	
	combined_table AS(
		SELECT * FROM rank_members
		UNION ALL
		SELECT * FROM rank_non_members
		ORDER BY 1,2
	),
	
	ranked_customers AS(
		SELECT customer_id,order_date,product_name,price,member,
		CASE
			WHEN rank = 0 THEN null
			ELSE rank
			END AS ranking
		FROM combined_table
	)
	
SELECT *
FROM cust_data

SELECT *
FROM ranked_customers