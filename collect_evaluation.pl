#!/usr/bin/env perl
# Parses prototext output from Milan's evaluator. Stores the key-value pairs in a hash.
# Copyright © 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');
use Getopt::Long;
use dzsys; # Dan's library for file system operations



my $metric = 'total-LAS-F1';
GetOptions
(
    'metric=s' => \$metric
);



my %cities =
(
    'C2L2'     => 'Cornell, Ithaca',
    'IMS'      => 'Stuttgart',
    'HIT-SCIR' => 'Harbin',
    'LATTICE'  => 'Paris',
    'Koc-University' => 'İstanbul',
    'Orange-Deskin'  => 'Lannion',
    'darc'     => 'Tübingen',
    'TurkuNLP' => 'Turku',
    'MQuni'    => 'Sydney',
    'IIT-Kharagpur'  => 'Kharagpur',
    'conll17-baseline' => 'Praha',
    'RACAI'    => 'Bucureşti',
    'LyS-FASTPARSE' => 'A Coruña',
    'Uppsala'  => 'Uppsala',
    'ParisNLP' => 'Paris',
    'Wanghao-ftd-SJTU' => 'Shanghai',
    'UParse'   => 'Edinburgh',
    'MetaRomance' => 'Santiago de Compostela',
    'TRL'      => 'Tokyo',
    'fbaml'    => 'Palo Alto'
);



# The output of the test runs is mounted in the master VM at this point:
my $testpath = '/media/conll17-ud-test-2017-05-09';
my @teams = dzsys::get_subfolders($testpath);
my @results;
foreach my $team (@teams)
{
    my $teampath = "$testpath/$team";
    my @runs = dzsys::get_subfolders($teampath);
    foreach my $run (@runs)
    {
        my $runpath = "$teampath/$run";
        if (-f "$runpath/output/evaluation.prototext")
        {
            my $hash = read_prototext("$runpath/output/evaluation.prototext");
            if ($hash->{'total-LAS-F1'} > 0)
            {
                $hash->{team} = $team;
                $hash->{erun} = $run;
                push(@results, $hash);
            }
        }
    }
}
@results = sort {$b->{$metric} <=> $a->{$metric}} (@results);
my %teammap;
foreach my $result (@results)
{
    next if (exists($teammap{$result->{team}}));
    $teammap{$result->{team}}++;
    my $name = substr($result->{team}.' ('.$cities{$result->{team}}.')'.(' 'x40), 0, 40);
    printf("%s\t%s\t%5.2f\n", $name, $result->{erun}, $result->{$metric});
}



#------------------------------------------------------------------------------
# Parses prototext output from Milan's evaluator. Stores the key-value pairs in
# a hash.
#------------------------------------------------------------------------------
sub read_prototext
{
    # Path to the prototext file:
    my $path = shift;
    open(FILE, $path) or die("Cannot read $path: $!");
    my %hash;
    my $key;
    while(<FILE>)
    {
        if (m/key:\s*"([^"]*)"/) # "
        {
            $key = $1;
        }
        elsif (m/value:\s*"([^"]*)"/) # "
        {
            my $value = $1;
            if (defined($key))
            {
                $hash{$key} = $value;
                $key = undef;
            }
        }
    }
    close(FILE);
    return \%hash;
}
