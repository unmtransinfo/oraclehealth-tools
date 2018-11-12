#############################################################################
### hf_runsql.R - MS SqlServer version
###   - read input SQL file
###   - connect to db
###   - run query, show progress for long queries
###   - output results (CSV)
#############################################################################
### dbSendQuery() executes SQL synchronously.  So dbHasCompleted() rather useless.
#############################################################################
### Jeremy Yang
### 11 Nov 2015
#############################################################################

args <- commandArgs(trailingOnly=T)
print(sprintf("DEBUG: length(args) = %d", length(args)))
if (length(args)<1)
{
  print(sprintf("Syntax: R -f hf_runsql.R --args SQLFILE [OFILE]"))
  quit()
}

fsql <- file(args[1])
sql <- ""
for (line in readLines(fsql))
  sql <- paste(sql, line, sep="\n")

#print(sql)
if (length(args)>1)
{
  fout = file(args[2],"w")
} else {
  fout = ""
}


library(DBI)
require(rJava)
library(RJDBC)

source("/home/jjyang/lib/R/hf_utils.R")

t0 <- proc.time()


conn <- hf_utils$dbConnect()

rset <- dbSendQuery(conn, sql)

#while (TRUE)
#{
#  done <- dbHasCompleted(rset)
#  if (done)
#  {
#    print(sprintf("query completed."))
#    break;
#  } else {
#    print(sprintf("searching..."))
#    system("sleep 1")
#  }
#}

#print(sprintf("rowcount: %d", dbGetRowCount(rset)))
info <- dbGetInfo(rset)
for (name in names(info))
  print(sprintf("%s: %s", name, info[name]))

rdata <- dbFetch(rset)

print(sprintf("rowcount: %d", nrow(rdata)))

write.csv(rdata, file=fout, quote=T, sep=",", row.names=F)

#print(sprintf("n[1,1]: %s", n[1,1]))

dbClearResult(rset)

dbDisconnect(conn)
print(sprintf("elapsed time (total): %.2fs",(proc.time()-t0)[3]))
print(sprintf("elapsed time (total): %s",hf_utils$NiceTime((proc.time()-t0)[3])))
