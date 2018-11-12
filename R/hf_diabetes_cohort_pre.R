library(readr)
library(plotly)
library(dplyr)

MID_INSULIN_ENG <- c(43829, 43830, 43831, 113373, 113374, 115543, 115544, 115940, 116103, 116104, 133781, 133782, 312759, 312761, 2485283, 3533894, 3533895, 3636863, 3636869, 4452574, 5236308, 5819190, 5819191, 5940412, 6922916, 7793987, 8060730, 8064453)

MID_INSULIN_HUM <- c(45058, 45059, 45060, 45061, 45062, 45064, 45065, 45066, 45067, 45068, 45070, 45071, 45072, 45073, 45074, 45075, 45077, 45078, 45079, 45080, 45081, 45082, 45951, 45955, 45957, 133778, 133779, 133780, 2725570, 4422919, 8060737, 8063991, 8065846, 8082851, 8083001)

MID_INSULIN_PORK <- c(22427, 45056, 45083, 45157, 45956, 51774)

#Sanity cutoffs:
HBA1C_MAX <- 20
HBA1C_MIN <- 3


###
#Insulin: counts vs year, grouped by (1) engineered/human, (2) generic_name.
#Merge rows, sum counts.
insulin_byyear <- read_csv("data/hf_insulin_byyear.csv", col_types = cols(year = col_integer(), medication_id = col_integer(), ndc_code = col_character()))
#
insulin_byyear$ins <- NA
insulin_byyear$ins[insulin_byyear$medication_id %in% MID_INSULIN_ENG] <- "ENGINEERED"
insulin_byyear$ins[insulin_byyear$medication_id %in% MID_INSULIN_HUM] <- "HUMAN"
#
insulin_codes <- unique(insulin_byyear[,c("medication_id","brand_name","generic_name","ins")])
#
insulin_byyear <- insulin_byyear[!(insulin_byyear$medication_id %in% MID_INSULIN_PORK),] 
#
ins_eng <- insulin_byyear[!is.na(insulin_byyear$year),c("encounter_count","patient_count","ins","year")]
ins_eng_e <- aggregate(x = ins_eng$encounter_count, by = list(ins_eng$ins, ins_eng$year), FUN = sum)
colnames(ins_eng_e) <- c("ins","year","encounter_count")
ins_eng_p <- aggregate(x = ins_eng$patient_count, by = list(ins_eng$ins, ins_eng$year), FUN = sum)
colnames(ins_eng_p) <- c("ins","year","patient_count")
ins_eng <- merge(ins_eng_e, ins_eng_p, by = c("ins","year"))
ins_eng <- ins_eng[order(ins_eng$year),]
#
write.csv(ins_eng, file = "data/insulin_eng_byyear.csv", row.names = F)
#
ins_gname <- insulin_byyear[!is.na(insulin_byyear$year),c("encounter_count","patient_count","generic_name","year")]
ins_gname_e <- aggregate(x = ins_gname$encounter_count, by = list(ins_gname$generic_name, ins_gname$year), FUN = sum)
colnames(ins_gname_e) <- c("generic_name","year","encounter_count")
ins_gname_p <- aggregate(x = ins_gname$patient_count, by = list(ins_gname$generic_name, ins_gname$year), FUN = sum)
colnames(ins_gname_p) <- c("generic_name","year","patient_count")
ins_gname <- merge(ins_gname_e, ins_gname_p, by = c("generic_name","year"))
ins_gname <- ins_gname[order(ins_gname$generic_name,ins_gname$year),]
#
write.csv(ins_gname, file = "data/insulin_generic-name_byyear.csv", row.names = F)
###
cols_this <- c("green","red")
p1 <- plot_ly() %>%
  add_trace(name="encounters", data = ins_eng, x = ~year, y = ~encounter_count, color = ~ins, colors = cols_this,
            type = 'scatter', mode = 'lines', line = list(width = 6, dash = "dot")) %>%
  add_trace(name="patients",data = ins_eng, x = ~year, y = ~patient_count, color = ~ins, colors = cols_this, 
            type = 'scatter', mode = 'lines', line = list(width = 6)) %>%
  add_annotations(x = 2002, y = max(ins_eng$encounter_count)/3, showarrow = F, text = "HUMAN", font = list(size = 18, color = cols_this[2])) %>%
  add_annotations(x = 2011, y = max(ins_eng$encounter_count), showarrow = F, text = "ENGINEERED", font = list(size = 18, color = cols_this[1])) %>%
  layout(title = "HF Insulins, engineered-or-human, encounters and patients vs year",
         xaxis = list(title = "Year", range =c(2000,2014)),
         yaxis = list (title = "N"),
         margin = list(t = 100, l = 60, r = 60),
         font = list(family = "Arial", size = 14),
         showlegend = T, legend = list(x = 0.1, y = 0.9))
p1
#
p2 <- plot_ly(ins_gname, x = ~year, y = ~encounter_count, color = ~generic_name, 
            type = 'scatter', mode = 'lines', line = list(width = 4)) %>%
  layout(title = "HF Insulins, encounters by generic name vs year",
         xaxis = list(title = "Year", range =c(2000,2014)),
         yaxis = list (title = "Encounters"),
         margin = list(t = 100, l = 60, r = 60),
         font = list(family = "Arial", size = 14),
         showlegend = T)
p2
#
###
#Diabetes diagnoses: counts vs year, grouped by diagnosis-groups.
diabetes_byyear <- read_csv("data/hf_diabetes_byyear.csv", col_types = cols(year = col_integer(), diagnosis_code = col_character()))

diabetes_byyear <- diabetes_byyear[grepl("^250", diabetes_byyear$diagnosis_code),]
#
diabetes_codes <- unique(diabetes_byyear[,c("diagnosis_type","diagnosis_code","diagnosis_description")])
diabetes_codes <- diabetes_codes[order(diabetes_codes$diagnosis_code),]

diab <- diabetes_byyear[!is.na(diabetes_byyear$year),c("encounter_count","patient_count","diagnosis_description","year")]
diab$diagnosis_description <- sub("mellitus", "Mellitus", diab$diagnosis_description)
diab$diagnosis_description <- sub("uncontrolled", "Uncontrolled", diab$diagnosis_description)
diab$diagnosis_description <- sub("type", "Type", diab$diagnosis_description)
diab$diagnosis_description <- sub("with .*$", "WITH COMPLICATIONS", diab$diagnosis_description)
diab$diagnosis_description <- sub("Complicating .*$", "WITH COMPLICATIONS", diab$diagnosis_description)
diab$diagnosis_description <- sub(" \\[juvenile\\ type]", "", diab$diagnosis_description, ignore.case=T)
diab$diagnosis_description <- sub(", not stated as uncontrolled", "", diab$diagnosis_description, ignore.case=T)
diab$diagnosis_description <- sub(" without mention of complication", "", diab$diagnosis_description, ignore.case=T)
diab_counts <- aggregate(x = diab$encounter_count, by = list(diab$diagnosis_description, diab$year), FUN = sum)
colnames(diab_counts) <- c("diag","year","encounter_count")
diab_counts <- diab_counts[order(diab_counts$diag,diab_counts$year),]
print("*** DIABETES Dx BY YEAR:\n")
print(diab_counts)
#
p4 <- plot_ly(diab_counts, x = ~year, y = ~encounter_count, color = ~diag, 
              type = 'scatter', mode = 'lines', line = list(width = 4)) %>%
  layout(title = "HF Diabetes, encounters by diagnosis vs year",
         xaxis = list(title = "Year", range =c(2000,2014)),
         yaxis = list (title = "Encounters"),
         margin = list(t = 100, l = 60, r = 60),
         font = list(family = "Arial", size = 14),
         showlegend = T, legend = list(x = 0.1, y = 0.9))
p4
#
###
#HbA1c labs: counts vs year, grouped by ...
hba1c_byyear <- read_csv("data/hf_lab_hba1c_byyear.csv", col_types = cols(year = col_integer()))
lab_codes <- unique(hba1c_byyear[,c("lab_procedure_id","lab_procedure_name")])
labs <- hba1c_byyear[!is.na(hba1c_byyear$year),c("encounter_count","patient_count","lab_procedure_name","year")]
labs_counts <- aggregate(x = labs$encounter_count, by = list(labs$lab_procedure_name, labs$year), FUN = sum)
colnames(labs_counts) <- c("lab_procedure_name","year","encounter_count")
labs_counts <- labs_counts[order(labs_counts$lab_procedure_name,labs_counts$year),]
labs_counts$lab_procedure_name <- sub("Hemoglobin A1C \\(Glycosylated Hemoglobin\\)", "HbA1c", labs_counts$lab_procedure_name)
#
print("*** HbA1c LAB PROCEDURES BY YEAR:\n")
print(labs_counts)
#
### Result indicator codes:
result_codes <- read_csv("data/hf_d_result_indicator.csv")
#
#if (interactive() && !(readline("DEBUG: continue [y]/n? ") %in% c('','y'))) {stop()}
#
hba1c_vals <- read_csv("data/hf_lab_hba1c_vals.csv", col_types = cols(numeric_result = col_double(), year = col_integer()))
#
print("*** HbA1c DISTRIBUTIONS:\n")
q <- quantile(hba1c_vals$numeric_result, probs = c(0, .25, .50, .75, seq(0.9, 1, 0.01)))
print(sprintf("HbA1c (raw): N: %d ; range: [%f,%f] ; mean: %f\n", nrow(hba1c_vals),
	min(hba1c_vals$numeric_result), max(hba1c_vals$numeric_result), mean(hba1c_vals$numeric_result)))
for (i in 1:length(q)) {
  print(sprintf("%5s-ile: %.2f\n", names(q)[i], q[i]))
}

hba1c_vals <- hba1c_vals[hba1c_vals$numeric_result>=HBA1C_MIN & hba1c_vals$numeric_result<=HBA1C_MAX,] 
#
#Quantiles:
q <- quantile(hba1c_vals$numeric_result, probs = c(0, .25, .50, .75, seq(0.9, 1, 0.01)))
print(sprintf("HbA1c (sane): N: %d ; range: [%f,%f] ; mean: %f\n", nrow(hba1c_vals),
	min(hba1c_vals$numeric_result), max(hba1c_vals$numeric_result), mean(hba1c_vals$numeric_result)))
for (i in 1:length(q)) {
  print(sprintf("%5s-ile: %.2f\n", names(q)[i], q[i]))
}
#
#result_indicator_id = 22 ?
#
hba1c_vals <- merge(hba1c_vals, result_codes, all.x=T, all.y=F, by="result_indicator_id")
#
print("*** HbA1c COUNTS BY RESULT INDICATOR:\n")
hba1c_vals$result_indicator_desc[is.na(hba1c_vals$result_indicator_desc)] <- "?"
t <- table(hba1c_vals$result_indicator_id)
for (riid in names(t))
{
  riid_desc <- result_codes$result_indicator_desc[result_codes$result_indicator_id==riid]
  riid_desc <- ifelse(length(riid_desc)>0, riid_desc, "?")
  print(sprintf("[riid=%2s] %18s: %6d\n", riid, riid_desc, t[riid]))
}
#
p5 <- plot_ly(hba1c_vals, y = ~numeric_result, x = ~result_indicator_desc, type = "box", boxmean = T,
              marker = list(symbol = "dot", opacity = 0.4)) %>%
  layout(title=sprintf("HealthFacts HbA1c values (10%% sample)<br>N_total = %d (%.2g)",nrow(hba1c_vals),nrow(hba1c_vals)),
         yaxis = list(title = sprintf("HbA1c (cutoffs: [%d,%d])",HBA1C_MIN,HBA1C_MAX), range = c(0,20)), 
         xaxis = list(title = "result_indicator_desc"), 
         margin = list(t=100,l=80,b=100,r=80), showlegend = F,
         font = list(family = "Arial", size = 14))
p5
#
###
