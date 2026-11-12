#!/usr/bin/env bash
# Downloads the datasets that are NOT committed to this repo (see DATASETS.md).
# Run from the repo root. Needs: curl, unzip, git; gh (HLGD); pip (WCEP).
# Skip parts with e.g. SKIP_MPNET=1 (the MPNet embeddings are ~1.2 GB).
set -euo pipefail
cd "$(dirname "$0")/.."
D=datasets

echo "== 1. UCI News Aggregator"
mkdir -p "$D/uci-news-aggregator"
( cd "$D/uci-news-aggregator"
  curl -fL -o news_aggregator.zip "https://archive.ics.uci.edu/static/public/359/news+aggregator.zip"
  unzip -o news_aggregator.zip )

echo "== 2. Miranda / News14 (Zenodo 6630367)"
mkdir -p "$D/miranda-zenodo"
( cd "$D/miranda-zenodo"
  Z="https://zenodo.org/records/6630367/files"
  curl -fL -o miranda_test.csv  "$Z/miranda_test.csv?download=1"
  curl -fL -o miranda_train.csv "$Z/miranda_train.csv?download=1"
  if [ -z "${SKIP_MPNET:-}" ]; then
    curl -fL -o miranda_test_corpus_features_mpnet.csv  "$Z/miranda_test_corpus_features_mpnet.csv?download=1"
    curl -fL -o miranda_train_corpus_features_mpnet.csv "$Z/miranda_train_corpus_features_mpnet.csv?download=1"
  fi )

echo "== 3. StreamBench (code only; data must be built or requested from the authors)"
if [ ! -d "$D/streambench/llm-streaming-eval" ]; then
  git clone --depth 1 https://github.com/yukyunglee/llm-streaming-eval.git "$D/streambench/llm-streaming-eval"
fi

echo "== 4. HLGD release data (code is already in $D/hlgd)"
( cd "$D/hlgd"
  gh release download 0.1 --repo tingofurro/headline_grouping --pattern 'hlgd_classification_0.1.zip' --dir . --clobber
  unzip -o hlgd_classification_0.1.zip -d hlgd_classification )

echo "== 5. WCEP data (code is already in $D/wcep)"
pip install -q gdown
mkdir -p "$D/wcep-data"
( cd "$D/wcep-data"
  gdown --folder "https://drive.google.com/drive/folders/1T5wDxu4ajFwEq77dG88oE95e8ppREamg" )

echo "Done. LoCoMo is already committed in $D/locomo."
