package edu.unm.health.biocomp.cerner.hf;

import java.io.*;
import java.util.*;
import java.util.regex.*;
import java.sql.*;

import edu.unm.health.biocomp.util.*;
import edu.unm.health.biocomp.util.db.*;

/**	HealthFacts patient facts app.  See online help.

	@author Jeremy J Yang
*/
public class hf_patients
{
  //Postgresql (via tunnel):
  private static String DBHOST="localhost";
  private static String DBNAME="healthfacts";
  private static Integer DBPORT=63333;

  private static String DBUSR="jjyang";
  private static String DBP=null;

  private static Integer NMAX=null;
  private static String ftype="all";

  /////////////////////////////////////////////////////////////////////////////
  private static void Help(String msg)
  {
    System.err.println(msg+"\n"
      +"hf_patients - HealthFacts patient facts app\n"
      +"Select patients and get all facts of specified type.\n"
      +"usage: hf_patients [options]\n"
      +"\n"
      +"  i/o:\n"
      +"    -o OFILE ............... output file (CSV)\n"
      +"\n"
      +"  patient selection:\n"
      +"    -nmax NMAX ............. patient limit [None]\n"
      +"    -skip SKIP ............. skip 1st SKIP patients (from input file only)\n"
      +"    -random ................ random selection (from db only)\n"
      +"    -skfile SKFILE ......... input SK IDs (else sample all)\n"
      +"    -sk SK ................. input SK ID\n"
      +"    -id ID ................. input patient ID (mapped to SK)\n"
      +"    -idfile IDFILE ......... input patient IDs (mapped to SK)\n"
      +"\n"
      +"  fact selection:\n"
      +"    -ftype FTYPE ........... ["+ftype+"]\n"
      +"\n"
      +"  options:\n"
      +"    -dbhost DBHOST ......... ["+DBHOST+"]\n"
      +"    -dbport DBPORT ......... ["+DBPORT+"] \n"
      +"    -dbname DBNAME ......... ["+DBNAME+"] \n"
      +"    -dbusr DBUSR ........... ["+DBUSR+"] \n"
      +"    -dbpw DBPW ............. [********]\n"
      +"    -v[v[v]] ............... verbose [very [very]]\n"
      +"    -h ..................... this help\n"
      +"\n"
      +"FTYPES:\n"
      +"\tdiagnosis\n"
      +"\tmedication\n"
      +"\tmed_history\n"
      +"\tsurgery\n"
      +"\tlab\n"
      +"\tclinical_event\n"
      +"\tdischarge\n"
      +"\tprocedure\n"
      +"\n");
    System.exit(1);
  }
  private static int verbose=0;
  private static int nskip=0;
  private static String ofile=null;
  private static String skfile=null;
  private static String pidfile=null;
  private static String sk=null;
  private static String pid=null;
  private static boolean random=false;
  /////////////////////////////////////////////////////////////////////////////
  private static void ParseCommand(String args[])
  {
    if (args.length==0) Help("");
    for (int i=0;i<args.length;++i)
    {
      if (args[i].equals("-o")) ofile=args[++i];
      else if (args[i].equals("-skfile")) skfile=args[++i];
      else if (args[i].equals("-idfile")) pidfile=args[++i];
      else if (args[i].equals("-sk")) sk=args[++i];
      else if (args[i].equals("-id")) pid=args[++i];
      else if (args[i].equals("-ftype")) ftype=args[++i];
      else if (args[i].equals("-random")) random=true;
      else if (args[i].equals("-nmax")) NMAX=Integer.parseInt(args[++i]);
      else if (args[i].equals("-skip")) nskip=Integer.parseInt(args[++i]);
      else if (args[i].equals("-dbhost")) DBHOST=args[++i];
      else if (args[i].equals("-dbport")) DBPORT=Integer.parseInt(args[++i]);
      else if (args[i].equals("-dbname")) DBNAME=args[++i];
      else if (args[i].equals("-dbusr")) DBUSR=args[++i];
      else if (args[i].equals("-dbpw")) DBP=args[++i];
      else if (args[i].equals("-v")) verbose=1;
      else if (args[i].equals("-vv")) verbose=2;
      else if (args[i].equals("-vvv")) verbose=3;
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
    java.util.Date t_0 = new java.util.Date();
    DBCon dbcon = null;
    try {
      //dbcon = new DBCon("microsoft",DBHOST,DBPORT,DBNAME,DBUSR,P(DBP));
      dbcon = new DBCon("postgres",DBHOST,DBPORT,DBNAME,DBUSR,DBP);
    }
    catch (SQLException e) { Help("Connection failed:"+e.getMessage()); }

    if (verbose>0)
      System.err.println(hf_utils.DBInfo(dbcon));

    OutputStream ostream=null;
    if (ofile!=null)
      ostream = new FileOutputStream(new File(ofile),false);
    else
      ostream = ((OutputStream)System.out);

    List<Long> sks = new ArrayList<Long>();
    if (skfile!=null)
    {
      if (verbose>0)
        System.err.println("Input patient SK file: "+skfile);
      BufferedReader br = new BufferedReader(new FileReader(new File(skfile)));
      for (String line=null; (line=br.readLine())!=null ; )
      {
        try { sks.add(Long.parseLong(line)); }
        catch (Exception e) { System.err.println("ERROR: bad sk: \""+line+"\""); }
      }
      br.close();
    }
    else if (sk!=null)
    {
      try { sks.add(Long.parseLong(sk)); }
      catch (Exception e) { System.err.println("ERROR: bad sk: \""+sk+"\""); }
    }
    else if (pidfile!=null)
    {
      if (verbose>0)
        System.err.println("Input patient ID file: "+pidfile);
      BufferedReader br = new BufferedReader(new FileReader(new File(pidfile)));
      for (String line=null; (line=br.readLine())!=null ; )
      {
        try { sks.add(hf_utils.Pid2Sk(dbcon,Long.parseLong(line))); }
        catch (Exception e) { System.err.println("ERROR: bad pid: \""+line+"\""); }
      }
      br.close();
    }
    else if (pid!=null)
    {
      try { sks.add(hf_utils.Pid2Sk(dbcon,Long.parseLong(pid))); }
      catch (Exception e) { System.err.println("ERROR: bad pid: \""+pid+"\""); }
    }
    else
    {
      sks = hf_utils.GetPatientSkList(dbcon, random, NMAX);
      //System.err.println("DEBUG: patient_sk count: "+sks.size()+(" (elapsed time: "+time_utils.TimeDeltaStr(t_0,new java.util.Date())+")"));
    }
    System.err.println("patient_sk count: "+sks.size());

    if (ftype!=null)
    {
      if (verbose>0)
        System.err.println("Patient fact type: "+ftype);
      hf_utils.PatientFacts(dbcon, sks, hf_utils.ParseFactType(ftype), NMAX, nskip, ostream, verbose);
    }
    else
      Help("No operation specified.");

    System.err.println("elapsed time: "+time_utils.TimeDeltaStr(t_0,new java.util.Date()));
  }
}
