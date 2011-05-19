#!/usr/bin/perl

use strict;
use Getopt::Std;
use Cwd;


sub printOptions
{
	print("Usage :: perl getPercentIdForBestGenePairs.pl\n");
	print("-d  Working directory. <REQUIRED> \n");
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

	our($opt_d,$opt_v,$opt_l,$opt_p,$opt_s);

	getopt("dvlsp");

	if((not defined $opt_d) || (not defined $opt_p) || (not defined $opt_s))
	{
		printOptions;
		exit(0);
	
	}

	my $working_dir = $opt_d;
	my $log = $opt_v;
	my $log_file = $opt_l;
	my $perl_dir = $opt_p;
	my $scripts_dir = $opt_s;
	



	if(not defined $log)
	{
		$log = 1;
	}

	my $message = "Logging messages from getPercentIdForBestGenePairs.pl......";
	my $priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


	chdir($working_dir);

	my $best_gene_pairs_file = "$working_dir/best-gene-pairs.txt";
	my $percent_id_file = "$working_dir/percent-identity.txt";

	if(not -e $best_gene_pairs_file)
	{
		$message = "$best_gene_pairs_file does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);
	}


	if(not -e $percent_id_file)
	{
		$message = "$percent_id_file does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);
	}

	my $output = "$working_dir/best-gene-pairs-percent-id.txt";

	open(IN,"$best_gene_pairs_file") or die("Could not open file $best_gene_pairs_file\n");
	my @data = <IN>;
	close IN;

	open(OUT,">$output") or die("Could not open file $output\n");

	foreach my $line (@data)
	{
		chomp($line);
		$line = trim($line);

		my $grep_res = `grep \'$line\' $percent_id_file`;

		if($grep_res ne "")
		{
			chomp($grep_res);
			print OUT "$grep_res\n";

		}
	}

	close OUT;
	
	$message = "Done..";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


}

main;
