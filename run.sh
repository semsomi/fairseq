#!/usr/bin/env bash

N=$1

SOURCE_LANG=en
TARGET_LANG=de
BIN=data-bin/wmt18ensemble

SCRIPTS=mosesdecoder/scripts
TOKENIZER=$SCRIPTS/tokenizer/tokenizer.perl
DETOKENIZER=$SCRIPTS/tokenizer/detokenizer.perl
CLEAN=$SCRIPTS/training/clean-corpus-n.perl
NORM_PUNC=$SCRIPTS/tokenizer/normalize-punctuation.perl
REM_NON_PRINT_CHAR=$SCRIPTS/tokenizer/remove-non-printing-char.perl
BPEROOT=subword-nmt/subword_nmt

CODE=$BIN/code

SOURCE_DICT=$BIN/dict.$SOURCE_LANG.txt
TARGET_DICT=$BIN/dict.$TARGET_LANG.txt
TEST=$BIN/test
CORPORA_DIR=data-bin/corpora
SHARDS_DIR=$CORPORA_DIR/shards
TRANSLATIONS_DIR=$CORPORA_DIR/translations

SHARD_NAME=mono$N

# UNDERSTAND WHAT MODEL TO USE
MODEL_NR=$(echo "$N % 6" | bc)

# If the rest is a zero then it's model 6
if [ $MODEL_NR = 0 ]
then
	MODEL_NR=6
fi

MODEL=$BIN/wmt18.model$MODEL_NR.pt

if [ -f "$MODEL" ]
then
	echo "$MODEL found."
else
	echo "$MODEL not found, downloading..."
	curl https://storage.googleapis.com/monok/wmt18.model$MODEL_NR.pt -o $BIN/wmt18.model$MODEL_NR.pt
fi

if [ -f "$SHARDS_DIR/$SHARD_NAME" ]
then
	echo "$SHARD_NAME found."
else
	echo "$SHARD_NAME not found, downloading..."
	curl https://storage.googleapis.com/monok/shards/mono0 -o $SHARDS_DIR/$SHARD_NAME
fi



echo "Tokenizing and BPE:ing"
cat $SHARDS_DIR/$SHARD_NAME | $NORM_PUNC -l $SOURCE_LANG | $TOKENIZER -a -l $SOURCE_LANG -q | python $BPEROOT/apply_bpe.py  -c $CODE > $SHARDS_DIR/$SHARD_NAME.bpe.$SOURCE_LANG

cp $TARGET_DICT $TEST
echo "Preprocessing..."
python preprocess.py --output-format raw --only-source --workers 1 --target-lang $TARGET_LANG --source-lang $SOURCE_LANG --testpref $SHARDS_DIR/$SHARD_NAME.bpe --destdir $TEST --srcdict $SOURCE_DICT --tgtdict $TARGET_DICT

python -u batch_generate.py $TEST --path $MODEL --batch-size 128 --beam 5 --raw-text --remove-bpe --replace-unk --task translation_mono --no-progress-bar | tee $TRANSLATIONS_DIR/translation.$N.output
cat $TRANSLATIONS_DIR/translation.$N.output | grep -P '^S' | cut -f2- | sed 's/@@\s*//g' | sed 's/@ - @\s*//g'  > $TRANSLATIONS_DIR/translation.$N.$SOURCE_LANG
cat $TRANSLATIONS_DIR/translation.$N.output | grep -P '^H' | cut -f3- | sed 's/@@\s*//g' | sed 's/@ - @\s*//g' | python addnoise.py   > $TRANSLATIONS_DIR/translation.$N.$TARGET_LANG

