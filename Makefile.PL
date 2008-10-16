use strict;
use inc::Module::Install;

name('MooseX-WithCache');
all_from('lib/MooseX/WithCache.pm');

requires('Moose', '0.59');
requires('Moose::Exporter');
requires('Cache::Memcached');
requires('Data::Dumper');
requires('Digest::MD5');

test_requires 'IO::Socket::INET';
test_requires 'Test::More';
test_requires 'Test::Exception';

auto_include_deps;
WriteAll;