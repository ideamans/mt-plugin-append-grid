package MT::AppendGrid::CMS::Schema;

use strict;
use warnings;
use MT::AppendGrid::Util;

sub edit {
    my ( $cb, $app, $id, $obj, $param ) = @_;
    $app->setup_editor_param($param);
    $param->{schema_format} ||= 'yaml';

    $param->{schema_yaml} = $obj->schema_yaml;
    $param->{schema_json} = $obj->schema_json;

    $param->{output} = File::Spec->catfile( plugin->{full_path},
        'tmpl', 'cms', 'edit_append_grid_schema.tmpl' );
}

sub save_filter {
    my ( $cb, $app ) = @_;
    my %values = $app->param_hash;

    my $name = $app->param('name');
    return $cb->error(plugin->translate('Name is required.'))
        if !defined $name || $name eq '';

    my $schema = MT->model('append_grid_schema')->new;
    $schema->set_values(\%values);
    return $cb->error($schema->errstr) unless $schema->validate;

    1;
}

sub pre_save {
    my ( $cb, $app, $obj ) = @_;
    my $schema_json = $app->param('schema_json');
    my $schema_yaml = $app->param('schema_yaml');

    if ( $obj->schema_format eq 'yaml' ) {
        $obj->schema_yaml($schema_yaml);
    } else {
        $obj->schema_json($schema_json);
    }

    1;
}

1;