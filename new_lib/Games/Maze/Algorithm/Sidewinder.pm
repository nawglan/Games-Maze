package Games::Maze::Algorithm::Sidewinder;

use List::Util qw/shuffle/;

sub generate {
    my ($class, %params) = @_;
    my $grid = $params{grid} || die "Error: Exected 'grid'";
    my $multilevel = $params{multilevel} || 0;
    my $num_stairs = $params{stairnum} || 1;

    my $iterator = $grid->eachRow();
    while (my $row = $iterator->()) {
        my @run = qw();
        foreach my $cell (@$row) {
            push @run, $cell;

            if (($cell->east ? 0 : 1) || (!($cell->north ? 0 : 1) && (rand() < 0.5))) {
                @run = shuffle @run;
                my $target = shift @run;
                $target->link($target->north) if $target->north;
                @run = qw();
            } else {
                $cell->link($cell->east);
            }
        }
    }

    return $grid;
}

1;
