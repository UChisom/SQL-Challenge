-- A. Pizza Metrics

-- How many pizzas were ordered?
SELECT COUNT(DISTINCT order_id)
FROM pizza_runner.customer_orders;

-- How many unique customer orders were made?
SELECT COUNT(DISTINCT customer_id)
FROM pizza_runner.customer_orders;

-- How many successful orders were delivered by each runner?

SELECT runner_id, COUNT(*) successful_orders
FROM(
	SELECT runner_id
	FROM pizza_runner.runner_orders
	WHERE cancellation IS NULL) T1
GROUP BY 1
ORDER BY 1

-- How many of each type of pizza was delivered?
WITH delivered_pizza AS (
	SELECT co.order_id, co.customer_id, pn.pizza_name
	FROM pizza_runner.customer_orders co
	LEFT JOIN pizza_runner.runner_orders ro
	ON co.order_id = ro.order_id
	LEFT JOIN  pizza_runner.pizza_names pn
	ON co.pizza_id = pn.pizza_id
	WHERE ro.cancellation IS NULL)

SELECT pizza_name, COUNT(*) freq
FROM delivered_pizza
GROUP BY 1

-- How many Vegetarian and Meatlovers were ordered by each customer?
-- Use delivered_pizza CTE above

SELECT customer_id, pizza_name, COUNT(*)
FROM delivered_pizza
GROUP BY 1, 2
ORDER BY 1, 2

-- What was the maximum number of pizzas delivered in a single order?
SELECT MAX(no_of_orders) max_orders
FROM(
	SELECT order_id, COUNT(*) no_of_orders
	FROM pizza_runner.customer_orders
	GROUP BY 1) T1

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
WITH pizza_changes AS(
	SELECT co.customer_id,
		CASE
			WHEN exclusion_1 IS NOT NULL OR exclusion_2 IS NOT NULL OR extras_1 IS NOT NULL OR extras_2 IS NOT NULL
				THEN 'Had atleast 1 change'
			ELSE 'No Change'
			END AS pizza_changes
	FROM pizza_runner.customer_orders co
	LEFT JOIN pizza_runner.runner_orders ro
	ON co.order_id = ro.order_id
	WHERE ro.cancellation IS NULL)
	
SELECT customer_id,pizza_changes, COUNT(*)
FROM pizza_changes
GROUP BY 1,2
ORDER BY 1,2
	
-- How many pizzas were delivered that had both exclusions and extras
WITH pizza_changes AS(
	SELECT *,
		CASE
			WHEN (exclusion_1 IS NOT NULL OR exclusion_2 IS NOT NULL) AND (extras_1 IS NOT NULL OR extras_2 IS NOT NULL)
				THEN 'Had both'
			ELSE 'Does not have both'
			END AS pizza_changes
	FROM pizza_runner.customer_orders co
	LEFT JOIN pizza_runner.runner_orders ro
	ON co.order_id = ro.order_id
	WHERE ro.cancellation IS NULL)
	
SELECT pizza_changes, COUNT(*)
FROM pizza_changes
GROUP BY 1
ORDER BY 1

-- What was the total volume of pizzas ordered for each hour of the day?
SELECT  EXTRACT(HOUR FROM order_time) order_hour, COUNT(*)
FROM pizza_runner.customer_orders
GROUP BY 1
ORDER BY 1

-- What was the volume of orders for each day of the week?
SELECT to_char(order_time, 'Day') order_day, COUNT(*)
FROM pizza_runner.customer_orders
GROUP BY 1
ORDER BY 2