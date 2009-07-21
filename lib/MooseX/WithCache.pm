# $Id: WithCache.pm 31342 2009-03-18 12:01:10Z daisuke $

package MooseX::WithCache;
use Moose;
use Moose::Exporter;
use 5.008;
our $VERSION   = '0.00005';
our $AUTHORITY = 'cpan:DMAKI';

Moose::Exporter->setup_import_methods(
    with_caller => [ 'with_cache' ]
);

no Moose;
no Moose::Exporter;

my %BACKENDS;

sub with_cache {
    my ($caller, $name, %args) = @_;

    # backend is the actual cache backend. this is the main guy that
    # does the cache-aware  meta protocol munging.
    # we
    my $backend_class = $args{backend} || 'Cache::Memcached';
    my $module = "MooseX::WithCache::Backend::$backend_class";

    my $backend = $BACKENDS{ $module };
    if (! $backend) {
        Class::MOP::load_class($module);
        $backend = $module->new();
        $BACKENDS{ $module } = $backend;
    }
    $backend->setup({ %args, cache_name => $name, package => $caller });
}

1;

__END__

=head1 NAME

MooseX::WithCache - Easy Cache Access From Moose Objects

=head1 SYNOPSIS

    package MyObject;
    use Moose;
    use MooseX::WithCache;

    with_cache 'cache' => (
        backend => 'Cache::Memcached',
    );

    no Moose;

    sub get_foo {
        my $self = shift;
        my $foo = $self->cache_get( 'foo' );
        if ($foo) {
            $foo = $self->get_froo_from_database();
            $self->cache_set(foo => $foo);
        }
        return $foo;
    }

    # main.pl
    my $object = MyObject->new(
        cache => Cache::Memcached->new({ ... })
    );

    my $foo = $object->get_foo();

    # if you want to do something with the cache object,
    # you can access it via the name you gave in with_cache
    my $cache = $object->cache;

=head1 DESCRIPTION

MooseX::WithCache gives your object instant access to cache objects.

MooseX::WithCache s not a cache object, it just gives your convinient methods
to access the cache through your objects.

By default, it gives you 3 methods:

    cache_get($key)
    cache_set($key, $value, $expires)
    cache_del($key)

But if there's a backend provided for it, you may get extra methods tailored
for that cache. For example, for Cache::Memcached, the backend provides
these additional methods:

    cache_get_multi(@keys);
    cache_incr($key);
    cache_decr($key);

=head2 STOP THAT CACHE

Data extraction/injection to the cache can be disabled. Simply set 
the cache_disabled() attribute that gets installed

    $object->cache_disabled(1);
    $object->cache_get($key); # won't even try

=head2 DEBUG OUTPUT

You can inspect what's going on with respect to the cache, if you specify
MOOSEX_WITHCACHE_DEBUG=1 in the environment. This will caue MooseX::WithCache to
display messages to STDERR.

=head2 KEY GENERATION

Sometimes you want to give compound keys, or simply transform the cache keys
somehow to normalize them.

MooseX::WithCache supports this through the cache_key_generator attribute.
The cache_key_generator simply needs to be a MooseX::WithCache::KeyGenerator
instance, which accepts whatever key provided, and returns a new key.

For example, if you want to provide complex key that is a perl structure,
and use its MD5 as the key, you can use MooseX::WithCache::KeyGenerator::DumpChecksum
to generate the keys.

Simply specify it in the constructor:

    MyObject->new(
        cache => ...,
        cache_key_generator => MooseX::WithCache::KeyGenerator::DumpChecksum->new()
    );

=head1 METHODS

=head2 with_cache($name, %opts)

Configures the cache for the object.

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut