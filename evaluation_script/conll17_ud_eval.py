#!/usr/bin/env python

# CoNLL 2017 UD Parsing evaluation script.
#
# Compatible with Python 2 and 3, can be used either as a module
# or a standalone executable.
#
# Copyright 2017 Institute of Formal and Applied Linguistics, Faculty of
# Mathematics and Physics, Charles University in Prague, Czech Republic.
#
# Changelog:
# - [02 Jan 2017] Version 0.9: Initial release
# - [25 Jan 2017] Version 0.9.1: Fix bug in LCS alignment computation

from __future__ import division
from __future__ import print_function

import argparse
import collections
import re
import sys

# CoNLL-U column names
ID, FORM, LEMMA, UPOS, XPOS, FEATS, HEAD, DEPREL, DEPS, MISC = range(10)

# UD Error is used when raising exceptions in this module
class UDError(Exception):
    pass

# Load given CoNLL-U file into internal representation
def load_conllu(file):
    # Internal representation classes
    class UDRepresentation:
        def __init__(self):
            self.characters = []
            self.tokens = []
            self.words = []
            self.sentences = []
    class UDSpan:
        def __init__(self, start, end):
            self.start = start
            self.end = end
    class UDWord(UDSpan):
        def __init__(self, span, columns, is_multiword):
            self.span = span
            self.columns = columns
            self.is_multiword = is_multiword

            # Ignore language-specific deprel subtypes
            index = self.columns[DEPREL].find(":")
            if index >= 0:
                self.columns[DEPREL] = self.columns[DEPREL][:index]

    ud = UDRepresentation()

    # Load the CoNLL-U file
    index, in_sentence = 0, False
    while True:
        line = file.readline()
        if not line:
            break
        line = line.rstrip("\r\n")

        # Handle sentence start boundaries
        if not in_sentence:
            # Skip comments
            if line.startswith("#"):
                continue
            # Start a new sentence
            ud.sentences.append(UDSpan(index, 0))
            in_sentence = True
        if not line:
            ud.sentences[-1].end = index
            in_sentence = False
            continue

        # Read next token/word
        columns = line.split("\t")
        if len(columns) != 10:
            raise UDError("The CoNLL-U line does not contain 10 tab-separated columns: '{}'".format(line))

        # Skip empty nodes
        if "." in columns[ID]:
            continue

        # Save token
        ud.characters.extend(columns[FORM])
        ud.tokens.append(UDSpan(index, index + len(columns[FORM])))
        index += len(columns[FORM])

        # Handle multi-word tokens to save word(s)
        if "-" in columns[ID]:
            try:
                start, end = map(int, columns[ID].split("-"))
            except:
                raise UDError("Cannot parse multi-word token ID '{}'".format(columns[ID]))

            for i in range(start, end + 1):
                word_line = file.readline().rstrip("\r\n")
                word_columns = word_line.split("\t")
                if len(word_columns) != 10:
                    raise UDError("The CoNLL-U line does not contain 10 tab-separated columns: '{}'".format(word_line))
                ud.words.append(UDWord(ud.tokens[-1], word_columns, is_multiword=True))
        # Basic tokens/words
        else:
            ud.words.append(UDWord(ud.tokens[-1], columns, is_multiword=False))

    if in_sentence:
        raise UDError("The CoNLL-U file does not end with empty line")

    return ud

# Evaluate the gold and system treebanks (loaded using load_conllu).
def evaluate(gold_ud, system_ud, deprel_weights=None):
    class F1Score:
        def __init__(self, gold_total, system_total, correct):
            self.precision = correct / system_total if system_total else 0.0
            self.recall = correct / gold_total if gold_total else 0.0
            self.f1 = 2 * correct / (system_total + gold_total) if system_total + gold_total else 0.0

    class Alignment:
        def __init__(self, gold_words, system_words, matched_words):
            self.gold_words = gold_words
            self.system_words = system_words
            self.matched_words = matched_words

    class AlignmentWord:
        def __init__(self, gold_word, system_word):
            self.gold_word = gold_word
            self.system_word = system_word

    def spans_f1_score(gold_spans, system_spans):
        correct, gi, si = 0, 0, 0
        while gi < len(gold_spans) and si < len(system_spans):
            if si < len(system_spans) and (gi == len(gold_spans) or system_spans[si].start < gold_spans[gi].start):
                si += 1
            elif gi < len(gold_spans) and (si == len(system_spans) or gold_spans[gi].start < system_spans[si].start):
                gi += 1
            else:
                correct += gold_spans[gi].end == system_spans[si].end
                si += 1
                gi += 1

        return F1Score(len(gold_spans), len(system_spans), correct)

    def alignment_f1_score(alignment, key_fn, weight_fn = None):
        gold, system, correct = 0, 0, 0

        for word in alignment.gold_words:
            gold += weight_fn(word) if weight_fn else 1

        for word in alignment.system_words:
            system += weight_fn(word) if weight_fn else 1

        for words in alignment.matched_words:
            if key_fn(words.gold_word) == key_fn(words.system_word):
                correct += weight_fn(words.gold_word) if weight_fn else 1

        return F1Score(gold, system, correct)

    def align_words(gold_words, system_words):
        alignment = Alignment(gold_words, system_words, [])

        gi, si = 0, 0
        while gi < len(gold_words) and si < len(system_words):
            if (gold_words[gi].span.start > system_words[si].span.start or not gold_words[gi].is_multiword) and \
                    (system_words[si].span.start > gold_words[gi].span.start or not system_words[si].is_multiword):
                # No multi-word token, align according to spans
                if (gold_words[gi].span.start, gold_words[gi].span.end) == (system_words[si].span.start, system_words[si].span.end):
                    alignment.matched_words.append(AlignmentWord(gold_words[gi], system_words[si]))
                    gi += 1
                    si += 1
                elif gold_words[gi].span.start <= system_words[si].span.start:
                    gi += 1
                else:
                    si += 1
            else:
                # Multi-word token
                gs, ss = gi, si
                multiword_span_end = gold_words[gi].span.end if gold_words[gi].is_multiword else system_words[si].span.end

                # Find all words in the multiword span
                while (gi < len(gold_words) and (gold_words[gi].span.start < multiword_span_end if gold_words[gi].is_multiword
                                                 else gold_words[gi].span.end <= multiword_span_end)) or \
                        (si < len(system_words) and (system_words[si].span.start < multiword_span_end if system_words[si].is_multiword
                                                     else system_words[si].span.end <= multiword_span_end)):
                    if gi < len(gold_words) and (si >= len(system_words) or
                                                 gold_words[gi].span.start <= system_words[si].span.start):
                        if gold_words[gi].is_multiword and gold_words[gi].span.end > multiword_span_end:
                            multiword_span_end = gold_words[gi].span.end
                        gi += 1
                    else:
                        if system_words[si].is_multiword and system_words[si].span.end > multiword_span_end:
                            multiword_span_end = system_words[si].span.end
                        si += 1

                if si > ss and gi > gs:
                    # LCS on the chosen words
                    lcs = [[0] * (si - ss) for i in range(gi - gs)]
                    for g in reversed(range(gi - gs)):
                        for s in reversed(range(si - ss)):
                            if gold_words[gs + g].columns[FORM] == system_words[ss + s].columns[FORM]:
                                lcs[g][s] = 1 + (lcs[g+1][s+1] if g+1 < gi-gs and s+1 < si-ss else 0)
                            lcs[g][s] = max(lcs[g][s], lcs[g+1][s] if g+1 < gi-gs else 0)
                            lcs[g][s] = max(lcs[g][s], lcs[g][s+1] if s+1 < si-ss else 0)

                    # Store aligned words
                    s, g = 0, 0
                    while g < gi - gs and s < si - ss:
                        if gold_words[gs + g].columns[FORM] == system_words[ss + s].columns[FORM]:
                            alignment.matched_words.append(AlignmentWord(gold_words[gs+g], system_words[ss+s]))
                            g += 1
                            s += 1
                        elif lcs[g][s] == (lcs[g+1][s] if g+1 < gi-gs else 0):
                            g += 1
                        else:
                            s += 1

        return alignment

    # Check that underlying character sequences do match
    if gold_ud.characters != system_ud.characters:
        index = 0
        while gold_ud.characters[index] == system_ud.characters[index]:
            index += 1

        raise UDError(
            "The catenation of tokens in gold file and in system file differ!\n" +
            "First 20 differing characters in gold file: '{}' and system file: '{}'".format(
                "".join(gold_ud.characters[index:index + 20]),
                "".join(system_ud.characters[index:index + 20])
            )
        )

    # Align words
    alignment = align_words(gold_ud.words, system_ud.words)

    # Compute the F1-scores
    result = {
        "Tokens": spans_f1_score(gold_ud.tokens, system_ud.tokens),
        "Sentences": spans_f1_score(gold_ud.sentences, system_ud.sentences),
        "Words": alignment_f1_score(alignment, lambda w: ""),
        "UPOS": alignment_f1_score(alignment, lambda w: w.columns[UPOS]),
        "XPOS": alignment_f1_score(alignment, lambda w: w.columns[XPOS]),
        "Feats": alignment_f1_score(alignment, lambda w: w.columns[FEATS]),
        "AllTags": alignment_f1_score(alignment, lambda w: (w.columns[UPOS], w.columns[XPOS], w.columns[FEATS])),
        "Lemmas": alignment_f1_score(alignment, lambda w: w.columns[LEMMA]),
        "UAS": alignment_f1_score(alignment, lambda w: w.columns[HEAD]),
        "LAS": alignment_f1_score(alignment, lambda w: (w.columns[HEAD], w.columns[DEPREL])),
    }

    # Add WeightedLAS if weights are given
    if deprel_weights is not None:
        def weighted_las(word):
            return deprel_weights[word.columns[DEPREL]] if word.columns[DEPREL] in deprel_weights else 1.
        result["WeightedLAS"] = alignment_f1_score(alignment, lambda w: (w.columns[HEAD], w.columns[DEPREL]), weighted_las)

    return result

if __name__ == "__main__":
    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("gold_file", type=argparse.FileType("r"),
                        help="Name of the file with the gold data.")
    parser.add_argument("system_file", type=argparse.FileType("r"), nargs="?", default=sys.stdin,
                        help="Name of the file with the gold data.")
    parser.add_argument("--weights", "-w", type=argparse.FileType("r"), default=None,
                        metavar="deprel_weights_file",
                        help="Compute WeightedLAS using given weights for Universal Dependency Relations.")
    parser.add_argument("--verbose", "-v", default=0, action='count',
                        help="Verbosity level.")
    args = parser.parse_args()

    # Use verbose if weights are supplied
    if args.weights is not None and not args.verbose:
        args.verbose = 1

    # Load weights if requested
    deprel_weights = args.weights
    if deprel_weights: # file with weights is given
        deprel_weights = {}
        for line in args.weights:
            # Ignore comments and empty lines
            if line.startswith("#") or not line.strip():
                continue

            columns = line.rstrip("\r\n").split()
            if len(columns) != 2:
                raise ValueError("Expected two columns in the UDM weights file on line '{}'".format(line))

            deprel_weights[columns[0]] = float(columns[1])

    # Load CoNLL-U files
    gold_ud = load_conllu(args.gold_file)
    system_ud = load_conllu(args.system_file)

    # Evaluate
    evaluation = evaluate(gold_ud, system_ud, deprel_weights)

    # Print the evaluation
    if not args.verbose:
        print("LAS F1 Score: {:.2f}".format(100 * evaluation["LAS"].f1))
    else:
        print("Metrics    | Precision |    Recall |  F1 Score")
        print("-----------+-----------+-----------+-----------")
        for metrics in ["Tokens", "Sentences", "Words", "UPOS", "XPOS", "Feats", "AllTags", "Lemmas", "UAS", "LAS"
                        ] + (["WeightedLAS"] if deprel_weights is not None else []):
            print("{:11}|{:10.2f} |{:10.2f} |{:10.2f}".format(
                metrics,
                100 * evaluation[metrics].precision,
                100 * evaluation[metrics].recall,
                100 * evaluation[metrics].f1
            ))
