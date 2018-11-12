####
#LOS vs Dx
hf <- read.csv("data/hf_gi_los.csv", stringsAsFactors=F)

hf$los_days <- as.integer(hf$los_days)

ndc <- length(unique(hf$diagnosis_code))
print(sprintf("diagnosis count: %s", ndc))

for (dd in unique(hf$diagnosis_description)[order(unique(hf$diagnosis_code))])
{
  n <- length(hf$patient_id[hf$diagnosis_description == dd])
  dc <- unique(hf$diagnosis_code[hf$diagnosis_description == dd])
  losm <- mean(hf$los_days[hf$diagnosis_description == dd], na.rm=T)
  print(sprintf("N:%8d LOS:%5.1fdays (%-6s: %s)", n, losm, dc, dd))
}


####
hf <- read.csv("data/hf_gi_med_los.csv", stringsAsFactors=F)

hf$los_days <- as.integer(hf$los_days)

ndc <- length(unique(hf$diagnosis_code))
print(sprintf("diagnosis count: %s", ndc))

for (dd in unique(hf$diagnosis_description)[order(unique(hf$diagnosis_code))])
{
  n <- length(hf$patient_id[hf$diagnosis_description == dd])
  dc <- unique(hf$diagnosis_code[hf$diagnosis_description == dd])
  losm <- mean(hf$los_days[hf$diagnosis_description == dd], na.rm=T)
  print(sprintf("N:%8d LOS:%5.1fdays (%-6s: %s)", n, losm, dc, dd))
}

#t <- table(hf$drug_desc)
t <- table(hf$generic_name)

drug_use <- data.frame(drug=rownames(t), n=rep(NA,length(rownames(t))))
                       
for (ddesc in rownames(t))
{
  n <- t[ddesc]
  drug_use$n[drug_use$drug == ddesc] <- n
}

drug_use <- drug_use[order(-drug_use$n),]

#Top drugs for this cohort:
for (i in 1:nrow(drug_use))
{
  if (grepl("[^c]cin",drug_use$drug[i],ignore.case=T))
  {  
    print(sprintf("%d. N: %8d %s", i, drug_use$n[i], drug_use$drug[i]))
  }
}
