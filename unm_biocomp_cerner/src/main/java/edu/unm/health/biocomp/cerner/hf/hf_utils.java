package edu.unm.health.biocomp.cerner.hf;

import java.io.*;
import java.util.*;
import java.util.regex.*;
import java.sql.*;

import edu.unm.health.biocomp.util.*;
import edu.unm.health.biocomp.util.db.*; //DBCon

/**	HealthFacts utils, static methods.
	@author Jeremy J Yang
*/
public class hf_utils
{
  /////////////////////////////////////////////////////////////////////////////
  /**   Return text with DB metadata.
  */
  public static String DBInfo(DBCon dbcon)
        throws SQLException
  {
    DatabaseMetaData meta = dbcon.getConnection().getMetaData();
    String txt=meta.getDatabaseProductName()
      +" "+meta.getDatabaseMajorVersion()+"."+meta.getDatabaseMinorVersion()+" ("
      +meta.getDriverName()+" "+meta.getDriverVersion()+")";
    //ResultSet rset;
    //rset=dbcon.executeSql("SELECT count(*) FROM hf_f_encounter");
    //if (rset.next())
    //  txt+=("total encounters: "+rset.getString(1)+"\n");
    //rset.getStatement().close();
    return txt;
  }
  /////////////////////////////////////////////////////////////////////////////
  public static List<String> GetTableList(DBCon dbcon)
        throws SQLException
  {
    ArrayList<String> tbls = new ArrayList<String>();
    ResultSet rset=dbcon.executeSql("SELECT table_schema,table_name FROM information_schema.tables");
    while (rset.next())
    {
      String sch = rset.getString(1);
      String tbl = rset.getString(2);
      if (tbl.matches(".*_[DdFf]_.*"))
        tbls.add(sch+":"+tbl);
    }
    rset.getStatement().close();
    Collections.sort(tbls);
    return tbls;
  }
  /////////////////////////////////////////////////////////////////////////////
  public static void Rset2Csv(ResultSet rset, OutputStream ostream, int verbose)
        throws SQLException
  {
    PrintWriter fout_writer=new PrintWriter(new OutputStreamWriter(ostream));
    ResultSetMetaData rset_meta = rset.getMetaData();
    int ncol = rset_meta.getColumnCount();
    for (int i=1;i<=ncol;++i)
    {
      if (i>1) fout_writer.write(",");
      fout_writer.write("\""+rset_meta.getColumnName(i)+"\"");
    }
    fout_writer.write("\n");
    while (rset.next())
    {
      for (int i=1;i<=ncol;++i)
      {
        if (i>1) fout_writer.write(",");
        String val = (rset.getString(i)==null)?"":rset.getString(i);
        if (rset_meta.getColumnType(i)==Types.CHAR || rset_meta.getColumnType(i)==Types.VARCHAR)
          fout_writer.write("\""+val+"\"");
        else
          fout_writer.write(val);
      }
      fout_writer.write("\n");
    }
    rset.getStatement().close();
    fout_writer.close();
  }
  /////////////////////////////////////////////////////////////////////////////
  /**
	@return	numerically ordered list of patient_sk IDs.
  */
  public static List<Long> GetPatientSkList(DBCon dbcon, boolean random, Integer nmax)
        throws SQLException
  {
    ArrayList<Long> sks = new ArrayList<Long>();
    String sql;
    if (random)
      sql="SELECT patient_sk,RANDOM() FROM hf_d_patient ORDER BY RANDOM()";
    else
      sql="SELECT patient_sk FROM hf_d_patient ORDER BY patient_sk";
    if (nmax!=null) sql+=" LIMIT "+nmax;
    ResultSet rset=dbcon.executeSql(sql);
    while (rset.next())
    {
      Long sk = rset.getLong(1);
      if (sk!=null) sks.add(sk);
    }
    return sks;
  }
  /////////////////////////////////////////////////////////////////////////////
  /**	Should be only one Sk, right?
  */
  public static Long Pid2Sk(DBCon dbcon, Long pid)
        throws SQLException
  {
    String sql="SELECT DISTINCT patient_sk FROM hf_d_patient WHERE patient_id = "+pid;
    ResultSet rset=dbcon.executeSql(sql);
    Long sk = null;
    if (rset.next())
      sk = rset.getLong(1);
    return sk;
  }
  /////////////////////////////////////////////////////////////////////////////
  public static Patient GetPatient(DBCon dbcon, long sk)
        throws SQLException
  {
    Patient p = new Patient(sk);

    String sql="SELECT DISTINCT patient_id,gender,race FROM hf_d_patient WHERE patient_sk::INTEGER = "+sk;
    ResultSet rset=dbcon.executeSql(sql);
    int i_row=0;
    while (rset.next())
    {
      ++i_row;
      Long id = rset.getLong(1);
      p.addPatientId(id);
      String gender = rset.getString(2);
      String race = rset.getString(3);
      if (gender!=null)
      {
        if (i_row==1 || p.getGender()==Patient.GENDER_UNKNOWN) p.setGender(gender);
      }
      if (race!=null)
      {
        if (i_row==1 || p.getRace()==Patient.RACE_UNKNOWN) p.setRace(race);
      }
    }
    return p;
  }
  /////////////////////////////////////////////////////////////////////////////
  /**	Find facts by type, write counts to output file.
  */
  public static void PatientFacts(DBCon dbcon, List<Long> sks, int ftype, Integer nmax, int skip, OutputStream ostream, int verbose)
        throws SQLException
  {
    PrintWriter fout_writer=new PrintWriter(new OutputStreamWriter(ostream));
    java.util.Date t_0 = new java.util.Date();

    //PatientList plist = new PatientList();
    int i_sk=0; //index into list
    long n_sk=0L; //# processed
    fout_writer.println("SK,PID,EID,Ftype,FID,PtypeID,Page,HospID,Result,Units,Date"); //11 fields
    if (verbose>1 && skip>0) System.err.println("skip = "+skip);
    Patient p = null;
    while (i_sk<sks.size() && n_sk<sks.size())
    {
      Long sk = sks.get(i_sk);
      if ((i_sk++)<skip)
      {
        if (verbose>2) System.err.println("Skipping SK["+i_sk+"]: "+sk);
        continue;
      }
      java.util.Date t_0_this = new java.util.Date();
      if (verbose>2) System.err.println(""+(n_sk+1)+". ["+i_sk+"] sk: "+sk);
      p = GetPatient(dbcon,sk);
      FactList flist=p.getFactList();
      AddFacts(dbcon,ftype,p.getPatientIds(),flist,verbose);
      if (verbose>2) System.err.println("\tnId: "+p.getPatientIdCount()+"; nFact: "+flist.size());
      if (flist.size()==0)
      {
        for (long pid: p.getPatientIds())
        {
          fout_writer.println(""+sk+","+pid+",,,,,,,,,");
          fout_writer.flush();
        }
      }
      else
      {
        for (Fact f: flist)
        {
          fout_writer.print(""+sk);			//1
          fout_writer.print(","+f.getPatientId());	//2
          fout_writer.print(","+f.getEncounterId());	//3
          fout_writer.print(","+f.getTypeStr());		//4
          fout_writer.print(","+f.getInstanceId());	//5
          fout_writer.print(","+f.getPatientTypeId());	//6
          fout_writer.print(","+f.getPatientAge());	//7
          fout_writer.print(","+f.getHospitalId());	//8
          fout_writer.print(","+((f.getResult()!=null)?f.getResult():""));		//9
          fout_writer.print(","+((f.getResultUnits()!=null && !f.getResultUnits().equalsIgnoreCase("NULL"))?f.getResultUnits():""));		//10
          fout_writer.print(","+f.getDateStr());		//11
          fout_writer.println();
          fout_writer.flush();
        }
      }
      //plist.add(p);
      if (verbose>2)
        System.err.println("\tt_this: "+time_utils.TimeDeltaStr(t_0_this,new java.util.Date()));
      if (nmax!=null && ++n_sk>=nmax) break;
      if (verbose>1 && n_sk%1000==0)
      {
        System.err.println("i_sk = "+i_sk+" / "+sks.size()+" ; runtime: "+time_utils.TimeDeltaStr(t_0,new java.util.Date()));
      }
    }
    fout_writer.close();
    //return plist;
  }
  /////////////////////////////////////////////////////////////////////////////
  /**	Parse fact type string to fact type int.
  */
  public static int ParseFactType(String str)
  {
    if (str.equalsIgnoreCase("event")||str.equalsIgnoreCase("clinical_event")) 
      return Fact.TYPE_CLINICAL_EVENT;
    else if (str.equalsIgnoreCase("diagnosis")) 
      return Fact.TYPE_DIAGNOSIS;
    else if (str.equalsIgnoreCase("implant_log")) 
      return Fact.TYPE_IMPLANT_LOG;
    else if (str.equalsIgnoreCase("medication")) 
      return Fact.TYPE_MEDICATION;
    else if (str.equalsIgnoreCase("med_history")) 
      return Fact.TYPE_MED_HISTORY;
    else if (str.equalsIgnoreCase("microbiology")) 
      return Fact.TYPE_MICROBIOLOGY;
    else if (str.equalsIgnoreCase("micro_susceptibility")) 
      return Fact.TYPE_MICRO_SUSCEPTIBILITY;
    else if (str.equalsIgnoreCase("lab")||str.equalsIgnoreCase("lab_procedure"))
      return Fact.TYPE_LAB_PROCEDURE;
    else if (str.equalsIgnoreCase("procedure")) 
      return Fact.TYPE_PROCEDURE;
    else if (str.equalsIgnoreCase("surgery")||str.equalsIgnoreCase("surgical_procedure")) 
      return Fact.TYPE_SURGICAL_PROCEDURE;
    else if (str.equalsIgnoreCase("surgical_case")) 
      return Fact.TYPE_SURGICAL_CASE;
    else if (str.equalsIgnoreCase("discharge")) 
      return Fact.TYPE_DISCHARGE;
    else if (str.equalsIgnoreCase("all")) 
      return Fact.TYPE_ALL;
    else
      return Fact.TYPE_UNKNOWN;
  }
  /////////////////////////////////////////////////////////////////////////////
  /**	Find all facts associated with specified patient IDs.
  */
  public static int AddFacts(DBCon dbcon, int ftype, List<Long> pids, FactList flist, int verbose)
        throws SQLException
  {
    int n_fact=0;
    if (ftype==Fact.TYPE_DIAGNOSIS || ftype==Fact.TYPE_ALL) 
      n_fact += AddFactsDiagnosis(dbcon, pids, flist, verbose);
    if (ftype==Fact.TYPE_MEDICATION || ftype==Fact.TYPE_ALL) 
      n_fact += AddFactsMedication(dbcon, pids, flist, verbose);
    if (ftype==Fact.TYPE_MED_HISTORY || ftype==Fact.TYPE_ALL) 
      n_fact += AddFactsMedHistory(dbcon, pids, flist, verbose);
    if (ftype==Fact.TYPE_LAB_PROCEDURE || ftype==Fact.TYPE_ALL) 
      n_fact += AddFactsLab(dbcon, pids, flist, verbose);
    if (ftype==Fact.TYPE_SURGICAL_PROCEDURE || ftype==Fact.TYPE_ALL) 
      n_fact += AddFactsSurgery(dbcon, pids, flist, verbose);
    if (ftype==Fact.TYPE_PROCEDURE || ftype==Fact.TYPE_ALL) 
      n_fact += AddFactsProcedure(dbcon, pids, flist, verbose);
    if (ftype==Fact.TYPE_CLINICAL_EVENT || ftype==Fact.TYPE_ALL) 
      n_fact += AddFactsClinicalEvent(dbcon, pids, flist, verbose);
    if (ftype==Fact.TYPE_DISCHARGE || ftype==Fact.TYPE_ALL) 
      n_fact += AddFactsDischarge(dbcon, pids, flist, verbose);

    Collections.sort(flist); //default sort by date
    return n_fact;
  }
  /////////////////////////////////////////////////////////////////////////////
  /**	Find all diagnosis facts associated with specified patient IDs.
  */
  public static int AddFactsDiagnosis(DBCon dbcon, List<Long> pids, FactList flist, int verbose)
        throws SQLException
  {
    String pids_str="";
    for (int i=0;i<pids.size();++i) pids_str+=(((i>0)?",":"")+pids.get(i));
    String sql=
       "SELECT DISTINCT\n"
             +"dd.diagnosis_id,\n"
             +"dd.diagnosis_code,\n"
             +"dd.diagnosis_type,\n"
             +"dd.diagnosis_description,\n"
             +"fe.encounter_id,\n"
             +"fe.patient_id,\n"
             +"fe.patient_type_id,\n"
             +"fe.age_in_years,\n"
             +"fe.hospital_id,\n"
             +"fe.admitted_dt_tm AS date\n"
      +"FROM\n"
              +"hf_f_diagnosis fd\n"
      +"JOIN\n"
              +"hf_f_encounter fe ON fd.encounter_id = fe.encounter_id\n"
      +"JOIN\n"
              +"hf_d_diagnosis dd ON fd.diagnosis_id = dd.diagnosis_id\n"
      +"JOIN\n"
              +"hf_d_diagnosis_type ddt ON fd.diagnosis_type_id = ddt.diagnosis_type_id\n"
      +"WHERE\n";

    if (dbcon.getDBType().equalsIgnoreCase("microsoft"))
      sql+="dd.diagnosis_code LIKE '[0-9][0-9][0-9].%'\nAND ";
    else if (dbcon.getDBType().equalsIgnoreCase("postgres"))
      sql+="dd.diagnosis_code SIMILAR TO '\\d\\d\\d\\.%'\nAND ";
    sql+="fe.patient_id IN ("+pids_str+")";
    //if (verbose>2) System.err.println("DEBUG: sql: "+sql);
    ResultSet rset=dbcon.executeSql(sql);
    int n_fact=0;
    while (rset.next())
    {
      java.util.Date date = rset.getDate("date");
      Fact f = new Fact(date, Fact.TYPE_DIAGNOSIS);
      f.setEncounterId(rset.getLong("encounter_id"));
      f.setPatientId(rset.getLong("patient_id"));
      f.setPatientTypeId(rset.getShort("patient_type_id"));
      f.setPatientAge(rset.getShort("age_in_years"));
      f.setInstanceId(rset.getInt("diagnosis_id"));
      f.setHospitalId(rset.getShort("hospital_id"));
      flist.add(f);
      ++n_fact;
    }
    rset.getStatement().close();
    return n_fact;
  }
  /////////////////////////////////////////////////////////////////////////////
  /**	Find all medication facts associated with specified patient IDs.
  */
  public static int AddFactsMedication(DBCon dbcon, List<Long> pids, FactList flist, int verbose)
        throws SQLException
  {
    String pids_str="";
    for (int i=0;i<pids.size();++i) pids_str+=(((i>0)?",":"")+pids.get(i));
    String sql=
       "SELECT DISTINCT\n"
             +"dm.medication_id,\n"
             +"dm.generic_name,\n"
             +"dm.brand_name,\n"
             +"dm.ndc_code,\n"
             +"fe.encounter_id,\n"
             +"fe.patient_id,\n"
             +"fe.patient_type_id,\n"
             +"fe.age_in_years,\n"
             +"fe.hospital_id,\n"
             +"fe.admitted_dt_tm AS date\n"
      +"FROM\n"
              +"hf_f_medication fm\n"
      +"JOIN\n"
              +"hf_f_encounter fe ON fm.encounter_id = fe.encounter_id\n"
      +"JOIN\n"
              +"hf_d_medication dm ON fm.medication_id = dm.medication_id\n"
      +"WHERE\n"
              +"fe.patient_id IN ("+pids_str+")";
    //if (verbose>2) System.err.println("DEBUG: sql: "+sql);
    ResultSet rset=dbcon.executeSql(sql);
    int n_fact=0;
    while (rset.next())
    {
      java.util.Date date = rset.getDate("date");
      Fact f = new Fact(date,Fact.TYPE_MEDICATION);
      f.setEncounterId(rset.getLong("encounter_id"));
      f.setPatientId(rset.getLong("patient_id"));
      f.setPatientTypeId(rset.getShort("patient_type_id"));
      f.setPatientAge(rset.getShort("age_in_years"));
      f.setInstanceId(rset.getInt("medication_id"));
      f.setHospitalId(rset.getShort("hospital_id"));
      flist.add(f);
      ++n_fact;
    }
    rset.getStatement().close();
    return n_fact;
  }
  /////////////////////////////////////////////////////////////////////////////
  /**	Find all medication history facts associated with specified patient IDs.
  */
  public static int AddFactsMedHistory(DBCon dbcon, List<Long> pids, FactList flist, int verbose)
        throws SQLException
  {
    String pids_str="";
    for (int i=0;i<pids.size();++i) pids_str+=(((i>0)?",":"")+pids.get(i));
    String sql=
       "SELECT DISTINCT\n"
             +"dmp.med_product_id,\n"
             +"dmp.drug_code,\n"
             +"dmp.drug_mnemonic_code,\n"
             +"dmp.drug_desc,\n"
             +"dmp.drug_mnemonic_desc,\n"
             +"fe.encounter_id,\n"
             +"fe.patient_id,\n"
             +"fe.patient_type_id,\n"
             +"fe.age_in_years,\n"
             +"fe.hospital_id,\n"
             +"fe.admitted_dt_tm AS date\n"
      +"FROM\n"
              +"hf_f_med_history fmh\n"
      +"JOIN\n"
              +"hf_f_encounter fe ON fmh.encounter_id = fe.encounter_id\n"
      +"JOIN\n"
              +"hf_d_med_product dmp ON fmh.med_product_id = dmp.med_product_id\n"
      +"WHERE\n"
              +"fe.patient_id IN ("+pids_str+")";
    //if (verbose>2) System.err.println("DEBUG: sql: "+sql);
    ResultSet rset=dbcon.executeSql(sql);
    int n_fact=0;
    while (rset.next())
    {
      java.util.Date date = rset.getDate("date");
      Fact f = new Fact(date, Fact.TYPE_MEDICATION);
      f.setEncounterId(rset.getLong("encounter_id"));
      f.setPatientId(rset.getLong("patient_id"));
      f.setPatientTypeId(rset.getShort("patient_type_id"));
      f.setPatientAge(rset.getShort("age_in_years"));
      f.setInstanceId(rset.getInt("med_product_id"));
      f.setHospitalId(rset.getShort("hospital_id"));
      flist.add(f);
      ++n_fact;
    }
    rset.getStatement().close();
    return n_fact;
  }
  /////////////////////////////////////////////////////////////////////////////
  /**	Find all lab facts associated with specified patient IDs.
	Slow!  93min for one pid, Jan 2016.
  */
  public static int AddFactsLab(DBCon dbcon, List<Long> pids, FactList flist, int verbose)
        throws SQLException
  {
    String pids_str="";
    for (int i=0;i<pids.size();++i) pids_str+=(((i>0)?",":"")+pids.get(i));
    String sql=
       "SELECT DISTINCT\n"
             +"dlp.lab_procedure_id,\n"
             +"dlp.lab_procedure_name,\n"
             +"dlp.lab_procedure_mnemonic,\n"
             +"dlp.lab_procedure_group,\n"
             +"dlp.lab_super_group,\n"
             +"dlp.loinc_code,\n"
	     +"flp.numeric_result,\n"
	     +"flp.result_units_id,\n"
	     +"du.unit_display,\n"
	     +"du.unit_desc,\n"
             +"fe.encounter_id,\n"
             +"fe.patient_id,\n"
             +"fe.patient_type_id,\n"
             +"fe.age_in_years,\n"
             +"fe.hospital_id,\n"
             +"fe.admitted_dt_tm AS date\n"
      +"FROM\n"
             +"hf_f_lab_procedure flp\n"
      +"JOIN\n"
             +"hf_f_encounter fe ON flp.encounter_id = fe.encounter_id\n"
      +"JOIN\n"
             +"hf_d_unit du ON flp.result_units_id = du.unit_id\n"
      +"JOIN\n"
             +"hf_d_lab_procedure dlp ON dlp.lab_procedure_id = flp.detail_lab_procedure_id\n"
      +"WHERE\n"
             +"fe.patient_id IN ("+pids_str+")";
    //if (verbose>2) System.err.println("DEBUG: sql: "+sql);
    ResultSet rset=dbcon.executeSql(sql);
    int n_fact=0;
    while (rset.next())
    {
      java.util.Date date = rset.getDate("date");
      Fact f = new Fact(date, Fact.TYPE_LAB_PROCEDURE);
      f.setEncounterId(rset.getLong("encounter_id"));
      f.setPatientId(rset.getLong("patient_id"));
      f.setPatientTypeId(rset.getShort("patient_type_id"));
      f.setPatientAge(rset.getShort("age_in_years"));
      f.setInstanceId(rset.getInt("lab_procedure_id"));
      f.setHospitalId(rset.getShort("hospital_id"));
      f.setResult(rset.getFloat("numeric_result"));
      f.setResultUnits(rset.getString("unit_display"));
      flist.add(f);
      ++n_fact;
    }
    rset.getStatement().close();
    return n_fact;
  }
  /////////////////////////////////////////////////////////////////////////////
  public static int AddFactsClinicalEvent(DBCon dbcon, List<Long> pids, FactList flist, int verbose)
        throws SQLException
  {
    String pids_str="";
    for (int i=0;i<pids.size();++i) pids_str+=(((i>0)?",":"")+pids.get(i));
    String sql=
       "SELECT DISTINCT\n"
             +"fce.event_code_id,\n"
             +"dec.event_code_desc,\n"
             +"dec.event_code_display,\n"
             +"dec.event_code_group,\n"
             +"dec.event_code_category,\n"
             +"fce.result_value_num,\n"
	     +"fce.result_units_id,\n"
	     +"du.unit_display,\n"
	     +"du.unit_desc,\n"
             +"fe.encounter_id,\n"
             +"fe.patient_id,\n"
             +"fe.patient_type_id,\n"
             +"fe.age_in_years,\n"
             +"fe.hospital_id,\n"
             +"fe.admitted_dt_tm AS date\n"
      +"FROM\n"
             +"hf_f_clinical_event fce\n"
      +"JOIN\n"
              +"hf_d_event_code dec ON dec.event_code_id = fce.event_code_id\n"
      +"JOIN\n"
              +"hf_d_unit du ON du.unit_id = fce.result_units_id\n"
      +"JOIN\n"
             +"hf_f_encounter fe ON fce.encounter_id = fe.encounter_id\n"
      +"WHERE\n"
             +"fe.patient_id IN ("+pids_str+")";
    ResultSet rset=dbcon.executeSql(sql);
    int n_fact=0;
    while (rset.next())
    {
      java.util.Date date = rset.getDate("date");
      Fact f = new Fact(date, Fact.TYPE_CLINICAL_EVENT);
      f.setEncounterId(rset.getLong("encounter_id"));
      f.setPatientId(rset.getLong("patient_id"));
      f.setPatientTypeId(rset.getShort("patient_type_id"));
      f.setPatientAge(rset.getShort("age_in_years"));
      f.setInstanceId(rset.getInt("event_code_id"));
      f.setHospitalId(rset.getShort("hospital_id"));
      f.setResult(rset.getFloat("result_value_num"));
      f.setResultUnits(rset.getString("unit_display"));
      flist.add(f);
      ++n_fact;
    }
    rset.getStatement().close();
    return n_fact;
  }
  /////////////////////////////////////////////////////////////////////////////
  public static int AddFactsSurgery(DBCon dbcon, List<Long> pids, FactList flist, int verbose)
        throws SQLException
  {
    String pids_str="";
    for (int i=0;i<pids.size();++i) pids_str+=(((i>0)?",":"")+pids.get(i));
    String sql=
       "SELECT DISTINCT\n"
             +"dsp.surgical_procedure_id,\n"
             +"dsp.surgical_procedure_desc,\n"
             +"dsp.anatomic_site,\n"
             +"dsp.order_specialty,\n"
             +"dsp.icd9_code,\n"
             +"fe.encounter_id,\n"
             +"fe.patient_id,\n"
             +"fe.patient_type_id,\n"
             +"fe.age_in_years,\n"
             +"fe.hospital_id,\n"
             +"fe.admitted_dt_tm AS date\n"
      +"FROM\n"
             +"hf_f_surgical_procedure fsp\n"
      +"JOIN\n"
              +"hf_d_surgical_procedure dsp ON fsp.surgical_procedure_id = dsp.surgical_procedure_id\n"
      +"JOIN\n"
             +"hf_f_encounter fe ON fsp.encounter_id = fe.encounter_id\n"
      +"WHERE\n"
             +"fe.patient_id IN ("+pids_str+")";
    ResultSet rset=dbcon.executeSql(sql);
    int n_fact=0;
    while (rset.next())
    {
      java.util.Date date = rset.getDate("date");
      Fact f = new Fact(date,Fact.TYPE_SURGICAL_PROCEDURE);
      f.setEncounterId(rset.getLong("encounter_id"));
      f.setPatientId(rset.getLong("patient_id"));
      f.setPatientTypeId(rset.getShort("patient_type_id"));
      f.setPatientAge(rset.getShort("age_in_years"));
      f.setInstanceId(rset.getInt("surgical_procedure_id"));
      f.setHospitalId(rset.getShort("hospital_id"));
      flist.add(f);
      ++n_fact;
    }
    rset.getStatement().close();
    return n_fact;
  }
  /////////////////////////////////////////////////////////////////////////////
  public static int AddFactsProcedure(DBCon dbcon, List<Long> pids, FactList flist, int verbose)
        throws SQLException
  {
    String pids_str="";
    for (int i=0;i<pids.size();++i) pids_str+=(((i>0)?",":"")+pids.get(i));
    String sql=
       "SELECT DISTINCT\n"
             +"dp.procedure_id,\n"
             +"dp.procedure_type,\n"
             +"dp.procedure_code,\n"
             +"dp.procedure_description,\n"
             +"fe.encounter_id,\n"
             +"fe.patient_id,\n"
             +"fe.patient_type_id,\n"
             +"fe.age_in_years,\n"
             +"fe.hospital_id,\n"
             +"fe.admitted_dt_tm AS date\n"
      +"FROM\n"
             +"hf_f_procedure fp\n"
      +"JOIN\n"
              +"hf_d_procedure dp ON fp.procedure_id = dp.procedure_id\n"
      +"JOIN\n"
             +"hf_f_encounter fe ON fp.encounter_id = fe.encounter_id\n"
      +"WHERE\n"
             +"fe.patient_id IN ("+pids_str+")";
    ResultSet rset=dbcon.executeSql(sql);
    int n_fact=0;
    while (rset.next())
    {
      java.util.Date date = rset.getDate("date");
      Fact f = new Fact(date, Fact.TYPE_SURGICAL_PROCEDURE);
      f.setEncounterId(rset.getLong("encounter_id"));
      f.setPatientId(rset.getLong("patient_id"));
      f.setPatientTypeId(rset.getShort("patient_type_id"));
      f.setPatientAge(rset.getShort("age_in_years"));
      f.setInstanceId(rset.getInt("procedure_id"));
      f.setHospitalId(rset.getShort("hospital_id"));
      flist.add(f);
      ++n_fact;
    }
    rset.getStatement().close();
    return n_fact;
  }
  /////////////////////////////////////////////////////////////////////////////
  public static int AddFactsDischarge(DBCon dbcon, List<Long> pids, FactList flist, int verbose)
        throws SQLException
  {
    String pids_str="";
    for (int i=0;i<pids.size();++i) pids_str+=(((i>0)?",":"")+pids.get(i));
    String sql=
       "SELECT DISTINCT\n"
             +"ddd.dischg_disp_id,\n"
             +"ddd.dischg_disp_code,\n"
             +"ddd.dischg_disp_code_desc,\n"
             +"fe.encounter_id,\n"
             +"fe.patient_id,\n"
             +"fe.patient_type_id,\n"
             +"fe.age_in_years,\n"
             +"fe.hospital_id,\n"
             +"fe.discharged_dt_tm AS date\n"
      +"FROM\n"
              +"hf_d_dischg_disp ddd\n"
      +"JOIN\n"
             +"hf_f_encounter fe ON ddd.dischg_disp_id = fe.discharge_disposition_id\n"
      +"WHERE\n"
             +"fe.patient_id IN ("+pids_str+")";
    ResultSet rset=dbcon.executeSql(sql);
    int n_fact=0;
    while (rset.next())
    {
      java.util.Date date = rset.getDate("date");
      Fact f = new Fact(date, Fact.TYPE_DISCHARGE);
      f.setEncounterId(rset.getLong("encounter_id"));
      f.setPatientId(rset.getLong("patient_id"));
      f.setPatientTypeId(rset.getShort("patient_type_id"));
      f.setPatientAge(rset.getShort("age_in_years"));
      f.setHospitalId(rset.getShort("hospital_id"));
      f.setInstanceId(rset.getInt("dischg_disp_code"));
      flist.add(f);
      ++n_fact;
    }
    rset.getStatement().close();
    return n_fact;
  }
}
