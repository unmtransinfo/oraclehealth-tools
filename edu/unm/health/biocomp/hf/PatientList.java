package edu.unm.health.biocomp.hf;

import java.io.*;
import java.util.*;

/**	Container for a list of patients.

	@author Jeremy J Yang
*/
public class PatientList
	extends ArrayList<Patient>
{
  public PatientList() {}

  /////////////////////////////////////////////////////////////////////////////
  /**
	@param	gender	patient gender (may be unknown)
	@return	newly allocated subset PatientList
  */
  public PatientList selectByGender(short gender)
  {
    PatientList pl = new PatientList();
    for (Patient p: this)
      if (p.getGender()==gender)
        pl.add(p);
    return pl;
  }
  /////////////////////////////////////////////////////////////////////////////
}
