#!/usr/bin/env perl
use lib '../new_lib';

use Games::Maze;
use Getopt::Long;

my %options = (
    rows => 5,
    cols => 5,
    levs => 1, # don't have multi-level mazes working yet
    seed => 42,
    cellsize => 3,
    method => 'RecursiveBacktracker',
    output => 'ascii',
    utf8   => '0',
    filename => 'example_maze' # only used if output is not ascii (svg, png, etc.)
);

GetOptions(
    'rows=i' => \$options{rows},
    'cols=i' => \$options{cols},
    'seed=i' => \$options{seed},
    'method=s' => \$options{method},
    'output=s' => \$options{output},
    'filename=s' => \$options{filename},
    'cellsize=i' => \$options{cellsize},
    'utf8' => \$options{utf8},
);
#    'levs=i' => \$options{levs},

my $maze = Games::Maze->new(
    gridtype => 'Square',
    celltype => 'Square',
    options => {
        seed => $options{seed},
        rows => $options{rows},
        columns => $options{cols},
        levels => $options{levs},
        method => $options{method},
    })->initialize()->generate();

$options{output} = lc $options{output};
if ($options{output} eq 'ascii') {
    print $maze->toString(cellsize => $options{cellsize}, utf8 => $options{utf8});
} elsif ($options{output} && $options{filename}) {
    $options{cellsize} = 10 if $options{cellsize} < 10;
    if ($options{output} eq 'pdf') {
        $maze->toPDF(filename => $options{filename} . ".$options{output}", imagetype => $options{output}, cellsize => $options{cellsize});
    } else {
        $maze->toImg(filename => $options{filename} . ".$options{output}", imagetype => $options{output}, cellsize => $options{cellsize});
    }
}

