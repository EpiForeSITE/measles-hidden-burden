# Figure SI 6
source("plotEBSP.R")

load("case_data_SW.RData")
load("case_data_notSW.RData")

case_data_combined <- merge(case_data_SW, case_data_notSW, by  = "date", all = TRUE)
case_data_combined[is.na(case_data_combined)] <- 0
names(case_data_combined) <- c("Date", "SW", "notSW")
case_data_combined <- case_data_combined %>%
  pivot_longer(
    cols = -Date,           
    names_to = "State",     
    values_to = "Cases"     
  )

case_data_combined_weekly <- case_data_combined %>%
  mutate(Date = Date) %>%
  mutate(Week_Starting = floor_date(Date, unit = "week", week_start = 3)) %>%
  group_by(Week_Starting, State) %>%
  summarize(Weekly_Cases = sum(Cases, na.rm = TRUE), .groups = "drop")
names(case_data_combined_weekly) <- c("Date", "State", "Cases")

df <- removeBurnin(read.table("EBSP_genomepi.log", header=T, sep='\t', as.is=T), 0.1)
res_genomepi <- processEBSPdata(df, T)

MRSD_date <- as.Date("2026-02-28")
res_genomepi$allYears <- as.numeric(format(MRSD_date, "%Y")) - res_genomepi$allTimes
res_genomepi$allCalendarDates <- MRSD_date - (res_genomepi$allTimes*365.25)

# Use generation time to get case numbers    
generation_time <- 11.9/365 # pulled from average time from rash onset to secondary case
res_genomepi$Nmedian <- res_genomepi$Nmedian / generation_time
res_genomepi$NlowerCPD <- res_genomepi$NlowerCPD / generation_time
res_genomepi$NupperCPD <- res_genomepi$NupperCPD / generation_time
res_genomepi$changePops <- lapply(res_genomepi$changePops, function(x) x / generation_time)

plot_data_genomepi <- data.frame("date" = res_genomepi$allCalendarDates, "pop" = res_genomepi$Nmedian, "lowCI" = res_genomepi$NlowerCPD, "highCI" = res_genomepi$NupperCPD)

ggplot() +
  geom_bar(data = case_data_combined_weekly, aes(x = Date, y = Cases, fill = State), stat = "identity", position = "dodge") +
  geom_line(data = plot_data_genomepi, 
            aes(x = date, y = pop, color = "Ne"), linewidth = 1) + # for fig SI6 - make sure its AUC
  labs(y = "Incidence", x = "Date")+
  theme_minimal()+
  theme(
    panel.grid.major = element_blank(), 
    panel.grid.minor = element_blank(), 
    axis.line = element_line(color = "black"),
    axis.text.x = element_text(hjust = 1, angle = 25, size = 15),
    axis.text.y = element_text(size = 15),
    axis.title.x = element_text(size = 20),
    axis.title.y = element_text(vjust = 2, size = 20),
    legend.text = element_text(size = 15),
    legend.title = element_blank(),
    legend.position = c(0.25, 0.8))+
  scale_x_date(date_breaks = "1 month", date_labels = "%b %Y",
               limits = c(as.Date("2025-05-01"), as.Date("2026-02-28")))+
  scale_fill_manual(values = c("SW" = "mediumpurple4", "notSW" = "coral"), labels = c("SW" = "Inside Community", "notSW" = "Outside Community"))+
  scale_color_manual(
    values = c("Ne" = "black"),
    labels = expression(Effective ~ Population ~ Size ~ (N[e]))
  )
