#!/usr/bin/env Rscript
#
# 2D kernal density plot, for use in:
# slacTree - SVG Large Annotated Circular Tree drawing program
#
# Original version: 6/16/2009 John P. McCrow (jmccrow [at] jcvi.org)
# J. Craig Venter Institute (JCVI)
# La Jolla, CA USA
#

args <- commandArgs(TRUE)
infile = paste("", args[1], sep="")
outfile = paste("", args[2], sep="")
invw = paste("", args[3], sep="")
invh = paste("", args[4], sep="")
inzl = paste("", args[5], sep="")

if(invw == 'NA') {
    viewwidth = 30000
} else {
    viewwidth = as.numeric(invw)
}
if(invh == 'NA') {
    viewheight = 30000
} else {
    viewheight = as.numeric(invh)
}

library(MASS)

imgres = 500
zres = 100

if(infile == 'NA' || outfile == 'NA') {
    warning("Usage: make_density_jpg.r [2D data file] [output file] [viewwidth] [viewheight] [zlim]\n(Use 'zlim' as output file to print zlim value instead of creating jpg image)")
    
} else {
    dat = read.table(file=infile, header=T)
    
    # scale abundance values to number of x,y points
    maxz = max(dat[,4])
    newz = round(zres * dat[,4] / maxz)
    x = rep(dat[1,2], newz[1])
    y = rep(dat[1,3], newz[1])
    for(i in 2:nrow(dat)) {
        x = c(x, rep(dat[i,2], newz[i]))
        y = c(y, rep(dat[i,3], newz[i]))
    }
    
    kd=kde2d(x, viewheight-y, n=imgres, lims=c(0,viewwidth,0,viewheight), h=c(2000,2000))

    if(outfile == 'zlim') {
        max(sqrt(kd$z))
    } else {
        if(inzl == 'NA') {
            zl = max(sqrt(kd$z))
        } else {
            zl = as.numeric(inzl)
        }

        jpeg(filename=outfile, width=imgres, height=imgres, quality=100)
            RGBcolorpal1=hsv(1/(1+exp(seq(-3.8,3.8,length=1000))),1,1)[300:1000]
            par(mar=c(0,0,0,0))
            image(kd$x, kd$y, sqrt(kd$z), col=RGBcolorpal1[150:700], zlim=c(0,zl))
        dev.off()
    }
}
