#!/usr/bin/perl

use strict;
use Getopt::Std;


sub printOptions
{
	print("Usage :: perl createWorkingDir.pl\n");
	print("-i  Input directory contains all the sequence files in fasta format. <REQUIRED>\n");
	print("-o  Output directory contains the results. <REQUIRED> \n");
	print("-v  Logging level. 1 is ERROR, 2 is WARNING, 3 is INFO. Default is 1.\n");
	print("-l  Log file with complete path. Default - Log messages will be written to standard output.\n");
	print("-p  Perl directory. <REQUIRED> \n");
	print("-s  Scripts directory. <REQUIRED> \n");
	


}


sub main
{
	our($opt_i,$opt_o,$opt_v,$opt_p,$opt_s,$opt_l);

	getopt("iovlsp");

	if((not defined $opt_i) || (not defined $opt_o) || (not defined $opt_p) || (not defined $opt_s))
	{
		printOptions;
		exit(0);
	
	}

	my $input_dir = $opt_i;
	my $output_dir = $opt_o;
	my $log = $opt_v;
	my $log_file = $opt_l;
	my $perl_dir = $opt_p;
	my $scripts_dir = $opt_s;

	if(not defined $log)
	{
		$log = 1;
	}

	my $message = "Logging messages from createWorkingDir.pl......";
	my $priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


	## create the fasta directory under the output directory
	
	chdir("$output_dir");
	
	if(-d "$output_dir/fasta")
	{
		system "rm -rf $output_dir/fasta";
	}	
	
	mkdir("fasta");
	chdir("fasta");


	## change to input directory and do ls to get the list of files/subdirectories. All files in the input directory will be assumed to be a sequence file. Subdirectories are ignored.
	chdir($input_dir);
	
	my $files = `ls`;
	my @pieces = split(/\n/,$files);

	
	foreach my $file (@pieces)
	{
		chomp($file);
		if(not -d $file)
		{

			if(not $file =~ m/~/)
			{

				$message = "Sequence file $file.";
				$priority = 3;
				system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
	
				## create directory structure in the output directory
				## use the name of the file to name the directory - look for '.' in the file name. Use everything before the first '.' for the directory name. Replace any space with underscore
	
				my @pcs = split(/\./,$file);
				my $directory_name = $pcs[0];
				$directory_name =~ s/\s+/_/; 
	
				$message = "Creating $directory_name under $output_dir/fasta.";
				$priority = 3;
				system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
	
	
				system("mkdir -p $output_dir/fasta/$directory_name");
	
				system "cp $input_dir/$file $output_dir/fasta/$directory_name";
			}
		}
		
	}

	$message = "Done..";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p \'$priority\' -m \'$message\'";


}

main;
