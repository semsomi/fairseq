#!/usr/bin/env bash


python setup.py build develop

mkdir -p data-bin/wmt18ensemble
mkdir -p data-bin/corpora/shards
mkdir -p data-bin/corpora/translations

echo 'Cloning Moses github repository (for tokenization scripts)...'
git clone https://github.com/moses-smt/mosesdecoder.git

echo 'Cloning Subword NMT repository (for BPE pre-processing)...'
git clone https://github.com/rsennrich/subword-nmt.git

curl https://storage.googleapis.com/monok/code -o data-bin/wmt18ensemble/code
curl https://storage.googleapis.com/monok/dict.de.txt -o data-bin/wmt18ensemble/cdict.de.txt
curl https://storage.googleapis.com/monok/dict.en.txt -o data-bin/wmt18ensemble/cdict.en.txt


# sacrebleu -t wmt18 -l en-de --echo src > wmt18.en-de.en
# cat wmt18.en-de.en| $NORM_PUNC -l en | $TOKENIZER -a -l en -q | python $BPEROOT/apply_bpe.py -c code | python $FAIRSEQ/interactive.py . --path wmt18.model1.pt:wmt18.model2.pt:wmt18.model3.pt:wmt18.model4.pt:wmt18.model5.pt:wmt18.model6.pt --remove-bpe --buffer-size 1024 --batch-size 16 -s en -t de |grep -P "^H" |cut -f 3- | $DETOKENIZER -l de -q > wmt18.en-de.ensemble.out



# python replace_copies.py -s wmt18.en-de.en -t wmt18.en-de.ensemble.out | $NORM_PUNC -l en | $TOKENIZER -a -l en -q | python $BPEROOT/apply_bpe.py -c nc_model/code | python $FAIRSEQ/interactive.py nc_model --path nc_model/model.pt --remove-bpe --buffer-size 1024 --batch-size 16 -s en -t de |grep -P "^H" |cut -f 3- | $DETOKENIZER -l de -q > wmt18.en-de.copies.out

# python replace_copies.py -s wmt18.en-de.en -t wmt18.en-de.ensemble.out -c wmt18.en-de.copies.out > wmt18.en-de.copyfixed.out

# cat wmt18.en-de.copyfixed.out | sacrebleu -t wmt18 -l en-de -lc
