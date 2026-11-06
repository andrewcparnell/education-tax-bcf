# Review: *Does Increasing Government Spend on Tertiary Education Improve the Future Tax Take? A Bayesian Causal Inference Analysis*

**Reviewer notes prepared 5 November 2026. Intended destination: arXiv preprint (no journal submission).**

---

## 1. Overall impression

This is an ambitious and, in several respects, genuinely clever paper. The three framing hurdles in the introduction are the right ones, and the "UNESCO denominator trap" section is the best idea in the manuscript: the observation that a composite ratio with both GDP per person and student headcount in the denominator inverts the cross-country ordering is sharp, correctly derived in Equation (1), and the unbundling into real PPP dollars per student and budget share is a real methodological contribution. The multivariate and three-wave BCF machinery is well matched to the problem, the use of a fourth tax channel as a specificity check shows good instincts, and the robustness suite (R1 to R8) is more thorough than most macro-fiscal papers manage. The writing is clear and well organised, the mathematical appendix is correct as far as I can check it, and the reference list is, unusually for a paper of this kind in 2026, almost entirely real. I checked the two McJames references and both exist and match (arXiv:2407.11927 and the JRSS-A paper, DOI 10.1093/jrsssa/qnae049), and I spot-checked a dozen others without finding a hallucination.

That said, I would not post this to arXiv in its present state, and if it came to me from a journal I would recommend major revisions bordering on reject-and-resubmit. The core problem is not the method, it is the gap between what the models estimate and what the paper claims. The headline conclusion rests on a result whose own placebo test (R5) recovers roughly half of it in pre-treatment data, a fact the text passes over by quoting only the smallest of the three placebo numbers. The abstract switches to 80% credible intervals precisely for the quantities whose 95% intervals include zero, and omits intervals entirely for others. The treatment is a *level* contrast (above or below the income-group median), yet the title, the framing and the policy section all speak of *increasing* spending. The "negative control" is mechanically constrained to move against the headline outcome because both are shares of the same revenue total. And a subgroup result that cuts against the policy message, the credibly negative Nordic effect in Table 4, is not discussed at all. None of these are fatal to the underlying work. Several are presentational, and the analysis you have already run contains most of the material needed to fix them. But arXiv has no referee to catch them for you, so the burden is entirely on the manuscript, and a paper making a strong fiscal-policy claim with this much selective presentation will be picked apart in public. My advice is to spend two or three weeks tightening the claims to match the evidence and then post with confidence.

---

## 2. Major concerns

### M1. The placebo test does not pass, and the text misreports it

This is the most serious problem. Section 5.5 states that the placebo check "yields near-zero estimates across all channels (+0.07 pp on Direct Income Tax / GDP, 95% CrI [-0.23, +0.35], P = 0.681), ruling out reverse causality". But Table 7 (R5) also reports **+0.58 pp on Direct Income Tax Share with P = 0.85**. That is the headline outcome of the paper, and +0.58 pp is roughly half of the +1.17 pp five-year effect you report as your central finding. The text quotes the one channel where the placebo is small and silently drops the one where it is not.

A pre-treatment effect of half the magnitude of the post-treatment effect, with a posterior probability of 0.85, is not "ruling out reverse causality". It is evidence that countries which fund universities above their income-group median were already on a trajectory toward direct-tax modernisation before the funding wave. That is exactly the confounding story a reader will reach for: state capacity drives both. You need to report R5 honestly in the text, give its full credible interval for every channel, and ideally add a formal pre-trend specification that estimates the placebo and the real effect jointly so you can report the posterior for the *difference*. If the difference is not credibly positive, the headline claim has to change. The within-country demeaning check (R3a) is the right tool here and should be promoted out of the robustness table into the main results, not left as a footnote, especially since it attenuates the Non-Resource Tax effect to +0.05 pp at +5 years.

### M2. The estimand is a level contrast, not an increase

The title asks whether *increasing* government spend improves the future tax take. The primary treatment is Z(i,t) = 1 if a country's per-student spending ratio is above the median of its own World Bank income group in wave t. That is a cross-sectional level comparison, repeated wave by wave. It answers "do countries that fund universities well collect more direct tax later", not "does raising funding raise future tax".

Only one of your four exposure definitions, M3b (observed within-country expansion of at least +2.5 pp), is a change-based treatment, and that is the one that comes closest to the title's question. Everything in Section 6.1 that converts the result into a policy recommendation and a cost-benefit ratio implicitly requires the change interpretation. I would do one of two things: either retitle and reframe the paper around funding *intensity regimes* and move M3b to the front as the policy-relevant specification, or make M3b primary throughout and relegate the median split to a robustness check. The current arrangement promises an interventional claim and delivers a correlational contrast dressed in causal language.

### M3. Selective reporting of intervals and subgroups

This runs through the paper and will be the first thing a critical reader notices.

In the abstract, the results with 95% intervals excluding zero are quoted with 95% intervals. The results whose 95% intervals include zero are quoted either with an 80% interval ("+0.53 percentage points of GDP at +10 years (80% CrI [+0.07, +1.00])", when Table 2 gives 95% CrI [-0.16, +1.23]) or with no interval at all (the +0.28 pp direct income tax figure, whose 95% CrI is [-0.10, +0.68]). The lbcf result of +1.45 pp is quoted with P = 0.971 and no interval; Table 5 gives [-0.05, +3.01]. Mixing interval widths within a single abstract according to whether they exclude zero is the Bayesian equivalent of p-hacking and will read that way. Pick one width, use it everywhere, and let the posterior probabilities carry the nuance.

The same pattern appears in the subgroup analysis. Table 4 row 6 reports a credibly **negative** effect for OECD Nordic high-public systems on Non-Resource Tax / GDP (-0.80 pp, P = 0.03) and this is never mentioned in the text. It is the single most striking result in the table and it cuts directly against the policy message. Either discuss it, including the caveat that five countries is far too few for a credible CATE, or drop the row. Relatedly, the text on page 12 quotes "Lower-Middle Income at +0.99 pp", a number that appears nowhere in Table 4, which has no lower-middle income row. Either that number is from an untabulated run or it is a transcription of the Elite Enrolment row, which is also +0.99. Please check.

### M4. The negative control is not independent of the headline outcome

Outcome 3 (direct income and profit taxes as a share of total revenue) and Outcome 4 (goods and services taxes as a share of total revenue) are shares of the same denominator. They are compositionally constrained: absent large movements in the residual categories, one must fall when the other rises. Your own Table 8 confirms this, with a residual correlation of -0.406 at +5 years and -0.559 at +10 years.

So the fact that Outcome 4 moves slightly down while Outcome 3 moves up is not a specificity check. It is close to an arithmetic consequence. A genuine negative control needs to be a channel with no mechanical link to the treatment effect you claim: trade and customs duties as a share of GDP, property tax as a share of GDP, or a placebo outcome unrelated to tax structure entirely. Better still, model the full revenue composition properly using a compositional (log-ratio or Dirichlet) likelihood, which would also be a genuinely novel methodological extension of mvbcf and would suit the multivariate framework well.

The problem is compounded by Table 6, where the linear local projection benchmark (B4) returns **+0.72 pp on Goods Tax Share with P = 0.798**, the opposite sign to your forest estimate. Your negative control fails under the parametric estimator and this is not mentioned. If the specificity story only holds under one estimator, say so.

### M5. "Direct effect larger than total effect" does not confirm the mechanism

Section 5.1, conclusion 1, says the M2 estimate being slightly larger than M1 is "confirming that university funding directly accelerates the structural transition toward formal income and corporate taxation". This does not follow. If funding raises tax share partly *through* GDP growth, removing that pathway should make the direct effect **smaller** than the total, not larger. Direct exceeding total implies either that the net mediated pathway is negative, or, more likely given the size of the gap relative to the posterior SDs, that the two estimates are statistically indistinguishable and the ordering is noise, or that conditioning on post-treatment variables has induced collider bias.

You cite Acharya, Blackwell and Sen (2016), who warn about exactly this, but you do not implement their sequential g-estimation, which is the standard fix and would be a strong addition. You should also engage with the recent Bayesian tree-based mediation literature, which has moved on considerably since 2016 and is directly relevant to what you are doing:

- Ting, A. and Linero, A. R. (2025), *Estimating Heterogeneous Causal Mediation Effects with Bayesian Decision Tree Ensembles*, JASA. https://doi.org/10.1080/01621459.2025.2491155

At minimum, add a sensitivity analysis for intermediate confounding (an E-value style bound, or a parameterised unmeasured mediator-outcome confounder) and reword this conclusion to say the two estimates are indistinguishable.

### M6. The denominator-unbundling comparison is confounded by sample composition

Table 3 and Figure 3 compare four exposure definitions estimated on four different samples: N = 283 (112 countries), 176 (86), 283 (112) and 403 (123). The headline conclusion of Section 5.2, that per-student intensity matters more than aggregate budget share, is drawn from a comparison between row 1 or 3 and row 4, but row 4 has 42% more observations and 11 more countries, which will systematically include lower-coverage, poorer countries whose outcomes behave differently.

This is straightforwardly fixable: re-estimate all four definitions on the common intersection sample (the set of country-waves where all four treatments are observed) and report that as the primary comparison, with the full-coverage versions as a secondary table. Without that, the conclusion that budget share "yields much smaller fiscal returns" cannot be separated from a change in who is in the sample. The same issue applies to Table 1, which is computed on yet another sample: the group counts sum to 185 countries and 808 country-waves, neither of which matches the 217/1,736 panel or the 121/372 estimation sample, and this is never stated.

### M7. Code and data availability, and reproducibility gaps

I could not confirm that `https://github.com/andrewcparnell/education-tax-bcf` is public and populated. If it is private at the time of posting, the data availability statement is false and the paper should not go up. For a paper that is entirely a data analysis, this is non-negotiable: make the repository public, with a tagged release and a DOI (Zenodo takes five minutes), *before* you post. The statement promises SHA-256 checksums and a `PROVENANCE.md`; make sure those exist and that a cold reader can run one script end to end.

Beyond the repository, several things needed to reproduce the analysis are missing from the paper itself:

- **The propensity score model is never specified.** You include pi-hat(X) in mu(.) and run an out-of-fold variant in R8, but nowhere do you say whether it is a probit, a random forest, a BART classifier or something else. This matters a great deal for the RIC argument.
- **The "19 pre-treatment baseline covariates" are never listed.** Section 4.1 enumerates roughly 14 items and I cannot reconstruct 19. Put the full list in an appendix table with source, units, transformation and missingness rate.
- **No overlap or balance diagnostics.** There is no propensity score distribution by treatment arm, no common-support check, and no covariate balance table. For a binary treatment defined by a median split in a 121-country panel, positivity is a live concern and a reader has no way to assess it. This is a standard requirement and its absence is conspicuous.
- The democracy index is not named (Polity? V-Dem? Which component?), and the GRD variable is not specified precisely (does "non-resource tax revenue" include social contributions?).

### M8. The MCMC is too short to support the precision reported

Table 9 reports effective sample sizes between **58 and 345** from 1,250 retained draws, with R-hat up to 1.019, apparently from a single chain (a split R-hat on one chain is much weaker than the multi-chain diagnostic). An ESS of 58 for the +10-year Goods Tax Share is simply not enough to report anything, let alone P(tau > 0) to three decimal places. With ESS around 250, the Monte Carlo standard error on a posterior probability of 0.98 is roughly 0.009, so the third decimal in "0.982" is noise.

Table 10 tells me the whole pipeline took 816 seconds. There is no computational argument for not running four chains of 20,000 iterations. Do that, report multi-chain R-hat and MCSE, and round posterior probabilities to two decimals. Also, P = 1.000 (Table 3, row 2) should be reported as > 0.999; 0 out of 1,250 draws is not probability one.

Relatedly, Table 9 shows 95% interval coverage of 97.6% to 99.3% against a nominal 95%, with PPC R-squared between 0.19 and 0.56. Systematically over-nominal coverage indicates the predictive intervals are over-dispersed. Your intervals are conservative, which is at least the safe direction, but it should be acknowledged and ideally diagnosed.

### M9. The moderator importance claim contradicts its own numbers

Section 5.4 states that "four moderators account for the vast majority of systematic CATE variation (surrogate R-squared = 45.3%)" and then lists 8.0%, 5.9%, 4.6% and 2.3%. Those sum to 20.8%, which is less than half of 45.3%. Either the percentages are shares of total CATE variance (in which case four moderators explain a fifth, not a vast majority) or they are shares of the 45.3% (in which case they should sum closer to 100%). As written the sentence is internally inconsistent and needs rewriting with the denominator stated explicitly.

I would also note that the five-year wave index appearing as the third most important moderator (4.6%) is awkward: it means the estimated effect varies systematically with calendar time, which undercuts the idea of a stable structural parameter. Worth a sentence.

### M10. The cost-benefit claim overreaches

Section 6.1 asserts that per-student investments "more than pay for themselves within a decade", resting on an unsourced cost figure: "a regime shift or a >= 2.5 pp per-student funding expansion costing roughly 0.15 to 0.35 percentage points of GDP". Where does that range come from? It appears nowhere else in the paper and is not derived from Table 1 in any way I can reconstruct.

Even granting the number, the comparison is not valid as stated. You are comparing an annual (or possibly one-off, it is unclear) cost against a revenue level change measured at a single horizon, with no discounting, no accounting for the fact that the cost is incurred for ten years while the benefit arrives at the end, and no treatment of the uncertainty in either. The MVPF literature you cite (Hendren and Sprung-Keyser, 2020) does this properly, which makes the contrast unflattering. Either do a simple NPV calculation with the posterior propagated through it, so you can report a posterior probability that the ratio exceeds one, or drop the "pays for itself" claim and say instead that the magnitudes are of the same order, which is defensible and still interesting.

### M11. Missing literature, and the priority claim

The reference list is strong on the microeconomics of higher education and on BART methodology, but has a real gap in the recent macro-fiscal literature on exactly this relationship, and the omitted work includes findings that cut against yours.

Most importantly, the **reverse causality** direction is documented and uncited. The World Bank's *Taxing for Growth: Revisiting the 15 Percent Threshold* (2024) finds that tax revenue predicts *subsequent* health and education spending, with a threshold effect around 15% of GDP, and separately examines the direct tax share. That is your causal arrow pointing the other way, in the same data sources, and you need to engage with it. https://documents1.worldbank.org/curated/en/099062724151523023/pdf/P1778861e0c40b081186a61ced16cac6cde.pdf

Also worth adding:

- World Bank and UNESCO, *Education Finance Watch 2024*, which documents stagnating per-student spending and discusses the per-student indicator's construction directly. This is the natural policy citation for your Section 3.3.
- The tax-effort literature, which repeatedly finds public education expenditure **negatively** associated with tax effort in developing economies. For example, the 2025 *Development Southern Africa* study on tax effort and the informal economy. https://doi.org/10.1080/0376835X.2025.2549280. A contradictory finding strengthens your paper if you confront it.
- Ting and Linero (2025), cited above, for the mediation machinery.
- Prevot, E., Haring, D. A., Nichols, T. E., Holmes, C. C. and Ganjgahi, H. (2025), *A hierarchical modelling approach for Bayesian Causal Forests on longitudinal data: a case study in multiple sclerosis clinical trials*, arXiv preprint, which is the closest recent competitor to your lbcf and should be acknowledged.
- The modern staggered-adoption panel literature (Callaway and Sant'Anna 2021, https://doi.org/10.1016/j.jeconom.2020.12.001; de Chaisemartin and D'Haultfoeuille 2020, https://doi.org/10.1257/aer.20181169). You do not have to use these estimators, but a reader from economics will want to know why a BCF is preferred to them for a panel with repeated waves and a binary exposure.

Finally, the claim to be "the first global causal inference analysis" of this relationship is strong and, given the literature above, hard to sustain. Soften to something like "to our knowledge the first to jointly model disaggregated tax channels using multivariate Bayesian causal forests", which is both defensible and still a genuine contribution.

### M12. Period shocks are unaddressed

With eight five-year waves, the +10-year outcome for your 2010-2014 treatment wave is 2020-2024, which is dominated by the pandemic: tax-to-GDP ratios moved sharply, GDP denominators collapsed and rebounded, and revenue composition shifted. The 2005-2009 and 2010-2014 waves similarly straddle the financial crisis. Neither COVID nor the GFC is mentioned anywhere in the paper. Given that the terminal wave carries a large share of the identifying variation for your headline +10-year results, you need a robustness check that drops the 2020-2024 outcome wave entirely, and a sentence acknowledging the issue.

---

## 3. Minor concerns

### Figures

- **Figure 2.** The four panels use free x-axis scales (-0.5 to 1.0, 0.0 to 0.8, 0 to 3, -2 to 1), which makes visual comparison across channels misleading: the apparently large panel 3 effect is on a different measurement scale (share of revenue) from panels 1 and 2 (share of GDP). Either use a common scale within each measurement type or add a clear scale annotation. The panel title is a causal assertion ("Government Tertiary Education Spend Increases Direct Tax Capacity Beyond General Growth") when most of the 95% intervals cross zero; use a neutral descriptive title and leave the claim to the text. The in-panel labels overlap the interval bars in panel 4. And the figure's numbers do not quite match Table 2 (figure shows -0.21 and -0.34; table shows -0.22 and -0.35), which looks like inconsistent rounding of -0.215 and -0.345. Fix the rounding convention globally.
- **Figure 3.** Same issue with the assertive title. The four rows are estimated on different samples (N = 283, 176, 283, 403) and the figure does not say so; add N to each row label.
- **Figure 4.** This is the weakest figure. You are fitting a smooth with a confidence ribbon through unit-level **posterior means** of the CATEs. Those are heavily shrunk by the conservative tau-forest prior, so the ribbon reflects the uncertainty of a smooth through point estimates, not the uncertainty in the CATEs themselves, and is dramatically too narrow. The visual impression that the effect is reliably positive everywhere is partly an artefact of the prior pulling everything toward a common positive mean. Either show posterior uncertainty on the points (even a sample of draws plotted faintly), or replace the figure with binned posterior summaries with proper credible intervals. Separately, the colour palette treats an ordinal variable (income group) with two similar oranges for low and lower-middle; use an ordered sequential palette. And the note explaining that gross enrolment can exceed 100% is unnecessary when the axis stops at 100 and no points appear above it.
- **Figure 5.** Why these seven countries? The selection criterion is not stated and the chosen set is uniformly positive, which invites the suspicion of cherry-picking. State the rule (largest sample coverage? an income-group stratified draw?) or show a random sample. The labels are also quite cluttered at +10 years.
- **Figure 6.** The two colours are the two horizons, not two chains, so these traces cannot speak to convergence across chains. Once you run multiple chains, overlay them and annotate each panel with R-hat and ESS. The panel for Goods Tax Share at +10 years, with ESS of 58, should visibly show the problem.
- **Figure 1.** Fine as a schematic, though the subtitle largely duplicates the caption. Consider trimming.

### Tables

- **Table 1.** The low-income median UNESCO ratio of exactly 150.0% is the winsorisation cap, so the displayed median is censored and uninformative, yet both the table discussion and the introduction build their rhetorical contrast on that number. Report the unwinsorised median (and the quantiles) and winsorise only for the plot. Also, the real PPP column is non-monotonic (low income $3,957 exceeds lower-middle $3,258 and is close to upper-middle $3,521), which is striking and goes undiscussed; it probably reflects small elite systems or coverage artefacts and deserves a sentence, since it slightly complicates your own narrative. Finally, state the sample underlying the table.
- **Table 5.** The "Comp. Prob." column is exactly the P value already shown in the tau-2 column (93.0/85.9/80.6/33.5 against 0.93/0.86/0.81/0.34). Delete it. More substantively, Table 5 gives tau-1 = -0.06 for Direct Income Tax / GDP at +5 years, while Table 2 gives +0.20 with P = 0.94 for the same quantity. The two models disagree in sign on one of your four outcomes and this is not mentioned. It needs explaining.
- **Table 4.** The subgroup Ns do not account for the sample: rows 1 to 3 sum to 244 of 283, rows 4 to 5 sum to 221. Say what happens to the remainder. A five-country, twenty-observation subgroup (row 6) should carry an explicit warning.
- **Table 6.** Comparing a Bayesian posterior SD against a frequentist clustered SE and concluding the forest is "more efficient" is not valid: a narrower posterior under a strongly regularising prior is not evidence of a better estimator without a calibration or coverage comparison. A short simulation showing nominal coverage under a realistic DGP would settle this and would strengthen the paper considerably.
- **Table 7.** R3b (country fixed effects at +10 years) is quoted in the text but not tabulated, while R3a appears only at +5 years. Show both horizons for both. Also note that R2 (N = 154 across 105 countries) is close to a cross-section, which limits what it can tell you.
- **Table 10.** Pleasant to include, but the energy figure covers only the final pipeline, not development and exploration, which is where almost all the compute in a project like this actually goes. Either say so or drop the appendix.

### Other

- The full panel of "1,736 country-wave observations across 217 sovereign territories" is exactly 217 x 8. That is the complete rectangular frame, not a count of observed data. Say so explicitly and give the actual observed counts per variable.
- N = 282 (Table 5, abstract) versus N = 283 (the +10-year sample) is unexplained.
- Is World Bank income group assigned contemporaneously or fixed at a reference year? Since the treatment is defined relative to within-group medians, and countries change groups, this materially affects the treatment definition.
- Effect sizes would benefit from context. Your residual SD on Income Tax Share is 4.20 to 5.23 pp (Table 8) against an effect of 1.17 to 1.66 pp; and the cross-group mean share runs 29% to 38% (Table 1), so +1.66 pp is roughly a 4 to 5% relative shift. Saying this makes the result more interpretable, not less impressive.
- There is no descriptive statistics table for the outcomes themselves (means, SDs, between versus within variation). Add one.
- Precision is inconsistent: P = 0.577 in the text against P = 0.58 in Table 2, 0.982 in the abstract against 0.98 in Table 2 and 0.983 in Table 6. Standardise.
- **arXiv-specific:** your abstract is roughly 2,900 characters and arXiv's hard limit is 1,920 including spaces, so it will be rejected at submission. You will need to cut it by about a third, which is a useful discipline given M3. I would also suggest cross-listing econ.EM and stat.AP, adding an ORCID, and using the Comment field for pages and figure counts.
- Given current norms and the fact that several of the inconsistencies above (numbers in text drifting from tables, the moderator arithmetic, the "vast majority" phrasing) are of a kind that LLM-assisted drafting tends to produce, I would add a one-line statement about any AI assistance used in drafting or analysis. It costs nothing and pre-empts the question.
- `mvbcf` and `lbcf` are set in typewriter font throughout as though they were released packages. If they are not on CRAN or GitHub as installable packages, use MVBCF and LBCF. If they are, cite them.

---

## 4. Typographical and language issues

The manuscript is consistently British English (modernisation, harmonised, winsorised, labour, Visualisation) with no American spellings intruding, and proper nouns like *Standardized World Income Inequality Database* are correctly left alone. First person plural is used throughout, which is fine, though it sits slightly oddly beside the single-author CRediT statement. The following are worth fixing. <!-- style-check: ignore -->

1. **"Government Spend"** in the title, in Figure 1's title and in Figure 2's title. "Spend" as a noun is business jargon; use "Government Spending" or "Public Spending" throughout.
2. Abstract: "372 complete four-outcome fiscal waves" should be "country-waves".
3. Introduction, hurdle 2: "can appear to spend 150% of GDP per person per student" reads awkwardly. Suggest "can appear to spend 150% of GDP per person on each student".
4. Range punctuation is inconsistent: "1985-1989" and "2020-2024" use hyphens, "20-50%" uses an en dash, and Figure 1's subtitle uses a spaced en dash "(1985 - 2024)". Standardise on unspaced en dashes for all numeric ranges.
5. "+5 to + 10-year" has a stray space after the plus sign. This appears in the Table 5 caption and again in Appendix A.
6. CRediT statement: "Writing - original draft, Writing - review and editing" should use en dashes, per the CRediT taxonomy's own formatting.
7. "MIT Licence" should be "MIT License", as that is the proper name of the licence. <!-- style-check: ignore -->
8. "pp" and "percentage points" alternate without a pattern. Define "pp" at first use and then use it consistently, or spell it out consistently.
9. Reference list: Jennifer Hill appears as both "J. Hill" (Hill, Linero and Murray 2020) and "J. L. Hill" (Hill 2011). Make the initials consistent.
10. McJames et al. (2024a) is given as volume 188(2), pages 510-531, with year 2024. Volume 188 of JRSS-A is the 2025 volume; the article was advance access in 2024. Decide whether you are citing the advance-access or the version of record and make the year, volume and pages consistent.
11. Several apparent run-together words in the text I read ("withincountry", "fouroutcome", "nonGaussian", "Pomeranz and VilaBelda") are almost certainly PDF line-break artefacts rather than real typos, but do check them in the source.

---

## Summary of what I would do before posting

The three things that would most change my assessment are: report R5 honestly and add a joint pre-trend test (M1); use a single interval width throughout and discuss the Nordic result (M3); and make the repository public with a Zenodo DOI, the covariate list, the propensity specification and an overlap diagnostic (M7). Those three alone would take the paper from "will be picked apart" to "solid and interesting". The reframing around the estimand (M2) and a proper negative control (M4) are the deeper fixes and would make it genuinely strong.

A few questions I would find useful:

1. On the placebo result, do you have the full posterior for R5 across all four channels? If the pre-trend on Income Tax Share really is +0.58, is there a story you believe about why (budget cycles following revenue booms, for instance), or does it look like straightforward confounding by state capacity?
2. Would you be willing to make M3b, the observed within-country expansion, the primary specification? It matches the title's question better, and it is where your strongest results already sit.
3. Is there a reason you ran only a single chain? If it was just pipeline convenience, four chains would remove an entire category of criticism for about twenty minutes of compute.
4. Do you have the data to construct a genuinely independent negative control, such as trade and customs duties as a share of GDP?
