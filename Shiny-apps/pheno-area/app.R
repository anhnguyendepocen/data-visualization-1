# pheno-area app


library(shiny)
library(dplyr)
library(ggplot2)
library(lubridate)

# reading in the data needed for the app
DBL <- read.csv("DBL-area.csv", stringsAsFactors = FALSE)

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Phenophases By Year"),

    # Sidebar 
    # makes you choose a NEON site with a dropdown menu
    # then lets you choose which years to display for the chosen site
    sidebarLayout(
      sidebarPanel(
        helpText("Choose a site to observe the percentages of individuals in each phenophase across the years chosen."),
        # dropdown select menu
        selectInput("select", label = h3(span("NEON Sites", style = "color:darkblue")), choices = list("Harvard Forest (HARV)" = "HARV", "Bartlett Experimental Forest (BART)" = "BART", 
                     "Smithsonian Environmental Research Center (SERC)" = "SERC", "University of Notre Dame Environmental Research Center (UNDE)" = "UNDE", 
                      "The Universtiy of Kansas Field Station (UKFS)" = "UKFS", "Oak Ridge (ORNL)" = "ORNL",
                      "LBJ National Grassland (CLBJ)" = "CLBJ", "Abby Road (ABBY)" = "ABBY", "Toolik Lake (TOOL)" = "TOOL",
                     "Caribou Creek (BONA)" = "BONA"), selected = "HARV"),
        # checkbox so can pick as many years as you want
        checkboxGroupInput("checkGroup", label = h3(span("Years", style = "color:darkblue")), choices = list("2015"="2015",
             "2016"="2016", "2017" = "2017", "2018"="2018", "2019"="2019"), selected = NULL)
        
      ),

        # Show a plot of the generated distribution
        mainPanel(
           plotOutput("areaPlot")
        )
    )
)

# Define server logic 
server <- function(input, output, session) {
  # since some sites have data for years that others don't, depending on what site you choose, 
  # the years with available data are shown for you to choose from
  observe({
    x <- input$select
    
    if (x == "ORNL" | x == "BART" | x=="HARV" | x=="UNDE")
      updateCheckboxGroupInput(session, "checkGroup", choices = list("2015"="2015",
                                                                     "2016"="2016", "2017" = "2017", "2018"="2018", "2019"="2019"))
    if (x == "SERC" | x=="UKFS" | x=="ABBY")
      updateCheckboxGroupInput(session, "checkGroup", choices = list("2016"="2016", "2017" = "2017", "2018"="2018", "2019"="2019"))
    if (x=="CLBJ" | x=="TOOL")
      updateCheckboxGroupInput(session, "checkGroup", choices = list("2017" = "2017", "2018"="2018", "2019"="2019"))
    if (x=="BONA")
      updateCheckboxGroupInput(session, "checkGroup", choices = list( "2018"="2018", "2019"="2019"))

     })
  

  # when a year isn't chosen, an error shows in the main panel
  # with this, instead of putting the error message, it shows this sentence so user
  # knows what they need to do.
    output$areaPlot <- renderPlot({
      validate(
        need(input$checkGroup != "", "Please select at least one year to plot.")
      )
      
  pheno <- DBL %>%
    filter(siteID %in% input$select) %>%
    filter(year %in% input$checkGroup)
  
  # look at the total individuals in phenophase status by day
  phenoSamp <- pheno %>%
    group_by(siteID) %>%
    count(date)
  phenoStat <- pheno %>%
    group_by(date, siteID, taxonID, phenophaseName, commonName) %>%
    count(phenophaseStatus) 
  phenoStat <- full_join(phenoSamp, phenoStat, by = c("date", "siteID"))
  ungroup(phenoStat)
  
  # only look at the yes's
  phenoStat_T <- filter(phenoStat, phenophaseStatus %in% "yes")
  
  # plot the percentage of individuals in the leaves phenophase
  # convert to percentage
  phenoStat_T$percent <- ((phenoStat_T$n.y)/phenoStat_T$n.x)*100
  
  phenoStat_T$dayOfYear <- yday(phenoStat_T$date)
  phenoStat_T$year <- substr(phenoStat_T$date, 1, 4)
  phenoStat_T$phenophaseName <- factor(phenoStat_T$phenophaseName, levels = c("Leaves", "Falling leaves", "Colored leaves",  "Increasing leaf size","Breaking leaf buds",  "Open flowers"))

  
  ggplot(phenoStat_T, aes(x = dayOfYear, y = percent, fill = phenophaseName, color = phenophaseName)) +
     #geom_density(alpha=0.3,stat = "identity", position = position_dodge(width = .1)) +
    geom_density(alpha=0.3,stat = "identity", position = "stack") +  
    theme_bw() + facet_grid(cols = vars(commonName),rows = vars(year), scale = "free_y") +
    xlab("Day Of Year") + ylab("% of Individuals") + xlim(0,366) +
    ggtitle("Phenophase Density for Selected Site") +
    theme(plot.title = element_text(lineheight = .8, face = "bold", size = 20, hjust = 0.5)) +
    theme(text = element_text(size = 15)) +
   scale_color_brewer(palette = "Set1") + scale_fill_brewer(palette = "Set1") +
    theme(legend.position = "bottom") + labs(fill = "Phenophase", color = "Phenophase")
  
  
  
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
