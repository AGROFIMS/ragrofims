#' Get metadata from experimental details
#' 
#' @param expsiteId experiment-site Id or expsiteId
#' @param format type of data structure format
#' @param serverURL database server URL
#' @param version api version
#' @importFrom ragapi ag_get_cropmea_expsiteId ag_get_phenomea_expsiteId ag_get_soil_expsiteId  ag_get_soil_expsiteId
#' @export
#' 
get_agrofims_traitlist <- function(expsiteId=NULL,
                                   format = "data.frame",
                                   serverURL = "https://research.cip.cgiar.org/agrofims/api/dev",
                                   version = "/0248/r"
                                   ){
  
  out1 <- ag_get_cropmea_expsiteId(expsiteDbId = expsiteId,
                                   format = format,
                                   serverURL = serverURL,
                                   version =version)
  
  #TODO: FERTILZIER / management practices
  
  out2 <- ag_get_phenomea_expsiteId(expsiteDbId = expsiteId,
                                    format = format,
                                    serverURL = serverURL,
                                    version =version)
  
  out3 <- ag_get_weather_expsiteId(expsiteDbId = expsiteId,
                                   format = format,
                                   serverURL = serverURL,
                                   version =version)
  
  out4 <- ag_get_soil_expsiteId(expsiteDbId = expsiteId,
                                format = format,
                                serverURL = serverURL,
                                version =version)
  
  traitlist_dt <- data.table::rbindlist(list(out1,out2,out3,out4),use.names = TRUE,fill = TRUE) %>% 
                  as.data.frame(stringsAsFactors=FALSE)
  
  if(nrow(traitlist_dt)>0){
    #Variable Name
    traitlist_dt <- mutate_variable_name(traitlist_dt)
    #Mutate timing values
    traitlist_dt <- mutate_timming_values(traitlist_dt)
    traitlist_dt <- mutate_nummeasurement_phenology(traitlist_dt)
    traitlist_dt$AgroFIMSId <- 1:nrow(traitlist_dt)
    traitlist_dt$VariableId <- 1:nrow(traitlist_dt)
  } else{
    traitlist_dt <- data.frame()
  } 
  return(traitlist_dt)
                        
}