package gov.lanl.burk.ortholog;

import java.util.*;
import gov.lanl.burk.util.*;


/*********************************************************************************************************************************************************

Author - Sindhu Vijaya Raghavan


***********************************************************************************************************************************************************/

public class Ortholog
{


	Vector orthologSet;
	double avgScore;
	String refGene;
	int numProdigalStarts;
	long alignPos;

	public Ortholog()
	{

	}

	public void setOrthologSet(Vector iSet)
	{

		orthologSet = iSet;
	}

	public Vector getOrthologSet()
	{
		return orthologSet;
	}

	public void setScore(double iScore)
	{
		avgScore = iScore;
	}

	public double getScore()
	{
		return avgScore;
	}

	public void setRefGene(String iGene)
	{
		refGene = iGene;
	}
	
	public String getRefGene()
	{
	
		return refGene;
	}

	public void setNumProdigalStarts(int iNum)
	{
		numProdigalStarts = iNum;

	}

	public int getNumProdigalStarts()
	{
		return numProdigalStarts;
	}

	public void setAlignPos(long iPos)
	{
		alignPos = iPos;
	}

	public long getAlignPos()
	{
		return alignPos;
	}



	public void display()
	{
		System.out.println("\nDisplaying ortholog set");
		System.out.println("Ref gene :: "+refGene);	
		System.out.println("Avg Score :: "+avgScore);
		System.out.println("Number of prodigal starts:: "+numProdigalStarts);
		System.out.println("Alignment pos :: "+alignPos);
		//System.out.println("Ortholog set :: "+orthologSet);

	}
}
