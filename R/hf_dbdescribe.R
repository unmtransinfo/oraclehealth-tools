library(DBI)
require(rJava)
library(RJDBC)

source("/home/jjyang/lib/R/hf_utils.R")



conn <- hf_utils$dbConnect()


tbls <- dbListTables(conn)
n_tbl <- 0
for (i in order(tbls))
{
  if (grepl("^HF_",tbls[i],ignore.case=T))
  {
    n_tbl <- n_tbl + 1
    print(sprintf("%d. %s", n_tbl, tbls[i]))
    fields <- dbListFields(conn,tbls[i])
    for (j in order(fields))
    {
      print(sprintf("  %s.%s", tbls[i],fields[j]))
    }
  }
}
print(sprintf("tables: %d", n_tbl))

dbDisconnect(conn)
