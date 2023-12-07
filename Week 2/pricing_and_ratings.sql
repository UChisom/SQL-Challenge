-- D. Pricing and Ratings

-- If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no
-- charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

WITH pizza_orders AS(
	SELECT  pn.pizza_name, COUNT(*) order_count
	FROM pizza_runner.customer_orders co
	LEFT JOIN pizza_runner.runner_orders ro
	ON co.order_id = ro.order_id
	LEFT JOIN pizza_runner.pizza_names pn
	ON co.pizza_id = pn.pizza_id
	WHERE ro.cancellation IS NULL
	GROUP BY 1)
	
SELECT SUM(price) total_amount
FROM(
	SELECT *,
		CASE
			WHEN pizza_name = 'Meatlovers' THEN order_count*12
			ELSE order_count*10
			END AS price
	FROM pizza_orders) T1


-- What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra

WITH cust_tbl AS(
	SELECT order_id,pizza_id,
		CASE WHEN extras_1 IS NULL THEN 0
		ELSE 1
		END extras_1_test,
		CASE WHEN extras_2 IS NULL THEN 0
		ELSE 1
		END extras_2_test
	FROM pizza_runner.customer_orders),
	
	fix_price AS(
	SELECT pizza_name, price+extras AS total_price
	FROM(
		SELECT pn.pizza_name,
			CASE
				WHEN pn.pizza_name = 'Meatlovers' THEN 12
				ELSE 10
				END AS price,
				ct.extras_1_test + ct.extras_2_test AS extras
		FROM cust_tbl ct
		LEFT JOIN pizza_runner.runner_orders ro
		ON ct.order_id = ro.order_id
		LEFT JOIN pizza_runner.pizza_names pn
		ON ct.pizza_id = pn.pizza_id
		WHERE ro.cancellation IS NULL) T1)
		
SELECT SUM(total_price)
FROM fix_price
	
-- The Pizza Runner team now wants to add an additional ratings system that allows 
-- customers to rate their runner, how would you design an additional table for this new dataset
-- - generate a schema for this new table and insert your own data for ratings for each successful customer
-- order between 1 to 5.

DROP TABLE IF EXISTS pizza_runner.customer_rating;
CREATE TABLE pizza_runner.customer_rating(
	"order_id" INTEGER,
	"rating" INTEGER
);

INSERT INTO pizza_runner.customer_rating
  ("order_id", "rating")
VALUES
  ('1', '4'),
  ('2', '3'),
  ('3', '5'),
  ('4', '3'),
  ('5', '1'),
  ('6', NULL),
  ('7', '3'),
  ('8', '5'),
  ('9', NULL),
  ('10', '2');
  
SELECT *
FROM pizza_runner.customer_rating cr,
	 pizza_runner.runner_orders ro
WHERE cr.order_id = ro.order_id

-- Using your newly generated table - can you join all of the information together to 
-- form a table which has the following information for successful deliveries?
-- customer_id .
-- order_id .
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas .

WITH tbl_1 AS(
	SELECT order_id, customer_id, order_time, COUNT(*) n_pizza
	FROM pizza_runner.customer_orders
	GROUP BY 1, 2, 3
	ORDER BY 2,1),
	
	tbl_2 AS(
	SELECT runner_id, round(AVG(speed), 2) avg_speed
	FROM(
		SELECT runner_id, round(CAST(distance_km/(duration_min/60) AS NUMERIC), 2) speed
		FROM pizza_runner.runner_orders
		WHERE cancellation IS  NULL) T1
	GROUP BY 1),
	
	new_tbl AS(
	SELECT t1.customer_id,
			t1.order_id,
			ro.runner_id, 
			cr.rating, 
			t1.order_time,
			ro.pickup_time_fixed pickup_time,
			EXTRACT(MINUTE FROM (ro.pickup_time_fixed - t1.order_time)) time_diff,
			ro.duration_min,
			t2.avg_speed,
			t1.n_pizza
	FROM tbl_1 t1
	LEFT JOIN pizza_runner.runner_orders ro
	ON t1.order_id = ro.order_id
	LEFT JOIN pizza_runner.customer_rating cr
	ON t1.order_id = cr.order_id
	LEFT JOIN tbl_2 t2
	ON ro.runner_id = t2.runner_id
	WHERE ro.cancellation IS NULL)
	
SELECT *
FROM new_tbl


-- If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for 
-- extras and each runner is paid $0.30 per kilometre traveled 
-- - how much money does Pizza Runner have left over after these deliveries?

WITH pizza_orders AS(
	SELECT  pn.pizza_name, COUNT(*) order_count
	FROM pizza_runner.customer_orders co
	LEFT JOIN pizza_runner.runner_orders ro
	ON co.order_id = ro.order_id
	LEFT JOIN pizza_runner.pizza_names pn
	ON co.pizza_id = pn.pizza_id
	WHERE ro.cancellation IS NULL
	GROUP BY 1),
	
	total_cost_ex_delivery AS(
	SELECT SUM(price) total_amount
	FROM(
		SELECT *,
			CASE
				WHEN pizza_name = 'Meatlovers' THEN order_count*12
				ELSE order_count*10
				END AS price
		FROM pizza_orders) T1),
		
	delivery_cost AS(
	SELECT SUM(distance_km*0.3) delivery_cost
	FROM pizza_runner.runner_orders
	WHERE cancellation IS NULL)

SELECT tc.total_amount - dc.delivery_cost remaining_cash
FROM total_cost_ex_delivery tc
CROSS JOIN delivery_cost dc