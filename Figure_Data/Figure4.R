# Figure 4A: Phylodynamic Line Graph
source("plotEBSP.R")

df1 <- removeBurnin(read.table("EBSP_epi.log", header=T, sep='\t', as.is=T), 0.1)
res_epi <- processEBSPdata(df1, T)
MRSD_date <- as.Date("2026-02-28")
res_epi$allYears <- as.numeric(format(MRSD_date, "%Y")) - res_epi$allTimes
res_epi$allCalendarDates <- MRSD_date - (res_epi$allTimes*365.25)
sigma <- (1/9)+(1/0.34)+1
generation_time <- 11.9/365 # pulled from average time from rash onset to secondary case
factor <- sigma/generation_time
res_epi$Nmedian <- res_epi$Nmedian*factor
res_epi$NlowerCPD <- res_epi$NlowerCPD*factor
res_epi$NupperCPD <- res_epi$NupperCPD*factor
plot_data_epi <- data.frame("date" = res_epi$allCalendarDates, "pop" = res_epi$Nmedian, "lowCI" = res_epi$NlowerCPD, "highCI" = res_epi$NupperCPD)

df1 <- removeBurnin(read.table("EBSP_genomepi.log", header=T, sep='\t', as.is=T), 0.1)
res_genomepi <- processEBSPdata(df1, T)
MRSD_date <- as.Date("2026-02-28")
res_genomepi$allYears <- as.numeric(format(MRSD_date, "%Y")) - res_genomepi$allTimes
res_genomepi$allCalendarDates <- MRSD_date - (res_genomepi$allTimes*365.25)
sigma <- (1/9)+(1/0.34)+1
generation_time <- 11.9/365 # pulled from average time from rash onset to secondary case
factor <- sigma/generation_time
res_genomepi$Nmedian <- res_genomepi$Nmedian*factor
res_genomepi$NlowerCPD <- res_genomepi$NlowerCPD*factor
res_genomepi$NupperCPD <- res_genomepi$NupperCPD*factor
plot_data_genomepi <- data.frame("date" = res_genomepi$allCalendarDates, "pop" = res_genomepi$Nmedian, "lowCI" = res_genomepi$NlowerCPD, "highCI" = res_genomepi$NupperCPD)

p_main_A <- ggplot()+
  geom_ribbon(data = plot_data_epi, aes(x = date, y = pop, ymin = lowCI, ymax = highCI, fill = "Epidemiological Inclusion"), alpha = 0.2) +
  geom_line(data = plot_data_epi, aes(x = date, y = pop, color = "Epidemiological Inclusion"), size = 1.5)+
  geom_ribbon(data = plot_data_genomepi, aes(x = date, y = pop, ymin = lowCI, ymax = highCI, fill = "Genomic Inclusion"), alpha = 0.2) +
  geom_line(data = plot_data_genomepi, aes(x = date, y = pop, color = "Genomic Inclusion"),size = 1.5)+
  labs(x = "Date", y= expression(Effective~Population~Size~(N[e])), color = "Among all linked cases", fill = "Among all linked cases")+
  scale_x_date(date_breaks = "1 month", date_labels = "%b %Y",
               limits = c(as.Date("2025-07-14"), as.Date("2026-02-28")))+
  theme_cowplot()+
  theme(legend.position = c(0.1, 0.85),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(), 
        axis.line = element_line(color = "black"), 
        axis.text.x = element_text(hjust = 1, size = 15, angle = 30),
        axis.text.y = element_text(size = 15),
        axis.title.x = element_text(vjust = -1, size = 15),
        axis.title.y = element_text(vjust = 2, size = 15),
        axis.ticks = element_line(color = "black"),
        legend.text = element_text(size = 15)
  )+
  scale_color_manual(name = "", 
                     values = c("Epidemiological Inclusion" = "#9C7BB2", 
                                "Genomic Inclusion" = "#B0895A"))+
  scale_fill_manual(name = "", 
                    values = c("Epidemiological Inclusion" = "#9C7BB2", 
                               "Genomic Inclusion" = "#B0895A"))

# Figure 4B: Phylodynamic Boxplot

scenario_colors <- c(
  "Epidemiological Inclusion" = "#9C7BB2", 
  "Genomic Inclusion" = "#B0895A"
)

estimates_df <- data.frame(
  scenario = c("Epidemiological Inclusion", "Genomic Inclusion"), 
  outbreak_size = c(1798, 2051),
  lower = c(1050, 1300),
  upper = c(3573, 3885)
)

p_main_B <- ggplot(estimates_df, aes(x = scenario, fill = scenario, color = scenario)) +
  geom_boxplot(aes(ymin = lower, 
                   lower = lower, 
                   middle = outbreak_size, 
                   upper = upper, 
                   ymax = upper,
                   alpha = 0.6,
                   color = scenario),
               stat = "identity",
               width = 0.9,
               position = position_dodge(width = 0.9)) +
  scale_fill_manual(values = scenario_colors, name = NULL) +
  scale_color_manual(values = scenario_colors, name = NULL) +
  scale_x_discrete(labels = c("Epidemiological \nInclusion", "Genomic \nInclusion")) +
  xlab("Sample Inclusion") + 
  ylab("Linked Outbreak Size") +
  theme_cowplot() +
  theme(legend.position = "none",
        axis.text.x = element_text(size = 15),
        axis.text.y = element_text(size = 15),
        axis.title.x = element_text(vjust = -1, size = 15),
        axis.title.y = element_text(vjust = 2, size = 15),
        axis.ticks = element_line(color = "black"))

# ABM Data

load("main_final.RData")
load("main_weekly.RData")

START_DATE           <- as.Date("2025-08-06")
EXTINCTION_THRESHOLD <- 100
DATE_XLIM            <- c(as.Date("2025-08-06"), as.Date("2026-03-01"))

# R0 values for the supplement sensitivity figure
R0_SUPPLEMENT <- seq(5, 17, by = 2)   # 5 7 9 11 13 15 17

# ---- 3 focal scenarios shown in main text + supplement ----
# Format: list(rash, iso, ct, label, color)
# Arm selection: iso == 0 → no-quarantine arm; iso > 0 → quarantine arm
FOCAL_SCENARIOS <- list(
  list(rash = 0.00, iso = 0.00, ct = 0.00,
       label = "No interventions",
       color = "#E4937B"),
  list(rash = 0.50, iso = 0.00, ct = 0.00,
       label = "Self-isolation only",
       color = "#8B7BAD"),
  list(rash = 0.75, iso = 0.00, ct = 0.25,
       label = "Self-isolation w/quarantine",
       color = "#4F868E")
)

SCENARIO_COLORS <- setNames(
  sapply(FOCAL_SCENARIOS, `[[`, "color"),
  sapply(FOCAL_SCENARIOS, `[[`, "label")
)
SCENARIO_LEVELS <- sapply(FOCAL_SCENARIOS, `[[`, "label")

# ---- Full parameter grid for heatmap (R0 = 9) ----
RASH_VALS <- c(0.00, 0.25, 0.50, 0.75, 1.00)
ISO_VALS  <- c(0.00, 0.25, 0.50, 0.75, 1.00)

# Figure 4C: ABM Line Graph

p_main_C <- ggplot(
  main_weekly,
  aes(x = week, y = median_weekly_cases,
      color = scenario_label, fill = scenario_label)) +
  geom_ribbon(aes(ymin = q25, ymax = q75), alpha = 0.2, color = NA) +
  geom_line(linewidth = 1) +
  scale_color_manual(values = SCENARIO_COLORS) +
  scale_fill_manual(values  = SCENARIO_COLORS) +
  coord_cartesian(xlim = DATE_XLIM) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b %Y", limits = c(as.Date("2025-07-14"), as.Date("2026-02-28")))+
  xlab("Date") + ylab("Weekly Cases") + labs(color = "Among cases from the community", fill = "Among cases from the community") +
  theme_cowplot() +
  theme(
    legend.position = c(0.55, 0.82),
    panel.grid.major = element_blank(), 
    panel.grid.minor = element_blank(), 
    axis.line = element_line(color = "black"), 
    axis.text.x = element_text(hjust = 1, size = 15, angle = 30),
    axis.text.y = element_text(size = 15),
    axis.title.x = element_text(vjust = -1, size = 15),
    axis.title.y = element_text(vjust = 2, size = 15),
    axis.ticks = element_line(color = "black"),
    legend.text = element_text(size = 15)
  )

# Figure 4D: ABM boxplot

p_main_D <- ggplot(
  main_final,
  aes(x = scenario_label, y = outbreak_size,
      color = scenario_label, fill = scenario_label, alpha = 0.8)
) +
  geom_boxplot(scale = "width") +
  scale_fill_manual(values  = SCENARIO_COLORS, name = NULL) +
  scale_color_manual(values = SCENARIO_COLORS, name = NULL) +
  scale_x_discrete(labels = c("No\nInterventions", "Self-Isolation\nOnly", "Self-Isolation\nWith Quarantine"))+
  xlab(NULL) + ylab("Community Outbreak Size") +
  theme_cowplot() +
  theme(
    legend.position = "none",
    axis.text.x = element_text(size = 15),
    axis.text.y = element_text(size = 15),
    axis.title.x = element_text(vjust = -1, size = 15),
    axis.title.y = element_text(vjust = 2, size = 15),
    axis.ticks = element_line(color = "black")
  )

plot_grid(p_main_A, p_main_B, p_main_C, p_main_D, ncol = 2, nrow = 2, rel_widths = c(1.6, 1), labels = c("A", "B", "C", "D"))


