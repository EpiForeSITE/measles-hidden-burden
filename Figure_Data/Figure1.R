# Figure 1
counties_data <- counties(state = c("UT", "AZ"), cb = TRUE)
states_data <- states(cb = TRUE) %>% filter(STUSPS %in% c("UT", "AZ"))

vax_map <- ggplot() +
  geom_sf(data = states_data, color = "black", size = 2) +
  geom_sf(data = counties_data, aes(fill = NAME), color = "black", alpha = 0.8) +
  scale_fill_manual(values = c("Carbon" = "#6FC0BAFF", 
                               "Daggett" = "#F4C659FF", 
                               "Duchesne" = "#6FC0BAFF",
                               "Emery" = "#6FC0BAFF", 
                               "Garfield" = "#6FC0BAFF",
                               "Morgan" = "#6FC0BAFF",
                               "Piute" = "#871C0FFF",
                               "Rich" = "#6FC0BAFF",
                               "Sanpete" = "#6FC0BAFF",
                               "Wayne" = "#6FC0BAFF",
                               "Iron" = "#6FC0BAFF",
                               "Millard" = "#6FC0BAFF",
                               "Salt Lake" = "#019875FF",
                               "Kane" = "#F4C659FF",
                               "Juab" = "#6FC0BAFF",
                               "Wasatch" = "#6FC0BAFF",
                               "Grand" = "#6FC0BAFF",
                               "Uintah" = "#6FC0BAFF",
                               "Box Elder" = "#6FC0BAFF",
                               "Summit" = "#6FC0BAFF",
                               "Sevier" = "#6FC0BAFF",
                               "Weber" = "#019875FF",
                               "Davis" = "#019875FF",
                               "Tooele" = "#019875FF",
                               "San Juan" = "#019875FF",
                               "Cache" = "#019875FF",
                               "Beaver" = "#019875FF",
                               "Washington" = "#F4C659FF",
                               "Utah" = "#6FC0BAFF",
                               "Apache" = "#F4C659FF",
                               "Cochise" = "#6FC0BAFF",
                               "Coconino" = "#F4C659FF",
                               "Gila" = "#F4C659FF",
                               "Graham" = "#F4C659FF",
                               "Greenlee" = "orange2",
                               "La Paz" = "#6FC0BAFF",
                               "Maricopa" = "#F4C659FF",
                               "Mohave" = "#871C0FFF",
                               "Navajo" = "orange2",
                               "Pima" = "#6FC0BAFF",
                               "Pinal" = "#019875FF",
                               "Santa Cruz" = "#019875FF",
                               "Yavapai" = "#871C0FFF",
                               "Yuma" = "#6FC0BAFF" )) +
  coord_sf(expand = FALSE) +
  theme_void()+
  theme(
    legend.position = "none",
    plot.margin = margin(0, 0, 0, 0)
  )

breaks <- c("95-100%", "90-94.9%", "85-89.9%", "80-84.9%", "75-79.9%", "<75%")
vals <- c(1,2,3,4,5,6)
dummy2 <- data.frame(breaks, vals)
dummy2$breaks <- factor(dummy2$breaks, levels = c("95-100%", "90-94.9%", "85-89.9%", "80-84.9%", "75-79.9%", "<75%"))
dummy_plot2 <- ggplot(data = dummy2, aes(x = breaks, y = vals, fill = breaks))+
  geom_bar(stat = "identity")+
  scale_fill_manual(values = c("95-100%" = "#019875FF", "90-94.9%" = "#6FC0BAFF", "85-89.9%" = "#F4C659FF", "80-84.9%" = "orange2", "75-79.9%" = "#AF2213FF", "<75%" = "#871C0FFF"))+
  labs(fill = "Vaccination Rate")+
  theme(
    legend.text = element_text(size = 15)
  )

shared_legend <- get_legend(dummy_plot2 + theme(legend.position = "right", 
                                                legend.box.margin = margin(0, 0, 0, 0),
                                                legend.margin     = margin(0, 0, 0, 0),
                                                plot.margin       = margin(0, 0, 0, 0)))
full_vax_map <- plot_grid(vax_map, shared_legend, ncol = 2, rel_widths = c(2, 1))

vaccination_rates <- read.csv("vaccination_rates.csv")
vaccination_rates <- pivot_longer(vaccination_rates, cols = c("United.States", "Mohave.County", "Washington.County", "Utah", "Arizona"), names_to = "Region")
vaccination_rates$Region <- factor(vaccination_rates$Region, levels = c("United.States", "Utah", "Arizona", "Washington.County", "Mohave.County"))

vax_plot <- ggplot(data = vaccination_rates, aes(x = School.Year, y = value, color = Region, group = Region)) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = 96.1, ymax = 97.8, 
           fill = "grey80", alpha = 0.3) +
  geom_hline(yintercept = c(96.1, 97.8), 
             linetype = "dashed", 
             color = "grey60", 
             size = 0.8)+
  geom_line(size = 2) +
  geom_line(size = 2) +
  geom_point(size = 4) + 
  theme_minimal() +
  scale_color_manual(
    name = "",
    labels = c("Washington.County" = "Washington County", "Mohave.County" = "Mohave County", "United.States" = "United States", "Utah" = "Utah", "Arizona" = "Arizona"), 
    values = c("Washington.County" = "#82B4DB", "Mohave.County" = "#ECA887", "United.States" = "#2D2D2D", "Utah" = "#2E5C8A", "Arizona" = "#B14A2B")
  ) +
  labs(x = "School Year", y = "% Students with 2+ MMR Doses") +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.line = element_line(color = "black"),
    axis.ticks = element_line(color = "black"),
    axis.text.x = element_text(angle = 35, vjust = 0.5),
    plot.title = element_text(size = 20, hjust = 0.5),
    axis.title = element_text(size = 20),
    axis.text = element_text(size = 15),
    legend.text = element_text(size = 15),
    legend.position = "bottom"
  )

plot_grid(full_vax_map, vax_plot, ncol = 2, rel_widths = c(1,1.5), labels = c("A", "B"))
