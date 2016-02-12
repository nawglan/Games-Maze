package Games::Maze::CellType::Square;

use open      qw(:std :utf8);    # undeclared streams in UTF-8
use Moo;
use MooX::late;
use namespace::clean;
extends "Games::Maze::Cell";

# directions for potential openings
has north => (
    is => 'rw',
    isa => 'Maybe[Games::Maze::Cell]',
);

has south => (
    is => 'rw',
    isa => 'Maybe[Games::Maze::Cell]',
);

has east => (
    is => 'rw',
    isa => 'Maybe[Games::Maze::Cell]',
);

has west => (
    is => 'rw',
    isa => 'Maybe[Games::Maze::Cell]',
);

# returns a list of cells that neighbor this cell
# with or without openings between this cell and the
# neighbor
sub neighbors {
    my ($self) = @_;
    my @list;
    push @list, $self->north if $self->north;
    push @list, $self->east if $self->east;
    push @list, $self->south if $self->south;
    push @list, $self->west if $self->west;

    if ($self->multilevel) {
      push @list, $self->up if $self->up;
      push @list, $self->down if $self->down;
    }

    wantarray ? @list : \@list; 
}

sub setNeighbors {
    my ($self, %params) = @_;
    my $grid = $params{grid} || die("Error: Parameter 'grid' is expected.");
    my $cell;

    # handle up / down
    if ($self->multilevel) {
        my $maxLevel = ($grid->options()->{levels} || 1) - 1;
        if ($self->level > 0) {
          $cell = $grid->getCell(row => $self->row, column => $self->column, level => ($self->level - 1));
          $self->down($cell) if $cell;
        }
        if ($self->level < $maxLevel) {
          $cell = $grid->getCell(row => $self->row, column => $self->column, level => ($self->level + 1));
          $self->up($cell) if $cell;
        }
    }

    # north
    if ($self->row > 0) {
          $cell = $grid->getCell(row => ($self->row - 1), column => $self->column, level => $self->level);
          $self->north($cell) if $cell;
    }
    # east
    if ($self->column < ($grid->options()->{columns} - 1)) {
          $cell = $grid->getCell(row => $self->row, column => ($self->column + 1), level => $self->level);
          $self->east($cell) if $cell;
    }
    # south
    if ($self->row < ($grid->options()->{rows} - 1)) {
          $cell = $grid->getCell(row => ($self->row + 1), column => $self->column, level => $self->level);
          $self->south($cell) if $cell;
    }
    # west
    if ($self->column > 0) {
          $cell = $grid->getCell(row => $self->row, column => ($self->column - 1), level => $self->level);
          $self->west($cell) if $cell;
    }
}

sub toString {
    my ($self, %params) = @_;
    my $cellSize = $params{cellsize} || 3;
    $cellSize = 3 if $cellSize < 3;
    my $charset = $params{utf8} ? 'utf8' : 'ascii';
    my $bodyContent = " " x $cellSize;
    my $characters = {
        utf8 => {
            topleftcorner => "\x{250c}",
            horizontalwall => "\x{2500}",
            toprightcorner => "\x{2510}",
            verticalwall => "\x{2502}",
            halfvwalltop => "\x{2575}",
            halfvwallbottom => "\x{2577}",
            halfhwallleft => "\x{2574}",
            halfhwallright => "\x{2576}",
            door => " ",
            fourwaycorner => "\x{253c}",
            body => $bodyContent,
            bottomleftcorner => "\x{2514}",
            bottomrightcorner => "\x{2518}",
            flattopwall => "\x{252c}",
            flatleftwall => "\x{251c}",
            flatrightwall => "\x{2524}",
            flatbottomwall => "\x{2534}",
        },
        ascii => {
            topleftcorner => "+",
            horizontalwall => "-",
            toprightcorner => "+",
            verticalwall => "|",
            door => " ",
            fourwaycorner => "+",
            body => $bodyContent,
            bottomleftcorner => "+",
            bottomrightcorner => "+",
            flattopwall => "+",
            flatleftwall => "+",
            flatrightwall => "+",
            flatbottomwall => "+",
            halfvwalltop => "|",
            halfvwallbottom => "|",
            halfhwallleft => "-",
            halfhwallright => "-",
        },
    };

    my $bodyRows = int($cellSize / 2.5);
    my @cellText;

    # top line of the maze
    unless ($self->north) {
        my $top = '';
        if (!$self->west) {
            # top left corner
            $top .= $characters->{$charset}{topleftcorner};
        }
        $top .= $characters->{$charset}{horizontalwall} x $cellSize;
        if ($self->east) {
            if ($self->linked($self->east)) {
                $top .= $characters->{$charset}{horizontalwall};
            } else {
                $top .= $characters->{$charset}{flattopwall};
            }
        } else {
            $top .= $characters->{$charset}{toprightcorner};
        }
        push @cellText, $top;
    }

    # body
    while ($bodyRows--) {
        my $body = '';
        if (!$self->west) {
            $body .= $characters->{$charset}{verticalwall};
        }
        $body .= $characters->{$charset}{body};
        if ($self->east) {
            if ($self->linked($self->east)) {
              $body .= $characters->{$charset}{door};
            } else {
              $body .= $characters->{$charset}{verticalwall};
            }
        } else {
            $body .= $characters->{$charset}{verticalwall};
        }
        push @cellText, $body;
    }

    # bottom
    my $bottom = '';
    if (!$self->west) {
        if ($self->south) {
            if ($self->linked($self->south)) {
                $bottom .= $characters->{$charset}{verticalwall};
            } else {
                $bottom .= $characters->{$charset}{flatleftwall};
            }
        } else {
          $bottom .= $characters->{$charset}{bottomleftcorner};
        }
    }
    if ($self->south) {
        if ($self->linked($self->south)) {
            $bottom .= $characters->{$charset}{door} x $cellSize;
        } else {
            $bottom .= $characters->{$charset}{horizontalwall} x $cellSize;
        }
    } else {
        $bottom .= $characters->{$charset}{horizontalwall} x $cellSize;
    }

    if ($self->east && $self->south) {
        if ($self->linked($self->east) && $self->linked($self->south)) {        # linked east and linked south
            # south not linked to it's east and east not linked to it's south
            if (!$self->south->linked($self->south->east) && !$self->east->linked($self->east->south)) {
                $bottom .= $characters->{$charset}{topleftcorner};
            # south not linked to it's east and east linked to it's south
            } elsif (!$self->south->linked($self->south->east) && $self->east->linked($self->east->south)) {
                $bottom .= $characters->{$charset}{halfvwallbottom};
            # south linked to it's east and east not linked to it's south
            } elsif ($self->south->linked($self->south->east) && !$self->east->linked($self->east->south)) {
                $bottom .= $characters->{$charset}{halfhwallright};
            # south linked to it's east and east linked to it's south
            } elsif ($self->south->linked($self->south->east) && $self->east->linked($self->east->south)) {
                $bottom .= $characters->{$charset}{door};
            }
        } elsif ($self->linked($self->east) && !$self->linked($self->south)) {  # linked east not linked south
            # south not linked to it's east and east not linked to it's south
            if (!$self->south->linked($self->south->east) && !$self->east->linked($self->east->south)) {
                $bottom .= $characters->{$charset}{flattopwall};
            # south not linked to it's east and east linked to it's south
            } elsif (!$self->south->linked($self->south->east) && $self->east->linked($self->east->south)) {
                $bottom .= $characters->{$charset}{toprightcorner};
            # south linked to it's east and east not linked to it's south
            } elsif ($self->south->linked($self->south->east) && !$self->east->linked($self->east->south)) {
                $bottom .= $characters->{$charset}{horizontalwall};
            # south linked to it's east and east linked to it's south
            } elsif ($self->south->linked($self->south->east) && $self->east->linked($self->east->south)) {
                $bottom .= $characters->{$charset}{halfhwallleft};
            }
        } elsif (!$self->linked($self->east) && $self->linked($self->south)) {  # not linked east linked south
            # south not linked to it's east and east not linked to it's south
            if (!$self->south->linked($self->south->east) && !$self->east->linked($self->east->south)) {
                $bottom .= $characters->{$charset}{flatleftwall};
            # south not linked to it's east and east linked to it's south
            } elsif (!$self->south->linked($self->south->east) && $self->east->linked($self->east->south)) {
                $bottom .= $characters->{$charset}{verticalwall};
            # south linked to it's east and east not linked to it's south
            } elsif ($self->south->linked($self->south->east) && !$self->east->linked($self->east->south)) {
                $bottom .= $characters->{$charset}{bottomleftcorner};
            # south linked to it's east and east linked to it's south
            } elsif ($self->south->linked($self->south->east) && $self->east->linked($self->east->south)) {
                $bottom .= $characters->{$charset}{halfvwalltop};
            }
        } elsif (!$self->linked($self->east) && !$self->linked($self->south)) { # not linked east not linked south
            # south not linked to it's east and east not linked to it's south
            if (!$self->south->linked($self->south->east) && !$self->east->linked($self->east->south)) {
                $bottom .= $characters->{$charset}{fourwaycorner};
            # south not linked to it's east and east linked to it's south
            } elsif (!$self->south->linked($self->south->east) && $self->east->linked($self->east->south)) {
                $bottom .= $characters->{$charset}{flatrightwall};
            # south linked to it's east and east not linked to it's south
            } elsif ($self->south->linked($self->south->east) && !$self->east->linked($self->east->south)) {
                $bottom .= $characters->{$charset}{flatbottomwall};
            # south linked to it's east and east linked to it's south
            } elsif ($self->south->linked($self->south->east) && $self->east->linked($self->east->south)) {
                $bottom .= $characters->{$charset}{bottomrightcorner};
            }
        }
    } elsif ($self->east) {
        if ($self->linked($self->east)) {
            $bottom .= $characters->{$charset}{horizontalwall};
        } else {
            $bottom .= $characters->{$charset}{flatbottomwall};
        }
    } elsif ($self->south) {
        if ($self->linked($self->south)) {
            $bottom .= $characters->{$charset}{verticalwall};
        } else {
            $bottom .= $characters->{$charset}{flatrightwall};
        }
    } else {
        $bottom .= $characters->{$charset}{bottomrightcorner};
    }

    push @cellText, $bottom;

    return @cellText;
}

sub draw {
    my ($self, %params) = @_;
    my $cellSize = $params{cellsize} || 10;
    $cellSize = 3 if $cellSize < 3;

    my $x1 = $self->column * $cellSize;
    my $y1 = $self->row * $cellSize;
    my $x2 = ($self->column + 1) * $cellSize;
    my $y2 = ($self->row + 1) * $cellSize;

    my $img = $params{image};
    $img->line($x1,$y1,$x2,$y1) unless $self->north;
    $img->line($x1,$y1,$x1,$y2) unless $self->west;

    $img->line($x2,$y1,$x2,$y2) unless $self->linked($self->east);
    $img->line($x1,$y2,$x2,$y2) unless $self->linked($self->south);

    return $self;
}


1;

