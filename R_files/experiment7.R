library(readr)
library(ggplot2)
library(dplyr)
combined_output <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/stylized_EU/res/results_csv/combined_output_new.csv")
combined_output2 <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/stylized_EU/res/results_csv/combined_output_newloss.csv")
combined_output$scaling <- "Scaling"
combined_output2$scaling <- "NoScaling"
combined_output <- rbind(combined_output, combined_output2)

# Add manually new column num_periods and set is equal to 50
combined_output$distance <- "CosineDist"

# Create factors
combined_output$method <- as.factor(combined_output$method)
combined_output$distance <- as.factor(combined_output$distance)
combined_output$clustering <- as.factor(combined_output$clustering)
combined_output$scenario <- as.factor(combined_output$scenario)
combined_output$num_periods <- as.factor(combined_output$num_periods)
combined_output$month <- as.factor(combined_output$month)

stochastic_output <- filter(combined_output, method == "stochastic")
output <- filter(combined_output, method != "stochastic")

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
    speedup = time.y / time.x
  ) %>%
  rename(
    avg_total_cost = avg_total_cost.x,  
    time = time.x
  ) %>%
  select(-avg_total_cost.y, -time.y)

# Filter out kmeans
output <- filter(output, clustering != "k_means")
output <- filter(output, num_periods == 100)
output <- filter(output, blended == FALSE)

# Plot the results
ggplot(output)+geom_point(mapping = aes(x = speedup, y = average_regret, colour = clustering), size = 2) + 
  facet_grid(cols = vars(method), rows = vars(scaling))
