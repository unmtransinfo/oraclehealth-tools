#!/usr/bin/Rscript
#############################################################################
# Get denominators for per-100K incidence from SQL:
# 'SELECT dp.gender, COUNT(DISTINCT fe.patient_id) patient_count FROM hf_f_diagnosis fd JOIN hf_f_encounter fe ON fe.encounter_id = fd.encounter_id JOIN hf_d_patient dp ON dp.patient_id = fe.patient_id GROUP BY dp.gender'
#
#Female|27321261
#Male|18646893
#Not Mapped|298
#Null|83
#NULL|5525
#Other|255
#Unknown/Invalid|6488
#############################################################################
library(readr)
library(data.table)
library(plotly)
library(dplyr)

N_MALE <- 18646893
N_FEMALE <- 27321261

icd_codes <- read_csv("data/hf_diag_codes_icd9.csv", col_types = cols(diagnosis_code = col_character()))
setDT(icd_codes, key="diagnosis_id")


dxcounts <- read_csv("data/hf_diag_bygender.csv" )

dxcounts <- dxcounts[dxcounts$gender %in% c('Female','Male'),]

dxcounts_f <- dxcounts[dxcounts$gender=='Female',]
dxcounts_m <- dxcounts[dxcounts$gender=='Male',]

dxcounts_f$gender <- NULL
dxcounts_m$gender <- NULL

colnames(dxcounts_f) <- c('diagnosis_id','dx_count_f')
colnames(dxcounts_m) <- c('diagnosis_id','dx_count_m')

dxcounts <- merge(dxcounts_f, dxcounts_m, all=T, by='diagnosis_id')
setDT(dxcounts, key="diagnosis_id")

dxcounts <- icd_codes[dxcounts]

dxcounts$nir_f <- NA #normalized-incidence-rate
dxcounts$nir_m <- NA #normalized-incidence-rate

dxcounts$nir_f <- dxcounts$dx_count_f * 1e5 / N_FEMALE
dxcounts$nir_m <- dxcounts$dx_count_m * 1e5 / N_MALE


