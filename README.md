# Utah-Arizona Border Simulations

This repository contains the R code needed to reproduce the analyses in paper *"Hidden Burden of a Measles Outbreak Revealed by Genomic and Transmission Models"*. Dependencies include the [`measles`](https://github.com/UofUEpiBio/measles) R package (version 0.3.1-0), [Quarto](https://quarto.org) for rendering reports, `ggplot2` for visualization, and `data.table` for data wrangling.


## Running additional scenarios

To run a scenario with a custom R0 value, execute:

```bash
R0=<value> EPISTORM=FALSE make report
```

The `EPISTORM=FALSE` will use POLYMOD's contact data (default), setting it to `TRUE` will use Epistorm instead. This will generate a `utah-arizona-<value>.md` report in the repository root. Other available variables include:

- `RASH_CONTACT_REDUX`: Contact rate reduction for rash cases.
- `ISO_WILL`: Isolation willingness.
- `Q_WILL`: Quarantine willingness.
- `QT_SUCCESS`: Success rate of contact tracing.
