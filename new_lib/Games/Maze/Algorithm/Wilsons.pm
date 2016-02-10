package Games::Maze::Algorithm::Wilsons;

use List::Util qw/first shuffle/;
use List::MoreUtils qw/first_index/;


sub generate {
    my ($class, %params) = @_;
    my $grid = $params{grid} || die "Error: Exected 'grid'";
    my $multilevel = $params{multilevel} || 0;
    my $num_stairs = $params{stairnum} || 1;

    my @unvisited = qw();

    # initialize
    my $iterator = $grid->eachCell();
    while (my $cell = $iterator->()) {
        push @unvisited, $cell;
    }

    #randomize the unvisited cells, and remove the first one
    @unvisited = shuffle @unvisited;
    shift @unvisited; # throw away the first cell

    while (@unvisited) {
        my $cell = $unvisited[0];
        my @path = ($cell);

        # while our cell is in the list of unvisited cells
        while (first {$_->id eq $cell->id} @unvisited) {
            # get a random neighbor of this cell
            my @neighbors = $cell->neighbors();
            @neighbors = shuffle @neighbors;
            $cell = $neighbors[0];

            # check to see if this cell is already in the path
            my $position = first_index {$_->id eq $cell->id} @path;
            if ($position != -1) {
                @path = splice @path, 0, ($position + 1);
            } else {
                push @path, $cell;
            }
        }

        while (scalar @path > 1) {
            my $cell = shift @path;
            $cell->link($path[0]);
            @unvisited = grep {$_->id ne $cell->id} @unvisited;
        }
    }

    return $grid;
}

1;

