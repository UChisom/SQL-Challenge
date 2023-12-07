-- B. Runner and Customer Experience
-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT CONCAT('Week-','',EXTRACT(week FROM registration_date)), COUNT(*)
FROM pizza_runner.runners
GROUP BY 1
ORDER BY 1

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH arrival_time_tbl AS(
	SELECT co.order_id,
		co.order_time,
		ro.runner_id,
		ro.pickup_time_fixed,
		EXTRACT(MINUTE FROM (ro.pickup_time_fixed - co.order_time)) AS pickup_time

	FROM pizza_runner.customer_orders co
	LEFT JOIN pizza_runner.runner_orders ro
	ON co.order_id = ro.order_id
	WHERE ro.cancellation IS NULL)

SELECT runner_id, ROUND(AVG(pickup_time), 2) avg_arrival_time
FROM arrival_time_tbl
GROUP BY 1
ORDER BY 1

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH order_count AS(
	SELECT order_id, order_time, COUNT(*) order_count
	FROM pizza_runner.customer_orders co
	GROUP BY 1,2 
	ORDER BY 1),
	
	pickup_time AS(
	SELECT oc.order_id, 
		   EXTRACT(MINUTE FROM (ro.pickup_time_fixed - oc.order_time)) AS pickup_time,
		   oc.order_count
	FROM order_count oc,
		pizza_runner.runner_orders ro
	WHERE oc.order_id = ro.order_id AND ro.cancellation IS NULL)
	
SELECT order_count, ROUND(AVG(pickup_time),2)
FROM pickup_time
GROUP BY 1
	
-- What was the average distance travelled for each customer?

WITH unique_order_cust_id AS(
	SELECT DISTINCT order_id, customer_id
	FROM pizza_runner.customer_orders 
	ORDER BY 1)
	
SELECT oc.customer_id, AVG(distance_km)
FROM unique_order_cust_id oc
LEFT JOIN pizza_runner.runner_orders ro
ON oc.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY 1
ORDER BY 2

-- What was the difference between the longest and shortest delivery times for all orders?

WITH order_time AS(
	SELECT DISTINCT order_id, order_time
	FROM pizza_runner.customer_orders
	ORDER BY 1),
	
	delivery_time AS(	
	SELECT ot.order_id,
		   ot.order_time,
		   ro.pickup_time_fixed,
		   ro.duration_min,
		   EXTRACT(MINUTE FROM (ro.pickup_time_fixed - ot.order_time)) + duration_min AS delivery_time
	FROM order_time ot,
		 pizza_runner.runner_orders ro
	WHERE ot.order_id = ro.order_id AND ro.cancellation IS NULL)

SELECT MAX(delivery_time) - MIN(delivery_time) AS diff
FROM delivery_time

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
WITH runner_speed AS(
	SELECT order_id, runner_id, round(speed::numeric,2) speed
	FROM
		(SELECT *, (distance_km * 1000)/(duration_min * 60) AS speed
		FROM pizza_runner.runner_orders
		WHERE cancellation IS NULL) t1)
		
SELECT runner_id, ROUND(AVG(speed),2) avg_spped
FROM runner_speed
GROUP BY 1
ORDER BY 2

-- What is the successful delivery percentage for each runner?
WITH status AS(
	SELECT runner_id,
		CASE
			WHEN cancellation IS NULL THEN 'delivered'
			ELSE 'not_delivered'
			END AS status
	FROM pizza_runner.runner_orders),
	
	status_count AS(
	SELECT runner_id, status, COUNT(*)
	FROM status
	GROUP BY 1, 2),
	
	not_delivered AS(
	SELECT *
	FROM status_count
	WHERE status = 'not_delivered'
	),
	
	pivot_tbl AS(
	SELECT sc.runner_id, sc.count AS delivered,
			CASE 
				WHEN nd.count IS NULL THEN 0
				ELSE nd.count
				END AS not_delivered
	FROM status_count sc
	LEFT JOIN not_delivered nd
	ON sc.runner_id = nd.runner_id
	WHERE sc.status = 'delivered')
	
SELECT runner_id, delivered::float/(delivered::float + not_delivered::float) * 100 AS delivery_perc
FROM pivot_tbl
ORDER BY 1