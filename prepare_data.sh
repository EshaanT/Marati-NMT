SCRIPTS=mosesdecoder/scripts
TOKENIZER=$SCRIPTS/tokenizer/tokenizer.perl
LC=$SCRIPTS/tokenizer/lowercase.perl
CLEAN=$SCRIPTS/training/clean-corpus-n.perl
BPEROOT=subword-nmt/subword_nmt
BPE_TOKENS=10000

src=mr
tgt=en
lang=mr-en
prep=data.tokenized.mr-en
tmp=$prep/tmp
orig=data

mkdir -p $tmp $prep

echo "pre-processing train data..."
for l in $src $tgt; do
    f=train.$l
    tok=train.tags.$lang.tok.$l
    
    cat $orig/$f |\
    perl $TOKENIZER -threads 8 -l $l > $tmp/$tok
    echo ""
    
done

perl $CLEAN $tmp/train.tags.$lang.tok $src $tgt $tmp/train.tags.$lang.clean 1 175

for l in $src $tgt; do
    perl $LC < $tmp/train.tags.$lang.clean.$l > $tmp/train.$l
done


for l in $src $tgt; do
    f=test.$l
    tok=test.tok.$l
    
    cat $orig/$f |\
    perl $TOKENIZER -threads 8 -l $l |\
    perl $LC > $tmp/$f
    echo ""
    
done 

for l in $src $tgt; do
    f=valid.$l
    
    
    cat $orig/$f |\
    perl $TOKENIZER -threads 8 -l $l |\
    perl $LC > $tmp/$f
    echo ""
    
done   

TRAIN=$tmp/train.mr-en
BPE_CODE=$prep/code
rm -f $TRAIN
for l in $src $tgt; do
    cat $tmp/train.$l >> $TRAIN
done

echo "learn_bpe.py on ${TRAIN}..."
python $BPEROOT/learn_bpe.py -s $BPE_TOKENS < $TRAIN > $BPE_CODE

for L in $src $tgt; do
    for f in train.$L valid.$L test.$L; do
        echo "apply_bpe.py to ${f}..."
        python $BPEROOT/apply_bpe.py -c $BPE_CODE < $tmp/$f > $prep/$f
    done
done
    
    