# Reviewer 7: Literature and Citation Verification Report

**Manuscript:** *Does Increasing Government Spending on Tertiary Education Improve the Future Tax Take? A Bayesian Causal Inference Analysis* (`paper/paper.tex`, `paper/paper.md`, `paper/references.bib`, and `literature/literature.csv`)  
**Referee Role:** Literature and Citation Verification Referee (Phase 6 Audit)

---

## Executive Summary and Overall Verdict

I have completed a comprehensive bibliographic, substantive, and chronological citation audit of `paper/paper.tex`, `paper/paper.md`, `paper/references.bib` (61 entries), and `literature/literature.csv` (58 rows covering 57 unique keys).

1. **Authenticity of References and DOIs:** All 61 entries in `paper/references.bib` correspond to genuine, real-world publications, working papers, or official datasets with valid DOIs/URLs. None of the references are fabricated.
2. **Audit of 14 Selected Papers (Part 1 below):** Across the 14 audited papers spanning continuous-treatment causal inference, random forests, proper scoring rules, forecast comparison, Bayesian causal forests, and public finance/higher education returns, the substantive and methodological claims in `paper/paper.tex` are well supported, subject to four specific bibliographic/attribution corrections detailed below:
   - **`hirano2004propensity` is uncited in `paper/paper.tex`:** It appears in `paper/references.bib` (lines 583-592), `literature/literature.csv` (row 51), and `paper/paper.md` (lines 25 and 104), but is never cited in `paper/paper.tex`.
   - **`mcjames2024mvbcf` page numbers and year synchronisation:** In `paper/references.bib` (line 31), the page range is listed as `510--531`, whereas the published *JRSS Series A* (Vol. 188, Issue 2, 2025, `10.1093/jrsssa/qnae049`) pagination is `428--450`. In addition, `literature/literature.csv` (row 3) lists the year as `2024` whilst `paper/references.bib` lists `2025`.
   - **`woody2021model` duplicate conflicting row in `literature/literature.csv`:** Whilst `paper/references.bib` (lines 87-96) and `paper/paper.tex` (line 103) are completely accurate (`Woody, Carvalho, and Murray, 2021`, *JCGS* 30(1): 144-161, DOI `10.1080/10618600.2020.1796684`), `literature/literature.csv` contains two rows for `woody2021model`: row 10 (accurate) and a duplicate row 53 that erroneously adds `Hahn, P. Richard` as an author, lists a non-matching DOI (`10.1080/10618600.2020.1844214`), and claims the paper extends BCF to continuous treatment slopes (which also spilled over into `paper/paper.md` lines 25 and 108).
   - **`chakrabarti2020state` outcome precision and `ting2025estimating` first name:** In `paper/paper.tex` (line 97), `chakrabarti2020state` is described as showing that state appropriations "boost graduates' earnings into their thirties"; because Chakrabarti et al. (2020) link National Student Clearinghouse data to New York Fed/Equifax consumer credit records (which measure student debt, credit scores, home/auto ownership, and neighbourhood income rather than direct individual wage records), "improve students' long-term financial outcomes and neighbourhood income into their thirties" is more faithful to the source. Additionally, in `paper/references.bib` (line 530), the first author of `ting2025estimating` (`10.1080/01621459.2025.2491155`) is **Angela Ting**, not `Ting, Andrew`.
3. **Chronological and Alphabetical Ordering Audit (Part 2 below):** I audited every multi-reference citation command in `paper/paper.tex` and `paper/paper.md`. I found **5 strictly out-of-chronological-order citation lists** (plus **3 same-year non-alphabetical citation lists**) in `paper/paper.tex`, and **4 strictly out-of-chronological-order citation lists** (plus **3 same-year non-alphabetical citation lists**) in `paper/paper.md`. Exact line numbers and fixes are provided in Part 2.

---

## Part 1: Detailed Verification of 14 Selected Cited Papers

### 1. `robinson1988root`
- **BibTeX Record (`paper/references.bib`, lines 594-603):** Robinson, Peter M. (1988), "Root-$N$-Consistent Semiparametric Regression", *Econometrica* 56(4): 931-954, DOI `10.2307/1912705`.
- **Exact Sentence(s) in `paper/paper.tex`:** Line 103.
- **Verification Verdict:** **Genuine and Justified.** All bibliographic details and the JSTOR DOI (`10.2307/1912705`) are exact. Robinson (1988) establishes the classic partially linear model $Y = \theta Z + g(X) + \varepsilon$ where conditioning on / partialling out $\mathbb{E}[Z \mid X]$ orthogonalises a continuous regressor $Z$ against nonparametric confounders $X$.

### 2. `hirano2004propensity`
- **BibTeX Record (`paper/references.bib`, lines 583-592):** Hirano, Keisuke and Imbens, Guido W. (2004), "The Propensity Score with Continuous Treatments", in *Applied Bayesian Modeling and Causal Inference from Incomplete-Data Perspectives*, pp. 73-84, Wiley, DOI `10.1002/0470090456.ch7`. <!-- style-check: ignore -->
- **Verification Verdict:** **Genuine Reference, Uncited in `paper.tex` (Action Required).** Cite `\citep{hirano2004propensity}` in `paper/paper.tex` (e.g., in Section 1 or Section 2.3 when introducing continuous-treatment causal inference under unconfoundedness) so that `references.bib` has zero uncited entries.

### 3. `breiman2001random`
- **BibTeX Record (`paper/references.bib`, lines 605-614):** Breiman, Leo (2001), "Random Forests", *Machine Learning* 45(1): 5-32, DOI `10.1023/A:1010933404324`.
- **Verification Verdict:** **Genuine and Justified.** Cited on Line 179 for random forest regression ensembles.

### 4. `wright2017ranger`
- **BibTeX Record (`paper/references.bib`, lines 616-625):** Wright, Marvin N. and Ziegler, Andreas (2017), "`ranger`: A Fast Implementation of Random Forests for High Dimensional Data in C++ and R", *Journal of Statistical Software* 77(1): 1-17, DOI `10.18637/jss.v077.i01`.
- **Verification Verdict:** **Genuine and Justified.** Cited on Line 179 for the `ranger` C++/R implementation.

### 5. `gneiting2007strictly`
- **BibTeX Record (`paper/references.bib`, lines 627-636):** Gneiting, Tilmann and Raftery, Adrian E. (2007), "Strictly Proper Scoring Rules, Prediction, and Estimation", *Journal of the American Statistical Association* 102(477): 359-378, DOI `10.1198/016214506000001437`.
- **Verification Verdict:** **Genuine and Justified (Fix Order in Multi-Cite on Line 316).** Reorder `\citealt{gneiting2007strictly, diebold1995comparing}` to `\citealt{diebold1995comparing, gneiting2007strictly}`.

### 6. `diebold1995comparing`
- **BibTeX Record (`paper/references.bib`, lines 638-647):** Diebold, Francis X. and Mariano, Roberto S. (1995), "Comparing Predictive Accuracy", *Journal of Business & Economic Statistics* 13(3): 253-263, DOI `10.1080/07350015.1995.10524599`.
- **Verification Verdict:** **Genuine and Justified (Fix Order in Multi-Cite on Line 316).**

### 7. `woody2021model`
- **BibTeX Record (`paper/references.bib`, lines 87-96):** Woody, Spencer, Carvalho, Carlos M., and Murray, Jared S. (2021), "Model Interpretation Through Lower-Dimensional Posterior Summarization", *Journal of Computational and Graphical Statistics* 30(1): 144-161, DOI `10.1080/10618600.2020.1796684`. <!-- style-check: ignore -->
- **Verification Verdict:** **Genuine and Justified in `paper.tex` and `references.bib`; Remove Duplicate Row 53 in `literature.csv` and Align `paper.md`.**

### 8. `mcjames2024mvbcf`
- **BibTeX Record (`paper/references.bib`, lines 25-34):** McJames, Nathan, O'Shea, Ann, Goh, Yong Chen, and Parnell, Andrew C. (2025), "Bayesian Causal Forests for Multivariate Outcomes: Application to Irish Data From an International Large Scale Education Assessment", *JRSS Series A* 188(2): 428-450, DOI `10.1093/jrsssa/qnae049`.
- **Verification Verdict:** **Genuine and Justified.** Update `pages={510--531}` to `pages={428--450}` in `paper/references.bib` (line 31), update `year` from `2024` to `2025` in `literature/literature.csv` (row 3), and swap the order in `paper/paper.tex` line 103 to `\citep{mcjames2024lbcf, mcjames2024mvbcf}`.

### 9. `jensen2022employment`
- **BibTeX Record (`paper/references.bib`, lines 175-184):** Jensen, Anders (2022), "Employment Structure and the Rise of the Modern Tax System", *American Economic Review* 112(1): 213-234, DOI `10.1257/aer.20191528`.
- **Verification Verdict:** **Genuine and Justified (Fix Order in Line 333 Multi-Cite).**

### 10. `kleven2016why`
- **BibTeX Record (`paper/references.bib`, lines 207-216):** Kleven, Henrik Jacobsen, Kreiner, Claus Thustrup, and Saez, Emmanuel (2016), "Why Can Modern Governments Tax So Much? An Agency Model of Firms as Fiscal Intermediaries", *Economica* 83(330): 219-246, DOI `10.1111/ecca.12182`.
- **Verification Verdict:** **Genuine and Justified.**

### 11. `valero2019economic`
- **BibTeX Record (`paper/references.bib`, lines 312-320):** Valero, Anna and Van Reenen, John (2019), "The Economic Impact of Universities: Evidence from Across the Globe", *Economics of Education Review* 68: 53-67, DOI `10.1016/j.econedurev.2018.09.001`.
- **Verification Verdict:** **Genuine and Justified.**

### 12. `chakrabarti2020state`
- **BibTeX Record (`paper/references.bib`, lines 344-352):** Chakrabarti, Rajashri, Gorton, Nicole, and Lovenheim, Michael F. (2020), "State Investment in Higher Education: Effects on Human Capital Formation, Student Debt, and Long-Term Financial Outcomes of Students", NBER Working Paper 27885, DOI `10.3386/w27885`.
- **Verification Verdict:** **Genuine Reference, Minor Substantive Refinement Recommended on Line 97.** Change *"boost graduates' earnings into their thirties"* to *"improve students' long-term financial outcomes and neighbourhood income into their thirties"*.

### 13. `hendren2020unified`
- **BibTeX Record (`paper/references.bib`, lines 301-310):** Hendren, Nathaniel and Sprung-Keyser, Ben (2020), "A Unified Welfare Analysis of Government Policies", *The Quarterly Journal of Economics* 135(3): 1209-1318, DOI `10.1093/qje/qjaa006`.
- **Verification Verdict:** **Genuine and Justified.**

### 14. `ting2025estimating`
- **BibTeX Record (`paper/references.bib`, lines 528-534):** Ting, Angela and Linero, Antonio R. (2025), "Estimating Heterogeneous Causal Mediation Effects with Bayesian Decision Tree Ensembles", *JASA*, DOI `10.1080/01621459.2025.2491155`.
- **Verification Verdict:** **Genuine Paper and DOI.** In `paper/references.bib` (line 530), change `author={Ting, Andrew and Linero, Antonio R.}` to `author={Ting, Angela and Linero, Antonio R.}`.

---

## Part 2: Complete Audit of Multi-Reference Citation Ordering

1. **`paper/paper.tex`, Line 62:** `\citep{trostel2010fiscal, hendren2020unified, chakrabarti2020state}` -> `\citep{trostel2010fiscal, chakrabarti2020state, hendren2020unified}`
2. **`paper/paper.tex`, Line 87:** `\citep{gordon2009tax, besley2009origins, besley2014pillars}` -> `\citep{besley2009origins, gordon2009tax, besley2014pillars}`
3. **`paper/paper.tex`, Line 101:** `\citep{imai2010general, vanderweele2016mediation, acharya2016explaining, ting2025estimating}` -> `\citep{imai2010general, acharya2016explaining, vanderweele2016mediation, ting2025estimating}`
4. **`paper/paper.tex`, Line 103:** `\citep{mcjames2024mvbcf, mcjames2024lbcf}` -> `\citep{mcjames2024lbcf, mcjames2024mvbcf}`
5. **`paper/paper.tex`, Line 181:** `(following \citealt{hahn2020bayesian}; see also \citealt{chipman2010bart} and \citealt{hill2011bayesian})` -> `(see \citealt{chipman2010bart}, \citealt{hill2011bayesian}, and \citealt{hahn2020bayesian})`
6. **`paper/paper.tex`, Line 316:** `\citealt{gneiting2007strictly, diebold1995comparing}` -> `\citealt{diebold1995comparing, gneiting2007strictly}`
7. **`paper/paper.tex`, Line 333:** `\citep{kleven2016why, jensen2022employment, valero2019economic}` -> `\citep{kleven2016why, valero2019economic, jensen2022employment}`
8. **`paper/paper.tex`, Line 348:** `\citep{hanushek2012better, angrist2021measuring, hendren2020unified}` -> `\citep{hanushek2012better, hendren2020unified, angrist2021measuring}`
9. **Corresponding multi-reference lists in `paper/paper.md` (Lines 21, 41, 55, 116, 170, 182, 196):** Reorder identically.
