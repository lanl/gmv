#!/usr/bin/perl

use strict;
use Getopt::Std;
use Cwd;


sub printOptions
{
	print("Usage :: perl outputResults.pl\n");
	print("-d  Working directory. <REQUIRED> \n");
	print("-v  Logging level. 1 is ERROR, 2 is WARNING, 3 is INFO. Default is 1.\n");
	print("-l  Log file with complete path. Default - Log messages will be written to standard output.\n");
	print("-p  Perl directory. <REQUIRED> \n");
	print("-s  Scripts directory. <REQUIRED> \n");
	print("-o  Output directory. <REQUIRED> \n");
}

sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub formatFile
{

	my $input = shift;
	my $output = shift;
	my $replace_id = shift;

	open(IN,"$input") or die("Could not open file $input\n");
	my @data = <IN>;
	close IN;

	open(OUT,">$output") or die("Could not open file $output\n");

	foreach my $line (@data)
	{
		chomp($line);
		if($line =~ m/>/)
		{
			print OUT ">$replace_id\n";
	
		}
		else
		{
			print OUT "$line\n";
		}
	}
	close OUT;
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
	#my $java_bin_dir = $opt_j;
	#my $java_code_dir = $opt_c;
	my $output_dir = $opt_o;


	if(not defined $log)
	{
		$log = 1;
	}

	my $message = "Logging messages from outputResults.pl......";
	my $priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	if(not -d $output_dir)
	{
		$message = "$output_dir does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
		exit(-1);

	}

	
	chdir($working_dir);

	$message = "Generating mappings....";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	##get mappings

	my $genome_map_file = "$working_dir/genome-name-mapping.txt";
	my $num_species =0;

	if(not -e $genome_map_file)
	{
		$message = "$genome_map_file does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);
	}

	my %genome_map;

	open(GENOME_MAP,"$genome_map_file") or die("Could not open file $genome_map_file\n");
	my @genome_name_data = <GENOME_MAP>;
	close GENOME_MAP;

	foreach my $line (@genome_name_data)
	{
		chomp($line);
		$line = trim($line);
		
		my @pieces = split(/=/,$line);
		my $count = @pieces;

		if($count eq 2)
		{
			my $genome_name = trim($pieces[0]);
			my $genome_id = trim($pieces[1]);

			$genome_map{$genome_name} = $genome_id;
			$num_species++;

		}

	}

	## read segment name mappings

	my $fasta_dir = "$working_dir/fasta";

	if(not -d $fasta_dir)
	{
		$message = "$fasta_dir does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);

	}

	my %seg_name_map;

	chdir($fasta_dir);
	my $dir_lst = `ls`;
	my @genome_dirs = split(/\n/,"$dir_lst");

	foreach my $dir (@genome_dirs)
	{
		chomp($dir);	
		$dir = trim($dir);

		my $seg_map_file = "$fasta_dir/$dir/segment-name-mapping.txt";
		
		if(not -e $seg_map_file)
		{
			$message = "$seg_map_file does not exist";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			exit(-1);

		}

		open(SEG_MAP,"$seg_map_file") or die("Could not open file $seg_map_file\n");
		my @seg_map_data = <SEG_MAP>;
		close SEG_MAP;

		foreach my $line (@seg_map_data)
		{
			my $genome_id = $genome_map{$dir};

			my @pieces = split(/=/,$line);
			my $count = @pieces;

			if($count eq 2)
			{

				my $seg_name = trim($pieces[0]);
				my $seg_id = trim($pieces[1]);

				$seg_id = $genome_id . "_". $seg_id;
				$seg_name = $dir. ".".$seg_name;

				$seg_name_map{$seg_id} = $seg_name;
			}


		}
	}

	my $mapping_dir = "$output_dir/mappings";

	if(-d $mapping_dir)
	{
		system "rm -rf $mapping_dir";

	}

	mkdir($mapping_dir);

	##write genome map

	my $output_map_file1 = "$mapping_dir/genome-name-mapping.txt";
	
	open(OUT,">$output_map_file1") or die("Could not open file $output_map_file1\n");
	foreach my $key (sort keys %genome_map)
	{
     		print  OUT "$genome_map{$key} = $key\n";
	}
	
	close OUT;

	my $output_map_file2 = "$mapping_dir/segment-name-mapping.txt";
	
	open(OUT,">$output_map_file2") or die("Could not open file $output_map_file2\n");
	
	foreach my $key (sort keys %seg_name_map) 
	{
     		print OUT "$key = $seg_name_map{$key}\n";
	}

	close OUT;


	##copy BLAST results
	$message = "Copying BLAST results....";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	my $blast_dir = "$working_dir/blast";
	
	if(not -d $blast_dir)
	{
		$message = "$blast_dir does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);

	}
	my $blast_tar_ball = "$output_dir/blast.tar.bz2";

	system "tar -cjf $blast_tar_ball $blast_dir";


	## copy input segments to output dir

	$message = "Copying input sequences....";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


	my $input_seq_dir = "$output_dir/input-sequences";

	if(-d $input_seq_dir)
	{
		system "rm -rf $input_seq_dir";
	}

	mkdir($input_seq_dir);
	
	
	chdir($fasta_dir);

	my $dir_lst = `ls`;
	my @genome_dirs = split(/\n/,"$dir_lst");

	foreach my $dir (@genome_dirs)
	{
		chomp($dir);	
		$dir = trim($dir);

		#print("\n$dir\n");	
		##create dir in output dir
		my $new_dir = "$input_seq_dir/$dir";
		mkdir($new_dir);

		my $prodigal_dir = "$fasta_dir/$dir/prodigal_prediction";
		
		if(not -d $prodigal_dir)
		{
			$message = "$prodigal_dir does not exist";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			exit(-1);
		}
		
		chdir($prodigal_dir);
		
		my $seg_list = `ls`;
		if($seg_list ne "")
		{
			my @segments = split(/\n/,$seg_list);
			
			foreach my $segment (@segments)
			{
				my $key = $segment;
				$key =~ s/.fasta//;
				$key = trim($key);
				my $new_segment_name = $seg_name_map{$key};
				$new_segment_name =~ s/$dir.//;
				
				my $new_segment_file = "$input_seq_dir/$dir/$new_segment_name".".fasta";
				my $old_segment_file = "$fasta_dir/$dir/$segment";
				
				formatFile($old_segment_file,$new_segment_file,$new_segment_name);
				
	
			}
		}
	}

	$message = "Copying alignments....";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	
	## copy alignments
	my $new_align_dir = "$output_dir/alignments";

	if(-d $new_align_dir)
	{
		system "rm -rf $new_align_dir";
	}

	mkdir($new_align_dir);

	my $align_dir = "$working_dir/alignments/output";

	if(not -d $align_dir)
	{
		$message = "$align_dir does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);
	}

	system "cp $align_dir/* $new_align_dir/";


	$message = "Copying feature files....";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


	## copy feature files
	my $new_feature_files_dir = "$output_dir/feature-files";

	if(-d $new_feature_files_dir)
	{
		system "rm -rf $new_feature_files_dir";
	}

	mkdir($new_feature_files_dir);

	my $feature_files_dir = "$working_dir/alignments/feature-files";

	if(not -d $feature_files_dir)
	{
		$message = "$feature_files_dir does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);
	}

	system "cp $feature_files_dir/* $new_feature_files_dir";

	
	$message = "Copying ortholog statistic file....";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	my $ortholog_stats_file = "$working_dir/prediction/orthologs-stats.txt";

	if(not -e $ortholog_stats_file)
	{
		$message = "$ortholog_stats_file does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);

	}

	system "cp $ortholog_stats_file $output_dir/";


	$message = "Formatting gene predictions file....";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	## format gene prediction file

	my $gene_prediction_file = "$working_dir/prediction/gene-predictions.txt";

	if(not -e $gene_prediction_file)
	{
		$message = "$gene_prediction_file does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);
	}

	open(IN,"$gene_prediction_file") or die("Could not open file $gene_prediction_file\n");
	my @data = <IN>;
	close IN;

	my $new_gene_prediction_file = "$output_dir/gene-predictions.txt";

	open(OUT,">$new_gene_prediction_file") or die("Could not open file $new_gene_prediction_file");
	
	my $index =0;
	my $num_genes=0;
	my @predicted_genes;
	foreach my $line(@data)
	{
		chomp($line);
		$line = trim($line);

		if($index == 0)
		{
			my $header = $line;
			$header = "GENE_NAME\t$header";
			print OUT "$header\n";
		}
		else
		{
			my @pieces = split(/\s+/,$line);
			my $count = @pieces;
			if($count eq 7)
			{
				my $gene_id = trim($pieces[0]);
				my @gene_pieces = split(/_/,$gene_id);
				my $gene_pieces_count = @gene_pieces;

				if($gene_pieces_count eq 3)
				{
					my $key = trim($gene_pieces[0]) ."_"."$gene_pieces[1]";
					my $gene_name = $seg_name_map{$key};
					$gene_name = $gene_name . ".".trim($gene_pieces[2]);

					my $new_line = "$gene_name\t$line";
					print OUT "$new_line\n";

				}


				$predicted_genes[$num_genes++] = $gene_id;

			}
		}
		$index++;
	}
	
	close OUT;


	$message = "Writing summary statistics....";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
	
	my $summary_file = "$working_dir/prediction/summary.txt";
	if(not -e $summary_file)
	{
		$message = "$summary_file does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);

	}

	open(SUMMARY,">>$summary_file") or die("Could not open file $summary_file\n");

	print SUMMARY "Total number of genes predicted is $num_genes\n";

	foreach my $key (sort keys %genome_map)
	{
     		my $search_str = $genome_map{$key};
		my @pgenes = grep(/$search_str/,@predicted_genes);

		my $gene_count = @pgenes;

		print SUMMARY "Number of genes predicted for genome $key is $gene_count\n";	
	}

	close SUMMARY;
	system "cp $summary_file $output_dir";

	$message = "Copying log files....";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	my $warnings_dir = "$working_dir/warnings";

	if(not -d $warnings_dir)
	{
		$message = "$warnings_dir does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);
	}

	system "cp -rf $warnings_dir $output_dir";
	
	my $time_log = "$working_dir/time-log";

	if(not -e $time_log)
	{
		$message = "$time_log does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);
	}

	system "cp $time_log $output_dir";

	if(defined $log_file)
	{
		if(-e $log_file)
		{

			system "cp $log_file $output_dir";
		}
	}

	$message = "Done....";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

}
main;