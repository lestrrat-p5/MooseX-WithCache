use strict;
use Test::More;
use Test::Exception;
use IO::Socket::INET;
use Moose::Meta::Class;

{
    package Hoge;
    use MooseX::WithCache;
}

BEGIN
{
    my $socket = IO::Socket::INET->new(
        PeerPort => '11211',
        PeerAddr => '127.0.0.1',
    );

    if ($socket) {
        eval { require Cache::Memcached };
        if ( $@ ) {
            plan(skip_all => "no memcached client found");
        } else {
            plan(tests => 11);
        }
    } else {
        plan(skip_all => "no memcached server found");
    }
}

{
    my $class = Moose::Meta::Class->create_anon_class(
        superclasses => [ 'Moose::Object' ]
    );
    
    MooseX::WithCache::with_cache($class->name, 'cache', backed => 'Cache::Memcached');

    my $object = $class->new_object(
        cache => Cache::Memcached->new({
            servers => [ '127.0.0.1:11211' ],
            namespace => join('.', rand(), time, $$, {}),
        }),
    );


    {
        my $value = time();
        my $key   = 'foo';
        lives_ok { $object->cache_del($key) }
            "delete key '$key' first to make sure";
        lives_ok { $object->cache_set($key => $value) }
            "set value '$key' to '$value'";
        lives_and { 
            my $v = $object->cache_get($key);
            is($v, $value, "value gotten from cache '$v' should match '$value'");
        } "get value '$key' to '$value' should live";
        lives_ok { $object->cache_del($key) }
            "delete key '$key' to purge";
    }

    {
        require MooseX::WithCache::KeyGenerator::DumpChecksum;
        $object->key_generator(
            MooseX::WithCache::KeyGenerator::DumpChecksum->new
        );
        my $value = time();
        my $key   = [ qw(1 2 3), { foo => 'bar' } ];
        lives_ok { $object->cache_del($key) }
            "delete key '$key' first to make sure";
        lives_ok { $object->cache_set($key => $value) }
            "set value '$key' to '$value'";
        lives_and { 
            my $v = $object->cache_get($key);
            is($v, $value, "value gotten from cache '$v' should match '$value'");
        } "get value '$key' to '$value' should live";
        lives_and { 
            my $v = $object->cache_get([ qw(1 2 3), { foo => 'bar' } ]);
            is($v, $value, "value gotten from cache '$v' should match '$value' (same structure, different object)");
        } "get value '$key' to '$value' should live (same structure, different key object)";
        lives_ok { $object->cache_del($key) }
            "delete key '$key' to purge";
    }

    {
        my %data = (
            a => 1,
            b => 2,
            c => 3,
            d => 4
        );

        while(my($key, $value) = each %data) {
            $object->cache_set($key, $value);
        }

        lives_and {
            my @keys = keys %data;
            my @ret  = $object->cache_get_multi(@keys);

            is( scalar @ret, scalar @keys, "got the same number of values" );
            is_deeply( \@ret, [ @data{@keys} ], "data validates" );
        } "get_multi";
    }
}