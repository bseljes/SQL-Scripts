/*
This query pulls Inspections KPI and groups by inspection attempt number
*/

SELECT
    insp.project AS 'Customer',
    install.install_complete_date AS 'Install Complete Date',
    insp.fic_uploaded_date AS 'FIC Upload Date',
    insp.inspection_status AS 'Inspection Status',
    CASE WHEN install.install_complete_date IS NOT NULL AND
    insp.fic_uploaded_date IS NOT NULL
    THEN DATEDIFF(DAY, install.install_complete_date, insp.fic_uploaded_date)
    WHEN install.install_complete_date IS NOT NULL AND
    insp.fic_uploaded_date IS NOT NULL
    THEN DATEDIFF(DAY, install.install_complete_date, GETDATE())
    ELSE NULL END AS 'Install Complete to FIC Upload Cycle',
    insp.region AS 'Region',
    MAX(insp.inspection_attempt_number) AS 'Inspection Attempt Number'
FROM
    podio.project_management_inspections insp
LEFT JOIN
    podio.project_management_installs install
ON
    install.project_master_id = insp.project_master_id
WHERE
    install.install_complete_date >= '2023-01-01'
GROUP BY
    insp.project, install.install_complete_date, insp.fic_uploaded_date, insp.region, insp.inspection_status
ORDER BY
    MAX(insp.inspection_attempt_number) DESC