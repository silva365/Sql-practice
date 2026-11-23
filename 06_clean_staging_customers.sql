-- Business question: Which rows from the raw customer import are safe to load, in a standard format?
-- Techniques: TRIM/LOWER/REPLACE cleaning, CASE-based date parsing, validation filters, dedupe with ROW_NUMBER()
WITH normalized AS (
    SELECT
        LOWER(TRIM(raw_email)) AS email,
        -- collapse doubled spaces, then proper-case first and last name
        REPLACE(REPLACE(TRIM(raw_name), '  ', ' '), '  ', ' ') AS name_clean,
        NULLIF(TRIM(raw_city), '')                              AS city_raw,
        CASE
            WHEN raw_signup GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' THEN raw_signup
            WHEN raw_signup GLOB '[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9][0-9]' THEN REPLACE(raw_signup, '/', '-')
            WHEN raw_signup GLOB '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]'               -- MM/DD/YYYY
                 THEN substr(raw_signup, 7, 4) || '-' || substr(raw_signup, 1, 2) || '-' || substr(raw_signup, 4, 2)
        END AS signup_date
    FROM staging_customers
),
formatted AS (
    SELECT email,
           UPPER(substr(name_clean, 1, 1)) || LOWER(substr(name_clean, 2, instr(name_clean, ' ') - 1))
             || UPPER(substr(name_clean, instr(name_clean, ' ') + 1, 1))
             || LOWER(substr(name_clean, instr(name_clean, ' ') + 2))           AS full_name,
           UPPER(substr(city_raw, 1, 1)) || LOWER(substr(city_raw, 2))          AS city,
           signup_date
    FROM normalized
    WHERE email LIKE '_%@_%._%'          -- basic email validity
      AND signup_date IS NOT NULL        -- unparseable dates are rejected
),
deduped AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY email ORDER BY signup_date) AS rn
    FROM formatted
)
SELECT email, full_name, city, signup_date
FROM deduped
WHERE rn = 1
ORDER BY email;
