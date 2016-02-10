package Games::Maze::Algorithm::HuntAndKill;

use List::Util qw/first shuffle/;
use List::MoreUtils qw/first_index/;


sub generate {
    my ($class, %params) = @_;
    my $grid = $params{grid} || die "Error: Exected 'grid'";
    my $multilevel = $params{multilevel} || 0;
    my $num_stairs = $params{stairnum} || 1;

    my $current = $grid->randomCell();

    while ($current) {
        my @unvisited_neighbors = grep {$_->links->size() == 0} $current->neighbors();
        if (@unvisited_neighbors) {
            @unvisited_neighbors = shuffle @unvisited_neighbors;
            $current->link($unvisited_neighbors[0]);
            $current = $unvisited_neighbors[0];
        } else {
            undef $current;
            my $iterator = $grid->eachCell();
            while (my $cell = $iterator->()) {
                my @visited_neighbors = grep {$_->links->size()} $cell->neighbors();
                if (($cell->links->size() == 0) && @visited_neighbors) {
                    $current = $cell;
                    @visited_neighbors = shuffle @visited_neighbors;
                    $current->link($visited_neighbors[0]);
                    break;
                }
            }
        }
    }

    return $grid;
}

1;

