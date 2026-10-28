# Utah-Arizona Border Simulations

This repository contains the R code needed to reproduce the analyses in paper *"Hidden Burden of a Measles Outbreak Revealed by Genomic and Transmission Models"*. Dependencies include the [`measles`](https://github.com/UofUEpiBio/measles) R package (version 0.4.1 or later, built on [`epiworldR`](https://github.com/UofUEpiBio/epiworldR) 0.19.0 or later, with `clone_epi()`, both installed from [r-universe](https://uofuepibio.r-universe.dev) in the dev container, see [`.devcontainer/Containerfile`](./.devcontainer/Containerfile)), [`multigroup.vaccine`](https://github.com/EpiForeSITE/multigroup-vaccine) (pinned to commit `ddd9201`) and [`socialmixr`](https://cran.r-project.org/package=socialmixr) (pinned to 0.7.0) for the population, contact, and vaccination data, [Quarto](https://quarto.org) for rendering reports, `ggplot2` for visualization, and `data.table` for data wrangling.

## Container

The dev container ([`.devcontainer/Containerfile`](./.devcontainer/Containerfile)) pins the R packages used in the analyses. It is published to the GitHub Container Registry by [`.github/workflows/container.yml`](./.github/workflows/container.yml) (tags `latest`, the release version, and the commit SHA):

```bash
docker run --rm -it -v "$PWD":/work -w /work ghcr.io/epiforesite/measles-hidden-burden:latest make data
```

## Data

The population, contact matrices, and vaccination data for the Utah-Arizona border community are built in this repository from the data released with `multigroup.vaccine`:

```bash
make data   # runs data/utaz_data.R and data/epistorm_matrix.R
```

[`data/utaz_data.R`](./data/utaz_data.R) follows the [`multigroup.vaccine` vignette](https://github.com/EpiForeSITE/multigroup-vaccine/blob/ddd9201f28b9908c033542f6a2445b84619af1c7/vignettes/experiments/utaz_age_school.Rmd) and writes `data/utaz_population.rds`, `data/utaz_contacts_polymod.rds`, and one `data/utaz_vaccination_adults_<assumption>.rds` file per adult vaccination assumption: `baseline`, `78pct`, `86pct`, and `93pct` (the "Alternate adult immunization assumptions" of the vignette). To add an assumption, call `save_vaccination(<coverage>)` at the end of the script (for example, `save_vaccination(0.9)` writes `utaz_vaccination_adults_90pct.rds`). The `baseline` data matches `measles::short_creek` (measles 0.4.1) except for the school sizes: rounding the rescaled schools can leave an age group a person off its census count, and here the largest school takes the difference (one person fewer in the largest school of ages 5-11 and of ages 12-13). The deterministic final sizes at R0 = 9 change by at most one infection. The POLYMOD matrix differs from `measles::short_creek_matrix` by up to 1.6% per cell (0.6% on average), since the latter was built with an earlier development version of `multigroup.vaccine`; after calibration, the deterministic final size changes by less than 0.1%.

### Tests

[`tests/tinytest/`](./tests/tinytest) checks the data with [`tinytest`](https://cran.r-project.org/package=tinytest):

```bash
make test
```

- **Data:** the census total, school counts that add up to their age group, rates between 0 and 1 with a plausible overall coverage, alternate adult assumptions that change only ages 18-69, and reciprocal contact matrices.
- **Calibration:** for each R0 in the Makefile, the scaled matrix gives back R0 with plausible contacts per day, and the deterministic final sizes at R0 = 9 are within 0.5% of the vignette.
- **Rebuild:** a fresh build with the data scripts matches the committed files.

[`.github/workflows/tests.yml`](./.github/workflows/tests.yml) runs them in the dev container on pull requests and pushes to `main` that change the data, the tests, or the container.

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
- `VAX_ADULTS`: Adult vaccination assumption, `baseline` (default) or the coverage of adults aged 18–69 (e.g., `78pct`); see [Data](#data).

## Parameters & references

This section lists every parameter used in the analyses. It follows the canonical, cited table in the `measles` R package: [`measles_parameters.csv`](https://github.com/UofUEpiBio/measles/blob/main/inst/extdata/measles_parameters.csv) (see also the [parameters vignette](https://github.com/UofUEpiBio/measles/blob/main/vignettes/parameters.qmd)). See [EpiForeSITE/measles#5](https://github.com/EpiForeSITE/measles/issues/5) for background.

The analyses are set up to be run with `measles` 0.4.1 or later; `template.qmd` stops if an older version is installed, and each report ends with the session information.

### Scenarios ([`Makefile`](./Makefile))

| Set | Contact matrix | R0 | Rash contact reduction / contact-tracing success | Isolation willingness | Quarantine willingness |
|---|---|---|---|---|---|
| `make scenarios` (main) | POLYMOD | 5, 7, 9, 11, 13, 15, 17 | 0.00 / 0.00; 0.50 / 0.00; 0.75 / 0.25 | 0.0 | 0.9 |
| `make sensitivity_epistorm` | Epistorm-Mix | 5, 7, 9, 11, 13, 15, 17 | 0.00 / 0.00; 0.50 / 0.00; 0.75 / 0.25 | 0.0 | 0.9 |
| `make sensitivity_rash_redux` | POLYMOD | 9 | 0, 0.25, 0.5, 0.75, 1 × 0, 0.25, 0.5, 0.75, 1 | 0.0 | 0.9 |

Each report runs two scenarios: with quarantine (21 days) and without quarantine (`Quarantine period` set to −1).

### Transmission model (`ModelMeaslesMixing()`, [`template.qmd`](./template.qmd))

| Parameter | Value used | Source |
|---|---|---|
| R0 (calibration target) | 5–17 (odd values); 9 in the rash-reduction sensitivity analysis | Sensitivity range informed by the effective reproduction number in Utah early in the outbreak; measles R0 is usually 12–18 (Guerra et al. 2017, *Lancet Infect Dis*, [doi:10.1016/S1473-3099(17)30307-9](https://doi.org/10.1016/S1473-3099(17)30307-9)). Used as `target_rep_number` in `calibrate_mixing_model()`. |
| Transmission rate (`transmission_rate`) | 0.2 | Assumption. Fixed; the contact matrix is scaled instead (`contact_matrix * scaling_factor`). |
| Infectious period used in calibration | 4 + 1/(h + 1/4) ≈ 7.6 days | Prodromal period plus the expected time in rash (exit by recovery at rate 1/4 or hospitalization at rate h). By construction, the calibration targets R0 without behavior change, so `rash_reduction_contact_rate` is not included. |
| Calibration method | Next-generation matrix | Diekmann et al. 2010, *J R Soc Interface* 7(47):873–885, [doi:10.1098/rsif.2009.0386](https://doi.org/10.1098/rsif.2009.0386), via `measles::calibrate_mixing_model()`. R0 is computed for a fully susceptible population. |
| Contact matrix (`contact_matrix`), main analysis | `data/utaz_contacts_polymod.rds` × scaling factor (15 groups: 2 pre-school age groups, 9 schools, 4 adult age groups) | POLYMOD (Mossong et al. 2008, *PLoS Med* 5(3):e74, [doi:10.1371/journal.pmed.0050074](https://doi.org/10.1371/journal.pmed.0050074)), retrieved with `multigroup.vaccine::contactMatrixAgeSchool(schportion = 0.7)` in [`data/utaz_data.R`](./data/utaz_data.R). The 70% share of school-age children's within-age-band contacts made at their own school is an assumption. |
| Contact matrix, Epistorm sensitivity analysis (`EPISTORM=TRUE`) | Epistorm-Mix US total contacts mapped to the 15 groups × scaling factor | Litvinova et al. 2025, *medRxiv*, [doi:10.1101/2025.11.20.25340662](https://doi.org/10.1101/2025.11.20.25340662). Downloaded from [epistorm/Epistorm-Mix](https://github.com/epistorm/Epistorm-Mix) (commit `05966ba`) and built by [`data/epistorm_matrix.R`](./data/epistorm_matrix.R) with the same method as the POLYMOD matrix (see [`data/README.md`](./data/README.md)). |
| Population size (`n`) | 5,915 (sum of `agepops`) | U.S. Census Bureau ACS table S0101 (2024; Hildale city UT, Colorado City town AZ, Centennial Park CDP AZ), retrieved from the `multigroup.vaccine` package (`getCityData()`). |
| Population groups (entities) | 15 groups from `data/utaz_vaccination_adults_<assumption>.rds`; school enrollments 250, 350, 190, 86, 150, 84, 114, 108, 205, rescaled to the census age counts (296, 414, 225, 94, 164, 92, 166, 158, 299) | Public school records, retrieved from the `multigroup.vaccine` package. Added with `add_entities_from_dataframe()`. |
| Vaccination (`prop_vaccinated`) | 0 in the constructor, then the per-group coverage `vacc_rate` (overall 51.9% at `baseline`; 57.4%, 61.7%, and 65.5% with 78%, 86%, and 93% of adults vaccinated) | School MMR records (school-age groups), retrieved from the `multigroup.vaccine` package; assumptions for the other groups (under 1: 0; ages 1–4 and 18–24: the elementary and high-school coverage; 25–44: mean of the 18–24 coverage and 95%; 45–69: 95%; 70+: 100%). The `VAX_ADULTS` alternatives set all adults aged 18–69 to 78%, 86%, or 93% (based on Washington County UT; Mohave County AZ, Utah, and Arizona; and both counties 10 years ago, per `multigroup.vaccine`). Distributed with `distribute_tool_to_entities()`. |
| Initial cases (`prevalence`) | `1 / N` (one index case) | Scenario input. |
| Vaccine efficacy (`vax_efficacy`) | 0.97; 0.93 for ages 1–4; 1 for ages 70+ | [Utah DHHS Measles Disease Plan](https://epi.utah.gov/wp-content/uploads/Measles-disease-plan.pdf) ("~97%"); CDC. Group values as in the `multigroup.vaccine` analysis; ages 1–4 and 70+ get copies of the model's all-or-nothing MMR vaccine made with `clone_epi()`. |
| Vaccine reduction in recovery (`vax_reduction_recovery_rate`) | 0.5 | Not active: the model ignores it ("(IGNORED) Vax improved recovery"). |
| Incubation period (`incubation_period`) | 12 days | Utah DHHS plan: exposure to prodrome averages 8–12 days. |
| Prodromal period (`prodromal_period`) | 4 days | Utah DHHS plan: prodrome lasts 2–4 days (range 2–8); contagious 4 days before rash onset. |
| Rash period (`rash_period`) | 4 days | Utah DHHS plan: contagious to 4 days after rash onset. |
| Rash contact reduction (`rash_reduction_contact_rate`) | 0, 0.5 or 0.75 (scenarios); 0–1 (sensitivity analysis) | Assumption. Agents with rash keep 100%, 50% or 25% of their contacts. |
| Hospitalization rate (`hospitalization_rate`) | 0.0278 per day (a 10% probability) | Jones et al. 2026, *NEJM Evid* 5(8), [doi:10.1056/EVIDpha2600141](https://doi.org/10.1056/EVIDpha2600141): 8% overall, 9% among unvaccinated in Utah. The model takes a daily rate: h = p·(1/rash) / (1 − p) = 0.1 × (1/4) / 0.9. |
| Hospitalization period (`hospitalization_period`) | 7 days | Assumption. |
| Days undetected (`days_undetected`) | 2 days | Assumption: on average, it takes about two days to detect a case. |
| Quarantine period (`quarantine_period`) | 21 days; −1 (no quarantine) in the comparison scenario | Utah DHHS plan: 21 days since last exposure. The no-quarantine scenario uses `set_param(measles_model, "Quarantine period", -1)`. |
| Quarantine willingness (`quarantine_willingness`) | 0.9 | Assumption. |
| Isolation willingness (`isolation_willingness`) | 0.0 (`ISO_WILL` in the Makefile) | Assumption. The behavior of cases with rash is represented by `rash_reduction_contact_rate`. |
| Isolation period (`isolation_period`) | 4 days | Utah DHHS plan: isolate until 4 days after rash onset. |
| Contact-tracing success (`contact_tracing_success_rate`) | 0, 0 or 0.25, paired with rash contact reduction 0, 0.5 and 0.75; 0–1 in the sensitivity analysis | Assumption. |
| Contact-tracing window (`contact_tracing_days_window`) | 4 days | Assumption; matches the Utah DHHS exposure definition (4 days before through 4 days after rash onset). |
| Simulation settings | 365 days; 1,000 runs per scenario (with and without quarantine); seed 8812; 8 threads | `run_multiple()` calls in `template.qmd`. |

The Utah DHHS Measles Disease Plan cited above is the edition last updated March 26, 2026.

**Notes on the transmission model**

- **Vaccination and vaccine efficacy.** `vacc_rate` is the share of each group that is vaccinated, and the model applies the vaccine efficacy. The MMR vaccine is all-or-nothing: each vaccinated agent is fully protected with probability equal to the efficacy. The efficacy is 0.97, except for ages 1–4 (0.93) and 70+ (1, presumed immunity), as in `multigroup.vaccine`; these groups get copies of the model's vaccine made with `clone_epi()` (epiworldR >= 0.19.0). Up to measles 0.4.0, `vacc_rate` was coverage × efficacy, so with `vax_efficacy = 0.97` the efficacy was counted twice (for example, 89.3% instead of 92.1% protected among ages 45–69); measles 0.4.1 fixed this in the data. At `baseline`, 51.9% are vaccinated and 50.3% are immune.
- **Hospitalization rate.** The rate is computed from the rash period used in the model (4 days). Earlier versions of the template used 1/3 (a 3-day rash), which gives a 12.9% probability of hospitalization with a 4-day rash instead of the intended 10%.

### Genomic burden estimate ([`BedfordMethodCount.R`](./BedfordMethodCount.R), [`plotEBSP.R`](./plotEBSP.R))

[`BedfordMethodCount.R`](https://github.com/EpiForeSITE/measles-hidden-burden/blob/main/BedfordMethodCount.R) is on `main` (added after this branch was created). These values convert the effective population size from the extended Bayesian skyline (EBSP) into case counts. They are not `measles` package parameters, so there is no package default.

| Parameter | Value used | Source |
|---|---|---|
| Reproduction number in the conversion | 5–18 (`BedfordMethodCount.R`); 9 (`plotEBSP.R`) | Sensitivity range. Enters as `1/R` in `sigma <- (1/R) + (1/0.34) + 1`. |
| Offspring dispersion (*k*) | 0.34 | As stated in the preprint; the source is not recorded in the code. Enters as `1/0.34` in `sigma`. |
| Generation time | 11.9 days | Code comment: "average time from rash onset to secondary case"; the source is not recorded in the code. |
| Most recent sample date | 2026-02-28 | Sequence data (`MRSD_date` in `BedfordMethodCount.R`). |
| MCMC burn-in | 10% | Convention (`removeBurnin(..., 0.1)`). |
| Credible interval | 95% (2.5% and 97.5% quantiles) | Convention (`processEBSPdata()` in `plotEBSP.R`). |

No reporting or ascertainment parameter is set in this repository.
