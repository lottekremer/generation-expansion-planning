library(readr)
library(ggplot2)
library(dplyr)
library(tidyr)
library(tidyverse)
library(RColorBrewer)

source("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/theme.R")

df_triangle <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/2d/results/blended.csv")
df_triangle <- df_triangle %>% filter(clustering != "convex_hull")

df_original <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/2d/results/original.csv")
df_original$take <- 0

df <- rbind(df_triangle, df_original)

# Create factors
df$distance <- as.factor(df$distance)
df$clustering <- as.factor(df$clustering)
df$seed <- as.factor(df$seed)
df$take <- as.factor(df$take)

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
  group_by(data, num_periods, distance, clustering, take) %>%
  summarise(
    cost_increase = median(cost_increase),
    speedup = median(speedup), 
    loss_ct_increase = median(loss_ct_increase),
    .groups = 'drop'
  )

output_quantiles_cost <- output_with_seeds %>%
  group_by(data, num_periods, distance, clustering, take) %>%
  summarise(
    q25 = quantile(cost_increase, 0.25),
    q75 = quantile(cost_increase, 0.75),
    mean_ci = median(cost_increase),
    .groups = 'drop'
  )

output_quantiles_loss <- output_with_seeds %>%
  group_by(data, num_periods, distance, clustering, take) %>%
  summarise(
    q25 = quantile(loss_ct_increase, 0.25),
    q75 = quantile(loss_ct_increase, 0.75),
    mean_ci = median(loss_ct_increase),
    .groups = 'drop'
  )


############### Plots loss ########################################
p <- ggplot(output_final, aes(x = num_periods, y = loss_ct_increase)) +
  geom_line(linewidth = 0.4) +
  geom_point(size = 0.4) +
  labs(
    x = "Number of Representative Periods", 
    y = "Timesteps with increase Loss of Load", 
    title = "Increase in timesteps with Loss of Loads per number of Representative Periods - 2D example"
  ) +
  geom_ribbon(data = output_quantiles_loss,
              mapping = aes(x = num_periods, ymin = q25, ymax = q75), 
              alpha = 0.2, inherit.aes = FALSE) +
  coord_cartesian(xlim = c(0, 100), 
                  ylim = c(0, 10)) + thesis_theme()  +
  facet_grid(rows = vars(distance),
             labeller = labeller(
               distance = c("CosineDist" = "Cosine Distance", "SqEuclidean" = "Squared Euclidean"))) 

show(p)

loss_table <- output_final %>%
  group_by(distance, num_periods) %>%
  summarise(
    mean_loss = mean(loss_ct_increase),
    .groups = 'drop'
  )

############## data points circle #############################

initial_demand <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/2d/inputs/demand.csv")
initial_wind <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/2d/inputs/generation_availability.csv")

outer_demand <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/2d/inputs_outer/demand.csv")
outer_wind <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/2d/inputs_outer/generation_availability.csv")

maxi <- max(initial_demand$demand)
outer_demand$demand <- outer_demand$demand / maxi
initial_demand$demand <- initial_demand$demand / maxi

initial <- left_join(initial_demand, initial_wind, by = c("period", "location", "timestep", "scenario"))
initial$wind <- initial$availability
outer <- left_join(outer_demand, outer_wind, by = c("period", "location", "timestep", "scenario"))
outer$wind <- outer$availability

################ Get representatives for visualization ################
output_essential <- output %>% select(-c(cost, time, loss_ct, weights)) %>% group_by(data, num_periods, distance, clustering, take) %>% slice(1) %>% ungroup() %>% select(-seed)
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
  group_by(data, num_periods, distance, clustering, take) %>%
  mutate(representative_period = row_number()) %>%  # Adds period index
  ungroup()

points_wide$demand <- points_wide$demand / maxi

######################## TEST ##################################################

takes <- c(0, 6, 11, 16, 21, 26, 31, 36, 41, 46, 51, 56, 61)


# Renumber based on matching position
output_takes <- output_final %>% filter(take %in% takes) %>%
  mutate(
    take = match(take, takes) - 1
  ) 

output_takes <- output_takes %>%
  mutate(
    take_label = case_when(
      take == 0 & clustering == "k_means" ~ "K-means",
      take == 0 & clustering == "k_medoids" ~ "K-medoids",
      TRUE ~ paste0("Triangle ", take)
    )
  )

# Base clustering colors
ref_labels <- c("k_means" = "K-means", "k_medoids" = "K-medoids")

# Palette for take != 0
distinct_takes <- output_takes %>%
  filter(!take_label %in% ref_labels) %>%
  distinct(take, take_label) %>%
  arrange(take)  

legend_levels <- c("K-means", "K-medoids", distinct_takes$take_label)

output_takes <- output_takes  %>%
  mutate(take_label = factor(take_label, levels = legend_levels))

take_palette <- setNames(
  colorRampPalette(brewer.pal(9, "Blues"))(nrow(distinct_takes)),
  distinct_takes$take_label
)

# Add Reference colors
ref_palette <- setNames(my_colors[names(ref_labels)], ref_labels)

# Combine all palettes
full_palette <- c(take_palette, ref_palette)

# Plot
p <- ggplot(output_takes %>% filter(clustering %in% c("k_means", "k_medoids")),
            aes(x = num_periods, y = cost_increase, group = take, color = take_label)) +
  geom_ribbon(data = output_quantiles_cost %>%
                filter(data == "output", clustering %in% c("k_means", "k_medoids")),
              mapping = aes(x = num_periods, ymin = q25, ymax = q75, fill = clustering),
              alpha = 0.2, inherit.aes = FALSE) +
  geom_line(linewidth = 0.05) +
  geom_point(size = 0.05) +
  scale_colour_manual(values = full_palette, name = "Clustering method") +
  scale_fill_manual(values = my_colors) +
  labs(
    x = "Number of representative periods", 
    y = "Relative regret (%)", 
    title = "Relative regret for different number of representative periods - 2D example",
    legend = "Method"
  ) +
  coord_cartesian(xlim = c(0, 100), ylim = c(0, 25)) +
  thesis_theme() +
  facet_grid(rows = vars(distance), cols = vars(clustering),
             labeller = labeller(
               distance = c("CosineDist" = "Cosine distance", "SqEuclidean" = "Squared euclidean"),
               clustering = c("k_means" = "K-means", "k_medoids" = "K-medoids")
             )) +
  guides(fill = "none")


show(p)

save_plot(p, paste0('C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/2D/example_blended.pdf'), 0.6)

