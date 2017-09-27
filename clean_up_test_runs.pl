#!/usr/bin/env perl
# Cleans up the folder with system outputs from the CoNLL 2017 shared task.
# Copyright © 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');
use find;
use dzsys;

find::go('.', \&process);

sub process
{
    my $cesta = shift;
    my $objekt = shift;
    my $druh = shift;
    # Jestliže se nacházíme uvnitř složky, která se jmenuje output, kontrolovat objekty. Jinde na nic nesahat.
    if($cesta =~ m:/output$:)
    {
        # Ve složce output nemají být podsložky.
        if($druh =~ m/^d/)
        {
            print("Removing folder $cesta/$objekt.\n");
            dzsys::saferun("rm -rf $cesta/$objekt") or die;
            return 0; # nevstupovat do podsložky
        }
        # Pokud jde o soubory, očekáváme buď .conllu (ve výstupech parserů), nebo .prototext (ve výstupu vyhodnocovadla).
        else
        {
            unless($objekt =~ m/^[a-z_]+\.(conllu|prototext)$/)
            {
                print("Removing file $cesta/$objekt.\n");
                unlink("$cesta/$objekt") or die("Cannot remove $cesta/$objekt: $!");
                return 0;
            }
        }
    }
    # Upravit přístupová práva u všech souborů.
    unless($druh =~ m/^d/)
    {
        chmod(0644, "$cesta/$objekt");
    }
    return $druh eq 'drx';
}
