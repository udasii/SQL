USE mban_a33;

-- Q1 Which courses are the most watched by students, and how are they rated? 

-- ANSWER: 
-- Query - A.1
-- PART a. Most watched courses by students based on total watch time
WITH cte_courses_by_watchtime AS
(SELECT course_id as course_id, 
		ROUND(SUM(minutes_watched)) as total_watch_time
FROM student_learning
GROUP BY course_id
ORDER BY total_watch_time DESC),

-- PART B. Most watched courses by students based on total students enrolled
cte_courses_by_students AS
(SELECT course_id as course_id, 
		COUNT(DISTINCT student_id) as total_students
FROM student_learning
GROUP BY course_id
ORDER BY total_students DESC),

-- PART C. Gathering Names for the course_id
cte_course_info AS
(SELECT course_id, course_title, AVG(course_rating) as avg_rating
FROM course_ratings
INNER JOIN course_info using (course_id)
GROUP BY course_id
ORDER BY avg_rating DESC)

-- Final Summary
SELECT i.course_id, i.course_title, i.avg_rating, c.total_watch_time, s.total_students
FROM cte_course_info i
INNER JOIN cte_courses_by_students s using (course_id)
INNER JOIN cte_courses_by_watchtime c using (course_id)
ORDER BY total_watch_time DESC;

-- Q2 How many students register each month, and what fraction are also onboarded?
-- ANSWER: 
-- Query - A.2.1
with cte_registered_purchases as
(SELECT 
	student_id, date_registered,
    (case when student_id IN (SELECT student_id FROM student_purchases) THEN 1 ELSE 0 END) as registered_and_purchased
    FROM
        student_info),
cte_registered_learning as
(SELECT 
	student_id, date_registered,
    (case when student_id IN (SELECT student_id FROM student_learning) THEN 1 ELSE 0 END) as registered_and_learning
    FROM
        student_info)

SELECT 
    DATE_FORMAT(si.date_registered, '%Y-%m') AS `date`,
    MONTHNAME(si.date_registered) AS `month`,
    COUNT(DISTINCT student_id) AS registered_students,
    SUM(rp.registered_and_purchased) as registered_and_purchased,
    CONCAT(ROUND((SUM(rp.registered_and_purchased)/COUNT(DISTINCT student_id)*100) , 1), '%') as '% of registered students who subscribed',
    SUM(rl.registered_and_learning) as registered_and_learning,
    CONCAT(ROUND((SUM(rl.registered_and_learning)/COUNT(DISTINCT student_id)*100),1),'%') as '% of registered students watching content'
FROM
    student_info si
INNER JOIN cte_registered_purchases rp using(student_id)
INNER JOIN cte_registered_learning rl using(student_id)
GROUP BY MONTH(si.date_registered);

-- Query - A.2.2
with cte_registered_purchases as
(SELECT 
	student_id, date_registered,
    (case when student_id IN (SELECT student_id FROM student_purchases) THEN 1 ELSE 0 END) as registered_and_purchased
    FROM
        student_info),
cte_registered_learning as
(SELECT 
	student_id, date_registered,
    (case when student_id IN (SELECT student_id FROM student_learning) THEN 1 ELSE 0 END) as registered_and_learning
    FROM
        student_info)
SELECT 
	COUNT(DISTINCT student_id) as registered_students, 
    SUM(registered_and_purchased) as student_members,
    CONCAT(ROUND((SUM(registered_and_purchased)/COUNT(DISTINCT student_id)*100),2),'%') as 'Registered Members',
    SUM(registered_and_learning) as student_learners,
    CONCAT(ROUND((SUM(registered_and_learning)/COUNT(DISTINCT student_id)*100),2),'%') as 'Registered Learners'
FROM
        student_info
INNER JOIN cte_registered_purchases p USING (student_id)
INNER JOIN cte_registered_learning l USING (student_id);


-- Q3 How do students engage with the online platform (minutes and average minutes watched) based on type (free-plan or paying)?

-- ANSWER: 
-- Query - A.3
SELECT COUNT(DISTINCT student_id) FROM mban_a33.student_learning;
-- 18,156 students that are registered are learning across multiple courses

SELECT 
    (CASE
        WHEN
            student_id IN (SELECT 
                    student_id
                FROM
                    student_purchases)
        THEN
            'paying'
        ELSE 'free-plan'
    END) AS plan_type,
    COUNT(DISTINCT student_id) AS no_of_students,
    ROUND(SUM(minutes_watched)) AS total_mins_watched,
    ROUND(AVG(minutes_watched), 2) AS avg_mins_watched
FROM
    student_learning
GROUP BY plan_type;


-- Q4: Do students watch more content with time, and does it vary seasonally?
-- ANSWER: 
-- Query - A.4
SELECT 
    MONTH(date_watched) AS `id`,
    MONTHNAME(date_watched) AS `month`,
    ROUND(SUM(minutes_watched)) AS minutes_watched
FROM
    student_learning
GROUP BY MONTHNAME(date_watched)
ORDER BY MONTH(date_watched);


-- Q5: Which countries have the most students registered, 
-- and does this number scale proportionally with the number of minutes watched per country?
-- ANSWER: 
-- Query - A.5
SELECT 
    si.student_country,
    COUNT(DISTINCT si.student_id) AS no_of_students,
    ROUND(SUM(sl.minutes_watched)) AS total_no_mins_watched
FROM
    student_info si
        LEFT JOIN
    student_learning sl USING (student_id)
GROUP BY student_country
ORDER BY no_of_students DESC; 