package gov.lanl.burk.ortholog;

import java.util.*;
import gov.lanl.burk.util.*;


/*********************************************************************************************************************************************************

Author - Sindhu Vijaya Raghavan


***********************************************************************************************************************************************************/

public class OrthologStatistic
{

	String refGene=null;
	double minPercentId=0.0;
	double maxPercentId = 0.0;
	double avgPercentId = 0.0;	
	double stdDevPercentId = 0.0;
	int numProdigalStarts =-1;
	int numCorrections = -1;

	public OrthologStatistic()
	{


	}

	public void setRefGene(String iName)
	{
		refGene = iName;
	}

	public String getRefGene()
	{
		return refGene;
	}

	public void setMinPercentId(double iMin)
	{
		minPercentId = iMin;
	}

	public double getMinPercentId()
	{
		return minPercentId;
	}

	public void setMaxPercentId(double iMax)
	{
		maxPercentId = iMax;
	}
	
	public double getMaxPercentId()
	{
		return maxPercentId;
	}

	public void setAvgPercentId(double iAvg)
	{
		avgPercentId = iAvg;
	}

	public double getAvgPercentId()
	{

		return avgPercentId;
	}
	
	public void setStdDev(double iStdDev)
	{
		stdDevPercentId = iStdDev;
	}

	public double getStdDev()
	{
		return stdDevPercentId;
	}

	public void setNumProdigalStarts(int iNum)
	{
		numProdigalStarts = iNum;
	}

	public int getNumProdigalStarts()
	{
		return numProdigalStarts;
	}
	
	public void setNumCorrections(int iNum)
	{

		numCorrections = iNum;
	}

	public int getNumCorrections()
	{

		return numCorrections;
	}

	public String getDisplayString()
	{
		String str = refGene + "\t" + Framework.roundTwoDecimals(minPercentId) + "\t" + Framework.roundTwoDecimals(maxPercentId) + "\t" + Framework.roundTwoDecimals(avgPercentId) + "\t" + Framework.roundTwoDecimals(stdDevPercentId) + "\t" + numProdigalStarts + "\t" + numCorrections;

		return str;

	}

}