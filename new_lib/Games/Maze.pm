package Games::Maze;

use Moo;
use namespace::clean;

# short name in the Games::Maze::GridType namespace, implemented as a Moo::Role
has gridtype => (
    is => 'rw',
    isa => sub {
        ($_[0] =~ /^\w+$/ && require "Games/Maze/GridType/$_[0].pm")
            or die "Error: 'gridtype' value '$_[0]' is not supported";
    },
    default => sub {'Square'}
);

# short name in the Games::Maze::CellType namespace, implemented as a Moo::Role
has celltype => (
    is => 'rw',
    isa => sub {
        ($_[0] =~ /^\w+$/ && require "Games/Maze/CellType/$_[0].pm")
            or die "Error: 'celltype' value '$_[0]' is not supported";
    },
    default => sub {'Square'}
);

# options, keys may be different based on type of grid and cell being used
has options => (
    is => 'rw',
    isa => sub {
        (ref $_[0] eq 'HASH' && keys %{$_[0]})
            or die "Error: 'options' value must be a non-empty hash reference";
    }
);

sub initialize {
  my ($self) = @_;
  my $gridtype = $self->gridtype;
  with "Games::Maze::GridType::$gridtype";

  my $options = $self->options;
  my $seed = delete $options->{seed};
  if (defined $seed) {
      srand $seed;
  } else {
      srand time;
  }

  $self->createGrid(%{$options});

  return $self;
}

sub getCell {
    my ($self, %params) = @_;
    my $x = $params{column};
    my $y = $params{row};
    my $z = $params{level};

    return $self->{_cellmap}[$z][$y][$x];
}

sub generate {
    my ($self, %params) = @_;
    my $method = $params{method} || $self->options->{method} || 'BinaryTree';
    require "Games/Maze/Algorithm/$method.pm" or die "Error: 'method' value '$method' is not supported";
    my $classname = "Games::Maze::Algorithm::$method";

    no warnings qw/once/;
    return $classname->generate(grid => $self);
}

1;

