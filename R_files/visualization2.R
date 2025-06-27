library(readr)
library(ggplot2)
library(dplyr)
library(tidyr)
library(tidyverse)



inputs <- read.csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/optimality/inputs/generation_availability.csv")
inputs_NED <- inputs %>% filter(scenario == 1900, location == "NED", time_step == 12, technology != "WindOff") %>% pivot_wider(names_from = technology, values_from = availability)
inputs_GER <- inputs %>% filter(scenario == 1900, location == "GER", time_step == 12, period == 2, technology != "WindOff") %>% pivot_wider(names_from = technology, values_from = availability)

inputs_centered <- read.csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/optimality/inputs_centered/generation_availability.csv")
inputs_centered <- inputs_centered %>% filter(scenario == 1900, location == "NED", timestep == 12, technology != "WindOff") %>% pivot_wider(names_from = technology, values_from = availability)

inputs_close <- read.csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/optimality/inputs_close/generation_availability.csv")
inputs_close_NED <- inputs_close %>% filter(scenario == 1900, location == "NED", timestep == 12, technology != "WindOff")%>% pivot_wider(names_from = technology, values_from = availability)
inputs_close_GER <- inputs_close %>% filter(scenario == 1900, location == "GER", timestep == 12, period == 50, technology != "WindOff")%>% pivot_wider(names_from = technology, values_from = availability)
inputs_close_NED_44 <- inputs_close %>% filter(scenario == 1900, location == "NED", timestep == 12, period == 50, technology != "WindOff")%>% pivot_wider(names_from = technology, values_from = availability)

inputs_close_mixed <- read.csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/optimality/inputs_closemixed/generation_availability.csv")
inputs_close_mixed_NED <- inputs_close_mixed  %>% filter(scenario == 1900, location == "NED", timestep == 12, technology != "WindOff")%>% pivot_wider(names_from = technology, values_from = availability)
inputs_close_mixed_GER <- inputs_close_mixed  %>% filter(scenario == 1900, location == "GER", timestep == 12, period == 50, technology != "WindOff")%>% pivot_wider(names_from = technology, values_from = availability)
inputs_close_mixed_NED_44 <- inputs_close_mixed  %>% filter(scenario == 1900, location == "NED", timestep == 12, period == 50, technology != "WindOff")%>% pivot_wider(names_from = technology, values_from = availability)

inputs_softmax <- read.csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/optimality/inputs_softmax/generation_availability.csv")
inputs_softmax <- inputs_softmax %>% filter(scenario == 1900, location == "NED", timestep == 12, technology != "WindOff")%>% pivot_wider(names_from = technology, values_from = availability)

ggplot(inputs_NED, aes(x = SunPV, y = WindOn)) +
  geom_point(size = 2) +
  labs(x = "Wind Availability", y = "SunPV Availability", 
       title = "Original values of Wind vs Solar Availability") +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1)) +
  theme_minimal()

ggplot(inputs_NED, aes(x = SunPV, y = WindOn)) +
  geom_point(size = 4, colour = "red") +
  geom_point(data = inputs_centered, aes(x = SunPV, y = WindOn), size = 1, colour = "red") +
  labs(x = "Wind Onshore Availability", y = "SunPV Availability") +
  scale_x_continuous(limits = c(0.1, 0.7)) +
  scale_y_continuous(limits = c(0, 0.75), expand = c(0,0)) +
  theme_minimal() +
  theme(
    axis.title = element_text(size = 12),  # Larger text
    axis.title.x = element_text(margin = margin(10, 0, 0, 0)),  # Move x-axis title down
    axis.title.y = element_text(margin = margin(0, 10, 0, 0))   # Move y-axis title left
  )

ggplot(inputs_NED, aes(x = SunPV, y = WindOn)) +
  geom_point(size = 4, colour = "red") +
  geom_point(data = inputs_GER, aes(x = SunPV, y = WindOn), size = 3, colour = "blue") +
  geom_point(data = inputs_close_NED, aes(x = SunPV, y = WindOn), size = 1, colour = "red") +
  geom_point(data = inputs_close_GER, aes(x = SunPV, y = WindOn), size = 3, shape = 17, colour = "blue") +
  geom_point(data = inputs_close_NED_44, aes(x = SunPV, y = WindOn), size = 3, shape = 17, colour = "red") +
  labs(x = "Wind Onshore Availability", y = "SunPV Availability") + scale_x_continuous(limits = c(0.1, 0.7)) +
  scale_y_continuous(limits = c(0, 0.75), expand = c(0,0)) +
  theme_minimal() + theme(
    axis.title = element_text(size = 12),  # Larger text
    axis.title.x = element_text(margin = margin(10, 0, 0, 0)),  # Move x-axis title down
    axis.title.y = element_text(margin = margin(0, 10, 0, 0))   # Move y-axis title left
  )

ggplot(inputs_NED, aes(x = SunPV, y = WindOn)) +
  geom_point(size = 4, colour = "red") +
  geom_point(data = inputs_GER, aes(x = SunPV, y = WindOn), size = 3, colour = "blue") +
  geom_point(data = inputs_close_mixed_NED, aes(x = SunPV, y = WindOn), size = 1, colour = "red") +
  geom_point(data = inputs_close_mixed_GER, aes(x = SunPV, y = WindOn), size = 3, shape = 17, colour = "blue") +
  geom_point(data = inputs_close_mixed_NED_44, aes(x = SunPV, y = WindOn), size = 3, shape = 17, colour = "red") +
  labs(x = "Wind Onshore Availability", y = "SunPV Availability") + scale_x_continuous(limits = c(0.1, 0.7)) +
  scale_y_continuous(limits = c(0, 0.75), expand = c(0,0)) +
  theme_minimal() + theme(
    axis.title = element_text(size = 12),  # Larger text
    axis.title.x = element_text(margin = margin(10, 0, 0, 0)),  # Move x-axis title down
    axis.title.y = element_text(margin = margin(0, 10, 0, 0))   # Move y-axis title left
  )

ggplot(inputs_NED, aes(x = SunPV, y = WindOn)) +
  geom_point(size = 4, colour = "red") +
  geom_point(data = inputs_softmax, aes(x = SunPV, y = WindOn), size = 1, colour = "red") +
  labs(x = "Wind Onshore Availability", y = "SunPV Availability") + scale_x_continuous(limits = c(0.1, 0.7)) +
  scale_y_continuous(limits = c(0, 0.75), expand = c(0,0)) +
  theme_minimal() + theme(
    axis.title = element_text(size = 12),  # Larger text
    axis.title.x = element_text(margin = margin(10, 0, 0, 0)),  # Move x-axis title down
    axis.title.y = element_text(margin = margin(0, 10, 0, 0))   # Move y-axis title left
  )

