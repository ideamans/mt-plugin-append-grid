package MT::AppendGrid::Util;

use strict;
use base qw(Exporter);
use Data::Dumper;
use MT::Util;
use MT::Util::YAML;

our @EXPORT = qw(plugin pp lookup_schema_by_field yaml2hash hash2yaml yaml2json json2hash hash2json json2yaml);

sub plugin {
    MT->component('AppendGrid');
}

sub pp { print STDERR Dumper(@_); }

sub lookup_schema_by_field {
    my ( $ctx, %args ) = @_;
    my $blog = $ctx->stash('blog');
    my @blog_ids = ( 0, $blog ? ($blog->id) : () );

    my $field;
    if ( $args{field} ) {
        $field = $args{field};
    } elsif ( my $basename = $args{basename} ) {
        $field = MT->model('field')->load({
            blog_id     => \@blog_ids,
            basename    => $basename,
        });
    } elsif ( my $tag = $args{tag} ) {
        $field = MT->model('field')->load({
            blog_id     => \@blog_ids,
            tag         => $tag,
        });
    }

    return unless $field;

    if ( $field->type eq 'append_grid_with_schema' ) {
        my $schema = MT->model('append_grid_schema')->load($field->options || 0)
            || return;

        my $hash = $schema->schema_hash;
        $hash->{mtTemplate} ||= $schema->template;
        return $hash;
    } elsif ( $field->type =~ /_yaml$/ ) {
        return yaml2hash($field->options);
    } elsif ( $field->type =~ /_json$/ ) {
        return json2hash($field->options);
    }
}

sub yaml2hash {
    eval { MT::Util::YAML::Load(@_) };
}

sub hash2yaml {
    eval { MT::Util::YAML::Dump(@_) };
}

sub yaml2json {
    eval { hash2json(yaml2hash(@_)) };
}

sub json2hash {
    eval { MT::Util::from_json(@_) };
}

sub hash2json {
    eval { MT::Util::to_json(@_, { pretty => 1 }) };
}

sub json2yaml {
    eval { hash2yaml(json2hash(@_)) };
}

1;