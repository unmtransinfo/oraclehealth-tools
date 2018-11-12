hf <- read.csv("data/hf_gi_stats.csv", stringsAsFactors=F)

#hf$diagnosis_code <- as.factor(hf$diagnosis_code)
#hf$diagnosis_description <- as.factor(hf$diagnosis_description)
#hf$agerange <- as.factor(hf$agerange)
hf$patients <- as.integer(hf$patients)

ndc <- length(unique(hf$diagnosis_code))
nar <- length(unique(hf$agerange))
print(sprintf("colitis classes: %s", ndc))
print(sprintf("agerange: %s", nar))


fmat <- matrix(rep(0,ndc*nar), nrow=ndc, ncol=nar, dimnames = list(unique(hf$diagnosis_description), unique(hf$agerange)))

for (i in 1:nrow(hf))
{
  dd <- hf$diagnosis_description[i]
  ar <- hf$agerange[i]
  pc <- hf$patients[i]
  fmat[dd, ar] <- pc
}

for (dd in levels(as.factor(hf$diagnosis_description)))
{
  n <- sum(hf$patients[hf$diagnosis_description == dd])
  dc <- unique(hf$diagnosis_code[hf$diagnosis_description == dd])
  print(sprintf("%42s (%-5s): %7d patients", dd, dc, n))
}

print("")
for (ar in levels(as.factor(hf$agerange)))
{
  n <- sum(hf$patients[hf$agerange == ar])
  print(sprintf("%12s: %7d patients", ar, n))
}


#library(gplots)
# 
#par(mar=c(5,5,5,12))
#my_palette <- colorRampPalette(rev(c("red","orange","yellow","gray")))(n = 16)
#heatmap.2(fmat, 
#          margins=c(8,8),
#          srtRow=45, srtCol=45,
#          main=sprintf("HealthFacts Colitis class by Agerange Counts"),
#          xlab="Age range", ylab="Colitis class",
#          cexRow=0.6,cexCol=0.6,
#          density.info="none",  # no density plot in legend
#          trace="none",
#          col=my_palette,
#          dendrogram="none",
#          Rowv=NULL,
#          Colv=NULL,
#          key.title=NA,key.xlab=NA,keysize=1.0)
