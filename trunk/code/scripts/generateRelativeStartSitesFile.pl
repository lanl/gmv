#!/usr/bin/perl

use strict;
use Getopt::Std;
use Cwd;


sub printOptions
{
	print("Usage :: perl generateRelativeStartSitesFile.pl\n");
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

	my $message = "Logging messages from generateRelativeStartSitesFile.pl......";
	my $priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";



	chdir($working_dir);

	my $all_genes_start_sites_file = "$working_dir/all-genes-startsites.txt";
	my $msa_start_end_pos_file = "$working_dir/msa-start-end-pos.txt";

	if(not -e $all_genes_start_sites_file)
	{
		$message = "$all_genes_start_sites_file does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);	


	}

	if(not -e $msa_start_end_pos_file)
	{
		$message = "$msa_start_end_pos_file does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);	


	}

	open(IN,"$msa_start_end_pos_file") or die("Could not open file $msa_start_end_pos_file\n");
	my @data = <IN>;
	close IN;

	my $output_file = "$working_dir/selected-genes-rel-startsites.txt";

	open(OUT,">$output_file") or die("Could not open file $output_file");

	foreach my $line (@data)
	{
		chomp($line);
		$line = trim($line);

		my @pieces = split(/,/,$line);
		my $count = @pieces;

		if($count eq 4)
		{
			my $gene_name = trim($pieces[0]);
			my $rel_start = trim($pieces[1]);
			my $rel_end = trim($pieces[2]);
			my $dir = trim($pieces[3]);

			## now look for this gene in all-genes-startsites.txt
			
			my $grep_res = `grep \'$gene_name\' $all_genes_start_sites_file`;

			
			if($grep_res ne "")
			{
				my @res = split(/\n/,$grep_res);
				my $grep_count = @res;

				if($grep_count eq 1)
				{
					
					my $gene_entry = $res[0];
					chomp($gene_entry);
					$gene_entry = trim($gene_entry);
					$gene_entry = $gene_entry ." , ". $rel_start. " , ". $rel_end;
					print OUT "$gene_entry\n";


				}
				else	
				{
					$message = "Multiple entries are found for $gene_name in $all_genes_start_sites_file";
					$priority = 2;
					system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


				}

			}
			else
			{
				$message = "Start sites not found for $gene_name in $all_genes_start_sites_file";
				$priority = 2;
				system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


			}
	
		}
		else
		{
			$message = "Incorrect format for $line in $msa_start_end_pos_file";
			$priority = 2;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


		}
		

	}
	

	close OUT;

	$message = "Done..";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

}

main;
