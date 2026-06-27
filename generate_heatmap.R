# Preamble. ----

# Check the associated README.md for more information. Code created by Sam
# Wilson. If you have any questions feel free to reach out on YouTube
# (@drsamwilson) or Instagram (@thatsamwilson). If you use the code for any
# interesting projects, I'd love to hear about it!

# Load packages.
pacman::p_load(
  tidyverse, # General
  magick, # Image processing
  khroma, # Colour palettes
  patchwork # Combining heatmaps
)

# File paths.
input_images_folder <- "/input_folder"
output_binaries_folder <- "/output_folder"
output_heatmap <- "/output_heatmaps"

# Parameters.
analysis_size <- 1024
plot_size <- 256
threshold_quantile <- 0.1
crop_pad <- round(analysis_size/50, digits = 0)

# Analysis. ----

# Image size.
image_size <- paste0(as.character(analysis_size), "x", as.character(analysis_size))

# Get list of image files (JPG/PNG) in input folder.
image_files <- list.files(input_images_folder, pattern = "\\.(jpg|jpeg|png)$", full.names = TRUE)

# Initialise matrix to sum binary matrices.
ii_min <- analysis_size
sum_matrix <- matrix(0, nrow = ii_min, ncol = ii_min)
image_count <- 0

# Process each image.
for (input in image_files) {
  
  # Read and resize image.
  img <- image_resize(image_read(input), image_size)
  
  # Get height and width.
  ii <- magick::image_info(img)
  ii_min <- min(ii$width, ii$height)
  
  # Create a new image with white background and black circle (to use as mask).
  mask <- magick::image_draw(image_blank(ii_min, ii_min))
  symbols(ii_min/2, ii_min/2, circles=(ii_min/2)-crop_pad, bg='black', inches=FALSE, add=TRUE)
  dev.off()
  
  # Create an image composite using both images (mask the image).
  img_masked <- magick::image_composite(img, mask, operator='copyopacity')
  
  # Fill transparent background with white.
  img_final <- magick::image_background(img_masked, 'white')
  
  # Convert to RGB array (0 to 1 scale).
  img_array <- as.numeric(image_data(img_final, channels = "rgb"))
  dim(img_array) <- c(ii_min, ii_min, 3)
  
  # Calculate brightness (mean of R, G, B).
  brightness <- rowMeans(img_array, dims = 2)
  
  # Dynamic threshold: 15th percentile (change in parameters if needed).
  threshold <- quantile(brightness, threshold_quantile)
    cat("Image:", basename(input), "Threshold:", threshold, "\n")
    
  # Create binary matrix: 1 for painted (below threshold), 0 for unpainted (above threhsold).
  binary <- matrix(as.numeric(brightness < threshold), nrow = ii_min, ncol = ii_min)
  
  # Save binary images.
  binary_array <- array(rep(1 - binary, 3), dim = c(ii_min, ii_min, 3))  # Invert binary: 1 -> 0, 0 -> 1
  binary_img <- image_read(binary_array * 255, "rgb")
  output_path <- file.path(output_binaries_folder, paste0(tools::file_path_sans_ext(basename(input)), "_binary.png"))
  image_write(binary_img, path = output_path, format = "png")
  
  # Add to sum matrix.
  sum_matrix <- sum_matrix + binary
  image_count <- image_count + 1
}


# Compute average matrix (probability of paint).
if (image_count > 0) {
  prob_matrix <- sum_matrix / image_count
} else {
  stop("No images processed.")
}

# Create heatmap. ----

heatmap_data <- expand.grid(x = 1:ii_min, y = 1:ii_min)
prob_matrix_flip <- prob_matrix[nrow(prob_matrix):1, ]  # flip vertically
heatmap_data$prob <- as.vector(t(prob_matrix_flip))     # transpose and flatten

# Downscale.
scale_factor <- ii_min / plot_size

heatmap_data <- heatmap_data %>%
  mutate(x = ceiling(x / scale_factor),
         y = ceiling(y / scale_factor)) %>%
  group_by(x, y) %>%
  summarise(prob = mean(prob), .groups = "drop") |> 
  mutate(prob = (prob - min(prob)) / (max(prob) - min(prob)))

# Create heatmaps with different colour palettes to see what works best.

# Iridescent.
heatmap_ir <- ggplot(heatmap_data, aes(x = x, y = y, fill = prob)) +
  geom_tile() +
  scale_fill_iridescent(
    limits = c(0, 1),
    name = "Paint probability",
    breaks = c(0, 0.5, 1),
  ) +
  coord_fixed() +
  theme_void() +
  theme(
    legend.position = "top",
    plot.background = element_rect(fill = "white", colour = NA),
    legend.title = element_text(margin = margin(r = 15))
    ) 

heatmap_ir

# Smooth rainbow.
heatmap_sm <- ggplot(heatmap_data, aes(x = x, y = y, fill = prob)) +
  geom_tile() +
  scale_fill_smoothrainbow(
      limits = c(0, 1),
    name = "Paint probability",
    breaks = c(0, 0.5, 1)
  ) +
  coord_fixed() +
  theme_void() +
  theme(
    legend.position = "top",
    plot.background = element_rect(fill = "white", colour = NA),
    legend.title = element_text(margin = margin(r = 15))
  ) 

heatmap_sm

# NOTE: Not the best option for data visualisation - colour intensity does not
# increase uniformly. The other options are better, I chose this palette because
# I had to paint a plate and it was an easier gradient to achieve with the paint
# I available to me.

# Black and white. 
heatmap_bw <- ggplot(heatmap_data, aes(x = x, y = y, fill = prob)) +
  geom_tile() +
  scale_fill_gradientn(
    colors = c("white", "black"),
    limits = c(0, 1),
    name = "Paint probability",
    breaks = c(0, 0.5, 1)) +
  coord_fixed() +
  theme_void() +
  theme(
    legend.position = "top",
    plot.background = element_rect(fill = "white", colour = NA),
    legend.title = element_text(margin = margin(r = 15))
  ) 

heatmap_bw

# Sunset (diverging).
heatmap_br <- ggplot(heatmap_data, aes(x = x, y = y, fill = prob)) +
  geom_tile() +
  scale_fill_sunset(
    midpoint = 0.5,
    limits = c(0, 1), 
    name = "Paint probability",
    breaks = c(0, 0.5, 1)) +
  coord_fixed() +
  theme_void() +
  theme(
    legend.position = "top",
    plot.background = element_rect(fill = "white", colour = NA),
    legend.title = element_text(margin = margin(r = 15))
  ) 

heatmap_br


# Viridis.
heatmap_vir <- ggplot(heatmap_data, aes(x = x, y = y, fill = prob)) +
  geom_tile() +
  viridis::scale_fill_viridis(
    option = "B",
    direction = -1,
    limits = c(0, 1), 
    name = "Paint probability",
    breaks = c(0, 0.5, 1)) +
  coord_fixed() +
  theme_void() +
  theme(
    legend.position = "top",
    plot.background = element_rect(fill = "white", colour = NA),
    legend.title = element_text(margin = margin(r = 15))
  ) 

heatmap_vir

# Create combined heatmap with different colour options.
heatmap <- (heatmap_bw + heatmap_ir) / (heatmap_sm + heatmap_vir)

heatmap


