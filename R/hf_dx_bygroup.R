#!/usr/bin/env Rscript
#
library(data.table)
library(dplyr)
library(readr)
library(plotly)

#Abbreviate using upper case only.
abr <- function(s) {
  gsub("[^A-Z]","",s)
}

dx <- read_csv("~/projects/hf/data/hf_diag_bygroup.csv", col_types = list(year = col_character()))
dx <- dx[dx$year != "(null)",]
dx$year <- as.integer(dx$year)

genders <- c("Female","Male")
dx <- dx[dx$gender %in% genders,]

races <- c("African American", "Asian", "Caucasian", "Hispanic", "Native American", "Pacific Islander")
dx <- dx[dx$race %in% races,]

writeLines(sprintf("\t%2s - %s", abr(c(genders,races)), c(genders,races)))

#For each gender+race combo subset, rename count cols and merge

dx_merged <- NA

for (gender in genders) {
  for (race in races) {
    dx_this <- dx[dx$gender==gender & dx$race==race,]
    
    colnames(dx_this)[colnames(dx_this)=="dx_count"] <- paste("dx_count", abr(gender), abr(race), sep="_")
    colnames(dx_this)[colnames(dx_this)=="patient_count"] <- paste("patient_count", abr(gender), abr(race), sep="_")
    dx_this$gender <- NULL
    dx_this$race <- NULL
    if (is.na(dx_merged)) {
      dx_merged <- dx_this
    } else {
      dx_merged <- merge(dx_merged, dx_this, by=c("diagnosis_id","year"), all.x=T, all.y=T)
    }
  }
}
dx_merged <- dx_merged[complete.cases(dx_merged),]


dx_merged$patient_count_TOTAL <- 0
dx_merged$dx_count_TOTAL <- 0
for (gender in genders) {
  for (race in races) {
    dx_merged$patient_count_TOTAL <- dx_merged$patient_count_TOTAL + dx_merged[[paste("patient_count", abr(gender), abr(race), sep="_")]]
    dx_merged$dx_count_TOTAL <- dx_merged$dx_count_TOTAL + dx_merged[[paste("dx_count", abr(gender), abr(race), sep="_")]]
  }
}

#stop() #DEBUG

hf_d_dx <- read_csv("~/projects/hf/data/hf_d_diagnosis.csv")

dx_merged <- merge(dx_merged, hf_d_dx, by="diagnosis_id", all.x=T, all.y=F)

#Remove non-diagnostic (CM) codes:
dx_merged <- dx_merged[grepl("^[0-9]",dx_merged$diagnosis_code),]

#Select more common dx (how? Female Caucasians)
dx_merged <- dx_merged[order(-(dx_merged$dx_count_TOTAL)),]

#Need denominators for all gender+race combos...

dx_denominators <- read_csv("~/projects/hf/data/hf_diag_bygroup_denominators.csv")
dx_denominators <- dx_denominators[dx_denominators$gender %in% genders,]
dx_denominators <- dx_denominators[dx_denominators$race %in% races,]
dx_denominators$year <- as.integer(dx_denominators$year)
dx_denominators <- dx_denominators[!is.na(dx_denominators$year),]

#Look at one year
y <- 2013
dx_merged <- dx_merged[dx_merged$year==y,]
dx_denominators <- dx_denominators[dx_denominators$year==y,]

#Focus on cancer/neoplasms
setDT(dx_merged)
dx_merged <- dx_merged[as.integer(substr(dx_merged$diagnosis_code,1,3)) %between% c(140,239),]
dx_merged <- dx_merged[order(as.numeric(dx_merged$diagnosis_code)),]

#Need statistical test.  Binomial test?  vs overall prevalence?

#for (dxid in ordered(unique(dx_merged$diagnosis_id)))
for (i in 1:nrow(dx_merged))
{

  dxid <- dx_merged$diagnosis_id[i]
  #For each dx, compute overall probability/prevalence.
  prob_overall <- dx_merged$patient_count_TOTAL[dx_merged$diagnosis_id==dxid] / sum(dx_denominators$patient_count)
  prv_overall <- 1e5 * prob_overall

  for (race in races) {
    for (gender in genders) {

      n_total_this <- dx_denominators$patient_count[dx_denominators$gender==gender & dx_denominators$race==race]
      #writeLines(sprintf("Total patients [%d, %18s, %6s] = %7d", y, race, gender, n_total_this))

      n_this <- dx_merged[dx_merged$diagnosis_id==dxid,][[paste("patient_count", abr(gender), abr(race), sep="_")]]

      pvalue <- binom.test(
	x=n_this,
	n=n_total_this,
	p=prob_overall,
	alternative="two.sided", conf.level=0.95)$p.value

      if (n_this>100 && pvalue<1e-50)
      {
        prob_this <- n_this / n_total_this
        
      writeLines(sprintf("Prvl [%2s_%1s] (%5d/%7d): %4.0f (%s%4.0f); pval=%8.2g, %-6s:%s",
	abr(race), abr(gender),
	n_this, n_total_this, 1e5*n_this/n_total_this,
	ifelse(prob_this>prob_overall, ">","<"),
	prv_overall,
	pvalue,
	hf_d_dx$diagnosis_code[hf_d_dx$diagnosis_id==dxid],
	hf_d_dx$diagnosis_description[hf_d_dx$diagnosis_id==dxid]))
      }
    }
  }
}


#dx_top <- dx[1:100,]

#Sort/group by ICD.
#dx_top <- dx_top[order(as.numeric(dx_top$diagnosis_code)),]
#rownames(dx_top) <- NULL

