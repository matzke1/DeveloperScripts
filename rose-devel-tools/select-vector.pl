#!/usr/bin/perl
use strict;
use JSON;

=head1 NAME

select-vector - select vectors for compiling with boost

=head1 USAGE

$0 [-N] JSON_FILES...

=head1 DESCRIPTION

Reads the JSON files specified on the command-line and computes their intersection. Then uses the intersection
to generate a list of version vectors. Finally selects up to N vectors and prints them to standard output.

=cut

# Validate schema
sub validate {
    my($json,$verbose) = @_;
    die unless 'ARRAY' eq ref $json;
    for my $boost (@{$json}) {
	die unless 'HASH' eq ref $boost;
	die unless exists $boost->{boost}; # boost version number
	print STDERR "boost-", $boost->{boost}, ":\n" if $verbose;
	my $os_list = $boost->{'primary-test-compilers'};
	die unless 'HASH' eq ref $os_list;
	for my $os_name (keys %{$os_list}) {
	    print STDERR "  $os_name:\n" if $verbose;
	    my $compiler_list = $os_list->{$os_name};
	    die unless 'ARRAY' eq ref $compiler_list;
	    for my $compiler (@{$compiler_list}) {
		die unless $compiler->{compiler}; # compiler vendor, like "GCC", "Clang", "Visual C++", etc.
		die unless $compiler->{lang}; # C++ language variant, like "default", "C++11", etc.
		my $version_list = $compiler->{versions};
		print STDERR "    ", $compiler->{compiler}, " ", $compiler->{lang}, ":" if $verbose;
		die unless 'ARRAY' eq ref $version_list;
		die unless @{$version_list} > 0; # need at least one version number
		for my $version (@{$version_list}) {
		    die if ref $version;
		    die unless $version;
		    print STDERR " $version" if $verbose;
		}
		print STDERR "\n" if $verbose;
	    }
	}
    }
    return $json;
}

# Read, parse, and validate a JSON file
sub read_json {
    my($file_name) = @_;
    open JSON, "<", $file_name or die "$file_name: $!\n";
    my $json = decode_json join "", <JSON>;
    close JSON;
    return validate $json;
}

# Compute intersection of two version lists.
sub intersect_versions {
    my($versions1, $versions2) = @_;
    my %intersection;
    $intersection{$_}++ for @{$versions1}, @{$versions2};
    return grep {$intersection{$_}==2} sort keys %intersection;
}

# Compute intersection of two compiler lists.
sub intersect_compilers {
    my($compilers1, $compilers2) = @_;
    my($result) = [];
    for my $compiler1 (@{$compilers1}) {
	for my $compiler2 (@{$compilers2}) {
	    next if $compiler1->{compiler} ne $compiler2->{compiler} || $compiler1->{lang} ne $compiler2->{lang};
	    my @versions = intersect_versions $compiler1->{versions}, $compiler2->{versions};
	    next unless @versions;
	    push @{$result}, $compiler1;
	    @{$result}[-1]->{versions} = \@versions;
	    last;
	}
    }
    return $result;
}

# compute intersection of two boost objects that have the same boost version number.
sub intersect_boost {
    my($boost1, $boost2) = @_;
    my($result) = { boost=>$boost1->{boost}, # version number
		    date =>$boost1->{date},  # dates may differ; arbitrarily use the first one
		    'primary-test-compilers' => {} # operating systems
                  };
    for my $os (keys %{$boost1->{'primary-test-compilers'}}) {
	my $compilers1 = $boost1->{'primary-test-compilers'}{$os};
	my $compilers2 = $boost2->{'primary-test-compilers'}{$os};
	next unless $compilers1 && $compilers2;
	my $compilers = intersect_compilers $compilers1, $compilers2;
	$result->{'primary-test-compilers'}{$os} = $compilers if $compilers;
    }
    return $result;
}

# Compute intersection of two JSON structures. Assume the JSON inputs have been validated.
sub intersect {
    my($json1, $json2) = @_;
    my($result) = [];
    for my $boost1 (@{$json1}) {
	my $found;
	for my $boost2 (@{$json2}) {
	    if ($boost1->{boost} eq $boost2->{boost}) { # compare boost version numbers
		$found = intersect_boost($boost1, $boost2);
		last;
	    }
	}
	push @{$result}, $found if $found;
    }
    return $result;
}

# Generate an array of version vectors. Assumes that the JSON input has been validated.
sub generate_all_vectors {
    my($json) = @_;
    my @result;
    for my $boost (@{$json}) {
	my $os_list = $boost->{'primary-test-compilers'};
	for my $os (keys %{$os_list}) {
	    my $compiler_list = $os_list->{$os};
	    for my $compiler (@{$compiler_list}) {
		my $versions = $compiler->{versions};
		for my $version (@{$versions}) {
		    push @result, {
			boost_version => $boost->{boost},       # boost version number
			os_name       => $os,                   # operating system name
			cxx_vendor    => $compiler->{compiler}, # C++ compiler vendor
			cxx_lang      => $compiler->{lang},     # C++ language variant
			cxx_version   => $version               # C++ compiler version
		    };
		}
	    }
	}
    }
    return @result;
}

# Shuffle the elements of an array
sub shuffle {
    my($aref) = @_;
    my $n = @{$aref};
    for my $i (0 .. $n-1) {
	my $j = int rand $n;
	($aref->[$i], $aref->[$j]) = ($aref->[$j], $aref->[$i]);
    }
}


########################################################################################################################

my $max_output;
while (@ARGV && $ARGV[0] =~ /^-/) {
    if ($ARGV[0] eq '--') {
	shift @ARGV;
	last;
    } elsif ($ARGV[0] =~ /^-(\d+)$/) {
	$max_output = $1;
	shift @ARGV;
    } elsif ($ARGV[0] =~ /^(-h|--help)$/) {
	system "perldoc", $0;
	exit 0
    } elsif ($ARGV[0] =~ /^-/) {
	die "unknown switch \"$ARGV[0]\"; see --help\n";
    } else {
	last;
    }
}
die "incorrect usage; see --help\n" unless @ARGV;


# Read all JSON files mentioned on the command line and compute their intersection
my $intersection = read_json shift @ARGV;
for my $file_name (@ARGV) {
    $intersection = intersect $intersection, read_json $file_name;
    last unless $intersection;
}

# Generate vectors
my @vectors = generate_all_vectors validate $intersection;
if (defined $max_output) {
    shuffle \@vectors;
    splice @vectors, $max_output;
}

# Print vectors
for my $vector (@vectors) {
    print join(" ", map {"$_='$vector->{$_}'"} qw/boost_version os_name cxx_vendor cxx_lang cxx_version/), "\n";
}

