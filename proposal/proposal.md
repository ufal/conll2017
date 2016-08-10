# CoNLL 2017 Shared Task Proposal: UD End-to-End parsing

[Call for proposals](http://www.conll.org/cfprop-sharedtask-2017)

For clarity, feasibility and encouragement of participants,
we propose only a small number of tracks and evaluation metrics
(even if there are many possibilities).


## Proposed Tracks


### Main Track

The main track is end-to-end parsing of UD corpora,
i.e., parsing from plain texts to dependency trees.

Most of the UD 1.4 corpora will be used as training/development/testing
data for this track (with some exceptions -- Japanese because of the license,
and corpora which cannot be reliably detokenized, i.e., for which we cannot
get enough raw texts).
Note that this means that in the track the testing data **will be known in
advance** and we have to trust the participants not to take advantage of it.

As majority of UD corpora do not contain the original plain text, we will
reconstruct it using unannotated raw texts.

Only systems working for **all the languages** will be accepted (we are
interested only in multi-lingual systems).

The participants will be allowed to use these data during training:

- UD 1.4 corpora with plain texts (either gold standard or automatically generated)
    - Automatically tokenized and POS-tagged variants will be provided
- additional raw texts for the languages involved (hopefully ~gigaword corpora
  for many languages)
- Europarl Parallel corpus
- for convenience, we will also provide word embeddings, computed from the
  texts above; however, participants are free to compute their own embeddings
  if they like

No additional data can be used during training -- therefore, if the participants
compute word embeddings, they can use only UD data and the given raw texts.
(Note that we do *not* propose
an additional Open track which would allow utilization of additional data and/or
software.)

A participating system will be evaluated on every corpora using the evaluation
metric(s) below, and the final score of the system will be the arithmetic
mean of the corpora scores (an analogue of macro-accuracy).


### Parallel Data Track [if we have the required data]

Very similar to the Main track (same training data, additional resources
and evaluation), with the following differences:

- The testing data would be previously unreleased parallel corpora in a subset
  of languages from the Main track. During evaluation, the system will get all the
  data at the same time (to be able to exploit the fact that the testing data are
  parallel corpora).
- Small parallel corpora (either a small part of the corpora discussed above,
  or small part of Europarl, etc.) would be released as development data.

All systems submitted to the Main track would be evaluated in Parallel data
track, so that systems in the Main track are evaluated also on unknown test set,
in addition to known UD testing data.


### Surprise Language Track

Similar to the Main track (same training data, additional resources and
evaluation), with the following differences:

- The testing data will be in previously unreleased languages, unknown to the
  participants until the evaluation. No development data will be provided.


## Evaluation Metrics

We propose that only one evaluation metrics is used -- F1-score under a
content-word-based evaluation metrics (with
[CNC](http://stp.lingfil.uu.se/~nivre/docs/udeval-cl.pdf) being the initial
proposal).
Notably, for a dependency edge to be considered correct:

- the dependent word and the head word must be both correct and tokenized
  correctly (in this respect, all technical roots are equivalent)
- the dependency relation must be correct
- the content-word-based metrics will probably define which dependency
  relations are ignored (for example, in [CNC](http://stp.lingfil.uu.se/~nivre/docs/udeval-cl.pdf),
  dependency relations in the Punct and Func subsets are ignored)

We currently do *not* propose to evaluate UAS (we already produce several
dozens of scores in the Main task for each system; and with UAS, we would have
two different orderings of participants in every track) nor plain LAS.

The evaluation starts by aligning the system-produces tokens to the
gold standard ones. This process is straightforward for
[CoNLL-U tokens](http://universaldependencies.org/format.html#words-and-tokens)
which can be identified by their range in the original plain text;
for [CoNLL-U words](http://universaldependencies.org/format.html#words-and-tokens)
being part of multiword-tokens, we use longest common subsequence to perform the
alignment. We completely ignore sentence breaks during tokenizer evaluation.

### Metric Focused on UD Content Word Dependencies

Joakim Nivre suggests the [CNC evaluation metrics](http://stp.lingfil.uu.se/~nivre/docs/udeval-cl.pdf)
as a starting point, but notes that we may have to tweak it a little bit.

The CNC is a modification of LAS, where the dependency relations
in the Punct and Func subset are ignored. The Punct subset consists of
`punct` deprel, the Func subset consists of the following deprels:

- `aux`
- `auxpass`
- `case`
- `cc`
- `cop`
- `det`
- `mark`
- `neg`

### Language Variants [undecided]

For some languages, there are multiple corpora in the UD (3 corpora for Czech, English,
Latin; 2 corpora for 8 languages in UD 1.3).

It is yet undecided whether these corpora will be evaluated separately (whereby
contributing multiple times to the final score), or only one corpus for each language
would be kept, or the corpora for a given language will be somehow merged.


## Evaluation Process

We plan to use the [Tira platform](http://www.tira.io/) as suggested in the Call
for proposals.

Therefore, the participants will **submit the systems**, not parsed data,
allowing us _not_ to give the testing data beforehand (only after
the Shared Task is evaluated).
