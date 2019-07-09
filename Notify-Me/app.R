library(shiny)
library(shinythemes)
library(ggplot2)
library(glue)
library(httr)
library(gitlink)

# Application Info
vanity_url <- 'https://colorado.rstudio.com/rsc/collab-notify/'
slack_owner_id <- Sys.getenv('SLACK_OWNER')
slack_webhook <- Sys.getenv('SLACK_HOOK')

# Get the current day of the month
dom <- 25

# Define the target for salespeople in our organization.
salesTarget <- 15000

# Set the seed so we always get the same data.
set.seed(1000)

# Generate some random sales data for the sake of demonstration.
salesData <- data.frame(
    salesperson = c(rep("tareef", dom+1), rep("sean", dom+1)),
    day = rep(0:dom, 2),
    dailySales = round(runif((dom+1)*2, 0, 1000),2)
)
# Zero out the start of the month (day 0)
salesData[salesData$day == 0,"dailySales"] <- 0

# Compute the running total of all sales for each salesperson through the month.
salesData$salesTotal <- ave(salesData$dailySales, 
                            salesData$salesperson, 
                            FUN = cumsum)

# Define UI for application that draws a histogram
ui <- fluidPage(theme = shinytheme("simplex"),
                
                titlePanel("Sales Reports"),
                tags$head(tags$script(src = "message-handler.js")),
                ribbon_css("https://github.com/colearendt/gitlink"),
                
                # Dislpay the subtitle computed on the server
                fluidRow(
                    div(style = "text-align: center;", 
                        h3(textOutput("subtitle")),
                        conditionalPanel(
                            condition = "output.isCollab == false",
                            actionButton("request", "Request Collaborator Access")
                        )
                    )
                ),
                
                # Show the plot of sales
                fluidRow(div(style = "padding-left: 40px; padding-right: 40px;", plotOutput("salesPlot"))),
                
                hr(),
                
                # Show the datatable of all sales
                fluidRow(div(style = "padding-left: 40px; padding-right: 40px;", dataTableOutput("salesTbl")))
                
)


server <- function(input, output, session) {
    
    user <- reactive({
        session$user
    })
    
    groups <- reactive({
        session$groups
    })
    
    observeEvent(input$request, {
        collab_alert <- glue('{{"text":"Hey <{slack_owner_id}>, {session$user} is requesting collaborator access to {vanity_url}"}}')
        
        POST(slack_webhook, body = collab_alert, add_headers('Content-Type' = 'application/json'))
        
        session$sendCustomMessage(type = 'confirm-request',
                                  message = 'Your Collaboration Request Has Been Sent.')
    })
    
    # Determine whether or not the user is a solutions engineer.
    isSolutions <- reactive({
        if ('solutions' %in% groups()){
            return(TRUE)
        } else{
            return(FALSE)
        }
    })
    
    output$isCollab <- reactive({
        isSolutions()
    })
    
    # Render the subtitle of the page according to what user is logged in.
    output$subtitle <- renderText({
        if (is.null(user())){
            return("You must log in to use this application.")
        } else {
            return("Monthly Sales Report")
        } 
    })
    
    output$salesPlot <- renderPlot({
        # If no user is logged in, render a blank plot.
        if (is.null(user())){
            return()
        }
        
        # Generate the sales plot
        p <- ggplot(salesData, aes(day, salesTotal, group=salesperson, color=salesperson))
        p <- p + geom_point()
        p <- p + geom_hline(yintercept=salesTarget, color=7)    
        p <- p + xlim(0, 30)
        p <- p + stat_smooth(method="lm", fullrange=TRUE)
        p <- p + ggtitle("September Sales Projections")
        p <- p + xlab("Day of Month")
        p <- p + ylab("Total Sales (USD)")
        print(p)    
    })
    
    output$salesTbl <- renderDataTable({
        # If no user is logged in, don't show any data.
        if (is.null(user())){
            return()
        }
        
        # Otherwise return all data that should be visible to this user.
        salesData
    })
    
    outputOptions(output, "isCollab", suspendWhenHidden = FALSE)  
}

# Run the application 
shinyApp(ui = ui, server = server)
