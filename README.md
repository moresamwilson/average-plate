# Average Plate

Code from these videos on [YouTube](https://www.youtube.com/shorts/SxD-9AyLftg) and [Instagram](https://www.instagram.com/reel/DVtk1plCjSu) — shared by request.

The R script takes painted plate images, creates binary maps showing where paint is/isn't using a dynamic brightness threshold, and then combines them to create paint probability heatmaps.

## Setup

### Prerequisites
This script uses the `pacman` package manager to automatically manage dependencies. Ensure you have R installed along with the following libraries:

* `tidyverse` (Data manipulation and plotting)
* `magick` (Image processing)
* `khroma` (Colour palettes)
* `patchwork` (Combining heatmaps)

### Directory Structure
Before running the script, update the paths in the **Preamble** section to point to your local directories:
* `input_images_folder`: Directory containing your source images (JPG/JPEG/PNG).
* `output_binaries_folder`: Directory where the generated binary/masked intermediate images will be saved.
* `output_heatmap`: Directory for the final heatmap outputs.

## Usage

1. Place your target plate images into your designated input folder.
2. Open `script_generate_heatmap.R` and adjust the configuration parameters if necessary:
   * `analysis_size`: Resolution to resize input images for processing (default: 1024x1024).
   * `threshold_quantile`: The brightness percentile threshold used to distinguish painted areas from the unpainted background (default: 0.1 or bottom 10%).
3. Run the script. 

The script will sequentially mask each image with a circular crop to isolate the plate surface, evaluate a dynamic local brightness threshold, output a binary representation to your output folder, and ultimately display a 2x2 composite panel comparing different data visualisation colour palettes.

## Notes

### The smoothed rainbow colour palette is not the best choice
Although this is the palette I chose to paint, from a data visualisation standpoint it is the worst option. It uses colour hue to encode value, with non-linear changes in colour intensity. I chose this palette purely because I had to paint a physical plate, and it was an easier gradient to achieve with the paint I had available to me. For more information on why this is bad, see the references below:

Borland D. & Taylor R. M., Rainbow color map (still) considered harmful, *IEEE Comput. Graph. Appl.*, **27**(2), pp. 14 - 7, [https://doi.org/10.1109/MCG.2007.323435](https://doi.org/10.1109/MCG.2007.323435)

Cleveland W. S. & McGill R., Graphical Perception: Theory, Experimentation, and Application to the Development of Graphical Methods, *J. Am. Stat. Assoc.*, **79**(387), pp. 531 - 554, [https://doi.org/10.1080/01621459.1984.10478080](https://doi.org/10.1080/01621459.1984.10478080)

### Downscaling and Pixel Grid Manipulation
Processing high-resolution spatial matrices directly in `ggplot2` via `geom_tile()` can be slow. To keep plotting efficient, the script uses an internal `plot_size` parameter (default: 256x256). After calculating the high-resolution paint probabilities, the script downscales the pixel grid by grouping adjacent pixels using a calculated `scale_factor` and averaging their probabilities. 

### Probability Scale Rescaling
To maximise contrast across the different colour palettes and clearly highlight the relative distribution of the paint, the final probability values are min-max normalised immediately after downscaling. This rescales the probability vector cleanly between a fixed range of 0 and 1:

$$prob = \frac{prob - min(prob)}{max(prob - min(prob))}$$

If you have any questions feel free to reach out on YouTube [@drsamwilson] (https://www.youtube.com/@drsamwilson) or Instagram [@thatsamwilson] (https://www.instagram.com/thatsamwilson). If you use the code for any interesting projects, I'd love to hear about it!
