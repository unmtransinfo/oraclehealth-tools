### Hepatitis and Lymphoma multimorbidity
###
library(RPostgreSQL, quietly = T)
library(data.table, quietly = T)
library(plotly, quietly = T)
library(dplyr, quietly = T)

t0 <- proc.time()

###
#DB connection for HF :
###
DBHOST <- "hsc-ctschf.health.unm.edu"
rval <- system2("/usr/bin/ssh", args=c("-T", "-O", "check", DBHOST))
if (rval != 0)
{
  print("DEBUG: ssh tunnel off; starting...")
  system2("/usr/bin/ssh", args=c("-f", "-N", "-T", "-M", "-4", "-L", "63333:localhost:5432", DBHOST))
} else {
  print("DEBUG: ssh tunnel on.")
}
con_hf <- dbConnect(PostgreSQL(), host="localhost", port="63333", dbname="healthfacts", user= "jjyang", password="")

###

###
sql <- "SELECT
	dd.diagnosis_code,
	dd.diagnosis_type,
	dd.diagnosis_description
FROM
	hf_d_diagnosis dd
WHERE
	dd.diagnosis_code SIMILAR TO '\\d\\d\\d\\.%'
	AND (
	  dd.diagnosis_description ILIKE '%Hepatitis B%'
	  OR dd.diagnosis_description ILIKE '%Hepatitis C%'
	  OR dd.diagnosis_description ILIKE '%Alcoholic%Hepatitis%'
	  OR dd.diagnosis_description ILIKE '%Lymphoma%'
	)
ORDER BY
	dd.diagnosis_code"
#
results <- dbSendQuery(con_hf,sql)
dcodes <- dbFetch(results, colClasses="character")
dcodes$diagnosis_code <- as.character(dcodes$diagnosis_code)
dbClearResult(results)
print(sprintf("n_diag_codes = %d\n",nrow(dcodes)))
###

sql <- "SELECT
	fe1.patient_id,
	dd1.diagnosis_code,
	CAST(fe1.admitted_dt_tm AS DATE) AS \"admit_date\"
FROM
	hf_f_encounter fe1
JOIN
	hf_f_diagnosis fd1 ON fd1.encounter_id = fe1.encounter_id
JOIN
	hf_d_diagnosis dd1 ON fd1.diagnosis_id = dd1.diagnosis_id
JOIN
	hf_d_diagnosis_type ddt ON fd1.diagnosis_type_id = ddt.diagnosis_type_id
WHERE
	dd1.diagnosis_code SIMILAR TO '\\d\\d\\d\\.%'
	AND ddt.diagnosis_type_display = 'Final'
	AND (
	  dd1.diagnosis_description ILIKE '%Hepatitis B%'
	  OR dd1.diagnosis_description ILIKE '%Hepatitis C%'
	  OR dd1.diagnosis_description ILIKE '%Alcoholic%Hepatitis%'
	)"
#
results <- dbSendQuery(con_hf,sql)
hep <- dbFetch(results, colClasses="character")
dbClearResult(results)
print(sprintf("Hepatitis diagnoses = %d\n",nrow(hep)))
hep_patients <- unique(hep$patient_id)
print(sprintf("Hepatitis patients: %d\n",length(hep_patients)))

t_hep <- table(hep$diagnosis_code)
print(t_hep)
for (code in names(t_hep))
{
  desc <- dcodes$diagnosis_description[dcodes$diagnosis_code == code]
  print(sprintf("%s (%s): %d (%.1f%%)", code, desc, t_hep[code], t_hep[code]*100/sum(t_hep)))

}
###
sql <- "SELECT
	fe1.patient_id,
	dd1.diagnosis_code,
	CAST(fe1.admitted_dt_tm AS DATE) AS \"admit_date\"
FROM
	hf_f_encounter fe1
JOIN
	hf_f_diagnosis fd1 ON fd1.encounter_id = fe1.encounter_id
JOIN
	hf_d_diagnosis dd1 ON fd1.diagnosis_id = dd1.diagnosis_id
JOIN
	hf_d_diagnosis_type ddt ON fd1.diagnosis_type_id = ddt.diagnosis_type_id
WHERE
	dd1.diagnosis_code SIMILAR TO '\\d\\d\\d\\.%'
	AND ddt.diagnosis_type_display = 'Final'
	AND dd1.diagnosis_description ILIKE '%Lymphoma%'"
#
results <- dbSendQuery(con_hf,sql)
lph <- dbFetch(results, colClasses="character")
dbClearResult(results)
print(sprintf("Lymphoma diagnoses = %d\n",nrow(lph)))
lph_patients <- unique(lph$patient_id)
print(sprintf("Lymphoma patients: %d\n",length(lph_patients)))

t_lph <- table(lph$diagnosis_code)
print(t_lph)
for (code in names(t_lph))
{
  desc <- dcodes$diagnosis_description[dcodes$diagnosis_code == code]
  print(sprintf("%s (%s): %d (%.1f%%)", code, desc, t_lph[code], t_lph[code]*100/sum(t_lph)))
}
###
comorbid_patients <- intersect(hep_patients, lph_patients)
print(sprintf("Comorbid patients: %d\n",length(comorbid_patients)))
###
hep_lph <- merge(hep[hep$patient_id %in% comorbid_patients,], lph[lph$patient_id %in% comorbid_patients,], 
                 all.x=F, all.y=F, by="patient_id")
hep_lph$date_interval <- hep_lph$admit_date.x - hep_lph$admit_date.y
hep_lph <- hep_lph[abs(hep_lph$date_interval)<183, ]
print(sprintf("Comorbid patients (diagnosis interval < 183days): %d\n",length(unique(hep_lph$patient_id))))

#
t_hep_lph <- table(hep_lph$diagnosis_code.x, hep_lph$diagnosis_code.y)
for (code.hep in colnames(t_hep_lph))
{
  for (code.lph in rownames(t_hep_lph))
  {
    n <- t_hep_lph[code.lph,code.hep]
    if (n>=10)
    {
      desc.hep <- dcodes$diagnosis_description[dcodes$diagnosis_code == code.hep]
      desc.lph <- dcodes$diagnosis_description[dcodes$diagnosis_code == code.lph]
      print(sprintf("%s (%s) + %s (%s): %d", code.hep, desc.hep, code.lph, desc.lph, n))
    }
  }
}
###
#
dbDisconnect(con_hf)
#

