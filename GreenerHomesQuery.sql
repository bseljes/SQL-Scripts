/*
This query pulls Greener Homes Financial KPI info for Calgary and Edmonton sales offices.
*/

SELECT
    fvd.sales_office AS 'Sales Office',
    0 AS 'FA Plan Start Day',
    0 AS 'Actual FA Start Day',
    2 AS 'FA Plan Cycle',
    MAX(fa_cycle_time) AS 'FA Actual Cycle',
    2 AS 'SS Plan Start Day',
    MAX(ss_start_day) AS 'SS Actual Start Day',
    4 AS 'SS Plan cycle',
    MAX(ss_cycle_time) AS 'SS Actual Cycle',
    7 AS 'Design Plan Satrt Day',
    MAX(des_start_day) AS 'Design Actual Start Day',
    5 AS 'Design Plan cycle',
    MAX(design_cycle_time) AS 'Design Actual Cycle',
    8 AS 'Eng Plan Start Day',
    MAX(eng_start_day) AS 'Eng Actual Start Day',
    4 AS 'Eng Plan cycle',
    MAX(eng_cycle_time) AS 'Eng Actual Cycle',
    7 AS 'Perm Plan Start Day',
    MAX(perm_start_day) AS 'Perm Actual Start Day',
    12 AS 'Perm Plan cycle',
    MAX(perm_cycle_time) AS 'Perm Actual Cycle',
    19 AS 'Utilities Plan Start Day',
    MAX(nem_start_day) AS 'Utilities Actual Start Day',
    14 AS 'Utilities Plan cycle',
    MAX(nem_cycle_time) AS 'Utilities Actual Cycle',
    0 AS 'Pre-Retro Insp Plan Start Day',
    MAX(retro_insp_start_day) AS 'Pre-Retro Insp Actual Start Day',
    18 AS 'Pre-Retro Insp Plan cycle',
    MAX(preretrofitinsp_cycle_time) AS 'Per-Retro Insp Actual Cycle',
    32 AS 'Retrofit Doc Review Plan Start Day',
    28 AS 'Retro Doc Rev Plan cycle',
    MAX(homeowner_review_cycle_time) AS 'Homeowner Review Actual Cycle',
    60 AS 'Loan App Review Plan Start Day',
    MAX(retro_insp_start_day) AS 'Retr Insp Actual Start Day',
    28 AS 'Loan App Rev Plan cycle',
    MAX(loan_appr_den_cycle_time) AS 'Loan Appr/Den Actual Cycle',
    1 AS 'Full Process Plan Start Day',
    1 AS 'Full Process Actual Start Day',
    88 AS 'Total Plan cycle',
    MAX(total_cycle_time) AS 'Total Actual Cycle'
FROM
    podio.fs_valor_deals fvd
    LEFT JOIN (
        SELECT
            fvd.sales_office,
            AVG(DATEDIFF(DAY, LEAST(wc.createddate2, wc.contract_signed_date), fvd.date_fluent_approved)) AS fa_cycle_time
        FROM
            podio.project_management_canada can
            LEFT JOIN
            podio.project_management_welcomecalls wc
            ON can.project_master_id = wc.project_master_id
            LEFT JOIN
            podio.fs_valor_deals fvd
            ON can.project_master_id = fvd.project_master_id
        WHERE
        fvd.sales_office IN ('AB Edmonton', 'AB Calgary')
        AND fvd.date_fluent_approved IS NOT NULL
        AND COALESCE(wc.created_date, wc.contract_signed_date) IS NOT NULL
        GROUP BY
        fvd.sales_office
        ) faquery
    ON fvd.sales_office = faquery.sales_office
    LEFT JOIN (
        SELECT
            fvd.sales_office,
            AVG(DATEDIFF(DAY, LEAST(wc.createddate2, wc.contract_signed_date), pmp.date_fluent_approved)) AS ss_start_day,
            AVG(DATEDIFF(DAY, LEAST(pmp.date_fluent_approved, ss.activation_date, wc.bucket_completion_date), ss.bucket_complete_date)) AS ss_cycle_time
        FROM
            podio.project_management_canada can
            LEFT JOIN
            podio.project_management_sitesurvey ss
            ON can.project_master_id = ss.project_master_id
            LEFT JOIN
            podio.project_management_welcomecalls wc
            ON can.project_master_id = wc.project_master_id
            LEFT JOIN
            podio.project_management_projects pmp
            ON can.project_master_id = pmp.project_master_id
            LEFT JOIN
            podio.fs_valor_deals fvd
            ON can.project_master_id = fvd.project_master_id
        WHERE
            pmp.date_fluent_approved IS NOT NULL
            AND wc.bucket_completion_date IS NOT NULL
            AND ss.status = 'Complete'
            AND fvd.sales_office IN ('AB Edmonton', 'AB Calgary')
        GROUP BY
        fvd.sales_office
    ) ssquery
    ON ssquery.sales_office = fvd.sales_office
    LEFT JOIN (
        SELECT
            fvd.sales_office,
            AVG(DATEDIFF(DAY, wc.createddate2, pmd.bucket_activation_date)) AS des_start_day,
            AVG(DATEDIFF(DAY, COALESCE(ss.bucket_complete_date, fvd.date_fluent_approved), pmd.cad_complete_date)) AS design_cycle_time
        FROM
            podio.project_management_canada can
            LEFT JOIN
            podio.project_management_designs pmd
            ON can.project_master_id = pmd.project_master_id
            LEFT JOIN
            podio.project_management_welcomecalls wc
            ON can.project_master_id = wc.project_master_id
            LEFT JOIN
            podio.fs_valor_deals fvd
            ON can.project_master_id = fvd.project_master_id
            LEFT JOIN
            podio.project_management_sitesurvey ss
            ON can.project_master_id = ss.project_master_id
        WHERE
            fvd.sales_office IN ('AB Edmonton', 'AB Calgary')
            AND pmd.cad_complete_date IS NOT NULL
            AND ss.bucket_complete_date IS NOT NULL
        GROUP BY
        fvd.sales_office
    ) desquery
    ON fvd.sales_office = desquery.sales_office
    LEFT JOIN (
        SELECT
            fvd.sales_office,
            AVG(DATEDIFF(DAY, wc.createddate2, pmd.engineering_requested_date)) AS eng_start_day,
            AVG(DATEDIFF(DAY, pmd.cad_complete_date, pmd.engineering_complete_date)) AS eng_cycle_time
        FROM
            podio.project_management_canada can
            LEFT JOIN
            podio.project_management_designs pmd
            ON
            can.project_master_id = pmd.project_master_id
            LEFT JOIN
            podio.fs_valor_deals fvd
            ON can.project_master_id = fvd.project_master_id
            LEFT JOIN
            podio.project_management_welcomecalls wc
            ON can.project_master_id = wc.project_master_id
        WHERE
            fvd.sales_office IN ('AB Edmonton', 'AB Calgary')
            AND pmd.engineering_complete_date IS NOT NULL
            AND pmd.cad_complete_date IS NOT NULL
        GROUP BY
            fvd.sales_office
    ) engquery
    ON fvd.sales_office = engquery.sales_office
    LEFT JOIN (
        SELECT
            fvd.sales_office,
            AVG(DATEDIFF(DAY, wc.createddate2, perm.bucket_activated_date)) AS perm_start_day,
            AVG(DATEDIFF(DAY, pmd.engineering_complete_date, perm.bucket_completion_date)) AS perm_cycle_time
        FROM
            podio.project_management_canada can
            LEFT JOIN
            podio.project_management_permitting perm
            ON can.project_master_id = perm.project_master_id
            LEFT JOIN
            podio.project_management_designs pmd
            ON can.project_master_id = pmd.project_master_id
            LEFT JOIN
            podio.fs_valor_deals fvd
            ON can.project_master_id = fvd.project_master_id
            LEFT JOIN
            podio.project_management_welcomecalls wc
            ON can.project_master_id = wc.project_master_id
        WHERE
            fvd.sales_office IN ('AB Edmonton', 'AB Calgary')
            AND perm.bucket_completion_date IS NOT NULL
            AND pmd.engineering_complete_date IS NOT NULL
        GROUP BY
            fvd.sales_office
    ) permquery
    ON fvd.sales_office = permquery.sales_office
    LEFT JOIN (
        SELECT
            fvd.sales_office,
            AVG(DATEDIFF(DAY, wc.createddate2, perm.bucket_completion_date)) AS nem_start_day,
            AVG(DATEDIFF(DAY, nem.bucket_activation_date, nem.nem_approved_date)) AS nem_cycle_time
        FROM
            podio.project_management_canada can
            LEFT JOIN
            podio.project_management_interconnectionpreinstall nem
            ON can.project_master_id = nem.project_master_id
            LEFT JOIN
            podio.fs_valor_deals fvd
            ON can.project_master_id = fvd.project_master_id
            LEFT JOIN
            podio.project_management_welcomecalls wc
            ON can.project_master_id = wc.project_master_id
            LEFT JOIN
            podio.project_management_permitting perm
            ON can.project_master_id = perm.project_master_id
        WHERE
            fvd.sales_office IN ('AB Edmonton', 'AB Calgary')
            AND nem_approved_date IS NOT NULL
            AND nem.bucket_activation_date IS NOT NULL
            AND -1 * DATEDIFF(DAY, nem_approved_date, nem.bucket_activation_date) > -1
        GROUP BY
            fvd.sales_office
    ) nemquery
    ON fvd.sales_office = nemquery.sales_office
    JOIN (
        SELECT
            fvd.sales_office,
            0 AS retro_insp_start_day,
            AVG(DATEDIFF(DAY, fvd.date_fluent_approved, can.preretrofit_completed_date)) AS preretrofitinsp_cycle_time
        FROM
            podio.project_management_canada can
            LEFT JOIN
            podio.fs_valor_deals fvd
            ON can.project_master_id = fvd.project_master_id
        WHERE
            can.preretrofit_completed_date IS NOT NULL
            AND fvd.date_fluent_approved IS NOT NULL
        GROUP BY fvd.sales_office
    ) retroinspquery
    ON fvd.sales_office = retroinspquery.sales_office
    LEFT JOIN (
        SELECT
            fvd.sales_office,
            AVG(DATEDIFF(DAY, wc.createddate2, preretrofit_scheduled_date)) AS horeview_start_day,
            AVG(DATEDIFF(DAY, preretrofit_scheduled_date, can.homeowner_review_status_reached_date)) AS homeowner_review_cycle_time
        FROM
            podio.project_management_canada can
            LEFT JOIN
            podio.fs_valor_deals fvd
            ON fvd.project_master_id = can.project_master_id
            LEFT JOIN
            podio.project_management_welcomecalls wc
            ON can.project_master_id = wc.project_master_id
        WHERE
            can.homeowner_review_status_reached_date IS NOT NULL
            AND can.preretrofit_completed = 'Yes'
            AND preretrofit_scheduled_date IS NOT NULL
        GROUP BY
            fvd.sales_office
    ) horeviewquery
    ON fvd.sales_office = horeviewquery.sales_office
    LEFT JOIN (
        SELECT
            fvd.sales_office,
            AVG(DATEDIFF(DAY, wc.createddate2, homeowner_review_status_reached_date)) AS loan_rev_start_day,
            AVG(DATEDIFF(DAY, homeowner_review_status_reached_date, COALESCE(can.greener_loan_application_approval_date, can.greener_loan_application_denial_date))) AS loan_appr_den_cycle_time
        FROM
            podio.project_management_canada can
        LEFT JOIN
            podio.fs_valor_deals fvd
            ON fvd.project_master_id = can.project_master_id
            LEFT JOIN
            podio.project_management_welcomecalls wc
            ON can.project_master_id = wc.project_master_id
        WHERE
            COALESCE(can.greener_loan_application_approval_date, can.greener_loan_application_denial_date) IS NOT NULL
            AND can.homeowner_review_status_reached_date IS NOT NULL
        GROUP BY
            fvd.sales_office
     )loanappdenquery
     ON fvd.sales_office = loanappdenquery.sales_office
    JOIN (
        SELECT
            fvd.sales_office,
            AVG(DATEDIFF(DAY, LEAST(pmp.date_fluent_approved, ss.activation_date, wc.bucket_completion_date), can.greener_loan_application_approval_date)) AS total_cycle_time
        FROM
            podio.project_management_canada can
            LEFT JOIN
            podio.project_management_sitesurvey ss
            ON ss.project_master_id = can.project_master_id
            LEFT JOIN
            podio.project_management_welcomecalls wc
            ON can.project_master_id = wc.project_master_id
            LEFT JOIN
            podio.project_management_projects pmp
            ON can.project_master_id = pmp.project_master_id
            LEFT JOIN
            podio.fs_valor_deals fvd
            ON can.project_master_id = fvd.project_master_id
        WHERE
            pmp.date_fluent_approved IS NOT NULL
            AND (wc.bucket_completion_date IS NOT NULL
            OR ss.activation_date IS NOT NULL
            OR pmp.date_fluent_approved IS NOT NULL)
            AND COALESCE(can.greener_loan_application_approval_date, can.greener_loan_application_denial_date) IS NOT NULL
            AND can.homeowner_review_status_reached_date IS NOT NULL
        GROUP BY fvd.sales_office
    ) totalquery
    ON fvd.sales_office = totalquery.sales_office
WHERE
    fvd.sales_office IN ('AB Edmonton', 'AB Calgary')
GROUP BY fvd.sales_office
