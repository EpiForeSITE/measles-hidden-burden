# Utah-Arizona Border Simulations

This repository contains the R code needed to reproduce the analyses in paper *"Hidden Burden of a Measles Outbreak Revealed by Genomic and Transmission Models"*. Dependencies include the [`measles`](https://github.com/UofUEpiBio/measles) R package (version 0.4.1 or later, built on [`epiworldR`](https://github.com/UofUEpiBio/epiworldR) 0.19.0-1 or later, both installed from [r-universe](https://uofuepibio.r-universe.dev) in the dev container, see [`.devcontainer/Containerfile`](./.devcontainer/Containerfile)), [`multigroup.vaccine`](https://github.com/EpiForeSITE/multigroup-vaccine) for the Epistorm-Mix contact matrix, [Quarto](https://quarto.org) for rendering reports, `ggplot2` for visualization, and `data.table` for data wrangling.

## Running the scenarios

The main scenarios (POLYMOD contacts) and the sensitivity analyses are run with:

```bash
make scenarios               # R0 = 5, 7, ..., 17; results in scenarios/
make sensitivity_epistorm    # same, with the Epistorm-Mix contact matrix
make sensitivity_rash_redux  # R0 = 9, grid of rash contact reduction x contact-tracing success
```

To run a single scenario, execute:

```bash
R0=<value> EPISTORM=FALSE make report
```

The `EPISTORM=FALSE` will use POLYMOD's contact data (default), setting it to `TRUE` will use Epistorm instead. The report is written to `$(TARGET_DIR)` (default `scenarios/`), named after its parameters. Other available variables include:

- `RASH_CONTACT_REDUX`: Contact rate reduction for rash cases.
- `ISO_WILL`: Isolation willingness.
- `Q_WILL`: Quarantine willingness.
- `QT_SUCCESS`: Success rate of contact tracing.

## Parameters & references

This section lists every parameter used in the analyses, including those left at the package defaults. It follows the canonical, cited table in the `measles` R package: [`measles_parameters.csv`](https://github.com/UofUEpiBio/measles/blob/main/inst/extdata/measles_parameters.csv) (see also the [parameters vignette](https://github.com/UofUEpiBio/measles/blob/main/vignettes/parameters.qmd)). See [EpiForeSITE/measles#5](https://github.com/EpiForeSITE/measles/issues/5) for background.

The analyses are set up to be run with `measles` 0.4.1 or later; `template.qmd` stops if an older version is installed, and each report ends with the session information. The defaults of every parameter used here match the canonical table. Values that differ from the package defaults are marked **Differs**.

Status: ✅ verified against the cited source; 🗣️ team assumption or rationale, confirmed by the authors; ⚠️ pending.

### Scenarios ([`Makefile`](./Makefile))

| Set | Contact matrix | R0 | Rash contact reduction / contact-tracing success | Isolation willingness | Quarantine willingness |
|---|---|---|---|---|---|
| `make scenarios` (main) | POLYMOD | 5, 7, 9, 11, 13, 15, 17 | 0.00 / 0.00; 0.50 / 0.00; 0.75 / 0.25 | 0.0 | 0.9 |
| `make sensitivity_epistorm` | Epistorm-Mix | 5, 7, 9, 11, 13, 15, 17 | 0.00 / 0.00; 0.50 / 0.00; 0.75 / 0.25 | 0.0 | 0.9 |
| `make sensitivity_rash_redux` | POLYMOD | 9 | 0, 0.25, 0.5, 0.75, 1 × 0, 0.25, 0.5, 0.75, 1 | 0.0 | 0.9 |

Each report runs two scenarios: with quarantine (21 days) and without quarantine (`Quarantine period` set to −1).

### Transmission model (`ModelMeaslesMixing()`, [`template.qmd`](./template.qmd))

| Parameter | Value used | Package default | Source | Status | Notes / why different |
|---|---|---|---|---|---|
| R0 (calibration target) | 5–17 (odd values); 9 in the rash-reduction sensitivity analysis | 15 | Guerra et al. 2017, *Lancet Infect Dis*, [doi:10.1016/S1473-3099(17)30307-9](https://doi.org/10.1016/S1473-3099(17)30307-9) | ✅ 🗣️ | **Differs** (except R0 = 15). A sensitivity range that extends below the 12–18 range in Guerra et al. Not a model argument: it is the `target_rep_number` of `calibrate_mixing_model()`. |
| Transmission rate (`transmission_rate`) | 0.2 | 0.9 | Assumption | 🗣️ | **Differs.** Fixed; the contact matrix is scaled instead (`contact_matrix * scaling_factor`). |
| Infectious period used in calibration | 4 + 1/(h + 1/4) ≈ 7.6 days | — (no default) | Prodromal period plus the expected time in rash | 🗣️ ⚠️ | Agents with rash can make contacts in these scenarios, so the expected time in rash (exits by recovery at rate 1/4 or hospitalization at rate h) is added. ⚠️ It does not account for `rash_reduction_contact_rate`: with a reduction r, the effective infectious period is 4 + (1 − r)/(h + 1/4) (see `?calibrate_mixing_model`), so for r = 0.5 and 0.75 the realized R0 is below the target. Pending author decision. |
| Calibration method | Next-generation matrix | Calibrated to the target R0 | Diekmann et al. 2010, *J R Soc Interface* 7(47):873–885, [doi:10.1098/rsif.2009.0386](https://doi.org/10.1098/rsif.2009.0386) | 🗣️ | Via `measles::calibrate_mixing_model()`, the same method as the canonical table. R0 is computed for a fully susceptible population. |
| Contact matrix (`contact_matrix`), main analysis | `measles::short_creek_matrix` × scaling factor (15 groups: 2 pre-school age groups, 9 schools, 4 adult age groups) | — (no default) | POLYMOD (Mossong et al. 2008, *PLoS Med* 5(3):e74, [doi:10.1371/journal.pmed.0050074](https://doi.org/10.1371/journal.pmed.0050074)), via `multigroup.vaccine::contactMatrixAgeSchool(schportion = 0.7)` | 🗣️ | Built in `data-raw/short_creek.R` of the `measles` package. 70% of school-age children's contacts *with their own age band* are with their own school (assumption). |
| Contact matrix, Epistorm sensitivity analysis (`EPISTORM=TRUE`) | Epistorm-Mix US total contacts mapped to the 15 groups × scaling factor | — (no default) | Litvinova et al. 2025, *medRxiv*, [doi:10.1101/2025.11.20.25340662](https://doi.org/10.1101/2025.11.20.25340662). Data: [epistorm/Epistorm-Mix](https://github.com/epistorm/Epistorm-Mix) at commit `05966ba` | 🗣️ | Built by [`data/epistorm_matrix.R`](./data/epistorm_matrix.R) with the same method as the POLYMOD matrix (`schportion = 0.7`), after making the age matrix reciprocal; see [`data/README.md`](./data/README.md). |
| Population size (`n`) | 5,915 (sum of `short_creek$agepops`) | — (no default) | U.S. Census Bureau ACS table S0101 (2024 files for Hildale city UT, Colorado City town AZ, Centennial Park CDP AZ), via `multigroup.vaccine` | 🗣️ | Scenario input. Not re-checked against the Census tables. |
| Population groups (entities) | 15 groups from `measles::short_creek`; school enrollments 250, 350, 190, 86, 150, 84, 114, 108, 205, rescaled to the census age counts (296, 414, 225, 94, 164, 92, 166, 158, 299) | — | Public school records, via `multigroup.vaccine` | 🗣️ | Scenario input. Added with `add_entities_from_dataframe()`. |
| Vaccination (`prop_vaccinated`) | 0 in the constructor, then the per-group `short_creek$vacc_rate` via `distribute_tool_to_entities()`; overall 51.9% vaccinated | — (no default) | School MMR records (school-age groups); assumptions for the other groups | 🗣️ | Under 1: 0; ages 1–4 and 18–24: the elementary and high-school coverage; 25–44: mean of the 18–24 coverage and 95%; 45–69: 95%; 70+: 100%. Since measles 0.4.1, `vacc_rate` is the vaccination coverage (it used to be coverage × efficacy). |
| Initial cases (`prevalence`) | `1 / N` (one index case) | — (no default) | Scenario input | 🗣️ | |
| Vaccine efficacy (`vax_efficacy`) | 0.97; 0.93 for ages 1–4; 1 for ages 70+ | 0.97 | [Utah DHHS Measles Disease Plan](https://epi.utah.gov/wp-content/uploads/Measles-disease-plan.pdf) ("~97%"); CDC; group values from `multigroup.vaccine` | ✅ 🗣️ | The default (0.97) for most groups. Ages 1–4 and 70+ get copies of the model's all-or-nothing MMR vaccine (`clone_epi()`) with efficacy 0.93 and 1 (presumed immunity), as in the `multigroup.vaccine` analysis. |
| Vaccine reduction in recovery (`vax_reduction_recovery_rate`) | 0.5 (default) | 0.5 | Not active | ✅ | Ignored by the model ("(IGNORED) Vax improved recovery"). |
| Incubation period (`incubation_period`) | 12 days (default) | 12 | Utah DHHS plan: exposure to prodrome averages 8–12 days | ✅ | |
| Prodromal period (`prodromal_period`) | 4 days | 4 | Utah DHHS plan: prodrome lasts 2–4 days (range 2–8); contagious 4 days before rash onset | ✅ | Passed explicitly; same as the default. |
| Rash period (`rash_period`) | 4 days | 3 | Utah DHHS plan: contagious to 4 days after rash onset | ✅ | **Differs.** At the upper end of the contagious period after rash onset. |
| Rash contact reduction (`rash_reduction_contact_rate`) | 0, 0.5 or 0.75 (scenarios); 0–1 (sensitivity analysis) | 1.0 | Assumption | 🗣️ | **Differs.** Agents with rash keep 100%, 50% or 25% of their contacts (1 = they stay home, the package default). |
| Hospitalization rate (`hospitalization_rate`) | 0.0278 per day (a 10% probability) | 0.2 per day (≈44% with a 4-day rash) | Jones et al. 2026, *NEJM Evid* 5(8), [doi:10.1056/EVIDpha2600141](https://doi.org/10.1056/EVIDpha2600141): 8% overall, 9% among unvaccinated in Utah | ✅ 🗣️ | **Differs.** The model takes a daily **rate**. A 10% probability is converted with h = p·(1/rash) / (1 − p) = 0.1 × (1/4) / 0.9 ≈ 0.0278, the inverse of p = h / (h + 1/rash). |
| Hospitalization period (`hospitalization_period`) | 7 days | 7 | Assumption | 🗣️ | Passed explicitly; same as the default. Observed stays are shorter: a mean of 2.1 nights in Utah (Jones et al. 2026). |
| Days undetected (`days_undetected`) | 2 days | 2 | Assumption: about 2 days from active case to public health notification | 🗣️ | Passed explicitly; same as the default. |
| Quarantine period (`quarantine_period`) | 21 days; −1 (no quarantine) in the comparison scenario | 21 | Utah DHHS plan: 21 days since last exposure | ✅ | The no-quarantine scenario sets `set_param(measles_model, "Quarantine period", -1)`. |
| Quarantine willingness (`quarantine_willingness`) | 0.9 | 1.0 | Assumption (field experience) | 🗣️ | **Differs.** Assumes 10% of contacts do not comply with quarantine. |
| Isolation willingness (`isolation_willingness`) | 0.0 (`ISO_WILL` in the Makefile; the template default is 1.0) | 1.0 | Assumption | 🗣️ ⚠️ | **Differs.** Detected cases do not isolate; the behavior of cases with rash is represented by `rash_reduction_contact_rate` instead. Pending author confirmation. |
| Isolation period (`isolation_period`) | 4 days | 4 | Utah DHHS plan: isolate until 4 days after rash onset | ✅ | Passed explicitly; same as the default. |
| Contact-tracing success (`contact_tracing_success_rate`) | 0, 0 or 0.25, paired with rash contact reduction 0, 0.5 and 0.75; 0–1 in the sensitivity analysis | 1.0 | Assumption | 🗣️ | **Differs.** |
| Contact-tracing window (`contact_tracing_days_window`) | 4 days | 4 | Assumption; matches the Utah DHHS exposure definition (4 days before through 4 days after rash onset) | 🗣️ ✅ | Passed explicitly; same as the default. |
| Simulation settings | 365 days; 1,000 runs per scenario (with and without quarantine); seed 8812; 8 threads | — | — | 🗣️ | `run_multiple()` calls in `template.qmd`. |

The Utah DHHS Measles Disease Plan cited above is the edition last updated March 26, 2026.

**Notes on the transmission model**

- **Vaccination and vaccine efficacy.** `short_creek$vacc_rate` is the share of each group that is vaccinated, and the model applies the vaccine efficacy. The MMR vaccine is all-or-nothing: each vaccinated agent is fully protected with probability equal to the efficacy. The efficacy is 0.97, except for ages 1–4 (0.93) and 70+ (1, presumed immunity), as in `multigroup.vaccine`; these groups get copies of the model's vaccine made with `clone_epi()` (epiworldR >= 0.19.0-1). Up to measles 0.4.0, `vacc_rate` was coverage × efficacy, so with `vax_efficacy = 0.97` the efficacy was counted twice (for example, 89.3% instead of 92.1% protected among ages 45–69); measles 0.4.1 fixes this in the data. Overall, 51.9% are vaccinated and 50.3% are immune.
- **Hospitalization rate.** The rate is computed from the rash period used in the model (4 days). Earlier versions of the template used 1/3 (a 3-day rash), which gives a 12.9% probability of hospitalization with a 4-day rash instead of the intended 10%.

### Genomic burden estimate ([`BedfordMethodCount.R`](./BedfordMethodCount.R), [`plotEBSP.R`](./plotEBSP.R))

[`BedfordMethodCount.R`](https://github.com/EpiForeSITE/measles-hidden-burden/blob/main/BedfordMethodCount.R) is on `main` (added after this branch was created). These values convert the effective population size from the extended Bayesian skyline (EBSP) into case counts. They are not `measles` package parameters, so there is no package default.

| Parameter | Value used | Source | Status | Notes |
|---|---|---|---|---|
| Reproduction number in the conversion | 5–18 (`BedfordMethodCount.R`); 9 (`plotEBSP.R`) | Sensitivity range | 🗣️ | Enters as `1/R` in `sigma <- (1/R) + (1/0.34) + 1`. |
| Constant 0.34 | 0.34 | Not recorded | ⚠️ | Enters as `1/0.34` in `sigma`. Its meaning and source should be stated (it looks like an offspring dispersion parameter *k*). |
| Generation time | 11.9 days | Code comment: "average time from rash onset to secondary case" | ⚠️ | Source not recorded. |
| Most recent sample date | 2026-02-28 | Sequence data | 🗣️ | `MRSD_date` in `BedfordMethodCount.R`. |
| MCMC burn-in | 10% | Convention | 🗣️ | `removeBurnin(..., 0.1)`. |
| Credible interval | 95% (2.5% and 97.5% quantiles) | Convention | 🗣️ | `processEBSPdata()` in `plotEBSP.R`. |

No reporting or ascertainment parameter is set in this repository.
