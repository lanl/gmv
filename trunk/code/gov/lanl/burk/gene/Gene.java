package gov.lanl.burk.gene;

import java.util.*;
import gov.lanl.burk.util.*;


/*********************************************************************************************************************************************************

Author - Sindhu Vijaya Raghavan


***********************************************************************************************************************************************************/


public class Gene
{

	int POS_DIR = 1;
	int NEG_DIR = -1;
	String geneName;
	long startPos;
	long endPos;
	int direction; 
	long segStart;
	long segEnd;
	Vector possibleStarts =null;
	Vector totalScores = null;
	Vector relativeStarts = null;
	long relStartPos;
	long relEndPos;	
	
	
	public Gene()
	{
		

	}
	
	public void setGeneName(String iName)
	{
		geneName = iName;

	}
	public String getGeneName()
	{
		return geneName;
	}

	public void setStartPos(long iPos)
	{
		startPos = iPos;
	}

	public long getStartPos()
	{
		return startPos;
	}

	public void setEndPos(long iPos)
	{
		endPos = iPos;
	}

	public long getEndPos()
	{
		return endPos;
	}

	public void setDir(String iDir)
	{
		if(iDir!=null)
		{	
			if("-1".equals(iDir))
			{
				direction = NEG_DIR;
			}
			else
			{
				direction = POS_DIR;
			}

		}
		else
		{

			direction = POS_DIR;
		}

	}

	public int getDir()
	{
		return direction;

	}

	public void setSegStart(long iPos)
	{
		segStart = iPos;

	}

	public long getSegStart()
	{

		return segStart;
	}

	public void setSegEnd(long iPos)
	{
		segEnd = iPos;
	}

	public long getSegEnd()
	{

		return segEnd;
	}

	public void setPossibleStarts(Vector iStarts)
	{

		possibleStarts = iStarts;
	}

	public Vector getPossibleStarts()
	{
		return possibleStarts;
	}

	public void setTotalScores(Vector iScores)
	{

		totalScores = iScores;
	}
	
	public Vector getTotalScores()
	{

		return totalScores;
	}

	public void setRelativeStarts(Vector iRelStarts)
	{
		relativeStarts = iRelStarts;

	}
	public Vector getRelativeStarts()
	{
		return relativeStarts;

	}

	public void setRelStartPos(long iPos)
	{
		relStartPos = iPos;
	}

	public long getRelStartPos()
	{
		return relStartPos;
	}

	public void setRelEndPos(long iPos)
	{
		relEndPos = iPos;
	}

	public long getRelEndPos()
	{
		return relEndPos;
	}


	public void computeRelativeStartPos()
	{


		if(possibleStarts!=null)
		{

			relativeStarts = new Vector();

			if(direction == POS_DIR)	
			{


				for(int i=0;i<possibleStarts.size();i++)
				{
					long pos = ((Long)possibleStarts.get(i)).longValue();
					long relPos = pos - segStart + 1;					
					Long relPosObj = new Long(relPos);
					relativeStarts.add(i,relPosObj);
		
					//compute relative start and end pos
					relStartPos = startPos - segStart + 1;
					relEndPos = endPos - segStart + 1;

					
				}

			}
			if(direction == NEG_DIR)
			{
				for(int i=0;i<possibleStarts.size();i++)
				{
					long pos = ((Long)possibleStarts.get(i)).longValue();
					long relPos = segEnd - pos + 1;
					Long relPosObj = new Long(relPos);
					relativeStarts.add(i,relPosObj);

					//compute relative start and end pos
					relStartPos = segEnd - startPos + 1;
					relEndPos = segEnd - endPos + 1;


				}

	


			}
			
		}
	}


	public void display()
	{


		System.out.println("\nGene Name :: "+geneName);
		System.out.println("Prodigal Start :: "+startPos);
		System.out.println("Prodigal End :: "+endPos);
		System.out.println("Direction :: "+direction);
		System.out.println("Segment start :: "+segStart);
		System.out.println("Segment end :: "+segEnd);
		System.out.println("Total Scores :: "+totalScores);
		System.out.println("Possible Starts :: "+possibleStarts);
		System.out.println("Relative Starts :: "+relativeStarts);
		System.out.println("Relative Start :: "+relStartPos);	
		System.out.println("Relative End :: "+relEndPos);
		

	}
		

}
