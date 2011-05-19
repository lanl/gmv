#!/usr/bin/perl

use strict;
use Getopt::Std;
use Cwd;


sub printOptions
{
	print("Usage :: perl predictCommonStart.pl\n");
	print("-d  Working directory. <REQUIRED> \n");
	print("-v  Logging level. 1 is ERROR, 2 is WARNING, 3 is INFO. Default is 1.\n");
	print("-l  Log file with complete path. Default - Log messages will be written to standard output.\n");
	print("-p  Perl directory. <REQUIRED> \n");
	print("-s  Scripts directory. <REQUIRED> \n");
	print("-j Java bin directory. <REQUIRED> \n");
	print("-c Java code directory. <REQUIRED> \n");	


}

sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub main
{

	our($opt_d,$opt_v,$opt_l,$opt_p,$opt_s,$opt_j,$opt_c);

	getopt("dvlspjc");

	if((not defined $opt_d) || (not defined $opt_p) || (not defined $opt_s) || (not defined $opt_j) || (not defined $opt_c))
	{ 
		printOptions;
		exit(0);
	
	}

	my $working_dir = $opt_d;
	my $log = $opt_v;
	my $log_file = $opt_l;
	my $perl_dir = $opt_p;
	my $scripts_dir = $opt_s;
	my $java_bin_dir = $opt_j;
	my $java_code_dir = $opt_c;


	if(not defined $log)
	{
		$log = 1;
	}

	my $message = "Logging messages from predictCommonStart.pl......";
	my $priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";



	chdir($working_dir);
	
	my $rel_start_pos_file = "$working_dir/selected-genes-rel-startsites.txt";

	if(not -e $rel_start_pos_file)
	{
		$message = "$rel_start_pos_file does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
		exit(-1);	
	}
	
	my $alignment_dir = "$working_dir/alignments/output";

	if(not -d $alignment_dir)
	{
		$message = "$alignment_dir does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
		exit(-1);	

	}

	my $percent_id_file = "$working_dir/best-gene-pairs-percent-id.txt";

	if(not -e $percent_id_file)
	{
		$message = "$percent_id_file does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
		exit(-1);	

	}

	my $feature_files_dir = "$working_dir/alignments/feature-files";

	if(-d $feature_files_dir)
	{

		system "rm -rf $feature_files_dir";
	}

	mkdir($feature_files_dir);

	my $prediction_dir = "$working_dir/prediction";

	if(-d $prediction_dir)
	{

		system "rm -rf $prediction_dir";
	}

	mkdir($prediction_dir);


	## now call the java program

	chdir($java_code_dir);
	
	my $classpath = ".:$java_code_dir/bin";
	my $java_exec_cmd;

	if(($log_file ne "") && ($log_file ne "nodef"))
	{
	
		$java_exec_cmd = "$java_bin_dir/java -Xms256m -Xmx256m -classpath $classpath gov.lanl.burk.genefinder.CommonStartFinder $rel_start_pos_file $alignment_dir $feature_files_dir $percent_id_file $prediction_dir $log $log_file";
	}
	else
	{
		$java_exec_cmd = "$java_bin_dir/java -classpath $classpath gov.lanl.burk.genefinder.CommonStartFinder $rel_start_pos_file $alignment_dir $feature_files_dir $percent_id_file $prediction_dir $log";
	}
	
	system "$java_exec_cmd";


	$message = "Done..";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

}

main;
