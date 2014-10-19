package MT::AppendGrid::Tags;

use strict;
use warnings;

use Data::Dumper;
use MT::Util;
use MT::AppendGrid::Util;

sub _context_schema {
    my ( $ctx, $args ) = @_;
    my $blog = $ctx->stash('blog');
    my $schema;

    if ( $args->{schema} ) {
        $schema = $args->{schema};
    } elsif ( my $basename = $args->{basename} ) {
        my $asset;

        # Lookup in the blog at first
        $asset = MT->model('field')->load({ blog_id => $blog->id, basename => $basename })
            if $blog;
        $asset ||= MT->model('field')->load({ basename => $basename });

        return $ctx->error(plugin->translate('AppendGrid Customfield which basename is "[_1]" is not found.', $basename))
            unless $asset;

        $schema = $asset->options;
    } elsif ( $ctx->stash('append_grid_schema') ) {
        $schema = $ctx->stash('append_grid_schema');
    } else {
        return '';
    }

    if ( ref $schema eq '' ) {
        # Parse as JSON
        $schema = eval { MT::Util::from_json($schema) }
            || return $ctx->error(plugin->translate('AppendGrid Customfield which basename is [_1] has no JSON hash options.', $basename));
    }

    return $ctx->error(plugin->translate('AppendGrid Customfield which basename is [_1] has no JSON hash options.', $basename))
        if ref $schema ne 'HASH';

    return $ctx->error(plugin->translate('AppendGrid Customfield which basename is [_1] has no columns array in options.', $basename))
        if ref $schema->{hash} ne 'ARRAY';

    foreach my $col ( @{$schema->{hash}} ) {
        return $ctx->error(plugin->translate('AppendGrid Customfield which basename is [_1] has invalid column in columns.', $basename))
            if ref $col ne 'HASH';
        return $ctx->error(plugin->translate('AppendGrid Customfield which basename is [_1] has column without name in columns.', $basename))
            unless $col->{name};
    }

    $schema;
}

sub _context_data {
    my ( $ctx, $args ) = @_;
    my $data;

    if ( $args->{data} ) {
        $data = $args->{data};
    } elsif ( my $tag = $args->{tag} ) {
        $tag =~ s/^MT:?//i;
        my %tag_args = map { delete $args->{$_} }
            map { s/^tag://; $_ }
            grep { /^tag:/ }
            keys %$args;

        $data = $ctx->tag( $tag, \%tag_args, $cond );
    } elsif ( $ctx->stash('append_grid_data') ) {
        $data = $ctx->stash('append_grid_data');
    } else {
        return '';
    }

    if ( ref $data ne '' ) {
        # Parse ad JSON
        $data = eval { MT::Util::from_json($data) }
            || return $ctx->error(plugin->translate('AppendGrid data is not JSON format.'));
    }

    return $ctx->error(plugin->translate('AppendGrid data is not an array of hash.'))
        if ref $data ne 'ARRAY';

    foreach my $hash ( @$data ) {
        return $ctx->error(plugin->translate('AppendGrid data is not an array of hash.'))
             if ref $hash ne 'HASH';
    }

    $data;
}

sub _require_context_schema {
    defined( my $schema = _context_schema(@_) ) || return;
    return plugin->translate('No AppendGrid schema context. Set AppendGrid customfield basename as basename attribute of AppendGridColumns or AppendGrid template tag.')
        unless $schema;

    $schema;
}

sub _require_context_data {
    defined( my $data = _context_data($ctx, $args) ) || return;
    return plugin->translate('No AppendGrid data context. Set AppendGrid tag as tag attribute or set JSON data as data attribute of AppendGridRows, AppendGrid template tag.')
        unless $data;

    $data;
}

sub _require_context_row {
    my ( $ctx, $args ) = @_;
    defined( my $data = _require_context_data($ctx, $args) ) || return;

    my $row;
    if ( defined $args->{row} ) {
        $row = $data->{int($args->{row})} || return '';
    } elsif ( $ctx->stash('append_grid_row') ) {
        $row = $ctx->stash('append_grid_row');
    } else {
        return $ctx->error(plugin->translate('No AppendGrid row context. Set index as row attribute of AppendGridRow template tag or use in AppendGridRows template tag.'));
    }

    return $ctx->error(plugin->translate('AppendGrid row is not a hash: [_1]', Dumper($row)))
        unless ref $row eq 'HASH';

    $row;
}

sub _require_context_cell {
    my ( $ctx, $args ) = @_;
    defined( my $row = _require_context_row(@_) ) || return;

    my $cell;
    if ( defined( $args->{col} ) ) {
        $cell = $row->{$args->{col}};
    } elsif ( my $col = $ctx->stash('apend_grid_column') ) {
        $cell = $row->{$col->{name}};
    }

    defined( $cell ) ? $cell : '';
}

sub _basic_loop {
    my ( $array, $stash, $ctx, $args, $cond ) = @_;

    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');
    my $result = '';
    my $vars = $ctx->{__stash}{vars} ||= {};
    my $size = scalar @$array;
    for( my $i = 0; $i < $size; $i++ ) {
        local $ctx->{__stash}->{$stash} = $element;
        local $vars->{__first__} = ( $i == 0 )? 1: 0;
        local $vars->{__last__} = ( $i == $size-1 )? 1: 0;
        local $vars->{__odd__} = ( $i % 2 ) == 1;
        local $vars->{__even__} = ( $i % 2 ) == 0;
        local $vars->{__counter__} = $i;

        defined( my $partial = $builder->build($ctx, $tokens, $cond) ) || return;
        $result .= $partial;
    }

    $result;
}

sub hdlr_AppendGrid {
    my ( $ctx, $args, $cond ) = @_;

    my ( $schema, $data );
    defined( $schema = _context_schema($ctx, $args) ) || return;
    defined( $data = _context_data($ctx, $args) ) || return;

    local $ctx->{__stash}->{append_grid_schema} = $schema;
    local $ctx->{__stash}->{append_grid_data} = $data;

    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');
    defined( my $partial = $builder->build($ctx, $tokens, $cond) ) || return;

    $partial;
}

sub hdlr_AppendGridColumns {
    my ( $ctx, $args, $cond ) = @_;
    defined( my $schema = _require_context_schema($ctx, $args) ) || return;

    local $ctx->{__stash}->{append_grid_schema} = $schema;
    _basic_loop($schema->{columns}, 'append_grid_column', @_);
}

sub hdlr_AppendGridColumn {
    my ( $ctx, $args ) = @_;

    my $column = $ctx->stash('append_grid_column')
        || return $ctx->error(plugin->translate('No AppendGrid column context. Use in AppendGridColumns template tag.'));

    my $key = $args->{key} || $args->{attr}
        || return $ctx->error(plugin->translate('[_1] template tag requires at least each of [_2] as attributes.', 'mt:AppendGridColumn', 'key, attr'));

    my $value = $column->{$key};
    $value = '' unless defined $value;

    $value;
}

sub hdlr_AppendGridRows {
    my ( $ctx, $args, $cond ) = @_;
    defined( my $data = _require_context_data($ctx, $args) ) || return;

    local $ctx->{__stash}->{append_grid_data} = $data;
    _basic_loop($data, 'append_grid_row', @_);
}

sub hdlr_AppendGridRow {
    my ( $ctx, $args, $cond ) = @_;
    defined( my $row = _require_context_row($ctx, $args) ) || return;

    local $ctx->{__stash}->{append_grid_row} = $row;
    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');
    defined( my $partial = $builder->build($ctx, $tokens, $cond) ) || return;

    $partial;
}

sub hdlr_AppendGridCell {
    my ( $ctx, $args ) = @_;
    defined( my $cell = _require_context_cell($ctx, $args) ) || return;
    $cell;
}

# Inspired from ContextHandlers.pm in Commercial.pack
sub hdlr_AppendGridCellAsset {
    my ( $ctx, $args, $cond ) = @_;
    defined( my $value = _require_context_cell($ctx, $args) ) || return;
    return '' unless $value;

    my $tokens  = $ctx->stash('tokens');
    my $builder = $ctx->stash('builder');
    my $res     = '';

    $args->{no_asset_cleanup} = 1;

    require MT::Asset;
    while ( $value
        =~ m!<form[^>]*?\smt:asset-id=["'](\d+)["'][^>]*?>(.+?)</form>!gis )
    {
        my $id = $1;

        my $asset = MT::Asset->load($id);
        next unless $asset;

        local $ctx->{__stash}{asset} = $asset;
        defined( my $out = $builder->build( $ctx, $tokens ) )
            or return $ctx->error( $builder->errstr );
        $res .= $out;
    }

    $res;
}

sub hdlr_AppendGridHeader {
    my ( $ctx, $args, $cond ) = @_;
    $ctx->var('__first__');
}

sub hdlr_AppendGridFooter {
    my ( $ctx, $args, $cond ) = @_;
    $ctx->var('__last__');
}



1;