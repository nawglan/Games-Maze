package Games::Maze::CellType::Square;

use strict;
use Moo;
use MooX::late;
use namespace::clean;
extends "Games::Maze::Cell";

# directions for potential openings
has north => (
    is => 'rw',
    isa => 'Maybe[Games::Maze::Cell]',
#    trigger => sub {my ($self, $target) = @_; warn ("DEZ: setting north for " . $self->id(size=>2) . " to " . $target->id(size=>2) . "\n");},
);

has south => (
    is => 'rw',
    isa => 'Maybe[Games::Maze::Cell]',
#    trigger => sub {my ($self, $target) = @_; warn ("DEZ: setting south for " . $self->id(size=>2) . " to " . $target->id(size=>2) . "\n");},
);

has east => (
    is => 'rw',
    isa => 'Maybe[Games::Maze::Cell]',
#    trigger => sub {my ($self, $target) = @_; warn ("DEZ: setting  east for " . $self->id(size=>2) . " to " . $target->id(size=>2) . "\n");},
);

has west => (
    is => 'rw',
    isa => 'Maybe[Games::Maze::Cell]',
#    trigger => sub {my ($self, $target) = @_; warn ("DEZ: setting  west for " . $self->id(size=>2) . " to " . $target->id(size=>2) . "\n");},
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

sub draw {
    my ($self, %params) = @_;
    my $cellSize = $params{cellsize} || 10;
    $cellSize = 3 if $cellSize < 3;

    my $wallSize = $params{wallsize} || 1;

    my $img = $params{image};
    if ($img) {
        my $x1 = $self->column * $cellSize;
        my $y1 = $self->row * $cellSize;
        my $x2 = ($self->column + $wallSize) * $cellSize;
        my $y2 = ($self->row + $wallSize) * $cellSize;

        $img->moveTo($x1,$y1);
        $img->lineTo($x2,$y1) unless $self->north;
        $img->moveTo($x1,$y1);
        $img->lineTo($x1,$y2) unless $self->west;

        $img->moveTo($x2,$y1);
        $img->lineTo($x2,$y2) unless $self->linked($self->east);
        $img->moveTo($x1,$y2);
        $img->lineTo($x2,$y2) unless $self->linked($self->south);

        return $self;
    } else {
        my $utf8 = $params{utf8} || 0;
        my $wall = $utf8 ? '|' : '|';
        my $door = $utf8 ? ' ' : ' ';
        my $corner = $utf8 ? '+' : '+';
        my $southWall = $utf8 ? '-' : '-';
        my $body = ' ' x $cellSize;
        my $bodyRows = int($cellSize / 3);
        my @cellText;

        # top line
        unless ($self->north) {
            push @cellText, (($self->west ? '' : ($self->north ? ($self->linked($self->north) ? $wall : $corner) : $corner)) . ($southWall x $cellSize) . ($self->east ? ($self->linked($self->east) ? $southWall : $corner) : $corner));
        }

        # body
        while ($bodyRows--) {
            push @cellText, (($self->west ? '' : $wall) . $body . ($self->east ? ($self->linked($self->east) ? $door : $wall) : $wall));
        }

        # bottom
        push @cellText, (($self->west ? '' : ($self->south ? ($self->linked($self->south) ? $wall : $corner) : $corner)) . ($self->linked($self->south) ? ($door x $cellSize) : ($southWall x $cellSize)) . ($self->east ? ($self->linked($self->east) ? $southWall : $corner) : $corner));

        return @cellText;
    }
}

sub toString {
}

1;
