package gov.lanl.burk.gene;

import java.util.*;
import gov.lanl.burk.util.*;
import gov.lanl.burk.gene.Gene;

/*********************************************************************************************************************************************************

Author - Sindhu Vijaya Raghavan


***********************************************************************************************************************************************************/



public class PredictedGene
{

	Gene gene =null; //entire Gene object
	boolean isProdigalStart; //indicates if the prodigal start was accepted
	long alignmentPos = -1; // start position in the alignment
	long relStartPos = -1; //start position after gaps in the alignment are removed i.e start position in the sequence fed as input to MSA
	long absoluteStartPos = -1; //start position in the original dna segment
	double score=0.0; //score corresponding to the start pos
	long prodigalStartPosInAlignment = -1;

	public PredictedGene()
	{


	}

	public void setGeneObj(Gene iGene)
	{
		gene = iGene;
		
	}

	public Gene getGeneObj()
	{

		return gene;
	}
	
	public void setIsProdigalStart(boolean iBool)
	{
		isProdigalStart = iBool;
	}

	public boolean getIsProdigalStart()
	{
		return isProdigalStart;
	}

	public void setAlignmentPos(long iPos)
	{
		alignmentPos = iPos;
	}

	public long getAlignmentPos()
	{
		return alignmentPos;
	}

	public void setRelStartPos(long iPos)
	{
		relStartPos = iPos;
	}

	public long getRelStartPos()
	{
		return relStartPos;
	}

	public void setAbsoluteStartPos(long iPos)
	{

		absoluteStartPos = iPos;
	}

	public long getAbsoluteStartPos()
	{
		return absoluteStartPos;
	}

	public void setScore(double iScore)
	{
		score = iScore;
	}

	public double getScore()
	{
		return score;
	}

	public void setProdigalStartPosInAlignment(long iPos)
	{
		prodigalStartPosInAlignment = iPos;
	}
	
	public long getProdigalStartPosInAlignment()
	{

		return prodigalStartPosInAlignment;
	}

}
