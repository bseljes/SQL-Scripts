/*
This query pulls Install KPI info
*/

SELECT
    COALESCE(time_stamp_of_when_install_was_scheduled, install_complete_date) AS 'Date Install Was Scheduled',
    status AS 'Install Scheduling Status',
    install.project AS 'Customer',
    COALESCE(ready.install_ready_date, install_ready_date_old) AS 'Install Ready Date',
    install_complete_date AS 'Install Complete',
    CASE WHEN COALESCE(ready.install_ready_date, install_ready_date_old) IS NOT NULL
    AND time_stamp_of_when_install_was_scheduled IS NOT NULL
    THEN GREATEST(DATEDIFF(DAY, COALESCE(ready.install_ready_date, install_ready_date_old), time_stamp_of_when_install_was_scheduled), 0)
    WHEN COALESCE(ready.install_ready_date, install_ready_date_old) IS NOT NULL AND
    time_stamp_of_when_install_was_scheduled IS NULL
    THEN DATEDIFF(DAY, COALESCE(ready.install_ready_date, install_ready_date_old), GETDATE())
    ELSE NULL END AS 'Install Scheduling Cycle Time',
    CASE WHEN COALESCE(ready.install_ready_date, install_ready_date_old) IS NOT NULL
    AND install_complete_date IS NOT NULL
    THEN GREATEST(DATEDIFF(DAY, COALESCE(ready.install_ready_date, install_ready_date_old), install_complete_date), 0)
    ELSE NULL END AS 'Install Ready to Complete Cycle Time',
    _scheduled_install_date AS 'Install Scheduled Date',
    install_complete_date AS 'Install Complete Date',
    CASE WHEN _scheduled_install_date IS NOT NULL AND install_complete_date IS NOT NULL
    THEN DATEDIFF(DAY, _scheduled_install_date, install_complete_date)
    WHEN _scheduled_install_date IS NOT NULL AND install_complete_date IS NULL
    THEN DATEDIFF(DAY, _scheduled_install_date, GETDATE())
    ELSE NULL END AS 'Install Date to Complete Cycle',
    install.region AS 'Region'
FROM
    podio.project_management_installs install
LEFT JOIN
    podio.project_management_installready ready
ON
    install.project_master_id = ready.project_master_id
WHERE
    COALESCE(ready.install_ready_date, install_ready_date_old) >= '2023-01-01'
