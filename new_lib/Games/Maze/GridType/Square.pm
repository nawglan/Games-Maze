package Games::Maze::GridType::Square;

# Squarish mazes.  Each row has equal number of columns

use Moo::Role;
use namespace::clean;

sub createGrid {
    my ($self, %params) = @_;
    my $rows = $params{rows} or die "Error: Expected 'rows'";
    my $cols = $params{columns} or die "Error: Expected 'columns'";
    my $levels = $params{levels} || 1;
    my $multilevel = $levels > 1 ? 1 : 0;

    my $cellClass = "Games::Maze::CellType::" . $self->celltype;

    for (my $z = 0; $z < $levels; $z++) {
        for(my $y = 0; $y < $rows; $y++) {
            for (my $x = 0; $x < $cols; $x++) {
                $self->{_cellmap}[$z][$y][$x] = $cellClass->new(row => $y, column => $x, level => $z, multilevel => $multilevel);
            }
        }
    }

    # set neighbors
    for (my $l = 0; $l < $levels; $l++) {
        for(my $r = 0; $r < $rows; $r++) {
            for (my $c = 0; $c < $cols; $c++) {
                my $cell = $self->{_cellmap}[$l][$r][$c];
                $cell->setNeighbors(grid => $self);
            }
        }
    }

    return $self;
}

sub toString {
    my ($self) = @_;

    my $levels = $self->options()->{levels} || 1;
    my $rows = $self->options()->{rows};
    my $cols = $self->options()->{columns};
    my $output = '';
    my $body = '   ';
    my $corner = '+';
    my $wall = '|';
    my $door = ' ';
    my $southwall = '---';

    for (my $z = 0; $z < $levels; $z++) {
        $output .= $corner . (($southwall . $corner) x $cols) . "\n";
        for(my $y = 0; $y < $rows; $y++) {
            my $top = $wall;
            my $bottom = $corner;
            for (my $x = 0; $x < $cols; $x++) {
                my $cell = $self->getCell(row => $y, column => $x, level => $z);
                my $east = $cell->linked($cell->east) ? $door : $wall;
                $top .= $body . $east;
                my $south = $cell->linked($cell->south) ? $body : $southwall;
                $bottom .= $south . $corner;
            }
            $output .= $top . "\n" .
                       $bottom . "\n";
        }
        $output .= "\n";
    }

    return $output;
}

sub size {
    my ($self) = @_;

    return $self->options()->{rows} * $self->options()->{columns} * ($self->options()->{levels} || 1);
}

sub levelSize {
    my ($self) = @_;

    return $self->options()->{rows} * $self->options()->{columns};
}

# retrieve a random cell in the grid, restrict to a given level if specified
sub randomCell {
    my ($self, %params) = @_;
    my $level = $params{level} || 0;

    #$level = int(rand(($self->options()->{levels} || 1))) unless defined $level;
    my $row = int(rand($self->options()->{rows}));
    my $column = int(rand($self->options()->{columns}));

    return $self->getCell(row => $row, column => $column, level => $level);
}

# iterator that goes over all cells individually
sub eachCell {
    my ($self, %params) = @_;
    my $level = $params{level} || 0;
    my ($currentState, $done);
    my $maxLevel = $self->options()->{levels} || 1;

    return sub {
        if ($currentState) {
            $currentState->{column} += 1;
            if ($currentState->{column} == $self->options()->{columns}) {
                $currentState->{column} = 0;
                $currentState->{row} += 1;
                if ($currentState->{row} == $self->options()->{rows}) {
                    $currentState->{level} += 1;
                    if ($currentState->{level} == $maxLevel) {
                        $done = 1;
                    } else {
                        $currentState->{row} = 0;
                    }
                }
            }
        } else {
            $currentState = {row => 0, column => 0, level => $level || 0};
        }
        if (!$done) {
            $currentState->{value} = $self->getCell(column => $currentState->{column}, row => $currentState->{row}, level => $currentState->{level});
        } else {
            delete $currentState->{value};
        }

        return undef if $done;
        return $currentState->{value};
    };
}

# iterator that goes over all cells by columns
sub eachColumn {
    my ($self, %params) = @_;
    my $level = $params{level} || 0;
    my ($currentState, $done);
    my $maxLevel = $self->options()->{levels} || 1;

    return sub {
        if ($currentState) {
            $currentState->{value} = [];
            $currentState->{column} += 1;
            if ($currentState->{column} == $self->options()->{columns}) {
                $currentState->{level} += 1;
                if ($currentState->{level} == $maxLevel) {
                    $done = 1;
                } else {
                    $currentState->{column} = 0;
                }
            }
        } else {
            $currentState = {column => 0, level => $level || 0, value => []};
        }
        if (!$done) {
            my $i = 0;
            while ($i < $self->options()->{columns}) {
                push @{$currentState->{value}}, $self->getCell(column => $currentState->{column}, row => $i, level => $currentState->{level});
                $i++;
            }
        }

        return undef if $done;
        return $currentState->{value};
    };
}

# iterator that goes over all cells by rows
sub eachRow {
    my ($self, %params) = @_;
    my $level = $params{level} || 0;
    my ($currentState, $done);
    my $maxLevel = $self->options()->{levels} || 1;

    return sub {
        if ($currentState) {
            $currentState->{value} = [];
            $currentState->{row} += 1;
            if ($currentState->{row} == $self->options()->{rows}) {
                $currentState->{level} += 1;
                if ($currentState->{level} == $maxLevel) {
                    $done = 1;
                } else {
                    $currentState->{row} = 0;
                }
            }
        } else {
            $currentState = {row => 0, level => $level || 0, value => []};
        }
        if (!$done) {
            my $i = 0;
            while ($i < $self->options()->{columns}) {
                push @{$currentState->{value}}, $self->getCell(column => $i, row => $currentState->{row}, level => $currentState->{level});
                $i++;
            }
        }

        return undef if $done;
        return $currentState->{value};
    };
}

1;

