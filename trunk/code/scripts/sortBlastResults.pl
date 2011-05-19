#!/usr/bin/perl

use strict;
use Getopt::Std;
use Cwd;


sub printOptions
{
	print("Usage :: perl sortBlastResults.pl\n");
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

	my $message = "Logging messages from sortBlastResults.pl......";
	my $priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";



	chdir($working_dir);

	my $identity_scores_dir = "$working_dir/identity-scores";

	if(-d $identity_scores_dir)	
	{
		system "rm -rf $identity_scores_dir";
	}

	mkdir($identity_scores_dir);
	
	my $prodigal_genes = "$working_dir/prodigal_genes";

	if(not -d "$prodigal_genes")
	{

		$message = "Directory $prodigal_genes is not found";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	}

	my $percent_id_file = "$working_dir/percent-identity.txt";
	
	if(not -e $percent_id_file)
	{
		
		$message = "Percent identity file $percent_id_file does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	}

	
	
	chdir("$prodigal_genes");


	my $genome_lst = `ls`;
	my @genomes = split(/\n/,$genome_lst);
	
	foreach my $genome (@genomes)
	{
		
		chomp($genome);
		$genome = trim($genome);

		my $genes_file = "$prodigal_genes/$genome";
		open(GENE_FILE,"$genes_file") or die("Could not open file $genes_file\n");
		my @gene_names = <GENE_FILE>;
		close GENE_FILE;

		my $temp = "$genome";
		$temp =~ s/-genes//;
		my $sorted_id_scores = "$identity_scores_dir/$temp-idscores-sorted.txt";

		open(SORTED_OUT,">$sorted_id_scores") or die("Could not open file $sorted_id_scores");
		
		foreach my $gene (@gene_names)
		{
			chomp($gene);
			$gene = trim($gene);
			
			$message = "............$gene............";
			$priority = 3;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


			my $grep_search_str = "$gene|";	

			my $potential_best_pairs_lst = `grep \'$grep_search_str\' $percent_id_file`;
			#print("$potential_best_pairs_lst\n");
			
			if($potential_best_pairs_lst ne "")
			{
				## each line in the results from grep look like this <gene1|gene2>,<percent id>
				#my %best_pairs_map;

				my @best_pairs = split(/\n/,$potential_best_pairs_lst);

				my %gene_pairs;
				my %gene_pair_values;
				my $idx =1;
				foreach my $pair (@best_pairs)				 
				{
					chomp($pair);
					$pair = trim($pair);
					if($pair ne "")
					{
					
						my @pieces = split(/,/,$pair);
						my $count = @pieces;

						if($count eq 2)
						{
							my $key = trim($pieces[0]);
							my $val = trim($pieces[1]);

							#$best_pairs_map{$key} = $val;
							$gene_pairs{$idx} = $key;
							$gene_pair_values{$idx} = $val;
							$idx++;
		
	
						}
		
					}
			
				}

				#print("Before sorting\n");
				#print("\ngene pairs\n");

				#while ( my ($key, $value) = each(%gene_pairs) ) {
					#my $val = $gene_pair_values{$value};
				 #       print "$key => $value\n";
    				#}

				#print("\nvalues\n");

				#while ( my ($key, $value) = each(%gene_pair_values) ) {
					#my $val = $gene_pair_values{$value};
				 #       print "$key => $value\n";
    				#}

				#print("\npairs and values\n");
	
				#while ( my ($key, $value) = each(%gene_pairs) ) {
				#	my $val = $gene_pair_values{$key};
				 #       print "$value => $val\n";
    				#}

				#my @sorted_best_pairs_keys = sort {$best_pairs_map{$b} <=> $best_pairs_map{$a}} keys %best_pairs_map;

				my @sorted_best_pairs_keys = sort {$gene_pair_values{$b} <=> $gene_pair_values{$a}} keys %gene_pair_values;

				#print("after sorting\n");
				foreach my $key (@sorted_best_pairs_keys)
				{
					my $g_pair = $gene_pairs{$key};
					my $g_pair_val = $gene_pair_values{$key};
					print SORTED_OUT "$g_pair,$g_pair_val\n";

					#print("$g_pair,$g_pair_val\n");

					#print("$key,$best_pairs_map{$key}\n");
					#my $val = $best_pairs_map{$key};
					#print SORTED_OUT "$key,$val\n";
				}
				
			}  ## end if($potential_best_pairs_lst ne "")


		
		} ## end foreach gene in cur genome
	
		close SORTED_OUT;	
	
	} ## end foreach genome

	$message = "Done..";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


	
}
main;
