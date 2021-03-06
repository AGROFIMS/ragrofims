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
                                   version = "/0345/r"
                                   ){
  
  out1 <- ag_get_cropmea_expsiteId(expsiteDbId = expsiteId,
                                   format = format,
                                   serverURL = serverURL,
                                   version =version)
  
  #TODO: FERTILZIER / management practices
  out5 <- ragapi::ag_get_manprac_expsiteId(expsiteDbId = expsiteId,
                                           format = format,
                                           serverURL = serverURL,
                                           version =version)
  
  
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
  
  traitlist_dt <- data.table::rbindlist(list(out1,out2,out5,out3,out4),use.names = TRUE,fill = TRUE) %>% 
                  as.data.frame(stringsAsFactors=FALSE)
  
  if(nrow(traitlist_dt)>0 && nrow(out1)>0){
    #Mutate crop and new 'other crop' names
    
    traitlist_dt <- traitlist_dt %>% 
                                dplyr::mutate(parametermeasured = as.character(parametermeasured)) %>%  
                                dplyr::mutate(parametermeasured = 
                                             case_when(singularity=="crop_phenology"~ group,
                                                   singularity=="management_practices"~ group,
                                                   singularity=="soil"~ "soil",
                                                   singularity=="weather"~ "weather",
                                                   TRUE~parametermeasured
                                                  )
                                              )
    #In case user select other management practices, it change to the new name
    traitlist_dt <- traitlist_dt %>% 
                                    dplyr::mutate(variableDataType = 
                                                    case_when(
                                                      singularity=="management_practices" & variableDataType=="OTHER"~ "DECIMAL",
                                                      TRUE~variableDataType
                                                    )
                                    )
    
    traitlist_dt <- traitlist_dt %>% 
      dplyr::mutate(variableLowerLimit = 
                      case_when(
                        singularity=="management_practices" & measurement=="Other"~ "0.00",
                        TRUE~variableLowerLimit
                      )
      )
    
    
    traitlist_dt <- traitlist_dt %>% 
      dplyr::mutate(variableUpperLimit = 
                      case_when(
                        singularity=="management_practices" & measurement=="Other"~ "10000.00",
                        TRUE~variableUpperLimit
                      )
      )

    traitlist_dt <- traitlist_dt %>% 
                        dplyr::mutate(variableLevel = 
                                    case_when(
                                      singularity=="management_practices" & measurement=="Other"~ "Plot",
                                      TRUE~as.character(variableLevel)
                                    )
      )
    
    if(is.element(el = "valueother", names(traitlist_dt)) ){
     
    traitlist_dt <- traitlist_dt %>% 
                            dplyr::mutate(measurement = 
                                            case_when(
                                            singularity=="management_practices" & measurement=="Other"~ as.character(valueother),
                                        TRUE~ as.character(measurement)
                                        )
        )
      
    }
    
    traitlist_dt <- mutate_crop_names(traitlist_dt)
    #Variable Name
    traitlist_dt <- mutate_variable_name(traitlist_dt)
    #Mutate timing values
    traitlist_dt <- mutate_timming_values(traitlist_dt)
    traitlist_dt <- mutate_nummeasurement_phenology(traitlist_dt)
    
    #traitlist_dt <- get_manprac_actualplan(traitlist_dt)
    traitlist_dt <- flatten_manprac_actualplan(traitlist_dt)
    
    if(nrow(out5)>0){ #for management practices
      manprac_dt_on <- traitlist_dt %>% dplyr::filter(managementmeasurement=="on")
      traitlist_dt <- traitlist_dt %>% dplyr::filter(is.na(managementmeasurement))
      traitlist_dt <- rbind(traitlist_dt , manprac_dt_on)
    }
    
    #Assign 1 to samplesperplot in case of having NA values
    traitlist_dt <- traitlist_dt %>% dplyr::mutate(samplesperplot = case_when( is.na(samplesperplot) ~ "1",
                                                                           TRUE~samplesperplot
                                                                           ) )
    #Assign 1 to samplesperseason in case of having NA values
    traitlist_dt <- traitlist_dt %>% dplyr::mutate(samplesperseason = case_when( is.na(samplesperseason) ~ "1",
                                                                           TRUE~samplesperseason
                                                                          ) )
    
    
  } else{
    traitlist_dt <- data.frame()
  } 
  return(traitlist_dt)
                        
}


# Internal function to add 
# 
# @param dt: data frame with the crop measurement table to add number of season and plots
# @examples \dontrun{
# dt<- data.frame(variableName =c("chipkpea_height","chipkea_weigth"), samplesperseason = c(2,10), samplesperplot=c(10,5))
# add_season_numplot_prefix(dt)
# } 

add_season_numplot_prefix<- function(dt){

  if(!is.null(dt) && nrow(dt)!=0){

    dt$samplesperseason <- as.numeric(dt$samplesperseason)
    dt$samplesperplot <- as.numeric(dt$samplesperplot)
    season_idx <- which(dt$samplesperseason<=0)
    nplot_idx <-  which(dt$samplesperplot<=0)

    if(length(season_idx)>0){
      dt$samplesperseason[season_idx]<- 1
    }
    if(length(nplot_idx)>0){
      dt$samplesperplot[nplot_idx]<- 1
    }

    var_season <- vector(mode="list", length = nrow(dt))

    for(i in 1:nrow(dt)){

      if(dt$samplesperseason[i]==1){
        var_season[[i]] <- dt$variableName[i]
      } else {
        var_season[[i]] <- paste0(1:dt$samplesperseason[i],":",dt$variableName[i])
      }
    }

    out <- NULL
    for( i in 1:length(var_season)){
      for( j in 1:length(var_season[[i]]))
      {
        if(dt$samplesperplot[i]==1){
          out <- append( out, paste0(var_season[[i]][j]) )
        } else {
          out <- append( out,  paste0(var_season[[i]][j], "__", 1:dt$samplesperplot[i]) )
        }
      }
    }
    return(out)
  } else{
    out<-NULL
  }
}


# 
# add_season_numplot_prefix<- function(dt){
# 
#   if(!is.null(dt) && nrow(dt)!=0){
#     out <- NULL
#     dt$samplesperseason <- as.numeric(dt$samplesperseason)
#     dt$samplesperplot <- as.numeric(dt$samplesperplot)
#     season_idx <- which(dt$samplesperseason<=0)
#     nplot_idx <-  which(dt$samplesperplot<=0)
# 
#     if(length(season_idx)>0){
#       dt$samplesperseason[season_idx]<- 1
#     }
#     if(length(nplot_idx)>0){
#       dt$samplesperplot[nplot_idx]<- 1
#     }
#     out <- list()
# 
#     #Number of instaces per seasons
#     for(i in 1:nrow(dt)) {
# 
#       if(dt$samplesperplot[i]==1L){
#         out[[i]] <- dt$variableName[i]
#       } else {
#         out[[i]]<- paste(dt$variableName[i],1:dt$samplesperplot[i],sep="__")
#       }
# 
#     }
# 
#     if(all(dt$samplesperseason==1L)){
#       out<- unlist(out)
#     }
#     else {
# 
#       out2<- list()
#       for( i in 1:nrow(dt)){
#         if(dt$samplesperseason[i]==1L){
#           out2[[i]] <- out[[i]]
#         } else {
#           out2[[i]]<- as.vector(outer(1:dt$samplesperseason[i], out[[i]], paste, sep=":"))
#         }
#       }
# 
#       out<- unlist(out2)
# 
#     }
# 
#   }
#   else {
# 
#     out<-NULL
# 
#   }
#   out
# 
# }
# 
# 
# 
