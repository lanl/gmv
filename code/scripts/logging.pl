#!/usr/bin/perl

use strict;
use Getopt::Std;
use Time::localtime;


sub printOptions
{
	print("Usage :: perl logging.pl\n");
	print("-v - Logging level 1 - ERROR, 2 - WARNING, 3 - INFO. Default is 1.\n");
	print("-l - Log file with complete path. Default - Log messages will be written to standard output.\n");
	print("-m - Message to be written. <REQUIRED>\n");
	print("-p - Message priority 1 - ERROR, 2 - WARNING, 3 - INFO. <REQUIRED>\n");


}

sub main
{

	our($opt_l,$opt_v,$opt_m,$opt_p);

	getopt("vlmp");

	#print("\n\n***************message $opt_m");
	#print("log level $opt_v\n");
	#print("priority $opt_p\n");
	#print("log file $opt_l\n");
	
	if((not defined $opt_m) || (not defined $opt_p)) 
	{
		printOptions;
		exit(0);
	
	}

	my $message = $opt_m;
	my $log_level = int($opt_v);
	my $log_file = $opt_l;
	my $priority = int($opt_p);

	
	if(not defined $log_level)
	{
		$log_level=1;
	}

	if(not defined $log_file)
	{

		$log_file = "nodef";
	}

	if($log_file eq "")
	{
		$log_file = "nodef";
	}


	my %message_type_map;

	$message_type_map{"1"} = "ERROR";
	$message_type_map{"2"} = "WARNING";
	$message_type_map{"3"} = "INFO";

	my $message_type = $message_type_map{$priority};
	

	
	if($priority <= $log_level)
	{
		#my @cur_time = localtime(time);
		#my $time_stamp = join(' ',@cur_time);
		
		my $time_stamp = ctime();
	
		if((defined $log_file) && ($log_file ne "nodef"))
		{
			open(OUT, ">>$log_file") or die("Could not open file $log_file\n");
			if($priority eq 1)
			{
				print OUT "$message_type\n";
			}
			print OUT "$time_stamp - $message\n";
			close OUT;

			if($priority eq 1)
			{
				print("Error occured. Check the log file for details\n");

			}

		}
		else
		{
			if($priority eq 1)
			{
				print("$message_type\n");
			}
			print("$time_stamp - $message\n");
		}

		
	}

}

main;
