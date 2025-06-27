transformed <- initial %>%
  mutate(
    availability = availability / demand
  )

transformed_wide <- points_wide %>%
  mutate(
    wind = wind / demand
  ) %>% filter(data == "normalized")

points_wide <- points_wide %>% filter(data == "output")

ggplot(transformed, aes(x= availability, y=demand)) + geom_point() + theme_minimal() + theme(legend.title = element_blank()) +
  coord_cartesian(xlim = c(0, 1.5), ylim = c(0, 1.5)) +
  geom_point(data = transformed_wide %>% filter(num_periods == 40, distance == "CosineDist"), aes(x = wind, y = demand, colour = clustering, shape = clustering), size = 4) + facet_grid(rows = vars(data), cols = vars(clustering))

# Should do it in such a way that
combined_output$data <- "output"
transformed_output$data <- "normalized"
combined_output <- rbind(combined_output, transformed_output)

points_wide <- rbind(points_wide, transformed_wide)

ggplot(combined_output, aes(x = availability, y = demand)) + 
  geom_point() + 
  theme_minimal() + 
  theme(legend.title = element_blank()) + 
  geom_point(data = points_wide %>% filter(num_periods == 4 ,distance == ""), aes(x = wind, y = demand, colour = clustering, shape = clustering), size = 4) + facet_grid(rows = vars(data), cols = vars(clustering))
