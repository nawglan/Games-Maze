#!/usr/bin/env perl
use lib '../new_lib';

use Games::Maze;
use Getopt::Long;

my %options = (
    rows => 5,
    cols => 5,
    levs => 1, # don't have multi-level mazes working yet
    seed => 42,
    method => 'RecursiveBacktracker',
);

GetOptions(
    'rows=i' => \$options{rows},
    'cols=i' => \$options{cols},
#    'levs=i' => \$options{levs},
    'seed=i' => \$options{seed},
    'method=s' => \$options{method},
);


print Games::Maze->new(
    gridtype => 'Square',
    celltype => 'Square',
    options => {
        seed => $options{seed},
        rows => $options{rows},
        columns => $options{cols},
        levels => $options{levs},
        method => $options{method},
    })->initialize()->generate()->toString();

