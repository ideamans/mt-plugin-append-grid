package MT::AppendGrid::CustomFields;

use strict;
use warnings;
use MT::AppendGrid::Util;
use MT::Request;

sub append_grid_with_json_params {
    my ( $key, $tmpl_key, $tmpl_param ) = @_;

    if ( $tmpl_key eq 'field_html' ) {
        $tmpl_param->{plugin_version} = plugin->{version};

        # Including css, js?
        my $cache = MT::Request->instance->cache('append_grid') || {};
        $tmpl_param->{append_grid_included} = $cache->{append_grid_included};
        $cache->{append_grid_included} = 1;
        MT::Request->instance->cache('append_grid', $cache);
    }

    1;
}

1;