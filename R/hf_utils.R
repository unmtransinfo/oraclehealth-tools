require(DBI)
require(rJava)
require(RJDBC)


hf_utils <- new.env()

#############################################################################
### Connections
DRIVER <- JDBC("net.sourceforge.jtds.jdbc.Driver", "/home/app/lib/jtds-1.3.1.jar")
DSN <- "jdbc:jtds:sqlserver://hsc-ctscvs5.health.unm.edu:1433;DatabaseName=HealthFacts"
DOMAIN <- "HEALTH"
USER <- "jjyang"


hf_utils$getPwd <- function(prompt = "Enter password: ") {
  cat(prompt)
  pwd <- system('stty -echo && read ff && stty echo && echo $ff && ff=""', intern=TRUE)
  cat('\n')
  invisible(pwd)
}

hf_utils$myPwd <- function() {
  pwd <- system('cat ~/.ep |nc.py', intern=TRUE)
  invisible(pwd)
}


hf_utils$dbConnect <- function(dsn=DSN, domain=DOMAIN, user=USER, password=hf_utils$myPwd()) {
  return (dbConnect(DRIVER,dsn,domain=domain,user=user,password=password));
}

#############################################################################
### Connections
hf_utils$NiceTime <- function(sec) {
  h <- as.integer(sec / 3600)
  m <- as.integer((as.integer(sec) %% 3600) / 60)
  s <- as.integer(sec) %% 60
  sprintf("%d:%02d:%02d",h,m,s)
}
