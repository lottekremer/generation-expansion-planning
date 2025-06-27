library(readr)
library(ggplot2)
library(dplyr)

source("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/theme.R")
combined_output <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/distribution/results/closemixed_results.csv")

# Create factors
combined_output$method <- as.factor(combined_output$method)
combined_output$distance <- as.factor(combined_output$distance)
combined_output$clustering <- as.factor(combined_output$clustering)
combined_output$type <- as.factor(combined_output$type)
combined_output$extreme <- as.factor(combined_output$extreme)

# Filter out stochastic version without representatives
stochastic_output <- filter(combined_output, method == "stochastic")
output <- filter(combined_output, method != "stochastic")

# Calculate the regret and speedup
stochastic_output_summary <- stochastic_output %>%
  group_by(data, type) %>%
  summarise(
    cost = first(cost),
    time = first(time),
    loss_ct = first(loss_ct),
    loss = first(loss),
    .groups = 'drop'
  )

output_with_seeds <- output %>%
  left_join(stochastic_output_summary, by = c("data", "type")) %>%
  mutate(
    cost_increase = pmax(0,(cost.x - cost.y) / cost.y * 100),
    speedup = time.y / time.x,
    loss_ct_increase = loss_ct.x - loss_ct.y,
    loss_increase = (loss.x - loss.y) / loss.y * 100
  ) %>%
  rename(
    cost = cost.x,  
    time = time.x
  ) %>%
  select(-cost.y, -time.y,-loss_ct.y, -loss_ct.x, - loss.x, loss.y)

# Summarize each entry for all seeds it was done with (take average of cost_increase and speedup) and calculate quantiles
output_final <- output_with_seeds %>%
  group_by(data, num_periods, distance, clustering, type, extreme) %>%
  summarise(
    cost_increase = median(cost_increase),
    speedup = median(speedup), 
    loss_ct_increase = median(loss_ct_increase),
    loss_increase = median(loss_increase),
    .groups = 'drop'
  )

output_quantiles_cost <- output_with_seeds %>%
  group_by(data, num_periods, distance, clustering, type, extreme) %>%
  summarise(
    q25 = quantile(cost_increase, 0.25),
    q75 = quantile(cost_increase, 0.75),
    mean_ci = mean(cost_increase),
    .groups = 'drop'
  )

output_quantiles_loss <- output_with_seeds %>%
  group_by(data, num_periods, distance, clustering, type, extreme) %>%
  summarise(
    q25 = quantile(loss_ct_increase, 0.25),
    q75 = quantile(loss_ct_increase, 0.75),
    mean_ci = mean(loss_ct_increase),
    .groups = 'drop'
  )

# Colours and categories
options <- palette.colors(palette = "R4")
cat_names <- c("softmax" = "Convex", "centered" = "Centered cluster", 
               "closemixed" = "Separate clusters without spatial correlation",
               "close" = "Separate clusters with spatial correlation")

cat <- "closemixed"

############### Plots relative regret ########################################
expand_none_rows <- function(data, extreme_value) {
  clusters <- unique(data$clustering[data$extreme == extreme_value])
  none_rows <- data %>% filter(extreme == "none")
  non_none_rows <- data %>% filter(extreme != "none")
  
  none_expanded <- lapply(clusters, function(clust) {
    none_rows %>% mutate(facet_clustering = clust)
  }) %>% bind_rows()
  
  bind_rows(
    non_none_rows %>% mutate(facet_clustering = clustering),
    none_expanded
  ) %>%
    mutate(color_group = ifelse(extreme == extreme_value, extreme_value, as.character(clustering)))
}

output_final_extended <- expand_none_rows(output_final, "extreme1") %>%
  mutate(color_group = ifelse(extreme == "blended", "blended", color_group))

quantile_expanded <- expand_none_rows(output_quantiles_cost, "extreme1") %>%
  mutate(color_group = ifelse(extreme == "blended", "blended", color_group))

quantile_loss_expanded <- expand_none_rows(output_quantiles_loss, "extreme1") %>%
  mutate(color_group = ifelse(extreme == "blended", "blended", color_group))

# Final plot
p <- ggplot(
  output_final_extended %>%
    filter(extreme != "extreme4", extreme != "blended", type == "insample", facet_clustering != "conical_hull"),
  aes(x = num_periods, y = cost_increase,
      colour = color_group, fill = color_group, linetype = color_group)) +
  geom_line(linewidth = 0.1) +
  geom_point(size = 0.1) +
  geom_ribbon(
    data = quantile_expanded %>%
      filter(extreme != "extreme4", extreme != "blended", type == "insample", facet_clustering != "conical_hull"),
    aes(x = num_periods, ymin = q25, ymax = q75, fill = color_group),
    alpha = 0.2,
    inherit.aes = FALSE
  ) +
  labs(
    x = "Number of representative periods",
    y = "Relative regret (%)",
    title = paste("Relative regret for different number of representative periods - ", cat_names[cat]),
    color = "Clustering method",
    fill = "Clustering method",
    linetype = "Clustering method"
  ) +
  coord_cartesian(xlim = c(3, 41), ylim = c(0, 150)) +
  facet_grid(
    rows = vars(distance), cols = vars(facet_clustering),
    labeller = labeller(
      distance = c("CosineDist" = "Cosine distance", "SqEuclidean" = "Squared euclidean"),
      facet_clustering = c("k_means" = "K-means", "k_medoids" = "K-medoids", "convex_hull" = "Greedy convex hull")
    )
  ) +
  scale_color_manual(values = my_colors, labels = my_labels) +
  scale_fill_manual(values = my_colors, labels = my_labels) +
  scale_linetype_manual(values = my_linetypes, labels = my_labels) +
  thesis_theme()

show(p)

save_plot(p, 'C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/Distribution/extreme_cost.pdf', 0.40)

# Final plot
p <- ggplot(
  output_final_extended %>%
    filter(extreme != "extreme4", type == "insample", facet_clustering != "conical_hull"),
  aes(x = num_periods, y = cost_increase,
      colour = color_group, fill = color_group, linetype = color_group)) +
  geom_line(linewidth = 0.1) +
  geom_point(size = 0.1) +
  geom_ribbon(
    data = quantile_expanded %>%
      filter(extreme != "extreme4", type == "insample", facet_clustering != "conical_hull"),
    aes(x = num_periods, ymin = q25, ymax = q75, fill = color_group),
    alpha = 0.2,
    inherit.aes = FALSE
  ) +
  labs(
    x = "Number of representative periods",
    y = "Relative regret (%)",
    title = paste("Relative regret for different number of representative periods - ", cat_names[cat]),
    color = "Clustering method",
    fill = "Clustering method",
    linetype = "Clustering method"
  ) +
  coord_cartesian(xlim = c(3, 41), ylim = c(0, 10)) +
  facet_grid(
    rows = vars(distance), cols = vars(facet_clustering),
    labeller = labeller(
      distance = c("CosineDist" = "Cosine distance", "SqEuclidean" = "Squared euclidean"),
      facet_clustering = c("k_means" = "K-means", "k_medoids" = "K-medoids", "convex_hull" = "Greedy convex hull")
    )
  ) +
  scale_color_manual(values = my_colors, labels = my_labels) +
  scale_fill_manual(values = my_colors, labels = my_labels) +
  scale_linetype_manual(values = my_linetypes, labels = my_labels) +
  thesis_theme()

show(p)

save_plot(p, 'C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/Distribution/extreme_cost_blended.pdf', 0.45)

# Final plot
p <- ggplot(
  output_final_extended %>%
    filter(extreme != "extreme4", type == "insample", facet_clustering != "conical_hull"),
  aes(x = num_periods, y = loss_ct_increase,
      colour = color_group, fill = color_group, linetype = color_group)) +
  geom_line(linewidth = 0.1) +
  geom_point(size = 0.1) +
  geom_ribbon(
    data = quantile_loss_expanded %>%
      filter(extreme != "extreme4", type == "insample", facet_clustering != "conical_hull"),
    aes(x = num_periods, ymin = q25, ymax = q75, fill = color_group),
    alpha = 0.2,
    inherit.aes = FALSE
  ) +
  labs(
    x = "Number of Representative Periods",
    y = "Increase in time steps with Loss of Load",
    title = paste("Additional time steps with LoL per number of representative periods - ", cat_names[cat]),
    color = "Clustering method",
    fill = "Clustering method",
    linetype = "Clustering method"
  ) +
  coord_cartesian(xlim = c(3, 41), ylim = c(-20, 200)) +
  facet_grid(
    rows = vars(distance), cols = vars(facet_clustering),
    labeller = labeller(
      distance = c("CosineDist" = "Cosine distance", "SqEuclidean" = "Squared euclidean"),
      facet_clustering = c("k_means" = "K-means", "k_medoids" = "K-medoids", "convex_hull" = "Greedy convex hull")
    )
  ) +
  scale_color_manual(values = my_colors, labels = my_labels) +
  scale_fill_manual(values = my_colors, labels = my_labels) +
  scale_linetype_manual(values = my_linetypes, labels = my_labels) +
  thesis_theme()

show(p)

save_plot(p, 'C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/Distribution/extreme_loss_blended.pdf', 0.45)

################### ONLY BLENDED AND EXTREME #################################
p <- ggplot(
  output_final_extended %>%
    filter(extreme != "extreme4", type == "insample", facet_clustering != "conical_hull"),
  aes(x = num_periods, y = cost_increase,
      colour = color_group, fill = color_group, linetype = color_group)) +
  geom_line(linewidth = 0.1) +
  geom_point(size = 0.1) +
  geom_ribbon(
    data = quantile_expanded %>%
      filter(extreme != "extreme4", type == "insample", facet_clustering != "conical_hull"),
    aes(x = num_periods, ymin = q25, ymax = q75, fill = color_group),
    alpha = 0.2,
    inherit.aes = FALSE
  ) +
  labs(
    x = "Number of Representative Periods",
    y = "Relative regret (%)",
    title = paste("Relative regret for different number of Representative Periods - ", cat_names[cat]),
    color = "Clustering Method",
    fill = "Clustering Method",
    linetype = "Clustering Method"
  ) +
  coord_cartesian(xlim = c(3, 41), ylim = c(0, 10)) +
  facet_grid(
    rows = vars(distance), cols = vars(facet_clustering),
    labeller = labeller(
      distance = c("CosineDist" = "Cosine Distance", "SqEuclidean" = "Squared Euclidean"),
      facet_clustering = c("k_means" = "K-means", "k_medoids" = "K-medoids", "convex_hull" = "Greedy Convex Hull")
    )
  ) +
  scale_color_manual(values = my_colors, labels = my_labels) +
  scale_fill_manual(values = my_colors, labels = my_labels) +
  scale_linetype_manual(values = my_linetypes, labels = my_labels) +
  thesis_theme()

show(p)
