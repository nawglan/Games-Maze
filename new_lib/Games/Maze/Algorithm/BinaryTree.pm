package Games::Maze::Algorithm::BinaryTree;

sub generate {
    my ($class, %params) = @_;
    my $grid = $params{grid} || die "Error: Exected 'grid'";
    my $multilevel = $params{multilevel} || 0;
    my $num_stairs = $params{stairnum} || 1;

    my $iterator = $grid->eachCell();
    while (my $cell = $iterator->()) {
        my $target;
        my $dir;
        if (rand() < 0.5) {
            $target = $cell->north if $cell->north;
            $dir = 'north';
            if (!$target) {
                $target = $cell->east if $cell->east;
                $dir = 'east';
            }
        } else {
            $target = $cell->east if $cell->east;
            $dir = 'east';
            if (!$target) {
                $target = $cell->north if $cell->north;
                $dir = 'north';
            }
        }
        if ($target) {
            $cell->link($target);
        }
    }
    return $grid;
}

1;
