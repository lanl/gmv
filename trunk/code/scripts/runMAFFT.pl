#!/usr/bin/perl

use strict;
use Getopt::Std;
use Cwd;


sub printOptions
{
	print("Usage :: perl runMAFFT.pl\n");
	print("-d - MAFFT directory <REQUIRED> \n");
	print("-i - Input file in fasta format <REQUIRED> \n");
	print("-o - Output alignment file (alignment will be in fasta format) <REQUIRED> \n");


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

	our($opt_d,$opt_i,$opt_o);

	getopt("dio");

	if((not defined $opt_d) || (not defined $opt_i) || (not defined $opt_o))
	{
		printOptions;
		exit(0);
	
	}

	my $mafft_dir = $opt_d;
	my $input = $opt_i;
	my $output = $opt_o;
	my $temp = $output.".temp";

	my $ret_val = system "$mafft_dir/mafft --localpair --maxiterate 1000 $input > $temp";

	if($ret_val ne 0)
	{
		print("Error while running mafft\n");
		exit(-1);

	}

	open(IN,"$temp") or die("Could not open file $temp\n");
	my @data = <IN>;
	close IN;

	open(OUT,">$output") or die("Could not open file $output\n");

	foreach my $line (@data)
	{
		$line =~ tr/a-z/A-Z/;
		print OUT "$line";

	}
	close OUT;

	system "rm $temp";

}

main;
