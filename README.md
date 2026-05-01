# Short Creek Simulations

This repository contains the R code needed to reproduce the analyses in paper *"Hidden Burden of a Measles Outbreak Revealed by Genomic and Transmission Models"*. Dependencies include the [`measles`](https://github.com/UofUEpiBio/measles) R package (version 0.3.1-0), [Quarto](https://quarto.org) for rendering reports, `ggplot2` for visualization, and `data.table` for data wrangling.

## Scenarios

The following scenarios were run across a range of basic reproduction numbers (R0):

| R0 | Results |
|----|---------|
| 8  | [link](./short-creek-8.-FALSEmd) |
| 10 | [link](./short-creek-10-FALSE.md) |
| 12 | [link](./short-creek-12-FALSE.md) |
| 14 | [link](./short-creek-14-FALSE.md) |
| 15 | [link](./short-creek-15-FALSE.md) |
| 16 | [link](./short-creek-16-FALSE.md) |
| 18 | [link](./short-creek-18-FALSE.md) |

### Sensitivity analysis

As a sensitivity analysis, each scenario was also run using an adapted version of the Epistorm US contact matrix (see [`data/README.md`](./data/README.md) for details):

| R0 | Results |
|----|---------|
| 8  | [link](./short-creek-8-TRUE.md) |
| 10 | [link](./short-creek-10-TRUE.md) |
| 12 | [link](./short-creek-12-TRUE.md) |
| 14 | [link](./short-creek-14-TRUE.md) |
| 15 | [link](./short-creek-15-TRUE.md) |
| 16 | [link](./short-creek-16-TRUE.md) |
| 18 | [link](./short-creek-18-TRUE.md) |

## Running additional scenarios

To run a scenario with a custom R0 value, execute:

```bash
R0=<value> EPISTORM=FALSE make report
```

The `EPISTORM=FALSE` will use POLYMOD's contact data (default), setting it to `TRUE` will use Epistorm instead. This will generate a `short-creek-<value>.md` report in the repository root.

