package MT::AppendGrid::Tags;

use strict;
use warnings;
use utf8;

use Data::Dumper;
use MT::Util;
use MT::AppendGrid::Util;

sub _context_schema {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash('blog');
    my $schema;

    if ( $args->{schema} ) {
        $schema = $args->{schema};
    } elsif ( my $basename = $args->{basename} ) {
        defined( $schema = lookup_schema_by_field($ctx, basename => $basename ) )
            || return $ctx->error(plugin->translate('AppendGrid Customfield which basename is "[_1]" is not found.', $basename));
    } elsif ( my $tag = $args->{tag} ) {
        defined( $schema = lookup_schema_by_field($ctx, tag => $tag ) )
            || return $ctx->error(plugin->translate('AppendGrid Customfield which tag is "[_1]" is not found.', $tag));
    } elsif ( my $field = $ctx->stash('field') ) {
        defined( $schema = lookup_schema_by_field($ctx, field => $field ) )
            || return $ctx->error(plugin->translate('AppendGrid Customfield which basename is "[_1]" is not found.', $field->basename));
    } elsif ( $ctx->stash('append_grid_schema') ) {
        $schema = $ctx->stash('append_grid_schema');
    } else {
        return '';
    }

    if ( ref $schema eq '' ) {
        # Parse as JSON
        $schema = eval { MT::Util::from_json($schema) }
            || return $ctx->error(plugin->translate('AppendGrid Customfield has no JSON hash schema.'));
    }

    return $ctx->error(plugin->translate('AppendGrid Customfield has no JSON hash schema.'))
        if ref $schema ne 'HASH';

    return $ctx->error(plugin->translate('AppendGrid Customfield has no columns array in schema.'))
        if ref $schema->{columns} ne 'ARRAY';

    foreach my $col ( @{$schema->{columns}} ) {
        return $ctx->error(plugin->translate('AppendGrid has invalid column definision in columns.'))
            if ref $col ne 'HASH';
        return $ctx->error(plugin->translate('AppendGrid has column without name in column definition.'))
            unless $col->{name};
    }

    $schema;
}

sub _context_data {
    my ( $ctx, $args, $cond ) = @_;
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
    } elsif ( my $field = $ctx->stash('field') ) {
        $data = $ctx->tag( $field->tag, {}, $cond );
    } elsif ( my $schema = $ctx->stash('append_grid_schema') ) {
        $data = $schema->{initData};
    } else {
        return '';
    }

    if ( ref $data eq '' ) {
        # Parse ad JSON
        return '' if $data eq '';
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
    my ( $ctx, $args, $cond ) = @_;
    defined( my $schema = _context_schema(@_) ) || return;
    return $ctx->error(plugin->translate('No AppendGrid schema context. Set AppendGrid customfield basename as basename attribute of AppendGridColumns or AppendGrid template tag.'))
        unless $schema;

    $schema;
}

sub _require_context_data {
    my ( $ctx, $args, $cond ) = @_;
    defined( my $data = _context_data(@_) ) || return;
    return $ctx->error(plugin->translate('No AppendGrid data context. Set AppendGrid tag as tag attribute or set JSON data as data attribute of AppendGridRows, AppendGrid template tag.'))
        unless $data;

    $data;
}

sub _require_context_column {
    my ( $ctx, $args, $cond ) = @_;
    defined( my $schema = _require_context_schema(@_) ) || return;

    my $col;
    if ( $ctx->stash('append_grid_column') ) {
        $col = $ctx->stash('append_grid_column');
    } elsif ( my $name = ( $args->{col} || $args->{column} ) ) {
        $col = ( grep { $_->{name} eq $name } @{$schema->{columns}} )[0]
            || return $ctx->error(plugin->translate('No column definition named "[_1]".', $name));
    } elsif ( defined ( my $index = $args->{index} ) ) {
        $col = $schema->{columns}->[$index]
            || return $ctx->error(plugin->translate('No column indexed [_1].', $name));
    }

    $col || return $ctx->error(plugin->translate('No AppendGrid column context. Set column, col or index attribute in [_1] or use [_1] tag inside mt:AppendGridColumns.'), $ctx->stash('tag'));
}

sub _require_context_row {
    my ( $ctx, $args, $cond ) = @_;
    defined( my $data = _require_context_data(@_) ) || return;
    return '' if ref $data ne 'ARRAY';

    my $row;
    if ( defined $args->{row} ) {
        $row = $data->[int($args->{row})] || return '';
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
    return '' if ref $row ne 'HASH';

    my $cell;
    my $col;
    if ( defined( $col = ( $args->{col} || $args->{column} ) ) ) {
        $cell = $row->{$col};
    } elsif ( $col = $ctx->stash('append_grid_column') ) {
        $cell = $row->{$col->{name}};
    } else {
        return $ctx->error(plugin->translate('Use mt:[_1] tag with col attribute or inside mt:AppendGridColumns.', $ctx->stash('tag')));
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

    local $vars->{__array__} = $array;
    local $vars->{__stashing__} = $stash;
    local $vars->{__size__} = $size;

    for( my $i = 0; $i < $size; $i++ ) {
        my $item = $array->[$i];
        my $vars = {};

        $vars = $item->{__vars__}
            if ref $item eq 'HASH' && ref $item->{__vars__} eq 'HASH';

        local $ctx->{__stash}->{$stash} = $item;
        local $vars->{__index__} = $i;
        local $vars->{__first__} = ( $i == 0 )? 1: 0;
        local $vars->{__last__} = ( $i == $size-1 )? 1: 0;
        local $vars->{__odd__} = ( $i % 2 ) == 1;
        local $vars->{__even__} = ( $i % 2 ) == 0;
        local $vars->{__counter__} = $i;
        local @{ $ctx->{__stash}->{vars} }{ keys %$vars } = values %$vars;

        defined( my $partial = $builder->build($ctx, $tokens, $cond) ) || return;
        $result .= $partial;
    }

    $result;
}

sub _hdlr_AppendGridOffset {
    my ( $offset, $ctx, $args, $cond ) = @_;
    my $vars = $ctx->{__stash}{vars} ||= {};
    my $stashing = $vars->{__stashing__} || return $ctx->error(plugin->translate('Not in AppendGrid loop context.'));

    my $array = $vars->{__array__} || return $ctx->error(plugin->translate('Not in AppendGrid loop context.'));
    return $ctx->error(plugin->translate('Not in AppendGrid loop context.')) unless ref $array eq 'ARRAY';

    my $counter = $vars->{__counter__};
    return $ctx->error(plugin->translate('Not in AppendGrid loop context.')) unless defined($counter);
    return $ctx->error(plugin->translate('Not in AppendGrid loop context.')) unless ref $counter eq '';

    my $i = int($counter) + int($offset);
    my $value = $array->[$i] || return '';
    my $size = $vars->{__size__};

    local $ctx->{__stash}{$stashing} = $value;
    local $vars->{__first__} = ( $i == 0 )? 1: 0;
    local $vars->{__last__} = ( $i == $size-1 )? 1: 0;
    local $vars->{__odd__} = ( $i % 2 ) == 1;
    local $vars->{__even__} = ( $i % 2 ) == 0;
    local $vars->{__counter__} = $i;

    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');
    defined( my $res = $builder->build($ctx, $tokens, $cond) )
        || return $ctx->error($builder->errstr);

    $res;
}

sub hdlr_AppendGridPrevious {
    _hdlr_AppendGridOffset( -1, @_ );
}

sub hdlr_AppendGridNext {
    _hdlr_AppendGridOffset( +1, @_ );
}

sub hdlr_AppendGrid {
    my ( $ctx, $args, $cond ) = @_;

    my ( $schema, $data );
    defined( $schema = _context_schema(@_) ) || return;
    defined( $data = _context_data(@_) ) || return;

    local $ctx->{__stash}->{append_grid_schema} = $schema;
    local $ctx->{__stash}->{append_grid_data} = $data;

    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');
    defined( my $partial = $builder->build($ctx, $tokens, $cond) ) || return;

    $partial;
}

sub hdlr_AppendGridColumns {
    my ( $ctx, $args, $cond ) = @_;

    defined( my $schema = _require_context_schema(@_) ) || return;

    local $ctx->{__stash}->{append_grid_schema} = $schema;
    _basic_loop($schema->{columns}, 'append_grid_column', @_);
}

sub hdlr_AppendGridColumn {
    my ( $ctx, $args ) = @_;
    defined( my $column = _require_context_column(@_) ) || return;

    my $key = $args->{key} || $args->{attr}
        || return $ctx->error(plugin->translate('mt:[_1] template tag requires at least one of [_2] as attributes.', $ctx->stash('tag'), 'key, attr'));

    my $value = $column->{$key};
    $value = '' unless defined $value;

    $value;
}

sub hdlr_AppendGridRows {
    my ( $ctx, $args, $cond ) = @_;
    defined( my $data = _require_context_data(@_) ) || return;

    my $prefix;
    if ( defined($args->{vars}) ) {
        $prefix = $args->{vars};
        if ( $prefix eq '0' ) {
            $prefix = undef;
        } else {
            $prefix = 'appendgrid' if $prefix eq '1';
            $prefix .= '_' if $prefix ne '';
        }

        if ( defined($prefix) ) {
            foreach my $hash ( @$data ) {
                delete $hash->{__vars__};

                my %vars;
                foreach my $key ( keys %$hash ) {
                    $vars{$prefix . $key} = $hash->{$key};
                }
                $hash->{__vars__} = \%vars;
            }
        }
    }

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

sub hdlr_IfAppendGridCustomField {
    my ( $ctx, $args, $cond ) = @_;
    my $schema = _context_schema(@_);
    $schema ? 1 : 0;
}

sub hdlr_AppendGridBuild {
    my ( $ctx, $args ) = @_;
    my ( $schema, $data );

    local $ctx->{__stash}{append_grid_data} = $data = _context_data(@_) || return '';
    local $ctx->{__stash}{append_grid_schema} = $schema = _context_schema(@_);

    if ( $args->{module} || $args->{widget} || $args->{name} || $args->{file} || $args->{identifier} ) {
        return $ctx->invoke_handler('include', $args );
    } elsif ( $schema && $schema->{mtTemplate} ) {
        my $builder = $ctx->stash('builder');
        my $tokens = $builder->compile($ctx, $schema->{mtTemplate});
        defined( my $res = $builder->build($ctx, $tokens) )
            || return $ctx->error($builder->errstr);

        return $res;
    }

    '';
}

sub hdlr_AppendGridRowGroups {
    my ( $ctx, $args, $cond ) = @_;
    my $group_by = $args->{group_by} || $args->{by}
        || return $ctx->error(plugin->translate('mt:[_1] template tag requires [_2] attribute.', $ctx->stash('tag'), 'group_by'));
    defined( my $data = _require_context_data(@_) ) || return;

    my $current = '';
    my $group;
    my @groups;
    foreach my $row ( @$data ) {
        my $value = $row->{$group_by};
        $value = '' unless defined $value;
        if ( !defined($group) || $current ne $value ) {
            push @groups, $group if $group;
            $group = [];
        }
        push @$group, $row;
        $current = $row->{$group_by};
        $current = '' unless defined $current;
    }
    push @groups, $group if $group;

    local $ctx->{__stash}->{append_grid_group_by} = $group_by;
    _basic_loop(\@groups, 'append_grid_data', @_);
}

sub hdlr_AppendGridRowGroup {
    my ( $ctx, $args ) = @_;

    defined( my $group = _require_context_data(@_) ) || return;
    my $group_by = $ctx->{__stash}->{append_grid_group_by}
        || return $ctx->error(plugin->translate('Use mt:[_1] template tag inside [_2] template tag.', $ctx->stash('tag'), 'AppendGridGroups'));

    if ( $group && ref $group eq 'ARRAY' && @$group ) {
        return $group->[0]->{$group_by};
    }

    '';
}

1;