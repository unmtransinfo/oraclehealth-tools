#############################################################################################
### Facts read from CSV files.  Codes (e.g. ICD-9) read via HF live.
#############################################################################################
library(RPostgreSQL)
library(wordcloud)

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
#(Probably should delete rows not 1st diag.)
###
hf <- read.csv("data/hf_cohort_ccancer.csv", stringsAsFactors=F, colClasses="character")

patients <- unique(hf[,c("patient_sk","ccancer_code")])

n_pid <- length(unique(hf$patient_id))
n_psk <- length(unique(patients$patient_sk))

print(sprintf("patient_id count: %d ; patient_sk count: %d\n",n_pid,n_psk))

###
sql <- "SELECT * FROM hf_d_diagnosis WHERE diagnosis_type = 'ICD9'"
results <- dbSendQuery(con_hf,sql)
dcodes <- dbFetch(results, colClasses="character")
dcodes$diagnosis_code <- as.character(dcodes$diagnosis_code)
dbClearResult(results)
print(sprintf("n_diag_codes = %d\n",nrow(dcodes)))

patients <- merge(patients, dcodes, all.x=T, all.y=F, by.x="ccancer_code", by.y="diagnosis_code")
colnames(patients)[1] <- "diagnosis_code"

ccancer_codes <- unique(patients$diagnosis_code) #colon cancer codes present

n_data <- nrow(patients)

n_total <- 0
for (code in ccancer_codes)
{
  n <- nrow(patients[patients$diagnosis_code==code,])
  desc <- dcodes$diagnosis_description[dcodes$diagnosis_code==code]
  print(sprintf("DIAGNOSIS [N = %5d, %4.1f%%] %5s %s", n, 100*n/n_data, code, desc))
  n_total <- n_total + n
}
print(sprintf("DEBUG: n_total = %d",n_total))
#wordcloud(patients$diagnosis_description, colors=brewer.pal(9,"BuGn")[-(1:4)])


#How many patients with multiple colon cancer diagnoses?
#cdcode = concatenated diagnosis codes
patients$cdcode <- rep(NA,nrow(patients))

n_multi <- 0
for (psk in unique(patients$patient_sk))
{
  p <- patients[patients$patient_sk == psk,]
  cdcode <- paste(sort(p$diagnosis_code),collapse=",")
  patients$cdcode[patients$patient_sk == psk] <- cdcode
  n <- nrow(p)
  if (n>1)
  {
    #print(sprintf("DEBUG: multiple diagnosis patient_sk: %s ; n = %d (%s)\n", psk, n, cdcode))
    n_multi <- n_multi + 1
  }
}
print(sprintf("DEBUG: patients with multiple diagnoses n_multi = %d",n_multi))
#for (cdcode in sort(unique(patients$cdcode)))
#{
#  if (!grepl(",",cdcode))
#  {
#    next
#  }
#  n <- nrow(patients[patients$cdcode == cdcode,])
#  print(sprintf("DIAGNOSIS_MULTI [N = %5d] %s\n",n,cdcode))
#}


###
#plist is one row per patient.
#Ignore race if few patients.
###
plist <- unique(hf[,c("patient_sk","gender","race")])
plist$race[is.na(plist$race) | (plist$race %in% c("Not Mapped","NULL"))] <- "Unknown"
plist$race[!(plist$race %in% c("African American","Caucasian","Other","Unknown"))] <- "Other"
tbl <- table(plist$race,plist$gender)
n_total <- 0
genders <- colnames(tbl)
for (race in rownames(tbl))
{
  n <- tbl[race,genders]
  print(sprintf("%24s: %s: [%4d, %4.1f%%] %s: [%4d, %4.1f%%]", race, genders[1], n[1], 100*n[1]/n_psk, 
                genders[2], n[2], 100*n[2]/n_psk))
  n_total <- n_total + sum(n)
}
print(sprintf("DEBUG: n_total = %d",n_total))

###
#Diagnoses (all other, comorbidity)
###
###
#New: diagnosis facts include age.
###

print("===== DIAGNOSES:")
diags <- read.csv("data/hf_cohort_ccancer_f_diagnosis.csv", stringsAsFactors=F, colClasses="character")
diags <- subset(diags, !is.na(FID) & FID!="")
tbl <- table(substr(diags$Date,1,4))
barplot(tbl, main="Diagnosis facts by year", xlab="year", las=3, ylab="count", col="orange")

for (y in rownames(tbl))
{
  print(sprintf("DIAGNOSIS [Nfacts = %6d, %4.1f%%] %s", tbl[y], 100*tbl[y]/sum(tbl), y))
}
diags <- merge(diags, dcodes, all.x=T, all.y=F, by.x="FID", by.y="diagnosis_id")
colnames(diags)[1] <- "diagnosis_id"
print(sprintf("unique other diagnoses: %d\n",length(unique(diags$diagnosis_id[!(diags$diagnosis_code %in% ccancer_codes)]))))

diags_ccancer <- subset(diags,diagnosis_code %in% ccancer_codes)
tbl <- table(substr(diags_ccancer$Date,1,4))
barplot(tbl, main="Colon cancer diagnosis facts by year", xlab="year", las=3, ylab="count", col="orange")

###
#Patient age:
###
patients$yob <- NA
diags_ccancer$yob <- NA
plist$yob <- NA
i <- 0
for (sk in unique(patients$patient_sk))
{
  i <- i + 1
  yobs <- as.integer(substr(diags$Date[diags$SK == sk], 1, 4)) - as.integer(diags$PAge[diags$SK == sk])
  yob <- floor(median(yobs, na.rm=T))
  patients$yob[patients$patient_sk == sk] <- yob
  diags_ccancer$yob[diags_ccancer$SK == sk] <- yob
  plist$yob[plist$patient_sk == sk] <- yob
}

#Merge by patient_sk and year.
diags_ccancer_sk <- subset(diags_ccancer, select = c("SK","Date","yob"))
diags_ccancer_sk$year <- substr(diags_ccancer_sk$Date, 1, 4)
diags_ccancer_sk$Date <- NULL
diags_ccancer_sk <- unique(diags_ccancer_sk)
tbl <- table(diags_ccancer_sk$year)
barplot(tbl, main="Colon cancer diagnosis patients by year", xlab="year", las=3, ylab="count", col="orange")
hist(as.integer(diags_ccancer_sk$year) - as.integer(diags_ccancer_sk$yob))
tbl <- table(as.integer(diags_ccancer_sk$year) - as.integer(diags_ccancer_sk$yob))
barplot(tbl, main="Colon cancer diagnosis patients by age", xlab="year", las=3, ylab="count", col="orange")

#1st diagnosis for each patient:
diags_ccancer$first <- NA
for (i in 1:nrow(diags_ccancer))
{
  sk <- diags_ccancer$SK[i]
  min_date <- min(diags_ccancer$Date[diags_ccancer$SK == sk], na.rm=T)
  diags_ccancer$first[i] <- (diags_ccancer$Date[i] == min_date)
}
tbl <- table(substr(diags_ccancer$Date[diags_ccancer$first == T], 1, 4))
barplot(tbl, main="Colon cancer 1st-diagnosis patients by year", xlab="year", las=3, ylab="count", col="orange")

age_1st_diag <- as.integer(substr(diags_ccancer$Date[diags_ccancer$first == T], 1, 4)) - diags_ccancer$yob[diags_ccancer$first == T]
tbl <- table(age_1st_diag)
barplot(tbl, main="Colon cancer 1st-diagnosis patients by age", xlab="age", las=3, ylab="count", col="orange")
ageMax <- 100
ageDelta <- 5
for (age in seq(0,ageMax,ageDelta))
{
  n <- length(age_1st_diag[age_1st_diag %in% age:(age+ageDelta)])
  print(sprintf("PATIENT_AGE: %2d-%2d: n = %4d", age, age+ageDelta, n))
}
print(sprintf("Age of 1st diagnosis mean: %d, median: %d", as.integer(round(mean(age_1st_diag))),
	as.integer(round(median(age_1st_diag)))))
#Wordcloud:
wordcloud(diags$diagnosis_description[!(diags$diagnosis_code %in% ccancer_codes)], max.words=200, colors=brewer.pal(9,"Blues")[-(1:4)])

###
#Medications
###
print("===== MEDS:")
meds <- read.csv("data/hf_cohort_ccancer_f_medication.csv", stringsAsFactors=F, colClasses="character")
meds <- subset(meds, !is.na(FID) & FID!="")
tbl <- table(substr(meds$Date,1,4))
barplot(tbl, main="Medication facts by year", xlab="year", las=3, ylab="count", col="orange")
for (y in rownames(tbl))
{
  print(sprintf("MED [Nfacts = %6d, %4.1f%%] %s", tbl[y], 100*tbl[y]/sum(tbl), y))
}

sql <- "SELECT * FROM hf_d_medication"
results <- dbSendQuery(con_hf,sql)
codes <- dbFetch(results, colClasses="character")
codes$ndc_code <- as.character(codes$ndc_code)
dbClearResult(results)
print(sprintf("n_med_codes = %d\n",nrow(codes)))
meds <- merge(meds, codes, all.x=T, all.y=F, by.x="FID", by.y="medication_id")
colnames(meds)[1] <- "medication_id"
print(sprintf("unique meds: %d\n",length(unique(meds$medication_id))))

###
#Merge with DrugCentral.
#Medications, prescription drugs, antineoplastic agents:
###
con_dc <- dbConnect(PostgreSQL(), host="lengua.health.unm.edu", dbname="drugcentral")
sql <- paste(
"SELECT DISTINCT",
"REPLACE(p.ndc_product_code,'-','')::CHAR(8) AS \"ndc\",",
"p.id AS \"product_id\",",
"p.product_name,",
"p.generic_name,",
"p.form,",
"p.route,",
"p.marketing_status,",
"s2a.atc_code",
"FROM product AS p",
"JOIN prd2label p2l ON p.ndc_product_code = p2l.ndc_product_code",
"JOIN label l ON l.id = p2l.label_id",
"JOIN active_ingredient ai ON ai.ndc_product_code = p.ndc_product_code",
"JOIN struct2atc s2a ON s2a.struct_id = ai.struct_id",
"WHERE p.marketing_status IN ('NDA','ANDA')",
"AND l.category LIKE '%HUMAN PRESCRIPTION%'")

results <- dbSendQuery(con_dc,sql)
mcodes <- dbFetch(results, colClasses="character")
dbClearResult(results)
print(sprintf("prescription ndc codes = %d\n",length(unique(mcodes$ndc))))

mcodes <- mcodes[order(mcodes$ndc),]

meds$ndc_code <- substr(meds$ndc_code,1,8)
meds <- merge(meds, subset(mcodes, select = c("ndc","atc_code")), all.x=T, all.y=F, by.x="ndc_code", by.y="ndc")

###
#Prescription meds:
#(have ATC codes in meds)
###
words <- c()
for (gn in sort(unique(meds$generic_name)))
{
  if (TRUE %in% !is.na(unique(meds$atc_code[meds$generic_name == gn])))
  {
    next
  }
  nm <- nrow(subset(meds, generic_name == gn))
  np <- length(unique(meds$SK[meds$generic_name == gn]))
  words <- c(words,rep(gn,np))
  if (np>(n_pid/10))
  {
    print(sprintf("MED [Npatients = %5d ; Nfacts = %5d] %s\n", np, nm, gn))
  }
}
wordcloud(words, max.words=100, colors=brewer.pal(9,"Blues")[-(1:4)])
rm(words)

print(sprintf("antineoplastic ndc codes in this cohort: %d", length(meds$ndc_code[!is.na(meds$atc_code) & grepl("^L01",meds$atc_code)])))

dbDisconnect(con_dc)
###

###
#Med history:
###
print("===== MED_HISTORY:")
medhs <- read.csv("data/hf_cohort_ccancer_f_med_history.csv", stringsAsFactors=F, colClasses="character")
medhs <- subset(medhs, !is.na(FID) & FID!="")
tbl <- table(substr(medhs$Date,1,4))
barplot(tbl, main="Medication history facts by year", xlab="year", las=3, ylab="count", col="orange")
for (y in rownames(tbl))
{
  print(sprintf("MED_HIST [Nfacts = %6d, %4.1f%%] %s", tbl[y], 100*tbl[y]/sum(tbl), y))
}

###
#Clinical events:
###
print("===== CLINICAL EVENTS:")
events <- read.csv("data/hf_cohort_ccancer_f_clinical_event.csv", stringsAsFactors=F, colClasses="character")
events <- subset(events, !is.na(FID) & FID!="")
tbl <- table(substr(events$Date,1,4))
barplot(tbl, main="Clinical event facts by year", xlab="year", las=3, ylab="count", col="orange")
for (y in rownames(tbl))
{
  print(sprintf("CLIN_EVENT [Nfacts = %6d, %4.1f%%] %s", tbl[y], 100*tbl[y]/sum(tbl), y))
}

sql <- "SELECT * FROM hf_d_event_code ORDER BY event_code_id"
results <- dbSendQuery(con_hf,sql)
codes <- dbFetch(results, colClasses="character")
dbClearResult(results)
codes$event_code_id <- as.character(codes$event_code_id)
print(sprintf("n_event_codes = %d\n",nrow(codes)))
events <- merge(events, codes, all.x=T, all.y=F, by.x="FID", by.y="event_code_id")
colnames(events)[1] <- "event_code_id"
print(sprintf("unique clinical events: %d\n",length(unique(events$event_code_id))))

n_data <- nrow(events)
tbl <- table(events$event_code_category)
n_total <- 0
for (rn in rownames(tbl))
{
  n <- tbl[rn]
  if (n>0.01*n_psk)
  {
    n_psk_this <- length(unique(events$SK[events$event_code_category == rn]))
    print(sprintf("CLIN_EVENT [Npatients = %6d, %4.1f%% ; Nfacts = %6d, %4.1f%%] %s", n_psk_this, 100*n_psk_this/n_psk, n, 100*n/n_data, rn))
  }
n_total <- n_total + n
}
print(sprintf("DEBUG: n_total = %d",n_total))

ecc <- "Vital Sign"
tbl <- table(events$event_code_desc[events$event_code_category == ecc])
n_total <- 0
for (rn in rownames(tbl))
{
  n <- tbl[rn]
  if (n>0.1*n_psk)
  {
    n_psk_this <- length(unique(events$SK[events$event_code_category == ecc & events$event_code_desc ==rn]))
    print(sprintf("CLIN_EVENT [Npatients = %6d, %4.1f%% ; Nfacts = %6d, %4.1f%%] %s: %s", n_psk_this, 100*n_psk_this/n_psk, n, 100*n/n_data, ecc, rn))
  }
  n_total <- n_total + n
}
print(sprintf("DEBUG: n_total = %d",n_total))

###
#Height, weight, BMI:
#BMI = kg/m^2
###
height <- subset(events, event_code_desc == "Height")
weight <- subset(events, event_code_desc == "Weight")
plist$height_min <- NA
plist$height_max <- NA
plist$weight_min <- NA
plist$weight_max <- NA
n_bmi <- 0
for (sk in plist$patient_sk)
{
  height_this <- subset(height, SK == sk, select = c("event_code_id","Result","Units","Date"))
  height_this$Result <- as.numeric(height_this$Result)
  heights <- c(height_this$Result[height_this$Units == "cm"],  height_this$Result[height_this$Units == "[in_us]"] * 2.54)
  if (length(heights)>0)
  {
    plist$height_min[plist$patient_sk == sk] <- min(heights)
    plist$height_max[plist$patient_sk == sk] <- max(heights)
  }
  
  weight_this <- subset(weight, SK == sk, select = c("event_code_id","Result","Units","Date"))
  weight_this$Result <- as.numeric(weight_this$Result)
  weights <- c(weight_this$Result)
  if (length(weights)>0)
  {
    plist$weight_min[plist$patient_sk == sk] <- min(weights)
    plist$weight_max[plist$patient_sk == sk] <- max(weights)
  }
  
  height_mean <- mean(heights, na.rm=T)
  weight_mean <- mean(weights, na.rm=T)
  bmi <- weight_mean / (height_mean/100)^2
  if (!is.na(height_mean) & !is.na(weight_mean))
  {
    print(sprintf("CLIN_EVENT (SK = %8s) Height: %5.1fcm ; Weight: %5.1fkg ; BMI: %5.1f", sk, height_mean, weight_mean, bmi))
    n_bmi <- n_bmi + 1
  }
}
print(sprintf("Patients with height, weight, BMI: %d / %d", n_bmi, nrow(plist)))

###
#Labs:
###
print("===== LABS:")
labs <- read.csv("data/hf_cohort_ccancer_f_lab.csv", stringsAsFactors=F, colClasses="character")
labs <- subset(labs, !is.na(FID) & FID!="")
tbl <- table(substr(labs$Date,1,4))
barplot(tbl, main="Lab facts by year", xlab="year", las=3, ylab="count", col="orange")
for (y in rownames(tbl))
{
  print(sprintf("LAB [Nfacts = %6d, %4.1f%%] %s", tbl[y], 100*tbl[y]/sum(tbl), y))
}

sql <- "SELECT * FROM hf_d_lab_procedure ORDER BY lab_procedure_id"
results <- dbSendQuery(con_hf,sql)
codes <- dbFetch(results, colClasses="character")
dbClearResult(results)
codes$lab_procedure_id <- as.character(codes$lab_procedure_id)
print(sprintf("n_lab_codes = %d\n",nrow(codes)))
labs <- merge(labs, codes, all.x=T, all.y=F, by.x="FID", by.y="lab_procedure_id")
colnames(labs)[1] <- "lab_procedure_id"
print(sprintf("unique lab procedures: %d\n",length(unique(labs$lab_procedure_id))))

n_data <- nrow(labs)
tbl <- table(labs$lab_super_group)
n_total <- 0
for (rn in rownames(tbl))
{
  n <- tbl[rn]
  if (n>0.1*n_psk)
  {
    n_psk_this <- length(unique(labs$SK[labs$lab_super_group == rn]))
    print(sprintf("LAB [Npatients = %6d, %4.1f%%; Nfacts = %6d, %4.1f%%] %s", n_psk_this, 100*n_psk_this/n_psk, n, 100*n/n_data, rn))
  }
  n_total <- n_total + n
}
print(sprintf("DEBUG: n_total = %d",n_total))

lsg <- "General Test"
labs_lsg <- labs[labs$lab_super_group == lsg,]
tbl <- table(labs_lsg$lab_procedure_group, labs_lsg$lab_procedure_mnemonic)
n_total <- 0
for (rn in rownames(tbl))
{
  for (cn in colnames(tbl))
  {
    n <- tbl[rn,cn]
    
    if (n>0.5*n_psk)
    {
      n_psk_this <- length(unique(labs_lsg$SK[labs_lsg$lab_procedure_group == rn & labs_lsg$lab_procedure_mnemonic == cn ]))
      print(sprintf("LAB [Npatients = %6d, %4.1f%% ; Nfacts = %6d, %4.1f%%] %s: %s: %s", n_psk_this, 100*n_psk_this/n_psk, n, 100*n/n_data, lsg, rn, cn))
    }
    n_total <- n_total + n
  }
}
print(sprintf("DEBUG: n_total = %d",n_total))


###
#Procedures:
###
print("===== PROCEDURES:")
procs <- read.csv("data/hf_cohort_ccancer_f_procedure.csv", stringsAsFactors=F, colClasses="character")
procs <- subset(procs, !is.na(FID) & FID!="")
tbl <- table(substr(procs$Date,1,4))
barplot(tbl, main="Procedure facts by year", xlab="year", las=3, ylab="count", col="orange")
for (y in rownames(tbl))
{
  print(sprintf("PROCEDURE [Nfacts = %6d, %4.1f%%] %s", tbl[y], 100*tbl[y]/sum(tbl), y))
}

sql <- "SELECT * FROM hf_d_procedure ORDER BY procedure_id"
results <- dbSendQuery(con_hf,sql)
codes <- dbFetch(results, colClasses="character")
dbClearResult(results)
codes$procedure_id <- as.character(codes$procedure_id)
print(sprintf("n_procedure_codes = %d\n",nrow(codes)))
procs <- merge(procs, codes, all.x=T, all.y=F, by.x="FID", by.y="procedure_id")
colnames(procs)[1] <- "procedure_id"
print(sprintf("unique procedures: %d\n",length(unique(procs$procedure_id))))
tbl <- table(procs$procedure_description)
for (y in rownames(tbl))
{
  if (tbl[y] > 100)
  {
    print(sprintf("Procedure [Nfacts = %6d, %4.1f%%] %s", tbl[y], 100*tbl[y]/sum(tbl), y))
  }
}


###
#Surgery
###
print("===== SURGERY:")
surgery <- read.csv("data/hf_cohort_ccancer_f_surgery.csv", stringsAsFactors=F, colClasses="character")
surgery <- subset(surgery, !is.na(FID) & FID!="")
tbl <- table(substr(surgery$Date,1,4))
barplot(tbl, main="Surgery facts by year", xlab="year", las=3, ylab="count", col="orange")

sql <- "SELECT * FROM hf_d_surgical_procedure ORDER BY surgical_procedure_id"
results <- dbSendQuery(con_hf,sql)
codes <- dbFetch(results, colClasses="character")
dbClearResult(results)
print(sprintf("n_surg_codes = %d\n",nrow(codes)))
codes$surgical_procedure_id <- as.integer(codes$surgical_procedure_id)
codes <- codes[order(codes$surgical_procedure_id),]
surgery <- merge(surgery, codes, all.x=T, all.y=F, by.x="FID", by.y="surgical_procedure_id")
for (surg_id in unique(surgery$FID))
{
  desc <- codes$surgical_procedure_desc[codes$surgical_procedure_id == surg_id]
  nf <- nrow(surgery[surgery$FID == surg_id,])
  np <- length(unique(surgery$SK[surgery$FID == surg_id]))
  if (np > 0.01*n_psk)
  {
    print(sprintf("SURGERY [Npatients = %4d ; Nfacts = %4d] %s", np, nf, desc))
  }
}

###
#Discharges:
###
print("===== DISCHARGE:")
dischgs <- read.csv("data/hf_cohort_ccancer_f_discharge.csv", stringsAsFactors=F, colClasses="character")
dischgs <- subset(dischgs, !is.na(FID) & FID!="")
tbl <- table(substr(dischgs$Date,1,4))
barplot(tbl, main="Discharge facts by year", xlab="year", las=3, ylab="count", col="orange")
for (y in rownames(tbl))
{
  print(sprintf("DISCHARGE [Nfacts = %6d, %4.1f%%] %s", tbl[y], 100*tbl[y]/sum(tbl), y))
}

sql <- "SELECT * FROM hf_d_dischg_disp ORDER BY dischg_disp_id"
results <- dbSendQuery(con_hf,sql)
codes <- dbFetch(results, colClasses="character")
dbClearResult(results)
print(sprintf("n_discharge_codes = %d\n",nrow(codes)))
codes$dischg_disp_code <- as.integer(codes$dischg_disp_code)
codes <- codes[order(codes$dischg_disp_code),]
dischgs <- merge(dischgs, codes, all.x=T, all.y=F, by.x="FID", by.y="dischg_disp_id")
colnames(dischgs)[1] <- "dischg_disp_id"
print(sprintf("unique discharge codes: %d\n",length(unique(dischgs$dischg_disp_code))))

n_data <- nrow(dischgs)
tbl <- table(dischgs$dischg_disp_code)
n_total <- 0
psk_total <- c()
psk_expired <- c()
for (ddcode in rownames(tbl))
{
  n <- tbl[ddcode]
  psk_this <- unique(dischgs$SK[dischgs$dischg_disp_code == ddcode])
  psk_total <- unique(c(psk_total, psk_this))
  if (ddcode %in% c(20,40,41,42))
  {
    psk_expired <- unique(c(psk_expired, psk_this))
  }
  dddesc <- paste(codes$dischg_disp_code_desc[codes$dischg_disp_code == ddcode],collapse=" OR ")
  print(sprintf("DISCHARGE [Npatients = %6d, %4.1f%%; Nfacts = %6d, %4.1f%%] %s: %s", length(psk_this), 100*length(psk_this)/n_psk, n, 100*n/n_data, ddcode, dddesc))
  n_total <- n_total + n
}
print(sprintf("DEBUG: n_total = %d",n_total))
print(sprintf("DEBUG: n_psk_expired = %d",length(psk_expired)))
print(sprintf("DEBUG: n_psk_total = %d",length(psk_total)))

dischgs_expired <- subset(dischgs, dischg_disp_code %in% c(20,40,41,42), select=c("SK","Date","dischg_disp_code"))
tbl <- table(substr(dischgs_expired$Date,1,4))
barplot(tbl, main="Expired by year", xlab="year", las=3, ylab="count", col="orange")

###
#dbDisconnect(con_hf)

print(sprintf("elapsed time (total): %.2fs",(proc.time()-t0)[3]))
