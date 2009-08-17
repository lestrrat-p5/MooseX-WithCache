#line 1
package SVN::Base;

#line 52

sub import {
    my (undef, $pkg, $prefix, @ignore) = @_;
    no warnings 'uninitialized';
    unless (${"SVN::_${pkg}::ISA"}[0] eq 'DynaLoader') {
	@{"SVN::_${pkg}::ISA"} = qw(DynaLoader);
	eval qq'
package SVN::_$pkg;
require DynaLoader;
bootstrap SVN::_$pkg;
1;
    ' or die $@;
    };

    my $caller = caller(0);

    my $prefix_re = qr/(?i:$prefix)/;
    my $ignore_re = join('|', @ignore);
    for (keys %{"SVN::_${pkg}::"}) {
	my $name = $_;
	next unless s/^$prefix_re//;
	next if $ignore_re && m/$ignore_re/;

	# insert the accessor
	if (m/(.*)_get$/) {
	    my $member = $1;
	    *{"${caller}::$1"} = sub {
		&{"SVN::_${pkg}::${prefix}${member}_".
		      (@_ > 1 ? 'set' : 'get')} (@_)
		  }
	}
	elsif (m/(.*)_set$/) {
	}
	else {
	    *{"${caller}::$_"} = ${"SVN::_${pkg}::"}{$name};
	}
    }

}

#line 111

1;
