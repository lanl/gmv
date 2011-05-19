package gov.lanl.burk.util;


import gov.lanl.burk.util.*;
import java.util.*;



public class CompareAlignments
{

	HashMap align1 =null;
	HashMap align2 = null;
	public CompareAlignments()
	{
	}


	public static void printOptions()
	{
		System.out.println("Usage");
		System.out.println("arg0 File 1 <REQUIRED>");
		System.out.println("arg1 File 2 <REQUIRED>");
		
	}

	public void compareAlign()
	{

		if(align1!=null && align2!=null)
		{
			boolean flag = true;
			Set keys = align1.keySet();
	        	Iterator it = keys.iterator();
	        	while (it.hasNext()) 
			{
				String geneId = (String)it.next();
				String seq1 = (String)align1.get(geneId);
				String seq2 = (String)align2.get(geneId);

				seq1 = seq1.trim();
				if(seq2!=null)
				{
					seq2 = seq2.trim();
			
					if(!seq1.equals(seq2))
					{
						System.out.println(geneId + " no match");
						System.out.println(seq1.length() + "--"+seq2.length());
						flag = false;
					}
					else
					{
						//System.out.println(geneId + " match");
					}
				}
				else
				{
					flag = false;
					System.out.println(geneId + " not found in sequence 2");

				}

	                }

			if(flag)
			{
				//System.out.println("passed");

			}
			else
			{
				System.out.println("failed");

			}


		}

	}

	public void readFiles(String file1, String file2)
	{

		if(file1!=null)
		{
			align1 = Framework.readFasta(file1);
			//System.out.println("Alignment 1");
			//Framework.displayMap(align1);

		}
		else
		{
			System.out.println(file1 + " is null");
			System.exit(0);
		}

		if(file2!=null)
		{
			align2 = Framework.readFasta(file2);
			//System.out.println("Alignment 2");
			//Framework.displayMap(align2);

		}
		else
		{
			System.out.println(file2 + " is null");
			System.exit(0);
		}

	

	}



	public static void main(String args[])
	{
		if(args!=null)
		{

			if(args.length == 2)
			{
				String file1 = (args[0]).trim();
				String file2 = (args[1]).trim();

				CompareAlignments compareObj = new CompareAlignments();	
				compareObj.readFiles(file1,file2);
				compareObj.compareAlign();
						
			}
			else
			{

				CompareAlignments.printOptions();
			}
		}
		else
		{

			CompareAlignments.printOptions();
		}


	}

}