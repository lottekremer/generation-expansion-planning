library(readr)
library(ggplot2)
library(dplyr)
library(tidyr)
library(tidyverse)

source("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/theme.R")
df <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/2d/results/original.csv")

# Create factors
df$distance <- as.factor(df$distance)
df$clustering <- as.factor(df$clustering)
df$seed <- as.factor(df$seed)
df$data <- as.factor(df$data)

# Filter out stochastic without representatives
stochastic_output <- filter(df, clustering == "stochastic")
output <- filter(df, clustering != "stochastic")
rm(df)

# Calculate the regret and speedup
stochastic_output_summary <- stochastic_output %>%
  summarise(
    cost = first(cost),
    time = first(time),
    loss_ct = first(loss_ct)
  )
rm(stochastic_output)

output_with_seeds <- output %>%
  mutate(
    cost_increase = (cost - stochastic_output_summary$cost) / stochastic_output_summary$cost * 100,
    speedup = stochastic_output_summary$time / time,
    loss_ct_increase = loss_ct,
  )

# Summarize each entry for all seeds it was done with (take average of cost_increase and speedup) and calculate quantiles
output_final <- output_with_seeds %>%
  group_by(num_periods, distance, clustering) %>%
  summarise(
    cost_increase = median(cost_increase),
    speedup = median(speedup), 
    loss_ct_increase = median(loss_ct_increase),
    .groups = 'drop'
  )

output_quantiles_cost <- output_with_seeds %>%
  group_by(num_periods, distance, clustering) %>%
  summarise(
    q25 = quantile(cost_increase, 0.25),
    q75 = quantile(cost_increase, 0.75),
    mean_ci = median(cost_increase),
    .groups = 'drop'
  )

output_quantiles_loss <- output_with_seeds %>%
  group_by(num_periods, distance, clustering) %>%
  summarise(
    q25 = quantile(loss_ct_increase, 0.25),
    q75 = quantile(loss_ct_increase, 0.75),
    mean_ci = median(loss_ct_increase),
    .groups = 'drop'
  )

# Colours
options <- palette.colors(palette = "R4")

############### Plots relative regret ########################################
p <- ggplot(output_final, aes(x = num_periods, y = cost_increase, 
                              colour = clustering, fill = clustering, linetype = clustering)) +
    geom_line(linewidth = 0.4) +
    geom_point(size = 0.4) +
    labs(
      x = "Number of representative periods", 
      y = "Relative regret (%)", 
      title = "Relative regret for different number of representative periods - 2D example",
      color = "Clustering method",  
      linetype = "Clustering method",  
      fill = "Clustering method"  
    )+
    geom_ribbon(data = output_quantiles_cost,
                mapping = aes(x = num_periods, ymin = q25, ymax = q75, fill = clustering), 
                alpha = 0.2, inherit.aes = FALSE)+
    coord_cartesian(xlim = c(0, 100), 
                    ylim = c(0, 25)) + thesis_theme()  +
    facet_grid(rows = vars(distance),
               labeller = labeller(
                 distance = c("CosineDist" = "Cosine distance", "SqEuclidean" = "Squared euclidean"))) +
    scale_color_manual(values = my_colors, 
                       labels = my_labels) +
    scale_fill_manual(values = my_colors, 
                      labels = my_labels) +
    scale_linetype_manual(values = my_linetypes,
                          labels = my_labels) 
  
show(p)
save_plot(p, paste0('C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/2D/example_cost_25.pdf'), 0.4)

############### Plots loss ########################################
p <- ggplot(output_final, aes(x = num_periods, y = loss_ct_increase,
                              colour = clustering, fill = clustering, linetype = clustering)) +
  geom_line(linewidth = 0.4) +
  geom_point(size = 0.4) +
  labs(
    x = "Number of representative periods", 
    y = "Increase in timesteps with loss of load", 
    title = "Increase in timesteps with loss of load per number of representative periods - 2D example",
    color = "Clustering method",  
    linetype = "Clustering method",  
    fill = "Clustering method"  
  )+
  geom_ribbon(data = output_quantiles_loss,
              mapping = aes(x = num_periods, ymin = q25, ymax = q75, fill = clustering), 
              alpha = 0.2, inherit.aes = FALSE)+
  coord_cartesian(xlim = c(0, 100), 
                  ylim = c(0, 10)) + thesis_theme()  +
  facet_grid(rows = vars(distance),
             labeller = labeller(
               distance = c("CosineDist" = "Cosine distance", "SqEuclidean" = "Squared euclidean"))) +
  scale_color_manual(values = my_colors, 
                     labels = my_labels) +
  scale_fill_manual(values = my_colors, 
                    labels = my_labels) +
  scale_linetype_manual(values = my_linetypes,
                        labels = my_labels) 

show(p)
save_plot(p, paste0('C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/2D/example_loss.pdf'), 0.4)

############## data points circle #############################

initial_demand <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/2d/inputs/demand.csv")
initial_wind <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/2d/inputs/generation_availability.csv")

outer_demand <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/2d/inputs_outer/demand.csv")
outer_wind <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/2d/inputs_outer/generation_availability.csv")

outer_demand$demand <- outer_demand$demand / max(initial_demand$demand)
initial_demand$demand <- initial_demand$demand / max(initial_demand$demand)

initial <- left_join(initial_demand, initial_wind, by = c("period", "location", "timestep", "scenario"))
outer <- left_join(outer_demand, outer_wind, by = c("period", "location", "timestep", "scenario"))

################ Get representatives for visualization ################
output_essential <- output %>% select(-c(cost, time, loss_ct, weights)) %>% group_by(data, num_periods, distance, clustering) %>% slice(1) %>% ungroup() %>% select(-seed)
output_essential <- output_essential %>%
  mutate(
    demand = str_replace_all(demand, "\\[|\\]", ""),  # Remove square brackets
    wind = str_replace_all(wind, "\\[|\\]", ""),      
    
    demand = str_trim(demand),                        # Trim extra spaces
    wind = str_trim(wind),                            
    
    demand = str_split(demand, ",\\s*"),              # Split on commas (handling spaces)
    wind = str_split(wind, ",\\s*"),                  
    
    demand = map(demand, as.numeric),                 # Convert to numeric
    wind = map(wind, as.numeric)                     
  )

points_wide <-output_essential %>%
  unnest_longer(c(demand, wind)) %>%  # Expands demand and wind lists into rows
  group_by(data, num_periods, distance, clustering) %>%
  mutate(representative_period = row_number()) %>%  # Adds period index
  ungroup()

points_wide$demand <- points_wide$demand / max(points_wide$demand)

############################## Plots representatives ############################
x <- 3
p <- ggplot(initial, aes(x = availability, y = demand)) + geom_point(size = 0.5) + thesis_theme() +
  labs(
    x =  "Wind availability",
    y = "Demand (scaled)", 
    title = paste("Demand and wind availability with" ,x , "representative periods"),
    color = "Clustering method",
    shape = "Clustering method"
  ) +
  geom_point(data = points_wide %>% filter(num_periods == x, data == "output", distance == "SqEuclidean"), 
             aes(x = wind, y = demand, colour = clustering, shape = clustering), size = 3)  +
  scale_shape_manual(values = c(15, 16, 17, 18),
                     labels = my_labels) + 
  scale_color_manual(values = my_colors, 
                     labels = my_labels) + 
  facet_grid(cols = vars(clustering), labeller = labeller(clustering = my_labels))


show(p)
save_plot(p, paste0('C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/2D/example_3.pdf'), 0.3)

###################### For searching a specific point ##############

points_wide_specific <- points_wide %>% filter(num_periods == 60, representative_period %in% c(2, 10, 29), data == "output", distance == "CosineDist", clustering == "convex_hull")
#points_wide_specific <- points_wide %>% filter(num_periods ==60, representative_period == c(1,2,3,4,5), clustering == "conical_hull")

p <- ggplot(initial, aes(x = availability, y = demand)) + geom_point(size = 0.5) + thesis_theme() +
  labs(
    x =  "Wind availability",
    y = "Demand (scaled)", 
    title = paste("Specific representative periods for greedy convex hull and cosine distance"),
    color = "Clustering method",
    shape = "Clustering method"
  ) + 
  geom_point(data = points_wide_specific, aes(x = wind, y = demand), colour = my_colors[3], shape=15, size = 3) + 
  facet_grid(cols = vars(representative_period)) + 
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1.5))

show(p)
save_plot(p, paste0('C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/2D/example_upper.pdf'), 0.4)
