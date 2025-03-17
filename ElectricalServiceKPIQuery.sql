/*
This query pulls Electrical Service Department KPI and pull through data.
*/
SELECT
    row_number() OVER (ORDER BY es.created_date) AS 'Index',
    Cast(DATEADD(DAY, 1 - DATEPART(WEEKDAY, es.created_date), es.created_date) as DATE) AS 'Week Start',
    CAST(es.created_date AS DATE) as 'Created Time', 
    title as 'Customer Name', 
    es.electrical_service as 'Electrical Service', 
    es.region as 'ES Region', 
    service_type as 'Service Type', 
    es.status as 'ES Status', 
    es.bucket_user as 'Bucket User', 
    es.design_complete_date as 'Design Complete Date', 
    es.complete_date as 'Complete Date', 
    accepted_quote_date as 'Accepted Quote Date', 
    accepted_quote_price as 'Accepted Quote Price', 
    mpu_needed as 'MPU Needed?', 
    es.assigned_installer as 'Assigned Installer', 
    es.scheduleddate as 'Scheduled Date', 
    es.project_stage as 'ES project Stage', 
    stage as 'Project Page Stage', 
    es.project_master_id as 'Master ID', 
    es.reason_for_holdcancellation 'Reason for Hold Cancellation', 
    es.steps_to_complete as 'Steps to Complete', 
    es.mpu_promised_in_agreement as 'MPU Promised in Agreement?', 
    mpu_change_order_needed as 'Change Order Needed?', 
    mpu_assigned_tech as 'MPU Assigned Tech',
    es.scheduled_install_date as 'Scheduled Install Date', 
    es.install_complete_date as 'Install Complete Date', 
    es.permit_submitted_date as 'Permit Submitted Date', 
    es.permit_approved_date as 'Permit Approved Date', 
    es.nem_submitted_date as 'NEM Submitted Date', 
    es.nem_approved_date as 'NEM Approved Date', 
    es.last_updated_date as 'Last Updated Date',
    DATEDIFF(DAY, es.created_date, es.accepted_quote_date) as 'Created to Quote Accepted',
    DATEDIFF(DAY, accepted_quote_date, es.scheduleddate) as 'Quote Accepted to Scheduled',
    CAST(row_number() OVER (ORDER BY es.created_date) AS NVARCHAR) + ' ' +
    title AS 'Indexed Customer Name',
    CASE
        WHEN es.created_Date IS NOT NULL
            AND (es.complete_date IS NOT NULL
                AND stage NOT IN ('Cancelled', 'Resolutions Review')
                AND es.status NOT IN ('Cancelled', 'Resolutions Review', 'MPU Not Needed')
                AND DATEDIFF(DAY, es.created_date, es.complete_date) > 0)
        THEN DATEDIFF(DAY, es.created_date, es.complete_date)
        WHEN es.created_Date IS NOT NULL
            AND (es.complete_date IS NULL
                AND stage NOT IN ('Cancelled', 'Resolutions Review')
                AND es.status NOT IN ('Cancelled', 'Resolutions Review', 'MPU Not Needed'))
        THEN DATEDIFF(DAY, es.created_date, GETDATE())
    END AS 'MPU Cycle Time',

    CASE
        WHEN es.[status] = 'Complete' THEN '1. Complete'
        WHEN es.[status] = 'Resolutions Review' THEN '2. Resolutions Review'
        WHEN es.[status] = 'On Hold' THEN '3. On Hold'
        WHEN es.[status] IN ('Cancelled', 'MPU Not Needed') THEN '4. MPU Not Needed'
        WHEN es.[status] = 'Scheduled' THEN '5. Scheduled'
        WHEN es.[status] = 'Ready to Schedule' THEN '6. Ready to Schedule'
        WHEN es.[status] IN ('Quote Approved', 'Quote Requested', 'Change Order Required') THEN '7. Not Ready to Schedule'
        WHEN es.[status] = 'New Request' THEN '8. New Request'
        ELSE NULL
    END AS 'Numbered ES Status',
    CASE WHEN es.complete_date IS NULL AND 
    (CASE
        WHEN es.created_Date IS NOT NULL
            AND (es.complete_date IS NOT NULL
                AND stage NOT IN ('Cancelled', 'Resolutions Review')
                AND es.status NOT IN ('Cancelled', 'Resolutions Review', 'MPU Not Needed')
                AND DATEDIFF(DAY, es.created_date, es.complete_date) > 0)
        THEN DATEDIFF(DAY, es.created_date, es.complete_date)
        WHEN es.created_Date IS NOT NULL
            AND (es.complete_date IS NULL
                AND stage NOT IN ('Cancelled', 'Resolutions Review')
                AND es.status NOT IN ('Cancelled', 'Resolutions Review', 'MPU Not Needed'))
        THEN DATEDIFF(DAY, es.created_date, GETDATE()) END) > 49
        THEN 1 ELSE 0 END AS 'Open Past 50 days'

 
 FROM podio.project_management_electricalservice es 
 
 INNER JOIN podio.project_management_projects pmp 
    ON pmp.project_master_id = es.project_master_id