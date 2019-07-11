package edu.unm.health.biocomp.hf;

import java.io.*;
import java.util.*;

/**	Container for a list of facts.

	@author Jeremy J Yang
*/
public class FactList
	extends ArrayList<Fact>
{
  public FactList() {}

  /////////////////////////////////////////////////////////////////////////////
  /**
	@param	type	fact type
	@return	newly allocated subset fact list
  */
  public FactList selectByType(int type)
  {
    FactList fl = new FactList();
    for (Fact f: this)
      if (f.getType()==type)
        fl.add(f);
    return fl;
  }
  /////////////////////////////////////////////////////////////////////////////
  public FactList selectByDate(Date mindate,Date maxdate)
  {
    FactList fl = new FactList();
    for (Fact f: this)
    {
      if (mindate!=null && f.getDate().compareTo(mindate)<0) continue;
      else if (maxdate!=null && f.getDate().compareTo(maxdate)>0) continue;
      else fl.add(f);
    }
    return fl;
  }
  /////////////////////////////////////////////////////////////////////////////
  public FactList selectByPatientId(long pid)
  {
    FactList fl = new FactList();
    for (Fact f: this)
      if (f.getPatientId()==pid)
        fl.add(f);
    return fl;
  }
}
