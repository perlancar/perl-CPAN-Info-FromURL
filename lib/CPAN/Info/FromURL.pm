package CPAN::Info::FromURL;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(extract_info_from_cpan_url);

our %SPEC;

our $re_author   = qr/(?:\w+)/;
our $re_dist     = qr/(?:\w+(?:-\w+)*)/;
our $re_mod      = qr/(?:\w+(?:::\w+)*)/;
our $re_version  = qr/(?:v?[0-9]+(?:\.[0-9]+)*(?:_[0-9]+|-TRIAL)?)/;
our $re_end_or_q = qr/(?:[?&]|\z)/;

$SPEC{extract_info_from_cpan_url} = {
    v => 1.1,
    summary => 'Extract information from a CPAN-related URL',
    description => <<'_',

Return a hash of information from some CPAN-related URL. Possible keys include:
`site` (site nickname, include: `mcpan` [metacpan.org, api.metacpan.org], `sco`
[search.cpan.org], `cpanratings` [cpanratings.perl.org]), `author` (CPAN author
ID), `module` (module name), `dist` (distribution name), `version` (distribution
version). Some keys might not exist, depending on what information the URL
provides. Return undef if URL is not detected to be of some CPAN-related URL.

_
    args => {
        url => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result => {
        schema => 'hash',
    },
    result_naked => 1,
    examples => [

        {
            name => "mcpan/pod/MOD",
            args => {url=>'https://metacpan.org/pod/Foo::Bar'},
            result => {site=>'mcpan', module=>'Foo::Bar'},
        },
        {
            name => "mcpan/module/MOD",
            args => {url=>'https://metacpan.org/module/Foo?'},
            result => {site=>'mcpan', module=>'Foo'},
        },
        {
            name => "mcpan/pod/release/AUTHOR/DIST-VERSION/lib/MOD.pm",
            args => {url=>'http://metacpan.org/pod/release/SRI/Mojolicious-6.46/lib/Mojo.pm'},
            result => {site=>'mcpan', author=>'SRI', dist=>'Mojolicious', version=>'6.46', module=>'Mojo'},
        },
        {
            name => "mcpan/source/AUTHOR/DIST-VERSION/lib/MOD.pm",
            args => {url=>'http://metacpan.org/source/SRI/Mojolicious-6.46/lib/Mojo.pm?'},
            result => {site=>'mcpan', author=>'SRI', dist=>'Mojolicious', version=>'6.46', module=>'Mojo'},
        },
        {
            name => "api.mcpan/source/AUTHOR/DIST-VERSION",
            args => {url=>'http://api.metacpan.org/source/SRI/Mojolicious-6.46?'},
            result => {site=>'mcpan', author=>'SRI', dist=>'Mojolicious', version=>'6.46'},
        },
        {
            name => 'mcpan/release/DIST',
            args => {url=>'https://metacpan.org/release/Foo-Bar'},
            result => {site=>'mcpan', dist=>'Foo-Bar'},
        },
        {
            name => 'mcpan/release/AUTHOR/DIST-VERSION',
            args => {url=>'https://metacpan.org/release/FOO/Bar-1.23'},
            result => {site=>'mcpan', author=>'FOO', dist=>'Bar', version=>'1.23'},
        },
        {
            name => 'mcpan/author/AUTHOR',
            args => {url=>'https://metacpan.org/author/FOO'},
            result => {site=>'mcpan', author=>'FOO'},
        },
        {
            name => 'mcpan/changes/distribution/DIST',
            args => {url=>'https://metacpan.org/changes/distribution/Module-XSOrPP'},
            result => {site=>'mcpan', dist=>'Module-XSOrPP'},
        },
        {
            name => 'mcpan/requires/distribution/DIST',
            args => {url=>'https://metacpan.org/requires/distribution/Module-XSOrPP?sort=[[2,1]]'},
            result => {site=>'mcpan', dist=>'Module-XSOrPP'},
        },

        {
            args => {url=>'http://search.cpan.org/~unera/DR-SunDown-0.02/lib/DR/SunDown.pm'},
            result => 'DR::SunDown',
        },
        {
            args => {url=>'https://search.cpan.org/~sri/Mojolicious-6.47/lib/Mojo.pm'},
            result => 'Mojo',
        },

        # search.cpan.org/dist/DIST
        {
            args => {url=>'http://search.cpan.org/dist/Foo-Bar/'},
            result => 'Foo::Bar',
        },

        # search.cpan.org/perldoc?MOD
        {
            args => {url=>'http://search.cpan.org/perldoc?Foo::Bar'},
            result => 'Foo::Bar',
        },
        {
            args => {url=>'http://search.cpan.org/perldoc?Foo'},
            result => 'Foo',
        },

        # search.cpan.org/search?mode=module&query=MOD
        {
            args => {url=>'http://search.cpan.org/search?mode=module&query=DBIx%3A%3AClass'},
            result => 'DBIx::Class',
        },

        # UNKNOWN
        {
            args => {url=>'https://www.google.com/'},
            result => undef,
        },
    ],
};
sub extract_info_from_cpan_url {
    my $url = shift;

    my $res;

    # metacpan
    if ($url =~ s!\Ahttps?://(api\.)?metacpan\.org/?!!i) {
        $res->{site} = 'mcpan';
        # note: /module is the old URL. /pod might misreport a script as a
        # module, e.g. metacpan.org/pod/cpanm.
        if ($url =~ m!\A(?:pod|module)/
                      ($re_mod)(?:[?&]|\z)!x) {
            $res->{module} = $1;
        } elsif ($url =~ m!\A(?:pod/release/|source/)
                           ($re_author)/($re_dist)-($re_version)/lib/((?:[^/]+/)*\w+)\.(?:pm|pod)
                           $re_end_or_q!x) {
            $res->{author} = $1;
            $res->{dist} = $2;
            $res->{version} = $3;
            $res->{module} = $4; $res->{module} =~ s!/!::!g;
        } elsif ($url =~ m!\A(?:pod/release/|source/)
                           ($re_author)/($re_dist)-($re_version)/?
                           $re_end_or_q!x) {
            $res->{author} = $1;
            $res->{dist} = $2;
            $res->{version} = $3;
        } elsif ($url =~ m!\Arelease/
                           ($re_dist)/?
                           $re_end_or_q!x) {
            $res->{dist} = $1;
        } elsif ($url =~ m!\Arelease/
                           ($re_author)/($re_dist)-($re_version)/?
                           $re_end_or_q!x) {
            $res->{author} = $1;
            $res->{dist} = $2;
            $res->{version} = $3;
        } elsif ($url =~ m!\A(?:changes|requires)/distribution/
                           ($re_dist)/?
                           $re_end_or_q!x) {
            $res->{dist} = $1;
        } elsif ($url =~ m!\Aauthor/
                           ($re_author)/?
                           $re_end_or_q!x) {
            $res->{author} = $1;
        }
    } elsif ($url =~ s!\Ahttps?://search\.cpan\.org/?!!i) {
        $res->{site} = 'sco';
    }

    $res;
}

=begin comment

if ($url =~ m!\Ahttps?://search\.cpan\.org/~[^/]+/[^/]+/lib/((?:[^/]+/)*\w+).pm\z!) {
        my $mod = $1;
        $mod =~ s!/!::!g;
        return $mod;
    }

    if ($url =~ m!\Ahttps?://search\.cpan\.org/dist/([A-Za-z0-9_-]+)/?\z!) {
        my $mod = $1;
        $mod =~ s!-!::!g;
        return $mod;
    }

    if ($url =~ m!\Ahttps?://search\.cpan\.org/perldoc\?(\w+(?:::\w+)*)\z!) {
        return $1;
    }

    # used by perlmonks.org
    {
        if ($url =~ m!\Ahttps?://search\.cpan\.org/search\?mode=module&query=(.+)\z!) {
            require URI::Escape;
            my $mod = URI::Escape::uri_unescape($1);
            last unless $mod =~ /\A\w+(::\w+)*\z/;
            return $mod;
        }
    }

    undef;
}

=end comment

1;
# ABSTRACT:

=head1 SEE ALSO

L<CPAN::Module::FromURL>, an earlier module that will be modified to be based on
this module.
