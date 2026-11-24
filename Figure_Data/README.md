# Figures

Scripts and inputs for the figures of the paper.

## Figure 4 (reproducible from this repository)

Run from the repository root with `make figures`:

| Script | Panels | Inputs | Output |
|---|---|---|---|
| [`FigurePhylodynamic.R`](./FigurePhylodynamic.R) | A-B: effective population size and linked outbreak size | `EBSP_epi.log`, `EBSP_genomepi.log`, [`../plotEBSP.R`](../plotEBSP.R) | `Figure4AB.{png,pdf}` and the full `Figure4.{png,pdf}` |
| [`FigureABM.R`](./FigureABM.R) | C-D: weekly cases and final outbreak size from the model | R0 = 9 outputs in [`../scenarios/`](../scenarios) | `Figure4CD.{png,pdf}` |
| [`FigureSI7.R`](./FigureSI7.R) | SI 7: weekly incidence and final outbreak-size distributions across R0 values | Main-scenario outputs in [`../scenarios/`](../scenarios) | `FigureSI7.{png,pdf}` |
| [`FigureSI9.R`](./FigureSI9.R) | SI 9: projected incidence and final outbreak size under POLYMOD and Epistorm-Mix assumptions | R0 = 9 outputs in [`../scenarios/`](../scenarios) and [`../sensitivity_epistorm/`](../sensitivity_epistorm) | `FigureSI9.{png,pdf}` |

`FigureABM.R` also holds the helpers that the summary `README.qmd` files of the model folders use (`abm_summaries()`, `scenario_file()`, the colors and theme). `model-inputs.{png,svg}` is a diagram of the model inputs.

## Other figures (original scripts)

These are the scripts behind the submitted figures, kept as written. They read their inputs by file name, so they run from a folder that holds the inputs and `plotEBSP.R`.

| Script | Figure | Inputs |
|---|---|---|
| [`Figure1.R`](./Figure1.R) | 1: vaccination coverage (map and trends) | `vaccination_rates.csv`; county shapes downloaded with `tigris` |
| [`Figure2.R`](./Figure2.R) | 2: vaccination status, ages, case map, and outbreak context | `vaxxed.csv`, `ages.csv`, `outbreak_context.csv`; county shapes downloaded with `tigris` |
| [`Figure3.R`](./Figure3.R) | 3: epidemic curve and phylogenetic tree | `case_data_SW.RData`, `case_data_notSW.RData`, `SW_or_Not.RData`, `beast_tree.tree` (not included) |
| [`Figure4.R`](./Figure4.R) | 4: the submitted version | EBSP logs, `main_final.RData`, `main_weekly.RData` (an earlier set of model runs) |
| [`FigureSI5.R`](./FigureSI5.R) | SI 5: EBSP case estimates | EBSP logs |
| [`FigureSI6.R`](./FigureSI6.R) | SI 6: EBSP estimates against reported cases | `EBSP_genomepi.log`, `case_data_SW.RData`, `case_data_notSW.RData` (not included) |

The case data and the tree for Figures 3 and SI 6 are not in the repository, since they derive from case- and sample-level records.
