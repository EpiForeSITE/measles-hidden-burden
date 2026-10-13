# Figure 2

## Figure 2A
vaxxed <- read.csv("vaxxed.csv")
names(vaxxed) <- c("Status", "United.States", "SW")
rownames(vaxxed) <- c("Unvaccinated or Unknown", "1 MMR Dose", "2+ MMR Doses")

vaxxed_long <- vaxxed %>%
  pivot_longer(cols = c(United.States, SW), 
               names_to = "Location", 
               values_to = "Percentage")

vax <- ggplot(vaxxed_long, aes(x = Status, y = Percentage, fill = Location)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(x = "MMR Vaccination Status of Cases",
       y = "Percent (%)") +
  theme_minimal()+
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.line = element_line(color = "black"),
    axis.ticks = element_line(color = "black"),
    plot.title = element_text(size = 22, hjust = 0.5),
    axis.title = element_text(size = 20),
    axis.text = element_text(size = 16),
    legend.text = element_text(size = 15),
    legend.position = c(0.10, 0.85),          
    legend.justification = c("left", "top"), 
    legend.background = element_blank()
  )+
  scale_x_discrete(labels = c("1 MMR Dose" = "1 MMR Dose", "2+ MMR Doses" = "2+ MMR Dose", "Unvaccinated or Unknown" = "Unvaccinated or\nUnknown"))+
  scale_fill_manual(
    name = "",
    labels = c("SW" = "Utah-Arizona\nBorder Outbreak", "United.States" = "United States"), 
    values = c("SW" = "mediumpurple4", "United.States" = "grey64")
  )

## Figure 2B
ages <- read.csv("ages.csv")
names(ages) <- c("Group", "United.States", "SW")

ages_long <- ages %>%
  pivot_longer(cols = c(United.States, SW), 
               names_to = "Location", 
               values_to = "Percentage")
ages_long$Group <- factor(ages_long$Group, 
                          levels = c("<5 years", "5-19 years", "20+ years", "Age Unknown"))

age <- ggplot(ages_long, aes(x = Group, y = Percentage, fill = Location)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(x = "Age of Cases",
       y = "Percent (%)") +
  theme_minimal()+
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.line = element_line(color = "black"),
    axis.ticks = element_line(color = "black"),
    plot.title = element_text(size = 22, hjust = 0.5),
    axis.title = element_text(size = 20),
    axis.text = element_text(size = 16),
    legend.position = "none"
  )+
  scale_fill_manual(
    name = "",
    labels = c("SW" = "SW", "United.States" = "United States"), 
    values = c("SW" = "mediumpurple4", "United.States" = "grey64")
  )

Fig2_AB <- plot_grid(vax, age, ncol = 1, labels = c("A", "B"))

## Figure 2C
counties_data <- counties(state = c("UT", "AZ"), cb = TRUE)

states_data <- states(cb = TRUE) %>%
  filter(STUSPS %in% c("UT", "AZ"))

case_count_map <- ggplot() +
  geom_sf(data = states_data, color = "black", size = 1.5) +
  geom_sf(data = counties_data, aes(fill = NAME), color = "black", alpha = 0.8) +
  scale_fill_manual(values = c("Carbon" = "grey87", 
                               "Daggett" = "grey87", 
                               "Duchesne" = "grey87",
                               "Emery" = "grey87", 
                               "Garfield" = "grey87",
                               "Morgan" = "grey87",
                               "Piute" = "grey87",
                               "Rich" = "grey87",
                               "Sanpete" = "grey87",
                               "Wayne" = "grey87",
                               "Iron" = "#F2C88FFF",
                               "Millard" = "#F2C88FFF",
                               "Salt Lake" = "#F2C88FFF",
                               "Kane" = "#FBE3C2FF",
                               "Juab" = "#FBE3C2FF",
                               "Wasatch" = "#FBE3C2FF",
                               "Grand" = "#FBE3C2FF",
                               "Uintah" = "#FBE3C2FF",
                               "Box Elder" = "#FBE3C2FF",
                               "Summit" = "#FBE3C2FF",
                               "Sevier" = "#FBE3C2FF",
                               "Weber" = "#FBE3C2FF",
                               "Davis" = "#FBE3C2FF",
                               "Tooele" = "#FBE3C2FF",
                               "San Juan" = "#FBE3C2FF",
                               "Cache" = "#FBE3C2FF",
                               "Beaver" = "#FBE3C2FF",
                               "Washington" = "#D37750FF",
                               "Utah" = "#ECB27DFF",
                               "Apache" = "grey87",
                               "Cochise" = "grey87",
                               "Coconino" = "#FBE3C2FF",
                               "Gila" = "grey87",
                               "Graham" = "grey87",
                               "Greenlee" = "grey87",
                               "La Paz" = "grey87",
                               "Maricopa" = "#FBE3C2FF",
                               "Mohave" = "#92351EFF",
                               "Navajo" = "#FBE3C2FF",
                               "Pima" = "#FBE3C2FF",
                               "Pinal" = "#FBE3C2FF",
                               "Santa Cruz" = "grey87",
                               "Yavapai" = "grey87",
                               "Yuma" = "grey87" )) +
  coord_sf(expand = FALSE) +
  theme_void()+
  theme(
    legend.position = "none",
    plot.margin = margin(0, 0, 0, 0)
  )

breaks <- c("0", "1-10", "11-50", "51-100", "101-200", ">200")
vals <- c(1,2,3,4,5,6)
dummy1 <- data.frame(breaks, vals)
dummy1$breaks <- factor(dummy1$breaks, levels = c("0", "1-10", "11-50", "51-100", "101-200", ">200"))
dummy_plot1 <- ggplot(data = dummy1, aes(x = breaks, y = vals, fill = breaks))+
  geom_bar(stat = "identity")+
  scale_fill_manual(values = c("0" = "grey87", "1-10" = "#FBE3C2FF", "11-50" = "#F2C88FFF", "51-100" = "#ECB27DFF", "101-200" = "#D37750FF", ">200" = "#92351EFF"))+
  labs(fill = "Case Count")+
  theme(
    legend.text = element_text(size = 15),
    legend.title = element_text(size = 15)
  )

shared_legend <- get_legend(dummy_plot1 + theme(legend.position = "right", 
                                                legend.box.margin = margin(0, 0, 0, 0),
                                                legend.margin     = margin(0, 0, 0, 0),
                                                plot.margin       = margin(0, 0, 0, 0)))
casecount_map <- plot_grid(case_count_map, shared_legend, ncol = 2, rel_widths = c(2, 1))

Fig2_ABC <- plot_grid(Fig2_AB, casecount_map, nrow = 1, ncol = 2, rel_widths = c(1.25,1), rel_heights = c(1,1.5), labels = c("", "C"))

## Figure 2D
outbreak_context <- read.csv("outbreak_context.csv")
outbreak_context$Date <- as.Date(outbreak_context$Date)

outbreak_context[is.na(outbreak_context)] <- 0

Utah_pop <- 3550000
Arizona_pop <- 7620000
Texas_pop <- 31700000
SouthCarolina_pop <- 5570000
Other_pop <- 294025471

outbreak_context <- outbreak_context %>%
  mutate(Utah = (Utah / Utah_pop) * 100000)
outbreak_context <- outbreak_context %>%
  mutate(Arizona = (Arizona / Arizona_pop) * 100000)
outbreak_context <- outbreak_context %>%
  mutate(Texas = (Texas / Texas_pop) * 100000)
outbreak_context <- outbreak_context %>%
  mutate(South.Carolina = (South.Carolina / SouthCarolina_pop) * 100000)
outbreak_context <- outbreak_context %>%
  mutate(Other = (Other / Other_pop) * 100000)

outbreak_context <- outbreak_context[-c(4,5,6)]

outbreak_long <- outbreak_context %>%
  pivot_longer(
    cols = -Date,
    names_to = "State",
    values_to = "Cases"
  )

OC <- ggplot(outbreak_long, aes(x = Date, y = Cases, fill = State)) +
  geom_bar(position = position_dodge(preserve = "single"), stat = "identity")+
  
  labs(y = "Incidence per 100,000", x = "Date", fill = "State") +
  theme_minimal() +
  theme(
    panel.grid.major = element_blank(), 
    panel.grid.minor = element_blank(), 
    axis.line = element_line(color = "black"),
    axis.text.x = element_text(hjust = 1, angle = 25, size = 15),
    axis.text.y = element_text(size = 15),
    axis.title.x = element_text(vjust = -1, size = 20),
    axis.title.y = element_text(vjust = 2, size = 15),
    legend.text = element_text(size = 15),
    legend.title = element_text(size = 15, face = "bold"),
    legend.position = "top") +
  scale_x_date(
    date_breaks = "1 month", 
    date_labels = "%b %Y"
  ) +
  scale_fill_manual(
    values = c(
      "Utah" = "mediumpurple4",
      "Arizona" = "indianred2",
      "Texas" = "sienna1",
      "South.Carolina" = "steelblue2",
      "Other" = "grey87"
    ),
    labels = c(
      "South.Carolina" = "South Carolina"
    )
  )+
  annotate("segment", 
           x = as.Date("2025-01-20"), xend = as.Date("2025-08-18"), 
           y = 1, yend = 1,  
           colour = "black", linewidth = 1)+
  annotate("text", 
           x = as.Date("2025-05-04"),
           y = 1.25,
           label = "Texas Outbreak", 
           size = 5, fontface = "italic")+
  annotate("segment", 
           x = as.Date("2025-10-01"), xend = as.Date("2026-04-25"), 
           y = 2.5, yend = 2.5,  
           colour = "black", linewidth = 1)+
  annotate("text", 
           x = as.Date("2026-01-15"),
           y = 2.75,
           label = "South Carolina Outbreak", 
           size = 5, fontface = "italic")+
  annotate("segment", 
           x = as.Date("2025-06-15"), xend = as.Date("2026-04-25"), 
           y = 1.5, yend = 1.5,  
           colour = "black", linewidth = 1)+
  annotate("text", 
           x = as.Date("2025-11-04"), 
           y = 1.75,
           label = "Utah/Arizona Outbreak", 
           size = 5, fontface = "italic")

plot_grid(Fig2_ABC, OC, nrow = 2, rel_heights = c(3,1), labels = c("", "D"))
