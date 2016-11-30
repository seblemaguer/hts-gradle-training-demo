#!/usr/bin/perl

################################################################################
## get_path.pl
##
## Copyright 2012 Sébastien Le Maguer(Sebastien.Le_maguer@irisa.fr)
##
################################################################################

# [FLYMAKE]
# [/FLYMAKE]


use lib "../ext/perl";
use lib "perl";

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
################################################################################


my $flagHelp = 0;
my $flagLabel = 0;
my $flagPath = 1;
my $flagAll = 0;
my $init_state = 0;
GetOptions('a|all' => \$flagAll, 'h|help' => \$flagHelp, 'l|label' => \$flagLabel, 's|state=i' => \$init_state);

if ($flagAll)
{
	$flagPath = 1;
	$flagLabel = 1;
}

################################################################################

sub usage()
{
	print <<EOF;
Usage:
	get_path.pl <tree_file> <label>
Synopsis:

Options:
	-a, --all		return the path and the label							[false]
	-h, --help
	-l, --label 	return the label instead of the path					[false]
	-s, --state 	state_id												[not defined, used values in 2-6]
	-t, --tree		return the path											[true]
EOF
}


################################################################################

####
#  sub extract_header
#
#  Function used to associates the answers to the questions of the decision
#  tree. Useless lines are removed until the tree of the given state (programm)
#  is reached
#
#  param[in]:
#    - $lines = lines of the file (reference on a list)
#
#  return the questions hashtable which associates a list of regexp (answers) to
#  a question id
##
sub extract_header
{
    my ($lines) = @_;

    my $stop = 0;
    my %questions = ();

    while ($stop == 0)
    {
        # Question lines
        if ((!defined($lines->[0]))) {
            die "question file is empty";
        }
        if ($lines->[0] =~ /^QS/)
        {
            my @cur_line = split(/ /, $lines->[0]);
            my $name = $cur_line[1]; # Nom de la question
            my @answers = split(/,/, $cur_line[3]);

            # Adapt the answers to perl regexp
            for (my $i=0; $i<@answers; $i++)
            {
                $answers[$i] =~ s/"//g;
                $answers[$i] =~ s/\*/.*/g;
                $answers[$i] =~ s/\+/\\+/g;
                $answers[$i] =~ s/\?/\\?/g;
                $answers[$i] =~ s/\-/\\-/g;
                $answers[$i] =~ s/\^/\\^/g;
            }

            # Add the question
            @{$questions{$name}} = @answers;
            shift(@{$lines});


            # # <DEBUG>
            # print "====== $name =====\n";
            # foreach my $ans (@answers)
            # {
            #     print "  -  $ans\n";
            # }
            # print "\n";
            # # </DEBUG>
        }

        # Empty lines
        elsif (($lines->[0] =~ /.*\[[0-9]\]\.stream/) or ($lines->[0] =~ /.*\[[0-9]\]$/))
        {
            $stop = 1;
        }

        # Useless lines
        else
        {
            shift(@{$lines});
        }
    }

    # # <DEBUG>
    # print (Dumper(\%questions));
    # # </DEBUG>
    return %questions;
}


####
#  sub generate_tree
#
#  Function used to generate the tree. The is only an array of arrays. The
#  second level array contains 3 elements: the node name, the left node index,
#  the right node index. By using the name, we can find the regexp of answers in
#  the previously generated question hashtable
#
#  param[in]:
#    - $lines = lines of the file (reference on a list)
#
#  return the tree in a list data structure
##
sub generate_tree
{
    my ($lines) = @_;

    # Delete cur_tree header
    shift(@{$lines});
    shift(@{$lines});
    my @tree = ();

    # Extract sub_part
    while ($lines->[0] !~ /^\}$/)
    {
        my @cur_line = split(/[\s\t]+/, $lines->[0]);

        # Current node
        my $index = -$cur_line[1];
        my $name = $cur_line[2];

        # Left node
        my $left = $cur_line[3];
        if ($left =~ /\d+\z/) # integer? => node
        {
            $left = -$left;
        }
        else
        {
            $left =~ s/"//g;
        }

        # Right node
        my $right = $cur_line[4];
        if ($right =~ /\d+\z/)  # integer? => node
        {
            $right = -$right;
        }
        else
        {
            $right =~ s/"//g;
        }

        # Add thee node to the tree (store in a table way)
        shift(@{$lines});
        %{$tree[$index]} = (name=>$name, left=>$left, right=>$right);
    }


    # # <DEBUG>
    # for (my $i=1; $i<@tree; $i++)
    # {
    #     print "index = $i, name = ".$tree[$i]->{name}.", left = ".$tree[$i]->{left}.", right = ".$tree[$i]->{right}."\n";
    # }
    # # </DEBUG>

    return @tree;
}


####
#  sub get_path
#
#  Function used to find the path of a list of labels in the loaded tree
#
#  param[in]:
#    - $refQuest = reference on the question hashtable
#    - $refTree = reference on the tree
#    - $label = label whose path is going to be search
#
##
sub get_path
{
    my ($refQuest, $refTree, $label) = @_;
    my $cur_node = 0;
    my $name = undef;
    my $result = "";

    while ($cur_node =~ /^\d+\z$/) # Integer value implies a node
    {
        $name = $refTree->[$cur_node]->{name};
        # Check if an answer validate the label
        my @answers = @{$refQuest->{$name}};
        my $i=0;
        my $next_node = $refTree->[$cur_node]->{left};
        while (($i < @answers) and
               ("$next_node" eq "$refTree->[$cur_node]->{left}"))
        {
            my $ans = $answers[$i];
            if ($label =~ /$ans/)
            {
                $next_node = $refTree->[$cur_node]->{right};
            }
            $i++;
        }

        # Print name of the node and indicate the path (! implies the label does
        # not validate the question)
        if ($flagPath)
        {
            if ("$next_node" eq "$refTree->[$cur_node]->{right}")
            {
                $result .= "$name => ";
            }
			else
            {
                $result .= "!($name) => ";
            }
        }

        $cur_node = $next_node;
    }

    # End of the tree!
    if ($flagPath)
    {
        $result .= "/";
    }

	if (!$flagLabel)
	{
		$result .= "\n";
	}
	elsif (!$flagPath)
	{
        $result .= "$cur_node\n";
	}
    else
    {
        $result .= "\t$cur_node\n";
    }

    return $result;
}

################################################################################


if (($flagHelp) or (@ARGV != 3))
{
	die usage();
}

#########
## Load trees
################################
open(TREE_FILE, "$ARGV[0]") or die("cannot open $ARGV[0]: $!");
my @lines = <TREE_FILE>;
close(TREE_FILE);

my %questions = extract_header(\@lines);
my @trees = ();

while ($#lines != -1)
{
	# Go to next tree
	while (($#lines != -1) and (!(($lines[0] =~ /.*\[[0-9]\]\.stream/) or ($lines[0] =~ /.*\[[0-9]\]$/))))
	{
		shift(@lines);
	}

	# Is there really an new tree ?
	if ($#lines != -1)
	{
		my @tree = generate_tree(\@lines);
		push (@trees, \@tree);
	}
}


#########
## Find models
################################
open(LABELS, "$ARGV[1]") or die("cannot open $ARGV[1]: $!");
my @labels = <LABELS>;
close(LABELS);

open(RESULTS, ">$ARGV[2]") or die("cannot open $ARGV[2]: $!");

foreach my $label (@labels)
{
    chomp($label);
    my @cur_line = split(/[\s\t]+/, $label);
	my $state;
	if ((defined($cur_line[1])) and ($init_state == 0))
	{
		$state = $cur_line[1];
	}
	elsif ($init_state != 0)
	{
		$state = $init_state;
	}
	else
	{
	 	$state = 2;
	}

	# # print start
	# print "$label\t";

	# Adapt indexes
	$state = $state - 2;

	# Find path
    my $path = get_path(\%questions, $trees[$state], $cur_line[0]);
    print RESULTS $path;
}


close(RESULTS);
