# Online / Stream Clustering for Topic Discovery — Literature Review

*Compiled 11 Nov 2026. Companion to `trend-tracking-memory-research.md`.*

**Scope.** Algorithms that cluster items arriving one at a time (or in small batches) without knowing the number of clusters in advance, viewed through one use case: discovering and tracking topics in a news stream.

**Link legend.** Unmarked links were confirmed in search results during this research. Links marked **†** were written from memory (well-known DOIs / arXiv IDs) and not opened; check them before citing.

---

## 1. Executive summary

1. **Use the family that matches your representation.** Generic stream clusterers (CluStream, DenStream, DBSTREAM) were designed for low-dimensional numeric data. Dense text embeddings (384–1024 dimensions, cosine geometry) are where they are weakest.
2. **The news-clustering field converged on single-pass, threshold-based centroid clustering** with time decay and multiple representations (Miranda 2018 and its descendants). It is simple and still the baseline to beat.
3. **Known failure on emergence.** In the Synthetic Fire Drill benchmark every DBSTREAM and DenStream detection of a new topic came from absorption into an existing cluster, never from a new cluster forming. Only windowed re-clustering (BERTrend) produced emergence signals.
4. **Thresholds are brittle.** DBSTREAM went from 0/22 to 22/22 detections across clustering thresholds 0.8 to 1.2. Methods that adapt the threshold (textClust 2022, EStream) or replace it with a probabilistic "new cluster" term (DP-means, CRP models) are worth attention.
5. **Bayesian nonparametrics is the principled version of "assign or spawn".** The Recurrent Chinese Restaurant Process was built for exactly your problem (storylines in news streams, with popularity decay) in 2008–2011.
6. **Hierarchy is under-used.** Incremental hierarchical methods (PERCH, GRINCH, OHAC, FISHDBC) can revisit earlier decisions, which pure online methods cannot.
7. **The 2025–26 frontier is LLM-in-the-loop clustering**: summaries as centroids (k-LLMmeans, with a streaming variant), LLM memory for clustering (LLM-MemCluster), retrieval-augmented incremental clustering (RAILS).

---

## 2. Surveys — start here

| Survey | Year | Why read it | Link |
|---|---|---|---|
| Silva et al., *Data Stream Clustering: A Survey* (ACM CSUR) | 2013 | The standard reference; online/offline two-phase design, window models | [doi](https://doi.org/10.1145/2522968.2522981) |
| Aggarwal, *A Survey of Stream Clustering Algorithms* (book chapter) | 2013/2018 | By the author of CluStream; includes text streams | [doi](https://doi.org/10.1201/9781315373515-10) |
| Carnein & Trautmann, *Optimizing Data Stream Representation: An Extensive Survey on Stream Clustering Algorithms* | 2019 | Categorises 51 algorithms: distance-threshold, density-grid, statistical-model, high-dimensional | [doi](https://doi.org/10.1007/s12599-019-00576-5) † |
| Zubaroğlu & Atalay, *Data Stream Clustering: A Review* | 2021 | Recent algorithms plus open problems: parameters, no standard evaluation, weak benchmark data | [arXiv](https://arxiv.org/abs/2007.10781) · [doi](https://doi.org/10.1007/s10462-020-09874-x) |
| *A Comprehensive Review on Evolving Data Stream Clustering* (IEEE) | 2021 | Concept drift and window models | [IEEE](https://ieeexplore.ieee.org/document/9616754/) |
| Wang et al., *Data Stream Clustering: An In-depth Empirical Study* (SIGMOD) | 2023 | Empirical comparison of design components | [doi](https://doi.org/10.1145/3589307) |
| Maden & Karagöz, *Recent methods on short text stream clustering: A survey study* | 2023 | The text-stream-specific survey (Dirichlet models, similarity methods, datasets, metrics) | [doi](https://doi.org/10.1002/wics.1610) |
| Nordahl et al., *On Evaluation of Data Stream Clustering Algorithms: A Survey* (IEEE Access) | 2025 | How these algorithms are evaluated: methodologies, datasets, measures | [doi](https://doi.org/10.1109/ACCESS.2025.3596435) |
| Carnein, Assenmacher & Trautmann, *An Empirical Comparison of Stream Clustering Algorithms* | 2017 | 10 algorithms; DBSTREAM best but order-dependent, DenStream inconsistent | [slides](https://pdfs.semanticscholar.org/a435/989fd53977e58cfd5371e90f8b0dc48f17fe.pdf) |

---

## 3. Algorithm families

### 3.1 Partition-based / k-means lineage

Fixed or bounded number of clusters; fast; needs k or a budget.

| Algorithm | Year | Core idea | Link |
|---|---|---|---|
| Sequential k-means (MacQueen) | 1967 | Update the nearest centroid by a running mean, one point at a time | [Project Euclid](https://projecteuclid.org/euclid.bsmsp/1200512992) † |
| STREAM / LSEARCH (Guha, Mishra, Motwani, O'Callaghan) | 2000–03 | Divide the stream into chunks, cluster each to k medians, recluster the medians; theoretical guarantees | [doi](https://doi.org/10.1109/TKDE.2003.1198387) † |
| Mini-batch k-means (Sculley) | 2010 | Stochastic k-means updates on small batches; the practical workhorse (in scikit-learn) | [doi](https://doi.org/10.1145/1772690.1772862) † |
| StreamKM++ (Ackermann et al.) | 2012 | Maintain a coreset (small weighted sample) and run k-means++ on it | [doi](https://doi.org/10.1145/2133803.2184450) † |
| BICO (Fichtenberger et al.) | 2013 | BIRCH data structure + coreset guarantees | [doi](https://doi.org/10.1007/978-3-642-40450-4_41) † |
| Online k-means (Liberty, Sriharsha, Sviridenko) | 2016 | Fully online, opens new clusters with a cost-doubling rule; provable competitive ratio | [arXiv](https://arxiv.org/abs/1412.5721) † |

**For news:** useful as a compute-cheap baseline, but k is unknown and grows over time, so these need a spawn rule bolted on. That leads to 3.2.

### 3.2 Distance-threshold / leader / micro-cluster methods

One pass; assign to the nearest summary if within a radius, otherwise open a new one. This is the family the news-tracking literature uses.

| Algorithm | Year | Core idea | Link |
|---|---|---|---|
| Leader algorithm (Hartigan) / single-pass clustering | 1975 | The original "nearest leader within threshold, else new leader" | (textbook) |
| BIRCH (Zhang, Ramakrishnan, Livny) | 1996 | Clustering Feature (CF) vectors (N, linear sum, squared sum) in a height-balanced tree; the origin of micro-clusters | [doi](https://doi.org/10.1145/233269.233324) † |
| CluStream (Aggarwal, Han, Wang, Yu) | 2003 | CF vectors + timestamps; online micro-clusters, offline macro-clustering over a chosen time horizon (pyramidal snapshots) | [doi](https://doi.org/10.1016/B978-012722442-8/50016-1) † |
| ClusTree (Kranen et al.) | 2011 | Anytime clustering: index micro-clusters in a tree so quality adapts to stream speed | [doi](https://doi.org/10.1007/s10115-010-0342-8) † |
| DP-means (Kulis & Jordan) | 2012 | k-means derived from a Dirichlet process: open a new cluster when distance exceeds λ. A principled threshold | [arXiv](https://arxiv.org/abs/1111.0352) † |
| MAD-Bayes (Broderick, Kulis, Jordan) | 2013 | Generalises the DP-means derivation | [arXiv](https://arxiv.org/abs/1212.2126) † |
| Dynamic Means (Campbell et al.) | 2013 | DP-means for evolving clusters: birth, death, and motion of centroids over time batches | [arXiv](https://arxiv.org/abs/1305.6659) † |
| EvoStream (Carnein & Trautmann) | 2018 | Uses idle time between arrivals to improve macro-clusters with evolutionary optimisation | [doi](https://doi.org/10.1016/j.bdr.2018.05.005) † |

**For news:** this is the core family. The whole design question is the threshold: how it is set, whether it adapts, and whether clusters fade.

### 3.3 Density-based

Arbitrary cluster shapes, native noise handling, decay.

| Algorithm | Year | Core idea | Link |
|---|---|---|---|
| Incremental DBSCAN (Ester et al.) | 1998 | Update DBSCAN clusters locally on insert/delete | [VLDB](https://www.vldb.org/conf/1998/p323.pdf) † |
| DenStream (Cao, Ester, Qian, Zhou) | 2006 | Core / potential / outlier micro-clusters with exponential fading; outliers can be promoted | [doi](https://doi.org/10.1137/1.9781611972764.29) |
| D-Stream (Chen & Tu) | 2007 | Density grid with decay; sporadic grids removed | [doi](https://doi.org/10.1145/1281192.1281210) † |
| DBSTREAM (Hahsler & Bolaños) | 2016 | Micro-clusters plus a shared-density graph between them for reclustering | [doi](https://doi.org/10.1109/TKDE.2016.2522412) |
| EDMStream (Gong et al., VLDB) | 2017 | Tracks evolution of density mountains; 7–15x faster than competitors | [PDF](https://www.vldb.org/pvldb/vol11/p393-gong.pdf) |
| FISHDBC (Dell'Amico) | 2019 | Incremental approximation of HDBSCAN\* for arbitrary distance functions, via HNSW | [arXiv](https://arxiv.org/abs/1910.07283) |
| Bubble-tree / dynamic HDBSCAN (Abduaziz et al.) | 2024 | Dynamic data summarisation to maintain the HDBSCAN hierarchy under inserts and deletes | [arXiv](https://arxiv.org/abs/2412.07789) |
| HDBSCAN (Campello, Moulavi, Sander) — batch reference | 2013 | The offline method most topic pipelines use | [doi](https://doi.org/10.1007/978-3-642-37456-2_14) |

**For news:** grids do not work in embedding dimensions; micro-cluster variants do, with care. Evidence:
- Fire Drill (2026): DenStream detected 15/16 injected topics vs DBSTREAM 10/16 and 12/16, with a lower false-positive floor, but all by absorption.
- Vykhopen et al. (2026) replaced HDBSCAN with online methods in a production narrative-monitoring pipeline and recommend DenStream over DBSTREAM.
- German Text Embedding Clustering Benchmark (2024): DBSTREAM and HDBSCAN were impractically slow on unreduced embeddings; UMAP reduction improved scores by about 13–15%, PCA did not.

### 3.4 Model-based / Bayesian nonparametric

"Assign or spawn" as a probability, with a prior that grows the number of clusters.

| Model | Year | Core idea | Link |
|---|---|---|---|
| Chinese Restaurant Process / Dirichlet Process mixture | 1973– | P(new cluster) ∝ α; P(existing) ∝ cluster size | (textbook) |
| Recurrent CRP / Temporal DPM (Ahmed & Xing, SDM) | 2008 | CRP across epochs: cluster popularity decays, clusters are born, die and evolve. Built for evolutionary clustering of news | [PDF](https://typeset.io/pdf/dynamic-non-parametric-mixture-models-and-the-recurrent-5c8g7pnlyx.pdf) |
| Distance-dependent CRP (Blei & Frazier) | 2011 | Customers link to other customers by distance (e.g. time decay), not to tables | [arXiv](https://arxiv.org/abs/0910.1022) † |
| Infinite Topic-Cluster model: *Storylines from Streaming Text* (Ahmed et al., AISTATS) | 2011 | RCRP storylines at the bottom, LDA topics on top; online inference | [PMLR](https://proceedings.mlr.press/v15/ahmed11a.html) |
| *Unified Analysis of Streaming News* (Ahmed et al., WWW) | 2011 | The same model at Yahoo! News scale, via sequential Monte Carlo | [PDF](https://typeset.io/pdf/unified-analysis-of-streaming-news-51jerubbph.pdf) |
| RCRP with duration-based discount (Diao & Jiang) | 2014 | Events on Twitter; penalises long-lived clusters | [PDF](https://core.ac.uk/download/35456201.pdf) |
| Sequential variational approximation (Lin, NeurIPS) | 2013 | One-pass DP mixture learning | (NeurIPS 2013 †) |
| Memoized online VI for DP mixtures (Hughes & Sudderth, NeurIPS) | 2013 | Birth and merge moves with cached statistics | (NeurIPS 2013 †) |
| Streaming DPMM sampler (Dinari & Freifeld, AISTATS) | 2022 | Adapts the DPMM and a split/merge sampler to streams with drift; Julia + Python code | [arXiv](https://arxiv.org/abs/2202.13312) · [PMLR](https://proceedings.mlr.press/v151/dinari22a.html) |
| Incremental Gaussian Mixture Clustering for Data Streams | 2024 | GMM-based incremental clustering | [arXiv](https://arxiv.org/abs/2412.07217) |

**For news:** the RCRP papers are the closest classical match to your problem statement (emerge, trend, fade, with hierarchy). Worth reading even if you never implement the sampler: the decay kernel and the spawn prior transfer directly to a threshold method.

### 3.5 Incremental hierarchical

| Algorithm | Year | Core idea | Link |
|---|---|---|---|
| BIRCH | 1996 | See 3.2; the tree is a hierarchy | [doi](https://doi.org/10.1145/233269.233324) † |
| PERCH (Kobren, Monath, Krishnamurthy, McCallum, KDD) | 2017 | Route each point to its nearest leaf, then rotate the tree to improve purity and balance; scales to many clusters ("extreme clustering") | [arXiv](https://arxiv.org/abs/1704.01858) |
| GRINCH (Monath et al., KDD) | 2019 | Adds a *graft* move that reattaches subtrees, so earlier mistakes can be undone; any linkage function | [arXiv](https://arxiv.org/abs/2001.00076) |
| OHAC — Online Hierarchical Clustering Approximations (Menon et al.) | 2019 | Rebuild only the path affected by the new point with HAC | [arXiv](https://arxiv.org/abs/1909.09667) † |
| DynHAC (fully dynamic approximate HAC) | 2025 | Supports insertions and deletions | [arXiv](https://arxiv.org/abs/2501.07745) |
| FISHDBC | 2019 | See 3.3; produces a density hierarchy | [arXiv](https://arxiv.org/abs/1910.07283) |

**For news:** this is the natural fit for story → topic → event structure, and "non-greedy incremental" (revisiting decisions) is the property plain online methods lack.

### 3.6 Text-stream-specific

| Algorithm | Year | Core idea | Link |
|---|---|---|---|
| ConStream / *On clustering massive text and categorical data streams* (Aggarwal & Yu) | 2006/2010 | Condensed droplets (word statistics) with fading; the classic text-stream baseline | [doi](https://doi.org/10.1007/s10115-009-0241-z) † |
| Streaming First Story Detection with LSH (Petrović, Osborne, Lavrenko, NAACL) | 2010 | Nearest-neighbour novelty in constant time using locality-sensitive hashing | [ACL](https://aclanthology.org/N10-1021/) † |
| MStream / MStreamF (Yin et al., KDD) | 2018 | Dirichlet-multinomial mixture for short text streams; one-pass or batch, with forgetting | [doi](https://doi.org/10.1145/3219819.3220094) † |
| textClust (Carnein, Assenmacher, Trautmann) | 2017 | TF-IDF micro-clusters with fading; in River | [doi](https://doi.org/10.1007/978-3-319-70625-2_8) |
| OSDM (Kumar et al., ACL) | 2020 | Online (not batch) Dirichlet model with word co-occurrence semantics; number of clusters automatic | [ACL](https://aclanthology.org/2020.acl-main.70/) |
| OSGM (Kumar et al., IEEE Trans. Cybernetics) | 2022 | Evolving topics in term-changing subspaces | [record](https://pesquisa.bvsalud.org/bolivia/resource/es/mdl-34591776) |
| textClust with automated threshold adaption (Assenmacher & Trautmann) | 2022 | Removes the hand-set distance threshold; argues for time-based evaluation | [doi](https://doi.org/10.1007/978-3-031-21743-2_1) |
| Context-enhanced Dirichlet model (Kumar et al.) | 2023 | Successor to OSDM | [doi](https://doi.org/10.1016/j.eswa.2023.120262) |

**For news:** these work on sparse word features, not embeddings. They are a useful contrast arm: TF-IDF beat doc2vec on news stream clustering in Staykovski et al. (2019), and the strongest news systems combine sparse and dense signals.

### 3.7 News story discovery (TDT lineage)

| Work | Year | Core idea | Link |
|---|---|---|---|
| TDT pilot study; on-line new event detection (Allan et al.; Yang, Pierce, Carbonell, SIGIR) | 1998 | Defines first-story detection and tracking; single-pass clustering with a time window | [Allan](https://doi.org/10.1145/290941.290954) † · [Yang](https://doi.org/10.1145/290941.290953) † |
| newsLens (Laban & Hearst) | 2017 | Keyword graph per window + Louvain communities, then link windows into stories | [ACL](https://aclanthology.org/W17-2701/) † |
| Story Forest (Liu et al.) | 2017/2020 | Events organised into story trees; production system at Tencent | [arXiv](https://arxiv.org/abs/1803.00189) † |
| Miranda et al., *Multilingual Clustering of Streaming News* (EMNLP) | 2018 | Online centroid clustering with several representation subspaces + timestamp features; learned (SVM) similarity and merge decisions | [arXiv](https://arxiv.org/abs/1809.00540) |
| Staykovski et al., *Dense vs. Sparse Representations for News Stream Clustering* | 2019 | TF-IDF beats doc2vec; argues for B-cubed F1 | [PDF](https://cris.unibo.it/retrieve/handle/11585/709220/e1dcb333-9b3f-7715-e053-1705fe0a6cc9/paper6.pdf) |
| Linger & Hajaiej, *Batch Clustering for Multilingual News Streaming* | 2020 | Mini-batches instead of strict one-at-a-time | [arXiv](https://arxiv.org/abs/2004.08123) |
| Saravanakumar et al., *Event-Driven News Stream Clustering using Entity-Aware Contextual Embeddings* (EACL) | 2021 | Non-parametric streaming k-means; sparse + dense + temporal similarity fed to a neural classifier | [PDF](https://cdn.amazon.science/99/5b/19d4cf374b64a130b50975856446/event-driven-news-stream-clustering-using-entity-aware-contextual-embeddings.pdf) |
| RevDet (Azeemi et al.) | 2021 | Memory-efficient tracking in large news feeds (GDELT, W2E) | [arXiv](https://arxiv.org/abs/2103.04390) |
| Santos, Mendes, Miranda, *Simplifying Multilingual News Clustering Through Projection From a Shared Space* | 2022 | Drops the supervised parts; open source | [arXiv](https://arxiv.org/abs/2204.13418) |
| USTORY (Yoon et al., SIGIR) | 2023 | Theme- and time-aware embedding, novelty-aware adaptive clustering, lightweight story summaries | [arXiv](https://arxiv.org/abs/2304.04099) · [code](https://github.com/cliveyn/ustory) |
| SCStory (Yoon et al., WWW) | 2023 | Self-supervised continual learning of story-indicative embeddings | [arXiv](https://arxiv.org/abs/2312.03725) |
| Nakshatri et al., *Using LLM for Improving Key Event Discovery* (EMNLP Findings) | 2023 | Temporally guided stream clustering using LLM event summaries | [doi](https://doi.org/10.18653/v1/2023.findings-emnlp.274) |
| PromptStream (Hatefi, Eklund, Forsman, LREC-COLING) | 2024 | Cloze-prompt article representations + continual contrastive learning | [PDF](https://aclanthology.org/2024.lrec-main.1157.pdf) |
| Jiang et al., *Topic Detection and Tracking with Time-Aware Document Embeddings* (LREC-COLING) | 2024 | Fuses time into the embedding | [arXiv](https://arxiv.org/abs/2112.06166) † |
| StreamBench (Lee et al., KDD) | 2026 | LLMs doing incremental clustering directly; structural cues help | [arXiv](https://arxiv.org/abs/2603.19250) |

### 3.8 Online and dynamic topic models

| Model | Year | Core idea | Link |
|---|---|---|---|
| Dynamic Topic Models (Blei & Lafferty) | 2006 | Topics drift across time slices (fixed number of topics) | [doi](https://doi.org/10.1145/1143844.1143859) † |
| Online LDA (Hoffman, Blei, Bach) | 2010 | Stochastic variational inference on mini-batches | [NeurIPS](https://papers.nips.cc/paper/2010/hash/71f6278d140af599e06ad9bf1ba03cb0-Abstract.html) † |
| BERTopic (Grootendorst) + online mode | 2022 | Embed → UMAP → HDBSCAN → c-TF-IDF; online variant swaps in incremental components | [arXiv](https://arxiv.org/abs/2203.05794) · [online docs](https://maartengr.github.io/BERTopic/getting_started/online/online.html) |
| ANTM — Aligned Neural Topic Model | 2023 | Cluster per overlapping window, align across time | [arXiv](https://arxiv.org/abs/2302.01501) † |
| BERTrend (Boutaleb et al.) | 2024 | Windowed BERTopic + topic merging + popularity with decay; noise / weak / strong signal | [arXiv](https://arxiv.org/abs/2411.05930) |
| StreamETM (Granese et al.) | 2025 | Embedded Topic Model per batch, merged with unbalanced optimal transport; online change-point detection | [arXiv](https://arxiv.org/abs/2504.07711) · [code](https://github.com/fgranese/StreamETM) |
| SB-SETM (Granese, Villata, Bouveyron, AISTATS) | 2026 | Stick-breaking prior infers the number of active topics per step; continuous optimal transport for merging; tested on 2022–23 war news | [arXiv](https://arxiv.org/abs/2510.18786) · [PMLR](https://proceedings.mlr.press/v300/granese26a.html) |

### 3.9 LLM-era clustering (2023–2026)

| Work | Year | Core idea | Link |
|---|---|---|---|
| ClusterLLM (Zhang, Wang, Shang, EMNLP) | 2023 | LLM answers triplet questions to refine the embedder and set granularity | [arXiv](https://arxiv.org/abs/2305.14871) † |
| *Large Language Models Enable Few-Shot Clustering* (Viswanathan et al.) | 2023 | LLM for keyphrase expansion, pairwise constraints, post-correction | [arXiv](https://arxiv.org/abs/2307.00524) † |
| TopicGPT (Pham et al.) | 2023 | Prompt-based topic generation and assignment | [arXiv](https://arxiv.org/abs/2311.01449) † |
| *Text Clustering as Classification with LLMs* | 2024/25 | LLM proposes labels, then classifies | [arXiv](https://arxiv.org/abs/2410.00927) † |
| k-LLMmeans — *Summaries as Centroids* (ICLR 2026) | 2025 | k-means whose centroids are LLM summaries, re-embedded; LLM budget independent of dataset size; **mini-batch variant for streams** + a streaming benchmark from StackExchange | [arXiv](https://arxiv.org/abs/2502.09667) |
| LLM-MemCluster | 2025 | Gives the LLM a dynamic memory of clusters while clustering | [arXiv](https://arxiv.org/abs/2511.15424) |
| *Unsupervised text clustering with large language models* | 2026 | Clustering without embeddings; mini-batch online variant | [ResearchGate](https://www.researchgate.net/publication/401127355_Unsupervised_text_clustering_with_large_language_models) |
| RAILS — Retrieval-Augmented Incremental LLM Clustering at Scale | 2026 | Retrieve candidate clusters, let the LLM assign or create | [arXiv](https://arxiv.org/abs/2609.24464) |
| RSM — *Compact-Memory LLM Agents via Online Max-Member Clustering* | 2026 | Online clustering inside agent memory; a merge rule beat Online K-Means and DP-means by 5.7 points | [arXiv](https://arxiv.org/abs/2609.04915) |
| RecMem (ACL Findings) | 2026 | Consolidate only when a group of items recurs enough (similarity and count thresholds) | [PDF](https://aclanthology.org/2026.findings-acl.1619.pdf) |
| Vykhopen et al., *Online Density-Based Clustering for Real-Time Narrative Evolution Monitoring* | 2026 | Production comparison: DBSTREAM, DenStream, textClust vs batch HDBSCAN | [arXiv](https://arxiv.org/abs/2601.20680) |

---

## 4. Evaluation

| Topic | Reference | Link |
|---|---|---|
| B-cubed precision/recall/F1; formal constraints on clustering metrics | Amigó et al. 2009 | [doi](https://doi.org/10.1007/s10791-008-9066-8) † |
| CMM — Cluster Mapping Measure for evolving streams (handles ageing, missed and misplaced points) | Kremer et al., KDD 2011 | [doi](https://doi.org/10.1145/2020408.2020555) † |
| MONIC — modelling cluster transitions (birth, death, split, merge, survive) | Spiliopoulou et al., KDD 2006 | [doi](https://doi.org/10.1145/1150402.1150491) † |
| Dendrogram purity for hierarchies | Used in PERCH / GRINCH | [arXiv](https://arxiv.org/abs/1704.01858) |
| Temporal Topic Quality for dynamic topic models | James et al., ACL 2024 | [arXiv](https://arxiv.org/abs/2309.08627) |
| Survey of how stream clustering is evaluated | Nordahl et al. 2025 | [doi](https://doi.org/10.1109/ACCESS.2025.3596435) |
| Emergence: injected fictitious topics, enrichment, latency | Synthetic Fire Drill 2026 | [MDPI](https://www.mdpi.com/2504-2289/10/9/314) |
| Clustering of embeddings: reduction matters (UMAP yes, PCA no) | German Text Embedding Clustering Benchmark 2024 | [arXiv](https://arxiv.org/abs/2401.02709) |

Practical points:
- Use **prequential / windowed** evaluation (score per sliding window, then average), as USTORY and SCStory do.
- Report **arrival-order sensitivity** (several shuffles of same-timestamp items). DBSTREAM is known to be order-dependent.
- MONIC's transition taxonomy is the right vocabulary for the lifecycle you want to track.

---

## 5. Software

| Library | Contents | Link |
|---|---|---|
| River (Python) | KMeans, STREAMKMeans, CluStream, DenStream, DBSTREAM, TextClust | [site](https://riverml.xyz/) · [paper](https://arxiv.org/abs/2012.04740) † |
| scikit-learn | `Birch`, `MiniBatchKMeans` (`partial_fit`) | [docs](https://scikit-learn.org/stable/modules/clustering.html) |
| MOA (Java) / CapyMOA (Python) | Reference implementations + CMM evaluation | [MOA](https://moa.cms.waikato.ac.nz/) |
| `stream` (R) | DBSTREAM's original home; many algorithms | [CRAN](https://cran.r-project.org/package=stream) |
| BERTopic | Online mode; merge models | [docs](https://maartengr.github.io/BERTopic/) |
| USTORY / SCStory | News story discovery | [USTORY](https://github.com/cliveyn/ustory) |
| Priberam news-clustering | Miranda et al. reference implementation | [GitHub](https://github.com/Priberam/news-clustering) |
| DPMMSubClustersStreaming | Streaming DPMM (Julia, Python wrapper) | [GitHub](https://github.com/BGU-CS-VIL/DPMMSubClustersStreaming.jl) |
| StreamETM | Online embedded topic model | [GitHub](https://github.com/fgranese/StreamETM) |

---

## 6. What this means for the trend-detection system

**Design choices the literature supports**

1. **Represent each article several ways**: dense embedding, sparse TF-IDF or entities, and time (Miranda; Saravanakumar; USTORY).
2. **Reduce dimensionality before density methods** (UMAP, not PCA) or stay with cosine-centroid methods in the original space.
3. **Make the spawn rule explicit and adaptive**: a DP-means-style penalty or textClust-style automatic threshold, rather than a hand-tuned constant.
4. **Add decay to cluster weight** (DenStream fading, RCRP kernel). This doubles as the lifecycle signal.
5. **Add a non-greedy step**: periodic re-clustering of recent or low-confidence items, merges and splits (GRINCH grafts, CluStream offline phase, BERTrend windows, RecMem consolidation). This is the fix for absorption.
6. **Keep a summary per cluster** and compare new items to it (USTORY summaries, k-LLMmeans centroids, StreamBench cues).

**Experiment matrix**

| Arm | Method | Library |
|---|---|---|
| A | Single-pass cosine centroid + time decay (DP-means spawn rule) | ~50 lines |
| B | DenStream on UMAP-reduced embeddings | River |
| C | textClust on TF-IDF | River |
| D | Windowed HDBSCAN + topic matching (BERTrend-style) | BERTopic / hdbscan |
| E | A + periodic consolidation pass | custom |
| F | A with LLM summary centroids (k-LLMmeans streaming) | custom |

Score each on B³-F1 (Miranda / News14), and on injected fictitious topics for emergence: detection rate, enrichment, latency, and whether the topic formed its own cluster.

**Suggested reading order (10 papers)**

1. Silva et al. 2013 (survey)
2. Miranda et al. 2018
3. Cao et al. 2006 (DenStream)
4. Kulis & Jordan 2012 (DP-means)
5. Ahmed et al. 2011 (*Unified Analysis of Streaming News*)
6. Monath et al. 2019 (GRINCH)
7. Yoon et al. 2023 (USTORY)
8. Boutaleb et al. 2024 (BERTrend)
9. *Synthetic Fire Drill* 2026
10. k-LLMmeans (ICLR 2026)
