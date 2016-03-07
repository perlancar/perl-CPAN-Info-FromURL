package CPAN::Info::FromURL;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(extract_cpan_info_from_url);

our %SPEC;

our $re_proto_http = qr!(?:https?://)!i;
our $re_author   = qr/(?:\w+)/;
our $re_dist     = qr/(?:\w+(?:-\w+)*)/;
our $re_mod      = qr/(?:\w+(?:::\w+)*)/;
our $re_version  = qr/(?:v?[0-9]+(?:\.[0-9]+)*(?:_[0-9]+|-TRIAL)?)/;
our $re_end_or_q = qr/(?:[?&]|\z)/;

$SPEC{extract_cpan_info_from_url} = {
    v => 1.1,
    summary => 'Extract/guess information from a URL',
    description => <<'_',

Return a hash of information from a CPAN-related URL. Possible keys include:
`site` (site nickname, include: `mcpan` [metacpan.org, api.metacpan.org], `sco`
[search.cpan.org], `cpanratings` [cpanratings.perl.org], `rt` ([rt.cpan.org]),
`cpan` [any normal CPAN mirror]), `author` (CPAN author ID), `module` (module
name), `dist` (distribution name), `version` (distribution version). Some keys
might not exist, depending on what information the URL provides. Return undef if
URL is not detected to be of some CPAN-related URL.

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
            args => {url=>'metacpan.org/module/Foo?'},
            result => {site=>'mcpan', module=>'Foo'},
        },
        {
            name => "mcpan/pod/release/AUTHOR/DIST-VERSION/lib/MOD.pm",
            args => {url=>'http://metacpan.org/pod/release/SRI/Mojolicious-6.46/lib/Mojo.pm'},
            result => {site=>'mcpan', author=>'SRI', dist=>'Mojolicious', version=>'6.46', module=>'Mojo'},
        },
        {
            name => "mcpan/pod/release/AUTHOR/DIST-VERSION/bin/SCRIPT",
            args => {url=>'http://metacpan.org/pod/release/PERLANCAR/App-PMUtils-1.23/bin/pmpath'},
            result => {site=>'mcpan', author=>'PERLANCAR', dist=>'App-PMUtils', version=>'1.23', script=>'pmpath'},
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
            name => 'sco/dist/DIST',
            args => {url=>'http://search.cpan.org/dist/Foo-Bar/'},
            result => {site=>'sco', dist=>'Foo-Bar'},
        },
        {
            name => 'sco/perldoc?MOD',
            args => {url=>'http://search.cpan.org/perldoc?Foo::Bar'},
            result => {site=>'sco', module=>'Foo::Bar'},
        },
        {
            name => 'sco/search?mode=module&query=MOD',
            args => {url=>'http://search.cpan.org/search?mode=module&query=DBIx%3A%3AClass'},
            result => {site=>'sco', module=>'DBIx::Class'},
        },
        {
            name => 'sco/~AUTHOR',
            args => {url=>'http://search.cpan.org/~unera?'},
            result => {site=>'sco', author=>'unera'},
        },
        {
            name => 'sco/~AUTHOR/DIST-REL/lib/MOD.pm',
            args => {url=>'http://search.cpan.org/~unera/DR-SunDown-0.02/lib/DR/SunDown.pm'},
            result => {site=>'sco', author=>'unera', dist=>'DR-SunDown', version=>'0.02', module=>'DR::SunDown'},
        },
        {
            name => 'sco/~AUTHOR/DIST-REL/bin/SCRIPT.pm',
            args => {url=>'http://search.cpan.org/~perlancar/App-PMUtils-1.23/bin/pmpath'},
            result => {site=>'sco', author=>'perlancar', dist=>'App-PMUtils', version=>'1.23', script=>'pmpath'},
        },

        {
            name => 'cpan/authors/id/A/AU/AUTHOR',
            args => {url=>'file:/cpan/authors/id/A/AU/AUTHOR?'},
            result => {site=>'cpan', author=>'AUTHOR'},
        },
        {
            name => 'cpan/authors/id/A/AU/AUTHOR/DIST-VERSION.tar.gz',
            args => {url=>'file:/cpan/authors/id/A/AU/AUTHOR/Foo-Bar-1.0.tar.gz'},
            result => {site=>'cpan', author=>'AUTHOR', release=>'Foo-Bar-1.0.tar.gz', dist=>'Foo-Bar', version=>'1.0'},
        },

        {
            name => 'cpanratings/dist/DIST',
            args => {url=>'http://cpanratings.perl.org/dist/Submodules'},
            result => {site=>'cpanratings', dist=>'Submodules'},
        },

        {
            name => 'rt/(Public/)Dist/Display.html?Queue=DIST',
            args => {url=>'https://rt.cpan.org/Dist/Display.html?Queue=Perinci-Sub-Gen-AccessTable-DBI'},
            result => {site=>'rt', dist=>'Perinci-Sub-Gen-AccessTable-DBI'},
        },

        {
            name => 'unknown',
            args => {url=>'https://www.google.com/'},
            result => undef,
        },
    ],
};
sub extract_cpan_info_from_url {
    my $url = shift;

    my $res;

    # metacpan
    if ($url =~ s!\A$re_proto_http?(api\.)?metacpan\.org/?!!i) {

        $res->{site} = 'mcpan';
        # note: /module is the old URL. /pod might misreport a script as a
        # module, e.g. metacpan.org/pod/cpanm.
        if ($url =~ m!\A(?:pod|module)/
                      ($re_mod)(?:[?&]|\z)!x) {
            $res->{module} = $1;
        } elsif ($url =~ s!\A(?:pod/release/|source/)
                           ($re_author)/($re_dist)-($re_version)/?!!x) {
            $res->{author} = $1;
            $res->{dist} = $2;
            $res->{version} = $3;
            if ($url =~ m!\Alib/((?:[^/]+/)*\w+)\.(?:pm|pod)!) {
                $res->{module} = $1; $res->{module} =~ s!/!::!g;
            } elsif ($url =~ m!\A(?:bin|scripts?)/
                               (?:[^/]+/)*
                               (.+?)
                               $re_end_or_q!x) {
                $res->{script} = $1;
            }
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

    } elsif ($url =~ s!\A$re_proto_http?search\.cpan\.org/?!!i) {

        $res->{site} = 'sco';
        if ($url =~ m!\Adist/
                     ($re_dist)/?
                     $re_end_or_q!x) {
            $res->{dist} = $1;
        } elsif ($url =~ m!\Aperldoc\?
                           (.+?)
                           $re_end_or_q!x) {
            require URI::Escape;
            $res->{module} = URI::Escape::uri_unescape($1);
        } elsif ($url =~ m!\Asearch\?!) {
            # used by perlmonks.org
            if ($url =~ m![?&]mode=module(?:&|\z)! && $
                    url =~ m![?&]query=(.+?)(?:&|\z)!) {
                require URI::Escape;
                $res->{module} = URI::Escape::uri_unescape($1);
            } elsif ($url =~ m![?&]mode=dist(?:&|\z)! && $
                    url =~ m![?&]query=(.+?)(?:&|\z)!) {
                require URI::Escape;
                $res->{dist} = URI::Escape::uri_unescape($1);
            } elsif ($url =~ m![?&]mode=author(?:&|\z)! && $
                    url =~ m![?&]query=(.+?)(?:&|\z)!) {
                require URI::Escape;
                $res->{author} = URI::Escape::uri_unescape($1);
            }
        } elsif ($url =~ s!\A~(\w+)/?!!) {
            $res->{author} = $1;
            if ($url =~ s!($re_dist)-($re_version)/?!!) {
                $res->{dist} = $1;
                $res->{version} = $2;
                if ($url =~ m!\Alib/((?:[^/]+/)*\w+)\.(?:pm|pod)!) {
                    $res->{module} = $1; $res->{module} =~ s!/!::!g;
                } elsif ($url =~ m!\A(?:bin|scripts?)/
                                   (?:[^/]+/)*
                                   (.+?)
                                   $re_end_or_q!x) {
                    $res->{script} = $1;
                }
            }
        }

    } elsif ($url =~ s!\A$re_proto_http?cpanratings\.perl\.org/?!!i) {

        $res->{site} = 'cpanratings';
        if ($url =~ m!\Adist/
                     ($re_dist)/?
                     $re_end_or_q!x) {
            $res->{dist} = $1;
        }

    } elsif ($url =~ s!\A$re_proto_http?rt\.cpan\.org/?!!i) {

        $res->{site} = 'rt';
        if ($url =~ m!\A(?:Public/)?Dist/Display\.html!) {
            if ($url =~ m![?&](?:Queue|Name)=(.+?)(?:&|\z)!) {
                require URI::Escape;
                $res->{dist} = URI::Escape::uri_unescape($1);
            }
        }

    } elsif ($url =~ m!/authors/id/(\w)/\1(\w)/(\1\2\w+)
                       (?:/
                           (?:[^/]+/)* # subdir
                           (($re_dist)-($re_version)\.(?:tar\.\w+|tar|zip|tgz|tbz|tbz2))
                       )?
                       $re_end_or_q!ix) {
        $res->{site} = 'cpan';
        $res->{author} = $3;
        if (defined $4) {
            $res->{release} = $4;
            $res->{dist} = $5;
            $res->{version} = $6;
        }
    }
    $res;
}

1;
# ABSTRACT:

=head1 SEE ALSO

L<CPAN::Author::FromURL>

L<CPAN::Dist::FromURL>

L<CPAN::Module::FromURL>

L<CPAN::Release::FromURL>
