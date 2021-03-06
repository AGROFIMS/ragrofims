#' Get protocol data from experimental data
#' 
#' @param expsiteId experiment-site Id or expsiteId
#' @param format type of data structure format
#' @param serverURL database server URL
#' @param version api version
#' @importFrom ragapi ag_get_cropmea_expsiteId ag_get_phenomea_expsiteId ag_get_soil_expsiteId  ag_get_soil_expsiteId
#' @importFrom dplyr distinct mutate count select left_join
#' @export
#'

get_manprac_protocol <- function(expsiteId=NULL,
                                 format = "data.frame",
                                 serverURL = "https://research.cip.cgiar.org/agrofims/api/dev",
                                 version = "/0253/r"
){
  
  protocol <- ragapi::ag_get_manprac_expsiteId(expsiteDbId = expsiteId,
                                               format = format,
                                               serverURL = serverURL,
                                               version =version)
  
  protocol <- protocol %>% dplyr::filter(protocol=="on") %>% as.data.frame(stringsAsFactors=FALSE)
  
  
  if(nrow(protocol)>0){
    
    #add values in variableName
    protocol$parametermeasured <- ""#only for mutate_crop_names
    protocol <- mutate_variable_name(protocol)
    #count number of evaluations: add "n" column or number of evaluations per measurement
    dt_count_index <- protocol %>% 
                            dplyr::count(cropcommonname, indexorder, variableName, measurement) %>% 
                            dplyr::select(1,3,4,5)
    protocol <- dplyr::left_join(dt_count_index,protocol)
    
    #Mutate crop names and other crops names
    protocol <- mutate_crop_names(protocol)
    #number of evaluation
    neval <- seq_protocol(dt_count_index$n)
    protocol <-  protocol %>% dplyr::mutate(variableName = paste0(cropcommonname,"_",measurement,"__",neval))
    #protocol <-  protocol %>% dplyr::filter(!is.na(value))#filter empty values
    #protocol <-  dplyr::distinct( protocol,measurement,cropcommonname,variableName, value, .keep_all=TRUE) #remove duplicates
    protocol$samplesperseason <- "1"
    protocol$samplesperplot <- "1"
    protocol$n <- NULL
    #protocol$Subgroup <- "" #for KDSmart speciallys
    protocol$AgroFIMSId <- 1:nrow(protocol)

  } else {
    protocol <- data.frame()
  }
  protocol
  
}

#' Vectorized creation of sequence of number of evaluation based on initial values.
#' @param .x vector vector of indexes
#' @export
#' 
seq_protocol <- function(.x){
  out <- unlist(lapply(.x, function(.x)seq.int(.x)))
}

