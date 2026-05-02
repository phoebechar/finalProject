library(tidyverse)
library(shiny)

day1 <- read.csv("data/day1_full.csv")
day2 <- read.csv("data/day2_full.csv")
day3 <- read.csv("data/day3_full.csv")

boat_tabs <- tabsetPanel(
  id = "craft",
  type = "hidden",
  tabPanel("Canoe",
           radioButtons("people_sel", 
                        label = "How many people?",
                        choices = 1:4),
  ),
  tabPanel("Kayak",
           radioButtons("people_sel", 
                        label = "How many people?",
                        choices = c(1, 2)),
  ),
  tabPanel("Voyageur",
           radioButtons("people_sel", 
                        label = "How many people?",
                        choiceNames = "5+", choiceValues = 5)
  ),
  tabPanel("SUP",
           radioButtons("people_sel", 
                        label = "How many people?",
                        choices = c(1))
  ),
)

day_tabs <- tabsetPanel(
  id = "level",
  type = "hidden",
  tabPanel("day1",
           sliderInput("level_sel", 
                       label = "What water level?",
                       min = 1706, max = 1707, value = 1706.5,
                       step = 0.05),
  ),
  tabPanel("day2",
           sliderInput("level_sel", 
                       label = "What water level?",
                       min = 2, max = 8, value = 5,
                       step = 0.05),
  ),
  tabPanel("day3",
           sliderInput("level_sel", 
                       label = "What water level?",
                       min = 2.5, max = 4.5, value = 3.5,
                       step = 0.05),
  )
)

ui <- fluidPage(
  sidebarLayout(
    sidebarPanel(
      radioButtons("day_sel",
                   label = "Which day are you interested in?",
                   choiceNames = c("Day 1", "Day 2", "Day 3"),
                   choiceValues = c("day1", "day2", "day3")),
      sliderInput("temp_sel",
                  label = "What temperature?",
                  min = 45, max = 80, value = 60),
      day_tabs,
      selectInput("boat_sel",
                  label = "Which type of craft?",
                  choices = c("Canoe", "Kayak", "SUP", "Voyageur")),
      boat_tabs,
      actionButton("action", label = "Generate Prediction")
    ),
    mainPanel(
      plotOutput("dist_plot"),
      textOutput("pred_print")
    ),
  )
)

server <- function(input, output, session) {
  observeEvent(input$boat_sel, {
    updateTabsetPanel(inputId = "craft", selected = input$boat_sel)
  })
  
  observeEvent(input$day_sel, {
    updateTabsetPanel(inputId = "level", selected = input$day_sel)
    
    if (input$day_sel == "day1") {
      updateSliderInput(session, "level_sel", 
                        min = 1706, max = 1707, value = 1706.5,
                        step = 0.05)
    } else if (input$day_sel == "day2") {
      updateSliderInput(session, "level_sel", 
                        min = 2, max = 8, value = 5,
                        step = 0.05)      
    } else if (input$day_sel == "day3") {
      updateSliderInput(session, "level_sel", 
                        min = 2.5, max = 4.5, value = 3.5,
                        step = 0.05)
    }
  })
  
  adk_react <- eventReactive(input$action, {
    df <- get(input$day_sel)
  })
  
  mod_react <- eventReactive(input$action, {
    pred_mod = lm(value ~ boatType + temp + water + n_paddler, adk_react())
    data <- data.frame(boatType = input$boat_sel, 
                       temp = input$temp_sel,
                       water = input$level_sel,
                       n_paddler = as.numeric(input$people_sel))
    list(
      prediction = predict(pred_mod, data),
      day = parse_number(input$day_sel),
      temp = input$temp_sel,
      level = input$level_sel
    )
  })
  
  output$dist_plot <- renderPlot({
    ggplot(data = adk_react(), aes(x = value)) +
      geom_density() +
      geom_vline(xintercept = mod_react()$prediction, 
                 color = "magenta", linewidth = 2) +
      theme_linedraw(base_size = 16) +
      theme(axis.title.y = element_blank(), 
            axis.text.y = element_blank()) +
      labs(x = "Time for Completion (Hours)",
           title = glue::glue("Distribution of Times for Day ", mod_react()$day))
  })
  
  output$pred_print <- renderText({
    mod <- mod_react()
    paste0("On Day ", mod$day, 
           " with a temperature of ", mod$temp,
           " degrees and a water level of ", mod$level,
           " ft, Your chosen craft has a predicted time of ",
           round(mod$prediction, 2), " hours")
  })
}

shinyApp(ui, server)
