library(readr)
library(ggplot2)
library(dplyr)
library(tidyr)
library(gridExtra)
library(grid)

source("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/theme.R")
highlight_col <- options[7]
highlight_col_2 <- options[8]

inputs <- read.csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/optimality/inputs/inputs_initial/generation_availability.csv")
inputs_NED <- inputs %>% filter(scenario == 1900, location == "NED", time_step == 12, technology != "WindOff") %>% pivot_wider(names_from = technology, values_from = availability)
inputs_GER <- inputs %>% filter(scenario == 1900, location == "GER", time_step == 12, period == 2, technology != "WindOff") %>% pivot_wider(names_from = technology, values_from = availability)

inputs_centered <- read.csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/optimality/inputs/inputs_in/inputs_centered/generation_availability.csv")
inputs_centered <- inputs_centered %>% filter(scenario == 1900, location == "NED", timestep == 12, technology != "WindOff") %>% pivot_wider(names_from = technology, values_from = availability)

inputs_close <- read.csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/optimality/inputs/inputs_in/inputs_close/generation_availability.csv")
inputs_close_NED <- inputs_close %>% filter(scenario == 1900, location == "NED", timestep == 12, technology != "WindOff")%>% pivot_wider(names_from = technology, values_from = availability)
inputs_close_GER <- inputs_close %>% filter(scenario == 1900, location == "GER", timestep == 12, period == 50, technology != "WindOff")%>% pivot_wider(names_from = technology, values_from = availability)
inputs_close_NED_44 <- inputs_close %>% filter(scenario == 1900, location == "NED", timestep == 12, period == 50, technology != "WindOff")%>% pivot_wider(names_from = technology, values_from = availability)

inputs_close_mixed <- read.csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/optimality/inputs/inputs_in/inputs_closemixed/generation_availability.csv")
inputs_close_mixed_NED <- inputs_close_mixed  %>% filter(scenario == 1900, location == "NED", timestep == 12, technology != "WindOff")%>% pivot_wider(names_from = technology, values_from = availability)
inputs_close_mixed_GER <- inputs_close_mixed  %>% filter(scenario == 1900, location == "GER", timestep == 12, period == 50, technology != "WindOff")%>% pivot_wider(names_from = technology, values_from = availability)
inputs_close_mixed_NED_44 <- inputs_close_mixed  %>% filter(scenario == 1900, location == "NED", timestep == 12, period == 50, technology != "WindOff")%>% pivot_wider(names_from = technology, values_from = availability)

inputs_softmax <- read.csv("C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/generation-expansion-planning/case_studies/optimality/inputs/inputs_in/inputs_softmax/generation_availability.csv")
inputs_softmax <- inputs_softmax %>% filter(scenario == 1900, location == "NED", timestep == 12, technology != "WindOff")%>% pivot_wider(names_from = technology, values_from = availability)

# Assuming the four ggplot objects are already created (p1, p2, p3, p4)
# Example for arranging them side by side (ncol = 2):

p1 <- ggplot(inputs_NED, aes(x = SunPV, y = WindOn)) + 
  geom_point(size = 2, colour = highlight_col) +
  geom_point(data = inputs_centered, aes(x = SunPV, y = WindOn), size = 0.2, colour = "black") +
  labs(x = "Wind Onshore", y = "SunPV", title = "Centered cluster") +
  coord_cartesian(xlim = c(0.1, 0.7), ylim = c(0, 0.75)) + scale_y_continuous(expand = c(0,0)) +
  scale_x_continuous(expand = c(0,0)) + thesis_theme()

p2 <- ggplot() + 
  geom_point(size = 1, colour = highlight_col) +
  geom_point(data = inputs_GER, aes(x = SunPV, y = WindOn), size = 2, colour = highlight_col_2) +
  geom_point(data = inputs_close_mixed_NED, aes(x = SunPV, y = WindOn), size = 0.2, colour = "black") +
  geom_point(data = inputs_close_mixed_GER, aes(x = SunPV, y = WindOn), size = 2, shape = 17, colour = highlight_col_2) +
  geom_point(data = inputs_close_mixed_NED_44, aes(x = SunPV, y = WindOn), size = 2, shape = 17, colour = highlight_col) +
  geom_point(data = inputs_GER, aes(x = SunPV, y = WindOn), size = 2, colour = highlight_col_2) +
  geom_point(data = inputs_NED, aes(x = SunPV, y = WindOn), size = 2, colour = highlight_col) +
  labs(x = "Wind Onshore", y = "SunPV", title = "Separate clusters without spatial correlation") +
  coord_cartesian(xlim = c(0.1, 0.7), ylim = c(0, 0.75)) + scale_y_continuous(expand = c(0,0)) +
  scale_x_continuous(expand = c(0,0)) + thesis_theme()


p3 <- ggplot() +
  geom_point(data = inputs_close_NED, aes(x = SunPV, y = WindOn), size = 0.2, colour = "black") +
  geom_point(data = inputs_GER, aes(x = SunPV, y = WindOn), size = 2, colour = highlight_col_2)  +
  geom_point(data = inputs_close_GER, aes(x = SunPV, y = WindOn), size = 2, shape = 17, colour = highlight_col_2) +
  geom_point(data = inputs_close_NED_44, aes(x = SunPV, y = WindOn), size = 2, shape = 17, colour = highlight_col) +
  geom_point(data = inputs_GER, aes(x = SunPV, y = WindOn), size = 2, colour = highlight_col_2)+
  geom_point(data = inputs_NED, aes(x = SunPV, y = WindOn), size = 2, colour = highlight_col) +
  labs(x = "Wind Onshore", y = "SunPV", title = "Separate clusters with spatial correlation") +
  coord_cartesian(xlim = c(0.1, 0.7), ylim = c(0, 0.75)) + scale_y_continuous(expand = c(0,0)) +
  scale_x_continuous(expand = c(0,0)) + thesis_theme()

p4 <- ggplot(inputs_NED, aes(x = SunPV, y = WindOn)) + 
  geom_point(size = 2, colour = highlight_col) +
  geom_point(data = inputs_softmax, aes(x = SunPV, y = WindOn), size = 0.2, colour = "black") +
  labs(x = "Wind Onshore", y = "SunPV", title = "Convex") +
  coord_cartesian(xlim = c(0.1, 0.7), ylim = c(0, 0.75)) + scale_y_continuous(expand = c(0,0)) +
  scale_x_continuous(expand = c(0,0)) + thesis_theme()

# Arrange plots in a 2x2 grid
p <- grid.arrange(p4, p1, p3, p2, ncol = 2)
save_plot(p, "C:/Users/kremerlaa/OneDrive - TNO/Documents/gep/Results/availability.pdf", 0.6)

