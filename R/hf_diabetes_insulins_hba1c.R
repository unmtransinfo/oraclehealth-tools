library(readr)
library(vioplot)
library(plotly)
library(dplyr)

mid_insulin_eng <- c(43829, 43830, 43831, 113373, 113374, 115543, 115544, 115940, 116103, 116104, 133781, 133782, 312759, 312761, 2485283, 3533894, 3533895, 3636863, 3636869, 4452574, 5236308, 5819190, 5819191, 5940412, 6922916, 7793987, 8060730, 8064453)

mid_insulin_hum <- c(45058, 45059, 45060, 45061, 45062, 45064, 45065, 45066, 45067, 45068, 45070, 45071, 45072, 45073, 45074, 45075, 45077, 45078, 45079, 45080, 45081, 45082, 45951, 45955, 45957, 133778, 133779, 133780, 2725570, 4422919, 8060737, 8063991, 8065846, 8082851, 8083001)

mid_insulin_pork <- c(22427, 45056, 45083, 45157, 45956, 51774)

#Sanity cutoffs:
HBA1C_MAX <- 20
HBA1C_MIN <- 3


###

insulin_byyear <- read_csv("data/hf_insulin_byyear.csv", col_types = cols(year = col_integer(), medication_id = col_integer(), ndc_code = col_character()))
#
insulin_byyear$ins <- NA
insulin_byyear$ins[insulin_byyear$medication_id %in% mid_insulin_eng] <- "ENGINEERED"
insulin_byyear$ins[insulin_byyear$medication_id %in% mid_insulin_hum] <- "HUMAN"
#
insulin_codes <- unique(insulin_byyear[,c("medication_id","brand_name","generic_name","ins")])
#
#
###
#Diabetes diagnoses: counts vs year, grouped by diagnosis-groups.
diabetes_byyear <- read_csv("data/hf_diabetes_byyear.csv", col_types = cols(year = col_integer(), diagnosis_code = col_character()))

diabetes_byyear <- diabetes_byyear[grepl("^250", diabetes_byyear$diagnosis_code),]
#
diabetes_codes <- unique(diabetes_byyear[,c("diagnosis_type","diagnosis_code","diagnosis_description")])
diabetes_codes <- diabetes_codes[order(diabetes_codes$diagnosis_code),]
#
###
#HbA1c labs: counts vs year, grouped by ...
hba1c_byyear <- read_csv("data/hf_lab_hba1c_byyear.csv", col_types = cols(year = col_integer()))
lab_codes <- unique(hba1c_byyear[,c("lab_procedure_id","lab_procedure_name")])
#
### Result indicator codes:
result_codes <- read_csv("data/hf_d_result_indicator.csv")
#
#
###
print("*** Diabetes+insulin+HbA1c (1% SAMPLE, 2010 ONLY):\n")
#
hf <- read_csv("data/hf_diabetes+meds+labs.csv",  col_types = cols(diagnosis_code = col_character(),  dx_date = col_date(format = "%Y-%m-%d %H:%M:%S"),  lab_date = col_date(format = "%Y-%m-%d %H:%M:%S"),  numeric_result = col_double()))

print(sprintf("total input data rows: %d", nrow(hf)))

hf <- hf[hf$numeric_result>=HBA1C_MIN & hf$numeric_result<=HBA1C_MAX,] 

hf <- merge(hf, diabetes_codes, by="diagnosis_code", all.x=T, all.y=F)
hf <- merge(hf, insulin_codes, by="medication_id", all.x=T, all.y=F)
hf <- merge(hf, lab_codes, by="lab_procedure_id", all.x=T, all.y=F)


print(sprintf("total working data rows: %d", nrow(hf)))

hf$days_d2m <- as.integer(difftime(hf$med_date, hf$dx_date, units = "days"))
hf$days_m2l <- as.integer(difftime(hf$lab_date, hf$med_date, units = "days"))

print(sprintf("mean days (dx->rx): %4.1f", mean(hf$days_d2m,na.rm=T)))
print(sprintf("mean days (rx->lab): %4.1f", mean(hf$days_m2l,na.rm=T)))

hf <- merge(hf, result_codes, by="result_indicator_id", all.x=T, all.y=F)

### Remove "Unknown/Invalid" results:
hf <- hf[hf$result_indicator_desc!="Unknown/Invalid",]

print(sprintf("total working data rows: %d", nrow(hf)))

#
###
hgbval_all <- hf$numeric_result
hgbval_eng <- hgbval_all[hf$ins=="ENGINEERED"]
hgbval_hum <- hgbval_all[hf$ins=="HUMAN"]
print(sprintf("ENGINEERED: mean Hgb A1C: %.2f ; variance: %.2f", mean(hgbval_eng,na.rm=T), var(hgbval_eng,na.rm=T)))
print(sprintf("HUMAN: mean Hgb A1C: %.2f ; variance: %.2f", mean(hgbval_hum,na.rm=T), var(hgbval_hum,na.rm=T)))
print(sprintf("ALL: mean Hgb A1C: %.2f ; variance: %.2f", mean(hgbval_all,na.rm=T), var(hgbval_all,na.rm=T)))

for (v in HBA1C_MIN:(HBA1C_MAX-1))
{
  print(sprintf("HgbA1C = %2d-%2d: eng=%5d   hum=%5d", v, v+1, length(which(as.integer(hgbval_eng)==v)), length(which(as.integer(hgbval_hum)==v))))
}
###
#plot
#
p6 <- plot_ly(hf, x = ~numeric_result, color = ~ins, 
            type = 'histogram', colors = cols_this) %>%
  layout(title = "HbA1c histograms",
         xaxis = list(title = "", range=c(0,HBA1C_MAX)),
         yaxis = list (title = "N"),
         margin = list(t = 100, l = 60, r = 60), 
         font = list(family = "Arial", size = 14),
         showlegend = T, legend = list(x=0.7,y=1.0))
p6
#
tt <- t.test(hgbval_eng, hgbval_hum, var.equal=F)
print(sprintf("Welch's 2-sample T-test p-value = %g", tt$p.value))

#boxplot box includes 2nd and 3rd quantile.  Thus 50% of data in box.
#range=1.5 means 97% of data within whiskers.
boxplot(hgbval_eng, hgbval_hum, ylim=c(0,25),
        names=c("engineered","human"), col="tomato",
        range=1.5, varwidth=T, boxwex=0.5)
title(main="Hgb A1C vs. Insulin class")
abline(h=mean(hgbval_eng), col="gray", lwd=2)
abline(h=mean(hgbval_hum), col="gray", lwd=2)
text(1,mean(hgbval_eng),sprintf("mean = %.2f",mean(hgbval_eng)), pos=3, cex=0.8)
text(2,mean(hgbval_hum),sprintf("mean = %.2f",mean(hgbval_hum)), pos=1, cex=0.8)

###
vioplot(hgbval_eng, hgbval_hum, ylim=c(0,25),
        names=c("engineered","human"), col="tomato",
        range=1.5, wex=0.5)
title(main="Hgb A1C vs. Insulin class")
text(1,mean(hgbval_eng),sprintf("mean = %.2f\nvar = %.2f",mean(hgbval_eng), var(hgbval_eng)), pos=4, cex=0.8)
text(2,mean(hgbval_hum),sprintf("mean = %.2f\nvar = %.2f",mean(hgbval_hum), var(hgbval_hum)), pos=4, cex=0.8)

