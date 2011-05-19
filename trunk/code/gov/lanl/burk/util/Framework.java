package gov.lanl.burk.util;


import java.util.Calendar;
import java.text.SimpleDateFormat;
import java.io.BufferedWriter;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.*;
import java.util.*;
import java.text.DecimalFormat;

/*********************************************************************************************************************************************************

Author - Sindhu Vijaya Raghavan


***********************************************************************************************************************************************************/



public class Framework
{

	public static final String DATE_FORMAT = "EEE MMM d HH:mm:ss yyyy";


	public Framework()
	{

	}


	public static void writeToFile(String iFile, String msg, boolean isAppend)
	{

		try 
		{
			BufferedWriter out = new BufferedWriter(new FileWriter(iFile,isAppend));
		        out.write(msg);
			out.write("\n");
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

	public static String getCurTime()
	{

		Calendar cal = Calendar.getInstance();
		SimpleDateFormat dateFormat = new SimpleDateFormat(DATE_FORMAT);
		return dateFormat.format(cal.getTime());

	}

	public static boolean fileExists(String file)
	{
		boolean res = false;

		if(file!=null)
		{
			File fileObj=new File(file);
			res = fileObj.exists();	
			
			if(res)
			{
				res = fileObj.isFile();

			}	

		}

		return res;

	}


	public static boolean dirExists(String file)
	{
		boolean res = false;

		if(file!=null)
		{
			File fileObj=new File(file);
			res = fileObj.exists();	
			
			if(res)
			{
				res = fileObj.isDirectory();

			}	

		}

		return res;

	}


	public static String getCWD()
	{

		String currentdir = System.getProperty("user.dir");
		return currentdir;
	}


	public static void setCWD(String path)
	{
		if(path!=null)
		{
			if(fileExists(path))
			{
				System.setProperty("user.dir",path);

			}

		}

	}	

	//public static BufferedReader runUnixCommand(String cmd)
	public static String runUnixCommand(String cmd)
	{

		BufferedReader stdInput =null;
		String retString =null;	

		if(cmd!=null)
		{
			try 
			{
				Process p = Runtime.getRuntime().exec(cmd);
				int i = p.waitFor();
				if (i == 0)
				{
					stdInput = new BufferedReader(new InputStreamReader(p.getInputStream()));
					String line = stdInput.readLine();
					while(line!=null)
					{
						if(retString==null)
						{
							retString = line;
						}
						else
						{
							retString = retString + "\n" +line;
						}
						line = stdInput.readLine();
					}
					
						
					stdInput.close();
				}
			}
			catch(Exception e)
			{
				e.printStackTrace();

			}

		}

		return retString;

	}

	public static void displayMap(HashMap map)
	{
		if(map!=null)
		{
			Set keys = map.keySet();
	        	Iterator it = keys.iterator();
	        	while (it.hasNext()) 
			{
				Object key = it.next();
				Object value = map.get(key);

				System.out.println(key + " => "+value);
	                }
		}
        }


	public static double roundTwoDecimals(double d) 
	{
        	DecimalFormat twoDForm = new DecimalFormat("#.##");
		return Double.valueOf(twoDForm.format(d));
	}


	
	
	public static HashMap readFasta(String file)
	{
		HashMap fasta=null;

		if(file !=null)
		{
			try 
			{	
       				BufferedReader in = new BufferedReader(new FileReader(file));
				fasta = new HashMap();
        			String line = in.readLine();
				boolean start = false;
				
				String fastaSeq="";
				String geneName="";
			        while (line != null) 
				{	
					line = line.trim();
					

					if(line.startsWith(">"))
					{
						
						if(!start)
						{
							start = true;
							
							
						}
						else
						{
							if((!fastaSeq.equals("")) && (!geneName.equals("")))
							{
								fastaSeq = fastaSeq.replaceAll("\\s+","");
								fasta.put(geneName,fastaSeq);
								//System.out.println(fastaSeq.length());
								
								
							}
							

						}
						fastaSeq="";
						geneName = new String(line);
						geneName = geneName.replace(">","");	
						geneName = geneName.trim();


					}
					else
					{

						fastaSeq = fastaSeq + line;

					}

					line = in.readLine();
				}

				// the last seq

				if((!fastaSeq.equals("")) && (!geneName.equals("")))
				{
					fastaSeq = fastaSeq.replaceAll("\\s+","");
					fasta.put(geneName,fastaSeq);
					
				}

			}
			catch(Exception e)
			{

				e.printStackTrace();
			}

		}

		return fasta;

	}


	public LinkedHashMap sortHashMapByValues(HashMap map) 
	{
		List mapKeys = new ArrayList(map.keySet());
		List mapValues = new ArrayList(map.values());
		Collections.sort(mapValues);
		Collections.sort(mapKeys);

		LinkedHashMap sortedMap = new LinkedHashMap();

		Iterator valueIt = mapValues.iterator();
		while (valueIt.hasNext()) 
		{
			Object val = valueIt.next();
			Iterator keyIt = mapKeys.iterator();

			while (keyIt.hasNext()) 
			{
			        Object key = keyIt.next();
			        String comp1 = map.get(key).toString();
			        String comp2 = val.toString();
			        
			        if (comp1.equals(comp2))
				{
				        map.remove(key);
				        mapKeys.remove(key);
				        sortedMap.put((String)key, (Double)val);
				        break;
			        }

			}

		}
		return sortedMap;
	}


}
