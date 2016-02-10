package Games::Maze::Cell;

use Set::Object;
use Moo;
use MooX::late;
use namespace::clean;

# x part of the coordinates for this cell
has column => (
    is => 'ro',
    isa => 'Int',
    default => sub {0}
);

# y part of the coordinates for this cell
has row => (
    is => 'ro',
    isa => 'Int',
    default => sub {0}
);

# z part of the coordinates for this cell
has level => (
    is => 'ro',
    isa => 'Int',
    default => sub {0}
);

# neighbor going up
has up => (
    is => 'rw',
    isa => 'Maybe[Games::Maze::Cell]',
    default => sub {}
);

# neighbor going down
has down => (
    is => 'rw',
    isa => 'Maybe[Games::Maze::Cell]',
    default => sub {}
);

# if true, we will include up and down in the potential neighbor list
has multilevel => (
    is => 'rw',
    isa => 'Int',
    default => sub {0}
);

# the neighbors of the cell that share an open wall
has links => (
    is => 'rw',
    isa => 'Set::Object',
    default => sub {Set::Object->new();}
);

# add a cell to the set of neighbors
sub link {
    my ($self, $cell, $oneway) = @_;
    if ($cell) {
        $self->links->insert($cell->id);
        $cell->link($self, 1) unless $oneway;
    }
}

# remove a cell from the set of neighbors
sub unlink {
    my ($self, $cell, $oneway) = @_;
    if ($cell) {
        $self->links->delete($cell->id);
        $cell->unlink($self, 1) unless $oneway;
    }
}

sub linked {
    my ($self, $cell) = @_;
    return 0 unless $cell;
    return ($self->links->has($cell->id) ? 1 : 0);
}

sub reset {
    my ($self) = @_;
    $self->links = Set::Light->new();
}

# id is the coordinates of the cell (x,y,z)
sub id {
    my ($self, %params) = @_;
    my $size = $params{size} || 0;
    my $formatstr = "%0${size}d:%0${size}d:%0${size}d";

    return sprintf $formatstr, $self->column, $self->row, $self->level;
}

1;

