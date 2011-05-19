package gov.lanl.burk.ortholog;

import java.io.BufferedWriter;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.*;
import java.util.*;
import gov.lanl.burk.util.*;
import gov.lanl.burk.gene.*;
import gov.lanl.burk.ortholog.*;


/*********************************************************************************************************************************************************

Author - Sindhu Vijaya Raghavan


***********************************************************************************************************************************************************/

public class FeatureFile
{
	Ortholog orthologSet =null;

	public FeatureFile()
	{

	}

	public FeatureFile(Ortholog iObj)
	{
		orthologSet = iObj;
	}

	public void setOrthologSet(Ortholog iObj)
	{

		orthologSet = iObj;
	}

	public Ortholog getOrthologSet()
	{

		return orthologSet;
	}

	public void createFeatureFile(String file)
	{
		if(file!=null && orthologSet!=null)
		{	
			try
			{
			        BufferedWriter out = new BufferedWriter(new FileWriter(file));
			        
				out.write("Prodigal\t0000ff\n");	
				out.write("Corrected\tff0000\n\n");
				out.write("PossibleStart\t99CC00\n");

				Vector orthologs = orthologSet.getOrthologSet();
				if(orthologs!=null)
				{

					for(int i=0;i<orthologs.size();i++)
					{
						PredictedGene pGene = (PredictedGene)orthologs.get(i);
						if(pGene!=null)
						{
							Gene gene = (Gene)pGene.getGeneObj();
							if(gene!=null)
							{

								//check the direction
								String geneName = gene.getGeneName();
								int dir = gene.getDir();
								boolean isProdigalStart = pGene.getIsProdigalStart();

								long alignmentBeg = -1;
								long alignmentEnd = -1;
								long prodigalBeg = -1;
								long prodigalEnd = -1;
	
								if(dir == -1)
								{
									alignmentBeg = pGene.getRelStartPos();
									alignmentEnd = alignmentBeg + 2;
									prodigalBeg = gene.getRelEndPos();
									prodigalEnd = prodigalBeg + 2;
								}
								else
								{
									alignmentBeg = pGene.getRelStartPos();
									alignmentEnd = alignmentBeg + 2;
									prodigalBeg = gene.getRelStartPos();
									prodigalEnd = prodigalBeg + 2;
								}

								
								
								if(isProdigalStart)
								{
									out.write(geneName+"\t"+geneName+"\t-1\t"+prodigalBeg+"\t"+prodigalEnd+"\tProdigal\n");

								}
								else
								{
									out.write(geneName+"\t"+geneName+"\t-1\t"+prodigalBeg+"\t"+prodigalEnd+"\tProdigal\n");
									out.write(geneName+"\t"+geneName+"\t-1\t"+alignmentBeg+"\t"+alignmentEnd+"\tCorrected\n");
								}

								// display all possible starts
								Vector allPossiStarts = gene.getRelativeStarts();

								if(allPossiStarts!=null)
								{
									for(int ii=0;ii<allPossiStarts.size();ii++)
									{
										long tPosBeg = ((Long)allPossiStarts.get(ii)).longValue();
										long tPosEnd = tPosBeg+2;

										if((tPosBeg!=prodigalBeg) && (tPosBeg!=alignmentBeg))
										{
											out.write(geneName+"\t"+geneName+"\t-1\t"+tPosBeg+"\t"+tPosEnd+"\tPossibleStart\n");
										}
										

									}

								}

								

							

								

							}

						}
					}

				}
				out.close();
		    	} 
			catch(FileNotFoundException e)
			{
				e.printStackTrace();
			}
			catch (IOException e) 
			{
		    	
				e.printStackTrace();
			}
			catch(Exception e)
			{
				e.printStackTrace();
			}
			
		}

	}



}
