#!/usr/bin/perl

use strict;
use Getopt::Std;

sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}



sub getValue
{

	my $str = shift;
	my @pcs = split(/=/,$str);
	my $len = @pcs;
	my $return_str="";
	
	if($len eq 2)
	{
		
		$return_str = trim($pcs[$len-1]);
	}

	return $return_str;
}	

sub printOptions
{
	print("Usage :: perl start.pl\n");
	print("-i  Input directory contains all the sequence files in fasta format. <REQUIRED> \n");
	print("-o  Output directory contains the results. <REQUIRED> \n");
	print("-w  Working directory cotains all the intermediate results. <REQUIRED> \n");
	#print("-r  Name of the reference genome file. Default - the first genome file in the genome set will be considered as the reference genome.\n");
	print("-f  1 to remove all intermediate files and 0 to retain intermediate files. Default 0. \n");
	print("-c  Complete path to the configuration file. <REQUIRED> \n");
	print("-v  Logging level. 1 is ERROR, 2 is WARNING, 3 is INFO. Default is 1.\n");
	print("-l  Log file with complete path. Default - Log messages will be written to standard output\n");
	print("-n  Number of processors on the machine on which BLAST could be run. Default 1. \n");
	print("-b  Begin step. See below for step numbers. If only the start step is specified, the program will run from the start step till the end. Default is run all steps.\n");
	print("-e  End step. See below for step numbers. If only the end step is specified, the program will run from the beginning till the end step. Default is run all steps.\n\n");
	print("Step Numbers\n");
	print("1  Create working directory and train and run Prodigal.\n");
	print("2  Process Prodigal files to obtain all possible start sites for all genes.\n");
	print("3  Create BLAST database.\n");
	print("4  Run BLAST.\n");
	print("5  Compute percent identity.\n");
	print("6  Get orthologous sets of genes.\n");
	print("7  Generate input files for alignments.\n");
	print("8  Get muscle alignments.\n");
	print("9  Prediction of start sites.\n");
	

}

sub main
{
	#our($opt_i,$opt_o,$opt_f, $opt_c, $opt_v, $opt_w, $opt_n, $opt_b, $opt_e, $opt_r,$opt_l);

	our($opt_i,$opt_o,$opt_f, $opt_c, $opt_v, $opt_w, $opt_n, $opt_b, $opt_e,$opt_l); ## do not take ref genome as input
	
	getopt("iofcvwnbel");

	if((not defined $opt_i) || (not defined $opt_o) || (not defined $opt_w) || (not defined $opt_c))
	{
		printOptions;
		exit(0);
	}

	my $input_dir = $opt_i;
	my $output_dir = $opt_o;
	my $working_dir = $opt_w;
	#my $ref_genome = $opt_r;
	my $remove_flag = $opt_f;
	my $config_file = $opt_c;
	my $log = $opt_v;
	my $log_file = $opt_l;
	my $num_processors = $opt_n;
	my $begin_step = trim($opt_b);
	my $end_step = trim($opt_e); 

	my $scripts_dir ="";
	my $muscle_dir="";
	my $prodigal_dir = "";
	my $blast_dir = "";
	my $perl_dir = "";
	my $java_bin_dir = "";
	my $java_code_dir = "";

	#my $ref_genome;

	my $exit_flag =0;

	my $max_steps =9;

	if(not defined $remove_flag)
	{
		$remove_flag = 0;
	}

	if(not defined $log)
	{

		$log = 1;
	}
	else
	{
		if(($log > 3) || ($log < 1))
		{
			print("\n\n**********************INCORRECT LOGGING LEVEL**********************\n\n");
			printOptions();
			exit(0);

		}

	}

	if(not defined $log_file)
	{
		$log_file = "nodef";
	}

	if(not defined $num_processors)
	{

		$num_processors = 1;
	}

	if(not defined $begin_step)
	{
		$begin_step =1;
	}

	if(not defined $end_step)
	{
			
		$end_step =$max_steps;
	}

	
	
	## check for errors

	if(not -d $input_dir)
	{
		print("Directory $input_dir does not exist. \n");
		$exit_flag =1;
	}

	if(not -d $output_dir)
	{
		print("Directory $output_dir does not exist. \n");
		$exit_flag =1;
	}

	if(not -d $working_dir)
	{
		print("Directory $working_dir does not exist. \n");
		$exit_flag =1;
		
	}

	if(not -e $config_file)	
	{
		print("Directory $config_file does not exist. \n");
		$exit_flag = 1;

	}

	if($begin_step > $end_step)
	{
		print("Start step number should not be greater than the end step number.\n");
		$exit_flag=1;

	}

	if(($begin_step > $max_steps) || ($end_step > $max_steps))
	{
		print("Step number should not exceed the maximum number of steps $max_steps.\n");
		$exit_flag =1;
	}



	##read the configs file

	if(-e $config_file)
	{

		open(INPUT,"$config_file") or die("Could not open file - $config_file\n");
		my @data = <INPUT>;
		close INPUT;

		
		foreach my $line (@data)
		{
			chomp($line);
			if($line =~ m/SCRIPTS_DIR/)
			{
				$scripts_dir = getValue($line);	
				
				if($scripts_dir eq "")
				{
					print("Scripts directory is not set in the config file.\n");
					$exit_flag =1;
				}
				elsif(not -d $scripts_dir)
				{
					print("Scripts directory does not exist.\n");
					$exit_flag =1;
				}

				
			}
			elsif($line =~ m/PRODIGAL_DIR/)
			{
				
				$prodigal_dir = getValue($line);
				if($prodigal_dir eq "")
				{
					print("Prodigal directory is not set in the config file.\n");
					$exit_flag =1;
					
				}
				elsif(not -d $prodigal_dir)
				{
					print("Prodigal directory does not exist.\n");
					$exit_flag=1;
				}
			}
			elsif($line =~ m/MUSCLE_DIR/)
			{
				$muscle_dir = getValue($line);	
				if($muscle_dir eq "")
				{

					print("Muscle directory is not set is not set in the config file.\n");
					$exit_flag =1;
					
				}
				elsif(not -d $muscle_dir)
				{
					print("Muscle directory does not exist. \n");
					$exit_flag =1;
				}

			}
			elsif($line =~ m/BLAST_DIR/)
			{
				$blast_dir = getValue($line);	
				if($blast_dir eq "")
				{
					print("BLAST directory is not set in the config file. \n");
					$exit_flag=1;
					
				}
				elsif(not -d $blast_dir)
				{
					print("BLAST directory does not exist. \n");
					$exit_flag =1;
				}
			}
			elsif($line =~ m/PERL_DIR/)
			{
				$perl_dir = getValue($line);	
				if($perl_dir eq "")
				{
					print("Perl directory is not set in the config file. \n");
					$exit_flag=1;
					
				}
				elsif(not -d $perl_dir)
				{	
					print("Perl directory does not exist. \n");
					$exit_flag =1;
				}
			}
			elsif($line =~ m/JAVA_BIN_DIR/)
			{
				$java_bin_dir = getValue($line);
				if($java_bin_dir eq "")
				{
					print("Java bin directory is not set in the config file. \n");
					$exit_flag=1;
					
				}
				elsif(not -d $java_bin_dir)
				{	
					print("Java bin directory does not exist. \n");
					$exit_flag =1;
				}
				

			}
			elsif($line =~ m/JAVA_CODE_DIR/)
			{
				$java_code_dir = getValue($line);
				if($java_code_dir eq "")
				{
					print("Java code directory is not set in the config file. \n");
					$exit_flag=1;
					
				}
				elsif(not -d $java_code_dir)
				{	
					print("Java code directory does not exist. \n");
					$exit_flag =1;
				}
				

			}
	
			

		}

	}

	if($exit_flag eq 1)
	{
		print("Exiting due to errors....\n");
		exit(-1);

	}

	my $message = "Logging level is $log.\n";
	$message = $message ."Logging messages from start.pl......\n";
	$message = $message . "Input directory is $input_dir.\n";
	$message = $message . "Output directory is $output_dir.\n";
	$message = $message . "Working directory is $working_dir.\n";
	$message = $message . "Flag to retain/remove intermediate files is $remove_flag.\n";
	$message = $message . "Config file is $config_file.\n";
	$message = $message . "Number of processors on which BLAST can be run is $num_processors.\n\n";
	$message = $message . "Scripts directory is $scripts_dir\n";
	$message = $message . "Prodigal directory is $prodigal_dir\n";
	$message = $message . "Muscle directory is $muscle_dir\n";
	$message = $message . "BLAST directory is $blast_dir\n";	
	$message = $message . "Perl directory is $perl_dir\n";
	$message = $message . "\n\n *************Running pipeline from $begin_step to $end_step*************";

	my $priority = 2;
	system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	my $time_log = "$working_dir/time-log";  ## time taken by each step in minutes
	my $start_time =0;
	my $end_time=0;
	my $time_taken=0;
	my $total_time =0;

	if($begin_step eq 1)
	{
		open(TIME_LOG,">$time_log") or die("Could not open file $time_log\n");

		print TIME_LOG "This file gives the time taken by each step in the pipeline in minutes\n\n";
	}
	else
	{
		open(TIME_LOG,">>$time_log") or die("Could not open file $time_log\n");
	}

	my $return_val=0;
	my $step_num =0;
	
	$step_num =1;
	
	if(($begin_step <= $step_num) && ($step_num <= $end_step))	
	{

		$message = "Running step $step_num...";
		$priority = 2;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
	
		##call createWorkingDir.pl
		$start_time = time();
		$return_val = system "$perl_dir/perl $scripts_dir/createWorkingDir.pl -i $input_dir -o $working_dir -v $log -l $log_file -p $perl_dir -s $scripts_dir";
		$end_time = time();

		if($return_val ne 0)
		{
			$message = "Error in creating working directory. Program exiting..";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
	
			close TIME_LOG;
			exit(0);
		}

		$time_taken = ($end_time - $start_time)/60;
		$total_time = $total_time + $time_taken;
		print TIME_LOG "Time take to create the initial working directory is $time_taken minutes\n";

		
		## call createInputSequences.pl
		$start_time = time();
		$return_val = system "$perl_dir/perl $scripts_dir/createInputSequences.pl -o $working_dir -v $log -l $log_file -p $perl_dir -s $scripts_dir";
		$end_time = time();
		
		if($return_val ne 0)
		{
			$message = "Error in creating dna sequence files. Program exiting.. ";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
	
			close TIME_LOG;
			exit(0);
		}

		$time_taken = ($end_time - $start_time)/60;
		$total_time = $total_time + $time_taken;
		print TIME_LOG "Time taken to create the input sequence files for prodigal is $time_taken minutes\n";

		
		
		## call trainProdigal.pl
		$start_time = time();
		$return_val = system "$perl_dir/perl $scripts_dir/trainProdigal.pl -d $working_dir -c $prodigal_dir -v $log -l $log_file -p $perl_dir -s $scripts_dir";
		$end_time = time();

		if($return_val ne 0)
		{
			$message = "Error in training prodigal. Program exiting.. ";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
	
			close TIME_LOG;
			exit(0);
		}

		$time_taken = ($end_time - $start_time)/60;	
		$total_time = $total_time + $time_taken;
		print TIME_LOG "Time taken to train prodigal is $time_taken minutes\n";
			
		## call runProdigal.pl
		$start_time = time();	
		$return_val = system "$perl_dir/perl $scripts_dir/runProdigal.pl -d $working_dir -c $prodigal_dir -v $log -l $log_file -p $perl_dir -s $scripts_dir";
		$end_time = time();

		if($return_val ne 0)
		{
			$message = "Error in running prodigal for gene prediction. Program exiting.. ";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
	
			close TIME_LOG;
			exit(0);

		}

		$time_taken = ($end_time - $start_time)/60;
		$total_time = $total_time + $time_taken;
		print TIME_LOG "Time taken by Prodigal to predict genes is $time_taken minutes\n";

		## call postprocessProdigalProteinFiles.pl
		$start_time = time();
		$return_val = system "$perl_dir/perl $scripts_dir/postprocessProdigalProteinFiles.pl -d $working_dir -v $log -l $log_file -p $perl_dir -s $scripts_dir";
		$end_time = time();
		
		if($return_val ne 0)
		{
			$message = "Error in postprocessing protein files generated by prodigal. Program exiting..";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			close TIME_LOG;
			exit(0);
		
		}

		$time_taken = ($end_time - $start_time)/60;
		$total_time = $total_time + $time_taken;
		print TIME_LOG "Time taken to postprocess prodigal protein files is $time_taken minutes\n";

                ## call get_all_genes_for_genome.pl
		$start_time = time();
		$return_val = system "$perl_dir/perl $scripts_dir/getAllGenesForGenome.pl -d $working_dir -v $log -l $log_file -p $perl_dir -s $scripts_dir";
		$end_time = time();

		if($return_val ne 0)	
		{
			$message = "Error in getting all gene names for genomes.";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			close TIME_LOG;
			exit(0);
		}

		$time_taken =  ($end_time - $start_time)/60;
		$total_time = $total_time + $time_taken;
		print TIME_LOG "Time taken to get all gene names for genomes is $time_taken minutes\n";
   
               
		$message = "Step $step_num is complete...";
		$priority = 2;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
		
		
	}

	$step_num =2;

	if(($begin_step <=$step_num) && ($step_num <=$end_step))
	{

		$message = "Running step $step_num...";
		$priority = 2;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
		
		##call postprocessProdigalScoresFiles.pl
		$start_time = time();
		$return_val = system "$perl_dir/perl $scripts_dir/postprocessProdigalScoresFiles.pl -d $working_dir -v $log -l $log_file -p $perl_dir -s $scripts_dir";
		$end_time = time();

		if($return_val ne 0)	
		{
			$message = "Error in postprocessing prodigal scores files. Program exiting..";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
	
			close TIME_LOG;
			exit(0);
		}
			
		$time_taken = ($end_time - $start_time)/60;
		$total_time = $total_time + $time_taken;
		print TIME_LOG "Time taken to postprocess prodigal score files is $time_taken minutes \n";

		$message = "Step $step_num is complete...";
		$priority = 2;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	}

	$step_num = 3;

	if(($begin_step <= $step_num) && ($step_num <=$end_step))
	{
		$message = "Running step $step_num...";
		$priority = 2;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


		## call createBLASTDB.pl
		$start_time = time();
		$return_val = system "$perl_dir/perl $scripts_dir/createBLASTDB.pl -d $working_dir -c $blast_dir -v $log -l $log_file -p $perl_dir -s $scripts_dir";
		$end_time = time();
		
		if($return_val ne 0)
		{
			$message = "Error in creating the database file for BLAST. Program exiting..";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";
	
			close TIME_LOG;
			exit(0);

		}
		
		$time_taken = ($end_time - $start_time)/60;	
		$total_time = $total_time + $time_taken;
		print TIME_LOG "Time taken to create database file for BLAST is $time_taken minutes\n";

		$message = "Step $step_num is complete...";
		$priority = 2;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";


	}

	$step_num = 4;
	
	if(($begin_step <= $step_num) && ($step_num <= $end_step))
	{
		$message = "Running step $step_num...";
		$priority = 2;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		
		## call runBLAST.pl
		$start_time = time();
		$return_val = system "$perl_dir/perl $scripts_dir/runBLAST.pl -d $working_dir -c $blast_dir -v $log -n $num_processors -l $log_file -p $perl_dir -s $scripts_dir";
		$end_time = time();

		if($return_val ne 0)
		{
			$message = "Error in running BLAST. Program exiting..";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			close TIME_LOG;
			exit(0);
		}

		$time_taken = ($end_time - $start_time)/60;
		$total_time = $total_time + $time_taken;
		print TIME_LOG "Time taken to run BLAST is $time_taken minutes \n";

		$message = "Step $step_num is complete..";
		$priority = 2;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	}

	$step_num =5;

	if(($begin_step <= $step_num) && ($step_num <= $end_step))
	{

		$message = "Running step $step_num...";
		$priority = 2;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

		
		## call compute_percent_identity.pl
		$start_time = time();
		$return_val = system "$perl_dir/perl $scripts_dir/computePercentIdentity.pl -d $working_dir -v $log -l $log_file -p $perl_dir -s $scripts_dir";
		$end_time = time();

		if($return_val ne 0)
		{

			$message = "Error while computing pairwise identity. Program exiting..";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			close TIME_LOG;
			exit(0);
		}

		$time_taken = ($end_time - $start_time)/60;
		$total_time = $total_time + $time_taken;
		print TIME_LOG "Time taken to compute percent identity is $time_taken minutes \n";

		$message = "Step $step_num is complete...";
		$priority = 2;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	}

	my $step_num = 6;

	if(($begin_step <= $step_num) && ($step_num <= $end_step))
	{
		$message = "Running step $step_num...";
		$priority = 2;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	
		## call sort_blast_results.pl
		$start_time = time();
		$return_val = system "$perl_dir/perl $scripts_dir/sortBlastResults.pl -d $working_dir -v $log -l $log_file -p $perl_dir -s $scripts_dir";
		$end_time = time();

		if($return_val ne 0)
		{
			$message = "Error while sorting results from BLAST. Program exiting.. ";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			close TIME_LOG;
			exit(0);
		}

		$time_taken = ($end_time - $start_time)/60;
		$total_time = $total_time + $time_taken;
		print TIME_LOG "Time taken to sort BALST results is $time_taken minutes \n";


		## call get_best_gene_pairs.pl
		$start_time = time();
		$return_val = system "$perl_dir/perl $scripts_dir/getBestGenePairs.pl -d $working_dir -v $log -l $log_file -p $perl_dir -s $scripts_dir";
		$end_time = time();

		if($return_val ne 0)
		{
			$message = "Error while generating best gene pairs. Program exiting..";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			close TIME_LOG;
			exit(0);
		}

		$time_taken = ($end_time - $start_time)/60;
		$total_time = $total_time + $time_taken;
		print TIME_LOG "Time taken to generate the best possible gene pairs is $time_taken minutes \n";

		## call get_orthologus_sets.pl
		$start_time = time();
		$return_val = system "$perl_dir/perl $scripts_dir/getOrthologousSets.pl -d $working_dir -v $log -l $log_file -p $perl_dir -s $scripts_dir";
		$end_time = time();

		if($return_val ne 0)
		{
			$message = "Error while generating orthologous sets of genes. Program exiting..";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			close TIME_LOG;
			exit(0);
		}

		$time_taken = ($end_time - $start_time)/60;
		$total_time = $total_time + $time_taken;
		print TIME_LOG "Time taken to generate orthologous sets of genes is $time_taken minutes \n";


		$message = "Step $step_num is complete..";
		$priority = 2;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	}

	my $step_num = 7;

	if(($begin_step <= $step_num) && ($step_num <= $end_step))
	{
		$message = "Running step $step_num...";
		$priority = 2;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	
		## call createInputForAlignment.pl
		$start_time = time();
		$return_val = system "$perl_dir/perl $scripts_dir/createInputForAlignment.pl -d $working_dir -v $log -l $log_file -p $perl_dir -s $scripts_dir";
		$end_time = time();

		if($return_val ne 0)
		{
			$message = "Error while creating input files for alignment. Program exiting.. ";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			close TIME_LOG;
			exit(0);
		}

		$time_taken = ($end_time - $start_time)/60;
		$total_time = $total_time + $time_taken;
		print TIME_LOG "Time taken to create input files for alignment is $time_taken minutes \n";

	}

	
	my $step_num = 8;

	if(($begin_step <= $step_num) && ($step_num <= $end_step))
	{
		$message = "Running step $step_num...";
		$priority = 2;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	
		## call getAlignments.pl
		$start_time = time();
		$return_val = system "$perl_dir/perl $scripts_dir/getAlignments.pl -d $working_dir -v $log -l $log_file -p $perl_dir -s $scripts_dir -r $muscle_dir";
		$end_time = time();

		if($return_val ne 0)
		{
			$message = "Error while generating muscle alignments. Program exiting.. ";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			close TIME_LOG;
			exit(0);
		}

		$time_taken = ($end_time - $start_time)/60;
		$total_time = $total_time + $time_taken;
		print TIME_LOG "Time taken to compute muscle alignments is $time_taken minutes \n";

	}

	my $step_num = 9;

	if(($begin_step <= $step_num) && ($step_num <= $end_step))
	{
		$message = "Running step $step_num...";
		$priority = 2;
		system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

	
		## call generateRelativeStartSitesFile.pl
		$start_time = time();
		$return_val = system "$perl_dir/perl $scripts_dir/generateRelativeStartSitesFile.pl -d $working_dir -v $log -l $log_file -p $perl_dir -s $scripts_dir";
		$end_time = time();

		if($return_val ne 0)
		{
			$message = "Error while generating relative start sites. Program exiting.. ";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			close TIME_LOG;
			exit(0);
		}

		$time_taken = ($end_time - $start_time)/60;
		$total_time = $total_time + $time_taken;
		print TIME_LOG "Time taken to compute relative start sites is $time_taken minutes \n";


		## call predictCommonStart.pl
		$start_time = time();
		$return_val = system "$perl_dir/perl $scripts_dir/predictCommonStart.pl -d $working_dir -v $log -l $log_file -p $perl_dir -s $scripts_dir -j $java_bin_dir -c $java_code_dir";
		$end_time = time();

		if($return_val ne 0)
		{
			$message = "Error while predicting common start sites. Program exiting.. ";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			close TIME_LOG;
			exit(0);
		}

		$time_taken = ($end_time - $start_time)/60;
		$total_time = $total_time + $time_taken;
		print TIME_LOG "Time taken to predict common start sites is $time_taken minutes \n";

		## call outputResults.pl

		$start_time = time();
		$return_val = system "$perl_dir/perl $scripts_dir/outputResults.pl -d $working_dir -v $log -l $log_file -p $perl_dir -s $scripts_dir -o $output_dir";
		$end_time = time();

		if($return_val ne 0)
		{
			$message = "Error while writing results to output dir. Program exiting.. ";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			close TIME_LOG;
			exit(0);
		}

		$time_taken = ($end_time - $start_time)/60;
		$total_time = $total_time + $time_taken;
		print TIME_LOG "Time taken to output results is $time_taken minutes \n";

		##call formatResultsGBKFormat.pl
	
		$start_time = time();
		$return_val = system "$perl_dir/perl $scripts_dir/formatResultsGBKFormat.pl -d $working_dir -v $log -l $log_file -p $perl_dir -s $scripts_dir -o $output_dir";
		$end_time = time();

		if($return_val ne 0)
		{
			$message = "Error while formatting results. Program exiting.. ";
			$priority = 1;
			system "$perl_dir/perl $scripts_dir/logging.pl -v $log -l \'$log_file\' -p $priority -m \'$message\'";

			close TIME_LOG;
			exit(0);
		}

		$time_taken = ($end_time - $start_time)/60;
		$total_time = $total_time + $time_taken;
		print TIME_LOG "Time taken to format results is $time_taken minutes \n";

		if($remove_flag eq 1)
		{
			system "rm -rf $working_dir";

		}


	}


		

	## pipeline ends
	print TIME_LOG "\n\n Total time take is $total_time minutes\n\n";
	
	close TIME_LOG;
	
}

main;
