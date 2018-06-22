# Template for BIOMAAP educational modules
# January 15th, 2018
# Created by Impact Media Lab

######### Load required packages
library(shiny)
library(shinydashboard)
library(leaflet)
library(png)
library(plotly)
library(htmlwidgets)
library(RCurl)

# Run the scripts to build the initial survey
source('www/ShinyAssessment.R')

#import some large images at start-up so they don't slow down loading later. 
  ## These are imported in the format required by plotly (r to javascript conversion package)
    image_file <- "www/results_background.png"
    txt <- RCurl::base64Encode(
      readBin(image_file, "raw", file.info(image_file)[1, "size"]), "txt")
    
    image_file2 <- "www/loading_circle.png"
    txt2 <- RCurl::base64Encode(
      readBin(image_file2, "raw", file.info(image_file2)[1, "size"]), "txt2")
    
    image_file3 <- "www/youarehere_button.png"
    txt3 <- RCurl::base64Encode(
      readBin(image_file3, "raw", file.info(image_file3)[1, "size"]), "txt3")
    
  ## Thes are the images in base R format. We call these in the download figure
    img<-readPNG("www/results_background.png")
    img2<-readPNG("www/youarehere_button.png")
    img3<-readPNG("www/loading_circle.png")
    img4<-readPNG("www/backgroud_for_download_plot.png")

#import data
  # These are the questions for the initial survey
    dat <- read.csv("www/Spectrum_plot.csv", as.is=TRUE, header=F)
  # These are the locations and comments on the interactive results figure. 
    math.items <- as.data.frame(
      read.csv('www/survey_question.csv', stringsAsFactors=FALSE)
      )


  
######################################################      
  
######### BUILDING THE MINDSET SURVEY

######################################################      
shinyServer(function(input, output, session) {
    
    # Save the most recent assessment results to display
    assmt.results <- reactiveValues(
      math = integer()
    )
  
    # This function will be called when the assessment is completed.
    saveResults <- function(results) {
      assmt.results$math <-  factor(results,
       levels = names(math.items)[4:9],
       ordered = TRUE)
    }
    
    # Multiple choice test example
    test <- ShinyAssessment(input, output, session,
                            name = 'Statistics',
                            item.stems = math.items$Stem,
                            item.choices = math.items[,c(4:9)],
                            callback = saveResults,
                            start.label = 'Take the Mindset Survey',
                            width="100%",
                            itemsPerPage = 1,
                            inline = FALSE)
    
    SHOW_ASSESSMENT$show <- FALSE
    
    output$ui <- renderUI({
      if(SHOW_ASSESSMENT$show) { # The assessment will take over the entire page.
        fluidPage(width = 12, uiOutput(SHOW_ASSESSMENT$assessment))
      } else { # Put other ui components here
        fluidPage(	 
        
          fluidRow(
            img(class="image", src ="growth_vs_fixed.png", width = "26%", style="display: block; margin-left: auto; 
                margin-right: auto; margin-top:20px; margin-bottom:-10px")
            ),
          
          tags$h1("What's your current mindset?", align = "center"),
          
          p("Students arrive at college with very different past experiences
            and opportunities, and thus diverse mindsets about mathematics. 
            Let's explore your current perspective on learning math. There are no 
            right or wrong answers. We are just interested in your ideas."
          ),
          
          p("For this survey, indicate the extent to which you agree or disagree with 
            each of the following statements."
          ),

          uiOutput(test$button.name, align="center"),
          br(),
          br()
          )
      }
    })


######################################################################      
    
######### BUILDING THE RESULTS OUTPUT FOR SURVEY
    
######################################################################      

    output$mass.plot <- renderPlotly({
      ab_line <- 3
      if(length(assmt.results$math) > 0) {
        #plot(assmt.results$math)

        print(math.items[,3])
        score_matrix <- matrix(NA, length(math.items[,3]), 6 )

        for(i in 1:length(math.items[,3])){
          if(math.items[i,3] == "A"){
            score_matrix[i,] <- seq(6,1)
          }else{
            score_matrix[i,] <- rev(seq(6,1))
          }

        }

        k <- as.numeric(assmt.results$math) #c( 2, 3, 4, 3, 6, 3, 4, 2)
        j <- 3
        score <- rep(NA, 8)
        for(j in 1:length(k)){
        score[j] <- score_matrix[j, k[j]]
        }

        sum_score <- sum(na.omit(score))
      #output$sum_score1 <- sum_score
     # save(sum_score, file="www/survey_score.Rdata")
      print(assmt.results$math)
      print(as.numeric(assmt.results$math))
       
        sum_score_1 <- dat[sum_score,] 
        sum_score_2 <- dat[1:sum_score,] 
        
        
        
       ####### 
      
      # setting plot margins
        m <- list(
          l = 5,
          r = 5,
          b = 5,
          t = 5,
          pad = 0
        )
      
      # setting text styles
      
        t <- list(
          family = "Oswald, sans-serif",
          size = 14,
          color = toRGB("#1176ff")
            )
        
        t2 <- list(
          family = "Oswald, sans-serif",
          size = 14,
          color = toRGB("#8FB230")
        )
        
        
           
      # Building the plot
      plot_ly(data = dat, x = ~V1, y = ~V2,
                type = 'scatter', mode = 'markers',
                     hoverinfo = 'text',
                text = ~paste(V3,
                              ' </br> ', V4),
                marker = list(size = 10,
                              color = c(rep("fff", 47), "#8FB230"),
                              line = list(color = "#8FB230",
                                          width = 1.5))) %>%

          #Adding blue text
          add_trace(data= dat, x = dat[1,1], y= dat[1,2], mode = 'text', 
                    text = ~paste(dat[1,5]),
                            xref = "x",
                            yref = "y",
                            textfont = t,
                            textposition = "top") %>%

          
          # Adding green text
          add_trace(data= dat, x = dat[48,1], y= dat[48,2], mode = 'text', 

                    text = ~paste(dat[48,5]),
                    xref = "x",
                    yref = "y",
                    textfont = t2,
                    textposition = "top") %>%
          
          # Adding green dot at end
          add_trace(data= dat, x = dat[48,1], y= dat[48,2], mode = 'markers', 
                    hoverinfo = 'text',
                    text = ~paste(dat[48,3],' </br> ', dat[48,4]),
                    xref = "x",
                    yref = "y",
                    marker = list(size = 10,
                                  color = "#8FB230",
                                  line = list(color = "#8FB230",
                                              width = 1.5))) %>%

          layout(autosize = F, width = 600, height = 300,
                 showlegend = FALSE, margin=m,
                 xaxis = list(
                         autotick = FALSE,
                         range = c(2.5, 8.6),
                         title = "",
                         showticklabels = F,
                         showgrid = F
                       ),
                 yaxis = list(
                         autotick = FALSE,
                         range = c(4, 9.15),
                         title = "",
                         showticklabels = F,
                         showgrid = F
                       ),
                images = list(
                           source =  paste('data:image/png;base64', txt, sep=','),
                           xref = "x",
                           yref = "y",
                           x = 2.3, #2.3
                           y = 10, #10
                           sizex = 6.4,sizey = 10, #6.4, 10
                           opacity = 1,
                           type="stretch",
                           layer = "below"
                       )
                     ) %>%
        
          #Adding dots to "you are here" point
          add_trace(data= sum_score_2, x = ~V1, y= ~V2, mode = 'markers', 
                    marker = list(size = 10,
                                  color = "1176ff",
                                  line = list(color = "#1176ff",
                                              width = 1.5))) %>%
        
        #Adding "you are here" dot
        add_trace(data= sum_score_1, x = ~V1, y= ~V2, mode = 'markers', 
                  marker = list(size = 13,
                                color = "orange",
                                line = list(color = "orange",
                                            width = 1.5))) %>%
          
          # Adding blue dot at start
          add_trace(data= dat, x = dat[1,1], y= dat[1,2], mode = 'markers', 
                    hoverinfo = 'text',
                    text = ~paste(dat[1,3],' </br> ', dat[1,4]),
                    xref = "x",
                    yref = "y",
                    marker = list(size = 10,
                                  color = "#1176ff",
                                  line = list(color = "#1176ff",
                                              width = 1.5))) %>%
          
          config(displayModeBar = F)




     } else {
    
       plotly_empty() %>% config(displayModeBar = F) %>% 
         
         layout(autosize = F, width = 600, height = 300, 
                showlegend = FALSE, 
                xaxis = list(
                  autotick = FALSE,
                  range = c(2.5, 8.6), 
                  title = "",
                  showticklabels = F,
                  showgrid = F
                ),
                yaxis = list(
                  autotick = FALSE,
                  range = c(4, 9.15),
                  title = "",
                  showticklabels = F,
                  showgrid = F
                ),
                images = list(
                  source =  paste('data:image/png;base64', txt2, sep=','),
                  xref = "x",
                  yref = "y",
                  x = 4, #2.3
                  y = 9, #10
                  sizex = 4.4,sizey = 5, #6.4, 10
                  opacity = 1,
                  type="stretch",
                  layer = "below"
                )
          ) 
     
        }
      })

    
        
######################################################################      
    
######### MAP OF LONDON
    
######################################################################      
    
  ## leaflet map
    output$mymap_1 <- renderLeaflet({
      
      m <- leaflet() %>%
        addTiles() %>%  # Add default OpenStreetMap map tiles
       # addMarkers(lng=174.768, lat=-36.852, popup="The birthplace of R") %>%
        addProviderTiles("providers$Stamen.Toner") %>%
      setView( -0.1278,51.5074, 12)
      m 
    
      })

######################################################################      
    
######### FORWARD & BACK BUTTONS ON LESSON SECTION
    
######################################################################      
    
#Previous_Button=tags$div(actionButton("Prev_Tab",HTML('<div class="col-sm-4"><i class="fa fa-angle-double-left fa-2x"></i></div>')))
    
    Next_Button=div(
      actionButton(inputId="Next_Tab", label ='Next', icon = icon("angle-double-right"), 
                   style="color: #1176ff; font-family: 'Source Sans Pro', sans-serif; 
                    font-size: 15px; font-weight: 400;
                   background-color: #ecf0f5; border-color: #ecf0f5", width="100%")
      )
    
   
    
    output$Next_Previous=renderUI({
      tab_list=input$List_of_tab[-length(input$List_of_tab)]
      nb_tab=length(tab_list)
        column(12,offset = 0,Next_Button)
      })
      

    observeEvent(input$Next_Tab,{
       tab_list=input$List_of_tab
       current_tab=which(tab_list==input$tabBox_next_previous)
       updateTabsetPanel(session,"tabBox_next_previous",selected=tab_list[current_tab+1])
      })
      

    #######
      
      Next_Button3=div(
        actionButton(inputId="Next_Tab3", label ='Next', icon = icon("angle-double-right"), 
                     style="color: #1176ff; font-family: 'Source Sans Pro', sans-serif; font-size: 15px; font-weight: 400;
                     background-color: #ecf0f5; border-color: #ecf0f5", width="100%")
        )
      
      
      
      output$Next_Previous3=renderUI({
        tab_list=input$List_of_tab[-length(input$List_of_tab)]
        nb_tab=length(tab_list)
        column(12,offset = 0,Next_Button3)
      })
      
      
      
      observeEvent(input$Next_Tab3,
                   {
                     tab_list=input$List_of_tab
                     current_tab=which(tab_list==input$tabBox_next_previous3)
                     updateTabsetPanel(session,"tabBox_next_previous3",selected=tab_list[current_tab+1])
                   })
      
      
      
######################################################################      
      
######### RESULTS OUTPUT FOR 3 MINDSET CATEGORIES
      
######################################################################      
      
      
      output$score_text <- renderUI({ 
        sum_score <- NA
        
        if(length(assmt.results$math) > 0) {
          #plot(assmt.results$math)
          
          print(math.items[,3])
          score_matrix <- matrix(NA, length(math.items[,3]), 6 )
          
          
          for(i in 1:length(math.items[,3])){
            if(math.items[i,3] == "A"){
              score_matrix[i,] <- seq(6,1)
            }else{
              score_matrix[i,] <- rev(seq(6,1))
            }
            
          }
          
          k <- as.numeric(assmt.results$math) #c( 2, 3, 4, 3, 6, 3, 4, 2)
          j <- 3
          score <- rep(NA, 8)
          for(j in 1:length(k)){
            score[j] <- score_matrix[j, k[j]]
          }
          
          sum_score <- sum(na.omit(score))
        }
        
        if(is.na(sum_score) == TRUE){
          fluidPage(
            p("")
            )
        }else{if(sum_score < 17){
        fluidPage(
        tags$h2("Your Score Suggests", align = "center"),
       
        p("Still a ways to go! Right now, you lean toward thinking that your intelligence doesn’t 
          change much. You prefer not to make mistakes if you can help it. You probably don’t really 
          like to put in a lot of effort on things that don’t come easily to you, because you don’t 
          really expect it will help. You may think that learning should be fast and when you find 
          something difficult you may feel like giving up."
          ),
        
        p("Most everyone has these beliefs to some extent, or in some area of their life. By 
          learning to approach life with a growth mindset, you may find yourself learning more, 
          and achieving successes in areas where you thought you just weren’t any good. This 
          transition may be difficult at first, but it feels great to work hard and improve, and 
          succeed where you thought you couldn’t. A good approach you can use to more consistently 
          approach challenges with a growth mindset is to examine your language and behavior. 
          If you are avoiding tasks that are difficult for you, there is probably a fixed mindset at 
          the root – a belief that you can’t improve much.  Instead, recognize that when works is 
          difficult, that is exactly when you are learning the most!"
          ),
      
        br()
        )
          
        }else{if( 16 < sum_score & sum_score < 33){
          fluidPage(
            tags$h2("Your Score Suggests", align = "center"),
            
            p("You’re on your way! You sometimes feel like your abilities, skills, and intelligence 
              can be improved through effort. Other times you feel like no matter how hard you work, 
              it won’t change your basic skill level.  Scientific evidence suggests, however, that 
              you CAN improve through effort and hard work, so your task is to more consistently 
              approach challenges knowing you can get better."
              ),
            
            p("A good approach that you can use to more consistently approach challenges with a 
              growth mindset is to examine your language and behavior. If you are avoiding tasks that
              are difficult for you, there is probably a fixed mindset at the root – a belief that you
              can’t improve much. Instead, recognize that when work is difficult, that is exactly
              when you are learning the most!"
              ),
            
            br()
            )
  
        }else{
          fluidPage(
            tags$h2("Your Score Suggests", align = "center"),
            
            p("Excellent! You are thinking with a growth mindset most of the time. You are ok with 
              challenging work because you know that is the fastest way to improve your current 
              abilities.  You don’t see getting an answer wrong as the worst thing in the world, 
              because now you will know that answer next time."
              ),
            
            p("Even people that have a growth mindset most of the time often have areas in their
              life where they don’t apply the same logic.  For example, even people that have worked
              hard to improve in athletics may not approach math or art with the same mindset. 
              Given where you are starting, your task should be to look for exceptions to your 
              growth mindset – are there times, places, or subjects where you might apply a growth 
              mindset more consistently? Are there ways to help your friends, family, or classmates 
              see their own potential for growth?"
            ),
            
            br()
            )
        }
        }}
      })
     
######################################################################      
      
######### BUILDING THE INTERACTIVE QUIZ
      
######################################################################      
      
      
###########################  1   #####################
   
      output$quiz_question_1_lesson <- renderUI({ 
       
       if(length(input$quiz_question_1) == 0){
         fluidPage(
           )
         
       }else{if(input$quiz_question_1 == 2){
          fluidPage(
            tags$h2("Right! You chose the correct answer.", align = "center"),
            
            p("Although it’s nice to hear that someone thinks you are smart, by phrasing the 
              compliment in this way the teacher is implying that a student’s achievements are 
              due to their innate characteristics (being smart), rather than due to the effort 
              put in. This indicates a fixed mindset."
              )
            )
        }else{
          fluidPage(
            tags$h2("Not quite! Let's talk through the problem", align = "center"),
            
            p("Although it’s nice to hear that someone thinks you are smart, by phrasing the 
              compliment in this way the teacher is implying that a student’s achievements are 
              due to their innate characteristics (being smart), rather than due to the effort 
              put in. This indicates a fixed mindset."
              )
            )
        
        }
       }
        
      })
      
###########################  2   #####################
      output$quiz_question_2_lesson <- renderUI({ 
        
        if(length(input$quiz_question_2) == 0){
          fluidPage(
          )
          
        }else{if(input$quiz_question_2 == 1){
          fluidPage(
              tags$h2("Right! You chose the correct answer.", align = "center"),
              
              p("By praising effort, the teacher is recognizing that achievement was the result of 
                the student’s hard work, rather than indicating something about the student’s innate 
                talent or intelligence. This is consistent with a growth mindset."
                )
              )
        }else{
          fluidPage(
            tags$h2("Not quite! Let's talk through the problem", align = "center"),
            
            p("By praising effort, the teacher is recognizing that achievement was the result of 
                the student’s hard work, rather than indicating something about the student’s innate 
              talent or intelligence. This is consistent with a growth mindset."
              )
            )
          
        }
        }
        
      })
      
      ###########################  3   #####################3
      output$quiz_question_3_lesson <- renderUI({ 
        
        if(length(input$quiz_question_3) == 0){
          fluidPage(
            #p("Answer me one little question"),
          )
          
          
        }else{if(input$quiz_question_3 == 1){
          fluidPage(
            tags$h2("Right! You chose the correct answer.", align = "center"),
            
            p("The coach recognizes that the player’s performance depends on the effort and 
              discipline put into practice, rather than being the result of inborn talent. 
              This indicates the coach has a growth mindset."
              )
            )
        }else{
          fluidPage(
            tags$h2("Not quite! Let's talk through the problem", align = "center"),
            
            p("The coach recognizes that the player’s performance depends on the effort and 
              discipline put into practice, rather than being the result of inborn talent. 
              This indicates the coach has a growth mindset."
            )
            )
          
        }
        }
        
      })
      
      ###########################  4   #####################3
      output$quiz_question_4_lesson <- renderUI({ 
        
        if(length(input$quiz_question_4) == 0){
          fluidPage(
          )
          
        }else{if(input$quiz_question_4 == 2){
          fluidPage(
            tags$h2("Right! You chose the correct answer.", align = "center"),
            
            p("By telling the player ‘you are not cut out for this,’ the coach is implying that 
              there is something about the player that makes them bad at this sport, and that 
              cannot be changed through practice or effort. The coach is also falling into a common 
              trap of the fixed mindset—that it is better to just give up because you can’t change."
              )
            )
        }else{
          fluidPage(
            tags$h2("Not quite! Let's talk through the problem", align = "center"),
            
            p("By telling the player ‘you are not cut out for this,’ the coach is implying that 
              there is something about the player that makes them bad at this sport, and that 
              cannot be changed through practice or effort. The coach is also falling into a common 
              trap of the fixed mindset—that it is better to just give up because you can’t change."
            )
          )
        }
        }
        
      })
      
      ###########################  5   #####################3
      output$quiz_question_5_lesson <- renderUI({ 
        
        if(length(input$quiz_question_5) == 0){
          fluidPage(
          )
        
        }else{if(input$quiz_question_5 == 2){
          fluidPage(
            tags$h2("Right! You chose the correct answer.", align = "center"),
            
            p("By avoiding a difficult problem (drawing hands) due to fear of failure, the artist is
              indicating that they prioritize performance over improving their skills. This indicates
              a fixed mindset.  An artist with a growth mindset would instead seek out more 
              opportunities to draw hands. They might be terrible drawings at first, but eventually 
              the artist’s skills at drawing hands would improve and they would be a better 
              artist all around."
              )
          )
        }else{
          fluidPage(
            tags$h2("Not quite! Let's talk through the problem", align = "center"),
            
            p("By avoiding a difficult problem (drawing hands) due to fear of failure, the artist is
              indicating that they prioritize performance over improving their skills. This indicates
              a fixed mindset.  An artist with a growth mindset would instead seek out more 
              opportunities to draw hands. They might be terrible drawings at first, but eventually 
              the artist’s skills at drawing hands would improve and they would be a better 
              artist all around."
            )
          )
        }
        }
        
      })
      
      ###########################  6   #####################3
      output$quiz_question_6_lesson <- renderUI({ 
        
        if(length(input$quiz_question_6) == 0){
          fluidPage(
          )
          
          
        }else{if(input$quiz_question_6 == 2){
          fluidPage(
            tags$h2("Right! You chose the correct answer.", align = "center"),
            
            p("By stating ‘I am just not good at chemistry,’ the student indicates that they believe
              that their skill in chemistry is fixed and cannot improve. This indicates a fixed 
              mindset. Because of that fixed mindset, the student is choosing to avoid a difficult 
              course in which they might have more opportunities to improve. This is one cost of 
              fixed mindset—you might needlessly limit yourself and your opportunities."
              )
            )
        }else{
          fluidPage(
            tags$h2("Not quite! Let's talk through the problem", align = "center"),
            
            p("By stating ‘I am just not good at chemistry,’ the student indicates that they believe
              that their skill in chemistry is fixed and cannot improve. This indicates a fixed 
              mindset. Because of that fixed mindset, the student is choosing to avoid a difficult 
              course in which they might have more opportunities to improve. This is one cost of 
              fixed mindset—you might needlessly limit yourself and your opportunities."
            )
          )
        }
        }
        
      })
      
      ###########################  7   #####################3
      output$quiz_question_7_lesson <- renderUI({ 
        
        if(length(input$quiz_question_7) == 0){
          fluidPage(
          )
          
        }else{if(input$quiz_question_7 == 1){
          fluidPage(
            tags$h2("Right! You chose the correct answer.", align = "center"),
            
            p("While this person certainly doesn’t have a good attitude about physics, 
              by recognizing that they could improve at physics if they put in the time and effort, 
              they actually are demonstrating a growth mindset. Growth versus fixed mindset is a 
              bit more complicated than just a ‘good attitude’ or ‘bad attitude,’ and it’s important 
              to understand the distinction since research supports that a growth mindset improves 
              learning."
              )
            )
        }else{
          fluidPage(
            tags$h2("Not quite! Let's talk through the problem", align = "center"),
            
            p("While this person certainly doesn’t have a good attitude about physics, 
              by recognizing that they could improve at physics if they put in the time and effort, 
              they actually are demonstrating a growth mindset. Growth versus fixed mindset is a 
              bit more complicated than just a ‘good attitude’ or ‘bad attitude,’ and it’s important 
              to understand the distinction since research supports that a growth mindset improves 
              learning."
            )
            )
          
        }
        }
        
      })
      
      ###########################  8   #####################3
      output$quiz_question_8_lesson <- renderUI({ 
        
        if(length(input$quiz_question_8) == 0){
          fluidPage(
          )

        }else{if(input$quiz_question_8 == 2){
          fluidPage(
            tags$h2("Right! You chose the correct answer.", align = "center"),
            
            p("Growth and fixed mindset can apply to all areas of our lives, not just our academic 
              subjects. People who demonstrate growth mindset in academic work might actually have a 
              fixed mindset in social situations. By claiming ‘I am doomed to be alone forever,’ the 
              student is implying that there is no way to improve their communication skills so that 
              future relationships might have a better chance of success. This indicates a fixed 
              mindset."
              )
            )
        }else{
          fluidPage(
            tags$h2("Not quite! Let's talk through the problem", align = "center"),
            
            p("Growth and fixed mindset can apply to all areas of our lives, not just our academic 
              subjects. People who demonstrate growth mindset in academic work might actually have a 
              fixed mindset in social situations. By claiming ‘I am doomed to be alone forever,’ the 
              student is implying that there is no way to improve their communication skills so that 
              future relationships might have a better chance of success. This indicates a fixed 
              mindset."
            )
            )
          
        }
        }
        
      })
  
      
##############
      
      output$downer <- renderPlot({
        if(length(assmt.results$math) > 0) {

          score_matrix <- matrix(NA, length(math.items[,3]), 6 )
          score <- rep(NA, 8)
          k <- as.numeric(assmt.results$math)
          
          for(i in 1:length(math.items[,3])){
            if(math.items[i,3] == "A"){
              score_matrix[i,] <- seq(6,1)
            }else{
              score_matrix[i,] <- rev(seq(6,1))
              }
    
            }
    
          for(j in 1:length(k)){
            score[j] <- score_matrix[j, k[j]]
            }
    
          sum_score <- sum(na.omit(score))
          sum_score_1 <- dat[sum_score,]
    
          pdf("www/Growth Mindset module_summary.pdf", height = 11, width=8.5)
          require(png)
    
          par(mar=c(0,0,0,0))
          #now open a plot window with coordinates
          plot(1:10,ty="n", bty='n', xaxt="n", yaxt="n", xlab="", ylab="", ylim=c(1.35,9.65), xlim=c(1.35,9.65))
          #specify the position of the image through bottom-left and top-right coords
    
          #xleft, ybottom, xright, ytop
          rasterImage(img4,1,1,10,10)
          rasterImage(img[260:1800, 1:3300, ],3.5,5.3,8,7.45)
    
          #dat transform to fit in the right place on the graph
          dat2 <- dat
          dat2[,1] <- (dat2[,1] * 0.7) + 1.9
          dat2[,2] <- (dat2[,2] * 0.45) + 3.5
          points(dat2, cex=1.6, pch=20, col="#8FB230")
          points(dat2[1:sum_score,], cex=1.6, pch=20, col="#1176ff")
    
          #print pdf to file
          dev.off()
          
          #report back when complete
          print("Download printed!!")
        }
      })

      
    #Download button copies file from folder to user's download folder.
      output$downloadReport <- downloadHandler(
        filename = function() {"Growth Mindset module_summary.pdf"},
        content = function(file) {
          file.copy("www/Growth Mindset module_summary.pdf", file)
          }
      )
      
    
      
    
#####
})