use strict;
use warnings;
use Test::More;
use File::Spec;
use Acme::CPANAuthors::MetaSyntactic;

plan skip_all => 'these tests are for release candidate testing'
    if !$ENV{RELEASE_TESTING};

eval "use CPAN::Common::Index::LocalPackage; 1"
    or plan skip_all =>
    "CPAN::Common::Index::LocalPackage required for testing authors list";

plan tests => 1;

# try to get a 02packages.details.txt.gz from somewhere
# locations found in CPAN.pm, and my local installations
my $details;
{
    my @dirs;
    eval "use File::HomeDir; 1" and do {
        push @dirs, File::HomeDir->my_data, File::HomeDir->my_home;
    };
    push @dirs, $ENV{HOME} if $ENV{HOME};
    push @dirs, File::Spec->catpath($ENV{HOMEDRIVE}, $ENV{HOMEPATH}, '')
      if $ENV{HOMEDRIVE} && $ENV{HOMEPATH};
    push @dirs, $ENV{USERPROFILE} if $ENV{USERPROFILE};
    @dirs
        = map +( "$_/.cpan/sources/modules", "$_/.cpanplus",
        "$_/.cpanm/sources/*" ),
        grep defined, @dirs;
    my @candidates =
        sort { (stat$b)[9] <=> (stat$a)[9] }
        map glob(  "$_/02packages.details.txt*" ), @dirs;
    $details = shift @candidates;
}

diag "Reading packages from $details";
my $index = CPAN::Common::Index::LocalPackage->new( { source => $details } );

# get both lists
my %seen;
my @current = sort keys %{ Acme::CPANAuthors::MetaSyntactic->authors };
my @latest  = sort grep !$seen{$_}++,
    map { $_->{uri} =~ m{cpan:///distfile/([A-Z]+)/} }
    $index->search_packages( { package => qr{^Acme::MetaSyntactic::[a-z]} } );

# compare both lists
my $ok = is_deeply( \@current, \@latest, "The list is complete" );

if ( !$ok ) {
    %seen = ();
    $seen{$_}++ for @latest;
    $seen{$_}-- for @current;
    diag "The list of Acme::MetaSyntactic themes authors has changed:";
    diag( $seen{$_} > 0 ? "+ $_" : "- $_" )
        for grep $seen{$_}, sort keys %seen;
}
