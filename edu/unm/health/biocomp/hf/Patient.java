package edu.unm.health.biocomp.hf;

import java.io.*;
import java.util.*;

/**	A HF patient.

	@author Jeremy J Yang
*/
public class Patient
	implements Comparable<Object>
{
  public static final short GENDER_FEMALE=1;
  public static final short GENDER_MALE=2;
  public static final short GENDER_OTHER=3;
  public static final short GENDER_UNKNOWN=0;

  public static final short RACE_AFRICAN_AMERICAN=1;
  public static final short RACE_ASIAN=2;
  public static final short RACE_BIRACIAL=3;
  public static final short RACE_CAUCASIAN=4;
  public static final short RACE_NATIVE_AMERICAN=5;
  public static final short RACE_PACIFIC_ISLANDER=6;
  public static final short RACE_OTHER=7;
  public static final short RACE_UNKNOWN=0;

  private long sk;
  private short gender;
  private short race;
  private FactList flist;
  private ArrayList<Long> pids;

  private Patient() {} //disallow default constructor
  public Patient(long _sk)
  {
    this.sk = _sk;
    this.gender = 0;
    this.race = 0;
    this.flist = new FactList();
    this.pids = new ArrayList<Long>();
  }
  public Patient(long _sk,short _gender,short _race)
  {
    this.sk = _sk;
    this.gender = _gender;
    this.race = _race;
    this.flist = new FactList();
    this.pids = new ArrayList<Long>();
  }

  public long getSk() { return this.sk; }
  public void setSk(long _sk) { this.sk = _sk; }
  public FactList getFactList() { return this.flist; }
  public void setFactList(FactList _flist) { this.flist = _flist; }

  public short getGender() { return this.gender; }
  public void setGender(short _gender) { this.gender = _gender; }
  public void setGender(String s)
  {
    if (s.equalsIgnoreCase("Female")) this.gender = Patient.GENDER_FEMALE;
    else if (s.equalsIgnoreCase("Male")) this.gender = Patient.GENDER_MALE;
  }
  public String getGenderStr()
  {
    return (this.gender==GENDER_FEMALE)?"Female":
           (this.gender==GENDER_MALE)?"Male":
           (this.gender==GENDER_OTHER)?"Other":"Unknown";
  }
  public short getRace() { return this.race; }
  public void setRace(short _race) { this.race = _race; }
  public void setRace(String s)
  {
    if (s.equalsIgnoreCase("African American")) this.race = Patient.RACE_AFRICAN_AMERICAN;
    else if (s.equalsIgnoreCase("Asian")) this.race = Patient.RACE_ASIAN;
    else if (s.equalsIgnoreCase("Biracial")) this.race = Patient.RACE_BIRACIAL;
    else if (s.equalsIgnoreCase("Caucasian")) this.race = Patient.RACE_CAUCASIAN;
    else if (s.equalsIgnoreCase("Native American")) this.race = Patient.RACE_NATIVE_AMERICAN;
    else if (s.equalsIgnoreCase("Pacific Islander")) this.race = Patient.RACE_PACIFIC_ISLANDER;
    else if (s.equalsIgnoreCase("Other")) this.race = Patient.RACE_OTHER;
  }
  public String getRaceStr()
  {
    return (this.race==RACE_AFRICAN_AMERICAN)?"African American":
           (this.race==RACE_ASIAN)?"Asian":
           (this.race==RACE_BIRACIAL)?"Biracial":
           (this.race==RACE_CAUCASIAN)?"Caucasian":
           (this.race==RACE_NATIVE_AMERICAN)?"Native American":
           (this.race==RACE_PACIFIC_ISLANDER)?"Pacific Islander":
           (this.race==RACE_OTHER)?"Other":"Unknown";
  }

  public List<Long> getPatientIds() { return this.pids; }
  public void addPatientId(long _pid) { this.pids.add(_pid); }
  public void clearIds() { this.pids.clear(); }
  public int getPatientIdCount() { return this.pids.size(); }

  public boolean hasExpired()
  {
    boolean exp = false;
    FactList fs = this.getFactList().selectByType(Fact.TYPE_DISCHARGE);
    if (fs.size()==0) System.err.println("DEBUG: no discharge facts known.");
    for (Fact f: fs)
    {
      if (f.getInstanceId() == 20
          ||f.getInstanceId() == 40
          ||f.getInstanceId() == 41
          ||f.getInstanceId() == 42) exp=true;
    }
    return exp;
  }
  public Date expiredDate()
  {
    Date d = null;
    FactList fs = this.getFactList().selectByType(Fact.TYPE_DISCHARGE);
    if (fs.size()==0) System.err.println("DEBUG: no discharge facts known.");
    for (Fact f: fs)
    {
      if (f.getInstanceId() == 20
          ||f.getInstanceId() == 40
          ||f.getInstanceId() == 41
          ||f.getInstanceId() == 42)
      d = f.getDate();
    }
    return d;
  }

  /////////////////////////////////////////////////////////////////////////////
  public int compareTo(Object o)        //native-order (by SK)
  {
    return ((Long)(this.getSk())).compareTo((Long)(((Patient)o).getSk()));
  }
}
