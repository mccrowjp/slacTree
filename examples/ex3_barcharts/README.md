## Example 3 ##
### Bar Charts ###

See [example 1](../ex1_simple) for initial creation of slacTree file from newick tree and taxonomic information.

| File | Description |
|------|-------------|
| ex3.st     | slacTree file includes info about the tree, taxa, and annotations |
| ex3.svg    | Scalable Vector Graphics (SVG) drawing of tree |
| ex3.pdf    | PDF version of SVG drawing |
| ex3.magnify.jpg | JPG picture of a small, zoomed in, section of the tree |

Procedure
---------

Annotations are in the slacTree file ex3.st.

Reduce the relative size of the tree to accomodate two extra levels of data:

```
plot    0.1     0       0.7     #000000
```

The `0.7` is the tree zoom parameter and indicates that we want to shrink the tree to 70% of the normal size so the two rings of bar charts will fit properly.

Show a subset of the tree:

```
rootn   59
```

The rootn annotation displays only the subset of the tree below node ID 59.  Use this annotation to quickly subset the tree without reworking the entire slacTree file.

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

Create SVG drawing from slacTree file:

```bash
slacTree.pl tree -i ex3.st -o ex3.svg
```

SVG files can be viewed in most browsers. The PDF and magnified JPG files were created by printing to a PDF from Firefox browser, and cropping the image in Preview in Mac OSX.
