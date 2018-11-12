library(DBI)
require(rJava)
library(RJDBC)

source("/home/jjyang/lib/R/hf_utils.R")



conn <- hf_utils$dbConnect()

print(sprintf("DEBUG: %s", str(conn@jc)))

tbls <- dbListTables(conn)
n_hf_tbls <- 0
for (tbl in tbls)
{
  if (grepl("^HF_",tbl,ignore.case=T))
  {
    n_hf_tbls <- n_hf_tbls + 1 
  }
}
print(sprintf("HF tables: %d", n_hf_tbls))

sql <- "SELECT COUNT(*) FROM hf_d_medication"
rset <- dbSendQuery(conn, sql)
print(sprintf("query completed: %s", dbHasCompleted(rset)))

#print(sprintf("rowcount: %d", dbGetRowCount(rset)))
info <- dbGetInfo(rset)
for (name in names(info))
  print(sprintf("%s: %s", name, info[name]))

n <- dbFetch(rset)
print(sprintf("n: %d", n[1,1]))

dbClearResult(rset)

dbDisconnect(conn)
