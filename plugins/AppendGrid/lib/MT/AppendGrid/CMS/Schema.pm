package MT::AppendGrid::CMS::Schema;

use strict;
use warnings;
use MT::AppendGrid::Util;

sub edit {
    my ( $cb, $app, $id, $obj, $param ) = @_;
    return $app->permission_denied
        unless $app->permissions->can_do('edit_custom_fields');

    my $blog_id = $app->can('blog') && $app->blog ? $app->blog->id : 0;
    $param->{append_grid_preview_url} = $app->uri(
        mode => 'preview_append_grid',
        args => {
            blog_id => $blog_id,
        },
    );

    $app->setup_editor_param($param);

    $param->{schema_format} ||= 'yaml';
    if ( $obj ) {
        $param->{schema_yaml} = $obj->schema_yaml;
        $param->{schema_json} = $obj->schema_json;
    } else {
        my $yaml = plugin->translate('_default_options_yaml');
        $param->{schema_yaml} = $yaml;
        $param->{schema_json} = yaml2json($yaml);
        $param->{template} = plugin->translate('_default_schema_template');
    }

    $param->{output} = File::Spec->catfile( plugin->{full_path},
        'tmpl', 'cms', 'edit_append_grid_schema.tmpl' );
}

sub preview {
    my ( $app ) = @_;
    return $app->permission_denied
        unless $app->permissions->can_do('edit_custom_fields');

    my $schema_format = $app->param('schema_format');
    my $schema = MT->model('append_grid_schema')->new;
    $schema->set_values({
        schema_format   => $app->param('schema_format'),
        schema_json     => $app->param('schema_json'),
        schema_yaml     => $app->param('schema_yaml'),
    });

    if ( $schema->validate ) {
        $app->json_result({
            schema => $schema->schema_hash
        });
    } else {
        $app->json_error($schema->errstr);
    }
}

sub save_filter {
    my ( $cb, $app ) = @_;
    return $app->permission_denied
        unless $app->permissions->can_do('edit_custom_fields');

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
    return $app->permission_denied
        unless $app->permissions->can_do('edit_custom_fields');

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