#!/usr/bin/env python

from __future__ import division
from __future__ import print_function

import argparse
import sys

from conll17_ud_eval import load_deprel_weights, load_conllu, evaluate

def main():
    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("gold_file", type=argparse.FileType("r"),
                        help="Name of the CoNLL-U file with the gold data.")
    parser.add_argument("system_file", type=argparse.FileType("r"), nargs="?", default=sys.stdin,
                        help="Name of the CoNLL-U file with the predicted data (default=STDIN).")
    parser.add_argument("--weights", "-w", type=argparse.FileType("r"), default=None,
                        metavar="deprel_weights_file",
                        help="Compute WeightedLAS using given weights for Universal Dependency Relations.")
    args = parser.parse_args()

    # Load weights if requested
    deprel_weights = load_deprel_weights(args.weights)

    # Load CoNLL-U files
    gold_ud = load_conllu(args.gold_file)
    system_ud = load_conllu(args.system_file)

    # Evaluate
    evaluation = evaluate(gold_ud, system_ud, deprel_weights)

    # Print the evaluation
    metrics = ["Tokens", "Sentences", "Words", "UPOS", "XPOS", "Feats", "AllTags", "Lemmas", "UAS", "LAS"]
    if deprel_weights is not None:
        metrics.append("WeightedLAS")

    for metric in metrics:
        for score in ("precision", "recall", "f1"):
            value = 100 * getattr(evaluation[metric], score)
            print('measure{\n  key: "%s-%s"\n  value: "%f"\n}' % (metric, score, value))

if __name__ == "__main__":
    main()
