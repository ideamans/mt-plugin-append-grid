#!/usr/bin/perl
package MT::AppendGrid::Test;
use strict;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/../lib", "$FindBin::Bin/../extlib");
use Test::More;

use MT;
use base qw( MT::Tool );
use Data::Dumper;

sub pp { print STDERR Dumper($_) foreach @_ }

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

sub test_template {
    my %args = @_;

    require MT::Builder;
    require MT::Template::Context;
    my $ctx = MT::Template::Context->new;
    my $builder = MT::Builder->new;

    $ctx->stash('append_grid_schema', $args{schema}) if $args{schema};
    $ctx->stash('append_grid_data', $args{data}) if $args{data};

    my $tokens = $builder->compile($ctx, $args{template}) or die $ctx->errstr || 'Feild to compile.';
    defined ( my $result = $builder->build($ctx, $tokens) )
        or die $ctx->errstr || 'Failed to build.';

    $result =~ s/^\n+//gm;
    $result =~ s/\n\s*\n/\n/gm;
    my @nodes = split( /::/, (caller(1))[3] );
    is($result, $args{expect}, pop @nodes);
}

sub template_basic {
    my %args;
    $args{template} = <<'EOT';
<mt:AppendGrid>
<table>
    <tr>
    <mt:AppendGridColumns>
        <th><mt:AppendGridColumn key="display" /></th>
    </mt:AppendGridColumns>
    </tr>
    <mt:AppendGridRows>
    <tr>
    <mt:AppendGridColumns>
        <td><mt:AppendGridCell /></td>
    </mt:AppendGridColumns>
    </tr>
    </mt:AppendGridRows>
</table>
</mt:AppendGrid>
EOT

    $args{schema} = {
        columns => [
            { name => 'column1', display => 'COLUMN1' },
            { name => 'column2', display => 'COLUMN2' },
            { name => 'column3', display => 'COLUMN3' },
        ]
    };
    $args{data} = [
        { column1 => 'VALUE1-1', column2 => 'VALUE1-2', column3 => 'VALUE1-3' },
        { column1 => 'VALUE2-1', column2 => 'VALUE2-2', column3 => 'VALUE2-3' },
    ];

    $args{expect} = <<'EOH';
<table>
    <tr>
        <th>COLUMN1</th>
        <th>COLUMN2</th>
        <th>COLUMN3</th>
    </tr>
    <tr>
        <td>VALUE1-1</td>
        <td>VALUE1-2</td>
        <td>VALUE1-3</td>
    </tr>
    <tr>
        <td>VALUE2-1</td>
        <td>VALUE2-2</td>
        <td>VALUE2-3</td>
    </tr>
</table>
EOH

    test_template(%args);
}

sub template_only_columns {
    my %args;
    $args{template} = <<'EOT';
<table>
    <tr>
    <mt:AppendGridColumns>
        <th><mt:AppendGridColumn key="display" />(<mt:AppendGridColumn key="name">)</th>
    </mt:AppendGridColumns>
    </tr>
</table>
EOT

    $args{schema} = {
        columns => [
            { name => 'column1', display => 'COLUMN1' },
            { name => 'column2', display => 'COLUMN2' },
            { name => 'column3', display => 'COLUMN3' },
        ]
    };

    $args{expect} = <<'EOH';
<table>
    <tr>
        <th>COLUMN1(column1)</th>
        <th>COLUMN2(column2)</th>
        <th>COLUMN3(column3)</th>
    </tr>
</table>
EOH

    test_template(%args);
}

sub template_column {
    my %args;

    $args{template} = <<'EOT';
<mt:AppendGridColumn index="1" key="name">
<mt:AppendGridColumn col="column3" key="display">
EOT
    $args{schema} = {
        columns => [
            { name => 'column1', display => 'COLUMN1' },
            { name => 'column2', display => 'COLUMN2' },
            { name => 'column3', display => 'COLUMN3' },
        ]
    };
    $args{expect} = <<'EOH';
column2
COLUMN3
EOH

    test_template(%args);
}

sub template_only_rows {
    my %args;

    $args{template} = <<'EOT';
<table>
    <mt:AppendGridRows>
    <tr>
        <td><mt:AppendGridCell column="column1" /></td>
        <td><mt:AppendGridCell column="column2" /></td>
        <td><mt:AppendGridCell column="column3" /></td>
    </tr>
    </mt:AppendGridRows>
</table>
EOT
    $args{data} = [
        { column1 => 'VALUE1-1', column2 => 'VALUE1-2', column3 => 'VALUE1-3' },
        { column1 => 'VALUE2-1', column2 => 'VALUE2-2', column3 => 'VALUE2-3' },
    ];

    $args{expect} = <<'EOH';
<table>
    <tr>
        <td>VALUE1-1</td>
        <td>VALUE1-2</td>
        <td>VALUE1-3</td>
    </tr>
    <tr>
        <td>VALUE2-1</td>
        <td>VALUE2-2</td>
        <td>VALUE2-3</td>
    </tr>
</table>
EOH

    test_template(%args);
}

sub tempalte_cell {
    my %args;

    $args{template} = q{<mt:AppendGridCell row="1" col="column3">};
    $args{data} = [
        { column1 => 'VALUE1-1', column2 => 'VALUE1-2', column3 => 'VALUE1-3' },
        { column1 => 'VALUE2-1', column2 => 'VALUE2-2', column3 => 'VALUE2-3' },
    ];
    $args{expect} = q{VALUE2-3};
    test_template(%args);
}

sub tempalte_group {
    my %args;

    $args{template} = <<'TMPL';
<mt:AppendGrid>
<mt:AppendGridRowGroups by="style">
    <h1><mt:AppendGridRowGroup></h1>
    <dl>
    <mt:AppendGridRows>
        <dt><mt:AppendGridRowGroup></dt>
        <dd><mt:AppendGridCell col="column"></dd>
    </mt:AppendGridRows>
    </dl>
</mt:AppendGridRowGroups>
</mt:AppendGrid>
TMPL

    $args{data} = [
        { style => 'li',    column => 'VALUE1'  },
        { style => 'li',    column => 'VALUE2'  },
        { style => 'p',     column => 'VALUE3'  },
        { style => 'li',    column => 'VALUE4'  },
        { style => 'li',    column => 'VALUE5'  },
        { style => 'li',    column => 'VALUE6'  },
        {                   column => 'VALUE7'  },
        { style => '',      column => 'VALUE8'  },
        { style => 'div',   column => 'VALUE9'  },
        { style => 'div',   column => 'VALUE10' },
    ];

    $args{expect} = <<'EXPECT';
    <h1>li</h1>
    <dl>
        <dt>li</dt>
        <dd>VALUE1</dd>
        <dt>li</dt>
        <dd>VALUE2</dd>
    </dl>
    <h1>p</h1>
    <dl>
        <dt>p</dt>
        <dd>VALUE3</dd>
    </dl>
    <h1>li</h1>
    <dl>
        <dt>li</dt>
        <dd>VALUE4</dd>
        <dt>li</dt>
        <dd>VALUE5</dd>
        <dt>li</dt>
        <dd>VALUE6</dd>
    </dl>
    <h1></h1>
    <dl>
        <dt></dt>
        <dd>VALUE7</dd>
        <dt></dt>
        <dd>VALUE8</dd>
    </dl>
    <h1>div</h1>
    <dl>
        <dt>div</dt>
        <dd>VALUE9</dd>
        <dt>div</dt>
        <dd>VALUE10</dd>
    </dl>
EXPECT
    test_template(%args);
}

sub main {
    my $mt = MT->instance;
    my $class = shift;

    $verbose = $class->SUPER::main(@_);

    uses;
    utils;
    schema;
    template_basic;
    template_only_columns;
    template_only_rows;
    template_column;
    tempalte_cell;
    tempalte_group;
}

__PACKAGE__->main() unless caller;

done_testing();


