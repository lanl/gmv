#!/usr/bin/perl

use strict;
use Getopt::Std;
use Cwd;


sub printOptions
{
	print("Usage :: perl formatResultsGBKFormat.pl\n");
	print("-d  Working directory. <REQUIRED> \n");
	print("-v  Logging level. 1 is ERROR, 2 is WARNING, 3 is INFO. Default is 1.\n");
	print("-l  Log file with complete path. Default - Log messages will be written to standard output.\n");
	print("-p  Perl directory. <REQUIRED> \n");
	print("-s  Scripts directory. <REQUIRED> \n");
	print("-o  Output directory. <REQUIRED> \n");
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

sub getSegment
{

	my $file = shift;
	my $seg_name = shift;

	my $dna_seq = `cat $file`;
	$seg_name = trim($seg_name);

	## remove the header
	$dna_seq =~ s/>$seg_name//;

	##remove \n and \r 
	$dna_seq =~ s/[\n\r]//g;
	$dna_seq = trim($dna_seq);

	return $dna_seq;


}

sub getDNASequence
{
	my $dna_seq = shift;
	my $beg = shift;
	my $end = shift;
	
	
	my $return_str="";

	if($dna_seq ne "")
	{
		$beg = $beg -1;
		$end = $end -1;
		my $fragment_len = ($end - $beg + 1);			
	
		if($beg <= $end)
		{
			$return_str = substr($dna_seq,$beg,$fragment_len);

		}

	}
	else
	{
		print("dna seq is empty\n");

	}
	return $return_str;
}

sub convertToAA
{
	my $codon = shift;
	my $aa ="";
	my(%aaMap)=('TCA'=>'S','TCC'=>'S','TCG'=>'S','TCT'=>'S','TTC'=>'F','TTT'=>'F','TTA'=>'L','TTG'=>'L','TAC'=>'Y','TAT'=>'Y','TAA'=>'_','TAG'=>'_','TGC'=>'C','TGT'=>'C','TGA'=>'_','TGG'=>'W','CTA'=>'L','CTC'=>'L','CTG'=>'L','CTT'=>'L','CCA'=>'P','CCC'=>'P','CCG'=>'P','CCT'=>'P','CAC'=>'H','CAT'=>'H','CAA'=>'Q','CAG'=>'Q','CGA'=>'R','CGC'=>'R','CGG'=>'R','CGT'=>'R','ATA'=>'I','ATC'=>'I','ATT'=>'I','ATG'=>'M','ACA'=>'T','ACC'=>'T','ACG'=>'T','ACT'=>'T','AAC'=>'N','AAT'=>'N','AAA'=>'K','AAG'=>'K','AGC'=>'S','AGT'=>'S','AGA'=>'R','AGG'=>'R','GTA'=>'V','GTC'=>'V','GTG'=>'V','GTT'=>'V','GCA'=>'A','GCC'=>'A','GCG'=>'A','GCT'=>'A','GAC'=>'D','GAT'=>'D','GAA'=>'E','GAG'=>'E','GGA'=>'G','GGC'=>'G','GGG'=>'G','GGT'=>'G');
	if($codon ne "")
	{
		if(exists $aaMap{$codon})
		{
			$aa = $aaMap{$codon};
		}		

	}

	return $aa;
}

sub convertToProtein
{
	my $dna = shift;
	my $protein ="";

	$dna = uc($dna);
	my $len = length($dna);

	for(my $i=0;$i<$len;$i=$i+3)
	{
		my $codon = substr($dna,$i,3);
		my $aa = convertToAA($codon);
		$protein = $protein . $aa; 
	}

	return $protein;

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

	our($opt_d,$opt_v,$opt_l,$opt_p,$opt_s,$opt_o);

	getopt("dvlspjco");

	if((not defined $opt_d) || (not defined $opt_p) || (not defined $opt_s) || (not defined $opt_o))
	{ 
		printOptions;
		exit(0);
	
	}

	my $working_dir = $opt_d;
	my $log = $opt_v;
	my $log_file = $opt_l;
	my $perl_dir = $opt_p;
	my $scripts_dir = $opt_s;
	my $output_dir = $opt_o;


	if(not defined $log)
	{
		$log = 1;
	}

	my $message = "Logging messages from formatResultsGBKFormat.pl......";
	my $priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	if(not -d $output_dir)
	{
		$message = "$output_dir does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
		exit(-1);

	}

	## create GBK format directory
	
	my $format_dir = "$output_dir/format";
	
	if(-d $format_dir)
	{
		system "rm -rf $format_dir";

	}
	mkdir("$format_dir");

	my $gbk_format_dir = "$format_dir/GBK";
	
	if(-d $gbk_format_dir)
	{

		system "rm -rf $gbk_format_dir";
	}
	mkdir("$gbk_format_dir");

	my $gene_prediction_file = "$output_dir/gene-predictions.txt";
	
	if(not -e $gene_prediction_file)
	{
		$message = "$gene_prediction_file does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
		exit(-1);


	}

	my $input_seq_dir = "$output_dir/input-sequences";

	if(not -d $input_seq_dir)
	{
		$message = "$input_seq_dir does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
		exit(-1);


	}

	chdir($input_seq_dir);

	my $genome_lst = `ls`;
	if($genome_lst ne "")
	{
		my @genomes = split(/\n/,$genome_lst);
		foreach my $genome (@genomes)
		{
			chomp($genome);
			$genome = trim($genome);
			
			#print("\n$genome\n");

			my $new_genome_dir = "$gbk_format_dir/$genome";
			mkdir("$new_genome_dir");
			#mkdir("$new_genome_dir/scores");
			mkdir("$new_genome_dir/cds");
			mkdir("$new_genome_dir/proteins");
			
			chdir($genome);
			my $seg_lst = `ls`;
			if($seg_lst ne "")
			{
				my @segments = split(/\n/,$seg_lst);
				foreach my $segment (@segments)
				{
					chomp($segment);
					$segment = trim($segment);
					my $segment_file = "$input_seq_dir/$genome/$segment";
					
					$segment =~ s/.fasta//;
					my $seg_str = getSegment($segment_file,$segment);
					#my $reverse_comp_seg_str = reverseComplement($seg_str);
					
					my $key = $genome.".".$segment.".";

					#print("\n$segment => $key\n");

					my $res = `grep \'$key\' $gene_prediction_file`;

					
					if($res ne "")
 					{
 						my %cds_map;
 						#my %scores_map;
 						my %protein_header_map;
 
 						my $cds_file = "$new_genome_dir/cds/$key"."cds";
 						#my $scores_file = "$new_genome_dir/scores/$key"."scores";
 						my $protein_file = "$new_genome_dir/proteins/$key"."proteins";
 
 						#open(SCORES_OUT,">$scores_file") or die("Could not open $scores_file\n");
 						#my $scores_header = "Beg\tEnd\tStd\tTotal";
 						#print SCORES_OUT "$scores_header\n";
 
 						open(CDS_OUT,">$cds_file") or die("Could not open $cds_file\n");

						open(PROTEIN_OUT,">$protein_file") or die("Could not open $protein_file\n");
 
 
 						my @result_lst = split(/\n/,"$res");
 						foreach my $result (@result_lst)
 						{
 							chomp($result);
 							$result = trim($result);
 
 							my @pieces = split(/\s+/,$result);
 							my $count = @pieces;
 
 							if($count == 8)
 							{
 								my $gene_name = trim($pieces[0]);
 								my $gene_id = trim($pieces[1]);
 								my $beg = trim($pieces[4]);
 								my $end = trim($pieces[5]);
 								my $dir = trim($pieces[6]);
 								#my $score = trim($pieces[7]);
 
 								#my $score_dir="";
 								my $cds_str="";
 								if($dir eq "1")
 								{
 								#	$score_dir = "+";
 									$cds_str = $beg.".."."$end";
 								}
  								else
 								{
 								#	$score_dir = "-";
 									$cds_str = "complement(".$beg.".."."$end".")";
									
 								}
 								
 
 								#my $scores_str = "$beg\t$end\t$score_dir\t$score";
 								#$scores_map{$gene_id} = $scores_str;
 
 								$cds_str = "\tCDS\t$cds_str";
 								$cds_map{$gene_id} = $cds_str;
 
 								my $protein_header = ">$gene_name # $beg # $end # $dir";
 								$protein_header_map{$gene_id} = $protein_header;

		
 							}					
 						}
  
 						## now sort the maps based on the keys and write the results to file
 
 						##writing cds file
 						foreach my $key (sort keys %cds_map) 
 						{
 							print CDS_OUT "$cds_map{$key}\n";
 						}
 
 						##writing scores file
 						#foreach my $key (sort keys %scores_map) 
 						#{
 						#	print SCORES_OUT "$scores_map{$key}\n";
 						#}
 
						foreach my $key (sort keys %protein_header_map) 
 						{
 							
							##convert dna to protein
							my $header = $protein_header_map{$key};
							my @header_pieces = split(/#/,$header);
							my $header_count = @header_pieces;

							if($header_count==4)
							{
								my $seg_beg = trim($header_pieces[1]);
								my $seg_end = trim($header_pieces[2]);	
								my $seg_dir = trim($header_pieces[3]);
								my $seq ="";
																
								#my $start_time = time();
								if($seg_dir eq "1")
								{
									$seq = getDNASequence($seg_str,$seg_beg,$seg_end);
								}
								else
								{
									$seq = getDNASequence($seg_str,$seg_beg,$seg_end);
									$seq = reverseComplement($seq);
									
								}
								#my $end_time = time();
								#my $time_taken = $end_time - $start_time;
								#print("$time_taken\n");
								
								if($seq ne "")
								{
									print PROTEIN_OUT "$protein_header_map{$key}\n";
									my $protein = convertToProtein($seq);
									chop($protein);
									print PROTEIN_OUT "$protein\n";

									#print(length($seq)."=>".length($protein)."\n");	
								} 
	
							}					
 						}
 
 						#close SCORES_OUT;
 						close CDS_OUT;
						close PROTEIN_OUT;	

						
 
 					}
					else
					{
						my $temp_key = "$key";
						chop($temp_key);
						$message = "No genes found in $temp_key";
						$priority = 2;
						system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
						
					}
				}
			}
			chdir("..")
		}
	}
	else
	{
		$message = "No genome directories found in $input_seq_dir";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
		exit(-1);


	}	



	$message = "Done..";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

}

main;