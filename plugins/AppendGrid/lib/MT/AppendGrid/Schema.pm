package MT::AppendGrid::Schema;

use strict;
use base qw( MT::Object );

use MT::Util;
use MT::Util::YAML;
use MT::AppendGrid::Util;

__PACKAGE__->install_properties(
    {   column_defs => {
            'id'          => 'integer not null auto_increment',
            'blog_id'     => 'integer',
            'name'        => 'string(255) not null',
            'description' => 'text',
            'schema_format' => 'string(16)',
            'schema' => 'text',
            'template' => 'text',
        },
        indexes => {
            blog_id  => 1,
            name     => 1,
        },
        primary_key => 'id',
        audit       => 1,
        datasource  => 'append_grid_schema',
        child_of    => [ 'MT::Blog', 'MT::Website' ],
    }
);

sub class_label {
    return plugin->translate("AppendGrid Schema");
}

sub class_label_plural {
    return plugin->translate("AppendGrid Schemas");
}

sub validate_schema_json {
    my $cls = shift;
    my ( $eh, $field_name, $json ) = @_;

    my $schema = eval { MT::Util::from_json($json) };
    return $eh->error(plugin->translate('[_1] is not in a JSON format.', $field_name))
        unless $schema;

    1;
}

sub is_yaml { shift->schema_format eq 'yaml' ? 1 : 0 }
sub is_json { shift->schema_format ne 'yaml' ? 1 : 0 }

sub schema_hash {
    my $obj = shift;
    my ( $hash ) = @_;

    if ( @_ ) {
        if ( $obj->is_yaml ) {
            $obj->schema(hash2yaml($hash));
        } else {
            $obj->schema(hash2json($hash));
        }
    }

    if ( $obj->is_yaml ) {
        yaml2hash($obj->schema);
    } else {
        json2hash($obj->schema);
    }
}

sub schema_json {
    my $obj = shift;
    my ( $json ) = @_;

    if ( @_ ) {
        if ( $obj->is_yaml ) {
            $obj->schema(json2yaml($json));
        } else {
            $obj->schema($json);
        }
    }

    if ( $obj->is_yaml ) {
        yaml2json($obj->schema);
    } else {
        $obj->schema;
    }
}

sub schema_yaml {
    my $obj = shift;
    my ( $yaml ) = @_;

    if ( @_ ) {
        if ( $obj->is_json ) {
            $obj->schema(yaml2json($yaml));
        } else {
            $obj->schema($yaml);
        }
    }

    if ( $obj->is_json ) {
        json2yaml($obj->schema);
    } else {
        $obj->schema;
    }
}

sub set_values {
    my $obj = shift;
    my ( $values ) = @_;

    if ( @_ && ref $values eq 'HASH' ) {
        if ( $values->{schema_format} eq 'yaml' ) {
            $values->{schema} = $values->{schema_yaml};
        } else {
            $values->{schema} = $values->{schema_json};
        }
    }

    $obj->SUPER::set_values(@_);
}

sub validate {
    my $obj = shift;
    my $hash = $obj->schema_hash || return $obj->error(plugin->translate('Schema YAML or JSON is malformed.'));

    1;
}

sub list_props {
    return {
        id => {
            base  => '__virtual.id',
            order => 100,
        },
        name => {
            auto      => 1,
            label     => 'Name',
            order     => 200,
            display   => 'force',
            html_link => sub {
                my ( $prop, $obj, $app ) = @_;
                return $app->uri(
                    mode => 'view',
                    args => { _type => 'append_grid_schema', blog_id => $obj->id, id => $obj->id },
                );
            },
        },
        blog_name => {
            label     => 'Website/Blog Name',
            base      => '__virtual.blog_name',
            order     => 400,
            display   => 'default',
            view      => ['system'],
            bulk_html => sub {
                my $prop     = shift;
                my ($objs)   = @_;
                my %blog_ids = map { $_->blog_id => 1 } @$objs;
                my @blogs    = MT->model('blog')->load(
                    { id => [ keys %blog_ids ], },
                    {   fetchonly => {
                            id        => 1,
                            name      => 1,
                            parent_id => 1,
                        }
                    }
                );
                my %blog_map = map { $_->id        => $_ } @blogs;
                my %site_ids = map { $_->parent_id => 1 }
                    grep { $_->parent_id && !$blog_map{ $_->parent_id } }
                    @blogs;
                my @sites
                    = MT->model('website')
                    ->load( { id => [ keys %site_ids ], },
                    { fetchonly => { id => 1, name => 1, }, } )
                    if keys %site_ids;
                my %urls = map {
                    $_->id => MT->app->uri(
                        mode => 'list',
                        args => {
                            _type   => 'append_grid_schema',
                            blog_id => $_->id,
                        }
                    );
                } @blogs;
                my %blog_site_map = map { $_->id => $_ } ( @blogs, @sites );
                my @out;

                for my $obj (@$objs) {
                    if ( !$obj->blog_id ) {
                        push @out, MT->translate('(system)');
                        next;
                    }
                    my $blog = $blog_site_map{ $obj->blog_id };
                    unless ($blog) {
                        push @out, MT->translate('*Website/Blog deleted*');
                        next;
                    }

                    my $name = undef;
                    if ( ( my $site = $blog_site_map{ $blog->parent_id } )
                        && $prop->site_name )
                    {
                        $name = join( '/', $site->name, $blog->name );
                    }
                    else {
                        $name = $blog->name;
                    }

                    push @out,
                          '<a href="'
                        . $urls{ $blog->id } . '">'
                        . encode_html($name) . '</a>';
                }

                return @out;
            },
        },
        created_on => {
            base    => '__virtual.created_on',
            display => 'default',
            order   => 500,
        },
        modified_on => {
            base  => '__virtual.modified_on',
            order => 600,
        },
        description => {
            auto    => 1,
            display => 'default',
            label   => 'Description',
        },
    };
}

1;