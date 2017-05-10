library(shiny)
library(plotly)
library(ggplot2)
library(GGally)
library(shinythemes)
library(d3treeR)

shinyUI(fluidPage(theme = shinytheme('flatly'),
  navbarPage("The Twisted Plotline: League of Legends Data Visualization",
####### Overview #######
             tabPanel('Overview',
                      includeMarkdown('overview.md')
                    ),
####### Teamwork #######
      tabPanel('Teamwork: Kills vs. Assists',
               fluidPage(
                 fluidRow(column(3,
                                 checkboxGroupInput(inputId = "fitline_teamwork",
                                                    label = "Add Fitlines?",
                                                    choices = c('Yes!'='fit')),
                                 includeText('teamwork.txt')),
                          column(9,  plotlyOutput('teamwork', height='600'))
                 )
               )
               ),
####### Champ Select #######
      tabPanel('Champion Select',
               fluidPage(
                 fluidRow(column(3,
                                 radioButtons("pickban", label = h3("Champion Selection"),
                                              choices = list("Most Picked" = "pick", 
                                                             "Most Banned" = "ban"
                                                             ), 
                                              selected = "pick"),
                                 includeText('champions.txt')),
                          column(9, plotlyOutput('pickbanplot', height='600'))
                 )
               )
    ),
####### Stats over Time #######
    tabPanel("Stats over Time",
               fluidPage(
               fluidRow(column(3,
               radioButtons("teamstats", label = h3("Team Statistics"),
                            choices = list("Gold Earned" = "teamGold", "Creeps Killed" = "teamCreeps", 
                                           "Damage Dealt" = "teamDamage", "Experience Gained" = "teamXp",
                                           "Kills Total" = "teamKills", "Deaths Total" = "teamDeaths",
                                           "Assists Total" = "teamAssists"), 
                            selected = "teamGold"),
               includeText('gold.txt')),
               column(9, plotlyOutput('stats', height='600'))
               )
             )
    ),
####### ADC / Support #######
    tabPanel('Player Differentiation',
             fluidPage(
               fluidRow(column(3,
                               radioButtons('parcoordInput',label='Select Factor',
                                            choices = c('Win vs. Loss' = 'Winner',
                                                        'Player Rank' = 'Rank',
                                                        'Champion Role' = 'Role'),
                                            selected = "Winner"),
                                            includeMarkdown('pcp.md')),
                               column(9, plotlyOutput("parcoordplot", height='600', width='auto'))

               )
             )
             
             
    ),
tabPanel('Champion Tree Map',
         fluidPage(
           fluidRow(column(3,
                           radioButtons('champtree',label='Select Match Outcome',
                                        choices = c('Win' = 'Yes',
                                                    'Lose' = 'No'),
                                        selected = "Yes"),
                           includeMarkdown('tree.md')),
                    column(9, d3tree2Output("treemap", height='600', width='auto'))
                    
           )
         )
         
         
)
  )

)
)





