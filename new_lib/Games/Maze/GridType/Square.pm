package Games::Maze::GridType::Square;

# Squarish mazes.  Each row has equal number of columns

use Data::Dumper;
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
    my ($self, %params) = @_;
    my $cellSize = $params{cellsize} || 3;
    my $utf8 = $params{utf8} || 0;
    $cellSize = 3 if ($cellSize < 3);

    my $levels = $self->options()->{levels};
    my $rows = $self->options()->{rows};
    my $cols = $self->options()->{columns};
    my $output = '';

    my $iterator = $self->eachRow();
    while (my $cells = $iterator->()) {
        my @rowText;
        foreach my $cell (@$cells) {
            my @cellText = $cell->toString(cellsize => $cellSize, utf8 => $utf8);
            for (my $i = 0; $i < scalar @cellText; $i++) {
                $rowText[$i] .= $cellText[$i];
            }
        }
        $output .= "$_\n" foreach (@rowText);
    }

    return $output;
}

sub toImg {
    my ($self, %params) = @_;
    my $cellSize = $params{cellsize} || 10;
    $cellSize = 3 if $cellSize < 3;
    my $bgColor = $params{bgcolor} || 'white';
    my $fgColor = $params{fgcolor} || 'black';
    my $trueColor = $params{truecolor} || 0;
    my $imgType = lc ($params{imagetype} || 'png');
    my $filename = $params{filename} || 'maze_' . int(rand(100)) . '.png';

    my $imgWidth = $cellSize * $self->options()->{columns} + 1;
    my $imgHeight = $cellSize * $self->options()->{rows} + 1;

    open my $IMGFILE, '>', $filename or die "Error: Unable to open $filename for output: $!";

    my $svgSupported = 1;
    require GD::SVG or ($svgSupported = 0);

    my $supported = {
        svg => undef,
        gif => undef,
        png => undef,
        jpg => undef,
        gd => undef,
        gd2 => undef,
        wbmp => undef
    };
    delete $supported->{svg} unless $svgSupported;

    if (!exists $supported->{$imgType}) {
        die "Error: Supported types are: " .
        ($svgSupported ? 'svg, ' : '') . "gif, png, jpg, gd, gd2, wbmp.\n" .
            "       Option 'imagetype' value $imgType is not supported.";
    }

    require GD::Simple or die 'Error: GD perl module is not installed.  Image output is not supported.';

    if ($imgType eq 'svg') {
        GD::Simple->class('GD::SVG');
    }

    my $img = GD::Simple->new($imgWidth, $imgHeight, $trueColor);

    $img->fgcolor($fgColor);
    $img->bgcolor($bgColor);

    # do this for each level
    my $iterator = $self->eachCell();
    while (my $cell = $iterator->()) {
        $cell->draw(cellsize => $cellSize, image => $img);
    }
    if ($imgType eq 'gif') {
        print $IMGFILE $img->gif();
    } elsif ($imgType eq 'png') {
        print $IMGFILE $img->png();
    } elsif ($imgType eq 'jpg') {
        print $IMGFILE $img->jpeg();
    } elsif ($imgType eq 'gd') {
        print $IMGFILE $img->gd();
    } elsif ($imgType eq 'gd2') {
        print $IMGFILE $img->gd2();
    } elsif ($imgType eq 'wbmp') {
        print $IMGFILE $img->wbmp($fgColor);
    } elsif ($imgType eq 'svg') {
        print $IMGFILE $img->svg();
    }

    close $IMGFILE;
}

sub toPDF {
    my ($self, %params) = @_;
    my $cellSize = $params{cellsize} || 10;
    my $wallSize = $params{wallsize} || 1;
    my $pageSize = $params{pagesize} || 'letter';
    $cellSize = 3 if $cellSize < 3;

    require PDF::Create or die 'Error: Unable to save as PDF. Please install PDF::Create.';
    my $pdf = PDF::Create->new(
        filename => $params{filename},
        Author => $params{author} || 'Games::Maze CPAN Module',
        Title => $params{title} || '',
        CreationDate => [localtime]
    );

    # do this for each level
    my $page = $pdf->new_page(MediaBox => $pdf->get_page_size($pageSize));
    my $iterator = $self->eachCell();
    while (my $cell = $iterator->()) {
        $cell->draw(cellsize => $cellSize, wallsize => $wallSize, image => $page);
    }
    $pdf->close;
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

