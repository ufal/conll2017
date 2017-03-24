#!/usr/bin/env python

from __future__ import division
from __future__ import print_function

import argparse
import json

from conll17_ud_eval import UDError, load_conllu_file, evaluate

def main():
    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("dataset", type=str, help="Directory name of the input dataset.")
    parser.add_argument("truth", type=str, help="Directory name of the truth dataset.")
    parser.add_argument("system", type=str, help="Directory name of system output.")
    parser.add_argument("output", type=str, help="Directory name of the output directory.")
    args = parser.parse_args()

    # Load input dataset metadata.json
    with open(args.dataset + "/metadata.json","r") as metadata_file:
        metadata = json.load(metadata_file)

    # Evaluate and compute sum of all treebanks
    metrics = ["Tokens", "Sentences", "Words", "UPOS", "XPOS", "Feats", "AllTags", "Lemmas", "UAS", "LAS"]
    treebanks = 0
    summation = {}
    results = []
    for entry in metadata:
        treebanks += 1

        ltcode, goldfile, outfile = entry['ltcode'], entry['goldfile'], entry['outfile']

        # Load gold data
        try:
            gold = load_conllu_file(args.truth + "/" + goldfile)
        except:
            results.append((ltcode+"-Status", "Error: Cannot load gold file"))
            continue

        # Load system data
        try:
            system = load_conllu_file(args.system + "/" + outfile)
        except UDError as e:
            if e.args[0].startswith("There is a cycle"):
                results.append((ltcode+"-Status", "Error: There is a cycle in generated CoNLL-U file"))
                continue
            if e.args[0].startswith("There are multiple roots"):
                results.append((ltcode+"-Status", "Error: There are multiple roots in a sentence in generated CoNLL-U file"))
                continue
            results.append((ltcode+"-Status", "Error: There is a format error (tabs, ID values, etc) in generated CoNLL-U file"))
            continue
        except:
            results.append((ltcode+"-Status", "Error: Cannot open generated CoNLL-U file"))
            continue

        # Evaluate
        try:
            evaluation = evaluate(gold, system)
        except UDError as e:
            if e.args[0].startswith("The concatenation of tokens in gold file and in system file differ"):
                results.append((ltcode+"-Status", "Error: The concatenation of tokens in gold file and in system file differ, cannot evaluate"))
                continue
            # Should not happen
            results.append((ltcode+"-Status", "Error: Cannot evaluate generated CoNLL-U file, internal error"))
            continue
        except:
            # Should not happen
            results.append((ltcode+"-Status", "Error: Cannot evaluate generated CoNLL-U file, internal error"))
            continue

        # Generate output metrics and compute sum
        results.append((ltcode+"-Status", "OK: Evaluated non-zero LAS F1 score" if evaluation["LAS"].f1 > 0 else "Error: Evaluated zero LAS F1 score"))

        for metric in metrics:
            results.append((ltcode+"-"+metric+"-F1", "{:.2f}".format(100 * evaluation[metric].f1)))
            summation[metric] = summation.get(metric, 0) + evaluation[metric].f1

    # Compute averages
    for metric in metrics:
        results.append(("total-"+metric+"-F1", "{:.2f}".format(100 * summation.get(metric, 0) / treebanks)))

    # Generate evaluation.prototext
    with open(args.output + "/evaluation.prototext", "w") as evaluation:
        for key, value in results:
            print('measure{{\n  key: "{}"\n  value: "{}"\n}}'.format(key, value), file=evaluation)


if __name__ == "__main__":
    main()
