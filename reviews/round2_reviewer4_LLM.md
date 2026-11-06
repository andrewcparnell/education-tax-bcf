# Review (second round): *Does Increasing Government Spending on Tertiary Education Improve the Future Tax Take? A Bayesian Causal Inference Analysis*

**Revised manuscript dated 6 November 2026. Intended destination: arXiv preprint.**

---

## 1. Overall impression

Yes, this is a great deal better, and in places it is now genuinely impressive. The response to the first round has been substantive rather than cosmetic. Credible intervals are reported at a single width throughout, so the earlier impression of cherry-picked uncertainty has gone. The 19 baseline covariates and 8 moderators are now listed in full. Sequential g-estimation (R9) has been implemented rather than merely cited, country fixed effects are now shown at both horizons with an honest acknowledgement that the +10-year version attenuates, a non-compositional negative control (R11) has been added, a pre-COVID restriction (R12) has been added, two-way fixed effects and cross-fitted double machine learning have joined the benchmark table on a common sample, pre-trend controls (R10) directly answer the earlier placebo worry, and the priority claim has been narrowed to something defensible. The conflict-of-interest paragraph in Section 2.3 about co-authorship of the mvbcf and lbcf methods is exactly the right instinct and does the paper credit. Section 5.1 now flags explicitly that the 95% CI for Non-Resource Tax / GDP crosses zero. The Metropolis-Hastings acceptance ratio in Equation (5) is correctly specified, including the nog-node count in the transition ratio, which is a detail many BART papers get wrong. The prose is more readable, the voice is more confident, and the limitations section is noticeably more honest.

What remains is a smaller number of deeper problems, two of which are new to me because the revision made them visible. The first is structural: Outcome 2 is constructed as Outcome 1 multiplied by Outcome 3, so the four "disaggregated channels" contain at most two independent pieces of information, and the paper's own introduction is the strongest argument against doing this. The second is a specification issue in the revised lbcf: the baseline-differenced trajectory sets the wave-0 outcome identically to zero for every country while retaining an additive µ0 forest and a residual term at that wave, which plausibly explains why the lbcf intervals are 30 to 40% narrower than the mvbcf intervals on effectively the same data, and the lbcf now supplies the most confident numbers in the abstract. Third, R12 is the most important new result in the paper and it is understated: dropping the pandemic outcome wave roughly halves the headline compositional effect (+1.48 to +0.74) and the direct income tax to GDP effect (+0.34 to +0.17), which the text describes only as widened intervals. Fourth, R11 shows that goods and services tax as a share of GDP also rises (+0.25 pp, P = 0.803), so the negative control passes only in its compositional form, which is the artefact described above. If this were a journal submission I would now say major revisions with a clear path to acceptance, rather than the reject-and-resubmit territory of the first version. For arXiv, I would fix the lbcf specification, rewrite the R12 and R5 paragraphs, and add one paragraph on the outcome algebra, and then post it without further hesitation. That is perhaps a week of work, not three.

---

## 2. Major concerns

### M1. The four tax outcomes contain at most two independent pieces of information

Section 3.2 defines Outcome 2 as `NonResTax × IncomeTax/Rev / 100`, that is, Outcome 1 multiplied by Outcome 3 and rescaled. Outcome 4 is the complement share of Outcome 3 within the same revenue denominator (Table 8 gives residual correlations of −0.42 and −0.58). So of the four channels, one is a level, one is a composition, one is their product, and one is the composition's mirror image.

This matters in three ways.

First, it undercuts the paper's own framing. The introduction's opening methodological complaint is that multiplying a tax ratio by GDP per person "automatically inflates the outcome by mathematical identity". Outcome 2 is built by exactly that kind of multiplication, just with a different second factor. A reader who accepts the introduction's logic will apply it here. You need to confront this head-on in Section 3.2, explain why the product is nonetheless the quantity of policy interest (it is, since it is the actual revenue share of GDP), and show that the result is not mechanically inherited. The cleanest demonstration would be to decompose the estimated effect on Outcome 2 into the level and composition components and show how much comes from each.

Second, the "borrowing strength across correlated tax outcomes" argument in Section 5.4 is weaker than presented. The strong residual correlations (+0.60, +0.71, +0.75) are partly constructed rather than discovered, so the efficiency gain is not evidence that the multivariate model is learning something about shared economic shocks.

Third, and most importantly for the headline, "the shift toward direct income taxation of +1.48 pp of revenue" and "the rise in direct income taxes of +0.34 pp of GDP" are not two independent confirmations of the same story. They are largely the same finding expressed twice. The abstract currently reads as though three or four distinct channels all point the same way. I would restructure the results around the two genuinely independent dimensions: does the tax take rise (Outcome 1), and does its composition shift (Outcome 3), with Outcome 2 presented as the policy-relevant combination rather than as separate evidence.

### M2. The revised lbcf contains a degenerate wave-0 row, and its unexplained precision gain

Equation (6) defines the baseline-differenced trajectory with Ỹ(i,0) = 0 by construction for every country, then models Ỹ(i,w) = µ0(X) + G1·[...] + G2·[...] + ε for all three waves including w = 0. At w = 0 both step indicators vanish, so the model is fitting µ0(X) plus a residual to an outcome that is identically zero for all 282 countries.

Two consequences follow. The µ0 forest is being asked to predict a constant, so its 75 trees are either shrunk to nothing (in which case they are wasted) or are absorbing structure that does not exist. More seriously, one third of the rows in the likelihood have exactly zero residual by construction, which will deflate the estimated residual variance and therefore narrow every posterior interval in the model. That would explain something I could not otherwise account for: on effectively the same data (N = 282 versus 283), the lbcf posterior SD on Direct Income Tax / GDP is about 0.13 pp against 0.216 pp from the mvbcf, and on Direct Income Tax Share about 0.55 pp against 0.793 pp. A 30 to 40% reduction in posterior SD from reorganising the same observations is not something baseline differencing should buy you for free, and the paper does not attempt to explain it.

This matters because the lbcf supplies the most confident statements in the abstract (+0.40 pp of GDP with P = 0.999; +1.94 pp of revenue with P = 1.000). If those intervals are artificially narrow, the abstract's strongest claims are the least reliable ones.

The fix is straightforward: either drop wave 0 from the likelihood entirely and model only the two increments, or revert µ0 to modelling the baseline *level* Y(i,0) rather than the differenced zero. Then refit and report what happens to the intervals. If the intervals widen materially, say so; if they do not, you will have closed the question and the result will be much stronger for it.

Relatedly, I notice that τ2 yields P = 0.90, 0.90 and 0.90 for three substantively different outcomes, with "compounding probabilities" of 90.1%, 90.1% and 90.2%. Three independent channels agreeing to the third decimal place is unlikely to be coincidence and suggests the τ2 forest is imposing a near-common scaled effect across outcomes rather than estimating three. Worth investigating.

### M3. R12 shows the headline effect roughly halves without the pandemic wave, and the text does not say so

This is the single most important new number in the revision. Dropping the 2020-2024 outcome wave takes the +10-year Direct Income Tax Share effect from +1.48 pp (P = 0.97) to **+0.74 pp (P = 0.77)**, and Direct Income Tax / GDP from +0.34 pp (P = 0.95) to **+0.17 pp (P = 0.71)**. Both point estimates halve and both lose credibility. The text describes this only as "losing a third of the sample widens the intervals on the disaggregated components", which is not what happened: the centres moved as much as the widths did.

Interestingly, the aggregate Non-Resource Tax / GDP effect goes the other way, strengthening to +0.71 pp (P = 0.92). So the pre-COVID sample tells a partly different story from the full sample: more aggregate revenue, less compositional shift. That is a genuinely interesting finding and it deserves a paragraph of its own rather than a half-clause. It also raises an obvious question that the paper should answer: is the compositional result partly a pandemic artefact, driven by the collapse of consumption bases (and hence VAT receipts) in 2020-2021 relative to salaried income, which was far better protected by furlough schemes and automatic withholding? That mechanism would produce exactly the pattern you observe, and it is not the mechanism Section 6.1 proposes.

Please rewrite this bullet honestly, promote R12 into the main results discussion, and either defend the full-sample result against this reading or soften the headline accordingly.

### M4. The negative control fails in levels

R11 is the right check and I am glad it is here. But look at what it returns: goods and services tax as a share of GDP rises by **+0.25 pp (P = 0.803)**, while direct income tax as a share of GDP rises by +0.30 pp (P = 0.939). Those are not very different. The text reports R11 as confirming "that indirect consumption taxes do not drive the fiscal dividend", which is not what a positive point estimate with P = 0.80 says.

Taken with M1, the picture is this: treated countries appear to collect somewhat more of everything, and the apparent *specificity* toward direct taxation rests entirely on the compositional outcomes, which are constrained to move in opposite directions. The claim in Section 5.1 point 3 that specificity is "Confirmed by the Negative-Control Channel", when the 95% CIs are [−1.41, +0.73] and [−2.02, +1.05], is not supportable. A result consistent with zero does not confirm anything.

The benchmark table compounds this. B4 (local projections) gives +0.72 on Goods Tax Share and B6 (double ML) gives +0.50, both positive, both unmentioned. So the negative control has the wrong sign under two of the four alternative estimators and under the non-compositional definition. I would retitle that finding as "Weak evidence of specificity" and describe it as a channel on which the data are uninformative, which is honest and does not damage the rest of the paper.

### M5. The placebo is still reported selectively

R5 now sits alongside R10, which is the correct methodological response and a good one. But the text still quotes only the smallest of the three placebo estimates: "small, noisy estimates (+0.07 pp on Direct Income Tax / GDP, P = 0.663)". The table in the same subsection gives **+0.59 pp on Direct Income Tax Share with P = 0.83**, which is roughly half the +5-year effect of +1.24 pp that the paper leads with, and **+0.24 pp on Non-Resource Tax / GDP with P = 0.79**.

I flagged this last time and it is the one place where the revision did not take the point. It is also unnecessary, because R10 gives you the answer: conditioning explicitly on the four pre-treatment fiscal trends leaves the effect intact and in fact raises it to +1.68 pp (P = 0.979). Say plainly that the raw placebo on the share channel is non-trivial, then show that R10 absorbs it. That sequence is far more persuasive than quoting the one channel where the placebo happens to be near zero, and a sceptical reader who reads the table before the text will notice the discrepancy.

### M6. Convergence diagnostics have improved but are not yet adequate, and the lbcf has none at all

Three specific problems.

**The Geweke test fails on the headline outcome.** Table 9 reports a Geweke z-score of **−3.03** for Income Tax Share at +5 years, which corresponds to a two-sided p of about 0.002: the first and last portions of the chain have different means. That is the chain producing the paper's most-quoted number (+1.24 pp, P = 0.990). The value is printed in the table and discussed nowhere. A reviewer who spots it will assume you did not look. Either run the chain longer until it passes, or explain the failure.

**Still a single chain.** ESS has improved (135 to 267, up from 58 to 345) and interval coverage is now close to nominal (95.4 to 97.5%), both welcome. But R̂ reaches 1.020 and these remain split-chain diagnostics on one chain, which cannot detect a chain stuck in the wrong place. Table 10 says 34 model fits took 973 seconds. Four chains at four times the length would cost about four hours. With ESS around 200, the Monte Carlo standard error on a probability of 0.99 is roughly 0.007, so reporting P = 0.990 and P = 1.000 to three decimals remains unsupportable regardless. Round to two decimals and report MCSE.

**The lbcf has no diagnostics whatsoever.** Table 9 covers only the M2 mvbcf fits. The longitudinal model supplies the abstract's strongest claims and the reader is given no R̂, no ESS, no Geweke, no posterior predictive check and no residual covariance for it. Given M2 above, this is the model that most needs them.

### M7. The propensity score model is still unspecified, and there is still no overlap or balance evidence

The propensity score π̂(X) appears in Equation (3), in Figure 1, in ablation B2 and in R8, but the paper never says what model produces it. Probit? Logit? BART? Random forest? This is not a detail: the whole RIC argument in Hahn et al. (2020) turns on π̂ being a reasonable estimate, and B2's interpretation depends on it. One sentence fixes this.

Section 3.3 now states that the median split yields "balanced common support with 47.3% treated at +5y and 49.8% treated at +10y". That is treatment prevalence, not common support. Common support is a statement about the overlap of the propensity distributions between arms, and a median split guarantees the former while saying nothing about the latter. Please either drop the phrase or supply the evidence: a histogram or density of π̂ by arm, the proportion of units outside the common range, and a standardised-mean-difference balance table for the 19 covariates. For a paper of this methodological ambition, their absence is the most conspicuous remaining gap in the diagnostics.

### M8. The benchmark table is read too finely in places, and its one large disagreement is unmentioned

Table 6 is a real improvement, particularly the move to an identical common sample. But the interpretation in the surrounding text repeatedly reads differences that are far smaller than the posterior uncertainty:

- B2: +0.34 versus +0.28 pp on Direct Income Tax / GDP, against a posterior SD of about 0.2 pp, is described as "showing how propensity score augmentation helps absorb negative selection bias". It shows nothing of the sort; the two are indistinguishable.
- B3: +0.17 versus +0.34 pp is described as "cutting the estimated effect in half" and as evidence of "severe" RIC. Again, these differ by less than one posterior SD.
- B1: the univariate fits give slightly *larger* point estimates, which you note fairly, but the efficiency gain claimed (0.85 to 0.79 pp) is about 7%, not obviously material.

Meanwhile, the one genuinely large disagreement goes unmentioned. On Non-Resource Tax / GDP the six estimators span **−0.26 pp (B5, two-way fixed effects) to +1.13 pp (B6, double ML)** on identical data: a sign flip across a range wider than any of the individual intervals. That is the honest headline of Table 6 and it bears directly on how much weight the aggregate revenue claim can carry. Say it. It will not hurt you, because your compositional result is far more stable across estimators than your level result, and that is itself worth reporting.

Minor but related: B4 to B6 are frequentist and the table labels them with P values. P is defined in Section 1 as a posterior probability given the data, which a local projection does not produce. Either relabel those cells (one-sided p-value complement) or drop the column for those rows.

### M9. Sample composition in Table 3, and subgroup reporting

Two items I raised last time that remain.

**Table 3 still compares across different samples.** Rows 1 and 3 share N = 283, so that comparison is clean and the PPP result is well supported. But the central claim of Section 5.2, that per-student intensity beats aggregate budget share, rests on comparing row 1 (N = 283, 112 countries) with row 4 (N = 403, 123 countries). The extra 120 country-waves will systematically be lower-coverage, poorer countries. Since Table 6 now demonstrates that you are willing and able to construct a common sample, do the same here: re-estimate all four exposures on the intersection and report that as the primary comparison.

**The Nordic result is still undiscussed.** Table 4 row 8 reports −0.72 on Non-Resource Tax / GDP with **P = 0.03**, a credibly negative effect, and the text says nothing about it. This is the only credibly negative estimate anywhere in the paper and it falls in precisely the countries a reader of a public-funding paper will look up first. Two sentences would do: note it, note that 20 observations across 5 countries cannot support a credible CATE, and note that it is the same subgroup where per-student funding is already far above the income-group median so the contrast is between high and very high.

**Numbers in the text that are not in any table.** Section 5.3 quotes CATEs for "all five OECD financing tiers (Nordic High-Public, Low-Tuition Public, Hybrid Public-Fee, High-Tuition High-Subsidy, and High-Tuition Low-Subsidy) ... +1.65 to +1.72 pp, P ∈ [0.906, 0.922]", but Table 4 shows only the Nordic row. Four of the five estimates are unverifiable. This is the same pattern as the untabulated lower-middle-income number in the previous version; please tabulate everything you quote, perhaps in an appendix table. Also, Table 4 row 4 (Low Income, N = 15 across 9 countries) is too small to carry a CATE and its Direct Income Tax Share estimate of −0.03 with CI [−3.31, +2.67] shows it; flag it in the caption.

### M10. Three claims that outrun the evidence, two of them unchanged from the first round

**The cost-benefit assertion.** Section 6.1 still states that "a regime shift or a ≥ 2.5 pp per-student funding expansion typically costs 0.15 to 0.35 percentage points of GDP" with no source and no derivation, and concludes that these investments "more than pay for themselves over a decade". There is still no discounting, no distinction between an annual flow cost and a level change in revenue, and no propagation of posterior uncertainty into the ratio. Given the +10-year intervals on Non-Resource Tax / GDP cross zero under the primary specification, the claim is not supported. Either derive the cost from Table 1 explicitly, construct a posterior for the benefit-cost ratio and report P(ratio > 1), or replace the claim with the much safer statement that the magnitudes are of the same order.

**The moderator arithmetic is still internally inconsistent.** Section 5.4 says five moderators "explain the bulk of systematic CATE variation (surrogate R² = 58.4%)" and then lists 8.1%, 6.1%, 3.7%, 3.7% and 3.4%, summing to 25.0%. That is well under half of 58.4%, exactly as in the previous version with different numbers. State the denominator explicitly and adjust the claim.

**Reverse causality is still absent.** The limitations list names unobserved concurrent reforms, brain drain, government boundaries and wave coarseness, all fair. It does not name the most obvious threat: that fiscal capacity drives education spending rather than the other way round. There is direct evidence for that direction in the same data sources, which the paper should engage with:

- World Bank (2024), *Taxing for Growth: Revisiting the 15 Percent Threshold*, which finds that tax revenue predicts subsequent health and education spending. https://documents1.worldbank.org/curated/en/099062724151523023/pdf/P1778861e0c40b081186a61ced16cac6cde.pdf
- World Bank and UNESCO, *Education Finance Watch 2024*, the natural policy citation for the per-student indicator discussion in Section 3.3.
- The tax-effort literature, which repeatedly finds public education expenditure negatively associated with tax effort in developing economies, for example https://doi.org/10.1080/0376835X.2025.2549280

On methods, two additions would still strengthen Section 2.3, given that mediation is central to the paper:

- Ting, A. and Linero, A. R. (2025), *Estimating Heterogeneous Causal Mediation Effects with Bayesian Decision Tree Ensembles*, JASA. https://doi.org/10.1080/01621459.2025.2491155
- Callaway, B. and Sant'Anna, P. H. C. (2021), *Difference-in-differences with multiple time periods*, Journal of Econometrics. https://doi.org/10.1016/j.jeconom.2020.12.001

I re-checked the reference list in this version and again found no fabricated entries, which is worth saying plainly.

---

## 3. Minor concerns

### Measurement and data

- **The resource adjustment in Equation (1) is ad hoc and mixes two revenue concepts.** The thresholds (half of rents above 10% of GDP, floored at 2%; or 70% of rents) have no source and no sensitivity analysis over those four constants. More importantly, the two branches measure different things: one adjusts *tax* revenue, the other adjusts *total government revenue excluding grants*, which includes non-tax revenue. Which branch a country falls into is not random; it correlates with statistical capacity and hence with development. At minimum, add a binary indicator for the branch used, report how many country-waves fall in each, and check whether the effect differs across them. R1 (raw WDI) partly covers this but only for the branch where WDI tax data exist.
- **The data snapshot has no date.** Section 3.1 cites internal file paths (`data/raw/wb_unesco_imf_wgi_long.csv`). File paths belong in the repository README, not the manuscript. What the manuscript needs instead is the access date and version of each source, since WDI, UIS and SWIID are all revised retrospectively.
- **1,736 = 217 × 8 exactly**, which means the "full harmonised panel" is the complete rectangular frame rather than a count of observed data. Still worth one clarifying sentence plus observed counts per variable.
- **World Bank income group assignment** is still not stated as contemporaneous or fixed, which matters because the treatment is defined relative to within-group medians and countries change groups.
- **Table 1** still reports a low-income median UNESCO ratio of exactly 150.0%, which is the winsorisation cap, so the headline contrast in Section 3.3 is built on a censored value. Report the unwinsorised median alongside. The real PPP column is also still non-monotonic (low income $3,957 exceeds lower-middle $3,258), which complicates your own narrative and deserves a sentence.

### Figures

- **Figure 2** retains a causal assertion as its title ("Government Tertiary Education Spending Increases Direct Tax Capacity Beyond General Growth") when five of the eight 95% intervals cross zero. It also still uses free x-scales across panels measured in different units. Neutral descriptive titles would serve you better and cost nothing.
- **Figure 4** is much improved by the addition of 80% unit-level CI bars, which was exactly the right fix. But the bars now visibly contradict the panel title: most individual units' 80% intervals cross zero, and Table 4 gives +0.90 pp with P = 0.83 for the elite regime. "Positive Across All Tertiary Enrolment Regimes" is no longer defensible given the figure's own content. The fitted smooth's ribbon also remains the uncertainty of a line through posterior means rather than uncertainty in the CATEs, which is now visually jarring beside the wide bars.
- **Figure 5** has the opposite problem from last time. The seven country trajectories now span +1.9 to +2.2 pp, a range of 0.3 pp, against country-level 80% intervals roughly 1.7 pp wide. The heterogeneity has essentially collapsed, so the figure shows seven indistinguishable lines. That is a legitimate finding (the lbcf τ-forest finds little country heterogeneity) but it should be stated as such, and the figure either simplified to the global fan with a note, or kept with an explicit sentence saying the country paths are statistically indistinguishable. The selection rule for the seven countries is also still unstated.
- **Figure 6** still plots horizons rather than chains, so it cannot speak to convergence, and omits the lbcf entirely.

### Tables

- **Table 5's "Comp. Prob." column** still duplicates the P value in the τ2 column exactly (90.1 against 0.90, and so on). Delete it, or define it as something distinct.
- **Table 4 enrolment regimes** sum to 244 of 283; say what happens to the other 39. The income groups now sum correctly to 283, which is a welcome fix.
- **CI bounds printed as "+0.00"** (Table 4 row 1, Table 7 R9) are ambiguous between a true zero and a small positive value. Use an extra decimal place or state the sign.
- **Section 5.5 says "13 ... checks (R1 through R12)"** while the heading says "(R1 to R12)". The count is right because of R3a/R3b, but make the two statements agree.
- **Table 9** would be more useful with MCSE on the ATE and with the lbcf fits included.

### Framing and interpretation

- Section 6.1 point 3 describes the high-income outcome as "a revenue-neutral compositional shift". The Non-Resource Tax / GDP estimate for high-income countries is +0.21 pp with P = 0.68 and CI [−0.75, +1.09]. That is an imprecise estimate, not evidence of neutrality. "No detectable change in the aggregate level" is the accurate phrasing.
- The explanation in Section 4.2 for why M2 exceeds M1 (enrolment dilution as a negative suppressor) is plausible and much better than the previous non-sequitur. But the gap it explains, +1.24 against +1.02 with a posterior SD of 0.55, is well within noise, so the paper now supplies a mechanism for a difference it cannot detect. Either test the difference directly on paired posterior draws, or say that the two are indistinguishable and offer the suppressor account as the reason you would not be surprised by a small gap in either direction. You could also support it directly by showing that the partial dependence of the outcome on forward enrolment change is negative.
- **The numbers have moved materially between versions** (for example, the +10-year Direct Income Tax Share from +1.66 to +1.48, and the lbcf cumulative Non-Resource Tax effect from +0.73 to +0.47). That is entirely legitimate given the data and model changes, but since v1 may already be in circulation, a short "changes from the previous version" note in the repository, or an arXiv v2 comment, would be good practice.
- **Mixed first-person voice.** The revision moved to first person singular, which suits a single-authored paper, but "we" and "our" survive in several places: "our archived World Bank ... dataset" (3.1), "Recall our running example" and "Once we unbundle the denominators" (3.3), "compare our four unbundled tertiary spending definitions" (5.2), "where our findings are rock-solid" (5.5), "our running examples" (6.1). Pick one and sweep.
- **The abstract is still too long for arXiv.** By my estimate it runs to roughly 2,400 to 2,500 characters against the hard limit of 1,920 including spaces, so the submission form will reject it. The inline definition of P can move to the body, and given M1 above, the four-outcome enumeration can be compressed considerably.
- The formal conflict-of-interest statement ("no competing financial or non-financial interests") sits slightly awkwardly beside the honest disclosure in Section 2.3 about co-developing the methods being evaluated. I would add one clause to the declaration pointing to that paragraph, which converts a possible criticism into evidence of care.

---

## 4. Typographical and language issues

Spelling remains consistently British throughout (modernisation, harmonised, winsorised, focussed, whilst, labour) with proper nouns correctly left in their original form, and the title fix to "Government Spending" has been applied in the title, Figure 1 and Figure 2. The following items from the previous round were not picked up, plus a few new ones.

1. **"MIT Licence"** in the Code Availability Statement should be "MIT License", which is the proper name of the licence. <!-- style-check: ignore -->
2. **CRediT statement** still uses hyphens: "Writing - original draft, Writing - review and editing" should use en dashes per the CRediT taxonomy.
3. **Range punctuation remains mixed**: "1985-1989" and "2020-2024" use hyphens, "20–50%" uses an en dash, and Figure 1's subtitle uses a spaced en dash "(1985 − 2024)" which is in fact a minus sign. Standardise on unspaced en dashes for numeric ranges.
4. **"+5 to + 10-year"** with a stray space after the plus still appears in the Table 5 caption and in Appendix A.
5. Section 5.5, R10 bullet: "∆Yi,t−1→tin Xi,t" is missing a space before "in". Possibly a PDF artefact, but check the source.
6. Section 6.2 opens with "Not surprisingly, there are important caveats to consider", which slightly undersells what follows. "Several caveats apply when interpreting observational cross-country panels" reads better.
7. Section 3.1: "Perhaps most frustratingly when working with raw international fiscal archives" is a sentence fragment attached to the following clause; recast.
8. Section 2.3: "the Multivariate and Longitudinal Bayesian Causal Forest extensions on which I am focussing (McJames et al. 2024a,b) were co-developed by the author" mixes first person and third person for the same individual. Use "by me" or recast as "which I co-developed with".
9. "pp" and "percentage points" still alternate without a pattern; define once and use consistently.
10. Reference list: Jennifer Hill still appears as both "J. Hill" (Hill, Linero and Murray 2020) and "J. L. Hill" (Hill 2011).
11. McJames et al. (2024a) is still given as volume 188(2), pages 510-531, year 2024. Volume 188 of JRSS-A is the 2025 volume and the article was advance access in 2024; make the year, volume and pages mutually consistent.

---

## Summary and recommendation

**Verdict: substantially improved, and close to ready.** If this were a journal submission I would now recommend major revisions with a clear route to acceptance. For arXiv, I would fix the following before posting and then post with confidence:

**Blockers (fix before posting)**

1. The lbcf wave-0 degeneracy (M2), since it may be inflating the abstract's most confident numbers.
2. The R12 paragraph (M3), rewritten to report the halving honestly.
3. One paragraph in Section 3.2 confronting the Outcome 2 = Outcome 1 × Outcome 3 construction (M1).
4. The R5 sentence (M5), reporting all three placebo channels and leaning on R10.
5. The Geweke failure (M6), either fixed by longer chains or explained.
6. The abstract cut to under 1,920 characters.

**Strongly recommended**

7. One sentence naming the propensity model, plus an overlap figure and a balance table (M7).
8. Table 3 re-estimated on a common sample (M9).
9. Two sentences on the Nordic subgroup, and tabulation of the five OECD tiers (M9).
10. The cost-benefit claim either derived properly or softened (M10).

**Questions I would be glad to have answered**

1. On the lbcf: is wave 0 actually included in the likelihood, or is it dropped in the implementation and only present in the notation of Equation (6)? If the latter, the equation needs a clarifying sentence and my M2 collapses to a presentational point. If the former, the refit is the priority.
2. Do you have a view on the COVID mechanism behind R12, that consumption bases fell further than withheld salaried income in 2020-2021? If the data can distinguish that from graduate maturation, it would make a strong addition to Section 6.1.
3. What does the partial dependence of the outcome on forward enrolment change look like? If it is negative, you have direct support for the suppressor explanation in Section 4.2 rather than an inference from a difference of means.
4. Is the repository public yet, with a Zenodo DOI? I still cannot confirm it resolves, and `run_all.sh` plus the pipeline tests deserve to be visible, since they are a genuine strength of this version.
