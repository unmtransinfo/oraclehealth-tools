#!/usr/bin/Rscript
#
library(readr)
library(data.table)
library(plotly)
library(dplyr)
library(RPostgreSQL)
library(vioplot)
#
TITLE_PREFIX <- "HF Type1 Diabetes Cohort"
#
#Sanity cutoffs:
HBA1C_MAX <- 20
HBA1C_MIN <- 3
###
#Insulin medication_id's:
MID_INSULIN_ENG <- c(43829, 43830, 43831, 113373, 113374, 115543, 115544, 115940, 116103, 116104, 133781, 133782, 312759, 312761, 2485283, 3533894, 3533895, 3636863, 3636869, 4452574, 5236308, 5819190, 5819191, 5940412, 6922916, 7793987, 8060730, 8064453)
MID_INSULIN_HUM <- c(45058, 45059, 45060, 45061, 45062, 45064, 45065, 45066, 45067, 45068, 45070, 45071, 45072, 45073, 45074, 45075, 45077, 45078, 45079, 45080, 45081, 45082, 45951, 45955, 45957, 133778, 133779, 133780, 2725570, 4422919, 8060737, 8063991, 8065846, 8082851, 8083001)
MID_INSULIN_PORK <- c(22427, 45056, 45083, 45157, 45956, 51774)
#
RACES_COMMON <- c("African American", "Asian", "Caucasian", "Hispanic", "Native American")
#
writeLines(sprintf("Run date: %s",date()))
#
#Initial cohort defined by diabetes query.
c0 <- read_csv("data/hf_diabetes_cohort.csv", col_types = cols( patient_id = col_integer(), patient_sk = col_integer(), diagnosis_code = col_character(), age_in_years = col_integer(), gender = col_character(), race = col_character(), dx_date = col_date(format = "%Y-%m-%d %H:%M:%S")))
setDT(c0, key="diagnosis_code")
#
writeLines("===== INITIAL COHORT, FROM DIABETES DIAGNOSES:")
writeLines(sprintf("Cohort-initial: nrows = %d ; n_patient_id = %d ; n_patient_sk = %d",nrow(c0), length(unique(c0$patient_id)),length(unique(c0$patient_sk))))
#
icd_codes <- read_csv("data/hf_diag_codes_icd9.csv", col_types = cols(diagnosis_code = col_character()))
setDT(icd_codes, key="diagnosis_code")
#icd_codes <- icd_codes[icd_codes$diagnosis_type=="ICD9",]
#
c0 <- icd_codes[c0]
#
t <- table(c0$diagnosis_code)
writeLines(sprintf("N = %d, %s: %s",t[names(t)], names(t), 
                   icd_codes$diagnosis_description[icd_codes$diagnosis_code %in% names(t)]))
#
c0$yob <- as.numeric(format(c0$dx_date,'%Y')) - c0$age_in_years
#
#Fix conflicting YOBs.
yob <- unique(subset(c0, select = c("patient_sk","yob")))
yob <- aggregate(x = yob$yob, by = list(yob$patient_sk), FUN = min)
colnames(yob) <- c("patient_sk","yob")
c0$yob <- NULL
c0 <- merge(c0, yob, all.x=T, all.y=F, by="patient_sk")
#
#Remove conflicting gender and race.
unanimous <- function(v) {
  if (length(v)==0) {return("CONFLICT")}
  for (val in v) {
    if (val!=v[1]) {
      writeLines("DEBUG: CONFLICT")
      return("CONFLICT")
      }
    }
  v[1]
}
#
gender <- unique(subset(c0, select = c("patient_sk", "gender")))
gender <- aggregate(x = gender$gender, by = list(gender$patient_sk), FUN = unanimous)
colnames(gender) <- c("patient_sk","gender")
writeLines(sprintf("Npatients with conflicting gender data: %d", nrow(gender[gender$gender=="CONFLICT",])))
c0$gender <- NULL
c0 <- merge(c0, gender, all.x=T, all.y=F, by="patient_sk")
c0 <- c0[c0$gender!="CONFLICT",]
#
race <- unique(subset(c0, select = c("patient_sk", "race")))
race <- aggregate(x = race$race, by = list(race$patient_sk), FUN = unanimous)
colnames(race) <- c("patient_sk","race")
writeLines(sprintf("Npatients with conflicting race data: %d", nrow(race[race$race=="CONFLICT",])))
c0$race <- NULL
c0 <- merge(c0, race, all.x=T, all.y=F, by="patient_sk")
c0 <- c0[c0$race!="CONFLICT",]
#
###
writeLines("===== GEOGRAPHY (BASED ON DIAGNOSIS LOCATION):")
###
#SSH tunnel required:
#dbcon_hf <- dbConnect(PostgreSQL(), host="localhost", port="63333", dbname="healthfacts", user= "jjyang", password="")
#
hosp_codes <- read_csv("data/hf_d_hospital.csv", col_types = cols(hospital_id = col_integer()))
#
setDT(hosp_codes,key="hospital_id")
setDT(c0, key="hospital_id")
c0 <- hosp_codes[c0]
#
t <- table(c0$census_region, c0$census_division)
for (cname in colnames(t)) {
  for (rname in rownames(t)) {
    n <- t[rname,cname]
    if (n>0) { 
      writeLines(sprintf("CENSUS REGION/DIVISION = %12s/%s: N = %6d",rname, cname, t[rname,cname]))
    }
  }
}
#
###
cohort <- unique(subset(c0, select = c("patient_sk", "yob", "gender", "race")))
cohort <- cohort[order(cohort$patient_sk),]
cohort <- cohort[cohort$gender %in% c("Female","Male"), ]
cohort$gender <- as.character(cohort$gender)
writeLines(sprintf("INITIAL COHORT: N = %d",nrow(cohort)))
#
writeLines("===== FILTERING PATIENTS WITH MANY IDs:")
pid_counts <- aggregate(x = c0$patient_id, by = list(c0$patient_sk), FUN = length)
colnames(pid_counts) <- c("patient_sk", "n_patient_id")
cohort <- merge(cohort, pid_counts, all.x=T, all.y=F, by="patient_sk")
#
#Dx per patient:
dx_counts <- aggregate(x = c0$diagnosis_code, by = list(c0$patient_sk), FUN = length)
colnames(dx_counts) <- c("patient_sk", "n_dx")
cohort <- merge(cohort, dx_counts, all.x=T, all.y=F, by="patient_sk")
#
writeLines(sprintf("Patients with >10 patient_ids: %d",nrow(cohort[cohort$n_patient_id>10,])))
#
cohort <- cohort[cohort$n_patient_id<=10,]
writeLines(sprintf("FILTERED COHORT: N = %d",nrow(cohort)))
#
n_pid <- length(unique(cohort$patient_id))
n_psk <- length(unique(cohort$patient_sk))
#
t <- table(cohort$n_patient_id)
writeLines(sprintf("PATIENT_ID_COUNT = %12s: N = %8d",names(t), t[names(t)]))
#
t <- table(cohort$n_dx)
writeLines(sprintf("Dx = %24s: N = %8d",names(t), t[names(t)]))
#
write.table(cohort$patient_sk, file = "data/hf_diabetes_cohort.sk", row.names=F, col.names=F, quote=F)
writeLines("===== GENDER AND RACE:")
t <- table(cohort$gender)
writeLines(sprintf("GENDER = %24s: N = %8d",names(t), t[names(t)]))
#
t <- table(cohort$race)
writeLines(sprintf("RACE = %24s: N = %8d",names(t), t[names(t)]))
#
###
#Dx for cohort only
writeLines("===== DIABETES Dx FOR COHORT ONLY:")
c0 <- merge(cohort, subset(c0, select = c("patient_sk","patient_id","diagnosis_id","diagnosis_code","dx_date","diagnosis_description","age_in_years")), all.x=T, all.y=F, by="patient_sk")
c0 <- c0[order(c0$patient_sk),]
#
t <- table(as.numeric(format(c0$dx_date,'%Y')))
writeLines(sprintf("Dx %s: N = %d",names(t), t[names(t)]))
#
q <- quantile(c0$age_in_years, seq(0,1,0.1))
writeLines(sprintf("AGE: %s-ile: %3d",names(q),q[names(q)]))
hist(c0$age_in_years, main="Age at diagnosis", xlab="age", ylab="", xlim=c(0,100), las=3, col="orange")
#
###
#ptype_codes <- dbGetQuery(dbcon_hf,"SELECT * FROM hf_d_patient_type")
ptype_codes <- read_csv("data/hf_d_patient_type.csv")
#
setDT(ptype_codes,key="patient_type_id")
###
# *** FACTS
###
###
writeLines("===== ALL Dx FOR COHORT:")
diags <- read_csv("data/hf_diabetes_cohort_f_diagnosis.csv.gz", col_types = cols(SK = col_integer(), FID = col_integer(), Date = col_date(format = "%Y-%m-%d")))
###
#
names(diags)[names(diags)=="FID"] <- "diagnosis_id"
setDT(diags, key="diagnosis_id")
writeLines(sprintf("DIAGNOSES: removing rows with missing dates: %d",nrow(diags[is.na(diags$Date),])))
diags <- diags[!is.na(diags$Date),]
#
setDT(icd_codes, key="diagnosis_id")
#
t <- table(as.numeric(format(diags$Date,'%Y')))
barplot(t, main="Diagnosis facts by year", xlab="year", las=3, ylab="count", col="orange")

writeLines(sprintf("DIAGNOSIS %s [Nfacts = %6d, %4.1f%%]", names(t), t[names(t)], 100*t[names(t)]/sum(t)))

diags <- icd_codes[diags]

diabetes_codes <- icd_codes$diagnosis_code[grepl("diabetes", icd_codes$diagnosis_description, ignore.case=T)]
#diabetes_codes <- c("250.01", "250.03")

writeLines(sprintf("unique other diagnoses: %d",length(unique(diags$diagnosis_id[!(diags$diagnosis_code %in% diabetes_codes)]))))
#Common other diagnoses:
diag_counts <- aggregate(x=diags$EID, by=list(diags$diagnosis_id), FUN=length) 
colnames(diag_counts) <- c("diagnosis_id", "n_diags")
setDT(diag_counts, key="diagnosis_id")
diag_counts <- icd_codes[diag_counts]
diag_counts <- diag_counts[!(diag_counts$diagnosis_code %in% diabetes_codes),]
diag_counts <- diag_counts[order(-diag_counts$n_diags),]
diag_counts <- diag_counts[1:50,]
DIDS_TOP_OTHER <- unique(diag_counts$diagnosis_id)
writeLines(sprintf("DIAGNOSES (%6s) %32s [Nfacts = %8d]", diag_counts$diagnosis_code,
	diag_counts$diagnosis_description, diag_counts$n_diags))
#
diags_diabetes <- subset(diags,diagnosis_code %in% diabetes_codes)
t <- table(as.numeric(format(diags_diabetes$Date,'%Y')))
barplot(t, main="Diagnosis facts by year", xlab="year", las=3, ylab="count" , col="orange")
#
diags <- merge(diags, ptype_codes, all.x=T, all.y=F, by.x="PtypeID", by.y="patient_type_id")
d <- data.table(table(diags$patient_type_desc))
d <- d[order(-d$N),]
writeLines(sprintf("Dx_PatientType = %24s: N = %8d",d$V1, d$N))
#
###
#Dx by gender:
diags <- merge(diags, cohort, all.x=T, all.y=F, by.x="SK", by.y="patient_sk")
n_diags_female <- nrow(diags[diags$gender=="Female",])
n_diags_male <- nrow(diags[diags$gender=="Male",])
writeLines(sprintf("Females in diags: %d",length(unique(diags$SK[diags$gender=="Female"]))))
writeLines(sprintf("Males in diags: %d",length(unique(diags$SK[diags$gender=="Male"]))))
writeLines(sprintf("Total patients in diags: %d",length(unique(diags$SK))))
#
if (interactive() & readline("DEBUG: continue [y]/n? ")=='n') stop("STOPPING...")
#
diag_counts_bygender <- aggregate(x=diags$EID, by=list(diags$diagnosis_id, diags$gender), FUN=length) 
colnames(diag_counts_bygender) <- c("diagnosis_id", "gender", "n_diags")
setDT(diag_counts_bygender, key="diagnosis_id")
diag_counts_bygender <- icd_codes[diag_counts_bygender]
diag_counts_bygender <- diag_counts_bygender[!(diag_counts_bygender$diagnosis_code %in% diabetes_codes),]
diag_counts_bygender <- diag_counts_bygender[diag_counts_bygender$diagnosis_id %in% DIDS_TOP_OTHER, ]
diag_counts_bygender <- diag_counts_bygender[order(diag_counts_bygender$diagnosis_id, diag_counts_bygender$gender),]
#Normalize for female/male distribution to reflect prevalence.
diag_counts_bygender$n_diags_norm <- NA
diag_counts_bygender$n_diags_norm[diag_counts_bygender$gender=="Male"] <- (n_diags_female + n_diags_male)/(2* n_diags_male) * diag_counts_bygender$n_diags[diag_counts_bygender$gender=="Male"] 
diag_counts_bygender$n_diags_norm[diag_counts_bygender$gender=="Female"] <- (n_diags_female + n_diags_male)/(2* n_diags_female) * diag_counts_bygender$n_diags[diag_counts_bygender$gender=="Female"]
diag_counts_bygender$n_diags_norm <- as.integer(diag_counts_bygender$n_diags_norm)
for (did in unique(diag_counts_bygender$diagnosis_id))
{
  diags_this <- diag_counts_bygender[diag_counts_bygender$diagnosis_id==did,]
  writeLines(sprintf("Dx: (%7s) %44s norm: N_female = %6d ; N_male = %6d", 
                     diags_this$diagnosis_code[1],
                     diags_this$diagnosis_description[1],
                     diags_this$n_diags_norm[diags_this$gender=="Female"],
                     diags_this$n_diags_norm[diags_this$gender=="Male"]))
}

#
###
#Medications
###
writeLines("===== ALL MEDS FOR COHORT:")
meds <- read_csv("data/hf_diabetes_cohort_f_medication.csv.gz", col_types = cols(SK = col_integer(), FID = col_integer(), Date = col_date(format = "%Y-%m-%d")))
###
writeLines(sprintf("MEDICATIONS: removing rows with missing dates: %d",nrow(meds[is.na(meds$Date),])))
meds <- meds[!is.na(meds$Date),]
names(meds)[names(meds)=="FID"] <- "medication_id"
setDT(meds, key="medication_id")
#
meds <- meds[order(meds$EID, meds$Date),]
#
#
t <- table(as.numeric(format(meds$Date,'%Y')))
barplot(t, main="Medication facts by year", xlab="year", las=3, ylab="count", col="orange")
writeLines(sprintf("MEDICATION %s [Nfacts = %6d, %4.1f%%]", names(t), t[names(t)], 100*t[names(t)]/sum(t)))
#
#med_codes <- dbGetQuery(dbcon_hf,"SELECT medication_id, ndc_code, brand_name, generic_name, product_strength_description, route_description FROM hf_d_medication")
#med_codes$medication_id <- as.integer(med_codes$medication_id)
#med_codes$ndc_code <- as.character(med_codes$ndc_code)
#
med_codes <- read_csv("data/hf_d_medication.csv", col_types = cols(medication_id = col_integer(), ndc_code = col_character()))
#
setDT(med_codes, key="medication_id")
#
writeLines(sprintf("n_med_codes = %d",nrow(med_codes)))
#meds <- med_codes[meds] #Why didn't this work?
meds <- merge(meds, med_codes, all.x=T, all.y=F, by="medication_id")
#
writeLines(sprintf("unique meds: %d",length(unique(meds$medication_id))))
#Common medications (not NaCl):
med_counts <- aggregate(x=meds$EID, by=list(meds$medication_id), FUN=length) 
colnames(med_counts) <- c("medication_id", "n_meds")
setDT(med_counts, key="medication_id")
med_counts <- med_codes[med_counts]
med_counts <- med_counts[order(-med_counts$n_meds),]
med_counts <- med_counts[!grepl("sodium chloride", med_counts$generic_name) & !grepl("sodium chloride", med_counts$brand_name, ignore.case=T), ]
med_counts <- med_counts[1:50,]
writeLines(sprintf("MEDICATIONS (%24s) %24s [Nfacts = %8d]", med_counts$generic_name,
                   med_counts$brand_name, med_counts$n_meds))
#
meds <- merge(meds, ptype_codes, all.x=T, all.y=F, by.x="PtypeID", by.y="patient_type_id")
d <- data.table(table(meds$patient_type_desc))
d <- d[order(-d$N),]
writeLines(sprintf("Rx_PatientType = %24s: N = %8d",d$V1, d$N))
###
#Glucose-lowering non-insulin drugs:
###
glnid_codes <- read_csv("data/hf_med_glucose-lowering.csv", col_types = cols(medication_id = col_integer()))
MID_GLNID <- unique(glnid_codes$medication_id)
glnids <- meds[meds$medication_id %in% MID_GLNID,]
writeLines(sprintf("Total glucose-lowering non-insulin meds: %d",nrow(glnids)))
writeLines(sprintf("Total patients with glucose-lowering non-insulin meds: %d",length(unique(glnids$SK))))
d <- data.table(table(glnids$generic_name))
d <- d[order(-d$N),]
writeLines(sprintf("Rx_GLNID = %24s: N_med = %8d",d$V1, d$N))
glnids_by_sk <- unique(subset(glnids, select = c("SK", "generic_name")))
d2 <- data.table(table(glnids_by_sk$generic_name))
d2 <- d2[order(-d2$N),]
writeLines(sprintf("Rx_GLNID = %24s: N_patient = %8d",d2$V1, d2$N))
sks_glnid <- unique(glnids$SK)
#
###
#Insulins:
###
insulins <- meds[meds$medication_id %in% c(MID_INSULIN_ENG,MID_INSULIN_HUM,MID_INSULIN_PORK),]
insulins$ins <- NA
insulins$ins[insulins$medication_id %in% MID_INSULIN_ENG] <- "ENGINEERED"
insulins$ins[insulins$medication_id %in% MID_INSULIN_HUM] <- "HUMAN"
#
writeLines(sprintf("Total ENGINEERED insulin meds: %d",nrow(insulins[insulins$ins=="ENGINEERED",])))
writeLines(sprintf("Total HUMAN insulin meds: %d",nrow(insulins[insulins$ins=="HUMAN",])))
writeLines(sprintf("Total insulin meds: %d",nrow(insulins)))
#
sks_insulins <- unique(insulins$SK)
sks_insulins_eng <- unique(insulins$SK[insulins$ins=="ENGINEERED"])
sks_insulins_hum <- unique(insulins$SK[insulins$ins=="HUMAN"])
sks_insulins_eng_only <- setdiff(sks_insulins_eng,sks_insulins_hum)
sks_insulins_hum_only <- setdiff(sks_insulins_hum,sks_insulins_eng)
writeLines(sprintf("Total patients with insulin meds: %d",length(sks_insulins)))
writeLines(sprintf("Patients with ENGINEERED insulin meds: %d",length(sks_insulins_eng)))
writeLines(sprintf("Patients with HUMAN insulin meds: %d",length(sks_insulins_hum)))
writeLines(sprintf("Patients with BOTH HUMAN and ENGINEERED insulin meds: %d",length(intersect(sks_insulins_hum,sks_insulins_eng))))
writeLines(sprintf("Patients with ONLY ENGINEERED insulin meds: %d",length(sks_insulins_eng_only)))
writeLines(sprintf("Patients with ONLY HUMAN insulin meds: %d",length(sks_insulins_hum_only)))
#
#
#Patients who switch once, either HUMAN->ENGINEERED or vice versa.
#For each patient in meds, find:
#  - dates of 1st, last E-insulin
#  - dates of 1st, last H-insulin
meds_e <- subset(meds, medication_id %in% MID_INSULIN_ENG, select = c(SK, Date))
meds_e_first <- aggregate(x=meds_e$Date, by=list(meds_e$SK), FUN=min) 
colnames(meds_e_first) <- c("patient_sk", "med_eins_first")
meds_e_last <- aggregate(x=meds_e$Date, by=list(meds_e$SK), FUN=max) 
colnames(meds_e_last) <- c("patient_sk", "med_eins_last")
#
meds_h <- subset(meds, medication_id %in% MID_INSULIN_HUM, select=c(SK,Date))
meds_h_first <- aggregate(x=meds_h$Date, by=list(meds_h$SK), FUN=min) 
colnames(meds_h_first) <- c("patient_sk", "med_hins_first")
meds_h_last <- aggregate(x=meds_h$Date, by=list(meds_h$SK), FUN=max) 
colnames(meds_h_last) <- c("patient_sk", "med_hins_last")
#
meds_eh <- merge(meds_h_first, meds_h_last, all=T, by="patient_sk")
meds_eh <- merge(meds_eh, meds_e_first, all=T, by="patient_sk")
meds_eh <- merge(meds_eh, meds_e_last, all=T, by="patient_sk")
#
meds_h2e <- meds_eh[!is.na(meds_eh$med_hins_last) & !is.na(meds_eh$med_eins_first) & meds_eh$med_hins_last<meds_eh$med_eins_first, ]
writeLines(sprintf("Patients H-to-E insulin switchers: %d",length(unique(meds_h2e$patient_sk))))
meds_e2h <- meds_eh[!is.na(meds_eh$med_eins_last) & !is.na(meds_eh$med_hins_first) & meds_eh$med_eins_last<meds_eh$med_hins_first, ]
writeLines(sprintf("Patients E-to-H insulin switchers: %d",length(unique(meds_e2h$patient_sk))))
#
###
#Clincial events:
###
writeLines("===== ALL CLINICAL EVENTS FOR COHORT:")
events <- read_csv("data/hf_diabetes_cohort_f_clinical_event.csv.gz", col_types = cols(SK = col_integer(), FID = col_integer(), Date = col_date(format = "%Y-%m-%d")))
###
names(events)[names(events)=="FID"] <- "event_code_id"
setDT(events, key="event_code_id")
writeLines(sprintf("CLINICAL EVENTS: removing rows with missing dates: %d",nrow(events[is.na(events$Date),])))
events <- events[!is.na(events$Date),]
t <- table(as.numeric(format(events$Date,'%Y')))
barplot(t, main="Clinical-event facts by year", xlab="year", las=3, ylab="count", col="orange")
writeLines(sprintf("LAB %s [Nfacts = %6d, %4.1f%%]", names(t), t[names(t)], 100*t[names(t)]/sum(t)))
#
#event_codes <- dbGetQuery(dbcon_hf,"SELECT * FROM hf_d_event_code")
event_codes <- read_csv("data/hf_d_event_code.csv", col_types = cols(event_code_id = col_integer()))
setDT(event_codes, key="event_code_id")
events <- event_codes[events]
#
#Common CLINICAL EVENTS:
#Aggregating by event_code_group (e.g. Height - length).
event_counts <- aggregate(x=events$EID, by=list(events$event_code_group), FUN=length) 
colnames(event_counts) <- c("event_code_group", "n_events")
#setDT(event_counts, key="event_code_id")
#event_counts <- event_codes[event_counts]
event_counts <- event_counts[order(-event_counts$n_events),]
event_counts <- event_counts[1:30,]
#writeLines(sprintf("CLINICAL_EVENT (%18s:%5d) %32s [Nfacts = %8d]", event_counts$event_code_group, event_counts$event_code_id, event_counts$event_code_desc, event_counts$n_events))
writeLines(sprintf("CLINICAL_EVENT (%18s) [Nfacts = %8d]", event_counts$event_code_group, event_counts$n_events))
#
events <- merge(events, ptype_codes, all.x=T, all.y=F, by.x="PtypeID", by.y="patient_type_id")
d <- data.table(table(events$patient_type_desc))
d <- d[order(-d$N),]
writeLines(sprintf("Clinical-events_PatientType = %24s: N = %8d",d$V1, d$N))
###
#BMI and Weight:
events_bmi <- events[events$event_code_display=="BMI",]
events_bmi <- events_bmi[events_bmi$Units=="kg/m2",]
events_bmi <- merge(events_bmi, cohort, all.x=T, all.y=F, by.x="SK", by.y="patient_sk")
events_bmi$race <- as.character(events_bmi$race)
events_bmi <- events_bmi[events_bmi$race %in% RACES_COMMON,]
#
events_wt <- events[events$event_code_display=="Wt",]
events_wt <- events_wt[events_wt$Units %in% c("[lb_tr]","kg"),]
events_wt$Result[events_wt$Units=="kg"] <- events_wt$Result[events_wt$Units=="kg"] * 2.20462
events_wt$Units <- "[lb_tr]"
events_wt <- merge(events_wt, cohort, all.x=T, all.y=F, by.x="SK", by.y="patient_sk")
events_wt$race <- as.character(events_wt$race)
events_wt <- events_wt[events_wt$race %in% RACES_COMMON,]
#
p3.1 <- plot_ly(events_bmi, y=~Result, x=~race, color=~gender, type="box",
  boxmean=T, marker=list(symbol="dot", opacity=0.4)) %>%
  layout(title=sprintf("%s<br>BMI values<br>N_total = %d",TITLE_PREFIX, nrow(events_bmi)),
  yaxis=list(title="BMI (kg/m2)", range=c(0,80)), xaxis=list(title=""), 
  margin=list(t=100,l=80,b=100,r=80), showlegend=T, legend = list(x=0.7,y=1.0), boxmode="group",
  font=list(family="Arial", size=14))
p3.1
#
p3.2 <- plot_ly(events_wt, y=~Result, x=~race, color=~gender, type="box",
              boxmean=T, marker=list(symbol="dot", opacity=0.4)) %>%
  layout(title=sprintf("%s<br>Weight values<br>N_total = %d", TITLE_PREFIX, nrow(events_wt)),
         yaxis=list(title="Wt (lb)", range=c(0,500)), xaxis=list(title=""), 
         margin=list(t=100,l=80,b=100,r=80), showlegend=T, legend = list(x=0.7,y=1.0), boxmode="group",
         font=list(family="Arial", size=14))
p3.2
#
###
#Labs:
###
writeLines("===== ALL LABS FOR COHORT:")
labs <- read_csv("data/hf_diabetes_cohort_f_lab.csv.gz", col_types = cols(SK = col_integer(), FID = col_integer(), Date = col_date(format = "%Y-%m-%d")))
###
names(labs)[names(labs)=="FID"] <- "lab_procedure_id"
setDT(labs, key="lab_procedure_id")
writeLines(sprintf("LABS: removing rows with missing dates: %d",nrow(labs[is.na(labs$Date),])))
labs <- labs[!is.na(labs$Date),]
t <- table(as.numeric(format(labs$Date,'%Y')))
barplot(t, main="Lab facts by year", xlab="year", las=3, ylab="count", col="orange")
writeLines(sprintf("LAB %s [Nfacts = %6d, %4.1f%%]", names(t), t[names(t)], 100*t[names(t)]/sum(t)))
#
#sql <- "SELECT * FROM hf_d_lab_procedure ORDER BY lab_procedure_id"
#lab_codes <- dbGetQuery(dbcon_hf,sql)
#lab_codes$lab_procedure_id <- as.integer(lab_codes$lab_procedure_id)
lab_codes <- read_csv("data/hf_d_lab_procedure.csv", col_types = cols(lab_procedure_id = col_integer()))
setDT(lab_codes,key="lab_procedure_id")
writeLines(sprintf("n_lab_codes = %d",nrow(lab_codes)))
labs <- lab_codes[labs]
writeLines(sprintf("unique lab procedures: %d",length(unique(labs$lab_procedure_id))))
#
n_data <- nrow(labs)
t <- table(labs$lab_super_group)
writeLines(sprintf("LAB_SUPER_GROUP %28s [Nfacts = %8d, %4.1f%%]", names(t), t[names(t)], 100*t[names(t)]/sum(t)))
#
#Common labs:
lab_counts <- aggregate(x=labs$EID, by=list(labs$lab_procedure_id), FUN=length) 
colnames(lab_counts) <- c("lab_procedure_id", "n_labs")
setDT(lab_counts, key="lab_procedure_id")
lab_counts <- lab_codes[lab_counts]
lab_counts <- lab_counts[order(-lab_counts$n_labs),]
lab_counts <- lab_counts[1:50,]
writeLines(sprintf("LAB_TEST (%18s:%5d) %32s [Nfacts = %8d]", lab_counts$lab_super_group, 
                   lab_counts$lab_procedure_id,lab_counts$lab_procedure_mnemonic, lab_counts$n_labs))
#
#HbA1c common test lab_procedure_id=1093 (General Test)
labs_hba1c <- labs[labs$lab_procedure_id==1093,]
sks_hba1c <- unique(labs_hba1c$SK)
writeLines(sprintf("Total HbA1c labs: %d",nrow(labs_hba1c)))
writeLines(sprintf("Patients with HbA1c labs: %d",length(sks_hba1c)))
labs_hba1c <- labs_hba1c[labs_hba1c$Result>=HBA1C_MIN & labs_hba1c$Result<=HBA1C_MAX,]
sks_hba1c <- unique(labs_hba1c$SK)
writeLines(sprintf("Total SANE HbA1c labs: %d",nrow(labs_hba1c)))
writeLines(sprintf("Patients with SANE HbA1c labs: %d",length(sks_hba1c)))
#
writeLines("===== FILTER COHORT FOR SUFFICIENT DATA:")
#
sks_ins_hba1c <- intersect(sks_insulins,sks_hba1c)
writeLines(sprintf("Patients with insulin meds AND SANE HbA1c labs: %d",length(sks_ins_hba1c)))
#
sks_ins_hum_only_hba1c <- intersect(sks_insulins_hum_only, sks_hba1c)
sks_ins_eng_only_hba1c <- intersect(sks_insulins_eng_only, sks_hba1c)
writeLines(sprintf("Patients with ONLY HUMAN insulin meds AND SANE HbA1c labs: %d",length(sks_ins_hum_only_hba1c)))
writeLines(sprintf("Patients with ONLY ENGINEERED insulin meds AND SANE HbA1c labs: %d",length(sks_ins_eng_only_hba1c)))
#
cohort <- cohort[cohort$patient_sk %in% union(sks_ins_hum_only_hba1c,sks_ins_eng_only_hba1c),]
#
#How many HbA1c's per patient?
hba1c_counts <- aggregate(x = labs_hba1c$Result, by = list(labs_hba1c$SK), FUN = length)
colnames(hba1c_counts) <- c("patient_sk", "n_hba1c")
cohort <- merge(cohort, hba1c_counts, all.x=T, all.y=F, by="patient_sk")
#
hba1c_mean <- aggregate(x = labs_hba1c$Result, by = list(labs_hba1c$SK), FUN = mean)
colnames(hba1c_mean) <- c("patient_sk", "mean_hba1c")
cohort <- merge(cohort, hba1c_mean, all.x=T, all.y=F, by="patient_sk")
#
hba1c_meandate <- aggregate(x=labs_hba1c$Date, by=list(labs_hba1c$SK), FUN=mean)
colnames(hba1c_meandate) <- c("patient_sk", "hba1c_meandate")
cohort <- merge(cohort, hba1c_meandate, all.x=T, all.y=F, by="patient_sk")
#
writeLines(sprintf("Patients with glucose-lowering non-insulin meds: N = %d",nrow(cohort[cohort$patient_sk %in% sks_glnid,])))
cohort <- cohort[!(cohort$patient_sk %in% sks_glnid),]
#
writeLines(sprintf("FINAL COHORT: N = %d",nrow(cohort)))
###
#
print("*** HbA1c DISTRIBUTIONS:\n")
q <- quantile(labs_hba1c$Result, probs = c(0, .25, .50, .75, seq(0.9, 1, 0.01)))
print(sprintf("HbA1c (raw): N: %d ; range: [%f,%f] ; mean: %f\n", nrow(labs_hba1c),
              min(labs_hba1c$Result), max(labs_hba1c$Result), mean(labs_hba1c$Result)))
for (i in 1:length(q)) {
  print(sprintf("%5s-ile: %.2f\n", names(q)[i], q[i]))
}
#
cohort$ins <- NA
cohort$ins[cohort$patient_sk %in% sks_insulins_eng_only] <- "ENGINEERED"
cohort$ins[cohort$patient_sk %in% sks_insulins_hum_only] <- "HUMAN"
#
setDT(labs_hba1c, key="SK")
labs_hba1c <- labs_hba1c[cohort]
#
labs_hba1c$age_in_years <- as.numeric(format(labs_hba1c$Date, '%Y')) - labs_hba1c$yob
#
labs_hba1c <- merge(labs_hba1c, ptype_codes, all.x=T, all.y=F, by.x="PtypeID", by.y="patient_type_id")
d <- data.table(table(labs_hba1c$patient_type_desc))
d <- d[order(-d$N),]
writeLines(sprintf("Labs-HbA1c_PatientType = %24s: N = %8d",d$V1, d$N))
#
#plot
cols_this <- c("green","red")
#
p1 <- plot_ly(labs_hba1c, x = ~Result, color = ~ins, 
            type = 'histogram', colors = cols_this) %>%
  layout(title = sprintf("%s<br>HbA1c histograms", TITLE_PREFIX),
         xaxis = list(title = "", range=c(0,HBA1C_MAX)),
         yaxis = list (title = "N"),
         margin = list(t = 100, l = 60, r = 60), 
         font = list(family = "Arial", size = 14),
         showlegend = T, legend = list(x=0.7,y=1.0))
p1
#
labs_hba1c <- labs_hba1c[!is.na(labs_hba1c$Result),]
labs_hba1c <- labs_hba1c[!is.nan(labs_hba1c$Result),]

hgbval_eng <- labs_hba1c$Result[labs_hba1c$ins=="ENGINEERED"]
hgbval_hum <- labs_hba1c$Result[labs_hba1c$ins=="HUMAN"]
#
tt <- t.test(hgbval_eng, hgbval_hum , var.equal=F)
print(sprintf("Welch's 2-sample T-test p-value = %g", tt$p.value))

#boxplot box includes 2nd and 3rd quantile.  Thus 50% of data in box.
#range=1.5 means 97% of data within whiskers.
#
boxplot(hgbval_eng, hgbval_hum, ylim=c(0,25), names=c("engineered","human"), col="tomato",
        range=1.5, varwidth=T, boxwex=0.5)
title(main="HbA1c vs. Insulin class")
abline(h=mean(hgbval_eng), col="gray", lwd=2)
abline(h=mean(hgbval_hum), col="gray", lwd=2)
text(1,mean(hgbval_eng),sprintf("mean = %.2f",mean(hgbval_eng)), pos=3, cex=0.8)
text(2,mean(hgbval_hum),sprintf("mean = %.2f",mean(hgbval_hum)), pos=1, cex=0.8)
###
vioplot(hgbval_eng, hgbval_hum, ylim=c(0,25), names=c("engineered","human"), col="tomato", range=1.5, wex=0.5)
title(main="HbA1c vs. Insulin class")
text(1,mean(hgbval_eng),sprintf("mean = %.2f",mean(hgbval_eng)), pos=4, cex=0.8)
text(2,mean(hgbval_hum),sprintf("mean = %.2f",mean(hgbval_hum)), pos=4, cex=0.8)
#
#
writeLines("===== HbA1c TRENDS Vs INSULIN-TYPE:")
writeLines(sprintf("HbA1c (%10s): N = %5d ; mean = %.2f ; median = %.2f", "ALL",
	length(labs_hba1c$Result),
	mean(labs_hba1c$Result), median(labs_hba1c$Result)))
for (ins in sort(unique(labs_hba1c$ins)))
{
  writeLines(sprintf("HbA1c (%10s): N = %5d ; mean = %.2f ; median = %.2f", ins,
	length(labs_hba1c$Result[labs_hba1c$ins==ins]),
	mean(labs_hba1c$Result[labs_hba1c$ins==ins]),
	median(labs_hba1c$Result[labs_hba1c$ins==ins])))
}
#
writeLines("===== HbA1c TRENDS Vs INSULIN-TYPE, BY RACE:")
labs_hba1c$race <- as.character(labs_hba1c$race)
labs_hba1c <- labs_hba1c[labs_hba1c$race %in% RACES_COMMON,]
#
for (race in sort(unique(labs_hba1c$race)))
{
  writeLines(sprintf("HbA1c (%16s  %10s): N = %5d ; mean = %.2f ; median = %.2f", race, "",
	length(labs_hba1c$Result[labs_hba1c$race==race]),
	mean(labs_hba1c$Result[labs_hba1c$race==race]),
	median(labs_hba1c$Result[labs_hba1c$race==race])))
  for (ins in sort(unique(labs_hba1c$ins)))
  {
    writeLines(sprintf("HbA1c (%16s, %10s): N = %5d ; mean = %.2f ; median = %.2f", race, ins,
	  length(labs_hba1c$Result[labs_hba1c$race==race & labs_hba1c$ins==ins]),
	  mean(labs_hba1c$Result[labs_hba1c$race==race & labs_hba1c$ins==ins]),
	  median(labs_hba1c$Result[labs_hba1c$race==race & labs_hba1c$ins==ins])))
    for (g in sort(unique(labs_hba1c$gender)))
    {
      writeLines(sprintf("HbA1c (%16s, %6s, %10s): N = %5d ; mean = %.2f ; median = %.2f", race, g, ins,
	length(labs_hba1c$Result[labs_hba1c$race==race & labs_hba1c$gender==g & labs_hba1c$ins==ins]),
	mean(labs_hba1c$Result[labs_hba1c$race==race & labs_hba1c$gender==g & labs_hba1c$ins==ins]),
	median(labs_hba1c$Result[labs_hba1c$race==race & labs_hba1c$gender==g & labs_hba1c$ins==ins])))
    }
  }
}
#
#Caucasians by age
race <- "Caucasian"
for (i in 2:9)
{
  age_range <- c(i*10, i*10+9)
  for (ins in sort(unique(labs_hba1c$ins)))
  {
    hba1c_this <- labs_hba1c$Result[labs_hba1c$race==race & labs_hba1c$ins==ins & labs_hba1c$age_in_years>=age_range[1] &  labs_hba1c$age_in_years<age_range[2]]
    writeLines(sprintf("HbA1c (%16s, %d-%d, %10s): N = %5d ; mean = %.2f ; median = %.2f", race, i*10, i*10+9, ins, 
                       length(hba1c_this), mean(hba1c_this), median(hba1c_this)))
  }
}
###
#
p2 <- plot_ly(labs_hba1c, y=~Result, x=~race, color=~ins, type="box",
  boxmean=T, colors=cols_this, marker=list(symbol="dot", opacity=0.4)) %>%
  layout(title=sprintf("%s<br>HbA1c values<br>N_total = %d", TITLE_PREFIX, nrow(labs_hba1c)),
  yaxis=list(title="HbA1c", range=c(0,HBA1C_MAX)), xaxis=list(title=""), 
  margin=list(t=100,l=80,b=100,r=80), showlegend=T, legend = list(x=0.7,y=1.0), boxmode="group",
  font=list(family="Arial", size=14))
p2
#
p2.2 <- plot_ly(labs_hba1c, y=~Result, x=~race, color=~gender, type="box",
              boxmean=T, marker=list(symbol="dot", opacity=0.4)) %>%
  layout(title=sprintf("%s<br>HbA1c values<br>N_total = %d", TITLE_PREFIX, nrow(labs_hba1c)),
         yaxis=list(title="HbA1c", range=c(0,HBA1C_MAX)), xaxis=list(title=""), 
         margin=list(t=100,l=80,b=100,r=80), showlegend=T, legend = list(x=0.7,y=1.0), boxmode="group",
         font=list(family="Arial", size=14))
p2.2
#
# Confounders:
#   Did HbA1c increase over time?  Adjust for year by including avg date of labs.
#   Age of patient.
#   Cohort defined "outpatient" based on initial query, but may have inpatient encounters.
###
#ok <- dbDisconnect(dbcon_hf)
#
