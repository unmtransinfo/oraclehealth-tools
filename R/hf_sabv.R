library(data.table)
library(dplyr)
library(readr)
library(plotly)


dx <- read_csv("~/projects/hf/data/hf_diag_bygender.csv", col_types = list(year = col_character()))
dx <- dx[dx$year != "(null)",]
dx$year <- as.integer(dx$year)

dx <- dx[dx$gender %in% c("Female","Male"),]

dx_f <- dx[dx$gender=="Female",]
dx_m <- dx[dx$gender=="Male",]

colnames(dx_f)[colnames(dx_f)=="dx_count"] <- "dx_count_f"
colnames(dx_m)[colnames(dx_m)=="dx_count"] <- "dx_count_m"
colnames(dx_f)[colnames(dx_f)=="patient_count"] <- "patient_count_f"
colnames(dx_m)[colnames(dx_m)=="patient_count"] <- "patient_count_m"

dx_f$gender <- NULL
dx_m$gender <- NULL

dx <- merge(dx_f, dx_m, by=c("diagnosis_id","year"), all.x=F, all.y=F)

hf_d_dx <- read_csv("~/projects/hf/data/hf_d_diagnosis.csv")

dx <- merge(dx, hf_d_dx, by="diagnosis_id", all.x=T, all.y=F)

dx_denominators <- read_csv("~/projects/hf/data/hf_diag_bygender_denominators.csv")
dx_denominators <- dx_denominators[dx_denominators$gender %in% c("Female","Male"),]
dx_denominators <- dx_denominators[!is.na(dx_denominators$year),]



#Remove non-diagnostic (CM) codes:
dx <- dx[grepl("^[0-9]",dx$diagnosis_code),]

#Look at one year
y <- 2013
dx <- dx[dx$year==y,]
dx <- dx[order(-(dx$dx_count_f+dx$dx_count_m)),]

n_f_total <- dx_denominators$patient_count[dx_denominators$year==y & dx_denominators$gender=="Female"]
n_m_total <- dx_denominators$patient_count[dx_denominators$year==y & dx_denominators$gender=="Male"]

writeLines(sprintf("Total patients in year %d: N_Female = %d ; N_Male = %d", y, n_f_total, n_m_total))

dx_top <- dx[1:100,]

#Sort/group by ICD.
dx_top <- dx_top[order(as.numeric(dx_top$diagnosis_code)),]
rownames(dx_top) <- NULL

dx_top$prv_ratio <- (dx_top$patient_count_f/n_f_total)/(dx_top$patient_count_m/n_m_total)
dx_top <- dx_top[dx_top$prv_ratio<10 & dx_top$prv_ratio>.1,] #Filter sex-specific conditions

# METRIC SHOULD BE SYMMETRIC:
# "PREDOMINANCE" = (1 - m/f) if f>m, (1 - f/m) if m>f. 
dx_top$prv_pdom <- NA
dx_top$prv_pdom[dx_top$prv_ratio>1] <- -1/dx_top$prv_ratio[dx_top$prv_ratio>1] + 1
dx_top$prv_pdom[dx_top$prv_ratio<1] <- dx_top$prv_ratio[dx_top$prv_ratio<1] - 1
dx_top$prv_pdom[dx_top$prv_ratio==1] <- 0


dx_top$prv_f <- 1e5 * dx_top$patient_count_f / n_f_total
dx_top$prv_m <- 1e5 * dx_top$patient_count_m / n_m_total
dx_top$prv <- (dx_top$prv_f + dx_top$prv_m ) / 2

# Binomial Test: If null hypothesis sex equality, meaningful p-value may be computed,
# where 50% is expected probability, and N is F+M diagnosed.
#
dx_top$pvalue <- NA
for (i in 1:nrow(dx_top))
{
  dx_top$pvalue[i] <- binom.test(
	x=dx_top$patient_count_f[i],
	n=dx_top$patient_count_f[i]+dx_top$patient_count_m[i],
	p=0.5,
	alternative="two.sided", conf.level=0.95)$p.value
}

#Top 50 Dx.  Prevalence normalized per 100k.
for (i in 1:nrow(dx_top))
{
  #Prevalence ratio = prv_f:prv_m
  writeLines(sprintf("%d. Patients = %6d ; Prevalence F:M = %4.0f/%4.0f = %5.1f%% ; pval = %.1g ; [%7s] %s", i,
  dx_top$patient_count_f[i]+dx_top$patient_count_m[i],
  dx_top$prv_f[i], dx_top$prv_m[i],
	100.0*dx_top$prv_ratio[i],
	dx_top$pvalue[i],
	dx_top$diagnosis_code[i], dx_top$diagnosis_description[i]))
}

#
dx_top$color <- ifelse(dx_top$prv_pdom>0, "#FF9999", "#9999FF")
#
p1 <- plot_ly() %>%
  add_bars(data=dx_top, x=1:nrow(dx_top), y=~prv_pdom, 
           marker = list(color=~color), 
           text=sprintf("ICD9_CM: %s\npatients = %d\npvalue = %.2g", dx_top$diagnosis_code, dx_top$patient_count_f+dx_top$patient_count_m, dx_top$pvalue)) %>%
  layout(title=paste0("Prevalence predominance (F:red ~ M:blue) by condition", sprintf("<br>Cerner Healthfacts, %d",y)),
         margin=list(t=100,r=80,b=140),showlegend=F,
         xaxis=list(title="", tickmode="array", tickvals=1:nrow(dx_top), ticktext=dx_top$diagnosis_description, tickangle=45),
         yaxis=list(title="", range=c(-1,1)),
         font=list(family="Arial",size=9),titlefont=list(size=22)) %>%
  add_annotations(text=sprintf("N_total = %d",n_f_total+n_m_total), x=.5, y=.8, align="center", xref="paper", yref="paper", font=list(family="Arial", size=14), showarrow=F) %>%
  add_annotations(text="prevalence_predominance = (1-M/F) if F>M, (F/M-1) if M>F", x=.5, y=.1, align="center", xref="paper", yref="paper", font=list(family="Arial", size=14), showarrow=F)
p1
#
