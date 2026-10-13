# Figure SI5
source("plotEBSP.R")

df <- removeBurnin(read.table("EBSP_epi.log", header=T, sep='\t', as.is=T), 0.1)
res_epi <- processEBSPdata(df, T)

# Get and format dates
MRSD_date <- as.Date("2026-02-28")
res_epi$allYears <- as.numeric(format(MRSD_date, "%Y")) - res_epi$allTimes
res_epi$allCalendarDates <- MRSD_date - (res_epi$allTimes*365.25)

# Use generation time to get case numbers    
generation_time <- 11.9/365 # pulled from average time from rash onset to secondary case
res_epi$Nmedian <- res_epi$Nmedian / generation_time
res_epi$NlowerCPD <- res_epi$NlowerCPD / generation_time
res_epi$NupperCPD <- res_epi$NupperCPD / generation_time
res_epi$changePops <- lapply(res_epi$changePops, function(x) x / generation_time)

df <- removeBurnin(read.table("EBSP_genomepi.log", header=T, sep='\t', as.is=T), 0.1)
res_genomepi <- processEBSPdata(df, T)

# Get and format dates
MRSD_date <- as.Date("2026-02-28")
res_genomepi$allYears <- as.numeric(format(MRSD_date, "%Y")) - res_genomepi$allTimes
res_genomepi$allCalendarDates <- MRSD_date - (res_genomepi$allTimes*365.25)

# Use generation time to get case numbers    
generation_time <- 11.9/365 # pulled from average time from rash onset to secondary case
res_genomepi$Nmedian <- res_genomepi$Nmedian / generation_time
res_genomepi$NlowerCPD <- res_genomepi$NlowerCPD / generation_time
res_genomepi$NupperCPD <- res_genomepi$NupperCPD / generation_time
res_genomepi$changePops <- lapply(res_genomepi$changePops, function(x) x / generation_time)

scenario_colors <- c(
  "Epidemiological Inclusion" = "#9C7BB2", 
  "Genomic Inclusion" = "#B0895A"
)

estimates_df <- data.frame(
  scenario = c("Epidemiological Inclusion", "Genomic Inclusion"), 
  outbreak_size = c(4944, 5821),
  lower = c(2859, 3549),
  upper = c(9691, 10924)
)

p_main_E <- ggplot(estimates_df, aes(x = scenario, fill = scenario, color = scenario)) +
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
        axis.title.x = element_text(vjust = -1, size = 20),
        axis.title.y = element_text(vjust = 2, size = 20),
        axis.ticks = element_line(color = "black"))

plot_data_epi <- data.frame("date" = res_epi$allCalendarDates, "pop" = res_epi$Nmedian, "lowCI" = res_epi$NlowerCPD, "highCI" = res_epi$NupperCPD)

plot_data_genomepi <- data.frame("date" = res_genomepi$allCalendarDates, "pop" = res_genomepi$Nmedian, "lowCI" = res_genomepi$NlowerCPD, "highCI" = res_genomepi$NupperCPD)

p_main_D <- ggplot()+
  geom_ribbon(data = plot_data_epi, aes(x = date, y = pop, ymin = lowCI, ymax = highCI, fill = "Epidemiological Inclusion"), alpha = 0.2) +
  geom_line(data = plot_data_epi, aes(x = date, y = pop, color = "Epidemiological Inclusion"), size = 1.5)+
  geom_ribbon(data = plot_data_genomepi, aes(x = date, y = pop, ymin = lowCI, ymax = highCI, fill = "Genomic Inclusion"), alpha = 0.2) +
  geom_line(data = plot_data_genomepi, aes(x = date, y = pop, color = "Genomic Inclusion"),size = 1.5)+
  labs(x = "Date", y= expression(Effective~Population~Size~(N[e])))+
  scale_x_date(date_breaks = "1 month", date_labels = "%b %Y",
               limits = c(as.Date("2025-07-14"), as.Date("2026-02-28")))+
  theme_cowplot()+
  theme(legend.position = c(0.1, 0.85),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(), 
        axis.line = element_line(color = "black"), 
        axis.text.x = element_text(hjust = 1, size = 15, angle = 30),
        axis.text.y = element_text(size = 15),
        axis.title.x = element_text(vjust = -1, size = 20),
        axis.title.y = element_text(vjust = 2, size = 20),
        axis.ticks = element_line(color = "black"),
        legend.text = element_text(size = 15)
  )+
  scale_color_manual(name = "", 
                     values = c("Epidemiological Inclusion" = "#9C7BB2", 
                                "Genomic Inclusion" = "#B0895A"))+
  scale_fill_manual(name = "", 
                    values = c("Epidemiological Inclusion" = "#9C7BB2", 
                               "Genomic Inclusion" = "#B0895A"))

plot_grid(p_main_D, p_main_E, ncol = 2, rel_widths = c(1.6, 1))