\name{import.shape}
\alias{import.shape}
\title{
Import a shapefile
}
\description{
Imports a shapefile, converting it to an object of class 'metapopulation' or 'landscape'.
}
\usage{
import.shape(filename, path, species.col, ID.col, area.col, dispersal, 
class.landscape=FALSE)
}
\arguments{
  \item{filename}{
Character vector with the shapefile name.
}
  \item{path}{
Character vector with the path to the file.
}
  \item{species.col}{
Character vector with the name of the column (in the shapefile) with the species occupancy data.
}
  \item{ID.col}{
Character vector with the name of the column (in the shapefile) with the patch Id.
}
  \item{area.col}{
Character vector with the name of the column (in the shapefile) with the patch area, in hectares.
}
  \item{dispersal}{
Species mean dispersal ability, in meters.
}
  \item{class.landscape}{
Should the output belong to the class 'metapopulation' or 'landscape'.
}
}
\value{
Delivers an object of class 'metapopulation' or 'landscape'.
}
\author{
Frederico Mestre and Fernando Canovas 
}
\note{
The shapefile must be in project coordinates (units=meters and hectares).
}
\seealso{
\code{\link{rland.graph}}, \code{\link{convert.graph}}
}
\examples{

\dontrun{

rl1 <- import.shape(filename = "yourshapefile.shp"
			,path = "C:/yourpath..."
			,species.col= "column with species"
			,ID.col="column with patch Id"
			,area.col="Column with area"
			,dispersal=800#Mean dispersal ability of the species 
			#(used to generate patch clusters, or components)
			)

}

}
