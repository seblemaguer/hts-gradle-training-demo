#!/usr/bin/perl

my $in = $ARGV[0];
my $out = $ARGV[1];

open(FILE, "$in") or die ("cannot open $in: $!");
my @lines = <FILE>;
close(FILE);

open(OUT, ">$out") or die ("cannot open $out: $!");

my $shift = 5 * 10000; # FIXME: hardcoded

my $pos = 0;
foreach my $line (@lines)
{
	if ($line !~ /state/)
    {
        if ($line =~ /(.*-[a-zA-Z]+\+.*): duration=([0-9]+)/)
        {
            printf OUT "%d ", $pos;
            $pos = $pos + $2*$shift;
            printf OUT "%d ", $pos;
            print OUT "$1\n";
        }
    }
}
close(OUT);
