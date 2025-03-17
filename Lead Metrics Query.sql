DECLARE @StartDate DATE = DATEADD(DAY, -30, CAST(GETDATE() AS DATE));
DECLARE @EndDate DATE = CAST(GETDATE() AS DATE);

/*
This script queries the database and returns all sales reps lead KPI data for the past 30 days and returns it as sorted and grouped data.
*/

WITH m1data AS (
    SELECT
    ssr.rep_name,
    -- # of M1s -30 Days
    COUNT(CASE WHEN COALESCE(appointment_date, date_outcome_updated, fvd.created_date) BETWEEN @StartDate AND @EndDate
    AND  commission_structure_valor != 'Closer Only' AND fvd.date_fluent_approved IS NOT NULL AND fund.concert_permitting_milestone_disbursed_date IS NOT NULL THEN 1 ELSE NULL END) AS 'M1s',
    -- # of FAs -30 Days
    COUNT(CASE WHEN COALESCE(appointment_date, date_outcome_updated, fvd.created_date) BETWEEN @StartDate AND @EndDate
    AND commission_structure_valor != 'Closer Only' AND fvd.date_fluent_approved IS NOT NULL THEN 1 ELSE NULL END) AS 'FAs'

    FROM
    podio.setups_salesreps ssr
    LEFT JOIN podio.fs_valor_deals fvd
    ON REPLACE(ssr.rep_name, ' (Inactive)', '') = REPLACE(fvd.closer, ' (Inactive)', '')
    LEFT JOIN podio.project_management_funding fund
    ON fvd.project_master_id = fund.project_id_master
    GROUP BY rep_name
),
mainsql AS (
SELECT
ssr.sales_office AS 'Sales Office',
ssr.rep_name AS 'Name',

-- Get Status Based on training date and non self gen appts
CASE WHEN COUNT(CASE WHEN commission_structure_valor != 'Closer Only' THEN 1 ELSE NULL END) > 19 
THEN 'Current' ELSE 'New' END AS 'Status',


-- # of Appts (Setter & Paid only) - 30 Days
COUNT(CASE WHEN (COALESCE(appointment_date, date_outcome_updated, fvd.created_date) BETWEEN @StartDate AND @EndDate) 
AND (commission_structure_valor != 'Closer Only') THEN 1 ELSE NULL END) AS '# of Appts (Setter & Paid only)',

-- # of FA from Appts (Setter & Paid only) - 30 Days
COUNT(CASE WHEN (COALESCE(appointment_date, date_outcome_updated, fvd.created_date) BETWEEN @StartDate AND @EndDate) 
AND (commission_structure_valor != 'Closer Only')
AND fluent_approved_date IS NOT NULL THEN 1 ELSE NULL END) AS '# of FA from Appts (Setter & Paid only)',

-- # of Contract Signed -30 Days
COUNT(CASE WHEN CAST(pmp.contract_signed_date AS DATE) IS NOT NULL
AND fvd.commission_structure_valor != 'Closer Only'
AND COALESCE(fvd.appointment_date, fvd.date_outcome_updated, fvd.created_date)
BETWEEN @StartDate AND @EndDate THEN 1 ELSE NULL END) AS '# of Contract Signed',
-- Close % (Setter & Paid only)
CASE WHEN 
    COUNT(CASE WHEN (COALESCE(appointment_date, date_outcome_updated, fvd.created_date) BETWEEN @StartDate AND @EndDate) 
    AND (commission_structure_valor != 'Closer Only')
    AND fluent_approved_date IS NOT NULL THEN 1 ELSE NULL END) > 0
    THEN
        ROUND(COUNT(CASE WHEN (fluent_approved_date BETWEEN @StartDate AND @EndDate) 
        AND (commission_structure_valor != 'Closer Only')
        AND fluent_approved_date IS NOT NULL THEN 1 ELSE NULL END)
        /
        CAST(COUNT(CASE WHEN (COALESCE(appointment_date, date_outcome_updated, fvd.created_date) BETWEEN @StartDate AND @EndDate) 
        AND (commission_structure_valor != 'Closer Only') THEN 1 ELSE NULL END) AS FLOAT), 3) ELSE 0 END AS 'Close % (Setter & Paid only)',

-- # of Failed Credit - 30 Days
COUNT(CASE 
    WHEN (outcome LIKE '%Pitched: Failed Cred%' AND commission_structure_valor NOT LIKE 'Closer%' 
    AND COALESCE(appointment_date, date_outcome_updated, fvd.created_date) BETWEEN @StartDate AND @EndDate) THEN 1 ELSE NULL 
    END) AS '# of Failed Credit',

-- # of FA (All Lead Types) - 30 Days
COUNT(CASE WHEN COALESCE(appointment_date, date_outcome_updated, fvd.created_date) BETWEEN @StartDate AND @EndDate AND fvd.date_fluent_approved IS NOT NULL THEN 1 ELSE NULL END) AS '# of FA (All Lead Types)',

-- AVG # of Paid Leads - 30 Days
ROUND( CAST( COUNT(CASE 
WHEN (commission_structure_valor LIKE 'Paid%' OR commission_structure_valor LIKE 'Rec%') AND COALESCE(appointment_date, date_outcome_updated, fvd.created_date) BETWEEN @StartDate AND @EndDate 
THEN 1 END) AS FLOAT) / 4.2, 2) AS 'AVG # of Paid Leads',

-- AVG # of Setter Leads - 30 Days
ROUND(CAST(COUNT(CASE 
WHEN commission_structure_valor LIKE 'setter' AND COALESCE(appointment_date, date_outcome_updated, fvd.created_date) BETWEEN @StartDate AND @EndDate 
THEN 1 END) AS FLOAT) / 4.2, 2) AS 'AVG # of Setter Leads',

-- THIS CODE BLOCK IS WRONG DO NOT USE (((((((((
-- Cancel % after FA (All Time) *** Remove Self Gens from this ***
-- ISNULL(ROUND(CAST(SUM(CASE WHEN fvd.date_fluent_approved IS NOT NULL AND stage = 'Cancelled' AND commission_structure_valor NOT LIKE 'Closer%'THEN 1 ELSE 0 
-- END) AS FLOAT) / NULLIF(SUM(CASE WHEN fvd.date_fluent_approved IS NOT NULL AND commission_structure_valor NOT LIKE 'Closer%' THEN 1 
-- ELSE 0 END), 0), 2), 0) AS 'Cancel % after FA'
-- )))))))))

-- Close with M1 %
CASE WHEN MAX(m1.M1s) = 0 OR MAX(m1.FAs) = 0 THEN 0 ELSE ((MAX(m1.M1s)*100) / MAX(m1.FAs) / 100.00) END AS 'Close % With M1 (Paid & Setter Only)'
FROM
podio.setups_salesreps ssr
LEFT JOIN podio.fs_valor_deals fvd
ON REPLACE(ssr.rep_name, ' (Inactive)', '') = REPLACE(fvd.closer, ' (Inactive)', '')
LEFT JOIN
podio.project_management_projects pmp
ON pmp.project_master_id = fvd.project_master_id
LEFT JOIN podio.project_management_funding fund
ON fvd.project_master_id = fund.project_id_master
LEFT JOIN m1data m1
ON REPLACE(ssr.rep_name, ' (Inactive)', '') = REPLACE(m1.rep_name, ' (Inactive)', '')
WHERE -- (outcome NOT LIKE 'Cancelled%' AND outcome NOT LIKE 'Not Pitched: Not V%' OR outcome IS NULL)
-- AND commission_structure_valor NOT LIKE 'Self Scheduled%'
rep_status NOT LIKE '%Inactive%'
AND ssr.rep_name NOT IN ('Meena Lidder', 'Talor Schmunk')
GROUP BY ssr.sales_office, ssr.rep_name)
SELECT
*
FROM
mainsql
WHERE
[Sales Office] = 'AB Calgary'
ORDER BY
  CASE
    WHEN [Close % (Setter & Paid only)] >= 0.08 THEN 0
    ELSE 1
  END,
  [Status] DESC,
  [Close % (Setter & Paid only)] DESC