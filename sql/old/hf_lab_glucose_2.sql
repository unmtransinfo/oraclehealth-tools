SELECT
        *
FROM
        hf_d_lab_procedure dlp
WHERE
        lab_procedure_name LIKE 'Glucose%'
ORDER BY lab_procedure_id
        ;