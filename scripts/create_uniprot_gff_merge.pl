#!/usr/bin/env perl 
#===============================================================================
#
#  DESCRIPTION: merges proteins from Uniprot data with genes from gff file
#
#       AUTHOR: Matthias P. Gerstl (matthias.gerstl@acib.at), 
#
#===============================================================================

use strict;
use warnings;
use utf8;
use Getopt::Std;
use Data::Dumper;

my $opt_string = 'hg:u:o:';
my %opt;
getopts( "$opt_string", \%opt ) or usage();
if ( $opt{h} or !$opt{g} or !$opt{u} or !$opt{o}){
    usage();
}

open(OUT, ">$opt{o}") or die ("Could not open $opt{o} for writing: $!\n");

my $u = readFile($opt{u});
my $proteins = processUniprot($u);
my $g = readFile($opt{g});

foreach my $x (@{$g}) {
    if ($x =~ /mRNA/){
        my @spl = split(/\t/, $x);
        if ($spl[2] eq "mRNA"){
            if ($x =~ /ID=/){
                my @spl2 = split(/ID=/, $x);
                my @spl3 = split(/;/, $spl2[1]);
                my $geneid = $spl3[0];
                if ($proteins->{$geneid}) {
                    my $ct = scalar(@{$proteins->{$geneid}});
                    if ($ct > 0){
                        for (my $i = 0; $i < $ct; $i++) {
                            print OUT "$geneid,$proteins->{$geneid}[$i]{name},$proteins->{$geneid}[$i]{acc}\n";
                        }
                    }
                }
            }
        }
    }
}

close OUT ;

#################################
# METHODS
#################################

sub processUniprot {
    my ($in) = @_;
    my $prot;
    my $acc = '';
    my $name = '';
    my $accSet = 0;
    my $nameSet = 0;
    foreach my $x (@{$in}) {
        if ($x =~ /<entry /){
            $acc = '';
            $name = '';
            $accSet = 0;
            $nameSet = 0;
        } elsif (!$accSet and $x =~ /<accession>/){
            my @spl = split(/>/, $x);
            my @spl2 = split(/</, $spl[1]);
            $acc = $spl2[0];
            $accSet = 1;
        } elsif (!$nameSet and $x =~ /<name>/){
            my @spl = split(/>/, $x);
            my @spl2 = split(/</, $spl[1]);
            $name = $spl2[0];
            $nameSet = 1;
        } elsif ($x =~ /type="ORF"/ and $x =~ /H671_/) {
            my @spl = split(/>/, $x);
            my @spl2 = split(/</, $spl[1]);
            my $data->{acc} = $acc;
            $data->{name} = $name;
            push(@{$prot->{$spl2[0]}}, $data);
        }
    }
    return $prot;
}

sub readFile {
    my ($file) = @_;
    open(IN, "<$file") or die ("Could not open $file for reading: $!\n");
    my @in = <IN>;
    close(IN);
    return \@in;
}

# HELP
#################################
sub usage {
    print <<"END_TEXT";
Merges proteins from Uniprot data with genes from gff file

Usage: $0 [OPTIONS]


   -h    show this help
   -g    gff file
   -u    uniprot file
   -o    output merge file

   Examples:
   $0 -g sorted.gff -u trembl.xml -o uniprot.merge

END_TEXT

   exit( 0 );
}




