#!/usr/bin/perl

use strict;
use Getopt::Std;
use Cwd;


sub printOptions
{
	print("Usage :: perl convertOrthologsStdFormat.pl\n");
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

	my $message = "Logging messages from convertOrthologsStdFormat.pl......";
	my $priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


	chdir($working_dir);

	## first read genome name mappings

	my $genome_map_file = "$working_dir/genome-name-mapping.txt";

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


	## now create the orthologs file

	my $output_dir = "$working_dir/formatted_results";
	
	if(-d $output_dir)
	{
		system "rm -rf $output_dir";

	}

	mkdir($output_dir);


	my $orthologs_dir = "$working_dir/ortholog_sets";
	
	if(not -d $orthologs_dir)
	{
		$message = "$orthologs_dir does not exist";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);
	}

	my $orthologs_file = "$output_dir/orthologs.txt";
	open(OUT,">$orthologs_file") or die("Could not open file $orthologs_file\n");

	
	chdir($orthologs_dir);
	my $orthologs_lst = `ls`;
	my @orthologs = split(/\n/,$orthologs_lst);

	foreach my $ortholog (@orthologs)
	{
		chomp($ortholog);
		$ortholog= trim($ortholog);
		
		my $ref_gene = "$ortholog";
		$ref_gene =~ s/-orthologs//;
	
		my @ref_gene_pieces = split(/_/,$ref_gene);
		my $ref_gene_count = @ref_gene_pieces;

		my $ref_gene_name;
	
		if($ref_gene_count eq 3)
		{
			my $ref_genome_id = trim($ref_gene_pieces[0]);
			my $ref_seg_id = trim($ref_gene_pieces[1]);
			my $ref_gene_id = trim($ref_gene_pieces[2]);

			my $ref_gene_key = $ref_genome_id . "_".$ref_seg_id;
			my $ref_gene_val = $seg_name_map{$ref_gene_key};

			$ref_gene_name = $ref_gene_val. "." . $ref_gene_id;

		}
			

		my $ortholog_file = "$orthologs_dir/$ortholog";

		if(not -e $ortholog_file)
		{
			print("$ortholog_file does not exist\n");
			exit(-1);
		}

		open(IN,"$ortholog_file") or die("Could not open file $ortholog_file\n");
		my @data = <IN>;
		close IN;

		foreach my $line (@data)
		{
			chomp($line);
			$line = trim($line);
			

			my @pieces = split(/_/,$line);
			my $count = @pieces;

			if($count eq 3)
			{
				my $genome_id = trim($pieces[0]);
				my $seg_id = trim($pieces[1]);
				my $gene_id = trim($pieces[2]);

				my $key = "$genome_id". "_". "$seg_id";
				my $val = $seg_name_map{$key};
				
				my $gene_name = $val . "." . $gene_id;

				print OUT "$ref_gene_name|$gene_name\n";


			}

		}
	}



	close OUT;

	$message = "Done..";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


}

main;
