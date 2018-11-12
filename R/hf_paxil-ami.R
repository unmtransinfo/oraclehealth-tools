###
hf <- read.csv("data/hf_paxil-ami.csv", stringsAsFactors=F)

print(sprintf("total input data rows: %d", nrow(hf)))
n_data <- nrow(hf)

hf$med_date <- as.Date(hf$med_date, "%Y-%m-%d")

hf$ami_date[hf$ami_date == "(null)"] <- NA
hf$ami_date <- as.Date(hf$ami_date, "%Y-%m-%d")
hf$ami_code[hf$ami_code == "(null)"] <- NA

#hf$dischg_disp_id[hf$dischg_disp_id == "(null)"] <- NA
#hf$exp_date[hf$exp_date == "(null)"] <- NA

ami_codes <- read.csv("data/hf_ami_codes.csv", stringsAsFactors=F)

n_total <- 0
for (code in levels(as.factor(hf$ami_code)))
{
  n <- nrow(hf[!is.na(hf$ami_code) & hf$ami_code==code,])
  desc <- ami_codes$diagnosis_description[ami_codes$diagnosis_code==code]
  print(sprintf("%5s [N = %7d, %4.1f%%] %s", code, n, 100*n/n_data, desc))
  n_total <- n_total + n
}
n_total <- n_total + nrow(hf[is.na(hf$ami_code),])
print(sprintf("DEBUG: n_total = %d",n_total))

for (i in 0:9)
{
  n_this <- nrow(hf[hf$age_in_years %in% range(i*10, (i+1)*10),])
  n_ami_this <- nrow(hf[hf$age_in_years %in% range(i*10, (i+1)*10) & !is.na(hf$ami_code),])
  print(sprintf("[%d-%d] Paxil prescribed patients with AMI diagnosis: %2d/%2d (%.2f%%)", i*10, (i+1)*10, n_ami_this, n_this, 100*n_ami_this/n_this))
}

n_ami <- nrow(hf[!is.na(hf$ami_code),])
print(sprintf("[TOTAL] Paxil prescribed patients with AMI diagnosis: %2d/%2d (%.2f%%)", n_ami, n_total, 100*n_ami/n_total))

###
hf <- read.csv("data/hf_diag_top.csv", stringsAsFactors=F)
hf <- hf[grepl('^410\\.', hf$diagnosis_code),]
n_ami_all <- sum(hf$patient_count)

counts <- read.delim("data/hf_counts.csv", stringsAsFactors=F)

print(sprintf("global AMI prevalence: %2d/%2d (%.2f%%)", n_ami_all, counts$patients, 100*n_ami_all/counts$patients))

