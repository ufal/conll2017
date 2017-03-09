#!/usr/bin/env python

from __future__ import division
from __future__ import print_function

import argparse

from conll17_ud_eval import evaluate_wrapper

def main():
    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("gold_file", type=str,
                        help="Name of the CoNLL-U file with the gold data.")
    parser.add_argument("system_file", type=str,
                        help="Name of the CoNLL-U file with the predicted data.")
    parser.add_argument("--weights", "-w", type=argparse.FileType("r"), default=None,
                        metavar="deprel_weights_file",
                        help="Compute WeightedLAS using given weights for Universal Dependency Relations.")
    args = parser.parse_args()

    # Evaluate
    evaluation = evaluate_wrapper(args)

    # Print the evaluation
    metrics = ["Tokens", "Sentences", "Words", "UPOS", "XPOS", "Feats", "AllTags", "Lemmas", "UAS", "LAS"]
    if args.weights is not None:
        metrics.append("WeightedLAS")

    for metric in metrics:
        for score in ("precision", "recall", "f1"):
            value = 100 * getattr(evaluation[metric], score)
            print('measure{\n  key: "%s-%s"\n  value: "%f"\n}' % (metric, score, value))

if __name__ == "__main__":
    main()
