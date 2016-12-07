#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: createKeggIntermineInputFile.pl
#
#        USAGE: ./createKeggIntermineInputFile.pl  
#
#  DESCRIPTION: creates Kegg input file needed for Intermine
#
#       AUTHOR: Matthias P. Gerstl 
#===============================================================================

use strict;
use warnings;
use utf8;
use Getopt::Std;
use Data::Dumper;

my $opt_string = 'hi:l:x:u:';
my %opt;
getopts( "$opt_string", \%opt ) or usage();
if ( $opt{h} or !$opt{i} or !$opt{l} or !$opt{x} or !$opt{u}){
    usage();
}

my $kegg_map = parseKeggFile($opt{i});
my $lewis_map = parseLewisXuGff($opt{l}, "lewis.");
my $xu_map = parseLewisXuGff($opt{x}, "xu.");
my $uniprot_map = parseUniprotFile($opt{u});

foreach my $x (keys(%{$kegg_map})) {
    printEntry($x, $kegg_map, $lewis_map);
    printEntry($x, $kegg_map, $xu_map);
    printEntry($x, $kegg_map, $uniprot_map);
}

sub printEntry {
    my ($entry, $kegg, $dataset) = @_;
    if ($dataset->{$entry}){
        foreach my $x (@{$dataset->{$entry}}) {
            print "$x\t";
            foreach my $y (@{$kegg->{$entry}}) {
                print "$y ";
            }
            print "\n";
        }
    }
}


sub parseUniprotFile {
    my ($f) = @_;
    my $in = readFile($f);
    my $map;
    my $name;
    foreach my $x (@{$in}) {
        if ($x =~ /<entry /){
            undef($name);
        } elsif ($x =~ /<name /){
            if ($x =~ /H671_/){
                my @spl = split(/>/, $x);
                my @spl2 = split(/</, $spl[1]);
                $name = $spl2[0];
            }
        } elsif ($x =~ /type="KEGG"/){
            if ($name) {
                my @spl = split(/cge:/, $x);
                my @spl2 = split(/"/, $spl[1]);
                push(@{$map->{$spl2[0]}}, $name);
            }
        }

    }
    undef($in);
    return $map;
}

sub parseLewisXuGff {
    my ($f, $pre) = @_;
    my $in = readFile($f);
    my $map;
    foreach my $x (@{$in}) {
        if ($x !~ /^#/){
            my @spl = split(/\s+/, $x);
            if ($spl[2] eq "gene") {
                if ($x =~ /GeneID:/){
                    my @spl2 = split(/GeneID:/, $x);
                    my @spl3 = split(/;/, $spl2[1]);
                    my $geneid = $spl3[0];
                    if ($x =~ /ID=gene/){
                        @spl2 = split(/ID=/, $x);
                        @spl3 = split(/;/, $spl2[1]);
                        my $id = $spl3[0];
                        push(@{$map->{$geneid}}, "$pre$id");
                    }
                }
            }
        }
    }
    undef($in);
    return $map;
}

sub parseKeggFile {
    my ($f) = @_;
    my $in = readFile($f);
    my $genes;
    my $entry;
    my $inGene = 0;
    foreach my $x (@{$in}) {
        if ($x =~ /^ENTRY/){
            my @spl = split(/\s+/, $x);
            $entry = $spl[1];
        } elsif ($x =~ /^\/\/\//) {
            undef($entry);
        } elsif ($inGene) {
            if ($x !~ /^\s/){
                $inGene = 0;
            } else {
                $x =~ s/^\s+//;
                my @spl = split(/\s+/, $x);
                push(@{$genes->{$spl[0]}}, $entry);
            }
        } elsif ($x =~ /^GENE/) {
            $inGene = 1;
            my @spl = split(/\s+/, $x);
            push(@{$genes->{$spl[1]}}, $entry);
        }
    }
    undef($in);
    return $genes;
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
   -i    maps file
   -l    lewis gff file
   -x    xu gff file
   -u    uniprot file

   Examples:
   $0 -i maps -l lewis.gff3 -x xu.gff3 -u 10029_trembl.xml

END_TEXT

   exit( 0 );
}




