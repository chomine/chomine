#!/usr/bin/env perl 
#===============================================================================
#
#  DESCRIPTION: creates gene ontology annotation file for brinkrolf gff file
#
#       AUTHOR: Matthias P. Gerstl (matthias.gerstl@acib.at), 
#
#===============================================================================

use strict;
use warnings;
use utf8;
use Getopt::Std;

my $opt_string = 'hi:o:';
my %opt;
getopts( "$opt_string", \%opt ) or usage();
if ( $opt{h} or !$opt{i} or !$opt{o} ){
    usage();
}

open(OUT, ">$opt{o}") or die ("Could not open $opt{o} for writing: $!\n");
open(IN, "<$opt{i}") or die ("Could not open $opt{i} for reading: $!\n");
my @in = <IN>;
close (IN);

foreach my $line (@in) {
    if ($line !~ /^#/) {
        my @spl = split(/\t/, $line);
        if ($spl[2] eq "mRNA") {
            if ($line =~ /GO:/) {
                my $id = getId($line);
                my $gos = getGos($line);
                foreach my $x (keys(%{$gos})) {
                    print OUT "Brinkrolf et al\t$id\t$id\t\t";
                    print OUT "GO:$x\tDB:nd\tND\t\t";
                    print OUT "P\t\t\tgene\ttaxon:10029\t";
                    print OUT "20151215\tBrinkrolf et al\t\t\n";
                }
            }
        }
    }
}

close OUT;

#################################
# METHODS
#################################

sub getGos {
    my $l = shift;
    my $gos;
    my @spl = split(/GO:/, $l);
    for (my $i = 1; $i < @spl; $i++) {
        my @spl2 = split(/\[/, $spl[$i]);
        my @spl3 = split(/ - /, $spl2[0]);
        $gos->{$spl3[0]} = $spl3[1];
    }
    return $gos;
}

sub getId {
    my $l = shift;
    if ($l =~ /Parent=/) {
        my @spl = split(/Parent=/, $l);
        return parseId($spl[1]);
    } elsif ($l =~ /ID=/) {
        my @spl = split(/ID=/, $l);
        return parseId($spl[1]);
    } else {
        die ("no ID or Parent in \n$l");
    }
}

sub parseId {
    my $x = shift;
    if ($x =~ /;/){
        my @spl = split(/;/, $x);
        return $spl[0];
    } else {
        return $x;
    }
}

sub usage {
    print <<"END_TEXT";
Parses Brinkrolf GFF file and creates GO file for ChoMine

Usage: $0 [OPTIONS]


   -h    show this help
   -i    input gff file
   -o    output GO file

   Examples:
   $0 -i input.gff -o gene_association.brinkrolf

END_TEXT

   exit( 0 );
}

