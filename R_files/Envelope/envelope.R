library(readr)
library(ggplot2)
library(dplyr)

source("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/theme.R")
insample <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/optimality/results/insample_distribution.csv")
outsample <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/optimality/results/outsample_distribution.csv")
envelope_one <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/optimality/results/envelope_experiment.csv")
envelope_two <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/optimality/results/envelope_experiment_two.csv")

envelope_one$num_periods <- envelope_one$num_periods + 4
envelope_two$num_periods <- envelope_two$num_periods + 1

# Bundling insample and outsample data
insample$type <- "insample"
outsample$type <- "outsample"
envelope_one$type <- "insample"
envelope_two$type <- "insample"
combined_output <- rbind(insample, outsample, envelope_one, envelope_two)

# Create factors
combined_output$method <- as.factor(combined_output$method)
combined_output$distance <- as.factor(combined_output$distance)
combined_output$clustering <- as.factor(combined_output$clustering)

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
  group_by(data, num_periods, distance, clustering, type) %>%
  summarise(
    cost_increase = median(cost_increase),
    speedup = median(speedup), 
    loss_ct_increase = median(loss_ct_increase),
    loss_increase = median(loss_increase),
    .groups = 'drop'
  )

output_quantiles_cost <- output_with_seeds %>%
  group_by(data, num_periods, distance, clustering, type) %>%
  summarise(
    q25 = quantile(cost_increase, 0.25),
    q75 = quantile(cost_increase, 0.75),
    mean_ci = mean(cost_increase),
    .groups = 'drop'
  )

output_quantiles_loss <- output_with_seeds %>%
  group_by(data, num_periods, distance, clustering, type) %>%
  summarise(
    q25 = quantile(loss_ct_increase, 0.25),
    q75 = quantile(loss_ct_increase, 0.75),
    mean_ci = mean(loss_ct_increase),
    .groups = 'drop'
  )

options <- palette.colors(palette = "R4")

# This set of experiments is currenlty only done on closemixed data

cat_names <- c("softmax" = "Convex", "centered" = "Centered cluster", 
               "closemixed" = "Separate clusters without spatial correlation",
               "close" = "Separate clusters with spatial correlation")
categories <- c("closemixed")

############### Plots relative regret ########################################
for (cat in categories) {
  p <- ggplot(output_final %>% filter(data == cat, type == "insample"), aes(x = num_periods, y = cost_increase, 
                                                        colour = clustering, fill = clustering, linetype = clustering)) +
    geom_line(linewidth = 0.4) +
    geom_point(size = 0.4) +
    labs(
      x = "Number of Representative Periods", 
      y = "Relative regret (%)", 
      title = paste("Relative regret for different number of Representative Periods - ", cat_names[cat]),
      color = "Clustering Method",  
      linetype = "Clustering Method",  
      fill = "Clustering Method"  
    )+
    geom_ribbon(data = output_quantiles_cost %>% filter(data == cat, type == "insample"),
                mapping = aes(x = num_periods, ymin = q25, ymax = q75, fill = clustering), 
                alpha = 0.2, inherit.aes = FALSE)+
    coord_cartesian(xlim = c(3, 41), 
                    ylim = c(0, 150)) + thesis_theme()  +
    facet_grid(rows = vars(distance),
               labeller = labeller(
                 distance = c("CosineDist" = "Cosine Distance", "SqEuclidean" = "Squared Euclidean")
                 )) +
    scale_color_manual(values = my_colors, 
                       labels = c("convex_hull" = "Convex Hull", 
                                  "k_means" = "K-means", 
                                  "k_medoids" = "K-medoids",
                                  "convex_hull_envelope" = "Convex hull with 4 added extremes",
                                  "convex_hull_envelope_two" = "Convex Hull with 1 added extreme")) +
    
    scale_fill_manual(values = my_colors, 
                      labels = c("convex_hull" = "Convex Hull", 
                                 "k_means" = "K-means", 
                                 "k_medoids" = "K-medoids",
                                 "convex_hull_envelope" = "Convex hull with 4 added extremes",
                                "convex_hull_envelope_two" = "Convex Hull with 1 added extreme")) +
    scale_linetype_manual(values = c("convex_hull" = "solid", 
                                     "k_means" = "dashed", 
                                     "k_medoids" = "dotted",
                                     "convex_hull_envelope" = "dotdash",
                                     "convex_hull_envelope_two" = "longdash"),
                          labels = c("convex_hull" = "Convex Hull", 
                                     "k_means" = "K-means", 
                                     "k_medoids" = "K-medoids", 
                                     "convex_hull_envelope" = "Convex hull with 4 added extremes",
                          "convex_hull_envelope_two" = "Convex Hull with 1 added extreme"))
  
  show(p)
  save_plot(p, paste0('C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/envelope/', cat, '_cost.pdf'), 0.4)}

############### Plots relative regret zoomed ########################################
for (cat in categories) {
  p <- ggplot(output_final %>% filter(data == cat, type == "insample"), aes(x = num_periods, y = cost_increase, 
                                                                            colour = clustering, fill = clustering, linetype = clustering)) +
    geom_line(linewidth = 0.4) +
    geom_point(size = 0.4) +
    labs(
      x = "Number of Representative Periods", 
      y = "Relative regret (%)", 
      title = paste("Relative regret for different number of Representative Periods - ", cat_names[cat]),
      color = "Clustering Method",  
      linetype = "Clustering Method",  
      fill = "Clustering Method"  
    )+
    geom_ribbon(data = output_quantiles_cost %>% filter(data == cat, type == "insample"),
                mapping = aes(x = num_periods, ymin = q25, ymax = q75, fill = clustering), 
                alpha = 0.2, inherit.aes = FALSE)+
    coord_cartesian(xlim = c(3, 41), 
                    ylim = c(0, 50)) + thesis_theme()  +
    facet_grid(rows = vars(distance),
               labeller = labeller(
                 distance = c("CosineDist" = "Cosine Distance", "SqEuclidean" = "Squared Euclidean")
               )) +
    scale_color_manual(values = my_colors, 
                       labels = c("convex_hull" = "Convex Hull", 
                                  "k_means" = "K-means", 
                                  "k_medoids" = "K-medoids",
                                  "convex_hull_envelope" = "Convex hull with 4 added extremes",
                                  "convex_hull_envelope_two" = "Convex Hull with 1 added extreme")) +
    
    scale_fill_manual(values = my_colors, 
                      labels = c("convex_hull" = "Convex Hull", 
                                 "k_means" = "K-means", 
                                 "k_medoids" = "K-medoids",
                                 "convex_hull_envelope" = "Convex hull with 4 added extremes",
                                 "convex_hull_envelope_two" = "Convex Hull with 1 added extreme")) +
    scale_linetype_manual(values = c("convex_hull" = "solid", 
                                     "k_means" = "dashed", 
                                     "k_medoids" = "dotted",
                                     "convex_hull_envelope" = "dotdash",
                                     "convex_hull_envelope_two" = "longdash"),
                          labels = c("convex_hull" = "Convex Hull", 
                                     "k_means" = "K-means", 
                                     "k_medoids" = "K-medoids", 
                                     "convex_hull_envelope" = "Convex hull with 4 added extremes",
                                     "convex_hull_envelope_two" = "Convex Hull with 1 added extreme"))
  
  show(p)
  save_plot(p, paste0('C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/envelope/', cat, 'zoomed_cost.pdf'), 0.4)}

############### Plots loss ########################################
for (cat in categories) {
  p <- ggplot(output_final %>% filter(data == cat, type == "insample"), aes(x = num_periods, y = loss_ct_increase, 
                                                                            colour = clustering, fill = clustering, linetype = clustering)) +
    geom_line(linewidth = 0.4) +
    geom_point(size = 0.4) +
    labs(
      x = "Number of Representative Periods", 
      y = "Increase of time steps with loss of load", 
      title = paste("Increase in loss of load for different number of Representative Periods - ", cat_names[cat]),
      color = "Clustering Method",  
      linetype = "Clustering Method",  
      fill = "Clustering Method"  
    )+
    geom_ribbon(data = output_quantiles_loss %>% filter(data == cat, type == "insample"),
                mapping = aes(x = num_periods, ymin = q25, ymax = q75, fill = clustering), 
                alpha = 0.2, inherit.aes = FALSE)+
    coord_cartesian(xlim = c(3, 41), 
                    ylim = c(0, 500)) + thesis_theme()  +
    facet_grid(rows = vars(distance),
               labeller = labeller(
                 distance = c("CosineDist" = "Cosine Distance", "SqEuclidean" = "Squared Euclidean")
               )) +
    scale_color_manual(values = my_colors, 
                       labels = c("convex_hull" = "Convex Hull", 
                                  "k_means" = "K-means", 
                                  "k_medoids" = "K-medoids",
                                  "convex_hull_envelope" = "Convex hull with 4 added extremes",
                                  "convex_hull_envelope_two" = "Convex Hull with 1 added extreme")) +
    
    scale_fill_manual(values = my_colors, 
                      labels = c("convex_hull" = "Convex Hull", 
                                 "k_means" = "K-means", 
                                 "k_medoids" = "K-medoids",
                                 "convex_hull_envelope" = "Convex hull with 4 added extremes",
                                 "convex_hull_envelope_two" = "Convex Hull with 1 added extreme")) +
    scale_linetype_manual(values = c("convex_hull" = "solid", 
                                     "k_means" = "dashed", 
                                     "k_medoids" = "dotted",
                                     "convex_hull_envelope" = "dotdash",
                                     "convex_hull_envelope_two" = "longdash"),
                          labels = c("convex_hull" = "Convex Hull", 
                                     "k_means" = "K-means", 
                                     "k_medoids" = "K-medoids", 
                                     "convex_hull_envelope" = "Convex hull with 4 added extremes",
                                     "convex_hull_envelope_two" = "Convex Hull with 1 added extreme"))
  
  show(p)
  save_plot(p, paste0('C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/envelope/', cat, 'loss.pdf'), 0.4)}


############ Table ############
output_table <- output_final %>% filter(distance == "CosineDist") %>% select(data, num_periods, clustering, cost_increase, loss_ct_increase, type) %>% 
  filter(num_periods %in% c(3,5,7,9,11)) %>% filter(data == "softmax")

