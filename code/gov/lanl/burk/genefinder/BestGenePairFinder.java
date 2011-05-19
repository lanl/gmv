package gov.lanl.burk.genefinder;

import gov.lanl.burk.util.*;
import gov.lanl.burk.genepair.*;
import java.util.*;
import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.*;
import java.io.FileWriter;




/******************************************************************************************************************************************************************************************************************************************

Author: Sindhu Vijaya Raghavan

	
******************************************************************************************************************************************************************************************************************************************/




public class BestGenePairFinder
{
	Logger logger;
	Vector genomes = null;
	
	public BestGenePairFinder()
	{
		logger = new Logger();

	}

	public static void printOptions()
	{
		System.out.println("Usage");
		System.out.println("arg0 Prodigal genes directory <REQUIRED>");
		System.out.println("arg1 Percent id directory <REQUIRED>");
		System.out.println("arg2 Tie file <REQUIRED>");
		System.out.println("arg3 Error file <REQUIRED>");
		System.out.println("arg4 Best gene pairs file <REQUIRED>");
		System.out.println("arg5 Best gene pairs with percent id file <REQUIRED>");
		System.out.println("arg6 Log level <REQUIRED>");
		System.out.println("arg7 Log file");

	}

	public Logger getLogger()
	{

		return logger;
	}

	public void configureLogger(String logLevel, String logFile)
	{
		int level = 1;

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

	public String getGenomeName(String geneId)
	{
		String genomeName = null;
		if(geneId!=null)
		{
			String pieces[] = geneId.split("_");
			if(pieces!=null)
			{
				if(pieces.length==3)
				{
					genomeName = (pieces[0]).trim();
				}

			}
		}

		return genomeName;
	}
	

	public String createGenePairObj(String line, GenePair gpObj)
	{
		String key =null;
		if(line!=null && gpObj!=null)
		{
			String pieces[] = line.split(",");
				
			if(pieces!=null)
			{
				if(pieces.length==2)
				{
					String genePair = (pieces[0]).trim();
					String scoreStr = (pieces[1]).trim();
					double score = Double.parseDouble(scoreStr);
					String genePieces[] = genePair.split("\\|");
					
					if(genePieces!=null)
					{
						if(genePieces.length==2)
						{
							String queryGene = genePieces[0];
							String dbGene = genePieces[1];
							String genomeName = getGenomeName(dbGene);
							key = queryGene+"|"+genomeName;
					
							gpObj.setQueryGene(queryGene);
							gpObj.setDBGene(dbGene);
							gpObj.setScore(score);

						}					

					}
				}

			}
		}

		return key;
	} 

	

	public void addToSortedList(Vector lst, GenePair gpObj)
	{
		
		if((lst!=null) && (gpObj!=null))
		{	
			double score = gpObj.getScore();
		
			int pos=0;
			boolean flag=false;
			for(int i=0;i<lst.size();i++)
			{	pos = i;
				GenePair obj = (GenePair)lst.get(i);
				double curScore = obj.getScore();
		
				if(curScore < score)
				{	flag = true;
					break;
				}	

			}
			if(flag)
			{
				lst.add(pos,gpObj);
			}	
			else
			{	lst.add(pos+1,gpObj);
				
			}	
			
		}
		

	}

	public HashMap readStdIdFile(String file)
	{
		HashMap map =null;
		if(file!=null)
		{
			try 
			{	
       				BufferedReader in = new BufferedReader(new FileReader(file));
				map = new HashMap();
				String line = in.readLine();
				
				while (line != null) 
				{	
					line = line.trim();
					//System.out.println(line);
					GenePair gpObj = new GenePair();
					String key = createGenePairObj(line,gpObj);
		
					if(map.get(key)!=null)
					{
						Vector lst = (Vector)map.get(key);
						//add to sorted list
						//lst.add(gpObj);
						addToSortedList(lst,gpObj);
						map.put(key,lst);

					}
					else
					{
						Vector lst = new Vector();
						lst.add(gpObj);
						map.put(key,lst);

					}
					line = in.readLine();
				}	
				
				
			}
			catch(Exception e)
			{

				e.printStackTrace();
			}

		}

		return map;

	}

	/*public void sortStdId(String stdIdDir)
	{
		if(stdIdDir!=null)
		{
			if(Framework.dirExists(stdIdDir))
			{
				File fileObj=new File(stdIdDir);
				String fileLst[] = fileObj.list();
				if(fileLst!=null)
				{
					for(int i=0;i<fileLst.length;i++)
					{
						String file = (fileLst[i]).trim();
						String idFile = stdIdDir+"/"+file;
						System.out.println("Processing file :: "+idFile);
						
						long start = System.currentTimeMillis();
						HashMap map = readStdIdFile(idFile);
						long end = System.currentTimeMillis();

						long time_taken = end - start;
						System.out.println("Time taken is "+time_taken);

						//Framework.displayMap(map);
						//System.exit(0);

					}

				}

			}

		}

	}*/

	public void getAllGenomes(String prodigalDir)
	{
		if(prodigalDir!=null)
		{
			if(Framework.dirExists(prodigalDir))
			{
				File fileObj = new File(prodigalDir);
				String fileLst[] = fileObj.list();
				if(fileLst!=null)
				{
					if(genomes==null)
					{
						genomes = new Vector();
					}
					for(int i=0;i<fileLst.length;i++)
					{
						String file = (fileLst[i]).trim();
						file = file.replace("-genes","");
						file = file.trim();
						genomes.add(file);
				
					}

				}
			}

		}

	}

	public void getBestGenePairs(String prodigalDir, String stdIdDir, String tiesFile, String errorsFile, String bestPairsFile, String bestPairsStdIdFile)
	{
		if(prodigalDir!=null && stdIdDir!=null && tiesFile!=null && errorsFile!=null && bestPairsFile!=null && bestPairsStdIdFile!=null && genomes!=null)
		{
			try 
			{

				//open output files
				BufferedWriter tiesOut = new BufferedWriter(new FileWriter(tiesFile));
				BufferedWriter errorsOut = new BufferedWriter(new FileWriter(errorsFile));
				BufferedWriter bestPairsOut = new BufferedWriter(new FileWriter(bestPairsFile));
				BufferedWriter bestPairsStdIdOut = new BufferedWriter(new FileWriter(bestPairsStdIdFile));

				//System.out.println("genomes::"+genomes);


				for(int i=0;i<genomes.size();i++)
				{	
					String genomeName = (String)genomes.get(i);

					int pri = 2;
					String msg = "Processing genome "+genomeName;
					logger.logMessage(pri,msg);

					String geneFile = prodigalDir + "/"+ genomeName+"-genes";
					String percentIdFile = stdIdDir + "/" + genomeName + "-std-id.txt";
					HashMap sortedIdMap = readStdIdFile(percentIdFile);
	
					//go thru the genes in geneFile
					BufferedReader in = new BufferedReader(new FileReader(geneFile));
					
					String line = in.readLine();
					
					while (line != null) 
					{	
						line = line.trim();
						String geneName = line;
						
						
						//for each gene, find the best gene pair in every genome
						for(int j=0;j<genomes.size();j++)
						{
							String searchGenome = (String) genomes.get(j);
							String key = geneName+"|"+searchGenome;

							
							if(sortedIdMap.get(key)!=null)
							{
								Vector allPairs = (Vector)sortedIdMap.get(key);
							
								String bestMatch=null;
								double bestScore=0.0;
								String secondBestMatch=null;
								double secondBestScore=0.0;
								boolean isTie = false;
								boolean isError = false;
		
								if(allPairs.size()==1)
								{
									GenePair bestPair = (GenePair)allPairs.get(0);
									bestMatch = bestPair.getDBGene();
									bestScore = bestPair.getScore();
									

								}
								else if(allPairs.size() > 1)
								{
									GenePair bestPair = (GenePair)allPairs.get(0);
									bestMatch = bestPair.getDBGene();
									bestScore = bestPair.getScore();

									GenePair secondBestPair = (GenePair)allPairs.get(1);
									secondBestMatch = secondBestPair.getDBGene();
									secondBestScore = secondBestPair.getScore();

									
								}

								if(secondBestMatch!=null)
								{
									if(bestScore == secondBestScore)
									{
										isTie = true;
										int priority = 2;
										String message = "There is a tie between the pairs "+geneName+"|"+bestMatch+" and "+geneName+"|"+secondBestMatch +" ("+bestScore+")";
										logger.logMessage(priority,message);
										tiesOut.write(geneName+"|"+bestMatch+", "+geneName+"|"+secondBestMatch+", "+Framework.roundTwoDecimals(bestScore)+"\n");

									}

									

								}

								
								if(isTie)
								{
									break;
								}

								

								//check for errors
								if(!isTie && bestMatch!=null)
								{
									if(genomeName.equals(searchGenome))
									{
										//gene name and best match should be the same
										if(!geneName.equals(bestMatch))
										{
											isError = true;
										}

									}

									
			
									if(!isError)
									{
										bestPairsOut.write(geneName+"|"+bestMatch+"\n");
										bestPairsStdIdOut.write(geneName+"|"+bestMatch+"|"+Framework.roundTwoDecimals(bestScore)+"\n");
										
									
									}
									else
									{
										errorsOut.write(geneName+"|"+bestMatch+"\n");
									}
								
								}
							
							}
						
						}
						line = in.readLine();	
					}

					
						
		
				}

				tiesOut.close();
				errorsOut.close();
				bestPairsOut.close();
				bestPairsStdIdOut.close();
			}
								
			catch(Exception e)
			{
				e.printStackTrace();
			}

		}

	}
	public static void main(String args[])
	{
		

		if(args!=null)
		{
			if((args.length==7) || (args.length==8))
			{
				String prodigalDir = (args[0]).trim();
				String stdIdDir = (args[1]).trim();
				String tieFile = (args[2]).trim();
				String errorsFile = (args[3]).trim();
				String bestPairsFile = (args[4]).trim();
				String bestPairsPercentIdFile = (args[5]).trim();
				String logLevel = (args[6]).trim();
				String logFile =null;
				
				if(args.length==8)
				{
					logFile = (args[7]).trim();
				}
				
				BestGenePairFinder obj = new BestGenePairFinder();
				obj.configureLogger(logLevel,logFile);

				Logger logObj = obj.getLogger();
				int priority = 2;
				String message = "Logging messages from BestGenePairFinder.java\n";
				message = message + "Prodigal directory :: " +prodigalDir + "\n";
				message = message + "Standard identity directory :: " + stdIdDir + "\n";
				message = message + "Tie file :: "+tieFile + "\n";
				message = message + "Errors file :: "+errorsFile + "\n";
				message = message + "Best gene pairs file :: "+bestPairsFile + "\n";
				message = message + "Best gene pairs with standard id file :: "+bestPairsPercentIdFile + "\n";
				message = message + "Log level :: "+ logLevel + "\n";
				message = message + "Log file :: "+logFile;
				logObj.logMessage(priority,message);

				message = "Getting best gene pairs.....";
				logObj.logMessage(priority,message);

				obj.getAllGenomes(prodigalDir);
				obj.getBestGenePairs(prodigalDir,stdIdDir,tieFile,errorsFile,bestPairsFile,bestPairsPercentIdFile);
			
				//obj.sortStdId(stdIdDir);
				//obj.output();
			}
			else
			{
				BestGenePairFinder.printOptions();
			}

		}
		else
		{
			BestGenePairFinder.printOptions();

		}

	}





}
