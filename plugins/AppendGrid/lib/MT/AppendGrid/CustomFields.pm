package MT::AppendGrid::CustomFields;

use strict;
use warnings;
use MT::AppendGrid::Util;
use MT::Request;

sub _append_grid_params {
    my ( $format, $key, $tmpl_key, $tmpl_param ) = @_;

    # pp $tmpl_param;
    if ( $tmpl_key eq 'field_html' ) {
        $tmpl_param->{plugin_version} = plugin->{version};

        # Including css, js?
        my $cache = MT::Request->instance->cache('append_grid') || {};
        $tmpl_param->{append_grid_included} = $cache->{append_grid_included};
        $cache->{append_grid_included} = 1;
        MT::Request->instance->cache('append_grid', $cache);
    } elsif ( $tmpl_key eq 'options_field' ) {
        unless ( $tmpl_param->{id} ) {
            my $key = "_default_options_$format";
            my $options = plugin->translate("_default_options_$format");
            $tmpl_param->{options} = plugin->translate("_default_options_$format");
        }
    }

    1;
}

sub append_grid_with_json_params {
    _append_grid_params('json', @_);
}

sub append_grid_with_yaml_params {
    _append_grid_params('yaml', @_);
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

1;