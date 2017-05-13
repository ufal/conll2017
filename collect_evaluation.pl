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
    'fbaml'    => 'Palo Alto',
    'Stanford' => 'Stanford',
    'Recurrent-Team' => 'Pittsburgh',
    'C2L2'     => 'Ithaca',
    'LyS-FASTPARSE' => 'A Coruña',
    'MetaRomance' => 'Santiago de Compostela',
    'UParse'   => 'Edinburgh',
    'Orange-Deskin' => 'Lannion',
    'ParisNLP' => 'Paris',
    'LATTICE'  => 'Paris',
    'CLCL'     => 'Genève',
    'IMS'      => 'Stuttgart',
    'darc'     => 'Tübingen',
    'conll17-baseline' => 'Praha',
    'Uppsala'  => 'Uppsala',
    'TurkuNLP' => 'Turku',
    'UT'       => 'Tartu',
    'RACAI'    => 'Bucureşti',
    'Koc-University' => 'İstanbul',
    'METU'     => 'Ankara',
    'IIT-Kharagpur'  => 'Kharagpur',
    'HIT-SCIR' => 'Harbin',
    'Wenba-NLU' => 'Wuhan',
    'Wanghao-ftd-SJTU' => 'Shanghai',
    'ECNU'     => 'Shanghai',
    'Mengest'  => 'Shanghai',
    'TRL'      => 'Tokyo',
    'MQuni'    => 'Sydney',
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
                # Get the identifier of the evaluated ("input") run.
                my $irunline = `grep inputRun $runpath/run.prototext`;
                if ($irunline =~ m/inputRun:\s*"([^"]*)"/) # "
                {
                    $hash->{srun} = $1;
                    # Get the identifier of the software that generated the input run.
                    my $swline = `grep softwareId $teampath/$hash->{srun}/run.prototext`;
                    if ($swline =~ m/softwareId:\s*"([^"]*)"/) # "
                    {
                        $hash->{software} = $1;
                    }
                }
                push(@results, $hash);
            }
        }
    }
}
@results = sort {$b->{$metric} <=> $a->{$metric}} (@results);
my %teammap;
my $i = 0;
foreach my $result (@results)
{
    next if (exists($teammap{$result->{team}}));
    $i++;
    $teammap{$result->{team}}++;
    my $name = substr($result->{team}.' ('.$cities{$result->{team}}.')'.(' 'x40), 0, 40);
    # If we are showing the total metric, also report whether all partial numbers are non-zero.
    my $tag = '';
    if ($metric eq 'total-LAS-F1')
    {
        $tag = ' [OK]';
        my @keys = grep {m/-LAS-F1$/} (keys(%{$result}));
        if (scalar(@keys) < 81)
        {
            $tag = ' ['.scalar(@keys).']';
        }
        else
        {
            foreach my $key (@keys)
            {
                if ($key =~ m/-LAS-F1$/)
                {
                    if ($result->{$key}==0)
                    {
                        $tag = ' [!!]';
                        last;
                    }
                }
            }
        }
    }
    printf("%2d. %s\t%s\t%5.2f%s\t%s => %s\n", $i, $name, $result->{software}, $result->{$metric}, $tag, $result->{srun}, $result->{erun});
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
