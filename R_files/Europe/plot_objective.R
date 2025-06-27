## RUN TIME FILE ##
library(readr)
library(ggplot2)
library(dplyr)

source("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/theme.R")
combined_output <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/europe/results/test.csv")
combined_output <- filter(combined_output, !is.na(year))

# Create factors
combined_output$method <- as.factor(combined_output$rp)
combined_output$distance <- as.factor(combined_output$distance)
combined_output$clustering <- as.factor(combined_output$clustering)
combined_output$type <- as.factor(combined_output$type)

# Make dataframe with expected values over all scenarios that are insample
initial <- combined_output %>%
  filter(type == "initial") %>%
  select(method, num_periods, clustering, investment_cost, operational_cost, runtime, process_time, seed) %>%
  mutate(
    estimated_cost = investment_cost + operational_cost,
    rp_time = runtime + process_time
  ) %>%
  select(method, num_periods, clustering, seed, estimated_cost, rp_time)

insample <- combined_output %>%
  filter(type == "insample") %>%
  select(method, num_periods, clustering, investment_cost, operational_cost, runtime, process_time, seed, loss_ct, loss, year) %>%
  mutate(
    total_cost = investment_cost + operational_cost,
    total_time = runtime + process_time
  )

insample_augmented <- insample %>%
  left_join(initial, by = c("method", "num_periods", "clustering", "seed"))

outsample <- combined_output %>%
  filter(type == "outsample") %>%
  select(method, num_periods, clustering, investment_cost, operational_cost, runtime, process_time, seed, loss_ct, loss, year) %>%
  mutate(
    total_cost = investment_cost + operational_cost,
    total_time = runtime + process_time
  )

insample_summarized <- insample_augmented %>%
  group_by(method, num_periods, clustering, seed) %>%
  summarise(
    avg_total_cost = mean(total_cost, na.rm = TRUE),
    total_runtime = sum(total_time, na.rm = TRUE),
    total_loss = sum(loss, na.rm = TRUE),
    total_loss_ct = sum(loss_ct, na.rm = TRUE),
    estimated_cost = mean(estimated_cost, na.rm = TRUE),
    rp_time = mean(rp_time, na.rm = TRUE),
    .groups = "drop"
  )

insample_summarized <- insample_summarized %>%
  mutate(
    total_time = total_runtime + rp_time,
    estimated_cost_error = (avg_total_cost - estimated_cost)/estimated_cost * 100,
  )

###################### RUNTIME PLOTS #################################
bootstrap_ci_cost <- function(df, metric_col = "avg_total_cost", R = 1000) {
  boot_fun <- function(data, indices) {
    mean(data[indices, ][[metric_col]], na.rm = TRUE)
  }
  
  boot_out <- boot(data = df, statistic = boot_fun, R = R)
  ci <- boot.ci(boot_out, type = "perc")
  
  list(
    mean = boot_out$t0,
    ci_lower = ci$percent[4],
    ci_upper = ci$percent[5]
  )
}

bootstrap_results_cost <- insample_summarized %>%
  filter(clustering %in% c("k_medoids", "k_means")) %>%
  group_by(method, clustering, num_periods) %>%
  group_modify(~ {
    ci_result <- bootstrap_ci_cost(.x, metric_col = "avg_total_cost", R = 1000)
    tibble(
      mean_total_cost = ci_result$mean,
      ci_lower = ci_result$ci_lower,
      ci_upper = ci_result$ci_upper
    )
  }) %>%
  ungroup()

cost_methods_summary <- insample_summarized %>%
  filter(clustering %in% c("convex_hull", "conical_bounded")) %>%
  group_by(method, num_periods, clustering) %>%
  summarise(mean_total_cost = mean(avg_total_cost, na.rm = TRUE), .groups = "drop")
results_cost_mean <- bootstrap_results_cost %>%
  select(method, num_periods, clustering, mean_total_cost)

results_cost_mean <- rbind(results_cost_mean, cost_methods_summary)

results_cost_all <- results_cost_mean %>%
  left_join(
    bootstrap_results_cost,
    by = c("method", "clustering", "num_periods")
  ) %>%
  select(
    method,
    num_periods,
    clustering,
    mean_total_cost = mean_total_cost.x,
    ci_lower = ci_lower,
    ci_upper = ci_upper
  )

p_cost <- ggplot() +
  geom_point(
    data = results_cost_all %>% filter(clustering != "k_means"),
    aes(
      x = factor(method),
      y = mean_total_cost,
      color = clustering,
      shape = method,
      group = clustering
    ),
    position = position_dodge(width = 0.6),
    size = 2
  ) +
  geom_errorbar(
    data = results_cost_all %>% filter(clustering != "k_means"),
    aes(
      x = factor(method),
      ymin = ci_lower,
      ymax = ci_upper,
      color = clustering,
      group = clustering
    ),
    position = position_dodge(width = 0.6),
    width = 0.2,
    na.rm = TRUE
  ) +
  facet_wrap(
    ~ num_periods,
    scales = "free_y",
    labeller = labeller(num_periods = function(x) paste(x, "representative periods"))
  ) +
  labs(
    title = "Total system cost over all scenarios",
    x = "Representative Period Selection Method",
    y = "Mean Total Cost (EUR)",
    color = "Clustering Type",
    shape = "Representative Method"
  ) +
  scale_color_manual(
    name = "Clustering Type",
    values = my_colors,
    labels = my_labels
  ) +
  scale_shape_manual(
    name = "Representative Method",
    values = c("cross" = 16, "per" = 17),
    labels = c("cross" = "Cross-Scenario", "per" = "Per-Scenario")
  ) +
  thesis_theme()

show(p_cost)

save_plot(p_cost, paste0('C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/Europe/total_cost.pdf'), 0.4)

