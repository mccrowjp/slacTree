## Example 5 ##
### Multiple Dataset Abundances ###

See [example 1](../ex1_simple) for initial creation of slacTree file from newick tree and taxonomic information.

| File | Description |
|------|-------------|
| ex5_combined.st     | slacTree file includes info about the tree, taxa, and annotations |
| ex5_combined.svg    | Scalable Vector Graphics (SVG) drawing of tree |
| ex5_combined.pdf    | PDF version of SVG drawing |
|  |  |
| ex5_sample1.st  | slacTree file with abundance values for sample1
| ex5_sample1.svg | SVG drawing of abundance density; references ex5_sample1.svg.density.jpg |
| ex5_sample1.svg.density.abund | Abundance values at x,y coordinates used to create density graphic
| ex5_sample1.svg.density.jpg | JPG picture of abundance density used as the background for the SVG |
| ex5_sample1.pdf | PDF version of SVG density figure |
|  |  |
| ex5_sample2.st  | slacTree file with abundance values for sample2
| ex5_sample2.svg | SVG drawing of abundance density; references ex5_sample2.svg.density.jpg |
| ex5_sample2.svg.density.abund | Abundance values at x,y coordinates used to create density graphic
| ex5_sample2.svg.density.jpg | JPG picture of abundance density used as the background for the SVG |
| ex5_sample2.pdf | PDF version of SVG density figure |
|  |  |
| ex5_sample3.st  | slacTree file with abundance values for sample3
| ex5_sample3.svg | SVG drawing of abundance density; references ex5_sample3.svg.density.jpg |
| ex5_sample3.svg.density.abund | Abundance values at x,y coordinates used to create density graphic
| ex5_sample3.svg.density.jpg | JPG picture of abundance density used as the background for the SVG |
| ex5_sample3.pdf | PDF version of SVG density figure |
|  |  |
| ex5_density_figure.jpg | Combined small multiples figure of density plots |

Procedure
---------

Annotations are in the slacTree files ex5_combined.st, ex5_sample1.st, ex5_sample2.st, ex5_sample3.st

Abundance values can be displayed in two ways:

1. Colored circles on nodes.  Allows for multiple datasets to be combined into a single figure with each displayed as a different color.
2. Kernal density plot.  Shows a better view of the combined taxonomic signal when there are many small or overlapping circles in a similar region of the tree.

In this example there are three datasets with separate abundance values in each of the slacTree files (ex5_sample1.st, ex5_sample2.st, ex5_sample3.st) used for creating density plots, as well as a single file (ex5_combined.st) with all three datasets combined for creating an aggregated display of abundance colored circles.

Add taxonomic highlighting annotations:

```
htax    Bacteria;Bacteroidetes/Chlorobigroup    #FFFFDD
htax    Bacteria;Firmicutes     #FFDDDD
htax    Bacteria;Proteobacteria;Delta   #9999FF
htax    Bacteria;Proteobacteria;Epsilon #DDDDFF
htax    Bacteria;Proteobacteria;Alpha   #DDDDFF
htax    Bacteria;Proteobacteria;Beta    #9999FF
htax    Bacteria;Proteobacteria;Gamma   #DDDDFF
htax    Bacteria;Actinobacteria #DDFFFF
htax    Bacteria;Cyanobacteria  #DDFFDD
```

Calibrate abundance circle sizes:

```
absize  30
```

The absize annotation sets a relative multiple for scaling the size of the circles by the range of abundance values.

Add a legend for abundance circle sizes:

```
lega    0.35    #000000 0.22    0.14    100
lega    0.035   #000000 0.22    0.19    10
```

Add a legend for abundance circle colors:

```
lega    0.25    #FF0000 0.22    0.1     0.1-0.8
lega    0.25    #00FF00 0.22    0.15    0.8-3.0
lega    0.25    #0000FF 0.22    0.20    >3.0
```

The lega annotation draws circles of sizes given by the first value, colored by the second value, at x,y points relative to the size of the entire view given by the next two values.  The final value is a text annotation and can be a size on another scale, or text indicating what colors were used.  In this example we also use multiple colors and provide a legend describing each.

Add abundance values:

```
abund   10      0.000565        #FF0000
...
```

The abund annotation sets each abundance value at a node and gives a color for the circle drawn.  The first value is the node ID, followed by the abundance, and then by the color.  The abundance can be scaled as desired, but the corresponding size of circles is governed by the scaling factor set in absize annotation.

Circles
-------

Create SVG drawing from slacTree file:

```bash
slacTree.pl tree -i ex5_combined.st -o ex5_combined.svg
```

Density
-------

Create SVG drawings from slacTree file:

```bash
slacTree.pl density -i ex5_sample1.st -o ex5_sample1.svg
slacTree.pl density -i ex5_sample2.st -o ex5_sample2.svg
slacTree.pl density -i ex5_sample3.st -o ex5_sample3.svg
```

Command line option -d may also be used to specify the base name of the abundance values file and the background JPG density image that are created as part of the density display.  If this option is not specified, as in the example above, then the output filename or input filename are used, if given.  If using **stdin** and **stdout** then the -d option is required.

Scaling multiple plots
----------------------

When producing multiple density plots, each plot is rescaled to the maximum density of each single plot, by default.  To draw all plots on the same scale, first determine the maximum density (zlim):

```
slacTree.pl zlim -i ex5_sample1.st
  0.0005202215
slacTree.pl zlim -i ex5_sample2.st
  0.0004459801
slacTree.pl zlim -i ex5_sample3.st
  0.000384656
```

Then use the maximum zlim from all three to scale each plot, instead of rescaling each individually:


```bash
slacTree.pl density -i ex5_sample1.st -o ex5_sample1.svg -z 0.0005202215
slacTree.pl density -i ex5_sample2.st -o ex5_sample2.svg -z 0.0005202215
slacTree.pl density -i ex5_sample3.st -o ex5_sample3.svg -z 0.0005202215
```

This produces the three SVG drawings with the densities all on the same scale.

Small-multiples
---------------

A summary figure is given as an example `ex5_density_figure.jpg` from the three density plots.


SVG files can be viewed in most browsers. The PDF files were created by printing to a PDF from Firefox browser, and the small-multiples JPG figure was created in Powerpoint by inserting each of the three density PDFs.

