#############################################################################################
library(RPostgreSQL)

t0 <- proc.time()

###
#DB connection for HF:
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
sql <- "
SELECT
        dpt.patient_type_id,
        dpt.patient_type_desc,
  CAST(fe.admitted_dt_tm AS DATE) AS \"admitted_date\",
	(EXTRACT(EPOCH FROM fe.discharged_dt_tm-fe.admitted_dt_tm)/3600) AS \"los_hrs\"
FROM
	hf_f_encounter fe
JOIN hf_d_patient_type dpt ON fe.patient_type_id = dpt.patient_type_id
WHERE fe.discharged_dt_tm >= fe.admitted_dt_tm
	AND fe.admitted_dt_tm BETWEEN CAST('2014-01-01' AS date) AND CAST('2014-12-31' AS date)
ORDER BY RANDOM()
LIMIT 100000
"
results <- dbSendQuery(con_hf,sql)
los <- dbFetch(results, colClasses="character")
los$los_hrs <- as.numeric(los$los_hrs)
dbClearResult(results)
print(sprintf("n_los = %d\n",nrow(los)))

ptypes <- unique(subset(los, select=c(patient_type_id,patient_type_desc)))
ptypes <- ptypes[order(ptypes$patient_type_id),]


for (i in 1:nrow(ptypes))
{
  ptype_id <- ptypes$patient_type_id[i]
  ptype_desc <- ptypes$patient_type_desc[i]
  los_this <- los[los$patient_type_id == ptype_id,]
  if (nrow(los_this)> 0.01*nrow(los))
  {
    print(sprintf("[%3s] %24s: N = %6d ; los_avg = %.4f hrs", ptype_id, ptype_desc, nrow(los_this), mean(los_this$los_hrs)))
  }
}

###
dbDisconnect(con_hf)

print(sprintf("elapsed time (total): %.2fs",(proc.time()-t0)[3]))