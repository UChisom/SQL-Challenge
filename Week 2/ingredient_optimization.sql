-- C. Ingredient Optimisation

-- What are the standard ingredients for each pizza?

WITH meatlovers AS(
	SELECT *, 'Meatlovers' pizza_type
	FROM pizza_runner.pizza_toppings
	WHERE topping_id IN (1, 2, 3, 4, 5, 6, 8, 10)),
	
	vegetarian AS(
	SELECT *, 'Vegetarian' pizza_type
	FROM pizza_runner.pizza_toppings
	WHERE topping_id IN (4, 6, 7, 9, 11, 12))
	
SELECT *
FROM meatlovers 
UNION ALL
SELECT *
FROM vegetarian

-- What was the most commonly added extra?
WITH most_added AS(
	SELECT extra
	FROM(
		SELECT extras_1 AS extra, COUNT(*) freq
		FROM pizza_runner.customer_orders
		WHERE extras_1 IS NOT NULL
		GROUP BY 1
		UNION ALL
		SELECT extras_2 AS extra, COUNT(*) freq
		FROM pizza_runner.customer_orders
		WHERE extras_2 IS NOT NULL
		GROUP BY 1) T1
	ORDER BY freq DESC
	LIMIT 1)
	
SELECT topping_name
FROM pizza_runner.pizza_toppings
WHERE topping_id = (SELECT * FROM most_added)

-- What was the most common exclusion?
WITH most_excluded AS(
	SELECT exclusion
	FROM(
		SELECT exclusion_1 AS exclusion, COUNT(*) freq
		FROM pizza_runner.customer_orders
		WHERE exclusion_1 IS NOT NULL
		GROUP BY 1
		UNION ALL
		SELECT exclusion_2 AS exclusion, COUNT(*) freq
		FROM pizza_runner.customer_orders
		WHERE exclusion_2 IS NOT NULL
		GROUP BY 1) T1
	ORDER BY freq DESC
	LIMIT 1)
	
SELECT topping_name
FROM pizza_runner.pizza_toppings
WHERE topping_id = (SELECT * FROM most_excluded)

-- Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

WITH prep_tbl AS(
	SELECT *, ROW_NUMBER() OVER()
	FROM pizza_runner.customer_orders co),

	exclusion_1 AS(
	SELECT co.row_number,co.pizza_id, co.order_id, pt.topping_name AS excluded_1
	FROM prep_tbl co
	LEFT JOIN pizza_runner.pizza_toppings pt
	ON co.exclusion_1 = pt.topping_id),
	
	exclusion_2 AS(
	SELECT co.row_number, co.order_id, pt.topping_name AS excluded_2
	FROM prep_tbl co
	LEFT JOIN pizza_runner.pizza_toppings pt
	ON co.exclusion_2 = pt.topping_id),
	
	extra_1 AS(
	SELECT co.row_number, co.order_id, pt.topping_name AS extra_1
	FROM prep_tbl co
	LEFT JOIN pizza_runner.pizza_toppings pt
	ON co.extras_1 = pt.topping_id),
	
	extra_2 AS(
	SELECT co.row_number, co.order_id, pt.topping_name AS extra_2
	FROM prep_tbl co
	LEFT JOIN pizza_runner.pizza_toppings pt
	ON co.extras_2 = pt.topping_id),
	
	order_summary AS (
	SELECT ex_1.row_number, ex_1.order_id,pn.pizza_name, ex_1.excluded_1, ex_2.excluded_2, ext_1.extra_1, ext_2.extra_2
	FROM exclusion_1 ex_1
	LEFT JOIN pizza_runner.pizza_names pn
	ON ex_1.pizza_id = pn.pizza_id
	LEFT JOIN exclusion_2 ex_2
	ON ex_1.row_number = ex_2.row_number
	LEFT JOIN extra_1 ext_1
	ON ex_1.row_number = ext_1.row_number
	LEFT JOIN extra_2 ext_2
	ON ex_1.row_number = ext_2.row_number)

SELECT 
	CASE
		WHEN excluded_1 IS NOT NULL AND excluded_2 IS NOT NULL AND extra_1 IS NOT NULL AND extra_2 IS NOT NULL 
			THEN CONCAT(pizza_name,' - Exclude ', excluded_1, ', ', excluded_2, ' - Extra ', extra_1, ', ', extra_2)
			
		WHEN excluded_1 IS NULL AND excluded_2 IS NULL AND extra_1 IS NULL AND extra_2 IS NULL 
			THEN pizza_name
			
		WHEN excluded_1 IS NOT NULL AND excluded_2 IS NULL AND extra_1 IS NOT NULL AND extra_2 IS NOT NULL 
			THEN CONCAT(pizza_name,' - Exclude ', excluded_1, ' - Extra ', extra_1, ', ', extra_2)
			
		WHEN excluded_1 IS NULL AND excluded_2 IS NULL AND extra_1 IS NOT NULL AND extra_2 IS NULL 
			THEN CONCAT(pizza_name, ' - Extra ', extra_1)
			
		WHEN excluded_1 IS NOT NULL AND excluded_2 IS NULL AND extra_1 IS NULL AND extra_2 IS NULL 
			THEN CONCAT(pizza_name,' - Exclude ', excluded_1)
			
		END AS summary
FROM order_summary

-- Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

WITH toppings AS(
	SELECT pizza_id,
			split_part(toppings, ', ', 1)::INT t1,
			split_part(toppings, ', ', 2)::INT t2,
			split_part(toppings, ', ', 3)::INT t3,
			split_part(toppings, ', ', 4)::INT t4,
			split_part(toppings, ', ', 5)::INT t5,
			split_part(toppings, ', ', 6)::INT t6,
			CASE 
				WHEN split_part(toppings, ', ', 7) = '' THEN Null
				ELSE split_part(toppings, ', ', 7)::INT
			END AS t7,

			CASE 
				WHEN split_part(toppings, ', ', 8) = '' THEN Null
				ELSE split_part(toppings, ', ', 8)::INT
			END AS t8
	FROM pizza_runner.pizza_recipes),
	
	toppings_tbl AS(
	SELECT top.pizza_id, pn.pizza_name, top.t1, top.t2, top.t3, top.t4, top.t5, top.t6, top.t7, top.t8
	FROM toppings top,
		pizza_runner.pizza_names pn
	WHERE top.pizza_id = pn.pizza_id),
	
	pizza_recipe AS(
	SELECT topping_id, topping_name t1, topping_name t2, topping_name t3,
		topping_name t4, topping_name t5, topping_name t6, topping_name t7, topping_name t8
	FROM pizza_runner.pizza_toppings),
	
	parse_recipe_name AS(
	SELECT tt.pizza_id,
		CASE WHEN tt.pizza_name = 'Meatlovers' THEN 'Meat Lovers'
			ELSE pizza_name
			END,
		pr1.t1, pr2.t2, pr3.t3, pr4.t4, pr5.t5, pr6.t6, pr7.t7, pr8.t8
	FROM toppings_tbl tt
	LEFT JOIN pizza_recipe pr1
	ON tt.t1 = pr1.topping_id
	LEFT JOIN pizza_recipe pr2
	ON tt.t2 = pr2.topping_id
	LEFT JOIN pizza_recipe pr3
	ON tt.t3 = pr3.topping_id
	LEFT JOIN pizza_recipe pr4
	ON tt.t4 = pr4.topping_id
	LEFT JOIN pizza_recipe pr5
	ON tt.t5 = pr5.topping_id
	LEFT JOIN pizza_recipe pr6
	ON tt.t6 = pr6.topping_id
	LEFT JOIN pizza_recipe pr7
	ON tt.t7 = pr7.topping_id
	LEFT JOIN pizza_recipe pr8
	ON tt.t8 = pr8.topping_id)

SELECT pizza_id,
	CASE
		WHEN pizza_id = 1
			THEN CONCAT(pizza_name, ': 2x',t1,', ',t2,', ',t3,', ',t4,', ',t5,', ',t6,', ',t7,', ',t8)
			ELSE CONCAT(pizza_name, ': ',t1,', ',t2,', ',t3,', ',t4,', 2x',t5,', ',t6)
		END AS ing_summary
FROM parse_recipe_name

--"Meat Lovers: 2xBacon, Beef, ... , Salami"

-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?