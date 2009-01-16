# $Id: /mirror/coderepos/lang/perl/MooseX-WithCache/trunk/lib/MooseX/WithCache/Backend/CHI.pm 98638 2009-01-16T05:41:09.754236Z daisuke  $

package MooseX::WithCache::Backend::CHI;
use Moose;
use CHI;
use constant DEBUG => $ENV{MOOSEX_WITHCACHE_DEBUG};

extends 'MooseX::WithCache::Backend';

__PACKAGE__->meta->make_immutable;

no Moose;

sub install_cache_attr {
    my ($self, $args) = @_;

    my $name = $args->{cache_name};
    my $class = $args->{package};
    my $meta = $class->meta;
    $meta->add_attribute($name => (
        is => 'rw',
        isa => 'CHI::Driver',
    ) );
}

sub build_cache_del_method {
    my ($self, $args) = @_;
    my $name = $args->{cache_name};
    return Moose::Meta::Method->wrap(
        name => 'cache_del',
        package_name => ref $self,
        body => sub {
            my ($self, $key) = @_;
            my $cache = $self->$name;
            if (! $cache) {
                return ();
            }

            my $keygen = $self->cache_key_generator;
            my $cache_key = $keygen ? $keygen->generate($key) : $key;
            if (&DEBUG) {
                $self->cache_debug(
                    "cache_del: key =",
                    ($cache_key || '(null)'),
                );
            }
            return $cache->remove($cache_key);
        }
    );
}

1;