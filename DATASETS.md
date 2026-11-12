# Datasets

Datasets live in `datasets/`. Below is each dataset with its license, source, and download instructions.

## What is committed vs. downloaded

| Path | In repo? | Upstream commit |
|---|---|---|
| `datasets/locomo/` | Yes, code + data (`data/locomo10.json`) | snap-research/locomo@3eb6f2c |
| `datasets/miranda-news-clustering/` | Yes, eval code only | Priberam/news-clustering@27dbbc2 |
| `datasets/hlgd/` | Yes, code + data (`hlgd_classification/{train,dev,test}.json`, release 0.1) | tingofurro/headline_grouping@47a30ed |
| `datasets/wcep/` | Yes, code only | complementizer/wcep-mds-dataset@8aa8418 |
| `datasets/uci-news-aggregator/` | No (gitignored) | |
| `datasets/miranda-zenodo/` | No (gitignored, ~1.2 GB embeddings) | |
| `datasets/wcep-data/` | No (gitignored) | |
| `datasets/streambench/` | No (gitignored, upstream has no license file) | |

Fetch everything that is not committed with:

```bash
bash scripts/download_datasets.sh          # SKIP_MPNET=1 to skip the 1.2 GB embeddings
```

Each committed directory keeps its upstream `LICENSE`.

## Eval Priority Order

Per the research notes: **UCI News Aggregator → Miranda/News14 → StreamBench**

---

## 1. UCI News Aggregator

| | |
|---|---|
| **Content** | 422,937 news article titles + URLs with story IDs and timestamps |
| **License** | Public Domain (URLs only, no article text) |
| **Source** | [UCI ML Repository](https://archive.ics.uci.edu/dataset/359/news+aggregator) |
| **Local path** | `datasets/uci-news-aggregator/` |

```bash
mkdir -p datasets/uci-news-aggregator && cd datasets/uci-news-aggregator
curl -L -o news_aggregator.zip "https://archive.ics.uci.edu/static/public/359/news+aggregator.zip"
unzip news_aggregator.zip
```

---

## 2. Miranda / News14

| | |
|---|---|
| **Content** | ~21k articles / 808 stories (EN), plus ES and DE |
| **License** | BSD 3-Clause (Priberam code + Zenodo features) |
| **Source (features)** | [Zenodo 6630367](https://zenodo.org/records/6630367) |
| **Source (eval code)** | [github.com/Priberam/news-clustering](https://github.com/Priberam/news-clustering) |
| **Local path** | `datasets/miranda-zenodo/` (features), `datasets/miranda-news-clustering/` (code) |

```bash
# Labels
mkdir -p datasets/miranda-zenodo && cd datasets/miranda-zenodo
curl -L -o miranda_test.csv "https://zenodo.org/records/6630367/files/miranda_test.csv?download=1"
curl -L -o miranda_train.csv "https://zenodo.org/records/6630367/files/miranda_train.csv?download=1"

# MPNet embeddings (~1.2 GB)
curl -L -o miranda_test_corpus_features_mpnet.csv "https://zenodo.org/records/6630367/files/miranda_test_corpus_features_mpnet.csv?download=1"
curl -L -o miranda_train_corpus_features_mpnet.csv "https://zenodo.org/records/6630367/files/miranda_train_corpus_features_mpnet.csv?download=1"

# Eval code
git clone --depth 1 https://github.com/Priberam/news-clustering.git datasets/miranda-news-clustering
```

Note: Raw article text is on Priberam FTP (`ftp://ftp.priberam.pt/SUMMAPublic/Corpora/Clustering/2018.0/`) but the server may reject connections. The Zenodo embeddings are sufficient for eval.

---

## 3. StreamBench

| | |
|---|---|
| **Content** | 605 events, 15,354 docs, 3-level hierarchy (story → topic → event) |
| **License** | CC BY-SA 4.0 (paper), code license unspecified |
| **Source** | [github.com/yukyunglee/llm-streaming-eval](https://github.com/yukyunglee/llm-streaming-eval) |
| **Paper** | [arXiv 2603.19250](https://arxiv.org/abs/2603.19250) (KDD 2026) |
| **Local path** | `datasets/streambench/` |

```bash
git clone --depth 1 https://github.com/yukyunglee/llm-streaming-eval.git datasets/streambench/llm-streaming-eval
```

**Status: code only.** The data file (`unified_events_218.json`) must be built using the scraping pipeline in `src/data_construction/` or requested from the authors.

---

## 4. HLGD (Headline Grouping Dataset)

| | |
|---|---|
| **Content** | 10 timelines, ~20k headline pairs |
| **License** | Apache 2.0 (code + annotations); headlines used under fair use (see `LEGAL.md` in repo) |
| **Source** | [github.com/tingofurro/headline_grouping](https://github.com/tingofurro/headline_grouping) |
| **Local path** | `datasets/hlgd/` |

```bash
git clone --depth 1 https://github.com/tingofurro/headline_grouping.git datasets/hlgd
cd datasets/hlgd && gh release download 0.1 --dir .
unzip hlgd_classification_0.1.zip -d hlgd_classification
# Optionally remove model weights (1.9 GB, not needed for eval):
rm -f cls_elec_base_hlgd_0.74f1.bin gpt2med_headline_gen_1.645.bin
```

---

## 5. WCEP (Wikipedia Current Events Portal)

| | |
|---|---|
| **Content** | 10,200 event clusters with human-written summaries |
| **License** | MIT |
| **Source (code)** | [github.com/complementizer/wcep-mds-dataset](https://github.com/complementizer/wcep-mds-dataset) |
| **Source (data)** | [Google Drive](https://drive.google.com/drive/folders/1T5wDxu4ajFwEq77dG88oE95e8ppREamg) |
| **Local path** | `datasets/wcep/` (code), `datasets/wcep-data/` (data) |

```bash
git clone --depth 1 https://github.com/complementizer/wcep-mds-dataset.git datasets/wcep
pip install gdown
mkdir -p datasets/wcep-data && cd datasets/wcep-data
gdown --folder "https://drive.google.com/drive/folders/1T5wDxu4ajFwEq77dG88oE95e8ppREamg"
```

---

## 6. LoCoMo (Long Conversation Memory)

| | |
|---|---|
| **Content** | 10 long conversations for memory system evaluation |
| **License** | CC BY-NC 4.0 (non-commercial only) |
| **Source** | [github.com/snap-research/locomo](https://github.com/snap-research/locomo) |
| **Local path** | `datasets/locomo/` |

```bash
git clone --depth 1 https://github.com/snap-research/locomo.git datasets/locomo
```

---

## License Summary

| Dataset | License | Commercial Use |
|---------|---------|----------------|
| UCI News Aggregator | Public Domain | Yes |
| Miranda / News14 | BSD 3-Clause | Yes |
| StreamBench | CC BY-SA 4.0 | Yes (share-alike) |
| HLGD | Apache 2.0 | Yes |
| WCEP | MIT | Yes |
| LoCoMo | CC BY-NC 4.0 | **No** |
