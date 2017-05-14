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



my %teams =
(
    'fbaml'       => {'city' => 'Palo Alto'},
    'Stanford'    => {'city' => 'Stanford'},
    'Recurrent-Team' => {'city' => 'Pittsburgh'},
    'C2L2'        => {'city' => 'Ithaca'},
    'LyS-FASTPARSE' => {'city' => 'A Coruña', 'primary' => 'software5'},
    'MetaRomance' => {'city' => 'Santiago de Compostela'},
    'UParse'      => {'city' => 'Edinburgh'},
    'Orange-Deskin' => {'city' => 'Lannion'},
    'ParisNLP'    => {'city' => 'Paris'},
    'LATTICE'     => {'city' => 'Paris'},
    'LIMSI-LIPN'  => {'city' => 'Paris'},
    'CLCL'        => {'city' => 'Genève'},
    'IMS'         => {'city' => 'Stuttgart', 'primary' => 'software2'},
    'darc'        => {'city' => 'Tübingen'},
    'conll17-baseline' => {'city' => 'Praha'},
    'Uppsala'     => {'city' => 'Uppsala'},
    'TurkuNLP'    => {'city' => 'Turku'},
    'UT'          => {'city' => 'Tartu'},
    'RACAI'       => {'city' => 'București'},
    'Koc-University' => {'city' => 'İstanbul'},
    'METU'        => {'city' => 'Ankara'},
    'OpenU-NLP-Lab' => {'city' => "Ra'anana"},
    'IIT-Kharagpur' => {'city' => 'Kharagpur', 'primary' => 'software3'},
    'HIT-SCIR'    => {'city' => 'Harbin'},
    'Wenba-NLU'   => {'city' => 'Wuhan'},
    'Wanghao-ftd-SJTU' => {'city' => 'Shanghai'},
    'ECNU'        => {'city' => 'Shanghai'},
    'Mengest'     => {'city' => 'Shanghai'},
    'NAIST-SATO'  => {'city' => 'Nara'},
    'naistCL'     => {'city' => 'Nara'},
    'TRL'         => {'city' => 'Tokyo'},
    'MQuni'       => {'city' => 'Sydney', 'primary' => 'software2'},
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
                        if ($teams{$team}{primary} eq $hash->{software})
                        {
                            $hash->{software} .= '-P';
                        }
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
    ###!!! Temporarily turn off checking for multiple systems of one team. Show all results.
    next if (0 && exists($teammap{$result->{team}}));
    $i++;
    $teammap{$result->{team}}++;
    my $name = substr($result->{team}.' ('.$teams{$result->{team}}{city}.')'.(' 'x40), 0, 40);
    # If we are showing the total metric, also report whether all partial numbers are non-zero.
    my $tag = '';
    if ($metric eq 'total-LAS-F1')
    {
        $tag = ' [OK]';
        my @keys = grep {m/-LAS-F1$/} (keys(%{$result}));
        my $n = scalar(@keys)-1; # subtracting the macro average
        if ($n < 81)
        {
            $tag = " [$n]";
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
