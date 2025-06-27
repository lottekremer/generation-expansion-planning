library(readr)
library(ggplot2)
library(dplyr)
combined_output <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/stylized_EU/configs_experiment/results/combined_output.csv")
combined_output_blended <- read_csv("~/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/stylized_EU/configs_experiment/results/combined_output_blended_2.csv")

# Style things for combined_output
combined_output$num_periods[combined_output$clustering != "crosscenario"] <- 
  combined_output$num_periods[combined_output$clustering != "crosscenario"] * 10
combined_output$clustering <- replace(combined_output$clustering, 
                                      combined_output$clustering=="crosscenario", "cross_scenario")
combined_output$clustering <- replace(combined_output$clustering, 
                                      combined_output$clustering=="perscenario", "per_scenario")
combined_output$clustering <- replace(combined_output$clustering, 
                                      combined_output$clustering=="completescenario", "group_scenario")

# Combine and put as factors for easier plotting
combined_output <- rbind(combined_output, combined_output_blended)
combined_output$method <- as.factor(combined_output$method)
combined_output$distance <- as.factor(combined_output$distance)
combined_output$clustering <- as.factor(combined_output$clustering)
combined_output$scenario <- as.factor(combined_output$scenario)
combined_output$num_periods <- as.factor(combined_output$num_periods)

stochastic_output <- filter(combined_output, clustering == "none")
combined_output <- filter(combined_output, clustering != "none")

# Calculate the increase in average cost for filtered_output, old cost is stochastic_output avg_total_cost row 1
stochastic_output_avg_cost <- stochastic_output$avg_total_cost[1]
combined_output$average_regret <- (combined_output$avg_total_cost - stochastic_output_avg_cost)
stochastic_output_runtime <- stochastic_output$time[1]
combined_output$speedup <- stochastic_output_runtime / combined_output$time

# Initial plots with all data 
ggplot(data = combined_output) + geom_point(mapping=aes(x=speedup,y=average_regret,colour=method), size=3) + 
  facet_wrap(~distance)+
  scale_color_brewer(palette="Set2")

ggplot(data = combined_output) + geom_point(mapping=aes(x=speedup,y=average_regret,colour=method), size=3) + 
  facet_grid(rows=vars(clustering), cols = vars(distance))+
  scale_color_brewer(palette="Set2") + theme(axis.title.x =element_text(size=14,face="bold", margin = margin(t = 10)), 
                                             axis.title.y =element_text(size=14,face="bold", margin = margin(r = 10)),
                                            legend.title = element_text(face = "bold", size = 12),legend.text = element_text(size = 12))

ggplot(data = combined_output) + geom_point(mapping=aes(x=speedup,y=average_regret,colour=clustering), size=3) + 
  facet_grid(rows=vars(method), cols = vars(distance))+
  scale_color_brewer(palette="Set2")

filtered_output <- combined_output
filtered_output <- filter(combined_output, !(num_periods %in% c(5)))
filtered_output <- filter(filtered_output, method != "k_means")

filtered_output_20 <- filter(filtered_output, num_periods == 20)
filtered_output_50 <- filter(filtered_output, num_periods == 50)
filtered_output_100 <- filter(filtered_output, num_periods == 100)
filtered_output_150 <- filter(filtered_output, num_periods == 150)

# Plots with filtered data but not split on representative periods numbers
ggplot(data = filtered_output) + geom_point(mapping=aes(x=speedup,y=average_regret,colour=method), size=3) + 
  facet_wrap(~distance)+
  scale_color_brewer(palette="Set2")

ggplot(data = filtered_output) + geom_point(mapping=aes(x=speedup,y=average_regret,colour=method), size=3) + 
  facet_grid(rows=vars(clustering), cols = vars(distance))+
  scale_color_brewer(palette="Set2")

ggplot(data = filtered_output) + geom_point(mapping=aes(x=speedup,y=average_regret,colour=num_periods), size=3) + 
  facet_grid(rows=vars(clustering), cols = vars(distance))+
  scale_color_brewer(palette="Set2")

# Data per number of representative periods full grid
ggplot(data = filtered_output_20) + geom_point(mapping=aes(x=speedup,y=average_regret,colour=clustering), size=4) + 
  facet_grid(rows=vars(method), cols = vars(distance)) +
  scale_color_brewer(palette="Set2")

ggplot(data = filtered_output_50) + geom_point(mapping=aes(x=speedup,y=average_regret,colour=clustering), size=4) + 
  facet_grid(rows=vars(method), cols = vars(distance)) +
  scale_color_brewer(palette="Set2")

ggplot(data = filtered_output_100) + geom_point(mapping=aes(x=speedup,y=average_regret,colour=clustering),size=4) + facet_grid(rows=vars(method), cols = vars(distance))+
  scale_color_brewer(palette="Set2")

ggplot(data = filtered_output_150) + geom_point(mapping=aes(x=speedup,y=average_regret,colour=clustering),size=4) + 
  facet_grid(rows=vars(method), cols = vars(distance))+
  scale_color_brewer(palette="Set2")

# Data per number of representative periods grid only distance, symbol for method
ggplot(data = filtered_output_20) + geom_point(mapping=aes(x=speedup,y=average_regret,colour=clustering, shape=method), size=3) +
  facet_wrap(~distance)+
  scale_color_brewer(palette="Set2")

ggplot(data = filtered_output_50) + geom_point(mapping=aes(x=speedup,y=average_regret,colour=clustering, shape=method), size=3) +
  facet_wrap(~distance)+
  scale_color_brewer(palette="Set2") + theme(axis.title.x =element_text(size=14,face="bold", margin = margin(t = 10)), 
                                             axis.title.y =element_text(size=14,face="bold", margin = margin(r = 10)),
                                             legend.title = element_text(face = "bold", size = 12),legend.text = element_text(size = 12))

ggplot(data = filtered_output_100) + geom_point(mapping=aes(x=speedup,y=average_regret,colour=clustering, shape=method),size=3) +
  facet_wrap(~distance)+
  scale_color_brewer(palette="Set2") + theme(axis.title.x =element_text(size=14,face="bold", margin = margin(t = 10)), 
                                             axis.title.y =element_text(size=14,face="bold", margin = margin(r = 10)),
                                             legend.title = element_text(face = "bold", size = 12),legend.text = element_text(size = 12))

ggplot(data = filtered_output_150) + geom_point(mapping=aes(x=speedup,y=average_regret,colour=clustering, shape=method),size=3) +
  facet_wrap(~distance)+
  scale_color_brewer(palette="Set2") + theme(axis.title.x =element_text(size=14,face="bold", margin = margin(t = 10)), 
                                             axis.title.y =element_text(size=14,face="bold", margin = margin(r = 10)),
                                             legend.title = element_text(face = "bold", size = 12),legend.text = element_text(size = 12))

# Define the options for `distance` and `method`
distance_options <- c("CityBlock", "CosineDist", "SqEuclidean")
method_options <- c("convex_hull", "k_medoids", "blended")

# Initialize the data frames for the boxplot
filtered_output_50_with_stochastic <- filtered_output_50[, !names(filtered_output) %in% c("average_regret", "speedup")]
filtered_output_100_with_stochastic <- filtered_output_100[,!names(filtered_output) %in% c("average_regret", "speedup")]
filtered_output_150_with_stochastic <- filtered_output_150[,!names(filtered_output) %in% c("average_regret", "speedup")]

# Loop over all combinations of `distance` and `method`
for (distance in distance_options) {
  for (method in method_options) {
    # Update `stochastic_output` with the current combination
    stochastic_output$distance <- distance
    stochastic_output$method <- method

    # Append to the respective data frames
    filtered_output_50_with_stochastic <- rbind(filtered_output_50_with_stochastic, stochastic_output)
    filtered_output_100_with_stochastic <- rbind(filtered_output_100_with_stochastic, stochastic_output)
    filtered_output_150_with_stochastic <- rbind(filtered_output_150_with_stochastic, stochastic_output)
  }
}

# Add stochastic input in the boxplot
ggplot(subset(filtered_output_50_with_stochastic, (method == "convex_hull" & distance == "CosineDist"))) + 
  geom_boxplot(mapping=aes(x=clustering,y=scenario_cost))
ggplot(subset(filtered_output_100_with_stochastic, (method == "convex_hull" & distance == "CosineDist"))) + 
  geom_boxplot(mapping=aes(x=clustering,y=scenario_cost)) + facet_grid(cols=vars(method), rows = vars(distance))
ggplot(subset(filtered_output_150_with_stochastic, (method == "convex_hull" & distance == "CosineDist"))) + 
  geom_boxplot(mapping=aes(x=clustering,y=scenario_cost)) + facet_grid(cols=vars(method), rows = vars(distance))

