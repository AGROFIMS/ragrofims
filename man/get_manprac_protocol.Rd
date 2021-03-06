% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/protocol_data.R
\name{get_manprac_protocol}
\alias{get_manprac_protocol}
\title{Get protocol data from experimental data}
\usage{
get_manprac_protocol(
  expsiteId = NULL,
  format = "data.frame",
  serverURL = "https://research.cip.cgiar.org/agrofims/api/dev",
  version = "/0253/r"
)
}
\arguments{
\item{expsiteId}{experiment-site Id or expsiteId}

\item{format}{type of data structure format}

\item{serverURL}{database server URL}

\item{version}{api version}
}
\description{
Get protocol data from experimental data
}
