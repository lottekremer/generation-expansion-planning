## RUN TIME FILE ##
library(readr)
library(ggplot2)
library(dplyr)
library(boot)
library(tidyr)
source("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/theme.R")


stochastic_investment <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/europe/results/investment_stochastic.csv")
investment <- read_csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/europe/results/investment.csv")

# Assuming 'investment_summary' is already aggregated as before
# Now aggregate 'stochastic_investment' if needed:
stochastic_summary <- stochastic_investment %>%
  pivot_longer(
    cols = c(windon, windoff, solar),
    names_to = "source",
    values_to = "benchmark_value"
  ) %>%
  group_by(source) %>%  # benchmark might not depend on rp or clustering, adjust if needed
  summarise(
    benchmark_value = mean(benchmark_value, na.rm = TRUE)  # or sum
  ) %>%
  ungroup()

investment_long <- investment %>%
  pivot_longer(
    cols = c(windon, windoff, solar),
    names_to = "source",
    values_to = "value"
  )

investment_summary <- investment_long %>%
  group_by(rp, clustering, num_periods, data, source) %>%
  summarise(
    value = mean(value, na.rm = TRUE)
  ) %>%
  ungroup()

investment_comparison <- investment_summary %>%
  left_join(
    stochastic_summary,
    by = c("source")
  )

p_investment <- ggplot() +
  geom_bar(
    data = investment_summary,
    aes(
      x = factor(rp),
      y = value,
      fill = source
    ),
    stat = "identity"
  ) +
  facet_grid(
    rows = vars(clustering),
    cols = vars(data),
    labeller = labeller(
      data = c(
        "blended" = "Blended + extremes",
        "extreme" = "Extremes",
        "output" = "Original"
      ),
      clustering = my_labels
      )
    ) +
  labs(
    title = "Investments by Representative Period and Energy Source",
    x = "Representative Period Method",
    y = "Investment Value",
    fill = "Clustering"
  ) +
  thesis_theme()

show(p_investment)

#################### NEW PLOT ############################
investment_comparison <- investment_comparison %>%
  mutate(
    percentage_diff = ((value - benchmark_value) / benchmark_value) * 100
  )

p_percentage_diff <- ggplot() +
  geom_bar(
    data = investment_comparison %>% filter(data == "blended"),
    aes(
      x = factor(rp),
      y = percentage_diff,
      fill = source
    ),
    stat = "identity",
    position = "stack"  # or position_dodge(width = 0.6)
  ) +
  facet_grid(
    rows = vars(clustering),
    cols = vars(num_periods),
    labeller = labeller(
      clustering = my_labels
    )
  ) +
  labs(
    title = "Investments by Representative Period and Energy Source",
    x = "Representative Period Method",
    y = "Investment Value",
    fill = "Clustering"
  ) +
  thesis_theme()
show(p_percentage_diff)

save_plot(
  p_percentage_diff,
  "C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/europe/results/investment_blended.pdf", 0.55
)

