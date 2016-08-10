# CoNLL 2017 UD Shared Task proposal

Notes from the lunch on Tuesday, Aug. 9, 2016 in Berlin
Present: Jan Hajič, Joakim Nivre, Chris Manning, Dan Zeman, Yoav Goldberg, Sampo Pyysalo, Filip Ginter, Jon Derdari, Fran Tyers, Jenna Kanerva, Tommi Pirinen, Özlem Çetinoğlu, Anssi Yli-Jyrä (13)

These are the basic parameters of the shared task proposal, agreed upon by the majority present:

- there will be one task: parsing UD trees, with the possibility to use the fact that all of them have the same (almost) format to develop cross-lingual parsers, one multilingual parser, or some other method that takes advantage of it, supported by the surprise language (that counts towards a final score).

- closed task - only organizers' supplied data allowed (see below)

- Core Data: UD treebanks which fulfil the following criteria: (a) correspond to version 2 (at least to the extent that can be automatically checked), (b) delivered in time (c) min. 10,000 words (for evaluation data) and (aiming for) 10,000 for designated development data (no restriction on training data size - 0 is OK); Google-supplied parallel data, about 500 sentences per language. Expectation: 15-20 UD treebanks v2.0 will be used for the ST (the more the better).

- Additional Data supplied: Raw texts, ~100 mil. tokens (maybe more, maybe less for small languages) per language, pre-analyzed by UDPipe (tokenization, lemmas if available, UPOS, XPOS, features); word2vec or other embeddings with description of parameters used on those data (analysis by UDPipe and embedding only as convenience for participants).

- Evaluation: one main metric - parsing only, macro-averaged over all languages. All languages must be parsed to get to the rankings. Organizers might provide more tables (per language, parallel data evaluated separately, ...)

- Evaluation data: there will be 10k min, of evaluation data for all UD treebanks provided for training, plus one or more surprise languages, which will only be evaluated (no training/dev data; possibly 10-20 sentences annotated. TBD: When to publish them? Together with training data? Or later? Or only in the VM when running the tests?) Language-specific relations, while available in the training data and participants free to use them, will not be part of evaluation, i.e., everything from the colon onwards will be deleted and only the universal “prefix” of the relation used for evaluation. TBD: LAS or CLAS (content-words-only-LAS) score?

## Rules, process and technical issues:

-- participants will submit one runtime system (capable of parsing any language), as a VM - compliant with CoNLL recommended rules.
-- the system will have to accept the following parameters: directory with input data (the exact structure TBD), language ID, and directory to which output data should go.
-- the system must respond to any language code (NB: surprise language) and produce some output in UD format, for all of the eval text
-- organizers will then run it on the evaluation data, one run per evaluation set, and publish results.
-- input test data will be available as raw text (original or pseudo-untokenized), and also preprocessed by UDPipe for tokenization, lemmatization, UPOS, XPOS and features; participants systems will be allowed to use any of those
-- participants will be explicitly warned not to use any other UD data than those supplied through the CoNLL 2017 ST (due to possible re-splitting, even if minimized)
-- development data will be marked, but there are no restrictions on using them as training as well (e.g. for final retraining)
-- novel techniques such as cross-lingual learning etc. encouraged but not enforced

## Additional points/remarks:

- will try to run same task in 2018 - with more UD2.0 treebanks, improved treebanks, new languages, new surprise language(s), same evaluation metric
- will have to have sample data very soon (at least for some languages, but including raw preprocessed data w/UDPipe, embeddings)
- the only condition for inclusion is UD 2.0 compliance (we will test as much as we can...) and 10k eval data size. Development preliminarily set to 10k but that might be eased. More treebanks per language are OK (TBD: are we going to tell the system which treebank the test data come from, i.e. do we follow the UD practice of extending the language codes, e.g. “fi_ftb”? Or do we just identify the language (note that the same applies for the distinction of Google test data vs. “treebank-native” test data).

