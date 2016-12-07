#!/usr/bin/env perl 
#===============================================================================
#
#  DESCRIPTION: sorts gff file so that child is always after Parent 
#               add a parent_type field to exons
#
#       AUTHOR: Matthias P. Gerstl (matthias.gerstl@acib.at)
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

my %parent_hash;
my @primary_arr;
my @print_arr;

my $gfffile = $opt{i};
open(IN, "<$gfffile") or die ("Could not open $gfffile: $!\n");
my @in = <IN>;
close(IN);

foreach my $line (@in) {
    chomp($line);
    if ($line =~ /^#/){
        print OUT "$line\n";
    } else {
        if ($line !~ /ID=/) {
            die "following line has no ID attribute:\n$line\n";
        }
        my $id;
        my @spl2 = split(/ID=/, $line);
        if ($spl2[1] =~ /;/) {
            my @spl3 = split(/;/, $spl2[1]);
            $id = $spl3[0];
        } else {
            $id = $spl2[1];
        }
        my @spl = split(/\t/, $line);
        my $type = $spl[2];
        if ($line !~ /Parent=/) {
            print OUT $line."\n";
            $parent_hash{$id} = $type;
        } else {
            my $parent;
            my @spl2 = split(/Parent=/, $line);
            if ($spl2[1] =~ /;/) {
                my @spl3 = split(/;/, $spl2[1]);
                $parent = $spl3[0];
            } else {
                $parent = $spl2[1];
            }
            my $t_h;
            $t_h->{line} = $line;
            $t_h->{parent} = $parent;
            if ($type eq "exon" or $type eq "CDS") {
                push(@print_arr, $t_h);
            } else {
                $parent_hash{$id} = $type;
                push(@primary_arr, $t_h);
            }
        }
    }
}

foreach my $x (@primary_arr) {
    if ($parent_hash{$x->{parent}}) {
        print OUT $x->{line}."\n";
    } else {
        die "Cannot find Parent for line\n$x->{line}!\n";
    }
}

foreach my $x (@print_arr) {
    if ($parent_hash{$x->{parent}}) {
        print OUT "$x->{line};parent_type=";
        print OUT $parent_hash{$x->{parent}};
        print OUT "\n";
    } else {
        die "Cannot find Parent for line\n$x->{line}!\n";
    }
}

close OUT;
