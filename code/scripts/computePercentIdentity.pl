#!/usr/bin/perl

use strict;
use Getopt::Std;
use Cwd;


sub printOptions
{
	print("Usage :: perl computePrcentIdentity.pl\n");
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


sub max
{
	my $num1 = shift;
	my $num2 = shift;

	if($num1 > $num2)
	{
		return $num1;
	}
	else
	{

		return $num2;
	}	

}

sub round_off
{
	my $num = shift;

	## rounds off to two decimal places

	## first multiple by 100, then use the int function to throw away any decimals and then divide by 100.

	my $res = int($num * 100);
	$res = $res/100;

	return $res;


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

	my $message = "Logging messages from computePrcentIdentity.pl......";
	my $priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


	chdir($working_dir);

	#my $start = time();
	#print("Processing started $start\n");
	
	my $protein_len_file = "$working_dir/proteins-length.txt";	

	if(not -e $protein_len_file)
	{
		$message = "$protein_len_file does not exist.";
		$priority = 1;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		
	}
	else
	{

		open(PROT_IN,"$protein_len_file") or die("Could not open file $protein_len_file");
		my @data = <PROT_IN>;
		close PROT_IN;

		my %protein_len_map;

		foreach my $line (@data)
		{
			chomp($line);
			$line = trim($line);

			if($line ne "")
			{

				my @pieces = split(/,/,$line);	
				my $len = @pieces;

				if($len eq 5)
				{
					my $protein_name = trim($pieces[0]);
					my $len = trim($pieces[4]);
			
					$protein_len_map{$protein_name} = $len;

				}
				else
				{

					$message = "$protein_len_file has incorrect format.";
					$priority = 1;
					system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

					exit(-1);

				}


			}

		}

		
		## now read through the blast file and compute percent identity for every pair of proteins

		my $percent_id_file = "$working_dir/percent-identity.txt";

		my $blast_results = "$working_dir/blast/results/blast-query-results";

		if(not -e $blast_results)
		{
			$message = "Blast results file $blast_results does not exist.";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			exit(-1);

		}
		else
		{
			open(BLAST_RES,"$blast_results") or die("Could not open file $blast_results\n");
			my @blast_data = <BLAST_RES>;
			close BLAST_RES;

			open(PERCENT_OUT,">$percent_id_file") or die("Could not open file $percent_id_file\n");
			
			foreach my $blast_line (@blast_data)
			{
	
				chomp($blast_line);
				$blast_line = trim($blast_line);
				if($blast_line ne "")
				{
					my @blast_pieces = split(/\s+/,$blast_line);
					my $blast_len = @blast_pieces;
					if($blast_len eq 12)	
					{
						my $query_prot = trim($blast_pieces[0]);
						my $db_prot = trim($blast_pieces[1]);
						my $blast_percent_id = trim($blast_pieces[2]);
						my $align_len = trim($blast_pieces[3]);
						my $query_prot_len = $protein_len_map{$query_prot};
						my $db_prot_len = $protein_len_map{$db_prot};

						## compute percent identity

						my $new_percent_id = ($blast_percent_id * $align_len)/max($query_prot_len,$db_prot_len);
						#$new_percent_id = round_off($new_percent_id);

						$new_percent_id = sprintf("%.2f",$new_percent_id);

						#print("new percent id is $new_percent_id\n\n");
					
						my $print_str = "$query_prot|$db_prot,$new_percent_id";
						#my $print_str = "$query_prot,$db_prot,$new_percent_id";
						
						print PERCENT_OUT "$print_str\n";
	
					}
					else
					{

						$message = "Format of blast results incorrect. Blast results should have exactly 12 columns.";
						$priority = 1;
						system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

						exit(-1);
					}

				}
			}
			close PERCENT_OUT;

		}

	}	
	
		
	$message = "Done..";
	$priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

}
main;
