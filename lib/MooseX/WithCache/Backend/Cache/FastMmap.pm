package MooseX::WithCache::Backend::Cache::FastMmap;

use Moose;
use Cache::FastMmap;
use constant DEBUG => $ENV{MOOSEX_WITHCACHE_DEBUG};

extends 'MooseX::WithCache::Backend';

around 'build_method_list' => sub {
    my ($next, $self, @args) = @_;
    my $list = $next->($self, @args);
    push @$list, qw(cache_incr cache_decr);
    return $list;
};

has 'cache_incr_method' => (
    is => 'rw',
    isa => 'Moose::Meta::Method',
);

has 'cache_decr_method' => (
    is => 'rw',
    isa => 'Moose::Meta::Method',
);

override(
    'build_cache_del_method',
    sub {
        my ($self, $args) = @_;
        my $name = $args->{cache_name}; 
        return Moose::Meta::Method->wrap(
            name => 'cache_del',
            package_name => ref $self,
            body => sub {
                my ($self, $key) = @_;
                my $cache = $self->$name;
                if ($self->cache_disabled || ! $cache) {
                    if (DEBUG) {
                        $self->cache_debug("cache_set: Cache disabled");
                    }
                    return (); 
                }

                my $keygen = $self->cache_key_generator;
                my $cache_key = $keygen ? $keygen->generate($key) : $key;
                if (DEBUG) {
                    $self->cache_debug(
                        "cache_del: key =",
                        ($cache_key || '(null)'),
                    );  
                }
                return $cache->remove($cache_key);
            }
        );
    },
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub install_cache_attr {
    my ($self, $args) = @_;

    my $name = $args->{cache_name};
    my $class = $args->{package};
    my $meta = $class->meta;
    $meta->add_attribute($name => (
        is => 'rw',
        isa => 'Cache::FastMmap',
    ) );
}

sub build_cache_incr_method {
    my ($self, $args) = @_;
    my $name = $args->{cache_name};
    return Moose::Meta::Method->wrap(
        name => 'cache_incr',
        package_name => ref $self,
        body => sub {
            my ($self, $key) = @_;
            my $cache = $self->$name;
            if ($self->cache_disabled || ! $cache) {
                if (DEBUG) {
                    $self->cache_debug("cache_incr: Cache disabled");
                }
                return ();
            }

            my $keygen = $self->cache_key_generator;
            my $cache_key = $keygen ? $keygen->generate($key) : $key;
            return $cache->get_and_set( $cache_key, sub { ++$_[1] } );
        }
    );
}

sub build_cache_decr_method {
    my ($self, $args) = @_;
    my $name = $args->{cache_name};
    return Moose::Meta::Method->wrap(
        name => 'cache_decr',
        package_name => ref $self,
        body => sub {
            my ($self, $key) = @_;
            my $cache = $self->$name;
            if ($self->cache_disabled || ! $cache) {
                if (DEBUG) {
                    $self->cache_debug("cache_decr: Cache disabled");
                }
                return ();
            }

            my $keygen = $self->cache_key_generator;
            my $cache_key = $keygen ? $keygen->generate($key) : $key;
            return $cache->get_and_set( $cache_key, sub { --$_[1] } );
        }
    );
}

1;

__END__

=head1 NAME

MooseX::WithCache::Backend::Cache::FastMmap - Cache::FastMmap Backend

=head1 SYNOPSIS

    package MyObject;
    use MooseX::WithCache;
    with_cache(
        backend => 'Cache::FastMmap'
    );

    package main;

    my $obj = MyObject->new(
        cache => Cache::FastMmap->new({ ... });
    );

    $obj->cache_get($key);
    $obj->cache_set($key);
    $obj->cache_del($key);
    $obj->cache_incr($key);
    $obj->cache_decr($key);

    # {
    #   results => {
    #       key1 => $cache_hit_value1,
    #       key2 => $cache_hit_value2,
    #       ...
    #   },
    #   missing => [ 'key3', 'key4', 'key5' .... ]
    # }

=head1 METHODS

=head2 build_cache_decr_method

=head2 build_cache_del_method

=head2 build_cache_get_method

=head2 build_cache_incr_method

=head2 build_cache_set_method

=head2 install_cache_attr

=cut
