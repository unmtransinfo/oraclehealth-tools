package edu.unm.health.biocomp.cerner.hf;

//import java.io.*;
import java.util.*;

/**	A HF fact has a date, a specific type, and is associated with an encounter.

	@author Jeremy J Yang
*/
public class Fact
	implements Comparable<Object>
{
  public static final short TYPE_CLINICAL_EVENT = 1;
  public static final short TYPE_DIAGNOSIS = 2;
  public static final short TYPE_IMPLANT_LOG = 3;
  public static final short TYPE_LAB_PROCEDURE = 4;
  public static final short TYPE_MEDICATION = 5;
  public static final short TYPE_MED_HISTORY = 6;
  public static final short TYPE_MICROBIOLOGY = 7;
  public static final short TYPE_MICRO_SUSCEPTIBILITY = 8;
  public static final short TYPE_PROCEDURE = 9;
  public static final short TYPE_SURGICAL_CASE = 10;
  public static final short TYPE_SURGICAL_PROCEDURE = 11;
  public static final short TYPE_DISCHARGE = 12;
  public static final short TYPE_ALL = 100; //Pseudo-type
  public static final short TYPE_UNKNOWN = 0;

  private Date date;
  private short type;
  private int instance_id; //instance of specified type, e.g. medication_id
  private long eid; //encounter_id
  private long pid; //patient_id
  private short ptype; //patients can change type (in/out), hence an encounter property (patient_type_id)
  private short page; //patient age at time of encounter (age_in_years)
  private short hosp; //hospital ID
  private Float result; //clinical event result (e.g. height)
  private String result_units; //clinical event result units (e.g. cm)

  private Fact() {} //disallow default constructor
  public Fact(Date _date,short _type)
  {
    this.date = _date;
    this.type = _type;
  }
  public Fact(Date _date,short _type,int _instance_id,long _eid,long _pid)
  {
    this.date = _date;
    this.type = _type;
    this.instance_id = _instance_id;
    this.eid = _eid;
    this.pid = _pid;
  }

  public Date getDate() { return this.date; }
  public String getDateStr()
  {
    Calendar cal=Calendar.getInstance();
    if (this.date==null) return null;
    cal.setTime(this.date);
    return String.format("%04d-%02d-%02d", cal.get(Calendar.YEAR), cal.get(Calendar.MONTH)+1, cal.get(Calendar.DAY_OF_MONTH));
  }
  public void setDate(Date _date) { this.date = _date; }
  public void setType(short _type) { this.type = _type; }
  public short getType() { return this.type; }
  public String getTypeStr()
  {
    return (this.type==TYPE_CLINICAL_EVENT)?"CE":
           (this.type==TYPE_DIAGNOSIS)?"D":
           (this.type==TYPE_IMPLANT_LOG)?"IL":
           (this.type==TYPE_LAB_PROCEDURE)?"LP":
           (this.type==TYPE_MEDICATION)?"M":
           (this.type==TYPE_MED_HISTORY)?"MH":
           (this.type==TYPE_MICROBIOLOGY)?"MB":
           (this.type==TYPE_MICRO_SUSCEPTIBILITY)?"MS":
           (this.type==TYPE_PROCEDURE)?"P":
           (this.type==TYPE_SURGICAL_CASE)?"SC":
           (this.type==TYPE_SURGICAL_PROCEDURE)?"SP":
           (this.type==TYPE_DISCHARGE)?"DC":""
	;
  }
  public int getInstanceId() { return this.instance_id; }
  public void setInstanceId(int _instance_id) { this.instance_id = _instance_id; }
  public short getPatientTypeId() { return this.ptype; }
  public void setPatientTypeId(short _ptype) { this.ptype = _ptype; }
  public short getPatientAge() { return this.page; }
  public void setPatientAge(short _page) { this.page = _page; }
  public long getEncounterId() { return this.eid; }
  public void setEncounterId(long _eid) { this.eid = _eid; }
  public long getPatientId() { return this.pid; }
  public void setPatientId(long _pid) { this.pid = _pid; }
  public void setHospitalId(short _hosp) { this.hosp = _hosp; }
  public short getHospitalId() { return this.hosp; }
  public void setResult(Float _r) { this.result = _r; }
  public Float getResult() { return this.result; }
  public void setResultUnits(String _u) { this.result_units = _u; }
  public String getResultUnits() { return this.result_units; }

  /////////////////////////////////////////////////////////////////////////////
  public int compareTo(Object o)        //native-order (by date)
  {
    if (this.getDate()==null && (Date)(((Fact)o).getDate())!=null) return -1;
    else if (this.getDate()!=null && (Date)(((Fact)o).getDate())==null) return 1;
    else if (this.getDate()==null && (Date)(((Fact)o).getDate())==null) return 0;
    return ((Date)(this.getDate())).compareTo((Date)(((Fact)o).getDate()));
  }
}
