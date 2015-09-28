## Example 1 ##
### Simple circular tree of ~1800 taxa ###

| File | Description |
|------|-------------|
| ex1.newick | Newick tree with numbered taxa |
| ex1.tax    | Taxonomic information including full taxa names, and taxonomy relationships |
| ex1.st     | slacTree file includes info about the tree, taxa, and annotations |
| ex1.svg    | Scalable Vector Graphics (SVG) drawing of tree |
| ex1.pdf    | PDF version of SVG drawing |
| ex1.magnify.jpg | JPG picture of small section of tree, zoomed in |

#### Procedure ####

1. Convert tree and taxonomy information into annotatable slacTree format:

slacTree.pl newick2st -i ex1.newick -t ex1.tax -o ex1.st

Default drawing parameters and comments indicating how to add annotations are added initially to the slacTree file

2. Create SVG drawing from slacTree file:

slacTree.pl tree -i ex1.st -o ex1.svg

The PDF and magnified JPG files were created by printing to a PDF from Firefox browser, and cropping the image in Preview in Mac OSX.
