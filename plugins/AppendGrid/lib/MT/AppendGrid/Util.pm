package MT::AppendGrid::Util;

use strict;
use base qw(Exporter);
use Data::Dumper;

our @EXPORT = qw(plugin pp);

sub plugin {
    MT->component('AppendGrid');
}

sub pp { print STDERR Dumper(@_); }

1;