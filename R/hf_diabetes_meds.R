library(vioplot)

hf <- read.delim("data/hf_diabetes+labs+meds.csv", stringsAsFactors=F)
print(sprintf("total input data rows: %d", nrow(hf)))

hf$lab_date <- as.Date(hf$lab_date, "%Y-%m-%d")
hf$med_date <- as.Date(hf$med_date, "%Y-%m-%d")

hf <- hf[hf$lab_date >= hf$med_date,]
#hf <- hf[hf$numeric_result>3,]
print(sprintf("total working data rows: %d", nrow(hf)))

n_data <- nrow(hf)

hf$days_m2l <- as.integer(hf$days_m2l)

diabetes_codes <- read.delim("data/hf_diabetes_codes.csv", colClasses="character")
diabetes_codes <- diabetes_codes[order(diabetes_codes$diagnosis_code),]


ndc <- length(levels(as.factor(hf$diagnosis_code)))
print(sprintf("diabetes codes: %d ; diabetes diagnoses in dataset: %s", nrow(diabetes_codes), ndc))

n_total <- 0
for (code in levels(as.factor(hf$diagnosis_code)))
{
  n <- nrow(hf[hf$diagnosis_code==code,])
  desc <- diabetes_codes$diagnosis_description[diabetes_codes$diagnosis_code==code]
  print(sprintf("%5s [N = %7d, %4.1f%%] %s", code, n, 100*n/n_data, desc))
  n_total <- n_total + n
}
print(sprintf("DEBUG: n_total = %d",n_total))

print(sprintf("mean days (med->lab): %4.1f", mean(as.integer(hf$lab_date-hf$med_date),na.rm=T)))

lab_codes <- read.delim("data/hf_labs_hgb-a1c_codes.csv", colClasses="character")

hf$lab_mn <- rep(NA,nrow(hf))
for (id in levels(as.factor(hf$lab_procedure_id)))
{
  lab_mn <- lab_codes[lab_codes$lab_procedure_id==id,]$lab_procedure_mnemonic
  print(sprintf("DEBUG: %s: %s",id,lab_mn))
  hf$lab_mn[hf$lab_procedure_id==id] <- lab_mn
}
n_total <- 0
for (lab_mn in levels(as.factor(hf$lab_mn)))
{
  n <- nrow(hf[hf$lab_mn==lab_mn ,])
  if (n>0)
    print(sprintf("[N = %6d, %4.1f%%] %s", n, 100*n/n_data, lab_mn))
  n_total <- n_total + n
}
print(sprintf("DEBUG: n_total = %d",n_total))


meds <- read.delim("data/hf_meds_insulins.csv", colClasses="character")
hf$generic_name <- rep(NA,nrow(hf))
hf$route <- rep(NA,nrow(hf))
for (id in levels(as.factor(hf$medication_id)))
{
  med_gname <- meds$generic_name[meds$medication_id==id]
  route <- meds$route_description[meds$medication_id==id]
  hf$generic_name[hf$medication_id==id] <- med_gname
  hf$route[hf$medication_id==id] <- route
}

hf$route <- as.factor(hf$route)
print(table(hf$route))

## Group insulin into engineered vs natural:
hf$med_class <- as.character(rep(NA,nrow(hf)))
hf$med_class[grepl("aspart",hf$generic_name, ignore.case=T)] <- "engineered"
hf$med_class[grepl("lispro",hf$generic_name, ignore.case=T)] <- "engineered"
hf$med_class[grepl("glargine",hf$generic_name, ignore.case=T)] <- "engineered"
hf$med_class[is.na(hf$med_class)] <- "natural"


#print(table(hf$med_class, hf$generic_name))

tbl <- table(hf$med_class, hf$generic_name)
n_total <- 0
for (rn in rownames(tbl))
{
  for (cn in colnames(tbl))
  {
    n <- tbl[rn,cn]
    if (n>0)
      print(sprintf("[N = %6d, %4.1f%%] %s: %s", n, 100*n/n_data, rn, cn))
    n_total <- n_total + n
  }
}
print(sprintf("DEBUG: n_total = %d",n_total))

hf$med_class <- as.factor(hf$med_class)
print(table(hf$med_class))
print(table(hf$med_class, hf$route))


hf$numeric_result <- as.numeric(hf$numeric_result)

hgbval_all <- hf$numeric_result
hgbval_eng <- hgbval_all[hf$med_class=="engineered"]
hgbval_nat <- hgbval_all[hf$med_class=="natural"]
print(sprintf("mean Hgb A1C: %.2f ; variance: %.2f", mean(hgbval_all,na.rm=T), var(hgbval_all,na.rm=T)))
print(sprintf("mean Hgb A1C (engineered insulin): %.2f ; variance: %.2f", mean(hgbval_eng,na.rm=T), var(hgbval_eng,na.rm=T)))
print(sprintf("mean Hgb A1C (natural insulin): %.2f ; variance: %.2f", mean(hgbval_nat,na.rm=T), var(hgbval_nat,na.rm=T)))

for (v in 0:25)
{
  print(sprintf("HgbA1C = %2d-%2d: e=%5d   n=%5d", v, v+1, length(which(as.integer(hgbval_eng)==v)), length(which(as.integer(hgbval_nat)==v))))
}

tt <- t.test(hgbval_eng[!is.na(hgbval_eng)], hgbval_nat[!is.na(hgbval_nat)], var.equal=F)
print(sprintf("Welch's 2-sample T-test p-value = %g", tt$p.value))

#boxplot box includes 2nd and 3rd quantile.  Thus 50% of data in box.
#range=1.5 means 97% of data within whiskers.
boxplot(hgbval_eng[!is.na(hgbval_eng)],
        hgbval_nat[!is.na(hgbval_nat)],
        ylim=c(0,25),
        names=c("engineered","natural"),
        col="tomato",
        range=1.5,
        varwidth=T,
        boxwex=0.5)
title(main="Hgb A1C vs. Insulin class")
abline(h=mean(hgbval_eng,na.rm=T), col="gray", lwd=2)
abline(h=mean(hgbval_nat,na.rm=T), col="gray", lwd=2)
text(1,mean(hgbval_eng,na.rm=T),sprintf("mean = %.2f",mean(hgbval_eng,na.rm=T)), pos=3, cex=0.8)
text(2,mean(hgbval_nat,na.rm=T),sprintf("mean = %.2f",mean(hgbval_nat,na.rm=T)), pos=1, cex=0.8)

###
vioplot(hgbval_eng[!is.na(hgbval_eng)],
        hgbval_nat[!is.na(hgbval_nat)],
        ylim=c(0,25),
        names=c("engineered","natural"),
        col="tomato",
        range=1.5,
        wex=0.5
        )
title(main="Hgb A1C vs. Insulin class")
text(1,mean(hgbval_eng,na.rm=T),sprintf("mean = %.2f\nvar = %.2f",mean(hgbval_eng,na.rm=T), var(hgbval_eng,na.rm=T)), pos=4, cex=0.8)
text(2,mean(hgbval_nat,na.rm=T),sprintf("mean = %.2f\nvar = %.2f",mean(hgbval_nat,na.rm=T), var(hgbval_nat,na.rm=T)), pos=4, cex=0.8)

