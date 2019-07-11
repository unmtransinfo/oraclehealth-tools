package edu.unm.health.biocomp.hf;

import java.io.*;
import java.util.*;
import java.util.regex.*;
import java.sql.*;

import edu.unm.health.biocomp.db.*;
import edu.unm.health.biocomp.util.*;

/**	HealthFacts query app.  See online help.

	@author Jeremy J Yang
*/
public class hf_query
{
  /////////////////////////////////////////////////////////////////////////////
  //MS SqlServer:
  //private static String DBHOST="hsc-ctscvs5.health.unm.edu";
  //private static String DBNAME="HealthFacts";
  //private static String DBDOMAIN="HEALTH";
  //private static Integer DBPORT=1433;

  //Postgresql (via tunnel):
  private static String DBHOST="localhost";
  private static String DBNAME="healthfacts";
  private static Integer DBPORT=63333;

  private static String DBUSR="jjyang";
  private static String DBP=null;

  /////////////////////////////////////////////////////////////////////////////
  private static void Help(String msg)
  {
    System.err.println(msg+"\n"
      +"hf_query - HealthFacts query application\n"
      +"usage: hf_query [options]\n"
      +"  operations:\n"
      +"    -test .................. test connection\n"
      +"    -info .................. db metadata\n"
      +"    -list_tables ........... \n"
      +"    -query ................. query db\n"
      +"  i/o:\n"
      +"    -sqlfile SQLFILE ....... \n"
      +"    -sql SQL ............... \n"
      +"    -o OFILE ............... output file (CSV)\n"
      +"  options:\n"
      +"    -dbhost DBHOST ......... ["+DBHOST+"]\n"
      +"    -dbport DBPORT ......... ["+DBPORT+"] \n"
      +"    -dbname DBNAME ......... ["+DBNAME+"] \n"
      +"    -dbusr DBUSR ........... ["+DBUSR+"] \n"
      +"    -dbpw DBPW ............. [********]\n"
      +"    -v[v] .................. verbose [very]\n"
      +"    -h ..................... this help\n");
    System.exit(1);
  }
  private static int verbose=0;
  private static String ofile=null;
  private static String sqlfile=null;
  private static String sql=null;
  private static boolean test=false;
  private static boolean info=false;
  private static boolean list_tables=false;
  private static boolean query=false;
  /////////////////////////////////////////////////////////////////////////////
  private static void ParseCommand(String args[])
  {
    if (args.length==0) Help("");
    for (int i=0;i<args.length;++i)
    {
      if (args[i].equals("-o")) ofile=args[++i];
      else if (args[i].equals("-sqlfile")) sqlfile=args[++i];
      else if (args[i].equals("-sql")) sql=args[++i];
      else if (args[i].equals("-test")) test=true;
      else if (args[i].equals("-info")) info=true;
      else if (args[i].equals("-list_tables")) list_tables=true;
      else if (args[i].equals("-query")) query=true;
      else if (args[i].equals("-dbhost")) DBHOST=args[++i];
      else if (args[i].equals("-dbport")) DBPORT=Integer.parseInt(args[++i]);
      else if (args[i].equals("-dbname")) DBNAME=args[++i];
      else if (args[i].equals("-dbusr")) DBUSR=args[++i];
      else if (args[i].equals("-dbpw")) DBP=args[++i];
      else if (args[i].equals("-v")) verbose=1;
      else if (args[i].equals("-vv")) verbose=2;
      else if (args[i].equals("-h")) Help("");
      else Help("Unknown option: "+args[i]);
    }
  }
  /////////////////////////////////////////////////////////////////////////////
  private static String P(String p)
	throws IOException
  {
    if (p!=null) return p;
    BufferedReader br = new BufferedReader(new FileReader(new File(System.getenv("HOME")+"/.ep")));
    String ep = br.readLine();
    br.close();
    p="";
    for (int i=0; i<ep.length(); i+=8)
      p+=((char)(Integer.parseInt(ep.substring(i,i+8))));
    return p;
  }
  /////////////////////////////////////////////////////////////////////////////
  public static void main(String [] args)
	throws Exception
  {
    ParseCommand(args);
    if (query && sql==null && sqlfile==null)
      Help("-query requires -sql or -sqlfile.");

    java.util.Date t_0 = new java.util.Date();

    DBCon dbcon = null;

    try {
      //dbcon = new DBCon("microsoft",DBHOST,DBPORT,DBNAME,DBUSR,P(DBP));
      dbcon = new DBCon("postgres",DBHOST,DBPORT,DBNAME,DBUSR,DBP);
    }
    catch (SQLException e) { Help("Connection failed:"+e.getMessage()); }

    if (sqlfile!=null)
    {
      BufferedReader br = new BufferedReader(new FileReader(new File(sqlfile)));
      sql="";
      for (String line=null; (line=br.readLine())!=null ; )
        sql+=(line+"\n");
      br.close();
    }

    OutputStream ostream=null;
    if (ofile!=null)
      ostream = new FileOutputStream(new File(ofile),false);
    else
      ostream = ((OutputStream)System.out);

    if (test)
    {
      System.err.println(dbcon.serverStatusTxt());
    }
    else if (info)
    {
      System.err.println(hf_utils.DBInfo(dbcon));
    }
    else if (list_tables)
    {
      for (String t: hf_utils.GetTableList(dbcon))
        System.err.println("\t"+t);
    }
    else if (query)
    {
      if (verbose>0)
        System.err.println("sql: \""+sql+"\"");
      ResultSet rset = null;
      try {
        rset = dbcon.executeSql(sql);
        hf_utils.Rset2Csv(rset,ostream,verbose);
      } catch (SQLException e) {
        System.err.println("ERROR (SQLException): "+e.getMessage());
      }
    }
    else
      Help("No operation specified.");

    System.err.println("elapsed time: "+time_utils.TimeDeltaStr(t_0,new java.util.Date()));
  }
}
