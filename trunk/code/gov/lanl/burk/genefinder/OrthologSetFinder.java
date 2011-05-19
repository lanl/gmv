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




public class OrthologSetFinder
{
	Logger logger;
	Vector refGenes=null;
	Vector bestGenePairs=null;
	
	
	public OrthologSetFinder()
	{
		logger = new Logger();

	}

	public static void printOptions()
	{
		System.out.println("Usage");
		System.out.println("arg0 Reference genes file <REQUIRED>");
		System.out.println("arg1 Best pairs of genes file <REQUIRED>");
		System.out.println("arg2 Ortholog directory <REQUIRED>");
		System.out.println("arg3 Number of genomes <REQUIRED>");
		System.out.println("arg4 Log level <REQUIRED>");
		System.out.println("arg5 Log file");

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

	public Vector readFile(String file)
	{

		Vector lst = null;
		if(file!=null)
		{
			try 
			{	
       				BufferedReader in = new BufferedReader(new FileReader(file));
				
				lst = new Vector();
				
				String line = in.readLine();
				
				while (line != null) 
				{	
					line = line.trim();
					lst.add(line);
					line = in.readLine();

				}
				in.close();
			}
			catch(Exception e)
			{
				e.printStackTrace();

			}
	
		}
		return lst;

	}

	public Vector getAllMatchesForGene(String gene)
	{
		Vector lst = null;

		if(gene!=null && bestGenePairs!=null) 
		{
			lst = new Vector();
			for(int i=0;i<bestGenePairs.size();i++)
			{
				String genePair = (String) bestGenePairs.get(i);
				if(genePair.startsWith(gene))
				{
					String pieces[] = genePair.split("\\|");
					if(pieces!=null)
					{
						if(pieces.length==2)
						{
							String orthoGene = (pieces[1]).trim();
							lst.add(orthoGene);
						}

					}

				}	

			}

		}
		return lst;

	}

	public void writeToFile(String file, Vector genes)
	{

		if(file!=null && genes!=null)
		{
			try
			{
				BufferedWriter out = new BufferedWriter(new FileWriter(file));
				
				for(int i=0;i<genes.size();i++)
				{
					String gene = (String) genes.get(i);
					out.write(gene+"\n");
		
				}
				out.close();
			}
			catch(Exception e)
			{
				e.printStackTrace();
			}
		}
	}	

	public void getOrthologSets(String orthologDir, int numGenomes)
	{
		if(refGenes!=null && bestGenePairs!=null && orthologDir!=null)
		{
			
			for(int i=0;i<refGenes.size();i++)
			{
				String refGene = (String) refGenes.get(i);
				boolean isPanReciprocal = true;
			
				Vector orthologSet = getAllMatchesForGene(refGene);
				if(orthologSet!=null)
				{
					if(orthologSet.size() == numGenomes)
					{

						for(int j=0;j<orthologSet.size();j++)
						{
							String gene1 = (String) orthologSet.get(j);
							for(int k=0;k<orthologSet.size();k++)
							{
								String gene2 = (String) orthologSet.get(k);
								String key = gene1 + "|" +gene2;
								if(!bestGenePairs.contains(key))
								{
									isPanReciprocal = false;
									break;
								}
								
							}

						}

					}
					else
					{
												
						isPanReciprocal = false;
						
					}

					if(isPanReciprocal)
					{
						String orthologFile = orthologDir + "/" + refGene+ "-orthologs";
						writeToFile(orthologFile,orthologSet);

					}
					else
					{
						int priority = 2;
						String message = "No ortholog set found for "+refGene;
						logger.logMessage(priority,message);

					}

					

				}

			}
		}
	}	


	public void process(String refGenesFile, String bestGenePairsFile, String orthologDir, String numGenomesStr)
	{
		if(refGenesFile!=null && bestGenePairsFile!=null && orthologDir!=null && numGenomesStr!=null)
		{
			refGenes = readFile(refGenesFile);
			bestGenePairs = readFile(bestGenePairsFile);
			int numGenomes = Integer.parseInt(numGenomesStr);
		
			getOrthologSets(orthologDir,numGenomes);

		}
	}


	public static void main(String args[])
	{
		

		if(args!=null)
		{
			if((args.length==5) || (args.length==6))
			{
				String refGenesFile = (args[0]).trim();
				String bestGenePairsFile = (args[1]).trim();
				String orthologDir = (args[2]).trim();
				String numGenomesStr = (args[3]).trim();
				String logLevel = (args[4]).trim();
				String logFile =null;
				
				if(args.length==6)
				{
					logFile = (args[5]).trim();
				}
				
				OrthologSetFinder obj = new OrthologSetFinder();
				obj.configureLogger(logLevel,logFile);

				Logger logObj = obj.getLogger();
				int priority = 2;
				String message = "Logging messages from OrthologSetFinder.java";
				logObj.logMessage(priority,message);

				message = "Generating ortholog sets.....";
				logObj.logMessage(priority,message);

				OrthologSetFinder finderObj = new OrthologSetFinder();
				finderObj.process(refGenesFile,bestGenePairsFile,orthologDir,numGenomesStr);
				

			}
			else
			{
				OrthologSetFinder.printOptions();
			}

		}
		else
		{
			OrthologSetFinder.printOptions();

		}

	}







}
