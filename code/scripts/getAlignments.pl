#!/usr/bin/perl

use strict;
use Getopt::Std;
use Cwd;


sub printOptions
{
	print("Usage :: perl getAlignments.pl\n");
	print("-d  Working directory. <REQUIRED> \n");
	print("-v  Logging level. 1 is ERROR, 2 is WARNING, 3 is INFO. Default is 1.\n");
	print("-l  Log file with complete path. Default - Log messages will be written to standard output.\n");
	print("-r  Muscle directory. <REQUIRED> \n");
	print("-p  Perl directory. <REQUIRED> \n");
	print("-s  Scripts directory. <REQUIRED>\n");


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

	our($opt_d,$opt_v,$opt_r,$opt_p,$opt_s,$opt_l);

	getopt("dvrpsl");

	if((not defined $opt_d) || (not defined $opt_r) || (not defined $opt_p) || (not defined $opt_s))
	{
		printOptions;
		exit(0);
	
	}

	my $working_dir = $opt_d;
	my $log = $opt_v;
	my $muscle_dir = $opt_r;
	my $perl_dir = $opt_p;
	my $scripts_dir = $opt_s;
	my $log_file = $opt_l;



	if(not defined $log)
	{
		$log = 1;
	}

	my $message = "Logging messages from getAlignments.pl......";
	my $priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


	chdir($working_dir);

	##check if the alignment directory exists
		
	my $align_dir = "$working_dir/alignments";

	if(not -d $align_dir)
	{
		$message = "Directory $align_dir does not exist.";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);

	}


	my $input_dir = "$align_dir/input";
	
	my $output_dir = "$align_dir/output";


	if(not -d $input_dir)
	{
		$message = "Directory $input_dir does not exist.";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
		
		exit(-1);
	
	}

	

	chdir($input_dir);

	my $input_lst = `ls`;

	if($input_lst ne "")
	{
		my @input_files = split(/\n/,$input_lst);
	
		foreach my $input_file (@input_files)
		{
			chomp($input_file);
			
			my $input_file_path = "$input_dir/$input_file";

			my $output_file = "$input_file";
			$output_file =~ s/input/align/;

			my $output_file_path = "$output_dir/$output_file";

			#print("$input_file\n");
			#print("$output_file\n\n");

			my $return_val = system "$perl_dir/perl $scripts_dir/runMuscle.pl -i $input_file_path -o $output_file_path -d $muscle_dir";
	
			#my $mafft_dir = "/home/sindhu/tools/mafft_v6.0.7/mafft-6.707-with-extensions/bin/";
			#my $return_val = system "$perl_dir/perl $scripts_dir/runMAFFT.pl -i $input_file_path -o $output_file_path -d $mafft_dir";

			if($return_val ne 0)
			{

				$message = "Error while running Muscle for $input_file_path.";
				$priority = 1;
				system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
		
				exit(-1);
			}

		}

	}

	$message = "Done..";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


}

main;
