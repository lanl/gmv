#!/usr/bin/perl

use strict;
use Getopt::Std;
use Cwd;


sub printOptions
{
	print("Usage :: perl getBestGenePairs.pl\n");
	print("-d  Working directory. <REQUIRED> \n");
	print("-v  Logging level. 1 is ERROR, 2 is WARNING, 3 is INFO. Default is 1.\n");
	print("-l  Log file with complete path. Default - Log messages will be written to standard output.\n");
	print("-p  Perl directory. <REQUIRED> \n");
	print("-s  Scripts directory. <REQUIRED> \n");


}

sub printMap
{
	my %map = shift;

	while ((my $key, my $value) = each(%map))
	{
	     print "$key --- $value\n";
	}


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

	if((not defined $opt_d) || (not defined $opt_s) || (not defined $opt_p)) 
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

	my $message = "Logging messages from getBestGenePairs.pl......";
	my $priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


	chdir($working_dir);

	if(-d "warnings")
	{
		system "rm -rf warnings";

	}
	
	mkdir("warnings");

	my $prodigal_genes = "$working_dir/prodigal_genes";

	if(not -d "$prodigal_genes")
	{

		$message = "Directory $prodigal_genes is not found";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);

	}

	
	
	my $tie_file = "$working_dir/warnings/gene-pairs-tied.txt";
	my $error_file = "$working_dir/warnings/inconsistent-gene-pairs.txt";
	my $output_file = "$working_dir/best-gene-pairs.txt";
	my $output_file2 = "$working_dir/best-gene-pairs-percent-id.txt";

	## open files

	open(TIE,">$tie_file") or die("Could not open file $tie_file\n");
	open(ERROR,">$error_file") or die("Could not open file $error_file\n");
	open(OUT,">$output_file") or die("Could not open file $output_file\n");
	open(OUT2,">$output_file2") or die("Could not open file $output_file2\n");



	chdir("$prodigal_genes");

	## for each genome file and each gene in the genome, search the best blast pair across all the genes in all the other genomes including itself

	my $genome_lst = `ls`;
	my @genomes = split(/\n/,$genome_lst);

	my @genome_names;
	my $index =0;
	foreach my $genome (@genomes)
	{
		chomp($genome);
		$genome = trim($genome);
		$genome =~ s/-genes//;
		$genome_names[$index++] = trim($genome);
			
	}

	my $all_genes_file = "$working_dir/all-genes.txt";
	
	if(not -e $all_genes_file)
	{
		$message = "$all_genes_file does not exist.";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);
	}

	open(GENE_FILE,"$all_genes_file") or die("Could not open file $all_genes_file\n");
	my @gene_names = <GENE_FILE>;
	close GENE_FILE;

	my $idscores_dir = "$working_dir/identity-scores";
	if(not -d $idscores_dir)
	{
		$message = "$idscores_dir does not exist.";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);
	}

	## check if all the idscores files are present

	foreach my $genome (@genome_names)
	{
		my $file = "$idscores_dir/$genome"."-idscores-sorted.txt";
		if(not -e $file)
		{

			$message = "$file does not exist.";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			exit(-1);
		}
		else
		{	$message = "$file exists.";
			$priority = 3;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		}

	}	
		
	foreach my $gene (@gene_names)
	{
		
		chomp($gene);
		$gene = trim($gene);
		
		if($gene ne "")
		{

			my $cur_genome;
			my $loc_index = index($gene,'_');
			
			if($loc_index ne -1)
			{
				$cur_genome = substr($gene,0,$loc_index);
				$cur_genome = trim($cur_genome);

			}

			my $percent_id_file = "$idscores_dir/$cur_genome"."-idscores-sorted.txt";
			
		
			## now look for the best possible match for gene in the other genomes including itself

			foreach my $search_genome (@genome_names)
			{
				chomp($search_genome);
				$search_genome = trim($search_genome);
				my $grep_search_str = "$gene|$search_genome"."_";
				my $potential_best_pairs_lst = `grep \'$grep_search_str\' $percent_id_file`;
				
				
				if($potential_best_pairs_lst ne "")
				{
					## each line in the results from grep look like this <gene1|gene2>,<percent id>
					#my %best_pairs_map;

					my @best_pairs = split(/\n/,$potential_best_pairs_lst);
					my $best_pairs_count = @best_pairs;

					my $best_match;
					my $best_score;
					my $second_best_score;
					my $second_best_match;
					my $isTie = 0;

					if($best_pairs_count eq 1)
					{
						my $pair = $best_pairs[0];
						chomp($pair);
						$pair = trim($pair);
						if($pair ne "")
						{
						
							my @pieces = split(/,/,$pair);
							my $count = @pieces;
					
							if($count eq 2)
							{
								$best_match = trim($pieces[0]);
								$best_score = trim($pieces[1]);
							}

						}	
					}
					elsif($best_pairs_count > 1)
					{
						
						## get the best pair
						my $pair = $best_pairs[0];
						chomp($pair);
						$pair = trim($pair);
						if($pair ne "")
						{
						
							my @pieces = split(/,/,$pair);
							my $count = @pieces;
					
							if($count eq 2)
							{
								$best_match = trim($pieces[0]);
								$best_score = trim($pieces[1]);
							}

						}

						## get the second best

						$pair = $best_pairs[1];
						chomp($pair);
						$pair = trim($pair);
						if($pair ne "")
						{
						
							my @pieces = split(/,/,$pair);
							my $count = @pieces;
					
							if($count eq 2)
							{
								$second_best_match = trim($pieces[0]);
								$second_best_score = trim($pieces[1]);
							}

						}



					}

					
					if((defined $second_best_score) && (defined $second_best_match))
					{
						if($best_score == $second_best_score)
						{
							$isTie =1;
							if($log eq 1)
							{
								$message = "There is a tie between the pairs $best_match and $second_best_match ($best_score).";
								$priority = 2;
								system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

							}
							print TIE "$best_match, $second_best_match, $best_score\n";

						}

					}

					my $isError = 0;
					
					## now check for errors
					
					if($isTie eq 1)
					{

						last; ## move to the next gene. do not search for this gene in other genomes. this gene is discarded.
					}

					if($isTie eq 0 && defined $best_match)
					{
					
						my @best_genes = split(/\|/,$best_match);
						my $gene_count = @best_genes;

						#print("gene count is $gene_count\n");

						if($gene_count eq 2)
						{
							my $gene_a = trim($best_genes[0]);
							my $gene_b = trim($best_genes[1]);

							if($gene_a =~ m/$cur_genome/ && $gene_b =~ m/$cur_genome/)
							{
								## both the genes belong to the same genome. Hence the two genes have to be identical
								if($gene_a ne $gene_b)
								{
									$isError =1;
								}
								
							}

							if($isError eq 0)	
							{

								print OUT "$best_match\n";
								print OUT2 "$best_match|$best_score\n";
							}

							else
							{
								print ERROR "$best_match\n";
							}

						}
						else
						{
							$message = "Incorrect number of genes in the gene pair $best_match.";
							$priority = 1;
							system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

							exit(-1);

						}

					}
				}  ## end if($potential_best_pairs_lst ne "")
			}## end foreach search genome

		}
		
	} ## end foreach gene in cur genome

	#my $end = time();
	#my $time_taken = ($end-$start)/60;
	#print("Ended.. Time taken is $time_taken\n");	
	

	close TIE;
	close ERROR;
	close OUT;
	close OUT2;

	$message = "Done..";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


}
main;
