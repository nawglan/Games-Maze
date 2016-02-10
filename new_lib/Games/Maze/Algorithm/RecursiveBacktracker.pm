package Games::Maze::Algorithm::RecursiveBacktracker;

use List::Util qw/first shuffle/;
use List::MoreUtils qw/first_index/;


sub generate {
    my ($class, %params) = @_;
    my $grid = $params{grid} || die "Error: Exected 'grid'";
    my $multilevel = $params{multilevel} || 0;
    my $num_stairs = $params{stairnum} || 1;

    my @stack;
    my $start_at = $grid->randomCell();
    push @stack, $start_at;

    while (@stack) {
        my $current = $stack[$#stack];
        my @neighbors = grep {$_->links->size() == 0} $current->neighbors();
        if (@neighbors) {
            @neighbors = shuffle @neighbors;
            $current->link($neighbors[0]);
            push @stack, $neighbors[0];
        } else {
            pop @stack;
        }
    }

    return $grid;
}

1;

