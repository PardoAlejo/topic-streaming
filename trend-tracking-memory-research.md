# Topic Discovery & Tracking × LLM Memory — Research Notes

*Compiled 11 Nov 2026*

## 1. The question

The system reads a continuous news stream on a theme (e.g. AI). It has to:

- discover topics (clusters), possibly hierarchical
- decide whether a new article belongs to an existing topic or spawns a new one
- track each topic's lifecycle: emerging, trending, quiet, dying

**Hypothesis:** LLM memory research (episodic and semantic memory, consolidation, forgetting) maps onto this problem and can contribute new ideas.

**Verdict:** partly confirmed. The two problems are structurally the same, but almost no work bridges them explicitly. Memory research adds 2–3 genuinely new ideas; on lifecycle scoring it adds nothing new.

---

## 2. Mapping between the two fields

| Topic tracking | LLM memory equivalent |
|---|---|
| Assign article to topic vs spawn a new one | Memory write decision. Mem0 retrieves similar memories and an LLM chooses ADD / UPDATE / DELETE / NOOP |
| Topic hierarchy (story → topic → event) | Zep/Graphiti graph tiers: episode → semantic entity → community. StreamBench uses story → topic → event |
| Trending / dying topics | Heat and forgetting. MemoryOS heat score (visits + length + exponential recency decay); BERTrend popularity with decay. Same idea, nothing new |
| Topic summary card | Karpathy's **LLM Wiki** (April 2026 gist): the LLM maintains a persistent markdown knowledge base, with a periodic "lint" pass for contradictions, stale claims and orphan pages |

Classic TDT already noted that single-pass clustering has to maintain a "memory" of events.

---

## 3. What memory research actually adds

1. **Two-speed processing: fast write, slow consolidation.**
   - The Synthetic Fire Drill benchmark found that stream clusterers (DBSTREAM, DenStream) detect new topics *only by absorbing them into existing clusters, never by forming new ones*. Only windowed re-clustering (BERTrend) produced a genuine emergence signal.
   - The fix borrowed from memory work is an offline "sleep" pass that re-clusters, merges and splits:
     - **LightMem**: sleep-time consolidation.
     - **RecMem**: consolidate a group only once its items recur enough to form a semantic cluster.
     - **Letta**: sleep-time agents.
   - This directly targets the weak point of incremental clustering plus a velocity score.

2. **Structured cluster cards instead of bare centroids.**
   - StreamBench: event-organised "structural cues" (people, location, result, attributes) improved LLM stream clustering by up to +4.37 B³-F1.
   - The authors name incremental external memory as future work.

3. **Bi-temporal state and invalidation.**
   - Zep marks contradicted facts with an `invalid_at` timestamp instead of deleting them, and tracks both when an event happened and when it was ingested.
   - This matters because tracking an entity's *current* state is the hardest part: StreamBench left 21% errors even with cues.

**What doesn't transfer:**
- Memory benchmarks are conversational QA. They don't test novelty or cluster structure.
- Mem0 makes about two LLM calls per write, which is too expensive per article.
- Influence currently flows the other way: memory papers import clustering (online clustering vs Online K-Means and DP-means, HDBSCAN-based consolidation).

---

## 4. Evaluation landscape

### Topic / story tracking
- **Metrics:** B³-F1 (main), AMI and ARI, averaged over sliding windows (typically 7-day windows with a 1-day slide).
- **Systems:** USTORY, SCStory, PromptStream, Miranda et al., newsLens, StoryForest, Staykovski.

### Emergence / weak signals
- There is **no standard benchmark**; BERTrend says so explicitly.
- **Synthetic Fire Drill (2026):**
  - Injects LLM-written articles about *fictitious* topics into real news streams, so ground truth is complete.
  - Metrics: detection rate, *enrichment* (density of the topic in its cluster vs its base rate), permutation significance, latency.
  - Key finding: detection rate alone is misleading.
- **BERTrend:** labels topics as noise, weak signal or strong signal using popularity percentiles (10th / 50th).

### Memory
- **Benchmarks:**
  - LoCoMo: 10 conversations.
  - LongMemEval: 500 questions covering extraction, multi-session reasoning, temporal reasoning, knowledge updates and abstention.
  - MemoryAgentBench, EvoMemBench.
- **Metrics:** QA accuracy or LLM-as-judge, plus tokens and latency.
- **Caveat:** Zep argues LoCoMo is flawed (full context beats memory systems; no knowledge-update questions).

---

## 5. Simplest baselines

- **Single-pass centroid clustering with a similarity threshold.** TF-IDF beat doc2vec on news.
- **DBSTREAM / DenStream** from the River library.
- **Cosine novelty detector:** max similarity to the last N articles. It fails on bursts (0/32 detections), because sibling articles mask each other.
- **BERTrend:** windowed BERTopic plus a popularity metric.
- **Memory side:** full context, BM25, dense RAG. BM25 scored 88.8 on retention vs 79.2 for Mem0 on EvoMemBench.

---

## 6. Datasets

Constraint: private network with no Hugging Face access; GitHub probably available.

| Dataset | Content | Host | Notes |
|---|---|---|---|
| Miranda et al. (News14) | EN ~21k articles / 808 stories, plus ES and DE | Priberam FTP via [news-clustering](https://github.com/Priberam/news-clustering) | The standard benchmark. Features-only copy on [Zenodo](https://zenodo.org/records/6630367) |
| UCI News Aggregator | 422,937 titles + URLs with story IDs and timestamps | [UCI](https://archive.ics.uci.edu/dataset/359/news+aggregator) | CC BY 4.0, easiest licence |
| OG2021 (Tokyo Olympics) | 10,940 articles, 1,350 event clusters, 9 languages | [CLARIN.SI public](https://clarin.si/repository/xmlui/handle/11356/1922) / [full text](https://clarin.si/repository/xmlui/handle/11356/1921) | CC BY-NC-ND; dense concurrent events |
| HLGD | 10 timelines, ~20k headline pairs | [GitHub release](https://github.com/tingofurro/headline_grouping) | Headlines only |
| WCEP18/19 | 10,200 event clusters | [complementizer/wcep-mds-dataset](https://github.com/complementizer/wcep-mds-dataset) | Summaries on Google Drive; articles must be scraped (takes days) |
| StreamBench | 605 events, 15,354 docs, 3-level hierarchy | [Zenodo](https://doi.org/10.5281/zenodo.20501891) | Best match for hierarchy |
| LoCoMo (memory) | 10 long conversations | [snap-research/locomo](https://github.com/snap-research/locomo) `data/locomo10.json` | CC BY-NC 4.0 |
| Synthetic Fire Drill | Synthetic articles, embeddings, ground truth | Stated as released | Repository URL not found; contact the authors |

**Suggested order:** UCI News Aggregator → Miranda English → StreamBench. Check licences: several are non-commercial.

---

## 7. Practical plan inside the private network

1. **Fire-Drill-style injection evaluation on your own stream.** Needs only an internal LLM; directly measures early detection and lead time.
2. **HLGD or Miranda** as a sanity check for the assign-vs-spawn decision, scored with B³-F1.
3. **Transfer the small public datasets once,** through an approved channel.
4. **Baselines:** single-pass centroid and cosine novelty (a few lines each); DBSTREAM and DenStream need `river`.

### Candidate experiment
Incremental clustering plus an offline consolidation pass (re-cluster, merge, split, LLM cluster cards), evaluated with injected fictitious topics. Metrics: detection rate, enrichment, latency.

---

## 8. Practical snippets

### Download the Miranda dataset on macOS (curl instead of wget)
```bash
#!/usr/bin/env bash
set -euo pipefail
BASE="ftp://ftp.priberam.pt/SUMMAPublic/Corpora/Clustering/2018.0"
FILES=(
  "dataset/dataset.dev.json"
  "dataset/dataset.test.json"
  "dataset-tok-ner/clustering.dev.json"
  "dataset-tok-ner/clustering.test.json"
)
mkdir -p dataset
for f in "${FILES[@]}"; do
  name="$(basename "$f")"
  curl --fail --retry 3 -C - --user 'ftp.priberam.pt|anonymous:' -o "dataset/$name" "$BASE/$f" \
  || curl --fail --retry 3 -C - --user 'anonymous:' -o "dataset/$name" "$BASE/$f"
done
ls -lh dataset
```
Corporate networks often block FTP, so download from a personal network.

### Password-protected archive
```bash
# macOS encrypted disk image (AES-256, built in)
hdiutil create -encryption AES-256 -srcfolder dataset -format UDZO dataset.dmg

# Cross-platform 7z (AES-256, file names also hidden)
brew install p7zip
7z a -p -mhe=on dataset.7z dataset/
```
Avoid `zip -e`: its ZipCrypto encryption is weak. Corporate security tools may block encrypted archives; prefer the firm's approved transfer process.

---

## 9. Key references

- Karpathy, *LLM Wiki* gist (Apr 2026): https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
- StreamBench, *Can Structural Cues Save LLMs?* (KDD'26): https://arxiv.org/abs/2603.19250
- *The Synthetic Fire Drill* (BDCC 2026): https://www.mdpi.com/2504-2289/10/9/314
- BERTrend (FuturED@EMNLP 2024): https://arxiv.org/abs/2411.05930
- USTORY (SIGIR'23): https://arxiv.org/abs/2304.04099 · code https://github.com/cliveyn/ustory
- SCStory (WWW'23): https://arxiv.org/abs/2312.03725
- Miranda et al., *Multilingual Clustering of Streaming News* (EMNLP'18): https://arxiv.org/abs/1809.00540
- Mem0: https://arxiv.org/abs/2504.19413
- Zep / Graphiti: https://arxiv.org/abs/2501.13956
- MemoryOS: https://arxiv.org/abs/2506.06326
- LightMem (ICLR'26): https://arxiv.org/abs/2510.18866
- RecMem (ACL Findings 2026): https://aclanthology.org/2026.findings-acl.1619.pdf
- Letta, sleep-time compute: https://letta.com/blog/sleep-time-compute
- LongMemEval: https://github.com/xiaowu0162/LongMemEval
- MemoryAgentBench: https://arxiv.org/abs/2507.05257
- EvoMemBench: https://arxiv.org/html/2605.18421
- SuperLocalMemory "The Living Brain": https://huggingface.co/papers/2604.04514
