#!/usr/bin/env perl 
#===============================================================================
#
#  DESCRIPTION: add ids to exons and CDS in gff file
#
#       AUTHOR: Matthias P. Gerstl (matthias.gerstl@acib.at), 
#
#===============================================================================

use strict;
use warnings;
use utf8;
use Getopt::Std;

use constant EXON => 1;
use constant CDS => 2;

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

my $id;
$id->[EXON] = 0;
$id->[CDS] = 0;

foreach my $l (@in) {
    my $id = getId($l);
    if ($id) {
        chomp($l);
        my @spl = split(/\t/, $l);
        for (my $i = 0; $i < 8; $i++) {
            print OUT $spl[$i]."\t";
        }
        print OUT "ID=".$id.";".$spl[8]."\n";
    } else {
        print OUT $l;
    }
}

close OUT;

#################################
# METHODS
#################################

sub getId {
    my $l = shift;
    if ($l =~ /\t/) {
        my @spl = split(/\t/, $l);
        if ($spl[2] eq "exon") {
            $id->[EXON]++;
            return "exon.".$id->[EXON];
        } 
        if ($spl[2] eq "CDS"){
            $id->[CDS]++;
            return "cds.".$id->[CDS];
        }
    }
    return 0;
}

sub usage {
    print <<"END_TEXT";
Add ids to exons and CDS in gff file

Usage: $0 [OPTIONS]


   -h    show this help
   -i    input gff file
   -o    output gff file

   Examples:
   $0 -i input.gff -o with_ids.gff

END_TEXT

   exit( 0 );
}
