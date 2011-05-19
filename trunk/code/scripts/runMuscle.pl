#!/usr/bin/perl

use strict;
use Getopt::Std;
use Cwd;


sub printOptions
{
	print("Usage :: perl runMuscle.pl\n");
	print("-d - Muscle directory <REQUIRED> \n");
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

	my $muscle_dir = $opt_d;
	my $input = $opt_i;
	my $output = $opt_o;

	my $ret_val = system "$muscle_dir/muscle -in $input -out $output";

	if($ret_val ne 0)
	{
		print("Error while running muscle\n");
		exit(-1);

	}

}

main;
