#############################################################################################
library(RPostgreSQL)

t0 <- proc.time()

###
#DB connection for HF codes lookup:
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
#Pre-selected cohort of colon cancer patients with 5 yrs of facts:
###
hf <- read.csv("data/hf_cohort_ccancer.csv", stringsAsFactors=F, colClasses="character")

patients <- unique(hf[,c("patient_sk","ccancer_code")])

n_pid <- length(unique(hf$patient_id))
n_psk <- length(unique(patients$patient_sk))

print(sprintf("patient_id count: %d ; patient_sk count: %d\n",n_pid,n_psk))

###
#Basic demographics; age, gender:
###
#Find year of birth (YOB) for each patient, from all encounters.
###
patients$yob <- NA
i <- 0
for (sk in unique(patients$patient_sk))
{
  i <- i + 1
  patient_ids <- hf$patient_id[hf$patient_sk == sk]
  sql <- sprintf("SELECT fe.admitted_dt_tm::CHAR(4) AS \"year\", fe.age_in_years from hf_f_encounter fe WHERE fe.patient_id in (%s)",
    paste(patient_ids, collapse=","))
  results <- dbSendQuery(con_hf,sql)
  age <- dbFetch(results, colClasses="character")
  age$year <- as.integer(age$year)
  dbClearResult(results)
  age$yob <- age$year - age$age_in_years
  yob <- floor(median(age$yob, na.rm=T))
  patients$yob[patients$patient_sk == sk] <- yob
  print(sprintf("%d. SK: %s ; IDs: %s ; YOB: %d", i, sk, paste(patient_ids, collapse=","), yob))
}
write.table(patients, file="data/hf_cohort_ccancer_patients.csv", sep=",", row.names=F)

###
#dbDisconnect(con_hf)

print(sprintf("elapsed time (total): %.2fs",(proc.time()-t0)[3]))
###
