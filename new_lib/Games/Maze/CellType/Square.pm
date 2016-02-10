package Games::Maze::CellType::Square;

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

1;
