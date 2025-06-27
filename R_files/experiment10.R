# In sample evaluation of the distrubution case studies

library(readr)
library(ggplot2)
library(dplyr)

combined_output <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/optimality/results/insample_distribution.csv")

# Create factors
combined_output$method <- as.factor(combined_output$method)
combined_output$distance <- as.factor(combined_output$distance)
combined_output$clustering <- as.factor(combined_output$clustering)
combined_output$num_periods <- as.integer(combined_output$num_periods)
combined_output$seed <- as.factor(combined_output$seed)

stochastic_output <- filter(combined_output, method == "stochastic")
output <- filter(combined_output, method != "stochastic")

# Calculate the regret and speedup
stochastic_output_summary <- stochastic_output %>%
  group_by(data) %>%
  summarise(
    cost = first(cost),
    time = first(time),
    loss_ct = first(loss_ct),
    loss = first(loss)
  )

output_with_seeds <- output %>%
  left_join(stochastic_output_summary, by = "data") %>%
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
  group_by(data, num_periods, distance, clustering) %>%
  summarise(
    cost_increase = median(cost_increase),
    speedup = median(speedup), 
    loss_ct_increase = median(loss_ct_increase),
    loss_increase = median(loss_increase),
  )

output_quantiles_cost <- output_with_seeds %>%
  group_by(data, num_periods, distance, clustering) %>%
  summarise(
    q25 = quantile(cost_increase, 0.25),
    q75 = quantile(cost_increase, 0.75),
    mean_ci = mean(cost_increase),
    .groups = 'drop'
  )

output_quantiles_loss <- output_with_seeds %>%
  group_by(data, num_periods, distance, clustering) %>%
  summarise(
    q25 = quantile(loss_ct_increase, 0.25),
    q75 = quantile(loss_ct_increase, 0.75),
    mean_ci = median(loss_ct_increase),
    .groups = 'drop'
  )

categories <- unique(output$data)
for (cat in categories) {
  cat <- "softmax"
  p <- ggplot(output_final %>% filter(data == cat, distance == "CosineDist"), aes(x = num_periods, y = cost_increase, 
                                                                            colour = clustering, 
                                                                            linetype = clustering, group = clustering)) +
    geom_line(size = 1) +
    geom_point(size = 1) +
    labs(x = "Number of Representative Periods", y = "Cost Increase (%)", 
         title = paste("Cost Increase % per number of Representative Periods - Cosine distance - Convex")) +
    geom_ribbon(data = output_quantiles_cost %>% filter(distance == "CosineDist", data == cat),
                mapping = aes(x = num_periods, ymin = q25, ymax = q75, fill = clustering), 
                alpha = 0.2, inherit.aes = FALSE)+
    theme_minimal() +
    scale_x_continuous(breaks = seq(
      from = 3, to = 41, by = 2)) +
    theme(legend.title = element_blank())  +
    scale_colour_discrete(labels = c("convex_hull" = "Convex Hull", "k_means" = "K-Means", "k_medoids" = "K-Medoids")) +
    scale_linetype_discrete(labels = c("convex_hull" = "Convex Hull", "k_means" = "K-Means", "k_medoids" = "K-Medoids")) +
    scale_fill_discrete(labels = c("convex_hull" = "Convex Hull", "k_means" = "K-Means", "k_medoids" = "K-Medoids"))
  
  
  show(p)
}


categories <- unique(output$data)
for (cat in categories) {
  p <- ggplot(output_final %>% filter(data == cat, distance == "CosineDist"), aes(x = num_periods, y = cost_increase, 
                                                                                  colour = clustering, 
                                                                                  linetype = clustering, group = clustering)) +
    geom_line(size = 1) +
    geom_point(size = 1) +
    labs(x = "Number of Periods", y = "Cost Increase (%)", 
         title = paste("Cost Increase vs Number of Periods - Cosine Distance - ", cat)) +
    geom_ribbon(data = output_quantiles_cost %>% filter(distance == "CosineDist", data == cat),
                mapping = aes(x = num_periods, ymin = q25, ymax = q75, fill = clustering), 
                alpha = 0.2, inherit.aes = FALSE)+
    theme_minimal() +
    coord_cartesian(xlim = c(3, 41), 
                    ylim = c(0, 10)) +
    scale_x_continuous(breaks = seq(
      from = 3, to = 41, by = 2)) +
    theme(legend.title = element_blank())
  
  show(p)
}

########## LOSS PLOTS ########################
categories <- unique(output$data)
for (cat in categories) {
  p <- ggplot(output_final %>% filter(data == cat, distance == "CosineDist"), aes(x = num_periods, y = loss_ct_increase, 
                                                                                  colour = clustering, 
                                                                                  linetype = clustering, group = clustering)) +
    geom_line(size = 1) +
    geom_point(size = 1) +
    labs(x = "Number of Periods", y = "Time steps with loss of load", 
         title = paste("Loss of load vs Number of Periods - Cosine Distance - ", cat)) +
    geom_ribbon(data = output_quantiles_loss %>% filter(distance == "CosineDist", data == cat),
                mapping = aes(x = num_periods, ymin = q25, ymax = q75, fill = clustering), 
                alpha = 0.2, inherit.aes = FALSE)+
    theme_minimal() +
    scale_x_continuous(breaks = seq(
      from = 3, to = 41, by = 2)) +
    theme(legend.title = element_blank())
  
  show(p)

}

categories <- unique(output$data)
for (cat in categories) {
  p <- ggplot(output_final %>% filter(data == cat, distance == "CosineDist", clustering == "convex_hull")) +
    geom_line(aes(x = num_periods, y = loss_ct_increase, color = "Loss of Load"), size = 1) +
    geom_point(aes(x = num_periods, y = loss_ct_increase, color = "Loss of Load"), size = 1) +
    geom_line(aes(x = num_periods, y = cost_increase, color = "Cost Increase"), size = 1, linetype = "dashed") +
    geom_point(aes(x = num_periods, y = cost_increase, color = "Cost Increase"), size = 1) +
    
    labs(x = "Number of Periods", 
         y = "Time Steps with Loss of Load",
         title = paste("Loss of Load vs Cost Increase - Cosine Distance - ", cat),
         color = "Metric") +
    
    scale_x_continuous(breaks = seq(3, 41, by = 2)) +
    
    # Create secondary y-axis for cost_increase (ggplot2 handles scaling)
    scale_y_continuous(
      sec.axis = sec_axis(~ ., name = "Cost Increase (%)") 
    ) +
    
    theme_minimal() +
    theme(legend.title = element_blank())
  
  show(p)

}

cat <- "closemixed"
p <- ggplot(output_final %>% filter(data == cat, distance == "CosineDist"), aes(x = num_periods, y = cost_increase, 
                                                                                colour = clustering, 
                                                                                linetype = clustering, group = clustering)) +
  geom_line(size = 1) +
  geom_point(size = 1) +
  labs(x = "Number of Representative Periods", y = "Cost Increase (%)", 
       title = paste("Cost Increase % per number of Representative Periods - Cosine distance - Uncorrelated clusters")) +
  geom_ribbon(data = output_quantiles_cost %>% filter(distance == "CosineDist", data == cat),
              mapping = aes(x = num_periods, ymin = q25, ymax = q75, fill = clustering), 
              alpha = 0.2, inherit.aes = FALSE)+
  theme_minimal() +
  scale_x_continuous(breaks = seq(
    from = 3, to = 41, by = 2)) +
  theme(legend.title = element_blank())  +
  scale_colour_discrete(labels = c("convex_hull" = "Convex Hull", "k_means" = "K-Means", "k_medoids" = "K-Medoids")) +
  scale_linetype_discrete(labels = c("convex_hull" = "Convex Hull", "k_means" = "K-Means", "k_medoids" = "K-Medoids")) +
  scale_fill_discrete(labels = c("convex_hull" = "Convex Hull", "k_means" = "K-Means", "k_medoids" = "K-Medoids"))


show(p)
