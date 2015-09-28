#!/usr/bin/env perl
use strict;

use constant {
    sec_init => 0,
    sec_nodes => 1,
    sec_taxa => 2,
    sec_annotations => 3
};

my $infile = shift;
my $outfile = shift;

unless($infile && $outfile) {
    die "Usage: $0 [old treeinfo file] [new slacTree file]\n";
}

open(IN, $infile) or die "Unable to open file $infile\n";
open(OUT, ">".$outfile) or die "Unable to write to file $outfile\n";

print STDERR "$infile -> $outfile\n";

my $section = sec_init;
my $lasttaxnum = 0;
my %nodes;

while(<IN>) {
    chomp;
    if(/^\#/) {
        if(/^# plot \(tree type/) {
            print OUT "# plot (x-offset, y-offset, tree zoom, tree color)\n";
        } else {
            print OUT $_."\n";
        }

    } elsif(/^>/) {
        if(/nod/i) {
            $section = sec_nodes;
        } elsif(/tax/i) {
            $section = sec_taxa;
        } elsif(/ann/i) {
            $section = sec_annotations;
        } else {
            print STDERR "Unknown section $_ in $infile\nSections must be one of (nodes, taxa, annotations)\n";
        }
        print OUT $_."\n";
        
    } else {
        if($section == sec_nodes) {
            my ($n, $l, $b, $t, $nt, $cn) = split(/\t/);
            if(length($n) > 0) {
                if($t =~ /[tn]/ && length($cn) < 1) { #No bootstrap values given, shift values to compensate
                    $cn = $nt;
                    $nt = $t;
                    $t = $b;
                    $b = 0;
                }
                $nodes{$cn} = 1;
                
                print OUT join("\t", ($cn, $n, $l, $b))."\n";
            }
            
        } elsif($section == sec_taxa) {
            
            my ($n, $l, $t, $namestr, $taxstr) = split(/\t/);
            
            if(length($n) > 0) {
                unless(exists($nodes{$n})) {
                    print STDERR "Unknown taxon node: $n\n";
                }
                
                $lasttaxnum++;
                my $tid = 'x'.$lasttaxnum;
                
                print OUT join("\t", ($n, $t, $tid, $namestr, $taxstr))."\n";
            }
            
        } elsif($section == sec_annotations) {
            my ($anntype, @annparams) = split(/\t/);
            
            if($anntype eq 'plot') { # General plotting params
                my ($type, $x, $y, $zt, $c) = @annparams;
                
                unless($type =~ /^r/i) {
                    print STDERR "Radial trees only supported in new version, old version shows: $type\n";
                }
                
                print OUT join("\t", ('plot', $x, $y, $zt, $c))."\n";
                
            } else {
                
                print OUT $_."\n";
            }
        } else {
            
            print OUT $_."\n";
        }
    }
}
close(IN);
close(OUT);
