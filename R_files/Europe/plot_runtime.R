## RUN TIME FILE ##
library(readr)
library(ggplot2)
library(dplyr)
library(boot)
library(tidyr)

stochastic <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/europe/results/stochastic.csv")

source("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/theme.R")
combined_output <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/europe/results/total.csv")

# Create factors
combined_output$method <- as.factor(combined_output$rp)
combined_output$distance <- as.factor(combined_output$distance)
combined_output$clustering <- as.factor(combined_output$clustering)
combined_output$type <- as.factor(combined_output$type)

# Make dataframe with expected values over all scenarios that are insample
initial <- combined_output %>%
  filter(type == "initial") %>%
  mutate(
    estimated_cost = investment_cost + operational_cost,
    rp_time = runtime + process_time
  ) %>%
  select(method, num_periods, clustering, seed, estimated_cost, rp_time, data, runtime, process_time)

insample <- combined_output %>%
  filter(type == "insample") %>%
  select(method, num_periods, clustering, investment_cost, operational_cost, runtime, process_time, seed, loss_ct, loss, year, data) %>%
  mutate(
    total_cost = investment_cost + operational_cost,
    total_time = runtime + process_time
  )

insample_hull <- insample %>%
  filter(clustering == "convex_hull" | clustering == "conical_bounded")

insample_2 <- insample_hull %>% mutate(seed = seed + 1)
insample_3 <- insample_hull %>% mutate(seed = seed + 2)
insample_4 <- insample_hull %>% mutate(seed = seed + 3)
insample_5 <- insample_hull %>% mutate(seed = seed + 4)
insample <- rbind(insample, insample_2, insample_3, insample_4, insample_5)

insample_augmented <- insample %>%
  left_join(initial, by = c("method", "num_periods", "clustering", "seed", "data"))
insample_augmented <- insample_augmented %>% drop_na()


outsample <- combined_output %>%
  filter(type == "outsample") %>%
  select(method, num_periods, clustering, investment_cost, operational_cost, runtime, process_time, seed, loss_ct, loss, year, data) %>%
  mutate(
    total_cost = investment_cost + operational_cost,
    total_time = runtime + process_time
  )

insample_summarized <- insample_augmented %>%
  group_by(method, num_periods, clustering, seed, data) %>%
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

######################### K-means bad #########################################
p <- ggplot(
  insample_summarized %>% filter(data == "output"),
  aes(x = rp_time, y = avg_total_cost,
      colour = clustering, shape = method)) +
  geom_point(size = 1) +
  labs(
    title = "Average total costs over all in-sample scenarios versus total run time",
    x = "Total run time",
    y = "Average total costs",
    color = "Clustering type",
    shape = "Representative method"
  ) + scale_color_manual(
    name = "Clustering type",
    values = my_colors,
    labels = my_labels
  ) + scale_shape_manual(
    name = "Representative Method",
    values = c("cross" = 16, "per" = 17),  
    labels = c("cross" = "Cross-scenario", "per" = "Per-scenario")
  ) + thesis_theme()


show(p)

save_plot(p, paste0('C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/Europe/kmeans.pdf'), 0.4)



############### OUTSAMPLE COST #############################################
bootstrap_ci_cost <- function(df, metric_col = "total_cost", R = 1000) {
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

bootstrap_outsample <- outsample %>%
  group_by(method, clustering, num_periods, data) %>%
  group_modify(~ {
    ci_result <- bootstrap_ci_cost(.x, metric_col = "total_cost", R = 1000)
    tibble(
      mean_total_cost = ci_result$mean,
      ci_lower = ci_result$ci_lower,
      ci_upper = ci_result$ci_upper
    )
  }) %>%
  ungroup()

p_cost <- ggplot() +
  geom_point(
    data = bootstrap_outsample %>% filter(clustering != "k_means"),
    aes(
      x = factor(method),
      y = mean_total_cost,
      color = clustering,
      shape = method,
      group = clustering
    ),
    position = position_dodge(width = 0.6),
    size = 1
  ) +
  geom_errorbar(
    data = bootstrap_outsample %>% filter(clustering != "k_means"),
    aes(
      x = factor(method),
      ymin = ci_lower,
      ymax = ci_upper,
      color = clustering,
      group = clustering
    ),
    position = position_dodge(width = 0.6),
    width = 0.5,
    na.rm = TRUE
  ) +
  facet_grid(
    rows = vars(data),
    cols = vars(num_periods),
    labeller = labeller(
      num_periods = function(x) paste(x, "representative periods"),
      data = c(
        "blended" = "Blended + extremes",
        "extreme" = "Extremes",
        "output" = "Original"
      )
    )
  ) +
  labs(
    title = "Average total cost over all out-of-sample scenarios",
    x = "Representative period method",
    y = "Average total cost",
    color = "Selection type",
    shape = "Representative method"
  ) +
  scale_color_manual(
    name = "Clustering type",
    values = my_colors,
    labels = my_labels
  ) +
  scale_shape_manual(
    name = "Representative method",
    values = c("cross" = 16, "per" = 17),
    labels = c("cross" = "Cross-scenario", "per" = "Per-scenario")
  )+
  thesis_theme()


show(p_cost)

save_plot(p_cost, "C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/Europe/cost_outsample.pdf", 0.55)

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

results_time_all <- initial %>%
  group_by(method, clustering, num_periods, data) %>%
  group_modify(~ {
    ci_result <- bootstrap_ci(.x, metric_col = "rp_time", R = 1000)
    tibble(
      mean_total_time = ci_result$mean,
      ci_lower = ci_result$ci_lower,
      ci_upper = ci_result$ci_upper
    )
  }) %>%
  ungroup()

  # Create the plot
  p <- ggplot() +
    geom_point(
      data = results_time_all %>% filter(clustering != "k_means"),
      aes(
        x = factor(method),
        y = mean_total_time,
        color = clustering,
        shape = method,
        group = clustering
      ),
      position = position_dodge(width = 0.6),
      size = 1
    ) +
    geom_errorbar(
      data = results_time_all %>% filter(clustering != "k_means"),
      aes(
        x = factor(method),
        ymin = ci_lower,
        ymax = ci_upper,
        color = clustering,
        group = clustering
      ),
      position = position_dodge(width = 0.6),
      width = 0.5,
      na.rm = TRUE
    ) +
    facet_grid(
      rows = vars(data),
      cols = vars(num_periods),
      labeller = labeller(
        num_periods = function(x) paste(x, "representative periods"),
        data = c(
          "blended" = "Blended + extremes",
          "extreme" = "Extremes",
          "output" = "Original"
        )
      )
    ) +
    labs(
      title = "Mean total time spent on reduced model",
      x = "Representative period method",
      y = "Mean runtime",
      color = "Selection type",
      shape = "Representative method"
    ) +
    scale_color_manual(
      name = "Selection type",
      values = my_colors,
      labels = my_labels
    ) +
    scale_shape_manual(
      name = "Representative method",
      values = c("cross" = 16, "per" = 17),
      labels = c("cross" = "Cross-scenario", "per" = "Per-scenario")
    )+
    thesis_theme()
  
  # Show the plot
show(p)
  
save_plot(p, paste0('C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/Europe/runtime.pdf'), 0.55)

########################### COST INSAMPLE ##############################################
bootstrap_ci_cost <- function(df, metric_col = "total_cost", R = 1000) {
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

bootstrap_results_cost <- insample_augmented %>%
  group_by(method, clustering, num_periods, data) %>%
  group_modify(~ {
    ci_result <- bootstrap_ci_cost(.x, metric_col = "total_cost", R = 1000)
    tibble(
      mean_total_cost = ci_result$mean,
      ci_lower = ci_result$ci_lower,
      ci_upper = ci_result$ci_upper
    )
  }) %>%
  ungroup()


p_cost <- ggplot() +
  geom_point(
    data = bootstrap_results_cost %>% filter(clustering != "k_means"),
    aes(
      x = factor(method),
      y = mean_total_cost,
      color = clustering,
      shape = method,
      group = clustering
    ),
    position = position_dodge(width = 0.6),
    size = 1
  ) +
  geom_errorbar(
    data = bootstrap_results_cost %>% filter(clustering != "k_means"),
    aes(
      x = factor(method),
      ymin = ci_lower,
      ymax = ci_upper,
      color = clustering,
      group = clustering
    ),
    position = position_dodge(width = 0.6),
    width = 0.5,
    na.rm = TRUE
  ) +
  facet_grid(
    rows = vars(data),
    cols = vars(num_periods),
    labeller = labeller(
      num_periods = function(x) paste(x, "representative periods"),
      data = c(
        "blended" = "Blended + extremes",
        "extreme" = "Extremes",
        "output" = "Original"
      )
    )
  ) +
  labs(
    title = "Average total cost over all in-sample scenarios",
    x = "Representative period method",
    y = "Average total cost",
    color = "Selection type",
    shape = "Representative method"
  ) +
  scale_color_manual(
    name = "Selection type",
    values = my_colors,
    labels = my_labels
  ) +
  scale_shape_manual(
    name = "Representative method",
    values = c("cross" = 16, "per" = 17),
    labels = c("cross" = "Cross-scenario", "per" = "Per-scenario")
  ) +
  thesis_theme()

show(p_cost)
save_plot(p_cost, "C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/Europe/cost_differentview.pdf", 0.55)

########################### LOSS OUTSAMPLE ###############################################
bootstrap_ci_loss_ct <- function(df, metric_col = "loss_ct", R = 1000) {
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

bootstrap_results_loss_ct <- outsample %>%
  group_by(method, clustering, num_periods, data) %>%
  group_modify(~ {
    ci_result <- bootstrap_ci_loss_ct(.x, metric_col = "loss_ct", R = 1000)
    tibble(
      mean_total_loss_ct = ci_result$mean,
      ci_lower = ci_result$ci_lower,
      ci_upper = ci_result$ci_upper
    )
  }) %>%
  ungroup()


results_loss_ct_mean <- bootstrap_results_loss_ct %>%
  select(method, num_periods, clustering, mean_total_loss_ct, data, ci_lower, ci_upper)


p_loss_ct <- ggplot() +
  geom_point(
    data = results_loss_ct_mean %>% filter(clustering != "k_means"),
    aes(
      x = factor(method),
      y = mean_total_loss_ct,
      color = clustering,
      shape = method,
      group = clustering
    ),
    position = position_dodge(width = 0.6),
    size = 1) +
      geom_errorbar(
        data = results_loss_ct_mean %>% filter(clustering != "k_means"),
        aes(
          x = factor(method),
          ymin = ci_lower,
          ymax = ci_upper,
          color = clustering,
          group = clustering
        ),
        position = position_dodge(width = 0.6),
        width = 0.5,
        na.rm = TRUE
      ) +
  facet_grid(
    rows = vars(data),
    cols = vars(num_periods),
    labeller = labeller(
      num_periods = function(x) paste(x, "representative periods"),
      data = c(
        "blended" = "Blended + extremes",
        "extreme" = "Extremes",
        "output" = "Original"
      )
    )
  ) +
  labs(
    title = "Average number of timesteps containing LoL over out-of-sample scenarios",
    x = "Representative period method",
    y = "Average timesteps LoL",
    color = "Selection type",
    shape = "Representative method"
  ) +
  scale_color_manual(
    name = "Selection type",
    values = my_colors,
    labels = my_labels
  ) +
  scale_shape_manual(
    name = "Representative method",
    values = c("cross" = 16, "per" = 17),
    labels = c("cross" = "Cross-scenario", "per" = "Per-scenario")
  )+
      thesis_theme()

show(p_loss_ct)
save_plot(p_loss_ct, "C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/Europe/loss_ct_outsample.pdf", 0.55)

########################### LOSS INSAMPLE ###############################################
bootstrap_ci_loss_ct <- function(df, metric_col = "loss_ct", R = 1000) {
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

bootstrap_results_loss_ct <- insample_augmented  %>%
  group_by(method, clustering, num_periods, data) %>%
  group_modify(~ {
    ci_result <- bootstrap_ci_loss_ct(.x, metric_col = "loss_ct", R = 1000)
    tibble(
      mean_total_loss_ct = ci_result$mean,
      ci_lower = ci_result$ci_lower,
      ci_upper = ci_result$ci_upper
    )
  }) %>%
  ungroup()

results_loss_ct_all <- bootstrap_results_loss_ct

p_loss_ct <- ggplot() +
  geom_point(
    data = results_loss_ct_all %>% filter(clustering != "k_means"),
    aes(
      x = factor(method),
      y = mean_total_loss_ct,
      color = clustering,
      shape = method,
      group = clustering
    ),
    position = position_dodge(width = 0.6),
    size = 1) +
  geom_errorbar(
    data = results_loss_ct_all %>% filter(clustering != "k_means"),
    aes(
      x = factor(method),
      ymin = ci_lower,
      ymax = ci_upper,
      color = clustering,
      group = clustering
    ),
    position = position_dodge(width = 0.6),
    width = 0.5,
    na.rm = TRUE
  ) +
  facet_grid(
    rows = vars(data),
    cols = vars(num_periods),
    labeller = labeller(
      num_periods = function(x) paste(x, "representative periods"),
      data = c(
        "blended" = "Blended + extremes",
        "extreme" = "Extremes",
        "output" = "Original"
      )
    )
  ) +
  labs(
    title = "Average number of timesteps containing LoL over in-sample scenarios",
    x = "Representative period method",
    y = "Average timesteps LoL",
    color = "Selection type",
    shape = "Representative method"
  ) +
  scale_color_manual(
    name = "Selection type",
    values = my_colors,
    labels = my_labels
  ) +
  scale_shape_manual(
    name = "Representative method",
    values = c("cross" = 16, "per" = 17),
    labels = c("cross" = "Cross-scenario", "per" = "Per-scenario")
  )+
  thesis_theme()

show(p_loss_ct)
save_plot(p_loss_ct, "C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/Europe/loss_ct_insample.pdf", 0.55)

###################### RUNTIME PLOTS (only model) #################################
bootstrap_ci <- function(df, metric_col = "runtime", R = 1000) {
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

bootstrap_results_time <- initial %>%
  group_by(method, clustering, num_periods, data) %>%
  group_modify(~ {
    ci_result <- bootstrap_ci(.x, metric_col = "runtime", R = 1000)
    tibble(
      mean_total_time = ci_result$mean,
      ci_lower = ci_result$ci_lower,
      ci_upper = ci_result$ci_upper
    )
  }) %>%
  ungroup()

# Create the plot
p <- ggplot() +
  geom_point(
    data = bootstrap_results_time %>% filter(clustering != "k_means"),
    aes(
      x = factor(method),
      y = mean_total_time,
      color = clustering,
      shape = method,
      group = clustering
    ),
    position = position_dodge(width = 0.6),
    size = 1
  ) +
  geom_errorbar(
    data = bootstrap_results_time %>% filter(clustering != "k_means"),
    aes(
      x = factor(method),
      ymin = ci_lower,
      ymax = ci_upper,
      color = clustering,
      group = clustering
    ),
    position = position_dodge(width = 0.6),
    width = 0.5,
    na.rm = TRUE
  ) +
  facet_grid(
    rows = vars(data),
    cols = vars(num_periods),
    labeller = labeller(
      num_periods = function(x) paste(x, "rp"),
      data = c(
        "blended" = "Blended + Worst-case",
        "extreme" = "Worst-case periods",
        "output" = "Original"
      )
    )
  ) +
  labs(
    title = "Average runtime for optimizing reduced model",
    x = "Representative period method",
    y = "Average runtime (s)",
    color = "Selection type",
    shape = "Representative method"
  ) +
  scale_color_manual(
    name = "Selection type",
    values = my_colors,
    labels = my_labels
  ) +
  scale_shape_manual(
    name = "Representative method",
    values = c("cross" = 16, "per" = 17),
    labels = c("cross" = "Cross-scenario", "per" = "Per-scenario")
  )+
  thesis_theme()

# Show the plot
show(p)

save_plot(p, paste0('C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/Europe/runtime_model.pdf'), 0.6)

###################### RUNTIME PLOTS (only processing) #################################
bootstrap_ci <- function(df, metric_col = "runtime", R = 1000) {
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

bootstrap_results_time <- initial %>%
  group_by(method, clustering, num_periods, data) %>%
  group_modify(~ {
    ci_result <- bootstrap_ci(.x, metric_col = "process_time", R = 1000)
    tibble(
      mean_total_time = ci_result$mean,
      ci_lower = ci_result$ci_lower,
      ci_upper = ci_result$ci_upper
    )
  }) %>%
  ungroup()

# Create the plot
p <- ggplot() +
  geom_point(
    data = bootstrap_results_time %>% filter(clustering != "k_means"),
    aes(
      x = factor(method),
      y = mean_total_time,
      color = clustering,
      shape = method,
      group = clustering
    ),
    position = position_dodge(width = 0.6),
    size = 1
  ) +
  geom_errorbar(
    data = bootstrap_results_time %>% filter(clustering != "k_means"),
    aes(
      x = factor(method),
      ymin = ci_lower,
      ymax = ci_upper,
      color = clustering,
      group = clustering
    ),
    position = position_dodge(width = 0.6),
    width = 0.5,
    na.rm = TRUE
  ) +
  facet_grid(
    rows = vars(data),
    cols = vars(num_periods),
    labeller = labeller(
      num_periods = function(x) paste(x, "rp"),
      data = c(
        "blended" = "Blended + Worst-case",
        "extreme" = "Worst-case periods",
        "output" = "Original"
      )
    )
  ) +
  labs(
    title = "Average runtime for selection representatives reduced model",
    x = "Representative period method",
    y = "Average runtime (s)",
    color = "Selection type",
    shape = "Representative method"
  ) +
  scale_color_manual(
    name = "Selection type",
    values = my_colors,
    labels = my_labels
  ) +
  scale_shape_manual(
    name = "Representative method",
    values = c("cross" = 16, "per" = 17),
    labels = c("cross" = "Cross-scenario", "per" = "Per-scenario")
  )+
  thesis_theme()

# Show the plot
show(p)

save_plot(p, paste0('C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/Europe/runtime_process.pdf'), 0.6)

