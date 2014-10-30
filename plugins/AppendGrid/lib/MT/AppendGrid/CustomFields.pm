package MT::AppendGrid::CustomFields;

use strict;
use warnings;
use MT::AppendGrid::Util;
use MT::Request;

sub _common_field_html_param {
    my ( $tmpl_param ) = @_;

    $tmpl_param->{plugin_version} = plugin->{version};

    # Including css, js?
    my $cache = MT::Request->instance->cache('append_grid') || {};
    $tmpl_param->{append_grid_included} = $cache->{append_grid_included};
    $cache->{append_grid_included} = 1;

    MT::Request->instance->cache('append_grid', $cache);
}

sub _append_grid_params {
    my ( $format, $key, $tmpl_key, $tmpl_param ) = @_;
    my $app = MT->instance;

    # pp $tmpl_param;
    if ( $tmpl_key eq 'field_html' ) {
        _common_field_html_param($tmpl_param);

        # YAML to JSON
        my $tmpl_param->{options} = yaml2json($tmpl_param->{options});
    } elsif ( $tmpl_key eq 'options_field' ) {
        unless ( $tmpl_param->{id} ) {
            my $key = "_default_options_$format";
            my $options = plugin->translate("_default_options_$format");
            $tmpl_param->{options} = plugin->translate("_default_options_$format");
        }

        my $blog_id = $app->can('blog') && $app->blog ? $app->blog->id : 0;
        $tmpl_param->{append_grid_preview_url} = $app->uri(
            mode => 'preview_append_grid',
            args => {
                blog_id => $blog_id,
            },
        );
    }

    1;
}

sub append_grid_with_json_params {
    _append_grid_params('json', @_);
}

sub append_grid_with_yaml_params {
    _append_grid_params('yaml', @_);
}

sub append_grid_schema_params {
    my ( $key, $tmpl_key, $tmpl_param ) = @_;

    $tmpl_param->{debug_mode} = $MT::DebugMode;

    if ( $tmpl_key eq 'field_html' ) {
        _common_field_html_param($tmpl_param);

        if ( my $append_field_schema = MT->model('append_grid_schema')->load($tmpl_param->{options} || 0) ) {
            $tmpl_param->{options} = $append_field_schema->schema_json;
        }
    } elsif ( $tmpl_key eq 'options_field' ) {
        my $app = MT->instance;
        my @blog_ids = $app->can('blog') && $app->blog ? ( $app->blog->id ) : ();
        push @blog_ids, 0;

        my @append_grid_schemas = MT->model('append_grid_schema')->load({blog_id => \@blog_ids});

        my $options = $tmpl_param->{options} || '';
        $tmpl_param->{append_grid_schemas} = [ map {
            {
                label       => $_->name,
                value       => $_->id,
                selected    => $_->id eq $options ? 1 : 0,
            }
        } @append_grid_schemas ];
    }
}

sub append_grid_validate {
    my ( $value ) = @_;
    my $app = MT->instance;

    # Check if parse as JSON.
    local $@;
    my $json = eval { MT::Util::from_json($value); };
    $app->error( plugin->translate('JSON is not parsable because [_1]: [_2]', $@, $value) )
        if $@;

    # Check format is array of hash?
    my $is_array_of_hash = 1;
    if ( ref $json eq 'ARRAY' ) {
        foreach my $hash ( @$json ) {
            if ( ref $hash ne 'HASH' ) {
                $is_array_of_hash = 0;
                last;
            }
        }
    } else {
        $is_array_of_hash = 0;
    }

    $app->error( plugin->translate('JSON data must be an array of hash: [_1]', $value ) )
        unless $is_array_of_hash;

    $value;
}

sub template_param_edit_field {
    my ( $cb, $app, $param, $tmpl ) = @_;

    my $header = $tmpl->getElementById('header_include');
    my $node = $tmpl->createElement('setvarblock', { name => 'html_head', append => 1 });
    $node->innerHTML(q{
        <mt:include name="cms/append_grid_html_head.tmpl" component="AppendGrid">
    });
    $tmpl->insertBefore($node, $header);

    1;
}

1;