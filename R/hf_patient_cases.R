hf <- read.csv("data/hf_patients_diag_rand1k.csv", stringsAsFactors=F)

print(sprintf("total input data rows: %d", nrow(hf)))

hf$Ftype[hf$Ftype==""] <- NA

hf$Date <- as.Date(hf$Date, "%Y-%m-%d")

hf$SK <- as.factor(hf$SK)
hf$Ftype <- as.factor(hf$Ftype)

n_sk <- length(levels(hf$SK))
n_pid <- length(levels(as.factor(hf$PID)))

print(sprintf("SK count: %d", n_sk))
print(sprintf("PID count: %d", n_pid))

skdata <- data.frame(SK = levels(hf$SK))

skdata$pidcount = rep(0,nrow(skdata))

for (i in 1:nrow(skdata))
{
  skdata$pidcount[i] <- length(levels(as.factor(hf$PID[hf$SK == skdata$SK[i]])))
}

n_unique_pid <- nrow(skdata[skdata$pidcount == 1,])

print(sprintf("SKs with single PID: %d (%.1f%%)", n_unique_pid, 100.0*n_unique_pid/n_sk))

print(sprintf("Non-unique PIDs: %d (%.1f%%)",n_pid-n_unique_pid, 100.0*(n_pid-n_unique_pid)/n_pid ))

skdata$diagcount = rep(0,nrow(skdata))
for (i in 1:nrow(skdata))
{
  skdata$diagcount[i] <- nrow(hf[hf$SK == skdata$SK[i] & hf$Ftype == "D",])
  
}
print(sprintf("Total diagnosis count: %d",sum(skdata$diagcount)))
print(sprintf("Mean diagnosis count: %.1f", mean(skdata$diagcount)))


###Link hospital data:
hospitals <- read.csv("data/hf_hospital_codes.csv")
hf$census_region <- rep(NA,nrow(hf))
for (id in levels(as.factor(hf$HID)))
{
  hosp_cr <- hospitals$census_region[hospitals$hospital_id==as.integer(id)]
  hf$census_region[hf$HID==id] <- as.character(hosp_cr)
}
print(table(as.factor(hf$census_region)))
n_total <- 0
for (cr in levels(as.factor(hf$census_region)))
{
  n <- nrow(hf[hf$census_region==cr ,])
  if (n>0)
    print(sprintf("[N = %6d, %4.1f%%] %s", n, 100*n/nrow(hf), cr))
  n_total <- n_total + n
}
print(sprintf("DEBUG: n_total = %d",n_total))
