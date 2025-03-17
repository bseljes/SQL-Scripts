SELECT
    designs.project AS 'Customer',
    CAST(pmp.fluent_approved_date AS DATE) AS 'FA Date',
    pmp.region AS 'Region',
    pmp.stage AS 'Project Page Stage',
    designs.project_master_id AS 'Master ID',
    designs.bucket_activation AS 'Bucket Activation',
    designs.status AS 'Design Staus',
    designs.site_plan AS 'Site Plan',
    designs.ebe AS 'EBE',
    designs.electrical AS 'Electrical',
    designs.checked_by AS 'Checked By',
    COALESCE(designs.engineering_complete_date, designs.cad_complete_date) AS 'Complete Date',
    COALESCE(corrections.corrections_complete_date, corrections.cad_complete_date) AS 'Design Correction Complete Date',
    corrections.correction_reason AS 'Correction Reason',
    corrections.corrections_requested_date AS 'Corrections Requested Date',
    corrections.completed_by AS 'Corrections Completed By',
    CASE WHEN corrections.design IS NULL THEN 0 ELSE 1 END AS 'Has Correction',
    DATEDIFF(DAY, pmp.fluent_approved_date, COALESCE(designs.cad_complete_date, GETDATE())) AS 'Cycle Time',
    DATEDIFF(DAY, corrections.corrections_requested_date, COALESCE(corrections.cad_complete_date, GETDATE())) AS 'Design Correction Cycle Time'
FROM podio.project_management_designs designs
LEFT JOIN
    podio.project_management_designcorrections corrections
ON
    designs.project_master_id = corrections.project_master_id
LEFT JOIN
    podio.project_management_projects pmp
ON
    pmp.project_master_id = designs.project_master_id
