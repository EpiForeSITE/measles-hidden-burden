# Figure 3

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

barplot <- ggplot() +
  geom_bar(data = case_data_combined_weekly, aes(x = Date, y = Cases, fill = State), stat = "identity", position = "dodge") +
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
    legend.title = element_text(size = 15),
    legend.position = "none")+
  scale_x_date(date_breaks = "1 month", date_labels = "%b %Y",
               limits = c(as.Date("2025-05-01"), as.Date("2026-02-28")))+
  scale_fill_manual(values = c("SW" = "mediumpurple4", "notSW" = "coral"))

tree <- read.beast("beast_tree.tree")
load("SW_or_Not.RData")
valid_labels <- SW_or_Not$UPHL_lab_accession[SW_or_Not$UPHL_lab_accession %in% tree@phylo[["tip.label"]]]
tree <- tidytree::keep.tip(tree, valid_labels)

tree_viz <- ggtree(tree, mrsd = "2026-02-28")+theme_tree2()

tree_data <- tree_viz$data

tree_data_joined <- tree_data %>%
  left_join(SW_or_Not, by = c("label" = "UPHL_lab_accession"))
tree_data_joined$x <- decimal2Date(tree_data_joined$x)
tree_viz$data <- tree_data_joined


tree_viz2 <- tree_viz + geom_tippoint(aes(color = SWorNOT), size = 3)+
  scale_color_manual(values = c("SW" = "mediumpurple4", "NotSW" = "coral"), labels = c("SW" = "Inside Community", "NotSW" = "Outside Community"))+
  labs(color = "Region")+
  scale_y_continuous(expand = expansion(mult = c(0.1, 0.05)))+
  scale_x_date(date_breaks = "1 month", date_labels = "%b %Y")+
  coord_cartesian(xlim = c(as.Date("2025-05-01"), as.Date("2026-02-28")))+
  theme(
    legend.position = c(0, 0.90),          
    legend.justification = c("left", "top"), 
    legend.background = element_blank(),
    legend.title = element_text(size = 15),
    legend.text = element_text(size = 10),
    plot.margin = margin(t = 10, r = 10, b = 10, l = 50),
    axis.text.x = element_blank()
  )

plot_grid(tree_viz2, barplot, ncol = 1, nrow = 2, labels = c("A", "B"))
