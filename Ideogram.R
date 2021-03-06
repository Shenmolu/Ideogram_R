
arg<-commandArgs()
library(grid)

canvasWidth<-10
canvasHeight<-7
cw<-0.0225
scaleRate<-1/300000000
dx<-0
dy<-0
dy2<-0.5
ruler<-FALSE

# Read data
print(arg[6])
print(arg[7])
print(arg[8])
cytoBand<-read.table(arg[6], colClasses = c("character", "numeric", "numeric", "character", "NULL"))
karyotype<-read.table(arg[7], colClasses = c("character", "numeric", "numeric", "character"))
outputName<-arg[8]
if (len(arg) > 8) {
  ruler<-arg[9]
  if （ruler == "-r") {
    ruler<-TRUE
  }
}

chromo<-vector()
centro<-vector()
length<-vector()
pArm<-TRUE
lastChrom<-"chr1"
len<-nrow(cytoBand)
chromo<-c(chromo, cytoBand[[1]][1])
for (i in 1:len) {
  # Get centromere location
  if (substr(cytoBand[[4]][i], start=1, stop=1) == "q" && pArm) {
    centro<-c(centro, cytoBand[[2]][i])
    pArm<-FALSE
  }

  # Get length
  if (cytoBand[[1]][i] != lastChrom) {
    length<-c(length, cytoBand[[3]][i-1])
    lastChrom<-cytoBand[[1]][i]
    chromo<-c(chromo, lastChrom)
    pArm<-TRUE
  }
}
length<-c(length, cytoBand[[3]][len])

# Draw
pdf(file=outputName,width=canvasWidth,height=canvasHeight)
vp<-viewport(x=0.5,y=0.5,width=0.9,height=0.95)
pushViewport(vp)

drawChrom<-function(chrom, color) {
  chr<-substr(chrom, start=4, stop=nchar(chrom))
  if (chr == "X") {
    chr<-16
  }
  else if (chr == "Y") {
    chr<-24
  }
  else {
    chr<-strtoi(chr)
    if (chr > 15) {
      chr<-chr+1
    }
  }
  par<-gpar()
  if (color != "") {
    par<-gpar(fill=color)
  }
  i<-which(chromo==chrom)
  cen<-centro[i]
  len<-length[i]
  space<-(1-cw-0.06)/15
  if (chr < 17) {
    grid.roundrect(x=0.03+cw/2+(chr-1)*space,
                   y=0.95,
                   width=cw,
                   height=cen*scaleRate,
                   just="top",
                   r=unit(canvasWidth*1/5, "mm"),
                   gp=par)

    grid.roundrect(x=0.03+cw/2+(chr-1)*space,
                   y=0.95-cen*scaleRate,
                   width=cw,
                   height=(len-cen)*scaleRate,
                   just="top",
                   r=unit(canvasWidth*1/5, "mm"),
                   gp=par)

    tx<-0.03+cw/2+(chr-1)*space
    ty<-0.98

    if (ruler == TRUE) {
      drawRuler(0.03+cw/2+(chr-1)*space, 0.95, len)
    }
  }
  else {
    grid.roundrect(x=0.03+cw/2+(chr-9)*space,
                   y=0.32,
                   width=cw,
                   height=cen*scaleRate,
                   just="top",
                   r=unit(canvasWidth*1/5, "mm"),
                   gp=par)
    grid.roundrect(x=0.03+cw/2+(chr-9)*space,
                   y=0.32-cen*scaleRate,
                   width=cw,
                   height=(len-cen)*scaleRate,
                   just="top",
                   r=unit(canvasWidth*1/5, "mm"),
                   gp=par)
    tx<-0.03+cw/2+(chr-9)*space
    ty<-0.35

    if (ruler == TRUE) {
      drawRuler(0.03+cw/2+(chr-9)*space, 0.32, len)
    }
  }

  if (color == "") {
    grid.text(chrom,x=tx,y=ty,just = "centre",gp=gpar(fontsize=9))
  }
}

drawBand<-function(chrom, start, end, color) {
  chr<-substr(chrom, start=4, stop=nchar(chrom))
  if (chr == "X") {
    chr<-16
  }
  else if (chr == "Y") {
    chr<-24
  }
  else {
    chr<-strtoi(chr)
    if (chr > 15) {
      chr<-chr+1
    }
  }

  if (chr < 17) {
    grid.clip(y=0.95-start*scaleRate,
              height=(end-start)*scaleRate,
              just="top")
  }
  else {
    grid.clip(y=0.32-start*scaleRate,
              height=(end-start)*scaleRate,
              just="top")
  }
  drawChrom(chrom, color)
  grid.clip()
}

drawRuler<-function(x0, y0, length) {
  grid.lines(x=c(x0-cw*7/10, x0-cw*7/10), y=c(y0, y0-length*scaleRate))
  scale<-20000000*scaleRate
  for (i in 0:(length/20000000)) {
    grid.lines(x=c(x0-cw*9/10, x0-cw*7/10), y=c(y0-i*scale, y0-i*scale))
    grid.text(as.character(i*20), x=x0-cw, y=y0-i*scale, just="right", gp=gpar(fontsize=5))
  }
}

for (i in 1:nrow(karyotype)) {
  if(karyotype[[4]][i] == "normal") {
    next
  }
  else if (karyotype[[4]][i] == "duplication" || karyotype[[4]][i] == "gain") {
    color<-"black"
  }
  else if (karyotype[[4]][i] == "deletion" || karyotype[[4]][i] == "loss") {
    color<-"gray"
  }

  drawBand(karyotype[[1]][i], karyotype[[2]][i], karyotype[[3]][i], color)
}

for (i in 1:length(chromo)) {
  drawChrom(chromo[i], "")
}

grid.rect(x=.25,y=.2,width=.015,height=.02,just="left",gp=gpar(fill="black"))
grid.text("duplication/gain",x=.275,y=.2,just="left",gp=gpar(fontsize=14))
grid.rect(x=.25,y=.15,width=.015,height=.02,just="left",gp=gpar(fill="gray"))
grid.text("deletion/loss",x=.275,y=.15,just="left",gp=gpar(fontsize=14))

dev.off()