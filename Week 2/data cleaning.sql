-- Preprocessing tasks
-- Clean up exclusions and extras columns in the customer_orders table

ALTER TABLE pizza_runner.customer_orders
DROP COLUMN exclusion_1

ALTER TABLE pizza_runner.customer_orders
	ADD COLUMN exclusion_1 VARCHAR(5),
	ADD COLUMN exclusion_2 VARCHAR(5),
	ADD COLUMN extras_1 VARCHAR(5),
	ADD COLUMN extras_2 VARCHAR(5)

UPDATE pizza_runner.customer_orders
SET exclusion_1 = split_part(exclusions, ', ', 1),
	exclusion_2 = split_part(exclusions, ', ', 2),
	extras_1 = split_part(extras, ', ', 1),
	extras_2 = split_part(extras, ', ', 2)

UPDATE pizza_runner.customer_orders
SET exclusion_1 = (CASE WHEN exclusion_1 ~ '^\d' THEN exclusion_1
				  	ELSE Null
				  	END),
	exclusion_2 = (CASE WHEN exclusion_2 ~ '^\d' THEN exclusion_2
				  	ELSE Null
				  	END),
	extras_1 = (CASE WHEN extras_1 ~ '^\d' THEN extras_1
				  	ELSE Null
				  	END),
	extras_2 = (CASE WHEN extras_2 ~ '^\d' THEN extras_2
				  	ELSE Null
				  	END)
	
					
ALTER TABLE pizza_runner.customer_orders
ALTER COLUMN exclusion_1 TYPE INT
USING exclusion_1::integer

ALTER TABLE pizza_runner.customer_orders
ALTER COLUMN exclusion_2 TYPE INT
USING exclusion_2::integer

ALTER TABLE pizza_runner.customer_orders
ALTER COLUMN extras_1 TYPE INT
USING extras_1::integer

ALTER TABLE pizza_runner.customer_orders
ALTER COLUMN extras_2 TYPE INT
USING extras_2::integer

ALTER TABLE pizza_runner.customer_orders
DROP COLUMN exclusions

ALTER TABLE pizza_runner.customer_orders
DROP COLUMN extras


-- Fixing runner_orders table

SELECT *
FROM pizza_runner.runner_orders

ALTER TABLE pizza_runner.runner_orders
ADD COLUMN distance_km VARCHAR(5),
ADD COLUMN duration_min VARCHAR(5),
ADD COLUMN pickup_time_fixed TIMESTAMP

UPDATE pizza_runner.runner_orders
SET distance_km = regexp_replace(distance, 'km', '', 'gi'),
	duration_min = regexp_replace(duration, 'minute|minutes|mins|min','', 'gi')
	
UPDATE pizza_runner.runner_orders
SET distance_km = (CASE WHEN distance_km ~ '^\d' THEN distance_km
				  	ELSE Null
				  	END),
	duration_min = (CASE WHEN duration_min ~ '^\d' THEN duration_min
				  	ELSE Null
				  	END)
					
ALTER TABLE pizza_runner.runner_orders
ALTER COLUMN distance_km TYPE FLOAT
USING distance_km::double precision

ALTER TABLE pizza_runner.runner_orders
ALTER COLUMN duration_min TYPE FLOAT
USING duration_min::double precision

UPDATE pizza_runner.runner_orders
SET cancellation = Null
WHERE cancellation IS NULL OR cancellation = 'null' OR cancellation = ''

UPDATE pizza_runner.runner_orders
SET pickup_time = Null
WHERE pickup_time = 'null' 

UPDATE pizza_runner.runner_orders
SET pickup_time_fixed = pickup_time::timestamp
WHERE pickup_time IS NOT NULL
	
ALTER TABLE pizza_runner.runner_orders
ADD PRIMARY KEY (order_id),
DROP COLUMN distance,
DROP COLUMN duration,
DROP COLUMN pickup_time
