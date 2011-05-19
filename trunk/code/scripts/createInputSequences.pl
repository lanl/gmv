#!/usr/bin/perl

use strict;
use Getopt::Std;
use Cwd;


sub printOptions
{
	print("Usage :: perl createInputSequences.pl\n");
	print("-o  Genome directory contains the sequence files <REQUIRED> \n");
	print("-v  Logging level. 1 is ERROR, 2 is WARNING, 3 is INFO. Default is 1.\n");
	print("-l  Log file with complete path. Default - Log messages will be written to standard output.\n");
	print("-p  Perl directory. <REQUIRED> \n");
	print("-s  Scripts directory. <REQUIRED> \n");


}

sub padIndex
{
	my $str = shift;
	my $index_len = shift;
	
	my $str_len = length($str);
	my $return_str = $str;
	
	if($str_len < $index_len)
	{
		for(my $i=1; $i <= $index_len-$str_len; $i++)
		{
			$return_str = "0".$return_str;
		}

	}

	return $return_str;

}

sub getIndexLength
{
	my $str = shift;

	my $len = length($str);

	return $len;

}

sub createMultipleFiles
{

	my $seq_file = shift;
	my $genome_name = shift;
	my $seq_dir = shift;
	my $log = shift;
	my $log_file = shift;
	my $perl_dir = shift;
	my $scripts_dir = shift;

	open(SEQ_FILE,"$seq_file") or die("Could not open file $seq_file\n");
	my @seq_data = <SEQ_FILE>;
	close SEQ_FILE;

	## find the number of sequences in the file by counting >

	my $seq_count =0;

	foreach my $line (@seq_data)
	{
		chomp($line);
		if($line =~ m/>/)
		{
			$seq_count++;
		}
	}	

	my $seq_idx_len = getIndexLength($seq_count);
	
	
	

	my $segment_name_mapping_file = "$seq_dir/segment-name-mapping.txt";

	open(MAP_FILE,">$segment_name_mapping_file") or die("Could not open file $segment_name_mapping_file \n");

	## now for each seq in the file, create an individual file. Use genome-name_seg-name.fasta to name the new files. 
	
	my $line_count = @seq_data; ## counts the number of lines in the file

	my $cur_seq_num =1; ## current sequence in the file

	for(my $i=0; $i< $line_count; $i++)
	{
		my $line = $seq_data[$i];
		chomp($line);
		if($line =~ m/>/)
		{
			
			my $seg_name = $line;
			$seg_name =~ s/>//;
			my $seg_id = padIndex($cur_seq_num, $seq_idx_len);
			my $new_seg_name = "D$seg_id";
			print MAP_FILE "$seg_name = $new_seg_name\n";	
			#print("$seg_name :: $new_seg_name\n");
			
			
			my $segment_file = "$seq_dir/$genome_name"."_"."$new_seg_name.fasta";
			open(SEG_FILE, ">$segment_file") or die("Could not open $segment_file\n");
			
			print SEG_FILE ">$new_seg_name\n";
			for(my $j = $i+1; $j < $line_count; $j++)	
			{
				#print("j $j\n");
				my $curline = $seq_data[$j];
				chomp($curline);
				if($curline =~ m/>/)
				{
					$i = $j-1;
					last;
				}
				else
				{
					print SEG_FILE "$curline\n";

				}

			}

			close SEG_FILE;	

			my $cwd = getcwd;
			chdir("prodigal_prediction");
			system "ln -s $segment_file $genome_name"."_"."$new_seg_name.fasta";
			chdir($cwd);
			$cur_seq_num++;
		}	
		
	}

	close MAP_FILE;
}


sub createMultipleSeqFilesForGenome
{

	my $seq_dir = shift;
	my $genome_name = shift;
	my $log = shift;
	my $log_file = shift;
	my $perl_dir = shift;
	my $scripts_dir = shift;
	
	## get the current working dir
	my $cwd = getcwd;

	chdir($seq_dir);
	
	my $file_lst = `ls`;

	## at this point of time, every genome directory should have atmost two files - one fasta file and its back up file (if present)
	
	my @files = split(/\n/,$file_lst);
	my $file_count = @files;


	if($file_count > 2)	
	{
		my $message = "Multiple fasta files found in the genome directory $seq_dir";
		my $priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);
	}
	else
	{	my $fasta_file;
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
		
		my $seq_file = "$seq_dir/$fasta_file";

		##before creating individual seq files for each genome seq, create prodigal directories
		
		mkdir("prodigal_training");
		mkdir("prodigal_prediction");
		mkdir("prodigal_results");

		chdir("prodigal_training");			
		system "ln -s $seq_file $genome_name-full.fasta";
		chdir($seq_dir);		
		
		chdir("prodigal_results");
		mkdir("genes");
		mkdir("proteins");
		mkdir("scores");
		chdir($seq_dir);
		

		createMultipleFiles($seq_file, $genome_name, $seq_dir, $log, $log_file,$perl_dir,$scripts_dir);
		
	}
	
	chdir($cwd);
}


sub main
{
	our($opt_o,$opt_v,$opt_s,$opt_p,$opt_l);

	getopt("ovspl");

	if((not defined $opt_o) || (not defined $opt_p) || (not defined $opt_s))
	{
		printOptions;
		exit(0);
	
	}

	my $output_dir = $opt_o;
	my $log = $opt_v;
	my $scripts_dir = $opt_s;
	my $perl_dir = $opt_p;
	my $log_file = $opt_l;

	if(not defined $log)
	{
		$log = 1;
	}


	my $message = "Logging messages from createInputSequences.pl....";
	my $priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


	if(-d "$output_dir/fasta/")
	{
		chdir("$output_dir/fasta/");
	}
	else
	{

		$message = "Directory $output_dir/fasta/ does not exist.";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
		exit(-1);
	}
	
	my $lst = `ls`;
	my @pcs = split(/\n/,"$lst");

	## ideally the length of pcs should be equal to the number of genomes/species. To avoid errors, I am actually counting the number of directories under $output_dir/fasta to get the number of genomes. This way the program will not fail if ant text files are accidently put in the fasta directory

	my $genome_count=0;

	foreach my $pc (@pcs)
	{
		chomp($pc);
		if(-d "$output_dir/fasta/$pc")
		{
			$genome_count++;
		}
	}

	$message = "Number of genome sequences is $genome_count.";
	$priority = 3;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	
	my $genome_map_file = "$output_dir/genome-name-mapping.txt";
	open(GENOME_MAP,">$genome_map_file") or die("Could not open file $genome_map_file\n");

	## for each genome dir, create createMultipleSeqFilesindividual files for the sequences and name them accordingly
	
	my $genome_index_len = getIndexLength($genome_count);
	
	my $count = 1;
	foreach my $genome_dir (@pcs)
	{
		chomp($genome_dir);

		## generate a new name for the genome	
		my $genome_idx = padIndex($count,$genome_index_len);
		my $genome_name = "G$genome_idx";
		$count++;

		## write the genome name mapping in the mapping file
		print GENOME_MAP "$genome_dir = $genome_name\n";
		
		##create multiple seq files
		
		my $seq_dir = "$output_dir/fasta/$genome_dir";
		createMultipleSeqFilesForGenome($seq_dir,$genome_name, $log,$log_file,$perl_dir,$scripts_dir);
		
	}

	close GENOME_MAP;

	$message = "Done..";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


}

main;
