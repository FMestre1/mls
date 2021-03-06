range_raster <-
function(presences.map, re.out, mask.map=NULL, plot.directions=TRUE)
  {
  if (packageVersion("rgrass7") >= "0.2.1") use_sp()
  
  if(class(re.out) != "expansion") stop(paste(re.out, " should be an object of class class 'expansion'", sep=""), call.=FALSE)
    
	if(!is.null(mask.map))
      {
        execGRASS("r.in.gdal", input=mask.map, output="map.mask", flags=c("overwrite", "o"))
        execGRASS("g.region", raster = "map.mask")
        execGRASS("r.null", map="map.mask", setnull="0")
        execGRASS("r.in.gdal", input=presences.map, output="presences", flags=c("overwrite", "o"))
      } else {
        execGRASS("r.in.gdal", input=presences.map, output="presences", flags=c("overwrite", "o", "e"))
        execGRASS("g.region", raster = "presences")
    }
    execGRASS("r.null", map="presences", setnull="0")
    execGRASS("r.mask", flags="r")
	wrapping <- function(x) strsplit(x, " ")
    extract.value <- function(parameters, cardinal="north")
      {
        agrep(parameters, pattern=cardinal, value=TRUE, max.distance=list(all=0)) -> temp
        wrapping(temp)[[1]] -> result
        as.numeric(result[length(result)]) -> result
        return(result)
      }
    create.vector <- function(in.name="north_horizon", out.name="north_horizon", type="line")
      {
        if(type == "line")
          {
            execGRASS("r.thin", input=in.name, output="tmp2", flags="overwrite")
            execGRASS("r.to.vect", input="tmp2", output=out.name, type=type, flags=c("overwrite"))
            execGRASS("g.remove", type="raster", name="tmp2",flags=c("f"))
          } 
        if(type == "point")
          {
            execGRASS("r.to.vect", input=in.name, output=out.name, type=type, flags=c("overwrite","z"))
          }
      }
    fit.sigmoid <- function(y, x, start.params = list(a = 1, b = 0.5, c = 0))
      {
        fitmodel <- nlsLM(y ~ a / (1 + exp(b * (x - c))), start = start.params)
        return(coef(fitmodel))
      }
    predict.sigmoid <- function(params, x)
      {
        return(params[1] / (1 + exp(params[2] * (x - params[3]))))
      }

    execGRASS("g.region", flags="p",intern=T) -> region.parameters
    extract.value(region.parameters, cardinal="north") -> north
    extract.value(region.parameters, cardinal="south") -> south
    extract.value(region.parameters, cardinal="east") -> east
    extract.value(region.parameters, cardinal="west") -> west
    extract.value(region.parameters, cardinal="nsres") -> nsres
    extract.value(region.parameters, cardinal="ewres") -> ewres

    execGRASS("r.mapcalc", expression=paste("north_horizon=y() > ", north-nsres, sep=""), flags="overwrite")
    execGRASS("r.null", map="north_horizon", setnull="0")
    create.vector(in.name="north_horizon", out.name="north_horizon")
    
    execGRASS("r.mapcalc", expression=paste("south_horizon=y() < ", south + nsres, sep=""), flags="overwrite")
    execGRASS("r.null", map="south_horizon", setnull="0")
    create.vector(in.name="south_horizon", out.name="south_horizon")

    execGRASS("r.mapcalc", expression=paste("west_horizon=x() < ", west+ewres, sep=""), flags="overwrite")
    execGRASS("r.null", map="west_horizon", setnull="0")
    create.vector(in.name="west_horizon", out.name="west_horizon")

    execGRASS("r.mapcalc", expression=paste("east_horizon=x() > ", east-ewres, sep=""), flags="overwrite")
    execGRASS("r.null", map="east_horizon", setnull="0")
    create.vector(in.name="east_horizon", out.name="east_horizon")

    execGRASS("r.mapcalc", expression=paste("wdns=",nsres,"/1000",sep=""), flags="overwrite")
    execGRASS("r.mapcalc", expression=paste("wdew=",ewres,"/1000",sep=""), flags="overwrite")

    create.vector(in.name="presences", out.name="presences", type="point")

	execGRASS("r.grow.distance", input = "presences", distance = "tempdir", flags = c("overwrite","m"))
	
	execGRASS("r.mapcalc", expression = "tempdir2 = tempdir/1000", flags = "overwrite")

    execGRASS("r.cost", input="wdns", output="temptrend", start_raster="north_horizon", flags="overwrite")
    execGRASS("r.mapcalc", expression="tempout = temptrend + tempdir2", flags="overwrite")
    execGRASS("r.univar", map="tempout", intern=T) -> map.stats
    extract.value(map.stats,"minimum") -> minimum.map
    extract.value(map.stats,"maximum") -> maximum.map
    execGRASS("r.mapcalc", expression=paste("Ndirectionality = 100 - ((tempout - ", minimum.map, ") * 100 / ", maximum.map-minimum.map, ")", sep=""),flags="overwrite")

    execGRASS("r.cost", input="wdns", output="temptrend", start_raster="south_horizon", flags="overwrite")
    execGRASS("r.mapcalc", expression="tempout = temptrend + tempdir2", flags="overwrite")
    execGRASS("r.univar", map="tempout", intern=T) -> map.stats
    extract.value(map.stats,"minimum") -> minimum.map
    extract.value(map.stats,"maximum") -> maximum.map
    execGRASS("r.mapcalc", expression=paste("Sdirectionality = 100 - ((tempout - ", minimum.map, ") * 100 / ", maximum.map-minimum.map, ")", sep=""),flags="overwrite")

    execGRASS("r.cost", input="wdew", output="temptrend", start_raster="east_horizon", flags="overwrite")
    execGRASS("r.mapcalc", expression="tempout = temptrend + tempdir2", flags="overwrite")
    execGRASS("r.univar", map="tempout", intern=T) -> map.stats
    extract.value(map.stats,"minimum") -> minimum.map
    extract.value(map.stats,"maximum") -> maximum.map
    execGRASS("r.mapcalc", expression=paste("Edirectionality = 100 - ((tempout - ", minimum.map, ") * 100 / ", maximum.map-minimum.map, ")", sep=""),flags="overwrite")

    execGRASS("r.cost", input="wdew", output="temptrend", start_raster="west_horizon", flags="overwrite")
    execGRASS("r.mapcalc", expression="tempout = temptrend + tempdir2", flags="overwrite")
    execGRASS("r.univar", map="tempout", intern=T) -> map.stats
    extract.value(map.stats,"minimum") -> minimum.map
    extract.value(map.stats,"maximum") -> maximum.map
    execGRASS("r.mapcalc", expression=paste("Wdirectionality = 100 - ((tempout - ", minimum.map, ") * 100 / ", maximum.map-minimum.map, ")", sep=""),flags="overwrite")

    execGRASS("g.remove", type="raster", name="temptrend,tempout",flags=c("f"))
    params.n <- fit.sigmoid(re.out$NORTH$PROPORTION, re.out$NORTH$DISTANCE/1000)
    params.s <- fit.sigmoid(re.out$SOUTH$PROPORTION, re.out$SOUTH$DISTANCE/1000)
    params.e <- fit.sigmoid(re.out$EAST$PROPORTION, re.out$EAST$DISTANCE/1000)
    params.w <- fit.sigmoid(re.out$WEST$PROPORTION, re.out$WEST$DISTANCE/1000)

    if(!is.null(mask.map))
      {
        execGRASS("r.mask", raster="map.mask")
      }

    execGRASS("r.mapcalc", expression=paste("Nprobability = Ndirectionality * (", params.n[1]," / (1 + exp(", params.n[2]," * (tempdir2 - ", params.n[3],"))))", sep=""),
              flags=c("overwrite"))
    execGRASS("r.mapcalc", expression=paste("Sprobability = Sdirectionality * (", params.s[1]," / (1 + exp(", params.s[2]," * (tempdir2 - ", params.s[3],"))))", sep=""),
              flags=c("overwrite"))
    execGRASS("r.mapcalc", expression=paste("Eprobability = Edirectionality * (", params.e[1]," / (1 + exp(", params.e[2]," * (tempdir2 - ", params.e[3],"))))", sep=""),
              flags=c("overwrite"))
    execGRASS("r.mapcalc", expression=paste("Wprobability = Wdirectionality * (", params.w[1]," / (1 + exp(", params.w[2]," * (tempdir2 - ", params.w[3],"))))", sep=""),
              flags=c("overwrite"))
    execGRASS("r.mapcalc", expression="range = (Nprobability + Sprobability + Eprobability + Wprobability)/4",flags=c("overwrite"))

    output <- raster(readRAST("range"))
	
    N1 <- re.out$NORTH[re.out$NORTH[, 2] != 0, ]
    N1$DISTANCE <- N1$DISTANCE / nsres
    S1 <- re.out$SOUTH[re.out$SOUTH[, 2] != 0, ]
    S1$DISTANCE <- S1$DISTANCE / nsres
    E1 <- re.out$EAST[re.out$EAST[, 2] != 0, ]
    E1$DISTANCE <- E1$DISTANCE / ewres
    W1 <- re.out$WEST[re.out$WEST[, 2] != 0, ]
    W1$DISTANCE <- W1$DISTANCE / ewres
	
    Time_series <- data.frame(DISTANCE = c(N1[, 1], S1[, 1], E1[, 1], W1[, 1]))
    Time_series$GENERATIONS <- c(N1[, 4], S1[, 4], E1[, 4], W1[, 4])
    fittedTS <- glm(GENERATIONS ~ DISTANCE, data = Time_series)
    message("Fitting the dispersal model to the species occurences. Building time step raster.")
    execGRASS("r.mapcalc", expression = paste("Generations = ",coefficients(fittedTS)[1], " + (", coefficients(fittedTS)[2], " * tempdir2)",sep = ""), flags = c("overwrite"))
	output_TS <- raster(readRAST("Generations"))	
		
    if(plot.directions == TRUE)
      {
         dev.new()
        par(mfrow=c(1,2))
        plot(re.out$NORTH$DISTANCE, re.out$NORTH$PROPORTION,
             main="Northern direction", xlab="Distance (m)", ylab="Probability")        
        lines(re.out$NORTH$DISTANCE, predict.sigmoid(params.n, re.out$NORTH$DISTANCE/1000))
        image(raster(readRAST("Nprobability")),main="Northern probability")
        contour(raster(readRAST("Nprobability")), add=T)
        dev.new()
        par(mfrow=c(1,2))
        plot(re.out$SOUTH$DISTANCE, re.out$SOUTH$PROPORTION,
             main="Southern direction", xlab="Distance (m)", ylab="Probability")        
        lines(re.out$SOUTH$DISTANCE, predict.sigmoid(params.s, re.out$SOUTH$DISTANCE/1000))
        image(raster(readRAST("Sprobability")),main="Southern probability")
        contour(raster(readRAST("Sprobability")), add=T)
        dev.new()
        par(mfrow=c(1,2))
        plot(re.out$EAST$DISTANCE, re.out$EAST$PROPORTION,
             main="Eastern direction", xlab="Distance (m)", ylab="Probability")        
        lines(re.out$EAST$DISTANCE, predict.sigmoid(params.e, re.out$EAST$DISTANCE/1000))
        image(raster(readRAST("Eprobability")),main="Eastern probability")
        contour(raster(readRAST("Eprobability")), add=T)
        dev.new()
        par(mfrow=c(1,2))
        plot(re.out$WEST$DISTANCE, re.out$WEST$PROPORTION,
             main="Western direction", xlab="Distance (m)", ylab="Probability")        
        lines(re.out$WEST$DISTANCE, predict.sigmoid(params.w, re.out$WEST$DISTANCE/1000))
        image(raster(readRAST("Wprobability")),main="Western probability")
        contour(raster(readRAST("Wprobability")), add=T)
      }
    vect.list <- execGRASS("g.list", type="vector", separator=",", intern=TRUE)
    rast.list <- execGRASS("g.list", type="raster", separator=",", intern=TRUE)
    if(!is.null(mask.map))
      {
        execGRASS("r.mask", flags="r")
      }
    execGRASS("g.remove", type="raster", name=rast.list,flags=c("f"))
    execGRASS("g.remove", type="vector", name=vect.list,flags=c("f"))
    out1 <- stack(output, output_TS)
    names(out1) <- c("PROB", "TSTEP")
    message("Writing dispersal model rasters.")
    writeRaster(output, filename = "PROB", format = "GTiff", 
        overwrite = TRUE)
    writeRaster(output_TS, filename = "TSTEP", format = "GTiff", 
        overwrite = TRUE)
    return(out1)
}
