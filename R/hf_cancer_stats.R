hf <- read.delim("~/projects/hf/data/hf_cancer_byclass+age.csv", stringsAsFactors=F)

hf$cancer_class <- as.factor(hf$cancer_class)
hf$agerange <- as.factor(hf$agerange)

ncc <- length(levels(hf$cancer_class))
nar <- length(levels(hf$agerange))
print(sprintf("cancer classes: %s", ncc))
print(sprintf("age ranges: %s", nar))


## Encounter frequency matrix of meds vs. diagnoses

fmat <- matrix(rep(0,ncc*nar), nrow=ncc, ncol=nar, dimnames = list(levels(hf$cancer_class), levels(hf$agerange)))

for (i in 1:nrow(hf))
{
  cc <- hf$cancer_class[i]
  ar <- hf$agerange[i]
  ec <- hf$encounter_count[i]
  pc <- hf$patient_count[i]
  #print(sprintf("DEBUG: \"%s\" , \"%s\" : %d", med, diag, n))
  fmat[cc, ar] <- pc
}



library(gplots)
# 
par(mar=c(5,5,5,12))
my_palette <- colorRampPalette(rev(c("red","orange","yellow","gray")))(n = 16)
heatmap.2(fmat, 
          margins=c(8,8),
          srtRow=45, srtCol=45,
          main=sprintf("HealthFacts CancerClass ByAgeGroup Counts (2014)"),
          xlab="Age Group", ylab="Cancer Class",
          cexRow=0.6,cexCol=0.6,
          density.info="none",  # no density plot in legend
          trace="none",
          col=my_palette,
          dendrogram="none",
          Rowv=NULL,
          Colv=NULL,
          key.title=NA,key.xlab=NA,keysize=1.0)
