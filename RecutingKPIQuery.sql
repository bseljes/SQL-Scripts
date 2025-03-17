/*
This query pulls the sales rep KPI numbers for use in recruiting
*/

DECLARE @StartDate DATE = DATEADD(DAY, -30, CAST(GETDATE() AS DATE));
DECLARE @EndDate DATE = CAST(GETDATE() AS DATE);
WITH RankedAppt AS (
    SELECT
        customer_name,
        closer,
        ROW_NUMBER() OVER (PARTITION BY closer ORDER BY COALESCE(appointment_date, date_outcome_updated, created_date) ASC) AS 'Ranked Appointments',
        fluent_approved_date
    FROM podio.sales_masterlistcustomers
    WHERE lead_source_type != 'Closer Only'
),
RankedFADates AS (
    SELECT 
        fluent_approved_date,
        ROW_NUMBER() OVER (PARTITION BY closer ORDER BY fluent_approved_date) AS 'Ranked FA',
        rapt.[Ranked Appointments],
        customer_name,
        closer
    FROM RankedAppt rapt
    WHERE
        fluent_approved_date IS NOT NULL
)
SELECT
    rso.full_name AS 'Full Name',
    rso.type AS 'Sales Rep Type',
    CAST(rfad.[Became Producer] AS DATE) AS 'Became Producer',
    CAST(rfad.[Became Performer] AS DATE) AS 'Sold 5 Deals',
    rfad.[Appts to 1 Deal],
    rfad.[Appts to 5 deals],
    CAST(rso.preferred_training_date AS DATE) AS 'Preferred Training Date',
    DATEDIFF(DAY, preferred_training_date, rfad.[Became Producer]) AS 'Time to 1 Deal',
    DATEDIFF(DAY, preferred_training_date, rfad.[Became Performer]) AS 'Time to 5 Deals',
    rso.indeed_id AS 'Indeed ID',
    rso.previous_sales_rep AS 'Previous Sales Rep',
    rso.sales_office AS 'Sales Office',
    rso.recruited_by AS 'Recruited By',
    candidate_show_for_training AS 'Show for Training?',
    rep_setter_id AS 'Setter ID',
    rso.recruit_type AS 'Recruit Type',
    rso.applied_date AS 'Applied Date',
    COALESCE(fa.[Total FAs], 0) AS 'Total FAs',
    COALESCE(fa.[Total Appts], 0) AS 'Total Appts',
    COALESCE(fa.[Total Close %], 0) AS 'Total Close %',
    fa.[-30 Days FAs],
    fa.[-30 Days Appts],
    COALESCE(fa.[Close % -30 Days], 0) AS 'Close % -30 Days',
    CASE WHEN ssr.rep_status = 'Inactive' Then 'Inactive' ELSE 'Active' END AS 'Active Status',
    CASE
        WHEN fa.[Total FAs] > 4 AND 
        (fa.[Close % -30 Days] >= 0.05 OR fa.[Total Close %] >= 0.05) THEN 'Performer'
        WHEN fa.[Total FAs] > 0 THEN 'Producer'
        ELSE 'No FAs'
    END AS 'Performance'
FROM
    podio.rep_support_onboardingrequests rso
LEFT JOIN (
    SELECT
    MIN(fluent_approved_date) AS 'Became Producer',
    MAX(CASE WHEN [Ranked FA] = 5 THEN RankedFADates.fluent_approved_date ELSE NULL END) AS 'Became Performer',
    MAX(CASE WHEN [Ranked FA] = 5 THEN [Ranked Appointments] ELSE NULL END) AS 'Appts to 5 deals',
    MAX(CASE WHEN [Ranked FA] = 1 THEN [Ranked Appointments] ELSE NULL END) AS 'Appts to 1 Deal',
    closer
    FROM RankedFADates
    GROUP BY
    closer) rfad
    ON rfad.closer = rso.full_name
LEFT JOIN (
    SELECT
        psm.closer,
        COUNT(CASE WHEN psm.fluent_approved_date <> 0 THEN 1 END) AS 'Total FAs',
        COUNT(CASE WHEN psm.fluent_approved_date BETWEEN @StartDate AND @EndDate THEN 1 END) AS '-30 Days FAs',
        COUNT(CASE WHEN COALESCE(appointment_date, date_outcome_updated, psm.created_date) IS NOT NULL THEN 1 END) AS 'Total Appts',
        COUNT(CASE WHEN COALESCE(appointment_date, date_outcome_updated, psm.created_date) BETWEEN @StartDate AND @EndDate THEN 1 END) AS '-30 Days Appts',
        ROUND(CAST(COUNT(CASE WHEN psm.fluent_approved_date IS NOT NULL THEN 1 END) AS FLOAT) /
            NULLIF(CAST(
                COUNT(CASE WHEN COALESCE(psm.appointment_date, date_outcome_updated, psm.created_date) IS NOT NULL THEN 1 END) AS FLOAT), 0), 3
        ) AS 'Total Close %',
        ROUND(IIF(
            COUNT(CASE WHEN COALESCE(appointment_date, date_outcome_updated, psm.created_date) BETWEEN @StartDate AND @EndDate THEN 1 END) = 0, 0,
                CAST(COUNT(CASE WHEN fluent_approved_date BETWEEN @StartDate AND @EndDate THEN 1 END) AS FLOAT) /
                NULLIF(CAST(
                    COUNT(CASE WHEN COALESCE(appointment_date, date_outcome_updated, psm.created_date) BETWEEN @StartDate AND @EndDate THEN 1 END) AS FLOAT), 0)), 3
        ) AS 'Close % -30 Days'
    FROM
        podio.sales_masterlistcustomers psm
    GROUP BY
        psm.closer
) fa ON fa.closer = rso.full_name
LEFT JOIN(
    SELECT
    rep_name,
    rep_status
    FROM
    podio.setups_salesreps
) ssr ON REPLACE(REPLACE(ssr.rep_name, '(Inactive)', ''), ' ', '') = rso.full_name
WHERE
    rso.type LIKE '%closer%'
    AND rso.agreement_status != 'Cancelled'