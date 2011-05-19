package gov.lanl.burk.genefinder;

import gov.lanl.burk.util.*;
import gov.lanl.burk.gene.*;
import gov.lanl.burk.ortholog.*;
import java.util.*;
import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.*;



/******************************************************************************************************************************************************************************************************************************************

Author: Sindhu Vijaya Raghavan

	
Algorithm for finding a consistent start site for an ortholog set:

1> Check if the prodigal start sites all line up in the alignment

For the reference gene, get the prodigal start site. Get the position in the alignment corresponding to the prodigal start site. For the remaining genes in the set, get the relative position corresponding to the alignment position. Relative position is the position in the alignment after gaps are removed in the substring from the beginning to the alignment position. If the relative position is same as the prodigal start for all the remaining genes, then select the alignment position as the common start. Else go to the next step.

2> If all the prodigal starts do not line up, then do the following:

For each of the start position for the reference gene:
	1> Get the position in the alignment.
	2> Get the relative postion corresponding the alignment position for the remaining genes.
	3> If the relative position is one of the prodigal proposed start pos, then get the score corresponding to this start position and compute the average score for all the genes.
	4> If the relative position is not one of the prodigal proposed start pos, then move to the next start position proposed by prodigal for the ref gene, i.e go to the beginning of step 2.
	5> After going through all the start positions for the reference gene, pick the start position that results in the highest average score.
	6> If a common start could not be found, discard the ortholog set.
		
******************************************************************************************************************************************************************************************************************************************/




public class CommonStartFinder
{
	Logger logger;
	HashMap genes;
	int numProdigalStartCount =0;
	int numOrthologsNoStartSitePredicted = 0;
	HashMap orthoSet = null;
	Vector orthlogStats = null;
	HashMap percentIdMap = null;
	Vector rejectedOthologs = null;
	boolean isFilter = false;
	int threshold=0;
	
	public CommonStartFinder()
	{
		logger = new Logger();

	}

	public static void printOptions()
	{
		System.out.println("Usage");
		System.out.println("arg 0 Start sites file <REQUIRED>");
		System.out.println("arg 1 Alignment directory <REQUIRED>");
		System.out.println("arg 2 Feature files directory <REQUIRED>");
		System.out.println("arg 3 Percent Id file <REQUIRED>");
		System.out.println("arg 4 Output directory <REQUIRED>");
		System.out.println("arg 5 Predicted genes features file <REQUIRED>");
		System.out.println("arg 6 Flag for filtering algorithm - 1 to turn on and 0 to turn off.<REQUIRED>");
		System.out.println("arg 7 Threshold for filtering algorithm. In case of invalid entry, threshold of 0 is used. <REQUIRED>");
		System.out.println("arg 8 Log level <REQUIRED>");
		System.out.println("arg 9 Log file");


	}

	public Logger getLogger()
	{

		return logger;
	}

	public void configureLogger(String logLevel, String logFile)
	{
		int level = 1; //default

		if(logLevel!=null)
		{
			try
			{
				level = Integer.parseInt(logLevel);
			}
			catch(Exception e)
			{
				e.printStackTrace();

			}

		}

		logger.setLogLevel(level);
		
		if(logFile!=null)
		{
			logger.setLogFile(logFile);

		}

	}
	
	public void configureFilteringAlgorithm(String flag, String thresholdStr)
	{

		if(flag!=null && thresholdStr!=null)
		{
			int index = Integer.parseInt(flag);
			if(index==1)
			{
				isFilter = true;
			}
			else
			{
				isFilter = false;
			}

			threshold = Integer.parseInt(thresholdStr);
		}

	}

	public long convertPosToLong(String str)
	{
		if(str!=null && !("".equals(str)))
		{
			long res = Long.parseLong(str);				
			return res;
		}

		return -1;
	}

	public Vector convertToList(String str, int type)
	{
		Vector res = null;
		if(str!=null && !("".equals(str)))
		{
			str = str.trim();
			String pieces[] = str.split("\\|");
			if(pieces!=null)
			{
				res = new Vector();		
				for(int i=0;i<pieces.length;i++)
				{
					String temp = (pieces[i]).trim();
					if(!"".equals(temp))
					{

						if(type == 1) //Long
						{
						
							Long tempObj = new Long(temp);
							res.add(tempObj);
						}

						if(type == 2)	//Double
						{
							Double tempObj = new Double(temp);			
							res.add(tempObj);

						}
					}
				

				}
			}
		}
	
		return res;

	}	

	public void readStartSitesFile(String file)
	{
		if(file !=null)
		{
			try 
			{	
       				BufferedReader in = new BufferedReader(new FileReader(file));
				genes = new HashMap();
        			String line = in.readLine();
				
			        while (line != null) 
				{	
					line = line.trim();
					String pieces [] = line.split(",");
					if(pieces!=null)
					{
						if(pieces.length==8)
						{
							String geneName = (pieces[0]).trim();
							String startPosStr = (pieces[1]).trim();
							String endPosStr = (pieces[2]).trim();
							String direction = (pieces[3]).trim();
							String possibleStartsStr = (pieces[4]).trim();
							String scoresStr = (pieces[5]).trim();
							String segStartStr = (pieces[6]).trim();
							String segEndStr = (pieces[7]).trim();

							
							//convert pos strings to numbers

							long startPos = convertPosToLong(startPosStr);
							long endPos = convertPosToLong(endPosStr);
							long segStartPos = convertPosToLong(segStartStr);
							long segEndPos = convertPosToLong(segEndStr);

							Vector possibleStarts = convertToList(possibleStartsStr,1);
							Vector totalScores = convertToList(scoresStr,2);	

							Gene geneObj = new Gene();
							geneObj.setGeneName(geneName);
							geneObj.setStartPos(startPos);
							geneObj.setEndPos(endPos);
							geneObj.setDir(direction);
							geneObj.setSegStart(segStartPos);
							geneObj.setSegEnd(segEndPos);
							geneObj.setPossibleStarts(possibleStarts);
							geneObj.setTotalScores(totalScores);
							geneObj.computeRelativeStartPos();

							genes.put(geneName,geneObj);
							

	
						}
						else
						{
							int priority = 2;
							String message = "Incorrect format in file "+ file + " on line "+line;
							logger.logMessage(priority,message);
						}
					}        			

					line = in.readLine();
				}
        			in.close();
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

	public long getAlignmentPos(long pos, String msaStr)
	{

		if(msaStr!=null && pos!= -1)
		{
			int nucleotideCount = 0;
			int index = 0;	
			
			while((index < msaStr.length()) && (nucleotideCount < pos))
			{
				char colVal = msaStr.charAt(index);
				Character colChar = new Character(colVal);
				Character dashChar = new Character('-');
				
				if(!colChar.equals(dashChar))
				{	
					nucleotideCount++;

				}
				index++;

			}

			return (index-1);

		}

		return -1;

	}

	public long getRelativePosInAlignment(long pos, String msaStr)
	{

		long relPos = -1;
		if((msaStr!=null) && (pos!=-1))
		{
			String substr = msaStr.substring(0,(int)(pos+1));

			//String substr = msaStr.substring(0,5);	
			// remove gaps
			substr = substr.replace("-","");
			relPos = substr.length();

		}

		return relPos;
	}

	public long getAbsPosForRelativePos(long pos, Gene geneObj)
	{

		long absPos = -1;
		int index=-1;
		if((pos!=-1) && (geneObj!=null))
		{
			Vector startLst = geneObj.getRelativeStarts();

			if(startLst!=null)
			{
				for(int i=0;i<startLst.size();i++)	
				{

					Long obj = (Long)startLst.get(i);
					long tempPos = obj.longValue();

					if(tempPos == pos)
					{
						index = i;
						break;
	
					}

				}
			}

			if(index!=-1)
			{
				Vector absPosLst = geneObj.getPossibleStarts();
				if(absPosLst!=null)
				{
					Long posObj = (Long)absPosLst.get(index);
					if(posObj!=null)
					{
						absPos = posObj.longValue();
					}

				}
			}

		}
		return absPos;




	}

	public double getScoreForStartPos(long pos, Gene geneObj)
	{

		double score = 0.0;
		int index=-1;
		if((pos!=-1) && (geneObj!=null))
		{
			Vector startLst = geneObj.getPossibleStarts();

			if(startLst!=null)
			{
				for(int i=0;i<startLst.size();i++)	
				{

					Long obj = (Long)startLst.get(i);
					long tempPos = obj.longValue();

					if(tempPos == pos)
					{
						index = i;
						break;
	
					}

				}
			}

			if(index!=-1)
			{
				Vector scoreLst = geneObj.getTotalScores();
				if(scoreLst!=null)
				{
					Double scoreObj = (Double)scoreLst.get(index);
					if(scoreObj!=null)
					{
						score = scoreObj.doubleValue();
					}

				}
			}

		}

		
		return score;

	}

	public boolean verifyProdigalStarts(String refGene, HashMap msa)
	{
		//System.out.println("in verifyProdigalStarts");
		
		boolean res = true;
		if(refGene!=null && msa!=null && genes!=null)
		{
			Object temp = genes.get(refGene);
			if(temp!=null)
			{
				Gene refGeneObj = (Gene)temp;
				int dir = refGeneObj.getDir();	
				long startPos = -1;
				long relStartPos = -1;
				long alignStartPos = -1;
				if(dir == 1)
				{
					startPos = refGeneObj.getStartPos();
					relStartPos = refGeneObj.getRelStartPos();
				}
				else if(dir == -1)
				{
					startPos = refGeneObj.getEndPos();
					relStartPos = refGeneObj.getRelEndPos();
				}
				else
				{
					int priority = 1;
					String message = "Invalid direction - "+dir + " for "+refGene;
					logger.logMessage(priority,message);
					System.exit(-1);

				}

				
				

				if(startPos!= -1 && relStartPos!= -1 && msa!=null)
				{
					Object msaObj = msa.get(refGene);
					if(msaObj!=null)
					{
					
						String msaStr = (String)msaObj;
						alignStartPos = getAlignmentPos(relStartPos,msaStr);

						//System.out.println("alignStartPos::"+alignStartPos);

						
						//for the remaining genes, get their rel start pos
						//compute the rel start pos for the alignmentStartPos

						res = true;

						Set keys = msa.keySet();
			        		Iterator it = keys.iterator();
			        		while (it.hasNext()) 
						{
							String geneName = (String)it.next();
							Gene geneObj = (Gene)genes.get(geneName);

							if(!geneName.equals(refGene))
							{
								int geneDir = geneObj.getDir();
								long geneRelStartPos = -1;
								
								if(geneDir == 1)
								{
									geneRelStartPos = geneObj.getRelStartPos();

								}
								else if(geneDir == -1)
								{

									geneRelStartPos = geneObj.getRelEndPos();
								}
								else
								{
									int priority = 1;
									String message = "Invalid direction - "+geneDir + " for "+geneName;
									logger.logMessage(priority,message);
									System.exit(-1);

								}
							
								String seqStr = (String)msa.get(geneName);
								//long relPosAlignment = getRelativePosInAlignment(alignStartPos,seqStr);
								long geneAlignPos = getAlignmentPos(geneRelStartPos,seqStr);


								/*System.out.println("geneName::"+geneName);
								System.out.println("geneRelStartPos::"+geneRelStartPos);
								System.out.println("geneAlignPos::"+geneAlignPos);*/

								
								/*if(relPosAlignment != geneRelStartPos)
								{
									res = false;

								}*/

								if(geneAlignPos != alignStartPos)
								{

									res = false;	
								}
					
										
							}
						 }

						// now create PredictedGene object if all genes have prodigal starts

						if(res)
						{
							//go thru msa hash map, for each gene in the orthlog set, create PredictedGene obj

							Vector bestConfig = new Vector();

							double totalScore = 0.0;

							Set msa_keys = msa.keySet();
				        		Iterator msa_it = msa_keys.iterator();
				        		while (msa_it.hasNext()) 
							{
								String geneName = (String)msa_it.next();
								Gene gObj = (Gene)genes.get(geneName);
								if(gObj!=null)
								{
									PredictedGene pGene = new PredictedGene();
									pGene.setGeneObj(gObj);	
									pGene.setIsProdigalStart(true);
									pGene.setAlignmentPos(alignStartPos);
									pGene.setProdigalStartPosInAlignment(alignStartPos);
									if(gObj.getDir() == 1)
									{
										long pos = gObj.getRelStartPos();
										pGene.setRelStartPos(pos);
										
										pos = gObj.getStartPos();
										pGene.setAbsoluteStartPos(pos);

										double score = getScoreForStartPos(pos,gObj);	
										pGene.setScore(score);	

										totalScore+= score;	


										
									}
									else if(gObj.getDir() == -1)
									{
										long pos = gObj.getRelEndPos();
										pGene.setRelStartPos(pos);
										
										pos = gObj.getEndPos();
										pGene.setAbsoluteStartPos(pos);
	
										double score = getScoreForStartPos(pos,gObj);	
										pGene.setScore(score);

										totalScore+= score;		

										
										
									}
									//predictedGenes.put(geneName,pGene);
									bestConfig.add(pGene);

								}

							}

							int numSpecies = msa_keys.size();
							if(numSpecies!=0)
							{
								double avgScore = totalScore/numSpecies;

								if(orthoSet==null)
								{
									orthoSet = new HashMap();
								}

								if(bestConfig!=null)
								{
									Ortholog orthologObj = new Ortholog();
									orthologObj.setOrthologSet(bestConfig);	
									orthologObj.setScore(avgScore);
									orthologObj.setRefGene(refGene);
									orthologObj.setNumProdigalStarts(numSpecies);
									orthologObj.setAlignPos(alignStartPos+1); //index starting from 1
									orthoSet.put(refGene,orthologObj);

								}
						

							}
						}

					}
				}
		
			}
			else
			{

				int priority = 1;
				String message = refGene + " is not found";
				logger.logMessage(priority,message);
				System.exit(-1);

			}

		}
		
		return res;
	}

	public boolean getBestPossibleStarts(String refGene, HashMap msa)		
	{

		//System.out.println("in getBestPossibleStarts :: "+refGene);
		
		boolean retFlag = false;
		int numOrthologs = 0;
		if(refGene!=null && msa!=null && genes!=null)
		{

			Set keys = msa.keySet();
			if(keys!=null)
			{
				int numSpecies = keys.size();
				
				
				if(genes.get(refGene)!=null && (msa.get(refGene)!=null))
				{
					double bestAvgScore = 0.0;
					Vector bestConfig =null;
					long bestAlignPos = -1;	
					boolean first = true;		

					String msaStr = (String)msa.get(refGene);
					Gene refGeneObj = (Gene)genes.get(refGene);
					Vector possibleRelStarts = refGeneObj.getRelativeStarts();
					Vector startPosScores = refGeneObj.getTotalScores();
					Vector possibleAbsStarts = refGeneObj.getPossibleStarts();
					long refGeneProdStart=-1;
					if(refGeneObj.getDir()==1)
					{
						refGeneProdStart = (long)refGeneObj.getRelStartPos();

					}

					if(refGeneObj.getDir()==-1)
					{
						refGeneProdStart = (long)refGeneObj.getRelEndPos();

					}

					long refGeneProdStartInAlign = getAlignmentPos(refGeneProdStart,msaStr);

					/*System.out.println("possibleRelStarts::"+possibleRelStarts);
					System.out.println("startPosScores::"+startPosScores);
					System.out.println("possibleAbsStarts::"+possibleAbsStarts);
					System.out.println("refGeneProdStart::"+refGeneProdStart);
					System.out.println("refGeneProdStartInAlign::"+refGeneProdStartInAlign);*/
					
					if(possibleRelStarts!=null && startPosScores!=null && possibleAbsStarts!=null) 
					{
						HashMap possibleConfigs = new HashMap();
						HashMap possibleScores = new HashMap();
						HashMap numProdigalStarts = new HashMap();

						for(int i=0;i<possibleRelStarts.size();i++)
						{
							Integer index = new Integer(i); // index for possibleConfigs and possibleScores
							double totalScore = 0.0;
							boolean isAlign = true;
							Vector config = new Vector();
							int prodStartCount =0;

							
							long refGeneRelStart = ((Long)possibleRelStarts.get(i)).longValue();
							long absoluteRefGeneStart = ((Long)possibleAbsStarts.get(i)).longValue();
							long alignStartPos = getAlignmentPos(refGeneRelStart,msaStr);
							double refGeneScore = ((Double)startPosScores.get(i)).doubleValue();
							totalScore+= refGeneScore;

							
							PredictedGene pRefGene = new PredictedGene();
							pRefGene.setGeneObj(refGeneObj);
							pRefGene.setAlignmentPos(alignStartPos);
							pRefGene.setRelStartPos(refGeneRelStart);
							pRefGene.setAbsoluteStartPos(absoluteRefGeneStart);
							pRefGene.setProdigalStartPosInAlignment(refGeneProdStartInAlign);
							pRefGene.setScore(refGeneScore);
							
							if(refGeneProdStart == refGeneRelStart)
							{
								prodStartCount++;
								pRefGene.setIsProdigalStart(true);
							}
							else
							{
								pRefGene.setIsProdigalStart(false);
							}

							config.add(pRefGene);

							/*System.out.println("\n\nrefGene::"+refGene);
							System.out.println("alignStartPos::"+alignStartPos);*/
							Iterator it = keys.iterator();
							while (it.hasNext()) 
							{
								String geneName = (String)it.next();
								
								if(genes.get(geneName)!=null)
								{
									Gene geneObj = (Gene)genes.get(geneName);
									
									if(!geneName.equals(refGene))
									{

										
										//get the relative pos in the alignment
										String seqStr = (String)msa.get(geneName);
										//long relPosAlignment = getRelativePosInAlignment(alignStartPos,seqStr);
										Vector geneRelStarts = geneObj.getRelativeStarts();
										long relPosAlignment = -1;
										 

										/*System.out.println("gene::"+geneName);
										System.out.println("relPosAlignment::"+relPosAlignment);
										System.out.println("geneRelStarts::"+geneRelStarts);*/

										boolean isFound = false;										
										if(geneRelStarts!=null)
										{
											//System.out.println("rel starts size::"+geneRelStarts.size());
											for(int ii=0;ii<geneRelStarts.size();ii++)
											{
												long tempPos = ((Long)geneRelStarts.get(ii)).longValue();
												long tempAlignPos = getAlignmentPos(tempPos,seqStr);
												//System.out.println("tempAlignPos::"+tempAlignPos);
												if(tempAlignPos == alignStartPos)
												{
													isFound = true;
													relPosAlignment = tempPos;
													break;

												}								
													
											}				
												
											//if(geneRelStarts.contains(relPosAlignment))
											if(isFound)
											{
												long absolutePos = getAbsPosForRelativePos(relPosAlignment,geneObj);
												double geneScore = getScoreForStartPos(absolutePos,geneObj);
												totalScore+=geneScore;

												
												PredictedGene pGene = new PredictedGene();
												pGene.setGeneObj(geneObj);
												pGene.setAlignmentPos(alignStartPos);
												pGene.setRelStartPos(relPosAlignment);
												pGene.setAbsoluteStartPos(absolutePos);
												pGene.setScore(geneScore);

												long geneProdStart=-1;
												if(geneObj.getDir()==1)
												{
													geneProdStart = (long)geneObj.getRelStartPos();

												}

												if(geneObj.getDir()==-1)
												{
													geneProdStart = (long)geneObj.getRelEndPos();

												}

												long geneProdStartInAlign = getAlignmentPos(geneProdStart,seqStr);
												pGene.setProdigalStartPosInAlignment(geneProdStartInAlign);

												if(geneProdStart == relPosAlignment)
												{
													prodStartCount++;
													pGene.setIsProdigalStart(true);
												}
												else
												{
													pGene.setIsProdigalStart(false);
												}

												config.add(pGene);

								

											}
											else
											{
												//System.out.println("start site not found in the list.. breaking..");				
												isAlign = false;
												break;
											}
										}	

									}
								}
								else
								{
									int priority = 2;
									String message = geneName + " is not found";
									logger.logMessage(priority,message);
									break;
								}

							} // end of while

							if(isAlign)
							{
								//compute avg score
								if(numSpecies > 0)
								{
								
									double avgScore = totalScore/numSpecies;
									possibleScores.put(index,avgScore);
									possibleConfigs.put(index,config);
									numProdigalStarts.put(index,prodStartCount);

									/*System.out.println("refGene::"+refGene);
									System.out.println("Config");
									System.out.println("avgScore::"+avgScore);
									System.out.println("config::"+config);
									System.out.println("prodStartCount::"+prodStartCount);*/

									if(first)
									{
										first = false;
										//assign the scores
										bestAvgScore = avgScore;
										bestConfig = config;
										numOrthologs = prodStartCount;
										bestAlignPos = alignStartPos+1; //index starting from 1
										


									}
									else
									{
										//filtering algorithm is turned off
										//select start sites based on the avg score
										if(!isFilter)
										{

											if(bestAvgScore < avgScore)
											{
												bestAvgScore = avgScore;
												bestConfig = config;
												numOrthologs = prodStartCount;
												bestAlignPos = alignStartPos+1; //index starting from 1
												
											}

											if(bestAvgScore == avgScore)
											{	
												if(prodStartCount > numOrthologs)
												{

													bestAvgScore = avgScore;
													bestConfig = config;
													numOrthologs = prodStartCount;
													bestAlignPos = alignStartPos+1; //index starting from 1

												}

											}
										}
										else
										{
											//filtering turned on
											//select start sites based on the number of prodigal starts
											
											if(prodStartCount > numOrthologs)	
											{

												bestAvgScore = avgScore;
												bestConfig = config;
												numOrthologs = prodStartCount;
												bestAlignPos = alignStartPos+1; //index starting from 1


											}
											if(prodStartCount == numOrthologs)
											{

												if(avgScore > bestAvgScore)
												{
													bestAvgScore = avgScore;
													bestConfig = config;
													numOrthologs = prodStartCount;
													bestAlignPos = alignStartPos+1; //index starting from 1

												}
											}
												
										}			
									}
			
									if(config.size()!=numSpecies)
									{
										int priority = 2;
										String message = "Problem while predicting genes for the ortholog set "+refGene;
										logger.logMessage(priority,message);
									}	
									

								}
							}
							
						}// end of for

						//now we have the gene predictions with the best avg score
						
						if(orthoSet==null)
						{
							orthoSet = new HashMap();
						}

						//System.out.println("bestConfig::"+bestConfig);

						if(bestConfig!=null)
						{
							//filtering turned off - basic algorithm	
							if(!isFilter)
							{
								Ortholog orthologObj = new Ortholog();
								orthologObj.setOrthologSet(bestConfig);	
								orthologObj.setScore(bestAvgScore);
								orthologObj.setRefGene(refGene);
								orthologObj.setNumProdigalStarts(numOrthologs);
								orthologObj.setAlignPos(bestAlignPos);

								orthoSet.put(refGene,orthologObj);

								retFlag = true;

							}
							else
							{
								int numGenomes = bestConfig.size();
								if((threshold > numGenomes) || (threshold < 0))
								{
									//majority
									if(numGenomes % 2 == 0)
									{
										threshold = numGenomes/2;
									}
									else
									{
									
										threshold = (int)(numGenomes/2)+1;
									}

								}
								if(numOrthologs >= threshold)	
								{
									Ortholog orthologObj = new Ortholog();
									orthologObj.setOrthologSet(bestConfig);	
									orthologObj.setScore(bestAvgScore);
									orthologObj.setRefGene(refGene);
									orthologObj.setNumProdigalStarts(numOrthologs);
									orthologObj.setAlignPos(bestAlignPos);

									orthoSet.put(refGene,orthologObj);

									retFlag = true;

								}
								else
								{

									retFlag = false;
								}					
							}			
							
						}
						else
						{
							//none of the start sites align
							//right now, don't do anything

						}		
							
					}
		
				}
				else
				{
					int priority = 1;
					String message = refGene + " is not found";
					logger.logMessage(priority,message);
					System.exit(-1);

				}
			}

		}
		
		return retFlag;
	}	


	/*public void addPredictedGenes(Vector config)
	{

		if(config!=null)
		{
			if(predictedGenes==null)
			{
				predictedGenes = new HashMap();
			}

			for(int i=0;i<config.size();i++)
			{
				PredictedGene pGene = (PredictedGene) config.get(i);
				Gene gene = pGene.getGeneObj();
				
				if(gene!=null)
				{
					String geneName = gene.getGeneName();
					if(geneName!=null)
					{
						predictedGenes.put(geneName,pGene);
					}
				}


			}

		}
	}*/


			
	public void findCommonStartSiteForMSA(String file, String refGene)
	{
		if(file!=null && refGene!=null)
		{
			HashMap msa = Framework.readFasta(file);
			if(msa!=null)
			{
				boolean res = verifyProdigalStarts(refGene,msa);
				
				if(!res)
				{
					res = getBestPossibleStarts(refGene,msa);
					if(!res)
					{

						numOrthologsNoStartSitePredicted++;
						if(rejectedOthologs == null)
						{
							rejectedOthologs = new Vector();
						}
						
						rejectedOthologs.add(refGene);

						int priority = 2;
						String message = "Could not find a common start for the ortholog set "+refGene;
						logger.logMessage(priority,message);
			
					}

				}
				else
				{
					numProdigalStartCount++;
				}

				
			}
			else
			{
				int priority = 2;
				String message = "Problem reading fasta file for reference gene "+refGene;
				logger.logMessage(priority,message);
			}
			
		}

	}

	public void displayOrthologSets()
	{
		if(orthoSet!=null)
		{
			
			Set keys = orthoSet.keySet();
	        	Iterator it = keys.iterator();
	        	while (it.hasNext()) 
			{
				String key = (String)it.next();
				Ortholog value = (Ortholog)orthoSet.get(key);
				String displayStr="";
				String refGene = value.getRefGene();
				long alignPos = value.getAlignPos();
				int numProdigalStarts = value.getNumProdigalStarts();
				double score = value.getScore();
				double formattedScore = Framework.roundTwoDecimals(score);
				
				displayStr = refGene + "\t" + alignPos + "\t" + numProdigalStarts + "\t" + formattedScore;

				System.out.println(displayStr);

				//value.display();

				//System.out.println(key + " => "+value);
	                }

		}
	}

	public void findCommonStarts(String alignDir)
	{

		if(alignDir!=null)
		{
		 	boolean exists = Framework.dirExists(alignDir);
			if(exists)
			{
				
				File fileObj=new File(alignDir);
				String dirListing[] = fileObj.list();

				if(dirListing!=null)
				{

					for(int i=0;i<dirListing.length;i++)
					{
						String msaFile = (dirListing[i]).trim();
						String msaFilePath = alignDir + "/" + msaFile;
						File msaFileObj = new File(msaFilePath);
						if(msaFileObj.isFile())
						{
							String refGene = new String(msaFile);
							refGene = refGene.replace("-orthologs-align.fasta","");
							refGene = refGene.trim();
							
							findCommonStartSiteForMSA(msaFilePath,refGene);
							
							

						}

					}

					
					
				}				

			}
			else
			{
				int priority = 1;
				String message = alignDir + " does not exist";
				logger.logMessage(priority,message);
				System.exit(-1);

			}			


		}

	}

	public void writeOrthologStats(String outputDir)
	{
		if(outputDir!=null && orthlogStats!=null)
		{
			if(Framework.dirExists(outputDir))
			{
				String outputFile = outputDir + "/orthologs-stats.txt";

				try 
				{
					BufferedWriter out = new BufferedWriter(new FileWriter(outputFile));
					String header = "ORTHOLOG_SET\tMIN_PERCENT_ID\tMAX_PERCENT_ID\tAVG_PERCENT_ID\tSTD_DEV\tNUM_PRODIGAL_STARTS\tNUM_CORRECTIONS\n";
					out.write(header);
					for(int i=0;i<orthlogStats.size();i++)
					{
						OrthologStatistic obj = (OrthologStatistic)orthlogStats.get(i);
						String msg = obj.getDisplayString();
						out.write(msg);
						out.write("\n");
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
			else
			{
				int priority = 1;
				String message = outputDir + " does not exist";
				logger.logMessage(priority,message);
				System.exit(-1);
			}

		}

	}

	

	public void output(String outputDir)
	{
		int priority = 2;
		String message = "Number of orthologs with prodigal predicted starts :: "+numProdigalStartCount+"\n";
		message = message + "Number of orthologs with no start sites predicted :: "+numOrthologsNoStartSitePredicted;
		logger.logMessage(priority,message);
		//displayOrthologSets();	
		writeOrthologStats(outputDir);
		writePredictedGenes(outputDir);
		writeSummaryStats(outputDir);
					

	}

	public void generatePredictedGenesFeaturesFile(String file)
	{

		if(file!=null)
		{
			try
			{
				BufferedWriter out = new BufferedWriter(new FileWriter(file));
				out.write("GENE_NAME\tREF_GENE\tABS_PROD_START\tREL_PROD_START\tALIGN_PROD_START\tABS_PRED_START\tREL_PRED_START\tALIGN_PRED_START\n");
				if(orthoSet!=null)				
				{
					
					Set keys = orthoSet.keySet();
			        	Iterator it = keys.iterator();
			        	while (it.hasNext()) 
					{
						String refGene = (String)it.next();
						Ortholog orthologObj = (Ortholog)orthoSet.get(refGene);
						
						Vector orthologs = orthologObj.getOrthologSet();
						if(orthologs!=null)
						{
							for(int i=0;i<orthologs.size();i++)
							{
								PredictedGene pGene = (PredictedGene) orthologs.get(i);
								Gene gene = pGene.getGeneObj();
								if(gene!=null)
								{		
									String geneName = gene.getGeneName();
									long absProdStart = gene.getStartPos();
									long relProdStart = gene.getRelStartPos();
									long alignProdStart = pGene.getProdigalStartPosInAlignment();

									long absPredictedStart = pGene.getAbsoluteStartPos();
									long relPredictedStart = pGene.getRelStartPos();
									long alignPredictedStart = pGene.getAlignmentPos();

									String displayStr = geneName + "\t" + refGene + "\t" + absProdStart + "\t" + relProdStart + "\t" + alignProdStart + "\t" + absPredictedStart+ "\t" + relPredictedStart+ "\t" + alignPredictedStart + "\n";
									out.write(displayStr);
								}
							}

						} 
						
					}

				}

				out.close();

			}
			catch(Exception e)
			{
				e.printStackTrace();

			}

		}
	}

	public void generateFeatureFiles(String outputDir)
	{

		if(outputDir!=null)
		{	
			if(Framework.dirExists(outputDir))
			{
				if(orthoSet!=null)				
				{
					
					Set keys = orthoSet.keySet();
			        	Iterator it = keys.iterator();
			        	while (it.hasNext()) 
					{
						String refGene = (String)it.next();
						Ortholog orthologObj = (Ortholog)orthoSet.get(refGene);
						if(orthologObj!=null)
						{
							String featureFile = outputDir + "/" + refGene + ".feature";
							FeatureFile fileObj = new FeatureFile(orthologObj);
							fileObj.createFeatureFile(featureFile);

						}

			                }


				}

			}
			else
			{
				int priority = 1;
				String message = outputDir + " does not exist";
				logger.logMessage(priority,message);
				System.exit(-1);


			}

		}

	}

	public void readPercentIdFile(String file)
	{

		if(file!=null)
		{
			try 
			{	
       				BufferedReader in = new BufferedReader(new FileReader(file));
				if(percentIdMap==null)
				{
					percentIdMap = new HashMap();
				}
        			String line = in.readLine();
				
			        while (line != null) 
				{	
					line = line.trim();
					
					String pieces [] = line.split("\\|");
					if(pieces!=null)
					{
						if(pieces.length == 3)
						{
							String key1 = (pieces[0]).trim();
							String key2 = (pieces[1]).trim();
							String val = (pieces[2]).trim();
							String key = key1+"|"+key2;

							Double percentId = new Double(val);
							percentIdMap.put(key,percentId);
							 

						}
					}

					line = in.readLine();

				}

				in.close();

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

	public void writeSummaryStats(String outputDir)
	{
		if(outputDir!=null && orthoSet!=null)
		{
			if(Framework.dirExists(outputDir))
			{
				String outputFile = outputDir + "/summary.txt";
				try 
				{
					BufferedWriter out = new BufferedWriter(new FileWriter(outputFile));

					int numOrthologsCommonStart =orthoSet.size();
					int numOrthologsRejected =0;

					if(rejectedOthologs!=null)
					{
						numOrthologsRejected = rejectedOthologs.size();
					}

					int totalOrthologs = numOrthologsCommonStart + numOrthologsRejected;

					/*System.out.println("totalOrthologs::"+totalOrthologs);
					System.out.println("numOrthologsCommonStart::"+numOrthologsCommonStart);
					System.out.println("numProdigalStartCount::"+numProdigalStartCount);
					System.out.println("numOrthologsRejected::"+numOrthologsRejected);*/

					out.write("Total number of ortholog sets is "+totalOrthologs+"\n\n");
					out.write("Number of ortholog sets with a common start is "+numOrthologsCommonStart+"\n");
					out.write("Number of ortholog sets with prodigal start is "+numProdigalStartCount+"\n\n");
					out.write("Number of ortholog sets with no common start is "+numOrthologsRejected+"\n");
					out.write("Orthologs with no common start are \n");
					
					if(rejectedOthologs!=null)
					{

						for(int i=0;i<rejectedOthologs.size();i++)
						{
							String tempName = (String) rejectedOthologs.get(i);
							out.write(tempName+"\n");

						}

					}
					out.write("\n");


					
					HashMap prodigalStartStat = new HashMap();
					Set keys = orthoSet.keySet();
					Iterator it = keys.iterator();
					while (it.hasNext()) 
					{
						String refGene = (String)it.next();
						Ortholog obj = (Ortholog)orthoSet.get(refGene);
						int numProdStart = obj.getNumProdigalStarts();
						Integer indexObj = new Integer(numProdStart);

						if(prodigalStartStat.get(indexObj) != null)
						{
							Integer prodStartObj = (Integer)prodigalStartStat.get(indexObj);
							int indexCount = prodStartObj.intValue();
							indexCount++;
							prodStartObj = new Integer(indexCount);
							prodigalStartStat.put(indexObj,prodStartObj);

						}
						else
						{
							Integer prodStartObj =  new Integer(1);	
							prodigalStartStat.put(indexObj,prodStartObj);

						}						
	

					}

					
					keys = prodigalStartStat.keySet();
					it = keys.iterator();
					while (it.hasNext()) 
					{
						Integer index = (Integer)it.next();
						Integer val = (Integer)prodigalStartStat.get(index);
						out.write("Number of ortholog sets with "+index+" number of Prodigal starts is "+val+"\n");

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
			else
			{
				int priority = 1;
				String message = outputDir + " does not exist";
				logger.logMessage(priority,message);
				System.exit(-1);
			}

				

			

		}

	}

	public void writePredictedGenes(String outputDir)
	{
		if(outputDir!=null && orthoSet!=null)
		{
			if(Framework.dirExists(outputDir))
			{
				String outputFile = outputDir + "/gene-predictions.txt";

				try 
				{
					BufferedWriter out = new BufferedWriter(new FileWriter(outputFile));
					//String header = "GENE_ID\tORTHOLOG_SET\tPROD_START\tNEW_START\tEND\tDIR\tTOTAL_SCORE\tIS_CORRECTED\n";
					//String header = "GENE_ID\tORTHOLOG_SET\tPROD_BEG\tNEW_BEG\tEND\tDIR\tIS_CORRECTED\n";
					String header = "GENE_ID\tORTHOLOG_SET\tPROD_BEG\tPROD_END\tNEW_BEG\tNEW_END\tDIR\tIS_CORRECTED\n";
					out.write(header);

					Set keys = orthoSet.keySet();
					Iterator it = keys.iterator();
					while (it.hasNext()) 
					{
						String refGene = (String)it.next();
						Ortholog obj = (Ortholog)orthoSet.get(refGene);
						Vector orthologs = obj.getOrthologSet();
						if(orthologs!=null)
						{
							for(int i=0;i<orthologs.size();i++)
							{
								PredictedGene pGene = (PredictedGene) orthologs.get(i);
								Gene gene = pGene.getGeneObj();
								if(gene!=null)
								{		
									String geneName = gene.getGeneName();
									double score = pGene.getScore();
									/*long newStartPos = pGene.getAbsoluteStartPos();
									long prodigalStart = -1;
									long prodigalEnd = -1;*/
									long prodBegin = -1;
									long beg = -1;
									long end = -1;
									long prodEnd = -1;
									int dir = gene.getDir();

									if(dir == -1)
									{
										//prodBegin = gene.getEndPos();
										//prodEnd = gene.getStartPos();
									
										prodBegin = gene.getStartPos();
										prodEnd = gene.getEndPos();
										beg = gene.getStartPos();
										end = pGene.getAbsoluteStartPos();

									}
									else
									{
										prodBegin = gene.getStartPos();
										prodEnd = gene.getEndPos();
										end = gene.getEndPos();
										beg = pGene.getAbsoluteStartPos();

									}

									/*if(dir==-1)
									{
										prodigalStart = gene.getEndPos();
										prodigalEnd = gene.getStartPos();
									}
									else
									{
										prodigalStart = gene.getStartPos();
										prodigalEnd = gene.getEndPos();

									}*/
									
									String isCorrected=null;
									if(pGene.getIsProdigalStart())
									{
										//isCorrected = "prodigal";
										isCorrected = "false";
									}
									else
									{
										//isCorrected = "corrected";
										isCorrected = "true";
									}

									//String msg = geneName+"\t"+refGene+"\t"+prodigalStart+"\t"+newStartPos+"\t"+prodigalEnd+"\t"+dir+"\t"+Framework.roundTwoDecimals(score)+"\t"+isCorrected+"\n";	
									//String msg = geneName+"\t"+refGene+"\t"+prodigalStart+"\t"+newStartPos+"\t"+prodigalEnd+"\t"+dir+"\t"+isCorrected+"\n";

									//String msg = geneName+"\t"+refGene+"\t"+prodBegin+"\t"+beg+"\t"+end+"\t"+dir+"\t"+isCorrected+"\n";					
									String msg = geneName+"\t"+refGene+"\t"+prodBegin+"\t" + prodEnd + "\t" +beg+"\t"+end+"\t"+dir+"\t"+isCorrected+"\n";					
									out.write(msg);			
	
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
			else
			{
				int priority = 1;
				String message = outputDir + " does not exist";
				logger.logMessage(priority,message);
				System.exit(-1);
			}

		}
	}

	public void generateStatsForOrtholog(Ortholog obj, String percentIdFile)
	{

		if(obj!=null && percentIdFile!=null)
		{	
			Vector orthologs = obj.getOrthologSet();
			String refGene = obj.getRefGene();
			Vector genesInSet = null;
			Vector precentIdLst =null;
			int numProdStart = obj.getNumProdigalStarts();
			int numSpecies = 0;

			if(orthologs!=null)
			{
				numSpecies = orthologs.size();
				genesInSet = new Vector();
				for(int i=0;i<orthologs.size();i++)
				{
					PredictedGene pGene = (PredictedGene) orthologs.get(i);
					Gene gene = pGene.getGeneObj();
					if(gene!=null)
					{		
						String geneName = gene.getGeneName();
						if(geneName!=null)
						{
							genesInSet.add(geneName);

						}
					}		
	
				}

			}
			
			if(genesInSet!=null)
			{
				precentIdLst = new Vector();

				for(int i=0;i<genesInSet.size();i++)
				{
					String gene1 = (String)genesInSet.get(i);
					for(int j=0;j<genesInSet.size();j++)
					{
						String gene2 = (String)genesInSet.get(j);
						String key = gene1+"|"+gene2;

						if(percentIdMap.get(key)!=null)
						{
							Double percentId = (Double)percentIdMap.get(key);
							precentIdLst.add(percentId);
						}
						
						/*String unixCmd = "grep "+key + " "+percentIdFile;
						String res = Framework.runUnixCommand(unixCmd);
	
											
						if(res!=null)
						{
							String pieces[] = res.split("\r|\n|\r\n");
							if(pieces!=null)
							{
								if(pieces.length ==1)
								{
									String result = (pieces[0]).trim();
									String items[] = result.split("\\|");
									if(items!=null)
									{ 
										if(items.length==3)
										{
											String val = (items[2]).trim();
											Double percentId = new Double(val);
											precentIdLst.add(percentId);			
										}
									}
								}
							}
						}*/
					}
				}
			}

			

			Statistics statsObj = new Statistics(precentIdLst);
			statsObj.computeStats();
			double min = statsObj.getMin();
			double max = statsObj.getMax();		
			double avg = statsObj.getAvg();
			double stdDev = statsObj.getStdDev();
			int numCorrections = numSpecies - numProdStart;

			OrthologStatistic orthoStatObj = new OrthologStatistic();
			orthoStatObj.setRefGene(refGene);
			orthoStatObj.setMinPercentId(min);
			orthoStatObj.setMaxPercentId(max);
			orthoStatObj.setAvgPercentId(avg);
			orthoStatObj.setStdDev(stdDev);
			orthoStatObj.setNumProdigalStarts(numProdStart);
			orthoStatObj.setNumCorrections(numCorrections);

			if(orthlogStats==null)
			{
				orthlogStats = new Vector();
			}

			orthlogStats.add(orthoStatObj);

			//System.out.println(orthoStatObj.getDisplayString());
							

		}
	}

	public void generateStatistics(String file)
	{
		if(file!=null && orthoSet!=null)
		{	
			readPercentIdFile(file);
			if(percentIdMap!=null)
			{
				Set keys = orthoSet.keySet();
				Iterator it = keys.iterator();
				while (it.hasNext()) 
				{
					String key = (String)it.next();
					Ortholog orthoObj = (Ortholog) orthoSet.get(key);
					generateStatsForOrtholog(orthoObj,file);
					
					
				}
			}
			else
			{	
				int priority = 1;
				String message = "Problem reading file "+file;
				logger.logMessage(priority,message);
				System.exit(-1);

			}		

		}
	}
	public static void main(String args[])
	{

		if(args!=null)
		{

			if(args.length >= 9)
			{
				String startSitesFile = (args[0]).trim();
				String alignmentDir = (args[1]).trim();
				String featureFilesDir = (args[2]).trim();
				String percentIdFile = (args[3]).trim();
				String outputDir = (args[4]).trim();
				String predicted_genes_features_file = (args[5]).trim();
				String filterAlgoFlag = (args[6]).trim();
				String thresholdStr = (args[7]).trim();
				String logLevel = (args[8]).trim();
				String logFile=null;			

				if(args.length == 10)
				{
					logFile = (args[9]).trim();
				}

				CommonStartFinder startFinderObj = new CommonStartFinder();

				startFinderObj.configureLogger(logLevel,logFile);
				
				Logger logObj = startFinderObj.getLogger();
				int priority = 2;
				String message = "Logging messages from CommonStartFinder.java\n";
				message = message + "Start site file :: " +startSitesFile + "\n";
				message = message + "Alignment dir :: " + alignmentDir + "\n";
				message = message + "Feature files dir :: "+featureFilesDir + "\n";
				message = message + "Percent id file :: "+percentIdFile + "\n";
				message = message + "Output directory :: "+outputDir + "\n";
				message = message + "Predictde genes features files :: "+predicted_genes_features_file + "\n";
				message = message + "Filtering algorithm flag :: "+filterAlgoFlag + "\n";
				message = message + "Threshold for filtering algorithm :: "+thresholdStr + "\n";
				message = message + "Log level :: "+ logLevel + "\n";
				message = message + "Log file :: "+logFile;
				logObj.logMessage(priority,message);

				startFinderObj.configureFilteringAlgorithm(filterAlgoFlag,thresholdStr);
				message = "Computing common starts.....";
				logObj.logMessage(priority,message);
				startFinderObj.readStartSitesFile(startSitesFile);
				startFinderObj.findCommonStarts(alignmentDir);
				message = "Computing common starts done....";
				logObj.logMessage(priority,message);

				message = "Generating statistics.....";
				logObj.logMessage(priority,message);
				startFinderObj.generateStatistics(percentIdFile);
				message = "Generating statistics done.....";
				logObj.logMessage(priority,message);
		
				message = "Writing results.....";
				logObj.logMessage(priority,message);
				startFinderObj.output(outputDir);
				startFinderObj.generateFeatureFiles(featureFilesDir);
				startFinderObj.generatePredictedGenesFeaturesFile(predicted_genes_features_file);
				message = "Writing results done.....";
				logObj.logMessage(priority,message);
				

			}
			else
			{
				CommonStartFinder.printOptions();

			}

		}
		else
		{
			CommonStartFinder.printOptions();

		}

	}

}
