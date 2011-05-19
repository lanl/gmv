#!/usr/bin/perl

use strict;
use Getopt::Std;
use Cwd;


sub printOptions
{
	print("Usage :: perl getAllGenesForGenome.pl\n");
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

	my $message = "Logging messages from getAllGenesForGenome.pl......";
	my $priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


	chdir($working_dir);

	if(-d "prodigal_genes")
	{
		system "rm -rf prodigal_genes";

	}

	mkdir("prodigal_genes");

	my $genome_names_file = "$working_dir/genome-name-mapping.txt";

	if(not -e $genome_names_file)
	{
	
		$message = "$genome_names_file is not present.";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		exit(-1);

	}
	else
	{
		open(IN,"$genome_names_file") or die("Could not open file $genome_names_file\n");
		my @data = <IN>;
		close IN;

		my @genome_names;
		my $index=0;

 
		foreach my $line (@data)
		{
			chomp($line);
			$line = trim($line);
			if($line ne "")
			{
				my @pieces = split(/=/,$line);

				my $len = @pieces;
				if($len ne 2)
				{

					$message = "$genome_names_file has incorrect format.";
					$priority = 1;
					system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

					exit(-1);

				}
				else
				{	
					$genome_names[$index++]	= trim($pieces[1]);			

				}
			}

		}

		## the protein_len_file has all the genes. grep for those genes that start with a particular genome name and get their names	


		my $protein_len_file = "$working_dir/proteins-length.txt";

		my $all_genes_file = "$working_dir/all-genes.txt";
		open(ALL_GENES,">$all_genes_file") or die("Could not open file $all_genes_file\n");

		if(not -e $protein_len_file)
		{
			$message = "$protein_len_file is not present.";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			exit(-1);

		}
		else
		{
			foreach my $genome (@genome_names)
			{
				my $genes_file = "$working_dir/prodigal_genes/$genome-genes";
				open(GENES,">$genes_file") or die("Could not open file $genes_file\n");
					
				my $search_str = $genome."_";
				#my $res = `cat $protein_len_file | grep $search_str`;

				my $res = `grep \'$search_str'\ $protein_len_file`;

				my @res_pieces = split(/\n/,$res);
				foreach my $pc (@res_pieces)
				{
					chomp($pc);
					$pc = trim($pc);
					
					my @cur_line = split(/,/,$pc);
					my $line_len = @cur_line;

					if($line_len eq 5)
					{
						my $print_str = trim($cur_line[0]);
						print GENES "$print_str\n";
						print ALL_GENES "$print_str\n";

					}
					
				}

				close(GENES);
			}
			
		}
		
		
	}


	close ALL_GENES;

	$message = "Done..";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
	
}

main;
