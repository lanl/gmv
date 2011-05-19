package gov.lanl.burk.util;


import java.util.*;


/*********************************************************************************************************************************************************

Author - Sindhu Vijaya Raghavan


***********************************************************************************************************************************************************/



public class Statistics
{
	double min=0.0;
	double max=0.0;
	double avg=0.0;
	double stdDev=0.0;
	Vector numbers=null;

	public Statistics()
	{


	}

	public Statistics(Vector iLst)
	{
		numbers = iLst;
	}

	public void setLst(Vector iLst)
	{

		numbers = iLst;
	}

	public Vector getLst()
	{
		return numbers;
	}

	public double getMin()
	{

		return min;
	}
	
	public double getMax()
	{
		return max;
	}

	public double getAvg()
	{
		return avg;
	}

	public double getStdDev()
	{
		return stdDev;
	}

	public void computeStats()
	{
		if(numbers!=null)
		{
			int size = numbers.size();
			if(size>0)
			{
				if(Collections.min(numbers)!=null)
				{				
					Double minObj = (Double)Collections.min(numbers);
					min = minObj.doubleValue();

				}
				
				if(Collections.max(numbers)!=null)
				{				
					Double maxObj = (Double)Collections.max(numbers); 
					max = maxObj.doubleValue();

				}	
				double lst[] = new double[size];
				double sum=0;
	
				for(int i=0;i<size;i++)
				{
					Double item = (Double)numbers.get(i);
					double val = item.doubleValue();
					sum+=val;
					lst[i] = val;
				}
				avg = sum/size;

				double diffSq=0;
				for(int i=0;i<size;i++)
				{
					double temp = (lst[i] - avg)*(lst[i] - avg);

					diffSq+=temp;	
				}
				diffSq = diffSq/size;

				stdDev = Math.sqrt(diffSq);
				
			}


		}
	}

}