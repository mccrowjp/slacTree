## Example 4 ##
### Abundances ###

See example 1 for initial creation of slacTree file from newick tree and taxonomic information.

| File | Description |
|------|-------------|
| ex4.st     | slacTree file includes info about the tree, taxa, and annotations |
| ex4.svg    | Scalable Vector Graphics (SVG) drawing of tree |
| ex4.pdf    | PDF version of SVG drawing |
| ex4.magnify.jpg | JPG picture of a small, zoomed in, section of the tree |
| ----------------| ------------|
| ex4.density.svg | SVG drawing of abundance density; references ex4.density.svg.density.jpg |
| ex4.density.svg.density.abund | Abundance values at x,y coordinates used to create density graphic
| ex4.density.svg.density.jpg | JPG picture of abundance density used as the background for the SVG |
| ex4.density.pdf | PDF version of SVG drawing |

Procedure
---------

Annotations are in the slacTree file ex4.st.

Abundance values can be displayed in two ways:
1. Colored circles on nodes.  Allows for multiple datasets to be combined into a single figure with each displayed as a different color.
2. Kernal density plot.  Shows a better view of the combined taxonomic signal when there are many small or overlapping circles in a similar region of the tree.

In this example the same slacTree file (ex4.st) is used for both types of figures.  Those annoations specific to the drawing of colored circles (absize, lega) are ignored when drawing the density plot.

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
lega    0.0035  #000000 0.22    0.24    1
```

The lega annotation draws circles of sizes given by the first value, colored by the second value, at x,y points relative to the size of the entire view given by the next two values.  The final value is a text annotation and can be a size on another scale, or text indicating what colors were used.  See example 5 for multiple colors combined in a single figure.

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
slacTree.pl tree -i ex2.st -o ex2.svg
```

Density
-------

Create SVG drawing from slacTree file:

```bash
slacTree.pl density -i ex2.st -o ex2.svg
```

Command line option -d may also be used to specify the base name of the abundance values file and the background JPG density image that are created as part of the density display.  If this option is not specified, as in the example above, then the output filename or input filename are used, if given.  If using **stdin** and **stdout** then the -d option is required.


SVG files can be viewed in most browsers. The PDF and magnified JPG files were created by printing to a PDF from Firefox browser, and cropping the image in Preview in Mac OSX.
