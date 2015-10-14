#!/usr/bin/perl

# Reads standard input, scanning it for compiler error messages, and builds a database of results on standard output.
# The results are intended to be fed into a web server for presentation.
use strict;

my @messages;

# Find the top of the repo for a specific file, or return the empty string.
sub find_repo {
    my ($filename) = @_;
    my ($dirname) = $filename =~ /(.*)\//;
    return "" unless -d $dirname;
    my $toplevel = `cd $dirname && git rev-parse --show-toplevel 2>/dev/null`;
    chomp $toplevel;
    return $toplevel;
}

# Make a filename relative to the top source directory if possible, otherwise leave it as-is.
sub make_relative {
    my ($root, $filename) = @_;
    if ($filename eq $root) {
	return ".";
    } elsif  (substr($filename, 0, length($root)) eq $root && substr($filename, length($root), 1) eq "/") {
	return substr($filename, length($root)+1);
    } else {
	return $filename;
    }
}

# Get source line and blame.
sub blame {
    my ($repo, $relname, $linenum) = @_;
    my ($author, $author_time, $summary, $source, $commit);
    open GIT, "(cd $repo && git blame -p -L $linenum,$linenum -- $relname) |" or return;
    while (<GIT>) {
	if (/^author (.*)/) {
	    $author = $1;
	} elsif (/^author-time (\d+)/) {
	    $author_time = $1;
	} elsif (/^summary (.*)/) {
	    $summary = $1;
	} elsif (/^\t(.*)/) {
	    $source = $1;
	} elsif (/^([0-9a-f]{40}) /) {
	    $commit = $1;
	}
    }
    close GIT;

    # Fix author names (some people didn't set their real name before committing)
    my %afix = (dquinlan     => "Dan Quinlan",
		matzke       => "Robb Matzke",
		panas2       => "Thomas Panas",
		saebjornsen1 => "Andreas Saebjornsen",
		willcock2    => "Jeremiah Willcock");
    $author = $afix{$author} || $author;
    return ($commit, $author, $author_time, $summary, $source);
}

# Called when some warning message is encountered.
sub process_message {
    my($filename, $linenum, $optcol, $message) = @_;
    my($repo) = find_repo($filename);
    return unless $repo;
    my($relname) = make_relative($repo,$filename);
    my($commit, $author, $atime, $summary, $source) = blame($repo, $relname, $linenum);
    return unless $commit;

    my $category = "uncategorized";
    if ($message =~ /#warning\b/) {
	$category = "author warning";
    } elsif ($message =~ /\b(defined but not used|unused variable)$/) {
	$category = "unused";
    } elsif ($message =~ /\bcomparison between signed and unsigned\b/) {
	$category = "mixed signed/unsigned";
    } elsif ($message =~ /\benum member .*? duplicates .*? and will be ignored\b/) {
	$category = "duplicate enum value";
    } elsif ($message =~ /\benum is multiply defined\b/) {
	$category = "cut-n-pasted code";
    } elsif ($message =~ /\benumeration value .*? not handled in switch\b/ ||
	     $message =~ /\bcontrol reaches end of non-void function\b/ ||
	     $message =~ /\bmay be used uninitialized\b/) {
	$category = "incomplete coding";
    } elsif ($message =~ /'typedef' was ignored in this declaration\b/ ||
	     $message =~ /\binitialized and declared 'extern'\b/) {
	$category = "ignored";
    } elsif ($message =~ /\bsuggest explicit braces\b/ ||
	     $message =~ /\bsuggest parentheses around\b/) {
	$category = "code improvement suggestion";
    } elsif ($message =~ /\bformat .*? expects type .*? but argument .*? has type\b/) {
	$category = "printf problem";
    } elsif ($message =~ /\bright shift count >= width of type\b/) {
	$category = "undefined behavior";
    } elsif ($message =~ /\bdeprecated conversion from\b/ ||
	     $message =~ /\bis deprecated\b/) {
	$category = "deprecated";
    } elsif ($message =~ /\bwill be initialized after\b/) {
	$category = "constructor problem";
    } elsif ($message =~ /"\/\*" within comment\b/) {
	$category = "dead code turd";
    }
    push @messages, {
	repo     => $repo,
	relname  => $relname,
	linenum  => $linenum,
	optcol   => $optcol,
	message  => $message,
	category => $category,
	commit   => $commit,
	author   => $author,
	atime    => $atime,
	summary  => $summary,
	source   => $source
    };
}

# print the database
sub emit_messages {
    for my $message (@messages) {
	for my $key (qw/repo relname linenum optcol message category commit author atime summary source/) {
	    printf "%-8s = %s\n", $key, $message->{$key};
	}
	print "----\n";
    }
}

###############################################################################################################################
	
while (<STDIN>) {
    if (my($filename, $line, $column, $message) = /(.*?):(\d+):(\d+): warning: (.*)/) {
	process_message($filename, $line, $column, $message);
    } elsif (($filename, $line, $message) = /(.*?):(\d+): warning: (.*)/) {
	process_message($filename, $line, undef, $message);
    }
}
emit_messages;
