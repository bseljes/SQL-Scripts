/*
This query pulls HOA department KPI info.
*/

SELECT
    hoa.project_master_id AS 'Master ID',
    hoa.project AS 'Customer', 
    hoa.status AS 'Status',
    hoa.region AS 'Region',
    CAST(hoa.created_date AS DATE) AS 'Created Date',
    hoa.hoa_needed AS 'HOA Needed?',
    hoa.hoa_information_requested_date AS 'Info Requested Date',
    hoa.all_necessary_items_received AS 'All Nec Items Received Date',
    hoa.sent_to_customer AS 'Sent to Customer',
    hoa.hoa_application_submitted_date AS 'Submitted Date', 
    hoa.hoa_approved_date AS 'Approved Date',
    hoa.install_complete_date AS 'Install Complete Date',
    CASE WHEN hoa.created_date IS NOT NULL AND hoa_needed <> 'No' AND hoa_information_requested_date IS NOT NULL
        THEN DATEDIFF(DAY, hoa.created_date, hoa_information_requested_date)
        WHEN hoa.created_date IS NOT NULL AND hoa_needed <> 'No' AND hoa_information_requested_date IS NULL
        THEN DATEDIFF(DAY, hoa.created_date, GETDATE())
        ELSE NULL END AS 'Requested Cycle',
    CASE WHEN hoa_information_requested_date IS NOT NULL AND hoa_needed <> 'No' AND all_necessary_items_received IS NOT NULL
        THEN DATEDIFF(DAY, hoa_information_requested_date, all_necessary_items_received)
        WHEN hoa_information_requested_date IS NOT NULL AND hoa_needed <> 'No' AND all_necessary_items_received IS NULL
        THEN DATEDIFF(DAY, hoa_information_requested_date, all_necessary_items_received)
        ELSE NULL END AS 'Requested to All Nec Recieved Cycle',
    CASE WHEN created_date IS NOT NULL AND hoa_application_submitted_date IS NOT NULL
        THEN DATEDIFF(DAY, created_date, hoa_application_submitted_date)
        WHEN created_date IS NOT NULL AND hoa_application_submitted_date IS NULL
        THEN DATEDIFF(DAY, created_date, GETDATE())
        ELSE NULL END AS 'Sub Cycle',
    CASE WHEN hoa_application_submitted_date IS NOT NULL AND hoa_approved_date IS NOT NULL AND hoa_needed <> 'No'
        THEN DATEDIFF(DAY, hoa_application_submitted_date, hoa_approved_date)
        WHEN hoa_application_submitted_date IS NOT NULL AND hoa_approved_date IS NULL AND hoa_needed <> 'No'
        THEN DATEDIFF(DAY, hoa_application_submitted_date, GETDATE())
        ELSE NULL END AS 'Sub to Appr Cycle',
    CASE WHEN hoa.created_date IS NOT NULL AND hoa_needed <> 'No' AND hoa_approved_date IS NOT NULL
        THEN DATEDIFF(DAY, hoa.created_date, hoa_approved_date)
        WHEN hoa.created_date IS NOT NULL AND hoa_needed <> 'No' AND hoa_approved_date IS NULL
        THEN DATEDIFF(DAY, hoa.created_date, GETDATE())
        ELSE NULL END AS 'Total PT Cycle'
FROM podio.project_management_hoas hoa
