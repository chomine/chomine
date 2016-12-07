#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: convertBlueTheme2chomine.pl
#
#        USAGE: ./convertBlueTheme2chomine.pl  
#
#  DESCRIPTION: converts theme.css from blue to chomine by changing color
#  values 
#
#       AUTHOR: Matthias P. Gerstl 
#===============================================================================

use strict;
use warnings;
use utf8;
use Getopt::Std;
use Image::Magick;
use POSIX;

my $opt_string = 'hm:';
my %opt;
getopts( "$opt_string", \%opt ) or usage();
if ( $opt{h} or !$opt{m} ){
    usage();
}

#--------------------------------------
# check if modulate hue value is valide
#--------------------------------------
my $modulate = $opt{m};
if (!checkModulate($modulate))
{
    die("Parameter m needs following value: 1 <= m <= 200\n");
}

#--------------
# read css file
#--------------
my $file = 'theme.css';
my $in = readFile($file);

#--------------------------------------------
# replace color values by rotating the colors
#--------------------------------------------
foreach my $x (@{$in}) {
    $x = replaceByPattern($x, 6, ';');
    $x = replaceByPattern($x, 6, ' ');
    $x = replaceByPattern($x, 3, ';');
    $x = replaceByPattern($x, 3, ' ');
    print $x;
}

#=====================================================
# rotate color in a line
# $line = line of css file
# $len = length of color (#012345; => 6 or #fff; => 3)
# $sep = character after color
#=====================================================
sub replaceByPattern {
    my ($line, $len, $sep) = @_;

    #----------------------
    # define search pattern
    #----------------------
    my $pat = '#';
    for (my $var = 0; $var < $len; $var++) 
    {
        $pat .= '.';
    }
    $pat .= $sep;

    #-----------------------------------------
    # check if line contains color information
    #-----------------------------------------
    if ($line =~ /$pat/)
    {
        #------------
        # parse color
        #------------
        my @spl = split(/#/, $line);
        foreach my $y (@spl) {
            my @spl2 = split(/$sep/, $y);
            foreach my $z (@spl2) {
                #-------------------------------------------------
                # check if value is true color not a tag like #nav
                #-------------------------------------------------
                if (length($z) == $len) {
                    if ($z =~ /^[0-9a-fA-F]+$/) {
                        #-------------------------
                        # rotate and replace color
                        #-------------------------
                        my $new = "#".convertColorValue("#$z", $modulate);
                        $new .= $sep;
                        my $old = "#$z".$sep;
                        $line =~ s/$old/$new/g;
                    }
                }
            }
        }
    }
    return $line;
}

#======================================
# check if modulate hue value is valide
# $modulate = hue value
#======================================
sub checkModulate
{
    my $modulate = shift;
    if ($modulate !~ /^[0-9]+\.{0,1}[0-9]+$/)
    {
        return 0;
    }
    elsif ($modulate < 0 or $modulate > 200)
    {
        return 0;
    }
    else
    {
        return 1;
    }
}

#==============================================================
# convert color by rotation using imageMagick modulate function
# $value = color value
# $hue = hue rotation percentage
#==============================================================
sub convertColorValue
{
    my ($value, $hue) = @_;
    my $img = Image::Magick->new;
    $img->Set(size=>'3x3');
    $img->ReadImage('canvas:white');
    $img->Set('pixel[1,1]'=>$value);
    $img->Modulate('hue'=>$hue);
    my $res = $img->Get('pixel[1,1]');
    return RGB2Hex($res);
}

#=====================================================
# converts imageMagick color value to html color value
# $val = color value
#=====================================================
sub RGB2Hex
{
    my ($val) = @_;
    my @spl = split(/,/, $val);
    my $r = 256*256*(floor($spl[0]/256));
    my $g = 256*(floor($spl[1]/256));
    my $b = floor($spl[2]/256);
    my $dec = $r + $g + $b;
    return sprintf("%.6x", $dec);
}

#====================================
# read file and load lines into array
# $file = filename
#====================================
sub readFile {
    my ($file) = @_;
    open(IN, "<$file") or die ("Could not open $file for reading: $!\n");
    my @in = <IN>;
    close(IN);
    return \@in;
}

#===========
# HELP usage
#===========
sub usage {
    print <<"END_TEXT";

Usage: $0 [OPTIONS]

Converts intermine theme blue to chomine theme by changing color values

   -h    show this help
   -m    modulate value between 0 and 200

   Example:
   $0 -m 33.3

END_TEXT

   exit( 0 );
}

