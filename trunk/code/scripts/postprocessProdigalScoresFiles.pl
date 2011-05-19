#!/usr/bin/perl

use strict;
use Getopt::Std;
use Cwd;


sub printOptions
{
	print("Usage :: perl postprocessProdigalScoresFiles.pl\n");
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
		exit(-1);
	
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


		
	my $message = "Logging messages from postprocessProdigalScoresFiles.pl......";
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
	
	my $start_sites_file = "$working_dir/all-genes-startsites.txt";

	open(START_POS_OUT,">$start_sites_file") or die("Could not open $start_sites_file\n");


	
	my $lst = `ls`;
	my @pcs = split(/\n/,"$lst");



	foreach my $genome_dir (@pcs)
	{
		chomp($genome_dir);
		

		my $prodigal_protein_dir = "$working_dir/fasta/$genome_dir/prodigal_results/proteins";
		my $prodigal_scores_dir = "$working_dir/fasta/$genome_dir/prodigal_results/scores";

		chdir($prodigal_protein_dir);

		

		my $seq_lst = `ls`;
		my @files = split(/\n/,$seq_lst);

		
		
		foreach my $file (@files)
		{
			
			chomp($file);
			if(not $file =~ m/~/)
			{
				if($file =~ m/-proteins/)
				{
					my $protein_file = $file;
					my $identifier = $protein_file;
					$identifier =~ s/-proteins//;
				
					my $scores_file = "$identifier-scores";
		
					if($log eq 1)
					{
						print("Processing $protein_file and $scores_file files\n");

					}
					
					my $protein_file_path = "$prodigal_protein_dir/$protein_file";
					my $scores_file_path = "$prodigal_scores_dir/$scores_file";

					
					## parse the scores file and store it in a hashmap
					
					my %start_sites_map;

					open(SCORES,"$scores_file_path") or die("Could not open file $scores_file_path\n");
					my @scores_data = <SCORES>;
					close SCORES;

					## format of the scores file
					##<begin pos>, <end pos>, <dir>, <total_score>, <score_comp1>, <score_comp2>
					## if the dir is '-', then the stop site is the first column.
					## if the dir is '+', then the stop site is the second column.

					## O(n) algo to parse the file
					## for each line in the file, check if the stop codon is present in the hashmap as the key
					## if so, append the corresponding start site and total score to the existing list. If not, then create a new
					## entry in the hashmap for the stop site	
		
					## a typical hashmap entry looks like this - stop site (key), <start_site_list>, <total_score_list> (value) 
					## <start_site_list> - p1|p2|p3|...|pn. <total_score_list> - s1|s2|s3|..|sn.


					foreach my $line (@scores_data)
					{
					
						chomp($line);
						$line = trim($line);
						if($line ne "" && (not $line =~ m/#/))  ##Modified by Sindhu 02/10/2011
						{
							my @score_pieces = split(/\s+/,"$line");
							my $num_entities = @score_pieces;
							
							#if($num_entities eq 6) ##Modified by Sindhu 02-10-2011
							if($num_entities eq 12)
							{
								my $dir = $score_pieces[2];
								$dir = trim($dir);
								my $start_site;
								my $end_site;
								my $total_score = $score_pieces[3];

								if($dir eq "+")
								{
									$start_site = $score_pieces[0];
									$end_site = $score_pieces[1];
								}
								else
								{
									$start_site = $score_pieces[1];
									$end_site = $score_pieces[0];
								}

								## check if the end_site is present in the hashmap

								my $cur_entry = $start_sites_map{$end_site};

														
								if($cur_entry ne "")	
								{
									## entry present. Append to the existing list
									
									my @entry_pieces = split(/,/,"$cur_entry");
									my $entry_count = @entry_pieces;
									if($entry_count eq 2)
									{
										my $start_site_entry = $entry_pieces[0];
										my $total_score_entry = $entry_pieces[1];

										$start_site_entry = $start_site_entry ."|".$start_site;
										$total_score_entry = $total_score_entry."|".$total_score;
									
										my $new_entry = "$start_site_entry,$total_score_entry";
										$start_sites_map{$end_site} = $new_entry;

									}

								}
								else
								{
									my $new_entry = "$start_site,$total_score";
									$start_sites_map{$end_site} = $new_entry;

								}
		
							}
							else
							{
								

								$message = "Incorrect number of columns '$line' in scores file - $scores_file_path.";
								$priority = 1;
								system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

								exit(-1);


							}
						}

					}

					## print the hashmap
					#while((my $k,my $v)=each %start_sites_map) 
					#{
  					#  print "$k => $v\n";
					#}


					## get all the headers in the protein file
					## use cat and grep to get the header lines instead of reading through the file

					my $header_list = `cat $protein_file_path | grep \'>\'`;
					
					my @headers = split(/\n/,$header_list);
						
					foreach my $header (@headers)	
					{
						chomp($header);
						$header = trim($header);
						if($header ne "")
						{
							my @hdr_pieces = split(/\#/,$header);
							my $num_pieces = @hdr_pieces; 
							if($num_pieces eq 4)
							{		
								my $strand_dir = trim($hdr_pieces[3]);
								my $key;
								if($strand_dir eq "1")
								{
									## pos dir. end site is in hdr_pieces[2]
									
									$key = trim($hdr_pieces[2]);

								}
								else
								{
									## neg dir. end site is in hdr_pieces[1]
									$key = trim($hdr_pieces[1]);

								}
								

								my $val = $start_sites_map{$key};
								$val = trim($val);
								#$val =~ s/,/ \# /;
								
								my $new_header = $header;
								$new_header =~ tr/\#/,/;
								$new_header =~ s/>//;
								$new_header = "$new_header , $val";
								$new_header = trim($new_header);
								print START_POS_OUT "$new_header\n";		
								

							}
							else
							{
								$message = "Header '$header' in the fasta file $protein_file_path is not correct.";
								$priority = 1;
								system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

								exit(-1);
							}

						}
					}
					
				}
				
			}
			

		}
		
	
	}

	close START_POS_OUT;

	$message = "Done..";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";



}


main;
