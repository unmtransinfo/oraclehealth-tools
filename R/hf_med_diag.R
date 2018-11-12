library(RPostgreSQL, quietly = T)
library(data.table, quietly = T)
library(plotly, quietly = T)
library(dplyr, quietly = T)

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
##md = "medication-diagnosis combo data"
#md <- read.csv("~/projects/hf/data/hf_med-diag.csv_3", stringsAsFactors=F, header=F)
md <- fread("data/hf_med-diag.csv_7", header=F, stringsAsFactors=F)
colnames(md) <- c("patient_id","medication_id","med_date","diagnosis_id","diag_date","interval_days")



mids <- unique(md$medication_id)
dids <- unique(md$diagnosis_id)
nmed <- length(mids)
ndiag <- length(dids)
print(sprintf("Unique meds: %d", nmed))
print(sprintf("Unique diagnoses: %d", ndiag))

mdc <- md[ , .(combo_count = length(patient_id)), by = .(medication_id,diagnosis_id) ]

print(sprintf("Unique meds: %d", length(unique(mdc$medication_id))))
print(sprintf("Unique diagnoses: %d", length(unique(mdc$diagnosis_id))))
print(sprintf("n_link_total = %d", sum(mdc$combo_count)))
print(sprintf("total combos: %d", nrow(mdc)))


###
sql <- "SELECT diagnosis_id,diagnosis_type,diagnosis_code,diagnosis_description FROM hf_d_diagnosis"
results <- dbSendQuery(con_hf,sql)
dcodes <- dbFetch(results, colClasses="character")
dcodes$diagnosis_code <- as.character(dcodes$diagnosis_code)
dbClearResult(results)
print(sprintf("n_diag_codes = %d\n",nrow(dcodes)))

mdc <- merge(mdc, dcodes, all.x=T, all.y=F, by.x="diagnosis_id", by.y="diagnosis_id")

dcodes_present <- unique(mdc$diagnosis_code) #codes present


###
sql <- "SELECT medication_id,ndc_code,generic_name FROM hf_d_medication"
results <- dbSendQuery(con_hf,sql)
mcodes <- dbFetch(results, colClasses="character")
mcodes$ndc_code <- as.character(mcodes$ndc_code)
dbClearResult(results)
#
dbDisconnect(con_hf)

print(sprintf("n_med_codes = %d\n",nrow(mcodes)))
mdc <- merge(mdc, mcodes, all.x=T, all.y=F, by.x="medication_id", by.y="medication_id")
print(sprintf("unique meds: %d\n",length(unique(mdc$medication_id))))


#Hack: remove uninteresting meds
drugs_skip <- c("LVP solution", "sodium chloride")
mid_skip <- mcodes$medication_id[mcodes$generic_name %in% drugs_skip]


mdc <- subset(mdc, !(medication_id %in% mid_skip))

## Frequency matrix of meds vs. diagnoses
#fmat <- matrix(rep(0,nmed*ndiag), nrow=nmed, ncol=ndiag, dimnames = list(mids,dids))
#for (i in 1:nrow(md))
#{
#  mid <- as.character(md$medication_id[i])
#  did <- as.character(md$diagnosis_id[i])
#  fmat[mid,did] <- fmat[mid,did] + 1
#}
#
#print(sprintf("n_link_total = %d", sum(fmat)))
#print(sprintf("total combos: %d", length(which(fmat>0))))

for (i in c(1,10,100,1000))
{
  n <- nrow(mdc[ combo_count > i])
  print(sprintf("md combos (c>%d): %d", i, n))
  if (n==0)
  {
    break
  }
}
print(sprintf("total md combos: %d", nrow(mdc)))



int_days <- md$interval_days
tbl <- table(int_days)
for (d in names(tbl))
{
  print(sprintf("int_days: %3s: %7d\n",d,tbl[d]))
}
barplot(table(int_days), main="interval_days", xlab="days", col="turquoise")

years <- as.integer(substr(md$med_date, 1, 4))
tbl <- table(years)
for (y in names(tbl))
{
  print(sprintf("year: %s: %7d\n",y,tbl[y]))
}
#barplot(table(years), main="year", xlab="year", col="orange")


#Common combos:
mdc <- mdc[ order(-combo_count,medication_id,diagnosis_id)]
for (i in 1:100)
{
  mid <- mdc$medication_id[i]
  did <- mdc$diagnosis_id[i]
  d_code <- dcodes$diagnosis_code[dcodes$diagnosis_id == as.integer(did)]
  d_desc <- dcodes$diagnosis_description[dcodes$diagnosis_id == as.integer(did)]
  m_code <- mcodes$ndc_code[mcodes$medication_id == as.integer(mid)]
  m_name <- mcodes$generic_name[mcodes$medication_id == as.integer(mid)]
  print(sprintf("%d.  mid='%s', did='%s'; med_ndc = %s ; med_name = %s; diag_code = %s ; diag_desc = %s ; count = %d",
	i, mid, did, m_code, m_name, d_code, d_desc, mdc$combo_count[i]))
}
write.csv(mdc[1:1000,], file="data/mdc_common.csv")

print(sprintf("elapsed time (total): %.2fs",(proc.time()-t0)[3]))

## We want a heatmap where both meds and diags are clustered hierarchically.

## Create a bipartite network med-diag, weighted by frequency.
n_min <- 10
mdnet <- subset(md, select = c("medication_id", "diagnosis_id"))
mdnet <- mdnet %>% group_by(medication_id, diagnosis_id) %>% summarise(n = n())
mdnet <- mdnet[mdnet$n >= n_min, ] #filter rare combos
print(sprintf("med-diag combos where n>=%d: %d\n", n_min, nrow(mdnet)))
write.table(mdnet, file = "data/mdnet.tsv", sep = "\t", row.names = F)

mdnet_meds <- merge(mdnet, mcodes, by = "medication_id", all.x = T, all.y = F)
mdnet_meds$diagnosis_id <- NULL
mdnet_meds$n <- NULL
mdnet_meds <- unique(mdnet_meds)
write.table(mdnet_meds, file = "data/mdnet_meds.tsv", sep = "\t", row.names = F)

mdnet_diags <- merge(mdnet, dcodes, by = "diagnosis_id", all.x = T, all.y = F)
mdnet_diags$medication_id <- NULL
mdnet_diags$n <- NULL
mdnet_diags <- unique(mdnet_diags)
write.table(mdnet_diags, file = "data/mdnet_diags.tsv", sep = "\t", row.names = F)

#Annotated for Cytoscape
mdnet_ann <- merge(mdnet, mcodes, by = "medication_id", all.x = T, all.y = F)
mdnet_ann <- merge(mdnet_ann, dcodes, by = "diagnosis_id", all.x = T, all.y = F)
write.table(mdnet_ann, file = "data/mdnet_ann.tsv", sep = "\t", row.names = F)

