USE mban_a32_aws_services;


SELECT *
FROM checkout_actions
group by error_message;

-- Final Query for Quick Sight

-- CTE for categorising services (Amazon Prime, One Medical, Prime Video etc.)
WITH cte_service as 
(SELECT 
    user_id, action_date, device, action_name, error_message,
    MONTHNAME(action_date) AS month,
    YEAR(action_date) AS year,
    (CASE
        WHEN action_name LIKE '%monthly%' THEN 'Amazon Prime'
        WHEN action_name LIKE '%annual%' THEN 'Amazon Prime'
        WHEN action_name LIKE '%quarterly%' THEN 'Amazon Prime'
        WHEN action_name LIKE '%landing%' THEN 'Amazon Prime'
        WHEN action_name LIKE '%video%' THEN 'Prime Video'
        WHEN action_name LIKE '%lifetime%' THEN 'Amazon Prime'
        WHEN action_name LIKE '%amazon-music%' THEN 'Amazon Music'
        WHEN action_name LIKE '%one%' THEN 'One Medical'
        WHEN action_name LIKE '%gift%' THEN 'Gift cards'
        WHEN action_name LIKE '%delivery%' THEN 'Fast Delivery'
    END) AS service
FROM checkout_actions),
-- CTE for subscription types for Relevant Services (Monthly, Quarterly, Annual or Lifetime)
cte_subs as 
(SELECT user_id, action_date, device, action_name, error_message,
    MONTHNAME(action_date) AS month,
    YEAR(action_date) AS year, 
    service,
	(CASE
        WHEN action_name LIKE '%monthly%' THEN 'Monthly'
        WHEN action_name LIKE '%annual%' THEN 'Annual'
        WHEN action_name LIKE '%lifetime%' THEN 'Lifetime'
        WHEN action_name LIKE '%quarterly%' THEN 'Quarterly'
        ELSE 'Not Applicable'
    END) AS subscription
FROM cte_service),
-- CTE for website activity (Checkout Page or Landing Page)
cte_web_activity as
(SELECT user_id, action_date, device, action_name, error_message,
    MONTHNAME(action_date) AS month,
    YEAR(action_date) AS year, 
    service,
    subscription,
    (CASE
        WHEN action_name LIKE '%completepayment%' THEN 'Checkout Page'
        ELSE 'Landing Page'
    END) AS `website_activity`
FROM cte_subs),
-- CTE for payment status 
cte_payment as
(SELECT user_id, action_date, device, action_name, error_message,
    MONTHNAME(action_date) AS month,
    YEAR(action_date) AS year, 
    service,
    subscription,
    website_activity,
    (CASE
		WHEN action_name LIKE '%fail%' THEN 'Failed'
        WHEN action_name LIKE '%success%' THEN 'Successful'
        ELSE 'Not Applicable'
    END) AS payment_status
FROM cte_web_activity
),
-- CTE for categorizing type of error  
cte_error as
(SELECT user_id, action_date, device, action_name, error_message,
    MONTHNAME(action_date) AS month,
    YEAR(action_date) AS year, 
    service,
    subscription,
    website_activity,
    payment_status,
    (CASE
		WHEN error_message LIKE '%required%' THEN 'Incomplete Information'
        WHEN error_message LIKE '%valid%' THEN 'Incomplete Information'
        WHEN error_message LIKE '%incorrect%' THEN 'Incomplete Information'
        WHEN error_message LIKE '%hour%' THEN 'Incomplete Information'
        WHEN error_message LIKE '%blank%' THEN 'Incomplete Information'
        WHEN error_message LIKE '%declined%' THEN 'Card Declined'
        WHEN error_message LIKE '%funds%' THEN 'Card Declined'
        WHEN error_message LIKE '%purchase%' THEN 'Card Declined'
        WHEN error_message LIKE '%error%' THEN 'Card Declined'
        WHEN error_message LIKE '%supported%' THEN 'Card Declined'
        WHEN error_message LIKE '%expired%' THEN 'Card Declined'
        WHEN action_name LIKE '%success%' THEN 'No Error'
        WHEN action_name LIKE '%landing%' THEN 'Not Applicable'
        ELSE 'Other'
    END) AS error_type
FROM cte_payment)
SELECT 
	user_id, device, action_date, `month`, `year`, service, subscription, website_activity, payment_status, error_type
FROM cte_error;


-- Other Analysis
SELECT error_message, COUNT(*) as error_count
FROM checkout_actions
WHERE action_name LIKE '%fail%'
GROUP BY error_message
ORDER BY error_count DESC;

-- Analyzing failed payment errors 
SELECT action_name, COUNT(*) AS action_count
FROM checkout_actions
WHERE action_name LIKE '%fail%'
GROUP BY action_name
ORDER BY action_count DESC;

-- Analyzing successful payments 
SELECT action_name, COUNT(*) AS action_count
FROM checkout_actions
WHERE action_name LIKE '%success%'
GROUP BY action_name
ORDER BY action_count DESC;

-- impact of device type for errors
SELECT device, COUNT(*) AS action_count
FROM checkout_actions
GROUP BY device;

SELECT device, COUNT(*) AS action_count
FROM checkout_actions
WHERE action_name LIKE '%fail%'
GROUP BY device;

SELECT device, COUNT(*) AS action_count
FROM checkout_actions
WHERE action_name LIKE '%success%'
GROUP BY device;

-- Monthly trend in user actions
SELECT DATE_FORMAT(action_date, '%Y-%m') AS month, COUNT(*) AS action_count
FROM checkout_actions
GROUP BY month
ORDER BY month;

-- Monthly trend in successful subscriptions
SELECT DATE_FORMAT(action_date, '%Y-%m') AS month, COUNT(*) AS subscription_count
FROM prime_subscriptions
GROUP BY month
ORDER BY month;


