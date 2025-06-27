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

################### PLOT AVERAGES INSAMPLE #################################
p <- ggplot(
  insample_summarized,
  aes(x = rp_time, y = avg_total_cost,
      colour = clustering, shape = method)) +
  geom_point(size = 1) +
  labs(
    x = "Total run time",
    y = "Average total cost",
    title = "No title yet",
    color = "Clustering",
    shape = "Method"
  ) +
  labs(
    title = "Total expected costs per experiment versus total run time",
    x = "Total run time",
    y = "Expected total costs",
    color = "Clustering Type",
    shape = "Representative Method"
  ) + scale_color_manual(
    name = "Clustering Type",
    values = my_colors,
    labels = my_labels
  ) + scale_shape_manual(
    name = "Representative Method",
    values = c("cross" = 16, "per" = 17),  # adjust if needed
    labels = c("cross" = "Cross-Scenario", "per" = "Per-Scenario")
  ) + thesis_theme()


show(p)

save_plot(p, paste0('C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/Europe/kmeans.pdf'), 0.4)


p <- ggplot(
  insample_summarized %>% filter(clustering != "k_means"),
  aes(x = total_time, y = estimated_cost_error,
      colour = clustering, shape = method)) +
  geom_point(size = 1) +
  labs(
    x = "Total run time",
    y = "Average total cost",
    title = "No title yet",
    color = "Clustering",
    shape = "Method"
  ) +
  thesis_theme()

show(p)

# Load required libraries
library(boot)

# Define bootstrap function for mean
bootstrap_ci <- function(df, metric_col = "total_cost", R = 1000) {
  boot_mean <- function(data, indices) {
    sampled <- data[indices, ]
    mean(sampled[[metric_col]], na.rm = TRUE)
  }
  
  boot_out <- boot(data = df, statistic = boot_mean, R = R)
  ci <- boot.ci(boot_out, type = "perc")
  
  list(
    mean = boot_out$t0,
    ci_lower = ci$percent[4],
    ci_upper = ci$percent[5]
  )
}

# Filter to only k_medoids clustering
insample_test <- insample_augmented 

# 1. Bootstrap results for k_medoids (already done)
bootstrap_results <- insample_test %>%
  group_by(clustering, method, num_periods) %>%
  group_modify(~ {
    ci_result <- bootstrap_ci(.x, metric_col = "total_cost", R = 1000)
    tibble(
      mean_avg_total_cost = ci_result$mean,
      ci_lower = ci_result$ci_lower,
      ci_upper = ci_result$ci_upper
    )
  }) %>%
  ungroup()

# 2. Filter out k_means
bootstrap_results <- bootstrap_results %>% filter(clustering != "k_means")

# 3. Plot both: bootstrap with error bars + point estimates for convex/conical
ggplot() +
  # Bootstrap results with error bars
  geom_point(
    data = bootstrap_results,
    aes(
      x = factor(num_periods),
      y = mean_avg_total_cost,
      color = clustering,
      shape = method,
      group = interaction(clustering, method)
    ),
    position = position_dodge(width = 0.6),
    size = 2
  ) +
  geom_errorbar(
    data = bootstrap_results,
    aes(
      x = factor(num_periods),
      ymin = ci_lower,
      ymax = ci_upper,
      color = clustering,
      group = interaction(clustering, method)
    ),
    position = position_dodge(width = 0.6),
    width = 0.2
  ) +
  
  labs(
    title = "Bootstrap CI",
    x = "Number of Representative Periods",
    y = "Mean Total Cost",
    color = "Clustering",
    shape = "Method"
  ) +
  theme_minimal()

# 1. Bootstrap results for k_medoids (already done)
bootstrap_results_outsample <- outsample %>%
  group_by(clustering, method, num_periods) %>%
  group_modify(~ {
    ci_result <- bootstrap_ci(.x, metric_col = "total_cost", R = 1000)
    tibble(
      mean_avg_total_cost = ci_result$mean,
      ci_lower = ci_result$ci_lower,
      ci_upper = ci_result$ci_upper
    )
  }) %>%
  ungroup()

# 2. Filter out k_means
bootstrap_results_outsample <- bootstrap_results_outsample %>% filter(clustering != "k_means")

# 3. Plot both: bootstrap with error bars + point estimates for convex/conical
ggplot() +
  # Bootstrap results with error bars
  geom_point(
    data = bootstrap_results_outsample,
    aes(
      x = factor(num_periods),
      y = mean_avg_total_cost,
      color = clustering,
      shape = method,
      group = interaction(clustering, method)
    ),
    position = position_dodge(width = 0.6),
    size = 2
  ) +
  geom_errorbar(
    data = bootstrap_results_outsample,
    aes(
      x = factor(num_periods),
      ymin = ci_lower,
      ymax = ci_upper,
      color = clustering,
      group = interaction(clustering, method)
    ),
    position = position_dodge(width = 0.6),
    width = 0.2
  ) +
  
  labs(
    title = "Bootstrap CI",
    x = "Number of Representative Periods",
    y = "Mean Total Cost",
    color = "Clustering",
    shape = "Method"
  ) +
  theme_minimal()



###################### RUNTIME PLOTS #################################
bootstrap_ci <- function(df, metric_col = "rp_time", R = 1000) {
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

# --- Step 2: Bootstrap for k_medoids only ---
bootstrap_results_time <- insample_summarized %>%
  filter(clustering %in% c("k_medoids", "k_means")) %>%
  group_by(method, clustering, num_periods) %>%
  group_modify(~ {
    ci_result <- bootstrap_ci(.x, metric_col = "rp_time", R = 1000)
    tibble(
      mean_total_time = ci_result$mean,
      ci_lower = ci_result$ci_lower,
      ci_upper = ci_result$ci_upper
    )
  }) %>%
  ungroup()

# --- Step 3: Point estimates for convex_hull / conical_bounded ---
time_methods_summary <- insample_summarized %>%
  filter(clustering %in% c("convex_hull", "conical_bounded")) %>%
  group_by(method, num_periods, clustering) %>%
  summarise(mean_total_time = mean(rp_time, na.rm = TRUE), .groups = "drop")

# --- Step 4: Combine bootstrap and point estimates ---
results_time_mean <- bootstrap_results_time %>%
  select(method, num_periods, clustering, mean_total_time = mean_total_time)

results_time_mean <- rbind(
  results_time_mean,
  time_methods_summary)

# Join mean results with error bars (will have NA for ci_lower/ci_upper where not bootstrapped)
results_time_all <- results_time_mean %>%
  left_join(
    bootstrap_results_time,
    by = c("method", "clustering", "num_periods")
  ) %>% select(
    method,
    num_periods,
    clustering,
    mean_total_time = mean_total_time.x,
    ci_lower = ci_lower,
    ci_upper = ci_upper
  )

ggplot() +
  # Points for all methods
  geom_point(
    data = results_time_all,
    aes(
      x = factor(method),
      y = mean_total_time,
      color = clustering,
      shape = method,
      group = clustering
    ),
    position = position_dodge(width = 0.6),
    size = 2
  ) +
  # Error bars only where data is available
  geom_errorbar(
    data = results_time_all,
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
  )+
  labs(
    title = "Total time spent on the reduced model for selection and optimization",
    x = "Representative Period Selection Method",
    y = "Mean Total Time (s)",
    color = "Clustering Type",
    shape = "Representative Method"
  ) +
  theme_minimal() + scale_color_manual(
    name = "Clustering Type",
    values = my_colors,
    labels = my_labels
  ) + scale_shape_manual(
    name = "Representative Method",
    values = c("cross" = 16, "per" = 17),  # adjust if needed
    labels = c("cross" = "Cross-Scenario", "per" = "Per-Scenario")
  )



# Separate k_medoids for bootstrapping
outsample_kmedoids <- outsample %>%
  filter(clustering == "k_medoids")

# Perform bootstrapping grouped by year
bootstrap_results_outsample <- outsample_kmedoids %>%
  group_by(method, num_periods, year) %>%
  group_modify(~ {
    ci_result <- bootstrap_ci(.x, metric_col = "total_cost", R = 1000)
    tibble(
      mean_avg_total_cost = ci_result$mean,
      ci_lower = ci_result$ci_lower,
      ci_upper = ci_result$ci_upper,
      clustering = "k_medoids"
    )
  }) %>%
  ungroup()

# Get deterministic point estimates for convex_hull and conical_bounded
point_estimates_outsample <- outsample %>%
  filter(clustering %in% c("convex_hull", "conical_bounded")) %>%
  group_by(method, num_periods, clustering, year) %>%
  summarise(mean_avg_total_cost = mean(total_cost), .groups = "drop")

ggplot() +
  # Bootstrap (k_medoids) results with error bars
  geom_point(
    data = bootstrap_results_outsample,
    aes(
      x = factor(num_periods),
      y = mean_avg_total_cost,
      color = clustering,
      shape = method,
      group = interaction(clustering, method)
    ),
    position = position_dodge(width = 0.6),
    size = 2
  ) +
  geom_errorbar(
    data = bootstrap_results_outsample,
    aes(
      x = factor(num_periods),
      ymin = ci_lower,
      ymax = ci_upper,
      color = clustering,
      group = interaction(clustering, method)
    ),
    position = position_dodge(width = 0.6),
    width = 0.2
  ) +
  
  # Point estimates (convex/conical only)
  geom_point(
    data = point_estimates_outsample,
    aes(
      x = factor(num_periods),
      y = mean_avg_total_cost,
      color = clustering,
      shape = method,
      group = interaction(clustering, method)
    ),
    position = position_dodge(width = 0.6),
    size = 2
  ) +
  
  facet_wrap(~ year, scales = "free_y") +
  labs(
    title = "Total Cost per Year: Bootstrap CI (k_medoids) + Point Estimates (Convex/Conical)",
    x = "Number of Representative Periods",
    y = "Mean Total Cost",
    color = "Clustering",
    shape = "Method"
  ) +
  theme_minimal()

################### Objective change #######################################

