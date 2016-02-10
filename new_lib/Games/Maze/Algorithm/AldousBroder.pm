package Games::Maze::Algorithm::AldousBroder;

use List::Util qw/shuffle/;

sub generate {
    my ($class, %params) = @_;
    my $grid = $params{grid} || die "Error: Exected 'grid'";
    my $multilevel = $params{multilevel} || 0;
    my $num_stairs = $params{stairnum} || 1;

    my $cell = $grid->randomCell();
    my $unvisited = $grid->size() - 1;

    while ($unvisited) {
        my @neighbors = shuffle $cell->neighbors;
        my $target = shift @neighbors;

        if ($target->links->size() == 0) {
            $cell->link($target);
            $unvisited--;
        }
        $cell = $target;
    }

    return $grid;
}

1;
