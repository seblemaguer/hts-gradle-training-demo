library('ggplot2')
library("reshape2")

# read command line arguments
args <- commandArgs(trailingOnly = TRUE)

data <- read.table(args[1], header=TRUE, sep="\t")
field <- args[2]

data <- data[data$coil==field,]

outputName <- args[3]

gg_color_hue <- function(n) {
    hues = seq(15, 375, length=n+1)
    hcl(h=hues, l=65, c=100)[1:n]
}

plotColors = gg_color_hue(2)

# Create the error plot.
fieldplot <- ggplot(data=data, aes(x=id_frame, y=value, group=type, colour=type)) +
    geom_line() +
    xlab("Time frame") + ylab(field) +
    facet_grid(axis ~ .)  +
    scale_y_continuous()

#increase size of gridlines
fieldplot <- fieldplot +
    theme(panel.grid.major = element_line(size = .5, color = "grey"),
                                        #increase size of axis lines
          axis.line = element_line(size=.7, color = "black"),
                                        #Adjust legend position to maximize space, use a vector of proportion
                                        #across the plot and up the plot where you want the legend.
                                        #You can also use "left", "right", "top", "bottom", for legends on t
                                        #he side of the plot
          legend.text = element_text(size=9),
                                        #increase the font size
          text = element_text(size=9))

# svg(file = outputName, width= 4.5, height = 5)
pdf(file = outputName, width = 8, height = 6)

# Generate the CDF.
fieldplot

invisible(dev.off())
