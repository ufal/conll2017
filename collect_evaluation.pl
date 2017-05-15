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
my $allresults = 0; # display multiple results per team
GetOptions
(
    'metric=s' => \$metric,
    'allresults' => \$allresults
);



# If takeruns is present, it is the sequence of system runs (not evaluation runs) that should be combined.
# Otherwise, we should take the last complete run (all files have nonzero scores) of the primary system.
# If no run is complete and no combination is defined, should we take the best-scoring run of the primary system?
# In any case, the primary system must be defined. We shall not just take the best-scoring one.
my %teams =
(
    'fbaml'       => {'city' => 'Palo Alto'},
    'fbaml2'      => {'city' => 'Palo Alto'},
    'Stanford'    => {'city' => 'Stanford'},
    'UALING'      => {'city' => 'Tucson'},
    'Recurrent-Team' => {'city' => 'Pittsburgh'},
    'C2L2'          => {'city' => 'Ithaca', 'primary' => 'software5', 'takeruns' => ['2017-05-12-09-27-46']}, # evaluator run: 2017-05-12-17-36-03
    'LyS-FASTPARSE' => {'city' => 'A Coruña', 'primary' => 'software5', 'takeruns' => ['2017-05-13-02-21-56']}, # evaluator run: 2017-05-14-10-10-24
    'MetaRomance' => {'city' => 'Santiago de Compostela'},
    'UParse'      => {'city' => 'Edinburgh'},
    'Orange-Deskin' => {'city' => 'Lannion'},
    'ParisNLP'    => {'city' => 'Paris'},
    'LATTICE'     => {'city' => 'Paris'},
    'LIMSI-LIPN'  => {'city' => 'Paris'},
    'CLCL'        => {'city' => 'Genève'},
    'CLCL2'       => {'city' => 'Genève'},
    'IMS'         => {'city' => 'Stuttgart', 'primary' => 'software2', 'takeruns' => ['2017-05-14-18-34-01', '2017-05-14-00-31-18', '2017-05-12-05-46-00']},
        # * From the run software2 2017-05-14-18-34-01: la
        # * From the run software2 2017-05-14-00-31-18: ar, ar_pud, cu, en, et, fr, fr_partut, fr_pud, fr_sequoia, got, grc_proiel, he, ja, ja_pud, la_ittb, la_proiel, nl_lassysmall, sl_sst, vi, zh
        # * From the run software2 2017-05-12-05-46-00: all the rest
        # In other words, take the oldest run (2017-05-12-05-46-00), and then for any test sets with outputs from the two later runs, use those numbers instead.
    'darc'        => {'city' => 'Tübingen'},
    'conll17-baseline' => {'city' => 'Praha'},
    'UFAL-UDPipe-1-2'  => {'city' => 'Praha'},
    'Uppsala'     => {'city' => 'Uppsala'},
    'TurkuNLP'    => {'city' => 'Turku'},
    'UT'          => {'city' => 'Tartu'},
    'RACAI'       => {'city' => 'București'},
    'Koc-University' => {'city' => 'İstanbul'},
    'METU'        => {'city' => 'Ankara'},
    'OpenU-NLP-Lab' => {'city' => "Ra'anana"},
    'IIT-Kharagpur' => {'city' => 'Kharagpur', 'primary' => 'software3', 'takeruns' => ['2017-05-13-17-01-25']},
    'HIT-SCIR'    => {'city' => 'Harbin'},
    'Wenba-NLU'   => {'city' => 'Wuhan'},
    'Wanghao-ftd-SJTU' => {'city' => 'Shanghai'},
    'ECNU'        => {'city' => 'Shanghai'},
    'Mengest'     => {'city' => 'Shanghai'},
    'NAIST-SATO'  => {'city' => 'Nara'},
    'naistCL'     => {'city' => 'Nara'},
    'TRL'         => {'city' => 'Tokyo'},
    'MQuni'       => {'city' => 'Sydney', 'primary' => 'software2', 'takeruns' => ['2017-05-09-20-35-48']} # evaluator run: 2017-05-10-05-14-53
);
# Some teams have multiple virtual machines.
my %secondary =
(
    'fbaml2' => 'fbaml',
    'CLCL2'  => 'CLCL'
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
# If we know what is the primary system of a team, remove results of other systems.
for (my $i = 0; $i <= $#results; $i++)
{
    my $team = $results[$i]{team};
    if (exists($teams{$team}{primary}))
    {
        if ($results[$i]{software} eq $teams{$team}{primary})
        {
            $results[$i]{software} .= '-P';
        }
        else
        {
            splice(@results, $i--, 1);
        }
    }
}
# Create a map from system run ids to corresponding evaluation runs.
my %srun2erun;
foreach my $result (@results)
{
    my $srun = $result->{srun};
    # There may be multiple evaluation runs of the same system runs. Take the first, discard the others.
    unless (exists($srun2erun{$srun}))
    {
        $srun2erun{$srun} = $result;
    }
}
# Combine runs where applicable.
foreach my $team (keys(%teams))
{
    if (exists($teams{$team}{takeruns}) && scalar(@{$teams{$team}{takeruns}}) > 1)
    {
        my $combination = combine_runs($teams{$team}{takeruns});
        push(@results, $combination);
    }
}
# Print the results.
@results = sort {$b->{$metric} <=> $a->{$metric}} (@results);
my %teammap;
my $i = 0;
foreach my $result (@results)
{
    my $uniqueteam = $result->{team};
    $uniqueteam = $secondary{$uniqueteam} if (exists($secondary{$uniqueteam}));
    next if (!$allresults && exists($teammap{$uniqueteam}));
    $i++;
    $teammap{$uniqueteam}++;
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
    my $final = '     ';
    if (exists($teams{$result->{team}}{takeruns}) && scalar(@{$teams{$result->{team}}{takeruns}})==1 && $result->{srun} eq $teams{$result->{team}}{takeruns}[0])
    {
        $final = 'Fin: ';
    }
    my $runs = "$result->{srun} => $result->{erun}";
    # Truncate long lists of combined runs.
    $runs = substr($runs, 0, 50).'...' if (length($runs) > 50);
    printf("%2d. %s\t%s\t%5.2f%s\t%s%s\n", $i, $name, $result->{software}, $result->{$metric}, $tag, $final, $runs);
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



#------------------------------------------------------------------------------
# Combines evaluations of multiple system runs and creates a new virtual
# evaluation run.
#------------------------------------------------------------------------------
sub combine_runs
{
    my $srunids = shift; # ref to list of system run ids
    if (scalar(@{$srunids}) < 2)
    {
        print STDERR ("Warning: Attempting to combine less than 2 runs. Will do nothing.\n");
        return;
    }
    # Find evaluation runs that correspond to the system runs.
    my @eruns;
    foreach my $srun (@{$srunids})
    {
        if (exists($srun2erun{$srun}))
        {
            push(@eruns, $srun2erun{$srun});
        }
        else
        {
            print STDERR ("Warning: No evaluation run for system run $srun.\n");
        }
    }
    return unless (scalar(@eruns) > 1);
    print STDERR ("Combining sruns: ", join(' + ', @{$srunids}), " ($eruns[0]{team})\n");
    print STDERR ("Combining eruns: ", join(' + ', map {$_->{erun}} (@eruns)), " ($eruns[0]{team})\n");
    # Combine the evaluations.
    ###!!! Note that we currently do not check that the combined runs belong to the same software.
    ###!!! In fact we will even combine runs from different teams (actually different VMs of one team).
    my %combination =
    (
        'team'     => $eruns[0]{team},
        'software' => $eruns[0]{software},
        'srun'     => join('+', @{$srunids}),
        'erun'     => join('+', map {$_->{erun}} (@eruns))
    );
    my %sum;
    foreach my $erun (@eruns)
    {
        my @keys = sort(keys(%{$erun}));
        my @sets = map {my $x = $_; $x =~ s/-LAS-F1$//; $x} (grep {m/^(.+)-LAS-F1$/ && $1 ne 'total'} (@keys));
        #print STDERR ("Run $erun->{erun}, ", scalar(@keys), " keys, ", scalar(@sets), " sets.\n");
        foreach my $set (@sets)
        {
            if ((!exists($combination{"$set-LAS-F1"}) || $combination{"$set-LAS-F1"} == 0) && exists($erun->{"$set-LAS-F1"}) && $erun->{"$set-LAS-F1"} > 0)
            {
                # Copy all values pertaining to $set to the combined evaluation.
                #print STDERR ("$set ");
                foreach my $key (@keys)
                {
                    if ($key =~ m/^$set-(.+)$/)
                    {
                        my $m = $1;
                        #print STDERR ("COPY $key ");
                        $combination{$key} = $erun->{$key};
                        $sum{$m} += $erun->{$key};
                    }
                }
            }
        }
        #print STDERR ("\n");
    }
    # Recompute the macro average scores.
    my $nsets = scalar(grep {m/^(.+)-LAS-F1$/ && $1 ne 'total'} (keys(%combination)));
    die if ($nsets < 1);
    foreach my $key (keys(%sum))
    {
        $combination{"total-$key"} = $sum{$key}/$nsets;
    }
    return \%combination;
}
