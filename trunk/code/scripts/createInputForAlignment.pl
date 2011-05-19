#!/usr/bin/perl

use strict;
use Getopt::Std;
use Cwd;


sub printOptions
{
	print("Usage :: perl createInputForAlignment.pl\n");
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

sub reverseComplement
{

	my $str = shift;
	
	$str =~ s/a/B/ig;
	$str =~ s/t/A/ig;
	$str =~ s/B/T/ig;

	$str =~ s/g/D/ig;
	$str =~ s/c/G/ig;
	$str =~ s/D/C/ig;

	my $ret_str = reverse($str);

	return $ret_str;

}

sub getMin
{

	my $str = shift;
	
	if($str ne "")
	{
		my @lst = split(/\|/,$str);
		my $min = $lst[0];

		foreach my $item (@lst)
		{
			if($item < $min)
			{
				$min = $item;
			}
		}

		#my @sorted = sort {$a <=> $b} @lst;
		#return $sorted[0];
		return $min;
		
	}
	return -1;

}

sub getMax
{
	my $str = shift;
	
	if($str ne "")
	{
		my @lst = split(/\|/,$str);
		my $max = $lst[0];

		foreach my $item (@lst)
		{
			if($item > $max)
			{	
				$max = $item;
			}
		}
		#my @sorted = sort {$b <=> $a} @lst;
		#return $sorted[0];

		return $max;
		
	}
	return -1;

}

sub getSequence
{

	my $file = shift;
	my $start_site = shift;
	my $end_site = shift;
	my $seg_name = shift;
	my $log = shift;
	my $log_file = shift;
	my $perl_dir = shift;
	my $scripts_dir = shift;
	
	my $return_str="";
	

	if((defined $file) && (defined $start_site) && (defined $end_site) && (defined $seg_name))
	{

		if(-e $file)
		{
		
			my $dna_seq = `cat $file`;
		
			$seg_name = trim($seg_name);

			## remove the header
			$dna_seq =~ s/>$seg_name//;

			##remove \n and \r 
			$dna_seq =~ s/[\n\r]//g;
			
			$dna_seq = trim($dna_seq);
			if($dna_seq ne "")
			{
				if($end_site > length($dna_seq))
				{

					$end_site = length($dna_seq);
				}

				##since the first index in the string is 0, decrement start site and end site
				$start_site = $start_site -1;
				$end_site = $end_site -1;
				my $fragment_len = ($end_site - $start_site + 1);			
			
				if($start_site <= $end_site)
				{
					$return_str = substr($dna_seq,$start_site,$fragment_len);

				}

			}
		}
		else
		{

			my $message = "$file does not exist";
			my $priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			exit(-1);

		}
	
	}

	##add the end site at the beg. Since we had decremented start and end sites by 1 earlier, add 1 to the end site for the actual location (starting 1)

	$end_site = $end_site +1;
	$return_str = $end_site . ",".$return_str;

	return $return_str;
}



sub main
{

	our($opt_d,$opt_v,$opt_l,$opt_s,$opt_p);

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

	my $message = "Logging messages from createInputForAlignment.pl......";
	my $priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


	chdir($working_dir);
	
	## check if fasta dir exists

	my $fasta_dir = "$working_dir/fasta";
	if(not -d $fasta_dir)
	{

		$message = "Directory $fasta_dir does not exist.";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);

	}

	## create MSA directory	

	my $msa_dir = "$working_dir/alignments";
	my $msa_input = "$msa_dir/input";
	my $msa_output = "$msa_dir/output";


	if(-d $msa_dir)
	{
		system "rm -rf $msa_dir";
		
	}

	mkdir("$msa_dir");
	mkdir("$msa_input");
	mkdir("$msa_output");
	

	##check if orthologs dir is present

	my $orthologs_dir = "$working_dir/ortholog_sets";
	if(not -d $orthologs_dir)
	{
		$message = "$orthologs_dir does not exist.";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);

	}

	##check if start sites file is present

	my $start_sites_file = "$working_dir/all-genes-startsites.txt";
	if(not -e $start_sites_file)
	{
		$message = "$start_sites_file does not exist.";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);

	}

	## read the start sites file and store it in a hashmap

	open(START_SITES,"$start_sites_file") or die("Could not open file $start_sites_file\n");
	my @start_site_data = <START_SITES>;
	close START_SITES;

	my %start_sites_map;

	foreach my $line(@start_site_data)
	{
		chomp($line);
		$line = trim($line);
	
		if($line ne "")
		{
			my @pieces = split(/,/,$line);
			my $count = @pieces;

			if($count eq 6)
			{
				my $key = trim($pieces[0]);
				$start_sites_map{$key} = $line;

			}

		}
	}
	

	
	## number of sites to append to the start site

	my $append_num = 250;


	## read genome mapping file

	my $genome_map_file = "$working_dir/genome-name-mapping.txt";
	if(not -e $genome_map_file)	
	{
		$message = "$genome_map_file does not exist.";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);
	}
	
	open(GENOME_MAP,"$genome_map_file") or die("Could not open file $genome_map_file\n");
	my @genome_map_data = <GENOME_MAP>;
	close GENOME_MAP;

	my %genome_map;

	foreach my $line (@genome_map_data)
	{
		chomp($line);
		$line = trim($line);

		my @pieces = split(/=/,$line);
		my $count = @pieces;

		if($count eq 2)
		{
			my $key = trim($pieces[1]);
			my $val = trim($pieces[0]);

			$genome_map{$key} = $val;

		}
		else
		{
			$message = "Incorrect format on line $line in $genome_map_file.";
			$priority = 2;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		}
		

	}

	

	## go through all the ortholog files one by one
	
	chdir($orthologs_dir);
	my $ortholog_lst = `ls`;
	if($ortholog_lst ne "")
	{
		my $align_pos_file = "$working_dir/msa-start-end-pos.txt";
		open(ALIGN_POS,">$align_pos_file") or die("Could not open $align_pos_file\n");
	
		my @orthologs = split(/\n/,$ortholog_lst);	
		
		foreach my $ortholog (@orthologs)
		{

			chomp($ortholog);
			$ortholog = trim($ortholog);

			#print("$ortholog\n");
			if($ortholog ne "")
			{
				my $ortholog_file = "$orthologs_dir/$ortholog";
				
				open(IN,"$ortholog_file") or die("Could not open file $ortholog_file\n");
				my @data = <IN>;
				close IN;

				my $msa_input = "$msa_input/$ortholog"."-input.fasta";
				open(MSA_OUT,">$msa_input") or die("Could not open file $msa_input\n");

				my $output_str;
				foreach my $gene_name (@data)
				{
					## get the seq and write it to the msa-input file

					chomp($gene_name);

					##get the genome name and the segment name

					my @pieces = split(/_/,$gene_name);
					my $count = @pieces;
					my $genome_name;
					my $segment_name;
					my $segment_id;
					
					if($count eq 3)
					{
						my $genome_id = trim($pieces[0]);
						$genome_name = $genome_map{$genome_id};
						$segment_id = trim($pieces[1]);

						$segment_name = $genome_id . "_".$segment_id;
					}
					else
					{

						$message = "$gene_name has incorrect format.";
						$priority = 2;
						system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

					}
					

					my $segment_file = "$fasta_dir/$genome_name/$segment_name.fasta";

					## now get all the start sites

					my $result = $start_sites_map{$gene_name};

					my @gene_pieces = split(/,/,$result);
					my $gene_pieces_count = @gene_pieces;

					##depending on the direction, start and end sites are adjusted.. 
					##these are the start and end site positions in the positive dir. 
					##if the dir is neg, then the reverse complement of the segment is computed

					if($gene_pieces_count eq 6)
					{
						my $dir = trim($gene_pieces[3]);
						my $start_site = trim($gene_pieces[1]); 
						my $end_site = trim($gene_pieces[2]);
						my $possible_starts = trim($gene_pieces[4]);

						if($dir eq 1)
						{	
							$start_site = getMin($possible_starts);
							$start_site = $start_site - $append_num;

							if($start_site < 0)
							{		
								$start_site = 1;
							}
						}

						if($dir eq -1)
						{
							## if the end site exceeds the len of the segment, 
							##limit it to the length of the seg later. 
							##At this point of time, we do not know the length of the segment.
								 									
							$end_site = getMax($possible_starts);
							$end_site = $end_site + $append_num;

						}

						## fetch the str
						my $dna_str;
						my $result_str = getSequence($segment_file,$start_site,$end_site, $segment_id, $log,$log_file, $perl_dir,$scripts_dir);
						my @str_pieces = split(/,/,$result_str);
						if(defined($str_pieces[0]) && defined($str_pieces[1]))
						{
							$end_site = $str_pieces[0];
							$dna_str = $str_pieces[1];

						}
						else
						{
							$message = "Could not get the dna sequence for $gene_name.";
							$priority = 1;
							system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
							exit(-1);

						}

						print ALIGN_POS "$gene_name, $start_site, $end_site, $dir\n";

						if($dir eq -1)
						{
							$dna_str = reverseComplement($dna_str);
						}

						my $header = ">$gene_name\n";

						if(not defined $output_str)
						{
							$output_str = $header."$dna_str\n";

						}
						else
						{
							$output_str = $output_str . $header. "$dna_str\n";

						}

					}
					else
					{
						$message = "Incorrect format for $start_sites_file.";
						$priority = 2;
						system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


					}
						
					
				} ## end for each gene_name

				print MSA_OUT "$output_str";
				close MSA_OUT;				

			}
	
		}

		close ALIGN_POS;
		
	}
	else
	{
		$message = "No ortholog sets found in $orthologs_dir.";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);

	}

	$message = "Done..";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	
}
main;
