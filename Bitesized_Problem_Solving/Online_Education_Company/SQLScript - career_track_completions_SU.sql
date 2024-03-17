USE sql_and_tableau;

-- CTE for exposure adding student_track_id index and calculating days_for_completion
-- student_track_id using ROW_NUMBER() / days_for_completion using DATEDIFF
WITH cte_id_and_days_completion as (
SELECT
ROW_NUMBER() OVER (ORDER BY student_id) as student_track_id, 
student_id,
track_id,
date_enrolled,
DATEDIFF(date_completed, date_enrolled)  as days_for_completion
FROM career_track_student_enrollments
),

-- CTE for using CASE to know if track was completed or not as track_completed (yes [1] / no [0]) using CASE

cte_track_completion as (
SELECT
student_track_id,
student_id,
track_id,
date_enrolled,
days_for_completion,
CASE WHEN days_for_completion IS NOT NULL THEN '1' ELSE '0' END as track_completed
FROM cte_id_and_days_completion
)
SELECT 
    c.student_track_id,
	c.student_id,
	t.track_name,
	c.date_enrolled,
	c.track_completed,
	c.days_for_completion
FROM
    cte_track_completion c
        INNER JOIN
    career_track_info t ON c.track_id = t.track_id
    ORDER BY student_track_id;


-- Create a view to find out how many students are enrolled in more than one track
CREATE VIEW enrol_status AS
    SELECT 
        student_id,
        COUNT(DISTINCT track_id) AS tracks,
        CASE
            WHEN COUNT(DISTINCT track_id) = 1 THEN 'SINGLE'
            ELSE 'MULTIPLE'
        END AS enrol_status
    FROM
        career_track_student_enrollments
    GROUP BY student_id;

SELECT 
    enrol_status, COUNT(DISTINCT student_id) as no_of_students
FROM
    enrol_status
GROUP BY enrol_status;