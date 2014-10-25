#!/usr/bin/perl
package MT::InstaPost::Test;
use strict;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/../lib", "$FindBin::Bin/../extlib");
use Test::More;

use MT;
use base qw( MT::Tool );

my $VERSION = 0.1;
sub version { $VERSION }

sub help {
    return <<'HELP';
OPTIONS:
    -h, --help             shows this help.
HELP
}

sub usage {
    return '[--help]';
}


## options
my ( $blog_id, $user_id, $verbose );

sub options {
    return (
    )
}

sub uses {
    use_ok('MT::AppendGrid::Schema');
    use_ok('MT::AppendGrid::CMS::Asset');
    use_ok('MT::AppendGrid::CustomFields');
    use_ok('MT::AppendGrid::L10N::en_us');
    use_ok('MT::AppendGrid::L10N::ja');
    use_ok('MT::AppendGrid::L10N');
    use_ok('MT::AppendGrid::Util');
}

sub utils {
    require MT::AppendGrid::Util;

    my $structure = { node => { scalar => 'value', array => [ 'a', 'b' ], hash => { a => "A", b => "B" } } };

    my $yaml = <<'YAML';
---
node:
  array:
    - a
    - b
  hash:
    a: A
    b: B
  scalar: value
YAML

    my $json = q!{
   "node" : {
      "array" : [
         "a",
         "b"
      ],
      "hash" : {
         "a" : "A",
         "b" : "B"
      },
      "scalar" : "value"
   }
}!;

    my $json2 = q!{
   "node" : {
      "scalar" : "value",
      "array" : [
         "a",
         "b"
      ],
      "hash" : {
         "a" : "A",
         "b" : "B"
      }
   }
}!;

    is_deeply(MT::AppendGrid::Util::yaml2hash($yaml), $structure, 'yaml2hash');
    is(MT::AppendGrid::Util::hash2yaml($structure), $yaml, 'hash2yaml');
    is(MT::AppendGrid::Util::yaml2json($yaml), $json, 'yaml2json');

    is_deeply(MT::AppendGrid::Util::json2hash($json), $structure, 'json2hash');
    is(MT::AppendGrid::Util::hash2json($structure), $json2, 'hash2json');
    is(MT::AppendGrid::Util::json2yaml($json), $yaml, 'json2yaml');
}

sub schema {
    my $schema = MT->model('append_grid_schema')->new();

    isa_ok($schema, 'MT::Object');

    $schema->set_values({
        schema_format => 'yaml',
        schema_yaml => <<'YAML',
---
columns:
    - first
    - second
YAML
    });

    is_deeply($schema->schema_hash, { columns => ['first', 'second'] }, 'schema_hash from yaml');

    # Change to JSON
    $schema->schema_format('json');
    $schema->schema_json('{"columns":["first", "second"]}');
    is_deeply($schema->schema_hash, { columns => ['first', 'second'] }, 'changed to json');

    # Get as YAML
    my $yaml = $schema->schema_yaml;
    is_deeply(yaml2hash($yaml), { columns => ['first', 'second'] }, 'get as yaml')
}

sub main {
    my $mt = MT->instance;
    my $class = shift;

    $verbose = $class->SUPER::main(@_);

    uses();
    utils();
    schema();
}

__PACKAGE__->main() unless caller;

done_testing();


