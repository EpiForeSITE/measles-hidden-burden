# R0 = 9 population-immunity re-run: final outbreak sizes of the three
# Figure 4 arms (see FigureABM.R) for each adult vaccination assumption, in
# total and for children (under 18) and adults, and a comparison of the arm
# without interventions with the deterministic final sizes of the
# multigroup.vaccine vignette ("Alternate adult immunization assumptions").
#
# Usage (from the repository root):
#   Rscript Figure_Data/PopulationImmunity.R [output_dir]
#
# Writes <output_dir>/summary.csv, <output_dir>/deterministic_comparison.csv,
# and <output_dir>/deterministic_comparison.{png,pdf}.

library(data.table)
library(ggplot2)
library(multigroup.vaccine)
source(file.path("Figure_Data", "FigureABM.R"))

args <- commandArgs(trailingOnly = TRUE)
dir  <- if (length(args)) args[1] else "population_immunity"

ASSUMPTIONS <- c("baseline", "78pct", "86pct", "93pct")
ADULTS      <- c("18to24", "25to44", "45to69", "70+")

# Final infections per run, by age, of each arm and assumption ----------------
runs <- rbindlist(lapply(ASSUMPTIONS, function(v) {
  rbindlist(lapply(seq_len(nrow(FOCAL_SCENARIOS)), function(i) {
    s <- FOCAL_SCENARIOS[i]
    f <- scenario_file(dir, 9, s$rash, s$ct, vax_adults = v)
    x <- as.data.table(
      readRDS(f)[[sub("outbreak_size", "infections_by_age", s$arm)]]
    )
    x[,
      .(
        Children = as.numeric(sum(infections[!age_group %in% ADULTS])),
        Adults   = as.numeric(sum(infections[age_group %in% ADULTS]))
      ),
      by = sim_num
    ][, `:=`(Total = Children + Adults, scenario = s$label, vax_adults = v)]
  }))
}))
runs[, scenario := factor(scenario, levels = FOCAL_SCENARIOS$label)]
runs[, vax_adults := factor(vax_adults, levels = ASSUMPTIONS)]

retained <- runs[Total >= MIN_OUTBREAK_SIZE]

out <- runs[, .(runs = .N), by = .(vax_adults, scenario)][
  retained[,
    .(
      retained = .N,
      median   = median(Total),
      q25      = quantile(Total, 0.25, names = FALSE),
      q75      = quantile(Total, 0.75, names = FALSE),
      child    = median(Children),
      adult    = median(Adults)
    ),
    by = .(vax_adults, scenario)
  ],
  on = .(vax_adults, scenario)
]
out[, child_adult_ratio := round(child / adult, 1)]
setorder(out, vax_adults, scenario)
fwrite(out, file.path(dir, "summary.csv"))
print(out)

# Deterministic final sizes, as in the vignette and test-calibration.R --------
cm  <- readRDS(file.path("data", "utaz_contacts_polymod.rds"))
det <- rbindlist(lapply(ASSUMPTIONS, function(v) {
  d <- readRDS(file.path("data", sprintf("utaz_vaccination_adults_%s.rds", v)))
  efficacy <- ifelse(
    d$age_labels %in% c("under1", "1to4"),
    0.93,
    ifelse(d$age_labels == "70+", 1, 0.97)
  )
  fs <- finalsize(
    popsize       = d$agepops,
    R0            = 9,
    contactmatrix = cm,
    relsusc       = 1,
    reltransm     = 1,
    initR         = rep(0, nrow(d)),
    initI         = as.numeric(d$age_labels == "18to24"),
    initV         = round(d$vacc_rate * d$agepops * efficacy)
  )
  data.table(
    vax_adults = v,
    Children   = sum(fs[!d$age_labels %in% ADULTS]),
    Adults     = sum(fs[d$age_labels %in% ADULTS])
  )[, Total := Children + Adults]
}))

# Comparison: medians and IQRs of the ABM arm without interventions -----------
groups <- c("Total", "Children", "Adults")

abm <- melt(
  retained[scenario == FOCAL_SCENARIOS$label[1]],
  id.vars       = "vax_adults",
  measure.vars  = groups,
  variable.name = "group"
)[,
  .(
    abm_median = median(value),
    abm_q25    = quantile(value, 0.25, names = FALSE),
    abm_q75    = quantile(value, 0.75, names = FALSE)
  ),
  by = .(vax_adults, group)
]

det_long <- melt(
  det,
  id.vars       = "vax_adults",
  measure.vars  = groups,
  variable.name = "group",
  value.name    = "deterministic"
)[, vax_adults := factor(vax_adults, levels = ASSUMPTIONS)]

comparison <- abm[det_long, on = .(vax_adults, group)]
comparison[, deterministic := round(deterministic)]
setorder(comparison, group, vax_adults)
fwrite(comparison, file.path(dir, "deterministic_comparison.csv"))
print(comparison)

# Figure ----------------------------------------------------------------------
MODEL_COLORS <- c(
  "Agent-based model (median)" = SCENARIO_COLORS[[1]],
  "Deterministic final size"   = SCENARIO_COLORS[[2]]
)
x_labels <- c(
  baseline = "Baseline",
  "78pct"  = "78%",
  "86pct"  = "86%",
  "93pct"  = "93%"
)
fig_data <- melt(
  comparison,
  id.vars       = c("vax_adults", "group"),
  measure.vars  = c("abm_median", "deterministic"),
  variable.name = "model"
)[, model := factor(model, labels = names(MODEL_COLORS))]
fig_data[, group := factor(
  group,
  levels = groups,
  labels = c("Total", "Children (under 18)", "Adults (18+)")
)]

fig <- ggplot(fig_data, aes(vax_adults, value, color = model, shape = model)) +
  geom_point(
    position = position_dodge(width = 0.4),
    size     = 2.6,
    stroke   = 1,
    fill     = "white"
  ) +
  facet_wrap(~group, nrow = 1) +
  scale_color_manual(values = MODEL_COLORS) +
  scale_shape_manual(values = c(16, 23)) +
  scale_x_discrete(labels = x_labels) +
  scale_y_continuous(
    labels = function(x) format(x, big.mark = ","),
    limits = c(0, NA)
  ) +
  labs(
    x        = "Adult vaccination assumption (coverage of ages 18-69)",
    y        = "Infections",
    title    = "Final outbreak size by adult vaccination assumption, R0 = 9",
    subtitle = sprintf(
      paste(
        "No interventions; agent-based model over the runs with 10 or more",
        "cases (interquartile ranges span at most %s infections)"
      ),
      max(comparison[, abm_q75 - abm_q25])
    )
  ) +
  theme_figure4() +
  theme(strip.text = element_text(face = "bold", color = INK_PRIMARY))

out_fig <- file.path(dir, "deterministic_comparison")
ggsave(
  paste0(out_fig, ".png"),
  fig,
  width  = 9,
  height = 4,
  dpi    = 300,
  bg     = "white"
)
ggsave(paste0(out_fig, ".pdf"), fig, width = 9, height = 4)
