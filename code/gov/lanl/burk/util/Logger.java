package gov.lanl.burk.util;


import gov.lanl.burk.util.*;

/*********************************************************************************************************************************************************

Author - Sindhu Vijaya Raghavan


***********************************************************************************************************************************************************/


public class Logger
{

	int ERROR =1;
	int WARNING = 2;
	int INFO =3;

	String logFile=null;
	int logLevel = 1;

	
	
	public Logger()
	{


	}
	public Logger(int iLevel)
	{
		logLevel = iLevel;
	}

	public Logger(String iFile)
	{
		logFile = iFile;

	}

	public Logger(int iLevel,String iFile)
	{
		
		logLevel = iLevel;
		logFile = iFile;
	}
	

	public void setLogLevel(int iLevel)
	{

		logLevel = iLevel;
	}

	public int getLogLevel()
	{

		return logLevel;
	}

	public void setLogFile(String iFile)
	{
		logFile = iFile;
	}

	public String getLogFile()
	{

		return logFile;
	}

	
	public void logMessage(int msgPriority, String msg)
	{
		boolean isAppend = true;
		if(msgPriority <= logLevel)
		{

			String timeStamp = Framework.getCurTime();
			String printMsg = timeStamp + " - " + msg;

			if(logFile !=null)
			{
				if(msgPriority == ERROR)
				{

					Framework.writeToFile(logFile,"ERROR",isAppend);
				}

				Framework.writeToFile(logFile,printMsg,isAppend);

				if(msgPriority == ERROR)
				{
					System.out.println("Error occured. Check the log file for details");
				}

				
				
			}
			else
			{
				if(msgPriority == ERROR)
				{

					System.out.println("ERROR");
				}

				System.out.println(printMsg);


			}



		}

	}


}
