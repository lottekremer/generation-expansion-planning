library(readr)
library(ggplot2)
library(dplyr)
library(tidyr)
library(tidyverse)

source("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/theme.R")
df <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/2d/results/new.csv")
df_test <- filter(df, num_periods == 3)

blended <- read.csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/2d/results/blended.csv")
df <- rbind(df, blended)
blended2 <- read.csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/2d/results/blended2.csv")
df <- rbind(df, blended2)

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

# Colours
options <- palette.colors(palette = "R4")

############### Plots relative regret boxplot ########################################
p <- ggplot(output_with_seeds %>% filter(num_periods == 3), aes(y = cost_increase)) + geom_boxplot() +
  labs(
    x = "Number of Representative Periods", 
    y = "Relative regret (%)", 
    title = "Relative regret for different number of Representative Periods - 2D example"
  ) + thesis_theme()

show(p)

############### Plots relative regret ########################################
p <- ggplot(output_final %>% filter(take == 1), aes(x = num_periods, y = cost_increase, colour = clustering)) +
  geom_line(linewidth = 0.4, show.legend = FALSE) +
  geom_point(size = 0.4, show.legend = FALSE) +
  labs(
    x = "Number of Representative Periods", 
    y = "Relative regret (%)", 
    title = "Relative regret for different number of Representative Periods - 2D example"
  ) +
  geom_ribbon(data = output_quantiles_cost,
              mapping = aes(x = num_periods, ymin = q25, ymax = q75), 
              alpha = 0.2, inherit.aes = FALSE) +
  coord_cartesian(xlim = c(0, 100), 
                  ylim = c(0, 50)) + thesis_theme()  +
  facet_grid(rows = vars(distance),
             labeller = labeller(
               distance = c("CosineDist" = "Cosine Distance", "SqEuclidean" = "Squared Euclidean")))

show(p)

output_final <- output_final %>%
  mutate(
    take = as.factor(take)
  )
########## Plots relative regret with others per take ################
p <- ggplot(output_final %>% filter(take %in% c(45,46,47,48,49,50,51,52,53,54,55,56,57)), aes(x = num_periods, y = cost_increase, 
                              colour = take, linetype = take)) +
  geom_line(linewidth = 0.4) +
  geom_point(size = 0.4) +
  labs(
    x = "Number of Representative Periods", 
    y = "Relative regret (%)", 
    title = "Relative regret for different number of Representative Periods - 2D example",
    color = "Clustering Method",  
    linetype = "Clustering Method",  
    fill = "Clustering Method"  
  )+
  coord_cartesian(xlim = c(0, 100), 
                  ylim = c(0, 25)) + thesis_theme()  +
  facet_grid(rows = vars(clustering), cols = vars(distance))

show(p)
save_plot(p, paste0('C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/2D/example_cost_blended2.pdf'), 0.7)


########## Plots relative regret with others ################
p <- ggplot(output_final, aes(x = num_periods, y = cost_increase, 
                              colour = clustering, fill = clustering, linetype = clustering)) +
  geom_line(linewidth = 0.4) +
  geom_point(size = 0.4) +
  labs(
    x = "Number of Representative Periods", 
    y = "Relative regret (%)", 
    title = "Relative regret for different number of Representative Periods - 2D example",
    color = "Clustering Method",  
    linetype = "Clustering Method",  
    fill = "Clustering Method"  
  )+ facet_grid(cols = vars(data),
                labeller = labeller(
                  data = c("blend" = "Blended", "blend2" = "Blended 2", "new" = "No blending")))+
  geom_ribbon(data = output_quantiles_cost,
              mapping = aes(x = num_periods, ymin = q25, ymax = q75, fill = clustering), 
              alpha = 0.2, inherit.aes = FALSE)+
  coord_cartesian(xlim = c(0, 100), 
                  ylim = c(0, 25)) + thesis_theme()  +
  facet_grid(rows = vars(distance), cols = vars(data),
             labeller = labeller(data = c("blend" = "Blended", "blend2" = "Blended 2", "new" = "No blending") ,
                                 distance = c("CosineDist" = "Cosine Distance", "SqEuclidean" = "Squared Euclidean"))) +
  scale_color_manual(values = my_colors, 
                     labels = c("convex_hull" = "Triangle + Greedy Convex Hull", 
                                "k_means" = "Triangle + K-means", 
                                "k_medoids" = "Triangle + K-medoids")) +
  scale_fill_manual(values = my_colors, 
                    labels = c("convex_hull" = "Triangle + Greedy Convex Hull", 
                               "k_means" = "Triangle + K-means", 
                               "k_medoids" = "Triangle + K-medoids")) +
  scale_linetype_manual(values = c("convex_hull" = "solid", 
                                   "k_means" = "dashed", 
                                   "k_medoids" = "dotted"),
                        labels = c("convex_hull" = "Triangle + Greedy Convex Hull", 
                                   "k_means" = "Triangle + K-means", 
                                   "k_medoids" = "Triangle + K-medoids")) 

show(p)
save_plot(p, paste0('C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/2D/example_cost_blended2.pdf'), 0.7)

########## Plots relative regret with blended ################
p <- ggplot(output_final %>% filter(data == "blend"), aes(x = num_periods, y = cost_increase, 
                                                          colour = clustering, fill = clustering, linetype = clustering)) +
  geom_line(linewidth = 0.4) +
  geom_point(size = 0.4) +
  labs(
    x = "Number of Representative Periods", 
    y = "Relative regret (%)", 
    title = "Relative regret for different number of Representative Periods - 2D example",
    color = "Clustering Method",  
    linetype = "Clustering Method",  
    fill = "Clustering Method"  
  )+
  geom_ribbon(data = output_quantiles_cost %>% filter(data == "blend"),
              mapping = aes(x = num_periods, ymin = q25, ymax = q75, fill = clustering), 
              alpha = 0.2, inherit.aes = FALSE)+
  coord_cartesian(xlim = c(0, 100), 
                  ylim = c(0, 25)) + thesis_theme()  +
  facet_grid(rows = vars(distance),
             labeller = labeller(
               distance = c("CosineDist" = "Cosine Distance", "SqEuclidean" = "Squared Euclidean"))) +
  scale_color_manual(values = my_colors, 
                     labels = c("convex_hull" = "Triangle + Blended + Greedy Convex Hull", 
                                "k_means" = "Triangle + Blended + K-means", 
                                "k_medoids" = "Triangle + Blended + K-medoids")) +
  scale_fill_manual(values = my_colors, 
                    labels = c("convex_hull" = "Triangle + Blended + Greedy Convex Hull", 
                               "k_means" = "Triangle + Blended + K-means", 
                               "k_medoids" = "Triangle + Blended + K-medoids")) +
  scale_linetype_manual(values = c("convex_hull" = "solid", 
                                   "k_means" = "dashed", 
                                   "k_medoids" = "dotted"),
                        labels = c("convex_hull" = "Triangle + Blended + Greedy Convex Hull", 
                                   "k_means" = "Triangle + Blended + K-means", 
                                   "k_medoids" = "Triangle + Blended + K-medoids")) 

show(p)
save_plot(p, paste0('C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/2D/example_cost_blended_25.pdf'), 0.4)


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
outer <- left_join(outer_demand, outer_wind, by = c("period", "location", "timestep", "scenario"))

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

############################## Plots representatives ############################
x <- 4
p <- ggplot(initial, aes(x = availability, y = demand)) + geom_point(size = 0.5) + thesis_theme() +
  labs(
    x =  "Wind availability",
    y = "Demand (scaled)", 
    title = paste("Demand and wind availability with" ,x , "representative periods")
  ) +
  facet_grid(cols = vars(distance)) + 
  geom_point(data = points_wide %>% filter(num_periods == x, take == 1), 
             aes(x = wind, y = demand), size = 3) +
  geom_point(data = outer, aes(x = availability, y = demand), size = 0.5, colour = "grey")

show(p)
save_plot(p, paste0('C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/2D/example_3.pdf'), 0.4)

####################### Plot circum circle ##########################
p <- ggplot(initial, aes(x = availability, y = demand)) + geom_point(size = 0.5) + thesis_theme() +
  labs(
    x =  "Wind availability",
    y = "Demand (scaled)", 
    title = "Circumcircle for original circle"
  ) + 
  geom_point(data = outer, aes(x = availability, y = demand), size = 0.5, colour = "grey")

show(p)

#### Select two sets of representatives to plot on the outer line  ##########
numbers1 <- c(57, 123, 189)
numbers2 <- c(46, 112, 178)
reps1 <- outer %>% filter(period %in% numbers1)
reps1_closed <- rbind(reps1, reps1[1, ])
reps2 <- outer %>% filter(period %in% numbers2)
reps2_closed <- rbind(reps2, reps2[1, ])
reps1$set <- "Minimum ratio set"
reps1_closed$set <- "Minimum ratio set"
reps2$set <- "Lowest regret set"
reps2_closed$set <- "Lowest regret set"
representatives <- rbind(reps1, reps2)
representatives_closed <- rbind(reps1_closed, reps2_closed)
initial_long <- initial %>% mutate(set = "Minimum ratio set") %>% bind_rows(initial %>% mutate(set = "Lowest regret set"))
outer_long <- outer %>% mutate(set = "Minimum ratio set") %>% bind_rows(outer %>% mutate(set = "Lowest regret set"))

# Now plot with facets
p <- ggplot(initial_long, aes(x = availability, y = demand)) +
  geom_point(size = 0.5) +
  thesis_theme() +
  labs(
    x =  "Wind availability",
    y = "Demand (scaled)", 
    title = "Circumcircle comparison"
  ) +
  geom_point(data = outer_long, aes(x = availability, y = demand), size = 0.5, colour = "grey") +
  geom_point(data = representatives, aes(x = availability, y = demand), size = 4, colour = options[7]) +
  geom_path(data = representatives_closed, aes(x = availability, y = demand), color = options[7]) +
  facet_grid(cols = vars(set)) +
  coord_cartesian(xlim = c(0, 1), 
                  ylim = c(0, 1.5)) 

show(p)

save_plot(p, paste0('C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/2D/circle_min.pdf'), 0.5)

### get table for 2d best triagnel option ##
output_table <- output_with_seeds %>%
  filter(clustering == "k_means", num_periods == 99, distance == "CosineDist")
