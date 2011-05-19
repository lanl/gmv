#!/usr/bin/perl

use strict;
use Getopt::Std;
use Cwd;


sub printOptions
{
	print("Usage :: perl trainProdigal.pl\n");
	print("-d  Working directory. <REQUIRED> \n");
	print("-c  Prodigal directory. <REQUIRED> \n");
	print("-v  Logging level. 1 is ERROR, 2 is WARNING, 3 is INFO. Default is 1.\n");
	print("-l  Log file with complete path. Default - Log messages will be written to standard output.\n");
	print("-p  Perl directory. <REQUIRED> \n");
	print("-s  Scripts directory. <REQUIRED> \n");


}

sub main
{
	our($opt_d,$opt_v,$opt_c,$opt_l,$opt_p,$opt_s);

	getopt("dvclsp");

	if((not defined $opt_d) || (not defined $opt_c) || (not defined $opt_p) || (not defined $opt_s))
	{
		printOptions;
		exit(0);
	
	}

	my $working_dir = $opt_d;
	my $prodigal_command_dir = $opt_c;
	my $log = $opt_v;
	my $log_file = $opt_l;
	my $perl_dir = $opt_p;
	my $scripts_dir = $opt_s;


	if(not defined $log)
	{
		$log = 1;
	}

	my $message = "Logging messages from trainProdigal.pl......";
	my $priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


	if(-d "$working_dir/fasta/")
	{
		chdir("$working_dir/fasta/");
	}
	else
	{
		$message = "Directory $working_dir/fasta/ does not exist.\n";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);
	}

	my $lst = `ls`;
	my @pcs = split(/\n/,"$lst");

	foreach my $genome_dir (@pcs)
	{
		chomp($genome_dir);

		my $prodigal_training_dir = "$working_dir/fasta/$genome_dir/prodigal_training/";

		my $cwd = getcwd;

		chdir($prodigal_training_dir);

		## this directory should have the full fasta file (and its backup maybe there)

		my $file_lst = `ls`;
		my @files = split(/\n/,$file_lst);
		my $file_count = @files;

		if($file_count > 2)
		{
			$message = "Multiple files found in the $prodigal_training_dir\n";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			exit(-1);

		}
		else
		{	
			my $fasta_file;
			if($file_count eq 1)
			{
				$fasta_file = $files[0];
			}
			else
			{	
				foreach my $file (@files)
				{
					chomp($file);
					if(not $file =~ m/~/)
					{
						$fasta_file = $file;
					}

				}
			}

			my $train_file = $fasta_file;
			$train_file =~ s/.fasta//;
			$train_file = $train_file . ".trn";

			my $train_file_path = "$prodigal_training_dir/$train_file";
			my $fasta_file_path = "$prodigal_training_dir/$fasta_file";
		
			$message = "\n\nCalling prodigal for training on $genome_dir...........\n";
			$message = $message . "Fasta file is $fasta_file_path\n";
			$message = $message . "Training file is $train_file_path \n";
			$priority = 3;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
	
			system "$prodigal_command_dir/prodigal -t $train_file_path < $fasta_file_path";
	
		}


				
	}

	$message = "Done..";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
	
}
main;
