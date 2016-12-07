#!/usr/bin/env perl 
#===============================================================================
#
#  DESCRIPTION: merges proteins from Uniprot data with genes from gff file
#
#       AUTHOR: Matthias Gerstl (), 
#
#===============================================================================

use strict;
use warnings;
use utf8;
use Getopt::Std;
use Data::Dumper;

my $opt_string = 'hg:u:p:o:';
my %opt;
getopts( "$opt_string", \%opt ) or usage();
if ( $opt{h} or !$opt{g} or !$opt{u} or !$opt{o} or !$opt{p} ){
    usage();
}

open(OUT, ">$opt{o}") or die ("Could not open $opt{o} for writing: $!\n");

my $u = readFile($opt{u});
my $proteins = processUniprot($u);
my $g = readFile($opt{g});
my $prefix = $opt{p};

foreach my $x (@{$g}) {
    if ($x =~ /gene/){
        my @spl = split(/\t/, $x);
        if ($spl[2] eq "gene"){
            if ($x =~ /GeneID:/){
                my @spl2 = split(/GeneID:/, $x);
                my @spl3 = split(/;/, $spl2[1]);
                my $geneid = $spl3[0];
                if ($proteins->{$geneid}) {
                    my $ct = scalar(@{$proteins->{$geneid}});
                    if ($ct > 0){
                        my @spl4 = split(/ID=/, $x);
                        my @spl5 = split(/;/, $spl4[1]);
                        my $id = $spl5[0];
                        for (my $i = 0; $i < $ct; $i++) {
                            print OUT "$prefix.$id,$proteins->{$geneid}[$i]{name},$proteins->{$geneid}[$i]{acc}\n";
                        }
                    }
                }
            }
        }
    }
}

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
        } elsif ($x =~ /type="GeneID"/) {
            my @spl = split(/id="/, $x);
            my @spl2 = split(/"/, $spl[1]);
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

Usage: $0 [OPTIONS]


   -h    show this help
   -g    gff file
   -u    uniprot file
   -p    prefix
   -o    output merge file

   Examples:
   $0 -u sorted.gff -u trembl.xml -p lewis -o uniprot.merge

END_TEXT

   exit( 0 );
}




