# Sensitivity analysis: adult vaccination (R0 = 9)


The three focal scenarios of Figure 4 at R0 = 9
(`make population_immunity`), for each assumption on the vaccination
coverage of adults aged 18 to 69: the current one (`baseline`) and the
alternate adult immunization assumptions of the [`multigroup.vaccine`
vignette](https://epiforesite.github.io/multigroup-vaccine/articles/experiments/utaz_age_school.html),
with 78%, 86%, and 93% coverage. In parentheses is the resulting
immunity of the whole population (50.3%, 55.6%, 59.8%, 63.5%): the share
vaccinated times the vaccine efficacy (93% under age 5, 97% otherwise),
with everyone aged 70 or older immune. Each scenario has 1,000 runs;
runs with fewer than 10 cases are excluded as early extinctions. As in
Figure 4, self-isolation with quarantine uses the run with quarantine
and the other two scenarios the run without. Children are those under
18.

<div id="tbl-population-immunity">

Table 1: Final outbreak size at day 365, median (interquartile range)
across the retained runs; the ratio is of the medians.

<div class="cell-output-display">

| Adult vaccination (population immunity) | Scenario | Retained runs | Total infections | Children | Adults | Child:adult ratio |
|:---|:---|---:|---:|---:|---:|---:|
| Baseline (50.3%) | No interventions | 777 | 2,700 (2,686-2,715) | 1,739 (1,731-1,747) | 961 (951-972) | 1.8 |
| Baseline (50.3%) | Self-isolation only | 703 | 2,567 (2,547-2,585) | 1,680 (1,670-1,691) | 887 (872-899) | 1.9 |
| Baseline (50.3%) | Self-isolation with quarantine | 594 | 2,138 (2,106-2,167) | 1,447 (1,426-1,466) | 690 (673-707) | 2.1 |
| 78% (55.6%) | No interventions | 726 | 2,295 (2,280-2,311) | 1,720 (1,713-1,730) | 575 (564-586) | 3.0 |
| 78% (55.6%) | Self-isolation only | 646 | 2,157 (2,138-2,177) | 1,656 (1,644-1,668) | 500 (487-513) | 3.3 |
| 78% (55.6%) | Self-isolation with quarantine | 532 | 1,781 (1,750-1,806) | 1,415 (1,395-1,434) | 366 (353-379) | 3.9 |
| 86% (59.8%) | No interventions | 691 | 2,072 (2,059-2,087) | 1,710 (1,700-1,720) | 363 (352-373) | 4.7 |
| 86% (59.8%) | Self-isolation only | 617 | 1,955 (1,937-1,972) | 1,642 (1,630-1,654) | 312 (302-323) | 5.3 |
| 86% (59.8%) | Self-isolation with quarantine | 499 | 1,626 (1,597-1,652) | 1,397 (1,374-1,414) | 230 (219-242) | 6.1 |
| 93% (63.5%) | No interventions | 669 | 1,898 (1,885-1,913) | 1,699 (1,689-1,709) | 200 (192-208) | 8.5 |
| 93% (63.5%) | Self-isolation only | 603 | 1,800 (1,783-1,816) | 1,629 (1,616-1,642) | 171 (163-178) | 9.5 |
| 93% (63.5%) | Self-isolation with quarantine | 481 | 1,508 (1,483-1,534) | 1,383 (1,363-1,401) | 126 (119-135) | 11.0 |

</div>

</div>

<div id="fig-population-immunity">

![](README_files/figure-commonmark/fig-population-immunity-1.png)

Figure 1: Figure SI 11. Projected final outbreak size at R0 = 9 under
alternative adult vaccination-coverage assumptions. Simulations used the
baseline coverage and 78%, 86%, and 93% coverage among adults aged 18-69
years, which give a population immunity of 50.3%, 55.6%, 59.8%, and
63.5%, respectively (the share vaccinated times the vaccine efficacy of
93% under age 5 and 97% otherwise, with everyone aged 70 or older
immune), under no interventions, self-isolation only, and self-isolation
with quarantine. Panels show total infections, infections among children
younger than 18 years, and infections among adults aged 18 years or
older. Points denote the median at day 365 across simulations with at
least 10 cases; vertical bars denote the 95% interval (2.5th to 97.5th
percentiles) across those simulations.

</div>
