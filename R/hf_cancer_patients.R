hf <- read.delim("~/projects/hf/data/hf_cancer-diabetes_patients.csv", stringsAsFactors=F)

print(sprintf("total data rows: %d", nrow(hf)))

cancer_codes <- read.delim("~/Downloads/HF/data/hf_cancer_codes.csv", colClasses = "character")
diabetes_codes <- read.delim("~/Downloads/HF/data/hf_diabetes_codes.csv", colClasses = "character")

cancer_codes <- cancer_codes[order(cancer_codes$diagnosis_code),]
diabetes_codes <- diabetes_codes[order(diabetes_codes$diagnosis_code),]

#for (i in 1:nrow(cancer_codes))
#{ print(sprintf("CANCER: %-6s: %s",cancer_codes$diagnosis_code[i],cancer_codes$diagnosis_description[i])) }

#for (i in 1:nrow(diabetes_codes))
#{ print(sprintf("DIABETES: %-6s: %s",diabetes_codes$diagnosis_code[i],diabetes_codes$diagnosis_description[i])) }


ncc <- length(levels(as.factor(hf$cancer_code)))
ndc <- length(levels(as.factor(hf$diabetes_code)))
print(sprintf("cancer codes: %d ; cancer diagnoses in dataset: %s", nrow(cancer_codes), ncc))
print(sprintf("diabetes codes: %d ; diabetes diagnoses in dataset: %s", nrow(diabetes_codes), ndc))

print(sprintf("mean absolute days between diagnoses: %.1f", mean(abs(hf$days_between_diagnoses))))
print(sprintf("mean absolute days between diagnoses (cancer->diabetes): %.1f", mean(hf[hf$days_between_diagnoses>0,]$days_between_diagnoses)))
print(sprintf("mean absolute days between diagnoses (diabetes->cancer): %.1f", -mean(hf[hf$days_between_diagnoses<0,]$days_between_diagnoses)))

## Group diabetes diagnoses into classes:
hf$diabetes_class <- rep(NA,nrow(hf))
for (code in c("250",as.character(seq(250.1,250.9,.1))))
{
  desc <- diabetes_codes[diabetes_codes$diagnosis_code==code,]$diagnosis_description[1]
  #print(sprintf("DEBUG: %s: \"%s\"",code,desc))
  if (nrow(hf[substr(hf$diabetes_code,1,5) == code,]) > 0)
    hf[substr(hf$diabetes_code,1,5) == code,]$diabetes_class <- desc
}
hf$diabetes_class <- as.factor(hf$diabetes_class)
for (class in ordered(levels(hf$diabetes_class)))
{
  print(sprintf("DIABETES CLASS: %s [N = %d]", class, nrow(hf[hf$diabetes_class==class,])))
}

## Group cancer diagnoses into classes:
hf$cancer_class <- rep(NA,nrow(hf))

cancer_classes = data.frame(
  from = c(
	"140",
	"150",
	"160",
	"170",
	"179",
	"190",
	"200",
	"209",
	"230"),
  to = c(
	"149.99",
	"159.99",
	"165.99",
	"176.99",
	"189.99",
	"199.99",
	"208.99",
	"209.99",
	"234.99"),
  desc = c(
	"MALIGNANT NEOPLASM OF LIP, ORAL CAVITY, AND PHARYNX",
	"MALIGNANT NEOPLASM OF DIGESTIVE ORGANS AND PERITONEUM",
	"MALIGNANT NEOPLASM OF RESPIRATORY AND INTRATHORACIC ORGANS",
	"MALIGNANT NEOPLASM OF BONE, CONNECTIVE TISSUE, SKIN, AND BREAST",
	"MALIGNANT NEOPLASM OF GENITOURINARY ORGANS",
	"MALIGNANT NEOPLASM OF OTHER AND UNSPECIFIED SITES",
	"MALIGNANT NEOPLASM OF LYMPHATIC AND HEMATOPOIETIC TISSUE",
	"NEUROENDOCRINE TUMORS",
	"CARCINOMA IN SITU"),
  stringsAsFactors = FALSE
	)

for (i in 1:nrow(cancer_classes))
{
  code_from = cancer_classes$from[i]
  code_to = cancer_classes$to[i]
  desc = cancer_classes$desc[i]
  #print(sprintf("DEBUG: [%s-%s]: %s",code_from,code_to,desc))
  n <- nrow(hf[as.numeric(hf$cancer_code)>=as.numeric(code_from) & as.numeric(hf$cancer_code)<as.numeric(code_to),])
  #print(sprintf("DEBUG: code_from = %s, code_to = %s nrow = %d",code_from, code_to, n))
  if (n>0) {
    hf[as.numeric(hf$cancer_code)>=as.numeric(code_from) & as.numeric(hf$cancer_code)<as.numeric(code_to),]$cancer_class <- desc
  } 
}

hf$cancer_class <- as.factor(hf$cancer_class)
for (class in ordered(levels(hf$cancer_class)))
{
  print(sprintf("CANCER CLASS: %s [N = %d]", class, nrow(hf[hf$cancer_class==class,])))
}

##  Patient count co-morbidity matrix of cancer vs. diabetes classes
ncc <- length(levels(hf$cancer_class))
ndc <- length(levels(hf$diabetes_class))
fmat <- matrix(rep(0,ncc*ndc), nrow=ncc, ncol=ndc, dimnames = list(levels(hf$cancer_class), levels(hf$diabetes_class)))

for (cc in levels(hf$cancer_class))
{
  for (dc in levels(hf$diabetes_class))
  {
    n <- nrow(hf[hf$cancer_class==cc & hf$diabetes_class==dc,])
    fmat[cc, dc] <- n
  }
}


library(gplots)
# 
par(mar=c(5,5,5,12))
my_palette <- colorRampPalette(rev(c("red","orange","yellow","gray")))(n = 16)
heatmap.2(fmat, 
          margins=c(8,8),
          srtRow=45, srtCol=45,
          main=sprintf("HF Cancer-Diabetes co-morbidity (2014)"),
          xlab="Diabetes Class", ylab="Cancer Class",
          cexRow=0.6,cexCol=0.6,
          density.info="none",  # no density plot in legend
          trace="none",
          col=my_palette,
          dendrogram="none",
          Rowv=NULL,
          Colv=NULL,
          key.title=NA,key.xlab=NA,keysize=1.0)

write.csv(fmat, "~/Downloads/HF/data/hf_cancer-diabetes_counts.csv")
