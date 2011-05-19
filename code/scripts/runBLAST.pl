#!/usr/bin/perl

use strict;
use Getopt::Std;
use Cwd;


sub printOptions
{
	print("Usage :: perl runBLAST.pl\n");
	print("-d  Working directory. <REQUIRED> \n");
	print("-c  Blast command directory. <REQUIRED> \n");
	print("-v  Logging level. 1 is ERROR, 2 is WARNING, 3 is INFO. Default is 1.\n");
	print("-l  Log file with complete path. Default - Log messages will be written to standard output.\n");
	print("-p  Perl directory. <REQUIRED> \n");
	print("-s  Scripts directory. <REQUIRED> \n");
	print("-n  Number of processors on the machine on which BLAST could be run. Default 1. \n");


}
sub main
{
	our($opt_d,$opt_v,$opt_c, $opt_n,$opt_l,$opt_s,$opt_p);

	getopt("dvcnslp");

	if((not defined $opt_d) || (not defined $opt_c) || (not defined $opt_p) || (not defined $opt_s))
	{
		printOptions;
		exit(-1);
	
	}

	my $working_dir = $opt_d;
	my $blast_cmd_dir = $opt_c;
	my $log = $opt_v;
	my $num_processors = $opt_n;
	my $log_file = $opt_l;
	my $perl_dir = $opt_p;
	my $scripts_dir = $opt_s;


	if(not defined $log)
	{
		$log = 1;
	}

	if(not defined $num_processors)
	{
		$num_processors =1;
	}

	my $message = "Logging messages from runBLAST.pl......";
	my $priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


	
	my $blast_query_file = "$working_dir/blast/blast-query";
	my $blast_db_file = "$working_dir/blast/db/blast-db";
	my $blast_results_file = "$working_dir/blast/results/blast-query-results";	

	if(not -e "$blast_query_file")
	{
		$message = "Blast query file  $blast_query_file does not exist.";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);
	}

	if(not -e "$blast_db_file")
	{
		$message = "Blast database file $blast_db_file does not exist.";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);
	
	}

	if(not -d "$working_dir/blast/results")
	{
		$message = "Blast results directory $working_dir/blast/results/ does not exist.";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);
	}

	
	##call blastp
	if(not -d "$blast_cmd_dir")
	{
		$message = "Blast command directory does not exist.";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);

	}

	$message = "Calling BLAST... \n";
	$priority = 3;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


	system "$blast_cmd_dir/blastall -F F -a $num_processors -p blastp -d $blast_db_file -i $blast_query_file -o $blast_results_file -m 8";


	$message = "Done..";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

}


main;
