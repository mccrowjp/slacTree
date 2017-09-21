#!/usr/bin/env perl
#
# slacTree - SVG Large Annotated Circular Tree drawing program
#
# Original version: 6/16/2009 John P. McCrow (jmccrow [at] jcvi.org)
# J. Craig Venter Institute (JCVI)
# La Jolla, CA USA
#

use strict;
use Math::Trig;
use Getopt::Long;
use JSON::PP;

### GLOBAL ###

use constant {
    sec_init => 0,
    sec_nodes => 1,
    sec_taxa => 2,
    sec_annotations => 3,
    
    node_internal => 0,
    node_taxon => 1,
    
    as_listed => 1,
    by_depth => 2,
    by_width => 3,
    
    layer_bottom => 0,
    layer_hst => 1,
    layer_tree => 2,
    layer_abund => 3,
    layer_top => 4,
    
    out_svg => 1,
    out_svg_density => 2,
    out_abund => 3
    
};

# Init
my $basepath = $0;
$basepath =~ s/\/[^\/]+$//;

my $defannfile = $basepath."/default_annotations.txt";
my $initfile = $basepath."/config.txt";
my $makejpgexe = $basepath."/make_density_jpg.r";

# Default parameters, can be changed in initfile
my %defparam = ('len_as_boot'=>0,
                'branch_order'=>2,
                'branch_reverse'=>0,
                'view_width'=>30000,
                'view_height'=>30000,
                'radial_space'=>10,
                'tree_rotation'=>0,
                'align_text'=>1,
                'tree_color'=>'#000000',
                'font_color'=>'#000000',
                'label_color'=>'#000000',
                'font_family'=>'Verdana',
                'legend_length'=>0,
                'legend_x_offset'=>0.1,
                'legend_y_offset'=>0.1,
                'tree_zoom'=>1,
                'font_zoom'=>2,
                'title_font_zoom'=>4,
                'label_font_zoom'=>1,
                'lab_offset_mult'=>1,
                'x_offset'=>0,
                'y_offset'=>0,
                'abund_max_size'=>10,
                'lega_txt_offset'=>0.025,
                'tvchart_same'=>0,
                'tvchart_scale'=>1,
                'tvchart_grid'=>0,
                'tvchart_color1'=>'#0000FF',
                'tvchart_color2'=>'#00FF00',
                'tvchart_pos2'=>1,
                'tvchart_min_len'=>0.005
);

# Command line parameters
my $infile;
my $outfile;
my $taxfile;
my $densityfilebase;
my $zlim;
my $forceoverwrite;
my $showhelp;
my $useSTDIN;
my $jplacebesthit;

my $nodeabundfile;
my $densityjpgfile;

# Tree
my %taxtext;
my %taxassign;
my %taxlen;
my %taxname;
my %nodename;
my %namenode;
my %nodelen;
my %nodeboot;
my %nodelongestlen;
my %nodesubtaxa;
my %nodeparent;
my %nctype;
my %nodechildren;
my $haslengths = 0; #Are lengths given
my $hasboot = 0;    #Are bootstrap values given
my $lastnodeid = 0;
my $lenasboot = $defparam{'len_as_boot'};
my $newick_branch_order = $defparam{'branch_order'};
my $newick_branch_reverse = $defparam{'branch_reverse'};

# Drawing
my $layer;
my %svglayerstr;
my $xmult;
my $ymult;
my $tmult;
my $toffx;
my $maxtextlen;
my $maxtaxval1;
my $maxtaxval2;
my $maxnodeabund;
my $numtax;
my $rcx;
my $rcy;
my $maxfont;
my $minfont;
my $maxx;
my $linewidth;
my $fgcolor;
my $fontsize;
my $taxfontsize;
my $labfontsize;
my $titlefontsize;
my $titletext;
my $hastaxval1;
my $hastaxval2;
my %taxvalgridlines1;
my %taxvalgridlines2;
my %labeltaxclr;
my %labeltaxstr;
my %taxslot;
my %slottax;
my %taxcolor;
my %taxgroup;
my @leghstrs;
my @lega_abund;
my @lega_color;
my @lega_x;
my @lega_y;
my @lega_str;
my %leghfg;
my %leghbg;
my %nodeabund;
my %nodeabundclr;
my %taxval1;
my %taxval2;
my %ttfgclr;
my %ttnodeclr;
my %ttbgclr;
my $boottxtcut;
my $boottxtdec;
my $boottxtsize;
my $boottxtclr;
my $bootlinecut;
my $bootlinelw;
my $bootlineclr;
my $inodetxtsize;
my $inodetxtclr;

# Drawing Defaults
my $output_type = out_svg;
my $rootnode = 1;

my $viewwidth = $defparam{'view_width'};
my $viewheight = $defparam{'view_height'};
my $radialspace = $defparam{'radial_space'};
my $treerotation = $defparam{'tree_rotation'};
my $aligntext = $defparam{'align_text'};
my $treecolor = $defparam{'tree_color'};
my $fontcolor = $defparam{'font_color'};
my $labelcolor = $defparam{'label_color'};
my $fontfam = $defparam{'font_family'};
my $legsize = $defparam{'legend_length'};
my $treezoom = $defparam{'tree_zoom'};
my $fontzoom = $defparam{'font_zoom'};
my $labelfontmult = $defparam{'label_font_zoom'};
my $xoffset = $defparam{'x_offset'};
my $yoffset = $defparam{'y_offset'};
my $labeloffsetmult = $defparam{'lab_offset_mult'};
my $legxoffset = $defparam{'legend_x_offset'};
my $legyoffset = $defparam{'legend_y_offset'};
my $legatextoffset = $defparam{'lega_txt_offset'};
my $abundmaxradius = $defparam{'abund_max_size'};
my $titlefontmult = $defparam{'title_font_zoom'};
my $tvchartsame = $defparam{'tvchart_same'};
my $tvchartscale = $defparam{'tvchart_scale'};
my $tvdefaultgrid = $defparam{'tvchart_grid'};
my $tvchartcolor1 = $defparam{'tvchart_color1'};
my $tvchartcolor2 = $defparam{'tvchart_color2'};
my $tvchart2pos = $defparam{'tvchart_pos2'};
my $mintvlen = $defparam{'tvchart_min_len'};


### SUBS ###

sub init_config {
    if(open(INIT, $initfile)) {
        while(<INIT>) {
            chomp;
            unless(/^\#/) {
                my ($key, $val) = split(/[\t\s]+/);
                if(length($key) > 0 && length($val) > 0) {
                    $defparam{$key} = $val;
                }
            }
        }
    } # ignore config file if not found
}

sub open_handles {
    if($useSTDIN) {
        open(IN, "<&=STDIN") or die "Unable to read from STDIN\n";
    } else {
        open(IN, $infile) or die "Unable to open file $infile\n";
    }
    
    if(length($outfile) > 0) {
        if(!$forceoverwrite && -e $outfile) {
            die "Output file already exists: $outfile\n(Remove file, or use -f option to force overwrite)\n";
        }
        open(OUT, ">".$outfile) or die "Unable to write to file $outfile\n";
        
    } else {
        open(OUT, ">&=STDOUT") or die "Unable to write to STDOUT\n";
    }
    
}

sub add_tree_node {
    my ($n, $p, $l, $b) = @_;
    my $pid;
    my $nid;
    
    # create parent if necessary
    if(exists($namenode{$p})) {
        $pid = $namenode{$p};
        
    } else {
        $lastnodeid++;
        $pid = $lastnodeid;
        $nodename{$pid} = $p;
        $namenode{$p} = $pid;
    }
    
    # create node if necessary
    if(exists($namenode{$n})) {
        $nid = $namenode{$n};
    } else {
        $lastnodeid++;
        $nid = $lastnodeid;
        $nodename{$nid} = $n;
        $namenode{$n} = $nid;
    }

    $nodeparent{$nid} = $pid;
    $nodelen{$nid} = $l;
    $nodeboot{$nid} = $b;
    $nctype{$nid} = node_internal;
    push(@{$nodechildren{$pid}}, $nid);
    
    return $nid;
}

sub add_tree_taxon_node {
    my ($n, $p, $l, $t) = @_;
    
    my $node = add_tree_node($n, $p, $l, 0);

    if(defined($node) && length($t) > 0) {
        $taxname{$node} = $t;
    }
    $nctype{$node} = node_taxon;
    $taxlen{$node} = $nodelen{$node};
    
    return $node;
}

sub findtaxnode {
    my ($n, $t) = @_;
    my $nc;
    my $bestnc;
    my $nccount=0;
    
    $t =~ s/\s*;\s*/;/g;
    $t =~ tr/A-Z/a-z/;
    
    for(my $i=0; $i<scalar(@{$nodechildren{$n}}); $i++) {
        
        if($nctype{(@{$nodechildren{$n}}[$i])} == node_internal) {
            $nc = findtaxnode(@{$nodechildren{$n}}[$i], $t);
            
        } elsif($nctype{(@{$nodechildren{$n}}[$i])} == node_taxon) {
            my $c = $taxassign{@{$nodechildren{$n}}[$i]};
            $c =~ s/\s*;\s*/;/g;
            $c =~ tr/A-Z/a-z/;
            if(substr($c, 0, length($t)) eq $t) {
                $nc = $n;
            } else {
                $nc = -1;
            }
        }
        
        if($nc >= 0) {
            $nccount++;
            $bestnc = $nc;
        }
    }
    
    if($nccount > 1) { # If more than 1 child, then this node or an ancestor is the best inclusive node
        return $n;
    } elsif($nccount == 1) { # If only 1 child, then the child is the best inclusive node
        return $bestnc;
    }
    
    return -1;
}

sub calc_tree_data {
    %nodesubtaxa = ();
    
    foreach my $nid (keys %taxlen) {
        $nodelongestlen{$nid} = $taxlen{$nid};
        $nodesubtaxa{$nid} = 1;
        my $n = $nodeparent{$nid};
        my $d = $taxlen{$nid};
        my %nodestouched = ();
        while(exists($nodelen{$n})) {
            if($nodestouched{$n}) {
                last;  # prevents possibility of cycles and nonterminating loop
            }
            $nodestouched{$n} = 1;
            
            # count subtaxa
            $nodesubtaxa{$n}++;
            
            # count longest total length (depth)
            $d += $nodelen{$n};
            if(!exists($nodelongestlen{$n}) || $d > $nodelongestlen{$n}) {
                $nodelongestlen{$n} = $d;
            }
            
            $n = $nodeparent{$n};
        }
    }
    
    foreach my $nid (keys %nodeparent) {
        # detect lengths, and bootstrap values
        if($nodelen{$nid} > 0) {
            $haslengths = 1;
        }
        if($nodeboot{$nid} > 0) {
            $hasboot = 1;
        }
    }
    
    # set rootnode
    $rootnode = (keys %nodeparent)[0];
    my %nodestouched = ();
    while(defined($nodeparent{$rootnode}) && !$nodestouched{$rootnode}) {
        $nodestouched{$rootnode} = 1;
        $rootnode = $nodeparent{$rootnode};
    }
    $nodesubtaxa{$rootnode} = scalar(keys %taxlen);
}

sub colorsubtree {
    my ($n, $c) = @_;
    
    for(my $i=0; $i<scalar(@{$nodechildren{$n}}); $i++) {
        if($nctype{(@{$nodechildren{$n}}[$i])} == node_internal) {
            colorsubtree(@{$nodechildren{$n}}[$i], $c);
            
        } else {
            $taxcolor{@{$nodechildren{$n}}[$i]} = $c;
        }
    }
}

sub colorsubtreeminus {
    my ($n, $notn, $c) = @_;
    
    for(my $i=0; $i<scalar(@{$nodechildren{$n}}); $i++) {
        unless(@{$nodechildren{$n}}[$i] == $notn) { # color all except node notn
            if($nctype{(@{$nodechildren{$n}}[$i])} == node_internal) {
                colorsubtree(@{$nodechildren{$n}}[$i], $c);
                
            } else {
                $taxcolor{@{$nodechildren{$n}}[$i]} = $c;
            }
        }
    }
}

sub readNewick_scanerror {
    my ($c, $e, $i) = @_;
    print STDERR "Unexpected character $c in Newick string, expected $e at position $i\n";
    return 0;
}

sub readNewick_parseerror {
    my ($s, $i) = @_;
    print STDERR "$s at position $i\n";
    return 0;
}

sub parse_newick {
    my $treestr = shift;
    
    my @Elist;
    my @Ilist;
    my $maxid=0;
    
    my $EOparen = 1;
    my $Ename = 2;
    my $Ecolon = 3;
    my $Enum = 4;
    my $Eid = 5;
    my $Ecomma = 6;
    my $ECparen = 7;
    
    my $SOparen = 0;
    my $Sname = 1;
    my $Scolon = 2;
    my $STnum = 3;
    my $Sid = 4;
    my $Sidclosed = 5;
    my $Scomma = 6;
    my $SCparen = 7;
    my $SPnum = 8;
    my $Send = 9;
    
    if(length($taxfile) > 0) {
        open(TAX, $taxfile) or die "Unable to open file $taxfile\n";
        
        while(<TAX>) {
            chomp;
            my ($id, $name, $assign) = split(/\t/);
            $taxtext{$id} = $name;
            $taxassign{$id} = $assign;
        }
        close(TAX);
    }
    
    $treestr =~ s/[\s\t\r\n]//g;
    
    # Scan
    my $curstate = $SOparen;
    my $etext = "";
    for(my $i=0; $i<length($treestr); $i++) {
        my $ci = substr($treestr, $i, 1);
        if($curstate == $SOparen) {
            if($ci eq "(") {
                push(@Elist, $EOparen);
                push(@Ilist, "");
            } elsif($ci =~ /[\d\w_]/) {
                $curstate = $Sname;
                $etext = $ci;
            } else {
                return readNewick_scanerror($ci, "( or name", $i);
            }
        } elsif($curstate == $Sname) {
            if($ci eq ")" || $ci eq ":" || $ci eq ",") {
                push(@Elist, $Ename);
                push(@Ilist, $etext);
                if($ci eq ")") {
                    $curstate = $SCparen;
                }
                if($ci eq ":") {
                    $curstate = $Scolon;
                }
                if($ci eq ",") {
                    $curstate = $Scomma;
                }
            } elsif($ci =~ /[^:,;\(\)\{\}]/) {
                $etext .= $ci;
            } else {
                return readNewick_scanerror($ci, ": or , or name", $i);
            }
        } elsif($curstate == $Scolon) {
            push(@Elist, $Ecolon);
            push(@Ilist, "");
            if($ci =~ /[\.\d\-e]/) {
                $curstate = $STnum;
                $etext = $ci;
            } else {
                return readNewick_scanerror($ci, "number", $i);
            }
        } elsif($curstate == $STnum) {
            if($ci eq ")" || $ci eq "{" || $ci eq "," || $ci eq ";") {
                push(@Elist, $Enum);
                push(@Ilist, $etext);
                if($ci eq ")") {
                    $curstate = $SCparen;
                }
                if($ci eq "{") {
                    $curstate = $Sid;
                    $etext = "";
                }
                if($ci eq ",") {
                    $curstate = $Scomma;
                }
                if($ci eq ";") {
                    $curstate = $Send;
                }
            } elsif($ci =~ /[\.\d\-e]/) {
                $etext .= $ci;
            } else {
                return readNewick_scanerror($ci, "{ or , or ; or number", $i);
            }
        } elsif($curstate == $Sid) {
            if($ci eq "}" || $ci eq ":" || $ci eq "," || $ci eq ")" || $ci eq ";") {
                push(@Elist, $Eid);
                push(@Ilist, $etext);
                if($etext > $maxid) { $maxid = $etext; }
                
                $curstate = $ci eq "}" ? $Sidclosed : $ci eq ":" ? $Scolon : $ci eq "," ? $Scomma : $ci eq ")" ? $SCparen : $ci eq ";" ? $Send : -1;
                
            } elsif($ci =~ /\d/) {
                $etext .= $ci;
            } else {
                return readNewick_scanerror($ci, "} or number", $i);
            }
        } elsif($curstate == $Sidclosed) {
            if($ci eq ",") {
                $curstate = $Scomma;
            } elsif($ci eq ")") {
                $curstate = $SCparen;
            } elsif($ci eq ";") {
                $curstate = $Send;
            } else {
                return readNewick_scanerror($ci, ", or ) or ;", $i);
            }
        } elsif($curstate == $Scomma) {
            push(@Elist, $Ecomma);
            push(@Ilist, "");
            if($ci eq "(") {
                push(@Elist, $EOparen);
                push(@Ilist, "");
                $curstate = $SOparen;
            } elsif($ci  =~ /[\d\w_]/) {
                $curstate = $Sname;
                $etext = $ci;
            } else {
                return readNewick_scanerror($ci, "( or name", $i);
            }
        } elsif($curstate == $SCparen) {
            push(@Elist, $ECparen);
            push(@Ilist, "");
            if($ci eq ")") {
            } elsif($ci eq "{" || $ci eq "I") {
                $curstate = $Sid;
                $etext = "";
            } elsif($ci eq ",") {
                $curstate = $Scomma;
            } elsif($ci eq ":") {
                $curstate = $Scolon;
            } elsif($ci eq ";") {
                $curstate = $Send;
            } elsif($ci  =~ /[\.\d\-e]/) {
                $curstate = $SPnum;
                $etext = $ci;
            } else {
                return readNewick_scanerror($ci, ") or { or I or , or : or ; or number", $i);
            }
        } elsif($curstate == $SPnum) {
            if($ci eq ":" || $ci eq "{" || $ci eq ",") {
                push(@Elist, $Enum);
                push(@Ilist, $etext);
                if($ci eq ":") {
                    $curstate = $Scolon;
                }
                if($ci eq "{") {
                    $curstate = $Sid;
                }
                if($ci eq ",") {
                    $curstate = $Scomma;
                }
            } elsif($ci =~ /[\.\d\-e]/) {
                $etext .= $ci;
            } else {
                return readNewick_scanerror($ci, ": or { or , or number", $i);
            }
        } elsif($curstate == $Send) {
            #end state
        } else {
            print STDERR "Unknown scan state: $curstate\n";
            return 0;
        }
    }
    
    # Parse
    my @Ebeginstack;
    my @Eendstack;
    my @parentnodestack;
    
    push(@Ebeginstack, 0);
    push(@Eendstack, scalar(@Elist)-1);
    push(@parentnodestack, -1);
    
    while(scalar(@Ebeginstack) > 0) {
        my $nodeid;
        my $Ebegin = pop(@Ebeginstack);
        my $Eend = pop(@Eendstack);
        my $parentnode = pop(@parentnodestack);
        
        for(my $i=$Ebegin; $i<=$Eend; $i++) {
            my $ei = $Elist[$i];
            my $ii = $Ilist[$i];
            
            if($ei == $EOparen) {
                my $parencount=1;
                my $j=$i+1;
                while($parencount>0 && $j<=$Eend) {
                    my $ej = $Elist[$j];
                    if($ej == $EOparen) {
                        $parencount++;
                    } elsif($ej == $ECparen) {
                        $parencount--;
                    }
                    if($parencount>0) {
                        $j++;
                    }
                }
                if($j > $i+1 && $j <= $Eend && $parencount == 0) {
                    my $k=$j+1;
                    my $l=$j+1;
                    my $len;
                    my $boot;
                    my $idname;
                    if($k+2 <= $Eend && $Elist[$k] == $Enum && $Elist[$k+1] == $Ecolon && $Elist[$k+2] == $Enum) {
                        $boot = $Ilist[$k];
                        $len = $Ilist[$k+2];
                        $l=$k+3;
                    } elsif($k+2 <= $Eend && $Elist[$k] == $Eid && $Elist[$k+1] == $Ecolon && $Elist[$k+2] == $Enum) {
                        $idname = $Ilist[$k];
                        $len = $Ilist[$k+2];
                        $l=$k+3;
                    } elsif($k+1 <= $Eend && $Elist[$k] == $Ecolon && $Elist[$k+1] == $Enum) {
                        $len = $Ilist[$k+1];
                        $l=$k+2;
                    } elsif($k <= $Eend && $Elist[$k] == $Enum) {
                        if($lenasboot) {
                            $boot = $Ilist[$k];
                        } else {
                            $len = $Ilist[$k];
                        }
                        $l=$k+1;
                    }
                    if($Elist[$l] == $Eid) {
                        $idname = $Ilist[$l];
                        $l++;
                    }
                    
                    if(length($idname) > 0) {
                        $nodeid = $idname;
                    } else {
                        $maxid++;
                        $nodeid = $maxid;
                    }
                    
                    add_tree_node($nodeid, $parentnode, 0.0+$len, 0.0+$boot);
                    
                    push(@Ebeginstack, $i+1);
                    push(@Eendstack, $j-1);
                    push(@parentnodestack, $nodeid);
                    
                    $i = $l-1;
                } else {
                    return readNewick_parseerror("No matching closing parenth for open parenth", $i);
                }
            } elsif($ei == $Ename) {
                my $tname = $Ilist[$i];
                my $len;
                my $idname;
                my $j=$i+1;
                my $k=$i+1;
                
                if($i+2 <= $Eend && $Elist[$i+1] == $Ecolon && $Elist[$i+2] == $Enum) {
                    $len = $Ilist[$i+2];
                    $i=$i+2;
                }
                if($i+1 <= $Eend && $Elist[$i+1] == $Eid) {
                    $idname = $Ilist[$i+1];
                    $i=$i+1;
                }
                
                if(length($idname) > 0) {
                    $nodeid = $idname;
                } else {
                    $maxid++;
                    $nodeid = $maxid;
                }
                
                add_tree_taxon_node($nodeid, $parentnode, 0.0+$len, $tname);
                
            } elsif($ei == $Ecomma) {
                #continue to next element
            } else {
                return readNewick_parseerror("Error parsing element $ei", $i);
            }
            
        } #for
    } #while
    
    calc_tree_data();
    
    return 1;
}

sub read_newick {
    my $treestr = "";
    
    while(<IN>) {
        chomp;
        $treestr .= $_;
    }
    
    parse_newick($treestr);
}

sub write_newick {
    my ($showlen, $showintid) = @_;
    
    my @cmdstack;
    my @nodestack;
    my $str;
    
    if(length($taxfile) > 0) {
        open(TAX, ">".$taxfile) or die "Unable to write to file $taxfile\n";
    }
    
    if(defined($rootnode)) {
        push(@nodestack,  $rootnode);
        push(@cmdstack, "x");
        
        while(scalar(@cmdstack) > 0) {
            my $cmd = pop(@cmdstack);
            
            if($cmd eq "(" || $cmd =~ /^\)/ || $cmd eq ",") {
                $str .= $cmd;
                
            } elsif($cmd eq "x") {
                my $n = pop(@nodestack);
                
                #Terminal nodes
                if(!exists($nodechildren{$n})) {

                    my $cstr = length($taxname{$n}) > 0 ? $taxname{$n} : length($nodename{$n}) > 0 ? $nodename{$n} : $n;
                    
                    if(length($taxfile) > 0) {
                        print TAX join("\t", ($cstr, $taxtext{$cstr}, $taxassign{$cstr}))."\n";
                    }
                    
                    $str .= $cstr;
                    
                    if($showlen) {
                        $str .= ":".(0.0+$nodelen{$n});
                    }
                    if($showintid) {
                        $str .= "{".$n."}";
                    }
                    
                } elsif(scalar(@{$nodechildren{$n}}) == 1) {
                    push(@nodestack, @{$nodechildren{$n}}[0]);
                    push(@cmdstack, "x");
                    
                } elsif(scalar(@{$nodechildren{$n}}) > 0) {
                    
                    #Internal nodes
                    my $intstr = ")";
                    if($showlen && $nodelen{$n} > 0.0) {
                        $intstr .= ":".(0.0+$nodelen{$n});
                    }
                    if($showintid && $n >= 0) {
                        $intstr .= "{".$n."}";
                    }
                    push(@cmdstack, $intstr);
                    
                    my $isfirst = 1;
                    foreach my $c (reverse @{$nodechildren{$n}}) {
                        push(@cmdstack, ",") unless $isfirst;
                        push(@nodestack, $c);
                        push(@cmdstack, "x");
                        $isfirst = 0;
                    }
                    push(@cmdstack, "(");
                }	
            }
        }

    }
    
    print OUT $str.";\n";
}

sub write_node_abundances {
    my ($n, $x, $y, $z) = @_;
    my $ax;
    my $ay;
    
    $ax = radialx($x*$xmult+$toffx, $y);
    $ay = radialy($x*$xmult+$toffx, $y);
    
    print ABUND join("\t", ($n, $ax, $ay, $z))."\n";
}

sub write_slactree {
    # branch order is by_depth
    my ($n0, $n1, $n2, @rest) = sort {$nodelongestlen{$b}<=>$nodelongestlen{$a} || $nodesubtaxa{$b}<=>$nodesubtaxa{$a} || $a<=>$b} keys %nodelen;
    my @sortednodelist = ($n0, $n2, $n1, @rest);  # swap first 2 child nodes
    
    if($newick_branch_order == as_listed) { # branch order is as_listed
        @sortednodelist = sort {$a<=>$b} keys %nodelen;
    
    } elsif($newick_branch_order == by_width) { # branch order is by_width
        @sortednodelist = sort {$nodesubtaxa{$b}<=>$nodesubtaxa{$a} || $a<=>$b} keys %nodelen;
    }
    
    if($newick_branch_reverse) {
        @sortednodelist = reverse @sortednodelist;
    }
    
    print OUT ">nodes\n";
    foreach my $node (@sortednodelist) {
        my $len = $haslengths ? sprintf("%.8f", $nodelen{$node}) : 1;
        my $boot = $hasboot ? sprintf("%.8f", $nodeboot{$node}) : 0;
        
        print OUT join("\t", ($nodename{$node}, $nodename{$nodeparent{$node}}, $len, $boot))."\n";
    }
    
    print OUT ">taxa\n";
    foreach my $tax (sort {$a<=>$b} keys %taxlen) {
        if(!defined($taxtext{$taxname{$tax}})) {
            $taxtext{$taxname{$tax}} = $taxname{$tax};
        }
        
        print OUT join("\t", ($nodename{$tax}, "r", $taxname{$tax}, $taxtext{$taxname{$tax}}, $taxassign{$taxname{$tax}}))."\n";
    }
    
    print OUT ">annotations\n";
    
    if(open(DA, $defannfile)) {
        while(<DA>) {
            print OUT;
        }
    }
}

sub read_slactree {
    my $section = sec_init;
    my $resetroot = 0;
    
    while(<IN>) {
        chomp;
        unless(/^\#/) {
            if(/^>/) {
                if(/nod/i) {
                    $section = sec_nodes;
                } elsif(/tax/i) {
                    $section = sec_taxa;
                } elsif(/ann/i) {
                    $section = sec_annotations;
                } else {
                    die "Unknown section $_ in $infile\nSections must be one of (nodes, taxa, annotations)\n";
                }
                
            } else {
                if($section == sec_init) {
                    my ($key, $val) = split(/[\t\s]+/);
                    if(length($key) > 0 && length($val) > 0) {
                        $defparam{$key} = $val;
                    }
                    
                } elsif($section == sec_nodes) {
                    my ($n, $p, $l, $b) = split(/[\t\s]+/);
                    if(length($n) > 0) {
                        add_tree_node($n, $p, $l, $b);
                    }
                    
                } elsif($section == sec_taxa) {
                    my ($n, $g, $name, $fullname, $taxstr) = split(/\t/);
                    if(length($n) > 0) {
                        unless(exists($namenode{$n})) {
                            die "Unknown taxon node: $n\n";
                        }
                        my $nid = $namenode{$n};
                        $nctype{$nid} = node_taxon;
                        $taxlen{$nid} = $nodelen{$nid};
                        $taxgroup{$nid} = $g;
                        $taxname{$nid} = $name;
                        $taxtext{$name} = $fullname;
                        $taxassign{$name} = $taxstr;
                    }
                    
                } elsif($section == sec_annotations) {
                    my ($anntype, @annparams) = split(/\t/);
                    
                    if($anntype eq 'plot') { # General plotting params
                        my ($x, $y, $zt, $c) = @annparams;
                        if(length($x)>0) {
                            $xoffset = 0+$x;
                        }
                        if(length($y)>0) {
                            $yoffset = 0+$y;
                        }
                        if(length($zt)>0) {
                            $treezoom = 0+$zt;
                        }
                        if(length($c)>0) {
                            $treecolor = $c;
                        }
                        
                    } elsif($anntype eq 'rad') { # Radial tree rotation and space
                        my ($a, $r) = @annparams;
                        if(length($a)>0 && $a>=0 && $a<360) {
                            $radialspace = $a;
                        }
                        if(length($r)>0 && $r>=0 && $r<360) {
                            $treerotation = $r;
                        }
                        
                    } elsif($anntype eq 'font') { # Font params
                        my ($zf, $f, $c) = @annparams;
                        if(length($zf)>0) {
                            $fontzoom = 0+$zf;
                        }
                        if(length($f)>0) {
                            $fontfam = $f;
                        }
                        if(length($c)>0) {
                            $fontcolor = $c;
                        }
                        
                    } elsif($anntype eq 'labs') { # Label params
                        my ($x1, $x2, $c) = @annparams;
                        if(length($x1)>0) {
                            $labeloffsetmult = $x1;
                        }
                        if(length($x2)>0) {
                            $labelfontmult = $x2;
                        }
                        if(length($c)>0) {
                            $labelcolor = $c;
                        }
                        
                    } elsif($anntype eq 'leg') { # Legend for branch length
                        my ($str, $x, $y) = @annparams;
                        if(length($str)>0) {
                            $legsize = $str;
                            if(length($x)>0) {
                                $legxoffset = $x;
                            }
                            if(length($y)>0) {
                                $legyoffset = $y;
                            }	  
                        }
                        
                    } elsif($anntype eq 'legh') { # Legend for highlights
                        my ($str, $c1, $c2) = @annparams;
                        push(@leghstrs, $str);
                        $leghfg{$str} = $c1;
                        $leghbg{$str} = $c2;
                        
                    } elsif($anntype eq 'lega') { # Legend for abundances
                        my ($a, $c, $x, $y, $str) = @annparams;
                        push(@lega_abund, $a);
                        push(@lega_color, $c);
                        push(@lega_x, $x);
                        push(@lega_y, $y);
                        push(@lega_str, $str);
                        
                    } elsif($anntype eq 'boottxt') { # Bootstrap values
                        my ($bc, $td, $ts, $tc) = @annparams;
                        if(length($bc)>0) {
                            $boottxtcut = $bc;
                        }
                        if(length($td)>0) {
                            $boottxtdec = $td;
                        }
                        if(length($ts)>0) {
                            $boottxtsize = $ts;
                        }
                        if(length($tc)>0) {
                            $boottxtclr = $tc;
                        }
                        
                    } elsif($anntype eq 'bootline') { # Bootstrap lines
                        my ($bc, $lw, $lc) = @annparams;
                        if(length($bc)>0) {
                            $bootlinecut = $bc;
                        }
                        if(length($lw)>0) {
                            $bootlinelw = $lw;
                        }
                        if(length($lc)>0) {
                            $bootlineclr = $lc;
                        }
                        
                    } elsif($anntype eq 'inodes') { # Internal node labels
                        my ($ts, $tc) = @annparams;
                        if(length($ts)>0) {
                            $inodetxtsize = $ts;
                        }
                        if(length($tc)>0) {
                            $inodetxtclr = $tc;
                        }
                        
                    } elsif($anntype eq 'absize') { # Max Abundance Size
                        my ($x) = @annparams;
                        if(length($x)>0) {
                            $abundmaxradius = $x;
                        }
                        
                    } elsif($anntype eq 'htax') { # Highlight Taxonomy
                        my ($str, $c) = @annparams;
                        $str =~ s/\s*;\s*/;/g;
                        drawtaxhighlight($rootnode, $str, $c);
                        
                    } elsif($anntype eq 'hst') { # Highlight SubTree
                        my ($n, $c, $m) = @annparams;
                        if($m eq "-") {
                            colorsubtreeminus($rootnode, $n, $c);
                        } else {
                            colorsubtree($n, $c);
                        }
                        
                    } elsif($anntype eq 'label') { # Label centered on taxon
                        my ($n, $str, $c) = @annparams;
                        $labeltaxstr{$n} = $str;
                        if(length($c)>0) {
                            $labeltaxclr{$n} = $c;
                        }
                        
                    } elsif($anntype eq 'abund') { # Abundance values on nodes
                        my ($n, $a, $c) = @annparams;
                        my $nid = $namenode{$n};
                        if(defined($nid)) {
                            push(@{$nodeabund{$nid}}, $a);
                            push(@{$nodeabundclr{$nid}}, $c);
                            if($a > $maxnodeabund) {
                                $maxnodeabund = $a;
                            }
                        }
                        
                    } elsif($anntype eq 'taxval') { # Taxon values to plot as bar
                        my ($n, $v1, $v2) = @annparams;
                        if(length($v1)>0) {
                            $hastaxval1 = 1;
                            if(exists($namenode{$n})) {
                                $taxval1{$namenode{$n}} = $v1;
                            } else {
                                $taxval1{$n} = $v1;
                            }
                            if($v1 > $maxtaxval1) {
                                $maxtaxval1 = $v1;
                            }
                        }
                        if(length($v2)>0) {
                            $hastaxval2 = 1;
                            if(exists($namenode{$n})) {
                                $taxval2{$namenode{$n}} = $v2;
                            } else {
                                $taxval2{$n} = $v2;
                            }
                            if ($v2 > $maxtaxval2) {
                                $maxtaxval2 = $v2;
                            }
                        }
                        
                    } elsif($anntype eq 'tvchart') { # Taxon value bar plot params
                        my ($s, $g, $c1, $c2, $p, $same) = @annparams;
                        if($s > 0) {
                            $tvchartscale = $s;
                        }
                        if($g) {
                            $tvdefaultgrid = 1;
                        }
                        if(length($c1) > 0) {
                            $tvchartcolor1 = $c1;
                        }
                        if(length($c2) > 0) {
                            $tvchartcolor2 = $c2;
                        }
                        if($p =~ /side/ || $p == 2) {
                            $tvchart2pos = 2;
                        }
                        if($same =~ /^y/i || $same == 1) {
                            $tvchartsame = 1;
                        } else {
                            $tvchartsame = 0;
                        }
                        
                    } elsif($anntype eq 'tvgrid') { # Taxon value bar plot grid
                        my ($v, $c) = @annparams;
                        if($c == 2) {
                            $taxvalgridlines2{$v}=1;
                        } else {
                            $taxvalgridlines1{$v}=1;
                        }
                        
                    } elsif($anntype eq 'ttclr') { # Taxon type color, fg and bg colors for taxa of given type
                        my ($tt, $c1, $c2, $c3) = @annparams;
                        $ttfgclr{$tt} = $c1;
                        $ttnodeclr{$tt} = $c2;
                        $ttbgclr{$tt} = $c3;
                        
                    } elsif($anntype eq 'rootn') { # Display tree only below given node
                        my ($n) = @annparams;
                        $rootnode = $namenode{$n};
                        $resetroot = 1;
                        
                    } elsif($anntype eq 'roott') { # Display tree only below given node
                        my ($a) = @annparams;
                        my $nid = findtaxnode(0, $a);
                        if($nid >= 0) {
                            $rootnode = $nid;
                            $resetroot = 1;
                        }
                        
                    } elsif($anntype eq 'titl') { # Title of plot
                        my ($str, $n) = @annparams;
                        $titletext = $str;
                        if ($n > 0) {
                            $titlefontmult = $n;
                        }
                    }
                    
                    
                }
                
            }
        }
    } # while

    my $newroot = $rootnode;

    calc_tree_data();

    if($resetroot) {
        $rootnode = $newroot;
    }
}

sub read_jplace_write_slactree {
    my $jstr;
    my $edgefield = 0;
    my %abund;
    my %idcolor;
    my %abundcolor;
    
    if(length($taxfile) > 0) {
        open(TAX, $taxfile) or die "Unable to open file $taxfile\n";
        
        while(<TAX>) {
            chomp;
            my ($id, $color) = split(/\t/);
            $idcolor{$id} = $color;
        }
        close(TAX);
    }
    
    while(<IN>) {
        chomp;
        $jstr .= $_;
    }

    my $href = decode_json($jstr);
    
    if(exists(${$href}{'version'})) {
        if(${$href}{'version'} < 3) {
            print STDERR "WARNING: jplace format version ".${$href}{'version'}." deprecated, should be 3 or higher.\n";
        }
    }
    
    if(exists(${$href}{'tree'})) {
        parse_newick(${$href}{'tree'});
        
    } else {
        die "No tree found in jplace file\n";
    }
    
    my $i=0;
    foreach my $f (@{${$href}{'fields'}}) {
        if($f eq 'edge_num') {
            $edgefield = $i;
        }
        $i++;
    }
    
    foreach my $pref (@{${$href}{'placements'}}) {
        my @edgelist = ();
        my @masslist = ();
        my $placecolor = '#FF0000';
        
        my $ppref = ${$pref}{'p'};
        foreach my $plist (@{$ppref}) {
            push(@edgelist, @{$plist}[$edgefield]);
        }
        
        my $edgemass = 1;
        if(exists(${$pref}{'m'})) {
            $edgemass = ${$pref}{'m'};
        }
        
        if(exists(${$pref}{'n'})) {
            my $npref = ${$pref}{'n'};
            foreach my $nlist (@{$npref}) {
                push(@masslist, $edgemass);
            }
        }
        
        if(exists(${$pref}{'nm'})) {
            my $nmpref = ${$pref}{'nm'};
            foreach my $nmlist (@{$nmpref}) {
                push(@masslist, @{$nmlist}[1]);
                if(exists($idcolor{@{$nmlist}[0]})) {
                    $placecolor = $idcolor{@{$nmlist}[0]};
                }
            }
        }
        
        my $beste = @edgelist[0];
        my $bestm = 0;
        foreach my $e (@edgelist) {
            $abundcolor{$e} = $placecolor;
            foreach my $m (@masslist) {
                if($jplacebesthit) {
                    if($m > $bestm) {
                        $bestm = $m;
                        $beste = $e;
                    } 
                } else {
                    $abund{$e} += ($m / scalar(@edgelist));
                }
            }
        }
        if($jplacebesthit) {
            $abund{$beste} += 1;
        }
    }
    
    write_slactree();
    
    if(scalar(keys %abund) > 0) {
        print OUT "\n";

        foreach my $node (sort keys %abund) {
            print OUT join("\t", ('abund', $node, $abund{$node}, $abundcolor{$node}))."\n";
        }
    }
    
}

# Calculate maximum x-value for drawing scale
sub getmaxx {
    my ($n, $px) = @_;
    my $x = $px + $nodelen{$n};
    my $m;
    my $maxx = $x;
    
    if(exists($nodechildren{$n})) {
        for(my $i=0; $i<scalar(@{$nodechildren{$n}}); $i++) {
            if($nctype{(@{$nodechildren{$n}}[$i])} == node_internal) {
                if(defined(@{$nodechildren{$n}}[$i])) {
                    $m = getmaxx(@{$nodechildren{$n}}[$i], $x);
                } else {
                    die "Undefined child ".($i+1)." under node $n\n";
                }
            } else {
                $m = ($x + $taxlen{@{$nodechildren{$n}}[$i]});
            }
            if($m > $maxx) {
                $maxx = $m;
            }
        }
    }
    
    return $maxx;
}

sub findcommonassignment($$) {
    my ($liststr1, $liststr2) = @_;
    
    my @list1 = split(/;/, $liststr1);
    my @list2 = split(/;/, $liststr2);
    my @commonlist = ();
    
    for(my $i=0; $i<scalar(@list1) && $i<scalar(@list2); $i++) {
        if($list1[$i] eq $list2[$i]) {
            push(@commonlist, $list1[$i]);
        } else {
            last;
        }
    }
    
    return join(";", @commonlist);
}

#Calculate drawing scale parameters
sub calc_scale_params() {
    $numtax = $nodesubtaxa{$rootnode};
    
    $maxtextlen = 0;
    foreach my $tid (keys %taxname) {
        if(length($taxtext{$taxname{$tid}}) > $maxtextlen) {
            $maxtextlen = length($taxtext{$taxname{$tid}});
        }
    }
    $maxfont = $viewheight/100;
    $minfont = $viewheight/1000;
    $maxx = getmaxx($rootnode, 0);
    $linewidth=int($viewwidth/3000);
    $taxfontsize = $fontzoom*(($viewheight/$numtax)<$minfont?$minfont:(($viewheight/$numtax)>$maxfont?$maxfont:$viewheight/$numtax));
    $xmult = ($treezoom*$viewwidth*0.95)/($maxx*3);
    $ymult = (360-$radialspace) / $numtax;
    $rcx = ($viewwidth*$xoffset) + ($viewwidth/2);
    $rcy = ($viewwidth*$yoffset) + ($viewwidth/2);
    $labfontsize = $labelfontmult*$taxfontsize;
    $titlefontsize = $titlefontmult*$taxfontsize;
    $fontsize = $taxfontsize;
    $toffx = $viewwidth/1500;
    $tmult = $fontsize*0.6;
    
    $layer = layer_tree;
    $fgcolor = $treecolor;
    
    if($tvchartsame) {
        $maxtaxval1 = ($maxtaxval2 > $maxtaxval1 ? $maxtaxval2 : $maxtaxval1);
        $maxtaxval2 = $maxtaxval1;
    }
}

# Naming convention for drawing subs is the following:
#    radial- convert between absolute and radial coordinates
#    print-  direct printing of absolute space objects in SVG
#    d-      lower level drawing of individual objects in tree space with conversion to absolute printing space
#    draw-   high level tree walking, or other calculations, before calling d- subs

sub radialx {
    my $x = shift;
    my $y = shift;
    
    return ($rcx + sin(deg2rad($y*$ymult+$treerotation))*$x);
}

sub radialy {
    my $x = shift;
    my $y = shift;
    
    return ($rcy + cos(deg2rad($y*$ymult+$treerotation))*$x);
}

sub radialangle {
    my $y = shift;
    
    return (90-($y*$ymult+$treerotation));
}

sub printline {
    my ($x1, $y1, $x2, $y2) = @_;
    
    $svglayerstr{$layer} .= "\t<path fill=\"none\" stroke=\"$fgcolor\" stroke-width=\"$linewidth\" d=\"M $x1 $y1 L $x2 $y2\"/>\n";
}

sub printarc {
    my ($x1, $y1, $x2, $y2, $r, $inout) = @_;
    
    $svglayerstr{$layer} .= "\t<path fill=\"none\" stroke=\"$fgcolor\" stroke-width=\"$linewidth\" d=\"M $x1 $y1 A $r $r 0 $inout 0 $x2 $y2\"/>\n";
}

sub printbox {
    my ($x1, $y1, $x2, $y2) = @_;
    
    $svglayerstr{$layer} .= "\t<path fill=\"$fgcolor\" stroke=\"none\" stroke-width=\"0\" d=\"M $x1 $y1 L $x1 $y2 L $x2 $y2 L $x2 $y1 Z\"/>\n";
}

sub printtext {
    my ($x, $y, $str, $alignx, $aligny) = @_;
    my $alignxstr;
    my $alignystr;
    
    if($alignx eq "center") {
        $alignxstr = "text-anchor=\"middle\"";
    } else {
        $alignxstr = "";
    }
    
    if($aligny eq "bottom") {
        $alignystr = "";
    } else {
        $alignystr = "dominant-baseline=\"central\"";
    }
    
    $svglayerstr{$layer} .= "<text x=\"$x\" y=\"$y\" font-size=\"$fontsize\" font-family=\"$fontfam\" fill=\"$fgcolor\" $alignxstr $alignystr >".$str."</text>\n";
}

sub printtextrot {
    my ($x, $y, $a, $str) = @_;
    
    $svglayerstr{$layer} .= "<g transform=\"translate($x,$y)\">\n";
    $svglayerstr{$layer} .= "<g transform=\"rotate($a)\">\n";
    $svglayerstr{$layer} .= "<text x=\"0\" y=\"0\" font-size=\"$fontsize\" font-family=\"$fontfam\" fill=\"$fgcolor\" dominant-baseline=\"central\">";
    $svglayerstr{$layer} .= $str;
    $svglayerstr{$layer} .= "</text>\n</g>\n</g>\n";
}

sub printcircle {
    my ($x, $y, $r, $w) = @_;
    
    $svglayerstr{$layer} .= "<circle cx=\"$x\" cy=\"$y\" r=\"$r\" stroke=\"$fgcolor\" fill=\"none\" stroke-width=\"$w\"/>\n";
}

sub printfillcircle {
    my ($x, $y, $r) = @_;
    
    $svglayerstr{$layer} .= "<circle cx=\"$x\" cy=\"$y\" r=\"$r\" stroke=\"$fgcolor\" fill=\"$fgcolor\" stroke-width=\"1\"/>\n";
}

sub printimage {
    my $imagefile = shift;
    
    $svglayerstr{$layer} .= "<image x=\"0\" y=\"0\" width=\"".$viewwidth."\" height=\"".$viewheight."\" xlink:href=\"".$imagefile."\" />\n";
}

sub printheader {
    print OUT <<HEAD;
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg width="100%" height="100%" viewBox="0 -1000 $viewwidth $viewheight" preserveAspectRatio="xMinYMin meet" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
HEAD
}

sub printfooter {
    print OUT "</svg>\n";
}

sub dvline {
    my ($x, $y1, $y2) = @_;
    
    my $ax1 = radialx($x*$xmult, $y1);
    my $ay1 = radialy($x*$xmult, $y1);
    my $ax2 = radialx($x*$xmult, $y2);
    my $ay2 = radialy($x*$xmult, $y2);
    
    printarc($ax1,$ay1,$ax2,$ay2,$x*$xmult, ((($y2-$y1)*$ymult<180)?0:1) );
}

sub dhline {
    my ($y, $x1, $x2) = @_;
    
    my $ax1 = radialx($x1*$xmult, $y);
    my $ay1 = radialy($x1*$xmult, $y);
    my $ax2 = radialx($x2*$xmult, $y);
    my $ay2 = radialy($x2*$xmult, $y);

    printline($ax1,$ay1,$ax2,$ay2);
}

sub dhtext {
    my ($x, $y, $str) = @_;
    
    $fontsize = $taxfontsize;
    my $ax = radialx($x*$xmult+$toffx+$linewidth*4, $y);
    my $ay = radialy($x*$xmult+$toffx+$linewidth*4, $y);
    
    printtextrot($ax, $ay, radialangle($y), $str);
}

sub dhinttxt {
    my ($x, $y, $str) = @_;

    my $ax = radialx($x*$xmult+$toffx, $y);
    my $ay = radialy($x*$xmult+$toffx, $y);

    printtextrot($ax, $ay, radialangle($y), $str);
}

sub dcirc {
    my ($x, $y, $w) = @_;
    
    my $ax = radialx($x*$xmult+$toffx, $y);
    my $ay = radialy($x*$xmult+$toffx, $y);
    
    printfillcircle($ax, $ay, $w);
}

sub dtitle {
    $fontsize = $titlefontsize;
    
    my $ax = $viewwidth/2;
    my $ay = 0;
    
    printtext($ax, $ay, $titletext, "center", "bottom");
}

sub dlegend {
    my $maxlegtext;
    my $fc = $fgcolor;
    my $lw = $linewidth;
    my $fs = $fontsize;
    
    $fontsize = $labfontsize * 2;
    
    my $ax = $viewwidth*$legxoffset;
    my $ay = $viewheight*$legyoffset;
    
    foreach my $str (@leghstrs) {
        if(length($str) > $maxlegtext) {
            $maxlegtext = length($str);
        }
    }
    my $legmult = 1000;
    
    #Draw any highlighting or text color legend items
    $linewidth = $ymult*$legmult;
    
    my $i=1;
    foreach my $str (@leghstrs) {
        if(length($leghbg{$str}) > 0) {
            $fgcolor = $leghbg{$str};
            printline($ax, $ay+($i*$ymult*$legmult), $ax+($maxlegtext*$tmult*4), $ay+($i*$ymult*$legmult));
        }
        
        if(length($leghfg{$str}) > 0) {
            $fgcolor = $leghfg{$str};
        } else {
            $fgcolor = $fontcolor;
        }
        printtext($ax, $ay+($i*$ymult*$legmult), $str, "left", "center");
        $i++;
    }
    $linewidth = $lw;
    
    #Draw branch length legend
    if($legsize > 0) {
        $i++;
        $fgcolor = $treecolor;
        printline($ax+($maxlegtext*$tmult)/2, $ay+($i*$ymult), $ax+($maxlegtext*$tmult)/2+($legsize*$xmult), $ay+($i*$ymult));
        $fgcolor = $fontcolor;
        printtext($ax+($maxlegtext*$tmult)/2+($legsize*$xmult)/2, $ay+($i*$ymult)-$tmult, $legsize, "center", "bottom");
    }
    
    # Draw abundance legend
    if($output_type == out_svg) {
        for(my $i=0; $i<scalar(@lega_abund); $i++) {
            my $x = $lega_x[$i]*$viewwidth;
            my $y = $lega_y[$i]*$viewheight;
            my $r = sqrt($lega_abund[$i])*$viewwidth*$abundmaxradius*0.001;
            my $str = $lega_str[$i];
            
            $fgcolor = $lega_color[$i];
            printfillcircle($x, $y, $r);
            
            $fgcolor = $fontcolor;
            printtext($x + ($viewwidth*$legatextoffset), $y, $str, "left", "center");
        }
    }
    
    $fgcolor = $fc;
    $fontsize = $fs;
}

sub dband {
    my ($y1, $y2, $color) = @_;
    my $fc = $fgcolor;
    my $lw = $linewidth;
    
    #Offset to cover text
    $y1 = $y1-0.5;
    $y2 = $y2+0.5;
    
    $fgcolor = $color;
    $linewidth = $maxtextlen*$tmult;
    
    my $ax1 = radialx($maxx*$xmult+($linewidth/2), $y1);
    my $ay1 = radialy($maxx*$xmult+($linewidth/2), $y1);
    my $ax2 = radialx($maxx*$xmult+($linewidth/2), $y2);
    my $ay2 = radialy($maxx*$xmult+($linewidth/2), $y2);
    
    printarc($ax1,$ay1,$ax2,$ay2,($maxx*$xmult+($linewidth/2)), ((($y2-$y1)*$ymult<180)?0:1) );
    
    $fgcolor = $fc;
    $linewidth = $lw;
}

sub dbar {
    my ($y, $v, $color) = @_;
    my $fc = $fgcolor;
    my $lw = $linewidth;
    my $av = $v/$maxtaxval1;
    $fgcolor = $color;
    
    if($av > 0 && $av < $mintvlen) {
        $av = $mintvlen;
    }
    
    my $ax1 = radialx($maxx*$xmult+$maxtextlen*$tmult+$toffx, $y);
    my $ay1 = radialy($maxx*$xmult+$maxtextlen*$tmult+$toffx, $y);
    my $ax2 = radialx($maxx*$xmult+(($maxtextlen*$tmult)*(1+$av))+$toffx, $y);
    my $ay2 = radialy($maxx*$xmult+(($maxtextlen*$tmult)*(1+$av))+$toffx, $y);
    
    $linewidth = $lw*8;
    printline($ax1,$ay1,$ax2,$ay2);
    
    $fgcolor = $fc;
    $linewidth = $lw;
}

sub dbar2_nextto {
    my ($y, $v1, $v2, $color1, $color2) = @_;
    my $fc = $fgcolor;
    my $lw = $linewidth;
    my $innerringx = ($maxx*$xmult)+($maxtextlen*$tmult)+$toffx;
    my $outerringx = ($maxx*$xmult)+($maxtextlen*$tmult*(1+$tvchartscale))+$toffx;
    my $av1 = $v1/$maxtaxval1;
    my $av2 = $v2/$maxtaxval2;
    
    if($av1 > 0 && $av1 < $mintvlen) {
        $av1 = $mintvlen;
    }
    if($av2 > 0 && $av2 < $mintvlen) {
        $av2 = $mintvlen;
    }
    
    $linewidth = $lw * 3;
    
    my $inneroffset = 0.2;
    my $ax11 = radialx($maxx*$xmult+$maxtextlen*$tmult+$toffx, ($y-$inneroffset));
    my $ay11 = radialy($maxx*$xmult+$maxtextlen*$tmult+$toffx, ($y-$inneroffset));
    my $ax12 = radialx($maxx*$xmult+(($maxtextlen*$tmult)*(1+($tvchartscale*$av1)))+$toffx, ($y-$inneroffset));
    my $ay12 = radialy($maxx*$xmult+(($maxtextlen*$tmult)*(1+($tvchartscale*$av1)))+$toffx, ($y-$inneroffset));
    my $ax21 = radialx($maxx*$xmult+$maxtextlen*$tmult+$toffx, ($y+$inneroffset));
    my $ay21 = radialy($maxx*$xmult+$maxtextlen*$tmult+$toffx, ($y+$inneroffset));
    my $ax22 = radialx($maxx*$xmult+(($maxtextlen*$tmult)*(1+($tvchartscale*$av2)))+$toffx, ($y+$inneroffset));
    my $ay22 = radialy($maxx*$xmult+(($maxtextlen*$tmult)*(1+($tvchartscale*$av2)))+$toffx, ($y+$inneroffset));
    
    $fgcolor = $color1;
    printline($ax11,$ay11,$ax12,$ay12);
    
    $fgcolor = $color2;
    printline($ax21,$ay21,$ax22,$ay22);
    
    $fgcolor = $fc;
    $linewidth = $lw;
}

sub dbar2_ontop {
    my ($y, $v1, $v2, $color1, $color2) = @_;
    my $fc = $fgcolor;
    my $lw = $linewidth;
    my $innerringx = ($maxx*$xmult)+($maxtextlen*$tmult)+$toffx;
    my $outerringx = ($maxx*$xmult)+($maxtextlen*$tmult*(1+$tvchartscale))+$toffx;
    my $av1 = $v1/$maxtaxval1;
    my $av2 = $v2/$maxtaxval2;
    
    if($av1 > 0 && $av1 < $mintvlen) {
        $av1 = $mintvlen;
    }
    if($av2 > 0 && $av2 < $mintvlen) {
        $av2 = $mintvlen;
    }
    
    my $ax11 = radialx($innerringx, $y);
    my $ay11 = radialy($innerringx, $y);
    my $ax12 = radialx($innerringx + ($maxtextlen*$tmult*$av1*$tvchartscale), $y);
    my $ay12 = radialy($innerringx + ($maxtextlen*$tmult*$av1*$tvchartscale), $y);
    my $ax21 = radialx($outerringx, $y);
    my $ay21 = radialy($outerringx, $y);
    my $ax22 = radialx($outerringx + ($maxtextlen*$tmult*$av2*$tvchartscale), $y);
    my $ay22 = radialy($outerringx + ($maxtextlen*$tmult*$av2*$tvchartscale), $y);
    $linewidth = $lw*8;
    
    $fgcolor = $color1;
    printline($ax11,$ay11,$ax12,$ay12);
    
    $fgcolor = $color2;
    printline($ax21,$ay21,$ax22,$ay22);
    
    $fgcolor = $fc;
    $linewidth = $lw;
}

sub dgridline {
    my ($v, $chartnum) = @_;
    my $fc = $fgcolor;
    my $r;
    
    if($chartnum == 2) {
        $r = ($maxx*$xmult)+($maxtextlen*$tmult*(1+($tvchartscale*(1+($v/$maxtaxval2)))))+$toffx;
    } else {
        $r = ($maxx*$xmult)+($maxtextlen*$tmult*(1+($tvchartscale*$v/$maxtaxval1)))+$toffx;
    }
    my $ay1 = $rcy;  
    my $ay2 = $rcy+$numtax*$ymult;
    
    $fgcolor = "#CCCCCC";
    
    dvline($r/$xmult, 0, $numtax);
    
    $fgcolor = $fc;
}

sub dlabel {
    my ($y, $str, $clr) = @_;
    my $fc = $fgcolor;
    
    $fontsize = $labfontsize;
    
    if(length($clr)>0) {
        $fgcolor = $clr;
    }
    
    my $ax = radialx($maxx*$xmult+$maxtextlen*$tmult*1.3*$labeloffsetmult, $y);
    my $ay = radialy($maxx*$xmult+$maxtextlen*$tmult*1.3*$labeloffsetmult, $y);

    #Print label with the middle aligned closely to the given taxon
    printtext($ax + ((0.90 * sin(deg2rad($y*$ymult))-1) * (length($str)*$tmult*$labelfontmult)/2), $ay, $str);
    
    $fgcolor = $fc;
    
}

sub drawhighlightbands() {
    my $lastclr;
    my $min;
    my $max;
    
    #Draw color bands for successive same colored taxa
    for(my $i=0; $i<$numtax; $i++) {
        if(length($lastclr) > 0) {
            if($lastclr eq $taxcolor{$slottax{$i}}) {
                $max = $i;
            } else {
                if($max >= $min && length($lastclr) > 0) {
                    dband($min, $max, $lastclr);
                }
                $min = $i;
                $max = $i;
            }
        } else {
            $min = $i;
            $max = $i;
        }
        $lastclr = "".$taxcolor{$slottax{$i}};
    }
    #Draw last band if necessary
    if($max >= $min && length($lastclr) > 0) {
        dband($min, $max, $lastclr);
    }
    
}

sub drawtaxhighlight {
    my ($n, $taxstr, $color) = @_;
    my @ccomp;
    my $ncomp;
    my $c;
    
    $taxstr =~ tr/A-Z/a-z/;
    
    if(exists($nodechildren{$n})) {
        for(my $i=0; $i<scalar(@{$nodechildren{$n}}); $i++) {
            if($nctype{(@{$nodechildren{$n}}[$i])} == node_internal) {
                push(@ccomp, drawtaxhighlight(@{$nodechildren{$n}}[$i], $taxstr, $color));
                
            } else {
                $c = $taxassign{$taxname{@{$nodechildren{$n}}[$i]}};
                $c =~ s/\s*;\s*/;/g;
                $c =~ tr/A-Z/a-z/;
                push(@ccomp, $c);
            }
            
            if($i==0) {
                $ncomp = $ccomp[0];
                
            } else {
                $ncomp = findcommonassignment($ncomp, $ccomp[$i]);
            }
        }
        
        #Color child node only when current node does not fit taxstr, but child does
        if(length($taxstr) > length($ncomp) || !(substr($ncomp, 0, length($taxstr)) eq $taxstr)) {
            for(my $i=0; $i<scalar(@{$nodechildren{$n}}); $i++) {
                if(substr($ccomp[$i], 0, length($taxstr)) eq $taxstr) {
                    if($nctype{(@{$nodechildren{$n}}[$i])} == node_internal) {
                        colorsubtree(@{$nodechildren{$n}}[$i], $color);
                    } else {
                        $taxcolor{@{$nodechildren{$n}}[$i]} = $color;
                    }
                }
            }
        }
    }
    
    return $ncomp;
}

sub drawtax {
    my ($t, $px, $y) = @_;
    my $fc = $fgcolor;
    
    my $x = ($px+$taxlen{$t});
    $taxslot{$t} = $y;
    $slottax{$y} = $t;
    
    $fgcolor = $treecolor;
    dhline($y, $px, $x); # Line from parent to terminal
    
    if($aligntext) { # Gray line out to text
        $fgcolor = "#CCCCCC";
        dhline($y, $x, $maxx);
    }
    
    if($ttnodeclr{$taxgroup{$t}}) {
        $fgcolor = $ttnodeclr{$taxgroup{$t}};
    } else {
        $fgcolor = $treecolor;
    }
    dcirc($x, $y, $linewidth*2); # Terminal node
    
    if($ttbgclr{$taxgroup{$t}}) { # Font and Background by taxon type
        $taxcolor{$t} = $ttbgclr{$taxgroup{$t}};
    }
    if($ttfgclr{$taxgroup{$t}}) {
        $fgcolor = $ttfgclr{$taxgroup{$t}};
    } else {
        $fgcolor = $fontcolor;
    }
    
    if($aligntext) { # Taxon name
        dhtext($maxx, $y, $taxtext{$taxname{$t}});
    } else {
        dhtext($x, $y, $taxtext{$taxname{$t}});
    }
    
    if($hastaxval1) {
        if($hastaxval2) {
            if($taxval1{$t}>0 || $taxval2{$t}>0) {
                if($tvchart2pos == 2) {
                    dbar2_nextto($y, $taxval1{$t}, $taxval2{$t}, $tvchartcolor1, $tvchartcolor2);
                } else {
                    dbar2_ontop($y, $taxval1{$t}, $taxval2{$t}, $tvchartcolor1, $tvchartcolor2);
                }
            }
        } else {
            if($taxval1{$t}>0) {
                dbar($y, $taxval1{$t}, $tvchartcolor1);
            }
        }
    }
    
    drawabund($x, $y, $t);
    
    $fgcolor = $fc;
    
    return $y;
}

sub drawabund {
    my ($x, $y, $n) = @_;

    if(exists($nodeabund{$n})) {
        #draws multiple abund values at the same node, in decreasing size order
        my @si = sort {@{$nodeabund{$n}}[$b] <=> @{$nodeabund{$n}}[$a]} (0 .. (scalar(@{$nodeabund{$n}})-1));
        foreach my $i (@si) {
            my $val = @{$nodeabund{$n}}[$i];
            my $clr = @{$nodeabundclr{$n}}[$i];
            my $ly = $layer;
            my $fc = $fgcolor;
            $layer = layer_abund;
            $fgcolor = $clr;
            
            if($output_type == out_svg) {
                dcirc($x, $y, sqrt($val)*$viewwidth*$abundmaxradius*0.001);   # relative to abund = 1
                
            } elsif($output_type == out_abund) {
                write_node_abundances($nodename{$n}, $x, $y, $val);
            }
            
            $fgcolor = $fc;
            $layer = $ly;
        }
    }
}

sub drawdensityimage {
    my $lw = $viewwidth/2;
    my $ax = radialx($toffx, 0);
    my $ay = radialy($toffx, 0);
    my $fc = $fgcolor;
    
    printimage($densityjpgfile);
    
    # mask outer area
    $fgcolor = "#FFFFFF";
    printcircle($ax, $ay, ($maxx*$xmult+($lw/2)), $lw);
    $fgcolor = $fc;
}

sub drawsubtree {
    my ($n, $px, $ymin) = @_;
    my $y;
    my $yfirst;
    my $ylast;
    my $m;
    my $fc;
    my $ly;
    my $x = ($px+$nodelen{$n});
    
    if(exists($nodechildren{$n})) {
        for(my $i=0; $i<scalar(@{$nodechildren{$n}}); $i++) {
            if($nctype{(@{$nodechildren{$n}}[$i])} == node_internal) {
                $y = drawsubtree(@{$nodechildren{$n}}[$i], $x, $ymin);
                $ymin += $nodesubtaxa{@{$nodechildren{$n}}[$i]};
            } else {
                $y = drawtax(@{$nodechildren{$n}}[$i], $x, $ymin);
                $ymin++;
            }
            
            if($i==0) {
                $yfirst = $y;
                $ylast = $y;
            } else {
                $ylast = $y;
            }
            
        }
    }
    
    $m = ($yfirst+$ylast)/2;
    
    dvline($x, $yfirst, $ylast);
    
    my $lw = $linewidth;
    my $fg = $fgcolor;
    my $fs = $fontsize;
    
    if(defined($bootlinecut) && $nodeboot{$n} >= $bootlinecut) {
        if(defined($bootlinelw)) {
            $linewidth = $lw*$bootlinelw;
        }
        if(defined($bootlineclr)) {
            $fgcolor = $bootlineclr;
        }
    }
    dhline($m, $px, $x);
    
    if(defined($boottxtcut) && $nodeboot{$n} >= $boottxtcut) {
        if(defined($boottxtsize)) {
            $fontsize = $taxfontsize*$boottxtsize;
        }
        if(defined($boottxtclr)) {
            $fgcolor = $boottxtclr;
        }
        my $bootstr = sprintf("%.2f",$nodeboot{$n});
        if(defined($boottxtdec) && $boottxtdec>=0 && $boottxtdec=~/^\d+$/) {
            $bootstr = sprintf("%.".$boottxtdec."f", $nodeboot{$n});
        }
        dhinttxt($px, $m+0.6, $bootstr);
    }
    
    if(defined($inodetxtsize)) {
        $fontsize = $taxfontsize*$inodetxtsize;
    }
    if(defined($inodetxtclr)) {
        $fgcolor = $inodetxtclr;
    }
    if(defined($inodetxtclr) || defined($inodetxtsize)) {
        dhinttxt($px, $m+0.6, $n);
    }
    
    $linewidth = $lw;
    $fgcolor = $fg;
    $fontsize = $fs;
    
    drawabund($x, $m, $n);
    
    return $m;
}

sub output_svg_tree {
    calc_scale_params();
    
    # draw main tree structure
    $layer = layer_tree;
    drawsubtree($rootnode, 0, 0);
    
    dlegend();
    dtitle();
    
    foreach my $t (keys %labeltaxstr) {
        if(length($labeltaxclr{$t}) > 0) {
            dlabel($taxslot{$t}, $labeltaxstr{$t}, $labeltaxclr{$t});
        } else {
            dlabel($taxslot{$t}, $labeltaxstr{$t}, $labelcolor);
        }
    }
    
    #Add hightlighted subtrees to layer
    $layer = layer_hst;
    
    if($output_type == out_svg_density) {
        drawdensityimage();
    }
    
    drawhighlightbands();
    
    if($maxtaxval1 > 0) {
        if($tvdefaultgrid) {
            #Draw default grid lines at the base of each taxval ring that has data
            dgridline(0,1);
            if($maxtaxval2 > 0) {
                dgridline(0,2);
            }
        }
        foreach my $v (keys %taxvalgridlines1) {
            dgridline($v,1);
        }
        foreach my $v (keys %taxvalgridlines2) {
            dgridline($v,2);
        }
    }
    
    #Print SVG in ordered layers
    if($output_type == out_svg || $output_type == out_svg_density) {
        printheader();
        foreach my $layer (sort {$a<=>$b} keys %svglayerstr) {
            print OUT $svglayerstr{$layer};
        }
        printfooter();
    }
}

sub setdensityfilenames {
    if(length($densityfilebase) > 0) {
        $nodeabundfile = $densityfilebase.".density.abund";
        $densityjpgfile = $densityfilebase.".density.jpg";
        
    } elsif(length($outfile) > 0) {
        $nodeabundfile = $outfile.".density.abund";
        $densityjpgfile = $outfile.".density.jpg";
        
    } elsif(length($infile) > 0 && !$useSTDIN) {
        $nodeabundfile = $infile.".density.abund";
        $densityjpgfile = $infile.".density.jpg";
    }
    
    unless(length($nodeabundfile) > 0 && length($densityjpgfile) > 0) {
        die "Must specify input/output file or option -d for density/abundance file base\n";
    }
}

sub output_node_abundances {
    unless(scalar(keys %nodeabund) > 0) {
        die "No abundance (abund) values found\n";
    }
    
    open(ABUND, ">".$nodeabundfile) or die "Unable to write to file: $nodeabundfile\n";
    
    print ABUND join("\t", ('node_id', 'x', 'y', 'abund'))."\n";
    
    $output_type = out_abund;
    output_svg_tree();
    
    close(ABUND);
}

# clear all drawing from all layers
sub clearall {
    %svglayerstr = ();
}

sub create_density_overlay {
    system(join(" ", ($makejpgexe, $nodeabundfile, $densityjpgfile, $viewwidth, $viewheight, $zlim, "&>/dev/null")));
}

sub output_zlim {
    if(open(GZ, "$makejpgexe $nodeabundfile zlim $viewwidth $viewheight 2>/dev/null |")) {
        while(<GZ>) {
            chomp;
            if(/^\[1\]\s+([^\s]+)$/) {
                $zlim = $1;
            }
        }
    }
    print OUT $zlim."\n";
}


### MAIN ###

GetOptions ("i=s" => \$infile,
            "o=s" => \$outfile,
            "t=s" => \$taxfile,
            "d=s" => \$densityfilebase,
            "z=f" => \$zlim,
            "f"   => \$forceoverwrite,
            "h"   => \$showhelp,
            "jpbest" => \$jplacebesthit);

my $command = shift;

if($infile eq '-') {
    $useSTDIN = 1;
}

my $help = <<HELP;
SVG Large Annotated Circular Tree drawing program (slacTree) v0.5
Created by John P. McCrow (6/16/2009)

Usage: slacTree.pl [command] (options)

  commands:
    newick2st     newick file -> basic slactree
    jplace2st     jplace file -> slactree with abundances
    st2newick     slactree file -> newick
    tree          slactree file -> SVG
    density       slactree file -> density plot overlay SVG
    zlim          calculate scaling factor (for multiple plots)

  options:
    -d            output density/abundance base file
    -f            force overwrite of output file (default: no overwrite)
    -h            show help
    -i file       input file (use '-' for STDIN)
    -o file       output file (default: STDOUT)
    -t file       taxonomic data file (optional)
    -z num        scaling factor (for multiple plots)
    --jpbest      jplace abundance best hit only
                  (default: all placements weighted by mass)

HELP

if($showhelp ||
   length($command) == 0 ||
   !($command =~ /^(newick2st|jplace2st|st2newick|tree|density|zlim)/i) ||
   !($useSTDIN || length($infile)>0)) {
       
       die $help;
}

init_config();

open_handles();

if($command =~ /^newick2st/i) {
    read_newick();
    write_slactree();
    
} elsif($command =~ /^jplace2st/i) {
    read_jplace_write_slactree();
    
} elsif($command =~ /^st2newick/i) {
    read_slactree();
    write_newick(1, 0);
    
} elsif($command =~ /^tree/i) {
    read_slactree();
    
    $output_type = out_svg;
    output_svg_tree();
    
} elsif($command =~ /^density/i) {
    setdensityfilenames();
    read_slactree();
    output_node_abundances();
    create_density_overlay();
    clearall();
    
    $output_type = out_svg_density;
    output_svg_tree();
    
} elsif($command =~ /^zlim/i) {
    setdensityfilenames();
    read_slactree();
    output_node_abundances();
    output_zlim();
}
