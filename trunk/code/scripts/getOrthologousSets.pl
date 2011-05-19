#!/usr/bin/perl

use strict;
use Getopt::Std;
use Cwd;


sub printOptions
{
	print("Usage :: perl getOrthologousSets.pl\n");
	print("-d  Working directory. <REQUIRED> \n");
	print("-r  Reference genome. \n");
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

	our($opt_d,$opt_v,$opt_r,$opt_l,$opt_s,$opt_p);

	getopt("dvrlsp");

	if((not defined $opt_d) || (not defined $opt_s) || (not defined $opt_p))
	{
		printOptions;
		exit(0);
	
	}

	my $working_dir = $opt_d;
	my $log = $opt_v;
	my $user_ref_genome = $opt_r;
	my $log_file = $opt_l;
	my $perl_dir = $opt_p;
	my $scripts_dir = $opt_s;


	if(not defined $log)
	{
		$log = 1;
	}


	my $message = "Logging messages from getOrthologousSets.pl......";
	my $priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


	chdir($working_dir);

	if(-d "ortholog_sets")
	{

		system "rm -rf ortholog_sets";
	}	
	
	mkdir("ortholog_sets");


	my $prodigal_genes_dir = "$working_dir/prodigal_genes";
	
	if(not -d "$prodigal_genes_dir")
	{
		$message = "Directory $prodigal_genes_dir is not found";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);

	}

	chdir($prodigal_genes_dir);
	
	my $genomes_lst = `ls`;
	my @genomes = split(/\n/,$genomes_lst);
	my $num_genomes = @genomes;
	
	my $min_num;
	my $ref_genome;
	
	foreach my $genome (@genomes)
	{
		chomp($genome);
		
		## get the number of genes in each genome. Ref genome is the one with the minimum number of genes
		
		my $num_genes = `cat $genome | wc -l`;
		chomp($num_genes);
		$num_genes = trim($num_genes);
		
		if(not defined $min_num)
		{
			$min_num = $num_genes;
			$ref_genome = $genome;
		}
		else
		{
			if($min_num > $num_genes)
			{		
				$min_num = $num_genes;
				$ref_genome = $genome;
			}
		}

	}

	my $genome_mappings_file = "$working_dir/genome-name-mapping.txt";
	open(GENOME_MAP,"$genome_mappings_file") or die("Could not open file $genome_mappings_file\n");
	my @genome_name_data = <GENOME_MAP>;
	close GENOME_MAP;

	my %genome_name_map;
	
	my $user_ref_genome_id;

	foreach my $genome_name (@genome_name_data)
	{
		chomp($genome_name);
		$genome_name = trim($genome_name);
		
		my @name_pieces = split(/=/,$genome_name);
		my $count = @name_pieces;
		if($count eq 2)
		{
			my $key = trim($name_pieces[1]);
			my $val = trim($name_pieces[0]);
			if(defined $user_ref_genome && $user_ref_genome ne "")
			{
				if($user_ref_genome eq $val)
				{

					$user_ref_genome_id = $key;
				}
			}
		}

		
	}

	my $ref_genome_id;

	if($ref_genome ne "")
	{
		my $loc_index = index($ref_genome,'-');
		if($loc_index ne -1)
		{
			$ref_genome_id = substr($ref_genome,0,$loc_index);
			$ref_genome_id = trim($ref_genome_id);
		}

	}

	if(not defined $user_ref_genome_id)
	{
		$user_ref_genome_id = $ref_genome_id;
	}

	$message = "User specified reference genome is $user_ref_genome\n";
	$message = $message . "User specified reference genome id is $user_ref_genome_id\n";
	$message = $message . "Reference genome is $ref_genome\n";
	$message = $message . "Reference genome id is $ref_genome_id";
	$priority = 3;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	
	my $ref_genome_file = "$prodigal_genes_dir/$ref_genome";

	my $best_gene_pairs_file = "$working_dir/best-gene-pairs.txt";

	if(not -e $best_gene_pairs_file)
	{

		$message = "$best_gene_pairs_file does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);
	}


	## for all genes in the ref genome, find is orthologus genes are present in the other genomes

	my $gene_list  = `cat $ref_genome_file`;
	my @ref_genes = split(/\n/,$gene_list);

	foreach my $ref_gene (@ref_genes)
	{

		my $isNotPanreciprocal = 0;
		my $orthologous_genes=""; 

		chomp($ref_gene);
		$ref_gene = trim($ref_gene);

		$message = "Reference gene is $ref_gene";
		$priority = 3;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";



		my $grep_search_cmd = "$ref_gene"."|";
		my $gene_pair_lst = `grep \'$grep_search_cmd\' $best_gene_pairs_file`;

		if($gene_pair_lst ne "")
		{
			my @gene_pairs = split(/\n/,$gene_pair_lst);
			my $num_gene_pairs = @gene_pairs;

			if($num_gene_pairs ne $num_genomes)
			{
				

				$message = "No orthologus set found for $ref_gene";
				$priority = 2;
				system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			}
			else
			{
				## check for pan-reciprocals
				foreach my $gene_pair (@gene_pairs)
				{
					chomp($gene_pair);
					my $gene1 = trim($gene_pair);
					$gene1 =~ s/$ref_gene//;
					$gene1 =~ s/\|//;
					$gene1 = trim($gene1);

					foreach my $search_gene_pair (@gene_pairs)
					{
						chomp($search_gene_pair);
						my $gene2 = trim($search_gene_pair);
						$gene2 =~ s/$ref_gene//;
						$gene2 =~ s/\|//;
						$gene2 = trim($gene2);

						
						## now look for gene1|gene2 in best gene pairs file. If it is not found for even a single pair, discard the gene
						my $search_str =  "$gene1|$gene2";

						#print("$search_str\n");

						my $grep_res = `grep \'$search_str\' $best_gene_pairs_file`;

						#print("grep res is $grep_res\n");

						if((not defined $grep_res) || ($grep_res eq ""))
						{

							$message = "$search_str is not found in the best pairs of genes";
							$priority = 3;
							system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

							$isNotPanreciprocal =1;
							last;
							
						}
					}
				
					if($isNotPanreciprocal eq 1)
					{
						last;
					}
					if($orthologous_genes eq "")
					{
						$orthologous_genes = $gene1;
					}
					else
					{
						$orthologous_genes = $orthologous_genes ."\n".$gene1;

					}	

						
				}

				if($isNotPanreciprocal eq 0)
				{
					## found the orthologus set
					##print the orthologus set to a file

					#print("$orthologous_genes\n\n");
					my $ortholog_set_file = "$working_dir/ortholog_sets/$ref_gene-orthologs";

					open(OUT,">$ortholog_set_file") or die("Could not open file $ortholog_set_file\n");
					print OUT "$orthologous_genes\n";
					close OUT;

				}
				else
				{

					$message = "Pan reciprocal search did not succeed for $ref_gene";
					$priority = 3;
					system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


				}
			}

		}


	}
	
		

	$message = "Done..";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	


}
main;
