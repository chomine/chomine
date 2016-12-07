#!/usr/bin/env perl 
#===============================================================================
#
#  DESCRIPTION: sorts gff file so that child is always after Parent 
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

my %id_hash;
my %id_keys;

open(OUT, ">$opt{o}") or die ("Could not open $opt{o} for writing: $!\n");
open(IN, "<$opt{i}") or die ("Could not open $opt{i} for reading: $!\n");
my @in = <IN>;
close (IN);

foreach my $line (@in) {
    if ($line =~ /Parent=/) {
        my $parent = getId($line, "Parent=");
        if (exists($id_keys{$parent})) {
            print OUT $line;
        } else {
            $id_hash{$parent} .= $line;
        }
    }
    if ($line =~ /ID=/) {
        if ($line !~ /Parent=/) {
            print OUT $line;
        }
        my $id = getId($line, "ID=");
        $id_keys{$id} = 1;
        if ($id_hash{$id}) {
            print OUT $id_hash{$id};
            delete $id_hash{$id};
        }
    }
    if ($line !~ /ID=/ and $line !~ /Parent=/) {
        print OUT $line;
    }
}
foreach my $x (keys(%id_hash)) {
    print OUT $id_hash{$x};
}

close OUT;

#################################
# METHODS
#################################

sub getId {
    my ($l, $key) = @_;
    chomp($l);
    my @spl = split(/$key/, $l);
    if ($spl[1] =~ /;/){
        my @spl2 = split(/;/, $spl[1]);
        return $spl[0];
    } else {
        return $spl[1];
    }
}

sub usage {
    print <<"END_TEXT";
Sort GFF file, so that it can be load into intermine. Parents are located by
child elements.

Usage: $0 [OPTIONS]


   -h    show this help
   -i    input gff file
   -o    output sorted gff file

   Examples:
   $0 -i input.gff -o sorted.gff

END_TEXT

   exit( 0 );
}

