George G. Vega Yon, Ph.D.
2026-05-07

# Scenario of Utah-Arizona Border Measles Outbreak (R0 = 7)

Parameters used for this scenario:

- R0: 7
- Rash contact reduction: 50%
- Isolation willingness: 0%
- Quarantine willingness: 90%
- Contact tracing success rate: 0%

> [!WARNING]
>
> ### Warning
>
> The data and model used in this vignette are for demonstration
> purposes only and do not reflect real-world conditions accurately. As
> in most agent-based models, the simulations performed here are
> simplified representations of the reality and provide rich information
> for scenario modeling, but not necessarily for forecasting or
> parameter estimation.

During the 2025 US measles outbreak, the number of cases in Utah climbed
rapidly in communities along the Utah-Arizona border. This vignette
shows how we can use the mixing model of the `measles` R package to do
scenario modeling of the situation using both age and school data.

## Set up

We start by loading the `measles` R package. Since the package depends
on <a href="https://cran.r-project.org/package=epiworldR"
target="_blank"><code>epiworldR</code></a>, `epiworldR` is loaded
automatically too:

``` r
library(measles)
```

    Loading required package: epiworldR

    Thank you for using epiworldR! Please consider citing it in your work.
    You can find the citation information by running
      citation("epiworldR")


    Attaching package: 'measles'

    The following objects are masked from 'package:epiworldR':

        get_contact_matrix, set_contact_matrix

For the data, we need two datasets: information about the population
distribution by age and vaccination status, and the contact matrix. The
`measles` R package comes with a pre-processed dataset that was created
using the [`multigroup.vaccine` R
package](https://github.com/EpiForeSITE/multigroup-vaccine). This data
uses real vaccination rates from publicly available school records, and
population age structure and composition from the latest US census.
Vaccination rates for the non-school-aged population were imputed based
on assumptions and do not reflect the actual vaccination information for
those age groups. We can load the needed data using the `data()`
function:

``` r
data(short_creek, package = "measles")
data(short_creek_matrix, package = "measles")
```

If we are using the Epistorm data, we need to adjust it

``` r
if (params$epistorm) {
  short_creek_matrix <- readRDS("data/short_creek_epistorm.rds")
}
```

Let’s take a look at the datasets:

``` r
short_creek
```

       age_labels agepops agelims  vacc_rate
    1      under1     141       1 0.00000000
    2        1to4     562       4 0.26512456
    3     5to11s1     296      11 0.06081081
    4     5to11s2     414      11 0.35748792
    5     5to11s3     225      11 0.40888889
    6    12to13s4      94      13 0.22340426
    7    12to13s5     164      13 0.35365854
    8    12to13s6      92      13 0.57608696
    9    14to17s7     166      17 0.22891566
    10   14to17s8     158      17 0.36075949
    11   14to17s9     299      17 0.44147157
    12     18to24     817      24 0.36474908
    13     25to44    1391      44 0.64270309
    14     45to69    1016      69 0.92125984
    15        70+      80      90 1.00000000

As we can see, the vaccination rates in this area are significantly low.
The vaccination rate needed to avert an outbreak is close to the 0.93
percent of the population. The overall vaccination rate is 50.2789518%,
meaning that 2941 people are unvaccinated. Let’s now look at the first
few entries of the contact matrix

``` r
# Looking at the first 5 columns
short_creek_matrix[, 1:5] |>
  round(2)
```

             under1 1to4 5to11s1 5to11s2 5to11s3
    under1     0.80 1.35    0.32    0.45    0.24
    1to4       0.34 5.60    0.86    1.20    0.65
    5to11s1    0.15 1.63   12.46    2.08    1.13
    5to11s2    0.15 1.63    1.49   13.05    1.13
    5to11s3    0.15 1.63    1.49    2.08   12.10
    12to13s4   0.08 0.61    1.62    2.26    1.23
    12to13s5   0.08 0.61    1.62    2.26    1.23
    12to13s6   0.08 0.61    1.62    2.26    1.23
    14to17s7   0.10 0.46    0.45    0.63    0.34
    14to17s8   0.10 0.46    0.45    0.63    0.34
    14to17s9   0.10 0.46    0.45    0.63    0.34
    18to24     0.09 0.53    0.26    0.37    0.20
    25to44     0.20 1.23    0.66    0.93    0.50
    45to69     0.09 0.59    0.31    0.43    0.24
    70+        0.03 0.26    0.15    0.20    0.11

``` r
# Looking at it as a heatmap
image(short_creek_matrix)
```

![](r0_7-epistorm_FALSE-rash_contact_redux_0.50-isolation_willingness_0.0-quarantine_willingness_0.9-contact_tracing_success_0.00_files/figure-commonmark/data-peak-matrix-1.png)

One important thing to note is that the data in `short_creek` must
coincide with that in the contact matrix, particularly, there should be
one entry in the `data.frame` for each row/column of the contact matrix.

## Creating the model

The measles models have many parameters. One that is of particular
importance is the hospitalization rate. The hospitalization rate is not
a probability, so, to match a 10% hospitalization probability, we need
to do some calculations. The hospitalization probability is given by the
following formula:

$$P(\text{hospitalization}) = \frac{\text{hospitalization}_\text{rate}}{\text{hospitalization}_\text{rate} + \text{recovery}_\text{rate}}$$

Where the $\text{recovery}_\text{rate}$ is given by the rash period
(1/duration of it, three days in this simulation). Programatically, we
can do the following:

``` r
N <- sum(short_creek$agepops)

# Finding hospitalization rate for
# a 10% hospitalization probability
# P(hosp) = hosp_r / (hosp_r + rec_r)
#   => hosp_r = P(hosp) (hosp_r + rec_r)
#             = P(hosp) * hosp_r + P(hosp) * rec_r
#   => hosp_r = P(hosp) * rec_r / (1 - P(hosp))
h_rate <- 0.1 * (1 / 3) / (1 - 0.1)
```

For calibration, we can make use of the function
`calibrate_mixing_model()`, which will give us the needed scaleing
factor to apply to the transmission probability (or contact matrix) to
get the desired R0. In this case, we will use an R0 of 7, which is
consistent with the literature on measles.

> [!IMPORTANT]
>
> While the decision to calibrate the contact matrix or the transmission
> probability is most likely irrelevant for the effective reproductive
> number, downscaling the contact matrix may result in fewer cases
> quarantined, which will affect the outbreak size.

``` r
r0 <- params$r0

# Figuring out the duration
total_duration <- 4 + 1/(h_rate + 1/3)

scaling_factor <- calibrate_mixing_model(
  contact_matrix = short_creek_matrix,
  target_rep_number = r0,
  infectious_period_days = total_duration,
  transmission_prob = 0.2
)
```

``` r
measles_model <- ModelMeaslesMixing(
  n                            = N,
  prevalence                   = 1 / N,
  transmission_rate            = 0.2,
  vax_efficacy                 = 0.97,
  contact_matrix               = short_creek_matrix * scaling_factor,
  prop_vaccinated              = 0.0, # This is modified later
  # Quarantine and isolation parameters
  days_undetected              = 2,
  quarantine_period            = 21,
  quarantine_willingness       = params$quarantine_willingness,
  isolation_willingness        = params$isolation_willingness,
  isolation_period             = 4,
  contact_tracing_success_rate = params$contact_tracing_success,
  contact_tracing_days_window  = 4,
  # Disease paramters
  rash_period                  = 3,
  prodromal_period             = 4,
  hospitalization_rate         = h_rate,
  hospitalization_period       = 7,
  rash_reduction_contact_rate  = params$rash_contact_redux
)
```

Now, since this is a mixing model, we are required to specify the
entities. To do so, we can either use the functions `entity()` and
`add_entity()`, or use the wrapper `add_entities_from_dataframe()` as
follows:

``` r
# Adding the entities to the model
add_entities_from_dataframe(
  model = measles_model,
  entities = short_creek,
  col_name = "age_labels",
  col_number = "agepops",
  as_proportion = FALSE
)
```

We can also specify the vaccination rates. There are multiple ways in
which we can do that. The default behavior of the model is, at each run,
randomly sample `prop_vaccinated` percent of the population and assign
the vaccine. Thus, the number of vaccinated individuals will be constant
across simulations. Nonetheless, since the schools and age groups have
different vaccination rates, it is better to use the
`distribute_tool_to_entities()` function. Like the
`add_entities_from_dataframe()` function, the
`distribute_tool_to_entities()` function simplifies the process:

``` r
# Creating the distribution function
dist_fun <- distribute_tool_to_entities(
  prevalence = short_creek$vacc_rate,
  as_proportion = TRUE
)

# Setting the distribution function
measles_model |>
  get_tool(0) |>
  set_distribution_tool(dist_fun)
```

Now, we can specify what to record from the simulation.

``` r
measles_model |>
  run_multiple(
    ndays = 365,
    nsims = params$nsims,
    seed  = 8812,
    saver = make_saver("outbreak_size", "hospitalizations", "reproductive"),
    nthreads = params$threads
  )
```

    Starting multiple runs (1000) using 8 thread(s)
    _________________________________________________________________________
    _________________________________________________________________________
    ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| done.

After calling the function `run_multiple()`, the C++ function will write
the information to disk. Before we read in the data, we can take a look
at the summary of the model, which will give us an overview of the last
run, including how much time it spend per simulation, and what is the
transsition matrix for the current run.

``` r
summary(measles_model)
```

    ________________________________________________________________________________
    ________________________________________________________________________________
    SIMULATION STUDY

    Name of the model   : Measles with Mixing and Quarantine
    Population size     : 5915
    Agents' data        : (none)
    Number of entities  : 15
    Days (duration)     : 365 (of 365)
    Number of viruses   : 1
    Last run elapsed t  : 0.00s
    Total elapsed t     : 15.00s (1000 runs)
    Last run speed      : 23.75 million agents x day / second
    Average run speed   : 141.85 million agents x day / second
    Rewiring            : off
    Last seed used      : 321912252

    Global events:
     - Quarantine process (runs daily)

    Virus(es):
     - Measles

    Tool(s):
     - MMR

    Model parameters:
     - (IGNORED) Vax improved recovery : 0.5000
     - Contact tracing days window     : 4.0000
     - Contact tracing success rate    : 0.0e+00
     - Days undetected                 : 2.0000
     - Hospitalization period          : 7.0000
     - Hospitalization rate            : 0.0370
     - Incubation period               : 12.0000
     - Isolation period                : 4.0000
     - Isolation willingness           : 0.0e+00
     - Prodromal period                : 4.0000
     - Quarantine period               : 21.0000
     - Quarantine willingness          : 0.9000
     - Rash period                     : 3.0000
     - Rash reduction contact rate     : 0.5000
     - Transmission rate               : 0.2000
     - Vaccination rate                : 0.0e+00
     - Vax efficacy                    : 0.9700

    Distribution of the population at time 365:
      - ( 0) Susceptible             : 5914 -> 5913
      - ( 1) Latent                  :    1 -> 0
      - ( 2) Prodromal               :    0 -> 0
      - ( 3) Rash                    :    0 -> 0
      - ( 4) Isolated                :    0 -> 0
      - ( 5) Isolated Recovered      :    0 -> 0
      - ( 6) Quarantined Latent      :    0 -> 0
      - ( 7) Quarantined Susceptible :    0 -> 0
      - ( 8) Quarantined Prodromal   :    0 -> 0
      - ( 9) Quarantined Recovered   :    0 -> 0
      - (10) Hospitalized            :    0 -> 0
      - (11) Recovered               :    0 -> 2

    Transition Probabilities:
     - Susceptible              1.00  0.00     -     -     -     -     -     -     -     -     -     -
     - Latent                      -  0.96  0.04     -     -     -     -     -     -     -     -     -
     - Prodromal                   -     -  0.33  0.67     -     -     -     -     -     -     -     -
     - Rash                        -     -     -  0.33     -     -     -     -     -     -     -  0.67
     - Isolated                    -     -     -     -     -     -     -     -     -     -     -     -
     - Isolated Recovered          -     -     -     -     -     -     -     -     -     -     -     -
     - Quarantined Latent          -     -     -     -     -     -     -     -     -     -     -     -
     - Quarantined Susceptible     -     -     -     -     -     -     -     -     -     -     -     -
     - Quarantined Prodromal       -     -     -     -     -     -     -     -     -     -     -     -
     - Quarantined Recovered       -     -     -     -     -     -     -     -     -     -     -     -
     - Hospitalized                -     -     -     -     -     -     -     -     -     -     -     -
     - Recovered                   -     -     -     -     -     -     -     -     -     -     -  1.00

To retrieve the results, we use the `run_multiple_get_results()`
function:

``` r
# Extracting the results
ans <- measles_model |>
  run_multiple_get_results(
    freader = data.table::fread
  )
```

The function call will get us the results as a list of data.frames
(data.table objects in this case). We will use the `data.table` package
to manipulate the information.

``` r
# Converting into data.table format for convenience
library(data.table)
outbreak_size <- ans$outbreak_size |> as.data.table()
hospitalizations <- ans$hospitalizations |> as.data.table()
reproductive <- ans$reproductive |> as.data.table()
```

## Reproductive number

``` r
# Filter the index case
reproductive <- reproductive[(source != -1) & source_exposure_date == 0]

reproductive[, mean(rt)]
```

    [1] 2.179

``` r
reproductive[, median(rt)]
```

    [1] 1

``` r
reproductive[rt > 0, mean(rt)]
```

    [1] 3.069014

``` r
hist(
  reproductive$rt,
  breaks = 50,
  main = "Reproductive number distribution",
  xlab = "Rt"
  )
```

![](r0_7-epistorm_FALSE-rash_contact_redux_0.50-isolation_willingness_0.0-quarantine_willingness_0.9-contact_tracing_success_0.00_files/figure-commonmark/reproductive-number-1.png)

## Outbreak size

Finally, since we are only interested about the final outbreak size (in
this case), can will collapse the data to get the total number of cases
at the final simulation day. Subsequently, we can plot the results using
the `hist` function:

``` r
# Aggregating to get the final
set.seed(331)
nsims <- length(unique(outbreak_size$sim_num))

with(
  outbreak_size[sample(1:.N, 20000)],
  {
    plot(
      x = date,
      y = outbreak_size,
      col = adjustcolor("blue", alpha.f = .1),
      pch = 19,
      ylab = "Cases",
      xlab = "Day",
      main = "Measles outbreak size at the Utah-Arizona Border",
      sub = sprintf(
        "Mixing model with age and school data (%i simulations)",
        nsims
      )
    )
})

# Adding a 50th percentile line
fiftieth <- outbreak_size[,
  .(outbreak_size = quantile(outbreak_size, probs = 0.5)),
  by = date]$outbreak_size

lines(
  x = outbreak_size$date |> unique() |> sort(),
  y = fiftieth,
  col = "black",
  lwd = 4,
  lty = "dashed"
)
```

![](r0_7-epistorm_FALSE-rash_contact_redux_0.50-isolation_willingness_0.0-quarantine_willingness_0.9-contact_tracing_success_0.00_files/figure-commonmark/timeline-outbreak-size-1.png)

We can also investigate the distribution of the final counts

``` r
# Aggregating to get the final
hist_ans <- with(
  outbreak_size[date == max(date)],
  {
    hist(
      outbreak_size,
      main = "Measles outbreak size at the Utah-Arizona Border",
      sub = sprintf(
        "Mixing model with age and school data (%i simulations)",
        nsims
      ),
      breaks = 50,
      xlab   = "Cases",
      xlim   = c(0, max(outbreak_size, n_unvax) * 1.1)
    )
})

# Adding the maximum number of unvaccinated individuals as
# a vertical line
abline(v = n_unvax, col = "black", lwd = 2, lty = "dashed")
text(
  x = n_unvax,
  y = hist_ans$counts |> max() * 0.5,
  labels = "Total unvaccinated",
  pos = 4,
  srt = 90,
  col = "black"
)
```

![](r0_7-epistorm_FALSE-rash_contact_redux_0.50-isolation_willingness_0.0-quarantine_willingness_0.9-contact_tracing_success_0.00_files/figure-commonmark/hist-outbreak-size-1.png)

The probability of a large outbreak (more than 100 cases) is 62.4%.

## Hospitalizations

In the case of the hospitalizations, we can draw a similar figure. The
hospitalizations data contains the following information:

1.  Cases per virus (just measles in this case).
2.  Cases per tool (or the lack of). Information about “no tool” is
    recorded with a `tool_id == -1`.
3.  The counts (how many records in the data).
4.  Weights.

The weights attribute is to ensure that we take into consideration
counting individuals more than once. For instance, if a model has more
than one tool (not just vaccination), the individual who has two tools
would be included twice in `count`. Thus, if we wanted to count the raw
number of hospitalization cases, we would add across `weight`, but the
`count` variable yields how many individuals were hospitalized under
that combination of tool and virus id.

``` r
hosp_tot <- hospitalizations[, .(total = sum(count)), by = .(sim_num, tool_id)]
hosp_tot[, status := fifelse(tool_id == -1, "Unvax", "Vax")]
hosp_tot[, tool_id := NULL]
```

We can create a couple of boxplot to show how many cases we see per
vaccination status:

``` r
hosp_tot <- merge(
  hosp_tot[status == "Unvax", .(sim_num, unvax = total)],
  hosp_tot[status == "Vax", .(sim_num, vax = total)],
  all = TRUE
)

# Filling zeros
hosp_tot[, unvax := fcoalesce(unvax, 0L)]
hosp_tot[, vax := fcoalesce(vax, 0L)]

hosp_tot[, .(vax, unvax)] |>
  as.matrix() |>
  boxplot(
    ylab = "Count",
    xlab = "Status",
    main = "Hospitalization per vaccination status",
    sub  = sprintf(
      "Mixing model with age and school data (%i simulations)",
      nsims
    )
  )
```

![](r0_7-epistorm_FALSE-rash_contact_redux_0.50-isolation_willingness_0.0-quarantine_willingness_0.9-contact_tracing_success_0.00_files/figure-commonmark/summary-hosp-1.png)

## Scenario without Quarantine

The previous scenario included a quarantine process based on contact
tracing. Using the same model object, we can run a separate scenario
that does not include quarantine. To do so, we simply need to set the
quarantine duration to `-1`, which effectively disables the quarantine
process. We can do this as follows:

``` r
# Setting the new parameter
set_param(measles_model, "Quarantine period", -1)

# We can now re-run the model (we need a new saver)
measles_model |>
  run_multiple(
    ndays = 365,
    nsims = 400,
    seed  = 8812,
    saver = make_saver("outbreak_size", "hospitalizations"),
    nthreads = params$threads
  )
```

    Starting multiple runs (400) using 8 thread(s)
    _________________________________________________________________________
    _________________________________________________________________________
    ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| done.

``` r
# Checking no quarantine in scenario summary
summary(measles_model)
```

    ________________________________________________________________________________
    ________________________________________________________________________________
    SIMULATION STUDY

    Name of the model   : Measles with Mixing and Quarantine
    Population size     : 5915
    Agents' data        : (none)
    Number of entities  : 15
    Days (duration)     : 365 (of 365)
    Number of viruses   : 1
    Last run elapsed t  : 0.00s
    Total elapsed t     : 21.00s (1400 runs)
    Last run speed      : 22.45 million agents x day / second
    Average run speed   : 138.89 million agents x day / second
    Rewiring            : off
    Last seed used      : 522087843

    Global events:
     - Quarantine process (runs daily)

    Virus(es):
     - Measles

    Tool(s):
     - MMR

    Model parameters:
     - (IGNORED) Vax improved recovery : 0.5000
     - Contact tracing days window     : 4.0000
     - Contact tracing success rate    : 0.0e+00
     - Days undetected                 : 2.0000
     - Hospitalization period          : 7.0000
     - Hospitalization rate            : 0.0370
     - Incubation period               : 12.0000
     - Isolation period                : 4.0000
     - Isolation willingness           : 0.0e+00
     - Prodromal period                : 4.0000
     - Quarantine period               : -1.0000
     - Quarantine willingness          : 0.9000
     - Rash period                     : 3.0000
     - Rash reduction contact rate     : 0.5000
     - Transmission rate               : 0.2000
     - Vaccination rate                : 0.0e+00
     - Vax efficacy                    : 0.9700

    Distribution of the population at time 365:
      - ( 0) Susceptible             : 5914 -> 5914
      - ( 1) Latent                  :    1 -> 0
      - ( 2) Prodromal               :    0 -> 0
      - ( 3) Rash                    :    0 -> 0
      - ( 4) Isolated                :    0 -> 0
      - ( 5) Isolated Recovered      :    0 -> 1
      - ( 6) Quarantined Latent      :    0 -> 0
      - ( 7) Quarantined Susceptible :    0 -> 0
      - ( 8) Quarantined Prodromal   :    0 -> 0
      - ( 9) Quarantined Recovered   :    0 -> 0
      - (10) Hospitalized            :    0 -> 0
      - (11) Recovered               :    0 -> 0

    Transition Probabilities:
     - Susceptible              1.00  0.00     -     -     -     -     -     -     -     -     -     -
     - Latent                      -  0.67  0.33     -     -     -     -     -     -     -     -     -
     - Prodromal                   -     -     -  1.00     -     -     -     -     -     -     -     -
     - Rash                        -     -     -     -  1.00     -     -     -     -     -     -     -
     - Isolated                    -     -     -     -     -  1.00     -     -     -     -     -     -
     - Isolated Recovered          -     -     -     -     -  1.00     -     -     -     -     -     -
     - Quarantined Latent          -     -     -     -     -     -     -     -     -     -     -     -
     - Quarantined Susceptible     -     -     -     -     -     -     -     -     -     -     -     -
     - Quarantined Prodromal       -     -     -     -     -     -     -     -     -     -     -     -
     - Quarantined Recovered       -     -     -     -     -     -     -     -     -     -     -     -
     - Hospitalized                -     -     -     -     -     -     -     -     -     -     -     -
     - Recovered                   -     -     -     -     -     -     -     -     -     -     -     -

Like before, we can extract the results using the
`run_multiple_get_results()` function:

``` r
# Extracting the results
ans_no_quarantine <- measles_model |>
  run_multiple_get_results(
    freader = data.table::fread
  )

outbreak_size_no_quarantine <-
  ans_no_quarantine$outbreak_size |> as.data.table()
hospitalizations_no_quarantine <-
  ans_no_quarantine$hospitalizations |> as.data.table()
```

We can compare both using a simple boxplot:

``` r
os_nq <- outbreak_size_no_quarantine[date == max(date)]$outbreak_size
os_q  <- outbreak_size[date == max(date)]$outbreak_size

bar_cols <- c("tomato", "steelblue") |>
  adjustcolor(alpha.f = 0.5)

hist(
  os_nq, breaks = 50,
  main = "Outbreak Size",
  col = bar_cols[1],
  xlab = "Outbreak size"
)
hist(
  os_q,
  col = bar_cols[2],
  add = TRUE, breaks = 50
)

legend(
  "topleft",
  legend = c("No quarantine", "Quarantine"),
  fill = bar_cols,
  border = NA,
  bty = "n"
)
```

![](r0_7-epistorm_FALSE-rash_contact_redux_0.50-isolation_willingness_0.0-quarantine_willingness_0.9-contact_tracing_success_0.00_files/figure-commonmark/compare-scenarios-1.png)

The probability of observing an outbreak of more than 100 cases is
62.40% with quarantine, and 64.25% without quarantine. So, although
mild, the quarantine process seems to have an effect in the outbreak
size, with a higher number of cases observed in the scenario without
quarantine.

## Analyzing the peak time

``` r
peak_no_quarantine <- rbind(
  outbreak_size_no_quarantine[,
    .(
      incidence = diff(outbreak_size),
      date = date[-1],
      type = "No quarantine"
      ), by = sim_num
    ],
  outbreak_size[,
    .(
      incidence = diff(outbreak_size),
      date = date[-1],
      type = "Quarantine"
      ), by = sim_num
    ]
)

library(ggplot2)

peak_no_quarantine |>
  ggplot(aes(
    x = date, y = incidence, group = sim_num
    )) +
    facet_wrap(~ type) +
    geom_line(alpha = 0.1) +
    labs(
      title = "Measles incidence at the Utah-Arizona Border (no quarantine)",
      x = "Day",
      y = "Incidence"
    ) +
    theme_minimal()
```

![](r0_7-epistorm_FALSE-rash_contact_redux_0.50-isolation_willingness_0.0-quarantine_willingness_0.9-contact_tracing_success_0.00_files/figure-commonmark/peak-time-1.png)

## Final comments

Ultimately, based on the current results, we would be expecting a large
proportion (close to 85%) of unvaccinated individuals to become
infected, with a small number of vaccinated individuals also getting
infected. Running other scenarios where the quarantine process is not
implemented results in unvaccinated individuals having a higher chance
of becoming infected. This is consistent with the high R0 of measles and
the low vaccination rates in the area. Nonetheless, these results should
be taken with caution, as this simulation is a simplification of reality
that does not consider, for example, individuals’ changing their
behavior as a function of what is observed; it would be natural to
expect some level of precaution, *e.g.*, reducing contact rates, would
be observed in such a situation.
