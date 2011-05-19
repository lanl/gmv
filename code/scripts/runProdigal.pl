#!/usr/bin/perl

use strict;
use Getopt::Std;
use Cwd;


sub printOptions
{
	print("Usage :: perl runProdigal.pl\n");
	print("-d  Working directory. <REQUIRED> \n");
	print("-c  Prodigal directory. <REQUIRED> \n");
	print("-v  Logging level. 1 is ERROR, 2 is WARNING, 3 is INFO. Default is 1.\n");
	print("-l  Log file with complete path. Default - Log messages will be written to standard output.\n");
	print("-p  Perl directory. <REQUIRED> \n");
	print("-s  Scripts directory. <REQUIRED> \n");


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
	our($opt_d,$opt_v,$opt_c,$opt_l,$opt_p,$opt_s);

	getopt("dvcslp");

	if((not defined $opt_d) || (not defined $opt_c) || (not defined $opt_s) || (not defined $opt_p))
	{
		printOptions;
		exit(-1);
	
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


	my $message = "Logging messages from runProdigal.pl......";
	my $priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


	if(-d "$working_dir/fasta/")
	{
		chdir("$working_dir/fasta/");
	}
	else
	{
		$message = "Directory $working_dir/fasta/ does not exist.";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);
	}


	## parse genome name mapping file

	my $genome_name_mapping = "$working_dir/genome-name-mapping.txt";
	
	open(MAP,"$genome_name_mapping") or die("Could not open file $genome_name_mapping\n");
	my @data = <MAP>;
	close MAP;



	my %genome_name_table;

	foreach my $item (@data)
	{
		chomp($item);
		my @pieces = split(/=/,$item);
		my $count = @pieces;

		if($count eq 2)
		{
			my $key = trim($pieces[0]);
			my $val = trim($pieces[1]);

			$genome_name_table{$key} = $val;
			
		}
	}


	my $lst = `ls`;
	my @pcs = split(/\n/,"$lst");

	foreach my $genome_dir (@pcs)
	{
		chomp($genome_dir);

		my $prodigal_prediction_dir = "$working_dir/fasta/$genome_dir/prodigal_prediction/";
		my $prodigal_results_dir = "$working_dir/fasta/$genome_dir/prodigal_results/";
		my $genome_name = $genome_name_table{$genome_dir};

		my $training_file = "$working_dir/fasta/$genome_dir/prodigal_training/$genome_name-full.trn";

		##go through the prediction dir. For each fasta file, call prodigal with the right set of parameters
		
		chdir("$prodigal_prediction_dir");
		
		my $seq_lst = `ls`;
		my @files = split(/\n/,$seq_lst);

		
		foreach my $file (@files)
		{
			chomp($file);
			if(not $file =~ m/~/)
			{
				my $fasta_file = $file;
				
				my $temp = $fasta_file;
	
				$temp =~ s/.fasta//;
			
				my $score_file = "$working_dir/fasta/$genome_dir/prodigal_results/scores/$temp-scores";
				my $protein_file = "$working_dir/fasta/$genome_dir/prodigal_results/proteins/$temp-proteins";
				my $genes_file = "$working_dir/fasta/$genome_dir/prodigal_results/genes/$temp-genes";


				$message = "Calling prodigal for gene prediction for $fasta_file...\n";
				$message = $message . "Genome sequence is $fasta_file.\n";
				$message = $message . "Training file is $training_file.\n";
				$message = $message . "Gene prediction scores can be found in $score_file.\n";
				$message = $message . "Predicted genes can be found in $genes_file. \n";
				$message = $message . "Equivalent proteins can be found in $protein_file.";
				$priority = 3;
				system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

				system "$prodigal_command_dir/prodigal -c -t $training_file -s $score_file -a $protein_file < $prodigal_prediction_dir/$fasta_file > $genes_file";
				
			}

		}
		
	
	}

	$message = "Done..";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
	

}



main;
