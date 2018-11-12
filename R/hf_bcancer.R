###
hf <- read.delim("data/hf_bcancer-diabetes+treatment.csv", stringsAsFactors=F)

print(sprintf("total input data rows: %d", nrow(hf)))
n_data <- nrow(hf)

hf$cancer_date <- as.Date(hf$cancer_date, "%Y-%m-%d")
hf$diabetes_date <- as.Date(hf$diabetes_date, "%Y-%m-%d")

hf$ai_id[hf$ai_id == "(null)"] <- NA
hf$ai_ndc_code[hf$ai_ndc_code == "(null)"] <- NA
hf$chemo_code[hf$chemo_code == "(null)"] <- NA


t <- table(!is.na(hf$ai_id), !is.na(hf$chemo_code))
rownames(t) <- c("AI_Yes","AI_No")
colnames(t) <- c("Chemo_Yes","Chemo_No")
print(t)

bcancer_codes <- read.csv("data/hf_bcancer_codes.csv", stringsAsFactors=F)

n_total <- 0
for (code in levels(as.factor(hf$cancer_code)))
{
  n <- nrow(hf[hf$cancer_code==code,])
  desc <- bcancer_codes$diagnosis_description[bcancer_codes$diagnosis_code==code]
  print(sprintf("%5s [N = %7d, %4.1f%%] %s", code, n, 100*n/n_data, desc))
  n_total <- n_total + n
}
print(sprintf("DEBUG: n_total = %d",n_total))


ai_ids <- read.csv("data/hf_med_aromataseinhibitors.csv", stringsAsFactors=F)

hf$ai_generic_name <- rep(NA,nrow(hf))
for (id in levels(as.factor(hf$ai_id)))
{
  ai_generic_name <- ai_ids$generic_name[ai_ids$medication_id==id]
  print(sprintf("DEBUG: %s: %s",id,ai_generic_name))
  hf$ai_generic_name[hf$ai_id==id] <- ai_generic_name
}
n_total <- 0
for (gname in levels(as.factor(hf$ai_generic_name)))
{
  n <- nrow(hf[hf$ai_generic_name==gname,])
  if (n>0)
    print(sprintf("[N = %6d, %4.1f%%] %s", n, 100*n/n_data, gname))
  n_total <- n_total + n
}
print(sprintf("DEBUG: n_total = %d",n_total))