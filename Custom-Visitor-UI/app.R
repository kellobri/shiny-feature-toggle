#
#

library(shiny)

# Define UI for application that draws a histogram
ui <- fluidPage(
    
    # Application title
    titlePanel("Old Faithful Geyser Data"),
    
    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            conditionalPanel(condition = "output.isUser == false", 
                             h4("This application is hosted on our internal RStudio Connect server"),
                             p("Contact the Data Science team to request access if you do not have an account."),
                             actionButton('email', 'Request Access')),
            conditionalPanel(condition = "output.isUser == true",
                             sliderInput("bins",
                                         "Number of bins:",
                                         min = 1,
                                         max = 50,
                                         value = 30)
            )
        ),
        
        # Show a plot of the generated distribution
        mainPanel(
            conditionalPanel(condition = "output.isUser == false", 
                             div(style="text-align: center;",
                                 h3("You must be logged in to see this application."),
                                 actionButton('login', 'Return to RStudio Connect'),
                                 img(src='plumber-lady.png', width = 250))
            ),
            conditionalPanel(condition = "output.isUser == true", plotOutput("distPlot"))
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
    
    user <- reactive({
        session$user
    })
    
    output$isUser <- reactive({
        if (is.null(user())){
            return(FALSE) 
        } else {
            return(TRUE)
        }
    })
    
    outputOptions(output, "isUser", suspendWhenHidden = FALSE)
    
    output$distPlot <- renderPlot({
        # generate bins based on input$bins from ui.R
        x    <- faithful[, 2]
        bins <- seq(min(x), max(x), length.out = input$bins + 1)
        
        # draw the histogram with the specified number of bins
        hist(x, breaks = bins, col = 'darkgray', border = 'white')
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
