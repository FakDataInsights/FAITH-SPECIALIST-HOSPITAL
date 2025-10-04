--CREATE PATIENTS TABLE
CREATE TABLE patient_details(
	patient_id INT PRIMARY KEY,
	name VARCHAR(50),
	age INT,
	gender VARCHAR(10),
	occupation VARCHAR(50),
	level_of_education VARCHAR(50),
	marital_status VARCHAR(50)
);


--CREATE DOCTORS TABLE
CREATE TABLE doctors(
	doctor_id VARCHAR(10) PRIMARY KEY,
	doctor_name VARCHAR(50),
	gender VARCHAR(1),
	email VARCHAR(50),
	specialization VARCHAR(50)
);


--CREATE ADMISSION TABLE
CREATE TABLE admission_details(
	admission_id INT PRIMARY KEY,
	patient_id INT REFERENCES patient_details(patient_id),
	admission_duration INT,
	doctor_id VARCHAR(10) REFERENCES doctors(doctor_id),
	dama VARCHAR(10),
	reason_for_dama VARCHAR(50),
	dead VARCHAR(10),
	cause_of_dead VARCHAR(50),
	ckd VARCHAR(10),
	cause_of_ckd VARCHAR(50),
	dialysis VARCHAR(10),
	no_of_sessions INT,
	stroke VARCHAR(10),
	diabetes_mellitus VARCHAR(10),
	cancer VARCHAR(10),
	type_of_cancer VARCHAR(50), 
	pud VARCHAR(10)
);


--CREATE RISK FACTORS TABLE
CREATE TABLE risk_factors(
	patient_id INT REFERENCES patient_details(patient_id),
	alcohol_history VARCHAR(10),
	tobacco_history VARCHAR(10),
	nsaid_use VARCHAR(10)
);



--REVIEWING TABLES
SELECT *
FROM patient_details;

SELECT *
FROM doctors;

SELECT *
FROM admission_details;

SELECT *
FROM risk_factors;


--PATIENTS WHO DISCHARGE AGAINST MEDICAL ADVICE BY DEMOGRAPHICS
SELECT 
  p.patient_id,
  p.name,
  p.age,
  p.gender,
  p.occupation,
  p.level_of_education,
  p.marital_status,
  a.admission_id,
  a.dama,
  a.reason_for_dama
FROM patient_details p
JOIN admission_details a ON p.patient_id = a.patient_id
WHERE a.dama = 'Yes'
ORDER BY p.age;

--COUNT OF DAMA BY AGE GROUP AND GENDER
SELECT 
  CASE 
    WHEN p.age < 15 THEN '0–14'
    WHEN p.age BETWEEN 15 AND 47 THEN '15–47'
    WHEN p.age BETWEEN 48 AND 64 THEN '48–64'
    ELSE '65+' 
  END AS age_group,
  p.gender,
  COUNT(*) AS count_of_dama
FROM patient_details p
JOIN admission_details a ON p.patient_id = a.patient_id
WHERE a.dama = 'Yes'
GROUP BY age_group, p.gender
ORDER BY count_of_dama DESC;

--COUNT OF DAMA BY LEVEL OF EDUCATION
SELECT 
	p.level_of_education,
	COUNT(*) AS count_of_dama
FROM patient_details p
JOIN admission_details a ON p.patient_id = a.patient_id
WHERE a.dama = 'Yes'
GROUP BY p.level_of_education
ORDER BY count_of_dama DESC;

--TOP 3 DAMA BY MARITAL STATUS
SELECT 
	p.marital_status,
	COUNT(*) AS count_of_dama
FROM patient_details p
JOIN admission_details a ON p.patient_id = a.patient_id
WHERE a.dama = 'Yes'
GROUP BY p.marital_status
ORDER BY count_of_dama DESC
LIMIT 3;

-- COMMON REASON FOR DAMA
SELECT 
	reason_for_dama, 
    COUNT(*) AS frequency
FROM admission_details
WHERE dama = 'Yes' AND reason_for_dama IS NOT NULL
GROUP BY reason_for_dama
ORDER BY frequency DESC;

-- AVERAGE LENGTH OF STAY
SELECT 
  ROUND(AVG(admission_duration), 2) AS avg_stay_overall,
  MAX(admission_duration) AS longest_stay,
  MIN(admission_duration) AS shortest_stay
FROM admission_details;

--AVERAGE LENGTH OF STAY BY CHRONIC DISEASE
SELECT 
  'CKD' AS condition,
  ROUND(AVG(admission_duration), 2) AS avg_duration
FROM admission_details
WHERE CKD = 'Yes'
UNION ALL
SELECT 
  'Stroke',
  ROUND(AVG(admission_duration), 2)
FROM admission_details
WHERE stroke = 'Yes'
UNION ALL
SELECT 
  'Diabetes_mellitus',
  ROUND(AVG(admission_duration), 2)
FROM admission_details
WHERE diabetes_mellitus = 'Yes'
UNION ALL
SELECT 
  'Cancer',
  ROUND(AVG(admission_duration), 2)
FROM admission_details
WHERE cancer = 'Yes'
UNION ALL
SELECT 
  'Pelvic_ulcer_disease',
  ROUND(AVG(admission_duration), 2)
FROM admission_details
WHERE pud = 'Yes';


-- EFFECT OF LENGTH OF STAY ON DAMA
SELECT 
  CASE 
    WHEN admission_duration <= 3 THEN '0–3 days'
    WHEN admission_duration BETWEEN 4 AND 7 THEN '4–7 days'
    WHEN admission_duration BETWEEN 8 AND 14 THEN '8–14 days'
    ELSE '15+ days'
  END AS duration_group,
  COUNT(*) FILTER (WHERE dama = 'Yes') AS dama_case,
  COUNT(*) AS total_patients
FROM admission_details
GROUP BY duration_group
ORDER BY duration_group;

--EFFECT OF LENGTH OF STAY ON MORTALITY
SELECT 
  CASE 
    WHEN admission_duration <= 3 THEN '0–3 days'
    WHEN admission_duration BETWEEN 4 AND 7 THEN '4–7 days'
    WHEN admission_duration BETWEEN 8 AND 14 THEN '8–14 days'
    ELSE '15+ days'
  END AS duration_group,
  COUNT(*) FILTER (WHERE dead = 'Yes') AS dama_case,
  COUNT(*) AS total_patients
FROM admission_details
GROUP BY duration_group
ORDER BY duration_group;


--TOTAL DEATH COUNT
SELECT
	COUNT(*) AS total_deaths
FROM admission_details
WHERE dead = 'Yes';

--CAUSE OF DEAD
SELECT 
    cause_of_dead, 
    COUNT(*) AS death_count
FROM admission_details
WHERE dead = 'Yes' AND cause_of_dead IS NOT NULL
GROUP BY cause_of_dead
ORDER BY death_count DESC;

--SPECIALIZATION WITH HIGHEST DEATH RATE
SELECT 
    d.specialization,
    COUNT(*) AS total_admissions,
    COUNT(CASE WHEN a.dead = 'Yes' THEN 1 END) AS total_deaths,
    ROUND(COUNT(CASE WHEN a.dead = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2) AS death_rate_percent
FROM doctors d
JOIN admission_details a ON d.doctor_id = a.doctor_id
GROUP BY d.specialization
ORDER BY death_rate_percent DESC;


--LINKING SPECIALIZATION WITH HIGHEST DEATH RATE TO CAUSE OF DEATH
SELECT 
    a.cause_of_dead,
    COUNT(*) AS death_count
FROM admission_details a
JOIN doctors d ON a.doctor_id = d.doctor_id
WHERE a.dead = 'Yes' AND d.specialization = 'Emergency medicine' 
GROUP BY a.cause_of_dead
ORDER BY death_count DESC;

--AGE GROUP DYING OF SEPSIS IN EMERGENCY MEDICINE
SELECT 
    CASE 
        WHEN p.age < 15 THEN '0-14'
        WHEN p.age BETWEEN 15 AND 47 THEN '15-47'
        WHEN p.age BETWEEN 48 AND 64 THEN '48-64'
        ELSE '65+' 
    END AS age_group,
    COUNT(*) AS sepsis_deaths
FROM patient_details p
JOIN admission_details a ON p.patient_id = a.patient_id
JOIN doctors d ON a.doctor_id = d.doctor_id
WHERE a.dead = 'Yes' AND d.specialization = 'Emergency medicine' AND a.cause_of_dead = 'Sepsis'
GROUP BY age_group
ORDER BY sepsis_deaths DESC;


-- GENDER WITH HIGH MORTALITY RATE 
SELECT 
    p.gender, 
    COUNT(*) AS death_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_of_death
FROM patient_details p
JOIN admission_details a ON p.patient_id = a.patient_id
WHERE a.dead = 'Yes'
GROUP BY p.gender
ORDER BY percentage_of_death DESC;

--AGE GROUP WITH HIGH MORTALITY RATE
SELECT 
    CASE 
        WHEN p.age < 15 THEN '0-14'
        WHEN p.age BETWEEN 15 AND 47 THEN '15-47'
        WHEN p.age BETWEEN 48 AND 64 THEN '48-64'
        ELSE '65+' 
    END AS age_group,
    COUNT(*) AS death_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_of_death
FROM patient_details p
JOIN admission_details a ON p.patient_id = a.patient_id
WHERE a.dead = 'Yes'
GROUP BY age_group
ORDER BY percentage_of_death DESC;

--PREVALENCE OF CHRONIC DISEASE AMONG PATIENTS
WITH illness_counts AS (
    SELECT 'CKD' AS illness, 
	COUNT(*) AS count FROM admission_details 
	WHERE ckd = 'Yes'
UNION ALL
    SELECT 'Stroke', 
	COUNT(*) FROM admission_details 
	WHERE stroke = 'Yes'
UNION ALL
    SELECT 'Diabetes Mellitus', 
	COUNT(*) FROM admission_details 
	WHERE diabetes_mellitus = 'Yes'
UNION ALL
    SELECT 'Cancer', 
	COUNT(*) FROM admission_details 
	WHERE cancer = 'Yes'
UNION ALL
    SELECT 'Peptic Ulcer Disease', 
	COUNT(*) FROM admission_details 
	WHERE pud = 'Yes'
)

SELECT 
    illness,
    count,
    ROUND(count * 100.0 / SUM(count) OVER (), 2) AS percentage
FROM illness_counts
ORDER BY percentage DESC;

--RISK FACTORS ON DEATH 
SELECT 
    r.alcohol_history, 
	r.tobacco_history, 
	r.nsaid_use,
    COUNT(CASE WHEN a.dead = 'Yes' THEN 1 END) AS death_count
FROM risk_factors r
JOIN admission_details a ON r.patient_id = a.patient_id
GROUP BY r.alcohol_history, r.tobacco_history, r.nsaid_use
ORDER BY death_count DESC;


SELECT 
    CASE 
        WHEN p.age < 15 THEN '0-14'
        WHEN p.age BETWEEN 15 AND 47 THEN '15-47'
        WHEN p.age BETWEEN 48 AND 64 THEN '48-64'
        ELSE '65+' 
    END AS age_group,
    a.dead,
    r.alcohol_history,
    r.tobacco_history,
    r.nsaid_use,
    COUNT(*) AS patient_count
FROM patient_details p
JOIN admission_details a ON p.patient_id = a.patient_id
JOIN risk_factors r ON a.patient_id = r.patient_id
WHERE 
    r.alcohol_history = 'No' AND r.tobacco_history = 'No' AND r.nsaid_use = 'No' AND a.dead = 'Yes'
GROUP BY age_group, a.dead, r.alcohol_history, r.tobacco_history, r.nsaid_use
ORDER BY patient_count DESC;


--AGE AND CHRONIC DISEASE BREAKDOWN FOR THOSE WHO DIED BUT WERE NOT AFFECTED BY THEIR LIFE STYLE
SELECT 
    CASE 
        WHEN p.age < 15 THEN '0-14'
        WHEN p.age BETWEEN 15 AND 47 THEN '15-47'
        WHEN p.age BETWEEN 48 AND 64 THEN '48-64'
        ELSE '65+' 
    END AS age_group,
	COUNT(*) AS total_deaths,
	COUNT(CASE WHEN a.ckd = 'Yes' THEN 1 END) AS deaths_with_ckd,
    COUNT(CASE WHEN a.stroke = 'Yes' THEN 1 END) AS deaths_with_stroke,
    COUNT(CASE WHEN a.diabetes_mellitus = 'Yes' THEN 1 END) AS deaths_with_diabetes,
    COUNT(CASE WHEN a.cancer = 'Yes'THEN 1 END) AS deaths_with_cancer,
    COUNT(CASE WHEN a.pud = 'Yes' THEN 1 END) AS deaths_with_pud
FROM patient_details p
JOIN admission_details a ON p.patient_id = a.patient_id
JOIN risk_factors r ON a.patient_id = r.patient_id
WHERE a.dead = 'Yes'
    AND r.alcohol_history = 'No'
    AND r.tobacco_history = 'No'
    AND r.nsaid_use = 'No'
GROUP BY age_group
ORDER BY age_group;



--AGE GROUP AT HIGH RISK
SELECT 
    CASE 
        WHEN p.age < 15 THEN '0-17'
        WHEN p.age BETWEEN 15 AND 47 THEN '15-47'
        WHEN p.age BETWEEN 48 AND 64 THEN '48-64'
        ELSE '65+' 
    END AS age_group,
    COUNT(CASE WHEN a.dead = 'Yes' THEN 1 END) AS death_count,
    COUNT(CASE WHEN a.dama = 'Yes' THEN 1 END) AS dama_count
FROM patient_details p
JOIN admission_details a ON p.patient_id = a.patient_id
GROUP BY age_group
ORDER BY death_count DESC, 
dama_count DESC;



--TOTAL DOCTORS
SELECT
	COUNT (*) AS total_doctors
FROM doctors;


--PERFORMANCE OF DOCTOR BY SPECIALIZATION AND OUTCOMES
SELECT 
    d.doctor_name,
	d.doctor_id,
    d.specialization,
    COUNT(*) AS total_patients,
    COUNT(CASE WHEN a.dead = 'Yes' THEN 1 END) AS total_deaths,
    COUNT(CASE WHEN a.dama = 'Yes' THEN 1 END) AS total_dama,
    ROUND(COUNT(CASE WHEN a.dead = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2) AS death_rate_percent,
    ROUND(COUNT(CASE WHEN a.dama = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2) AS dama_rate_percent,
 -- Ranking within specialization
    RANK() OVER (PARTITION BY d.specialization ORDER BY 
                 COUNT(CASE WHEN a.dead = 'Yes' THEN 1 END) * 1.0 / COUNT(*) ASC) AS rank_in_specialization,
-- Overall ranking by performance (lower death rate)
    RANK() OVER (ORDER BY 
                 COUNT(CASE WHEN a.dead = 'Yes' THEN 1 END) * 1.0 / COUNT(*) ASC) AS overall_rank
FROM doctors d
JOIN admission_details a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_name, d.doctor_id, d.specialization
ORDER BY d.specialization, rank_in_specialization;



--PERFORMANCE OF DOCTORS BASED ON WORKLOAD AND OUTCOMES
SELECT 
    d.doctor_id,
    d.doctor_name,
    d.specialization,
    COUNT(*) AS total_patients,
    COUNT(CASE WHEN a.dead = 'Yes' THEN 1 END) AS total_deaths,
    ROUND(COUNT(CASE WHEN a.dead = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2) AS death_rate_percent,
    COUNT(CASE WHEN a.dama = 'Yes' THEN 1 END) AS total_dama,
    ROUND(COUNT(CASE WHEN a.dama = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2) AS dama_rate_percent,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS workload_rank,
    RANK() OVER (ORDER BY COUNT(CASE WHEN a.dead = 'Yes' THEN 1 END) ASC) AS performance_rank_low_death,
    RANK() OVER (ORDER BY COUNT(CASE WHEN a.dama = 'Yes' THEN 1 END) ASC) AS performance_rank_low_dama
FROM doctors d
JOIN admission_details a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.doctor_name, d.specialization
ORDER BY workload_rank;
