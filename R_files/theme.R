# Load necessary libraries
library(ggplot2)

# Define thesis theme
thesis_theme <- function() {
  font <- "sans"
  
  theme_bw() %+replace%
    theme(
      plot.title = element_text(             
        family = font,            
        size = 8,                
        face = 'bold',            
        hjust = 0,                
        vjust = 4),               
      
      axis.title = element_text(
        family = font,            
        size = 8),
      
      axis.text = element_text(              
        family = font,           
        size = 6),               
      
      axis.text.x = element_text(            
        margin = margin(5, b = 5)),
      
      plot.margin = margin(t = 20, r = 10, b = 10, l = 10),
      
      legend.title = element_text(
        family = font, 
        size = 8), 
      
      legend.text = element_text(
        family = font, 
        size = 6),
      # Customize grid line thickness (thinner grid lines)
      panel.border = element_rect(linewidth = 0.1, fill = NA),  # Adjust border thickness
      panel.grid.major = element_line(linewidth = 0.02),  # Adjust major grid line thickness
      panel.grid.minor = element_line(linewidth = 0.02),  # Adjust minor grid line thickness
      panel.grid.major.x = element_line(linewidth = 0.02),  # Adjust major grid line thickness for x axis
      panel.grid.minor.x = element_line(linewidth = 0.02),  # Adjust minor grid line thickness for x axis
      panel.grid.major.y = element_line(linewidth = 0.02),  # Adjust major grid line thickness for y axis
      panel.grid.minor.y = element_line(linewidth = 0.02),  # Adjust minor grid line thickness for y axis
      
      panel.spacing.x = unit(0, "cm"),  # Horizontal spacing between facets
      legend.box.margin = margin(0, 0, 0, 0),
      legend.margin = margin(0, 0, 0, 0),
    
      strip.text.y = element_text(family = font, size = 6, angle = -90, margin = margin(l = 5, r = 5)),  # Vertical text and adjusted margin
      strip.text.x = element_text(family = font, size = 6, angle = 0, margin = margin(b = 5, t = 5)),  # Horizontal text for vertical strips
      
      # Remove the background for facet label boxes
      strip.background = element_rect(fill = NA, color = "black", linewidth = 0.1) )  # Adjust margins
      
      # Optional: Increase facet box size to fit text better

}

# Get colors from the R palette
options <- palette.colors(palette = "R4")

# Define a color mapping for clustering groups
my_colors <- c(
  "k_means" = options[2],    
  "k_medoids" = options[3],  
  "convex_hull" = options[4],
  "extreme1" = options[5],
  "blended" = options[6],
  "conical_hull" = options[1],
  "conical_bounded" = options[1],
  "triangle_k_means" = options[8],
  "triangle_k_medoids" = options[1]
)

# Set aesthetics
my_labels <- c(
  "convex_hull" = "Greedy convex hull",
  "k_means" = "K-means",
  "k_medoids" = "K-medoids",
  "conical_hull" = "Greedy bounded conical hull",
  "conical_bounded" = "Greedy bounded conical hull",
  "extreme1" = "Worst-case period",
  "blended" = "Worst-case + blended"
)

my_linetypes <- c(
  "convex_hull" = "solid",
  "k_means" = "dashed",
  "k_medoids" = "dotted",
  "conical_hull" = "dotdash",
  "extreme1" = "solid",
  "blended" = "solid"
)

# Function to save plots with specific dimensions
save_plot <- function(plot, filename, ratio) {
  # Convert points to inches
  width_in_inches <- 481.87546 / 72.27
  height <- width_in_inches * ratio
  
  # Save the plot with the specified dimensions
  ggsave(filename, plot = plot, width = width_in_inches, height = height, units = "in")
}

# Function to save plots with specific dimensions
save_plot_2d <- function(plot, filename, ratio, width) {
  # Convert points to inches
  width_in_inches <- width * 481.87546 / 72.27
  height <- width_in_inches * ratio
  
  # Save the plot with the specified dimensions
  ggsave(filename, plot = plot, width = width_in_inches, height = height, units = "in")
}
