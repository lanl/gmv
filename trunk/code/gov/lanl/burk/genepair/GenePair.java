package gov.lanl.burk.genepair;


/*********************************************************************************************************************************************************

Author - Sindhu Vijaya Raghavan


***********************************************************************************************************************************************************/

public class GenePair
{

	String queryGene=null;
	String dbGene = null;
	double stdIDScore =0.0;

	public GenePair()
	{

	}
	
	public GenePair(String iQueryGene,String iDBGene,double iScore)
	{
		queryGene = iQueryGene;
		dbGene = iDBGene;
		stdIDScore = iScore;
	}
	
	public void setQueryGene(String iQueryGene)
	{

		queryGene = iQueryGene;
	}
	
	public String getQueryGene()
	{
		return queryGene;
	}
	public void setDBGene(String iDBGene)
	{
		dbGene = iDBGene;
	}

	public String getDBGene()
	{
		return dbGene;
	}

	public void setScore(double iScore)
	{
		stdIDScore = iScore;
	}
	public double getScore()
	{
		return stdIDScore;
	}

	public String toString()
	{
		String returnStr = queryGene+"|"+dbGene+","+stdIDScore;
		return returnStr;
	}


}