## Example 2 ##
### Highlighting Taxonomic Groups ###

See [example 1](../ex1_simple) for initial creation of slacTree file from newick tree and taxonomic information.

| File | Description |
|------|-------------|
| ex2.st     | slacTree file includes info about the tree, taxa, and annotations |
| ex2.svg    | Scalable Vector Graphics (SVG) drawing of tree |
| ex2.pdf    | PDF version of SVG drawing |
| ex2.magnify.jpg | JPG picture of a small, zoomed in, section of the tree |

Procedure
---------

Annotations are in the slacTree file ex2.st.

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

The htax annotation highlights any taxa with a taxonomic string beginning with the substring given, and uses the color from the third column of the annotation.

Add a legend for the branch lengths:

```
leg     0.1     0.1     0.1
```

The leg annotation adds the first length given as a line and as text, and places it at relative x,y position from the next two values given.  The x and y values are [0-1] values relative to the entire view starting at the upper-left corner.

Add a legend for the taxonomic highlights:

```
legh    Actinobacteria  #000000 #DDFFFF
legh    Bacteroidetes/Chlorobigroup     #000000 #FFFFDD
legh    Cyanobacteria   #000000 #DDFFDD
legh    Firmicutes      #000000 #FFDDDD
legh    Alphaproteobacteria     #000000 #DDDDFF
legh    Betaproteobacteria      #000000 #9999FF
legh    Gammaproteobacteria     #000000 #DDDDFF
legh    Deltaproteobacteria     #000000 #9999FF
legh    Epsilonproteobacteria   #000000 #DDDDFF
```
The legh annotation adds rows below the leg annotation for each taxonomic group color.  If no branch length legend is needed, you may still change the x,y location of the legend by specifying the x,y relative values and leaving the first value of the leg annotation as 0.


Create SVG drawing from slacTree file:

```bash
slacTree.pl tree -i ex2.st -o ex2.svg
```

SVG files can be viewed in most browsers. The PDF and magnified JPG files were created by printing to a PDF from Firefox browser, and cropping the image in Preview in Mac OSX.
