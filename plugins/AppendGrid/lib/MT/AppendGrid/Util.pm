package MT::AppendGrid::Util;

use strict;
use base qw(Exporter);
use Data::Dumper;
use MT::Util;
use MT::Util::YAML;

our @EXPORT = qw(plugin pp yaml2hash hash2yaml yaml2json json2hash hash2json json2yaml);

sub plugin {
    MT->component('AppendGrid');
}

sub pp { print STDERR Dumper(@_); }

sub yaml2hash {
    eval { MT::Util::YAML::Load(@_) };
}

sub hash2yaml {
    eval { MT::Util::YAML::Dump(@_) };
}

sub yaml2json {
    eval { hash2json(yaml2hash(@_)) };
}

sub json2hash {
    eval { MT::Util::from_json(@_) };
}

sub hash2json {
    eval { MT::Util::to_json(@_, { pretty => 1 }) };
}

sub json2yaml {
    eval { hash2yaml(json2hash(@_)) };
}

1;