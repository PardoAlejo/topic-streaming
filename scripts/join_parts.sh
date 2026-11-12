#!/usr/bin/env bash
# Rebuilds files that were split into <100 MB parts to fit GitHub's per-file limit.
# Run from the repo root after cloning:  bash scripts/join_parts.sh
# Writes e.g. datasets/miranda-zenodo/miranda_test_corpus_features_mpnet.csv
# (gunzipped) and datasets/wcep-data/train.jsonl.gz (kept gzipped, like test/val).
set -euo pipefail
cd "$(dirname "$0")/.."
for first in $(find datasets -name '*.part-00' | sort); do
  base="${first%.part-00}"
  case "$base" in
    *.csv.gz) out="${base%.gz}"; [ -f "$out" ] || { echo "-> $out"; cat "$base".part-* | gunzip > "$out"; } ;;
    *)        out="$base";       [ -f "$out" ] || { echo "-> $out"; cat "$base".part-* > "$out"; } ;;
  esac
done
echo "Done."
