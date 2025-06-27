library(readr)
library(ggplot2)
library(dplyr)
combined_output <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/stylized_EU/configs_experiment/results/combined_output_allmonths.csv")

# Create factors
combined_output$method <- as.factor(combined_output$method)
combined_output$distance <- as.factor(combined_output$distance)
combined_output$clustering <- as.factor(combined_output$clustering)
combined_output$scenario <- as.factor(combined_output$scenario)
combined_output$num_periods <- as.factor(combined_output$num_periods)
combined_output$month <- as.factor(combined_output$month)

stochastic_output <- filter(combined_output, num_periods == "0")
output <- filter(combined_output, num_periods != "0")

# Calculate the regret and speedup
stochastic_summary <- stochastic_output %>%
  group_by(month) %>%
  summarise(
    avg_total_cost = first(avg_total_cost),  # or use mean if you want an average
    time = first(time)  # or use mean if you want an average
  )

output <- output %>%
  left_join(stochastic_summary, by = "month") %>%
  mutate(
    average_regret = (avg_total_cost.x - avg_total_cost.y) / avg_total_cost.y * 100,
    speedup = time.y / time.x,
    speedup_with_dispatch = time.y / time_with_dispatch
  ) %>%
  rename(
    avg_total_cost = avg_total_cost.x,  
    time = time.x
  ) %>%
  select(-avg_total_cost.y, -time.y)

output_50 <- output %>% filter(num_periods == "50") %>% filter(speedup_with_dispatch > 4.5)
output_100 <- filter(output, num_periods == "100") %>% filter(speedup_with_dispatch > 2.5)
output_150 <- filter(output, num_periods == "150") %>% filter(speedup_with_dispatch > 2)

ggplot(output_50) + 
  geom_point(mapping = aes(x = speedup_with_dispatch, y = average_regret, colour = clustering), size = 2) + 
  facet_grid(cols = vars(method), rows = vars(distance)) +
  scale_color_brewer(palette = "Set2") + xlab("Speedup") + ylab("Average regret (as % of optimal objective)") +
  ggtitle("Speedup vs. average regret for 50 representative periods across 10 scenarios, \nrepeated on 12 different input sets") +
  theme(axis.title.x =element_text(size=12, margin = margin(t = 10)), 
        axis.title.y =element_text(size=12, margin = margin(r = 10)),
        legend.title = element_text(face = "bold", size = 12),legend.text = element_text(size = 12))

ggplot(output_100) + 
  geom_point(mapping = aes(x = speedup_with_dispatch, y = average_regret, colour = clustering), size = 2) + 
  facet_grid(cols = vars(method), rows = vars(distance)) +
  scale_color_brewer(palette = "Set2") + xlab("Speedup") + ylab("Average regret (as % of optimal objective)") +
  ggtitle("Speedup vs. average regret for 100 representative periods across 10 scenarios, \nrepeated on 12 different input sets") +
  theme(axis.title.x =element_text(size=12, margin = margin(t = 10)), 
        axis.title.y =element_text(size=12, margin = margin(r = 10)),
        legend.title = element_text(face = "bold", size = 12),legend.text = element_text(size = 12))


ggplot(output_150) + 
  geom_point(mapping = aes(x = speedup_with_dispatch, y = average_regret, colour = clustering), size = 2) + 
  facet_grid(cols = vars(method), rows = vars(distance)) +
  scale_color_brewer(palette = "Set2") + xlab("Speedup") + ylab("Average regret (as % of optimal objective)") +
  ggtitle("Speedup vs. average regret for 150 representative periods across 10 scenarios, \nrepeated on 12 different input sets") +
  theme(axis.title.x =element_text(size=12, margin = margin(t = 10)), 
        axis.title.y =element_text(size=12, margin = margin(r = 10)),
        legend.title = element_text(face = "bold", size = 12),legend.text = element_text(size = 12))


months <- unique(output$month)  # Get the unique months in your data
rep_periods <- c(50, 100, 150)

for (rep_period in rep_periods) {

  data_period <- subset(output, num_periods == rep_period)
  
  # Loop through each month
  for (m in months) {
    
    # Subset the data for the current month within the current representative period
    data_month <- subset(data_period, month == m)
    
    # Create the plot for the current month and representative period
    plot <- ggplot(data_month) + 
      geom_point(mapping = aes(x = speedup_with_dispatch, y = average_regret, colour = clustering, shape=method), size = 2) + 
      facet_grid(cols = vars(distance)) +  
      scale_color_brewer(palette = "Set2") + 
      ggtitle(paste("Month", m, " - Rep Period", rep_period))  # Add title with month and representative period
    
    # Print the plot
    print(plot)
  }
}
