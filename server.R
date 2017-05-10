library(shiny)
library(ggplot2)
library(plotly)
library(GGally)
library(dplyr)
library(tidyr)
library(treemap)
library(d3treeR)
library(zoo)

shinyServer(function(input, output) {
  
  set.seed(1)
  matchdf <- read.csv('matchdf_tagfix.csv')
  matchdf <- matchdf[,2:ncol(matchdf)]
  matchdf$Winner <- as.factor(matchdf$Winner)
  levels(matchdf$Winner) <- list('No'="0",'Yes'="1")
  
  match_subset <- matchdf[matchdf$Rank %in% c('CHALLENGER','MASTER', 'DIAMOND'),]
  match_subset$Rank <- "DIAMOND+"
  match_removed <- matchdf[!(matchdf$Rank %in% c('CHALLENGER','MASTER','DIAMOND')),]
  match_subset <- rbind(match_subset, match_removed[c(runif(9565,0,1)>.9),])
  match_subset$Rank <- as.factor(match_subset$Rank)
  Minutes <- as.integer(match_subset$matchDuration/60)
  match_subset <- cbind(match_subset,Minutes)
  match_subset$Rank <- factor(match_subset$Rank, levels = c('UNRANKED',
                                                            'BRONZE',
                                                            'SILVER',
                                                            'GOLD',
                                                            'PLATINUM',
                                                            'DIAMOND+'))

  ####### Overview #######
  
  ####### Teamwork #######

  output$teamwork <- renderPlotly(
    
    if (length(input$fitline_teamwork) == 1){
    ggplotly(ggplot(match_subset, aes(x=Kills, y=Assists))+
                                  geom_count(aes(color=Winner), alpha=0.5)+
                                  geom_smooth(method='lm', se = FALSE ,aes(color=Winner))+
                                  xlab('Number of Kills')+
                                  ylab('Number of Assists')+
                                  scale_x_continuous(breaks=c(0,5,10,15,20,25))+
                                  scale_y_continuous(breaks=c(0,5,10,15,20,25))+
                                  scale_color_manual(values = c("#BC403E", "#5285C4")) +
                                  theme(
                                    axis.title.x = element_text(),
                                    axis.title.y = element_text(),
                                    panel.background = element_blank(),
                                    panel.grid.major = element_line(colour='grey'),
                                    panel.border = element_rect(color = 'grey', fill=NA)
                                  )
                                )} else {
                                  ggplotly(ggplot(match_subset, aes(x=Kills, y=Assists))+
                                             geom_count(aes(color=Winner), alpha=0.5)+
                                             xlab('Number of Kills')+
                                             ylab('Number of Assists')+
                                             scale_x_continuous(breaks=c(0,5,10,15,20,25,30))+
                                             scale_y_continuous(breaks=c(0,5,10,15,20,25,30))+
                                             scale_color_manual(values = c("#BC403E", "#5285C4"))+
                                             theme(
                                               axis.title.x = element_text(),
                                               axis.title.y = element_text(),
                                               panel.background = element_blank(),
                                               panel.grid.major = element_line(colour='grey'),
                                               panel.border = element_rect(color = 'grey', fill=NA)
                                             )
                                  )
                                })
  ####### Champ Select #######
  
  matchdf2 <- read.csv('matchdf.csv', stringsAsFactors = FALSE)
  matchdf2$winner <- as.factor(matchdf2$winner)
  levels(matchdf2$winner) <- list('No'="0",'Yes'="1")
  
  output$pickbanplot <- renderPlotly(
    
    if(input$pickban == "pick"){
      tab <- table(matchdf2$championName)
      tab_s <- sort(tab)
      top10 <- tail(names(tab_s), 20)
      d_s <- subset(matchdf2, championName %in% top10)
      d_s$championName <- factor(d_s$championName, levels = rev(top10))
      d_s <- as.data.frame(table(d_s[c("championName", "winner")]))
      ggplotly(
        ggplot(d_s, aes(x = championName,y = Freq, fill = winner)) + 
          geom_bar(alpha = 0.8, stat = "identity",position = "dodge") + 
          xlab("Picked Champions") + ylab("Count") +
          scale_fill_manual(values = c("#BC403E", "#5285C4")) + 
          theme(
            axis.title.x = element_text(),
            axis.title.y = element_text(),
            panel.background = element_blank(),
            panel.grid.major = element_line(colour='grey'),
            panel.border = element_rect(color = 'grey', fill=NA)
          )
      ) %>% layout(margin = list(l=-50, r=20, b=0, t=50, pad=0),
                   xaxis = list(tickangle = 30, autorange = FALSE),
                   legend = list(title = "Winner", orientation = "h", xanchor = "center",
                                 yanchor = "top", y = -0.14, x = 0.54)) %>%
        add_annotations( text="Winner", xref="paper", yref="paper",
                         x=0.43, xanchor="center",
                         y=-0.149, yanchor="top", legendtitle=TRUE, showarrow=FALSE)
    } else {
      bandf <- matchdf2 %>% 
        group_by(matchteamId, winner, ban1, ban2, ban3) %>%
        summarise(teamGold = sum(endGold, na.rm = TRUE))
      ban1 <- bandf[c("winner", "ban1")]
      names(ban1) <- c("winner", "ban")
      ban2 <- bandf[c("winner", "ban2")]
      names(ban2) <- c("winner", "ban")
      ban3 <- bandf[c("winner", "ban3")]
      names(ban3) <- c("winner", "ban")
      bandf <- rbind(ban1, rbind(ban2, ban3))
      tab <- table(bandf$ban)
      tab_s <- sort(tab)
      top10 <- tail(names(tab_s), 20)
      d_s <- subset(bandf, ban %in% top10)
      d_s$ban <- factor(d_s$ban, levels = rev(top10))
      ggplotly(
        ggplot(d_s, aes(x = ban, fill = factor(winner))) +
        geom_bar(alpha=0.8, position = "dodge") + xlab("Banned Champions") + ylab("Count") +
          scale_fill_manual(values = c("#BC403E", "#5285C4")) +
          theme(
            axis.title.x = element_text(),
            axis.title.y = element_text(),
            panel.background = element_blank(),
            panel.grid.major = element_line(colour='grey'),
            panel.border = element_rect(color = 'grey', fill=NA)
      )) %>% layout(margin = list(l=-50, r=20, b=0, t=50, pad=0),
                    xaxis = list(tickangle = 30),
                    legend = list(title = "Winner", orientation = "h", xanchor = "center",
                                  yanchor = "top", y = -0.14, x = 0.54)) %>%
        add_annotations( text="Winner", xref="paper", yref="paper",
                         x=0.43, xanchor="center",
                         y=-0.149, yanchor="top", legendtitle=TRUE, showarrow=FALSE) 
    }
  )
  
  ####### Stats over Time #######
  
  gametime <- matchdf2[c("matchteamId", "matchDuration", "winner", "kills", "deaths", "assists", 
                        "endGold", "endDamage", "endCreeps", "endXp")]
  
  gametime <- gametime %>% 
    group_by(matchteamId, matchDuration, winner) %>% 
    summarise(teamGold = sum(endGold, na.rm = TRUE),
              teamKills = sum(kills, na.rm = TRUE),
              teamDeaths = sum(deaths, na.rm = TRUE),
              teamAssists = sum(assists, na.rm = TRUE),
              teamDamage = sum(endDamage, na.rm = TRUE),
              teamCreeps = sum(endCreeps, na.rm = TRUE),
              teamXp = sum(endXp, na.rm = TRUE)) %>%
    as.data.frame()

  temp1 <- gametime[gametime$winner == "Yes",]
  temp2 <- gametime[gametime$winner == "No",]
  
  temp1 <- temp1 %>% 
    group_by(matchDuration, winner) %>% 
    summarise(teamGold = mean(teamGold, na.rm = TRUE),
              teamKills = mean(teamKills, na.rm = TRUE),
              teamDeaths = mean(teamDeaths, na.rm = TRUE),
              teamAssists = mean(teamAssists, na.rm = TRUE),
              teamDamage = mean(teamDamage, na.rm = TRUE),
              teamCreeps = mean(teamCreeps, na.rm = TRUE),
              teamXp = mean(teamXp, na.rm = TRUE)) %>%
    as.data.frame()

  temp2<- temp2 %>% 
    group_by(matchDuration, winner) %>% 
    summarise(teamGold = mean(teamGold, na.rm = TRUE),
              teamKills = mean(teamKills, na.rm = TRUE),
              teamDeaths = mean(teamDeaths, na.rm = TRUE),
              teamAssists = mean(teamAssists, na.rm = TRUE),
              teamDamage = mean(teamDamage, na.rm = TRUE),
              teamCreeps = mean(teamCreeps, na.rm = TRUE),
              teamXp = mean(teamXp, na.rm = TRUE)) %>%
    as.data.frame()

  
  output$stats <- renderPlotly({

    temp1.zoo <- zoo(temp1[input$teamstats], temp1$matchDuration)
    temp2.zoo <- zoo(temp2[input$teamstats], temp2$matchDuration)
    
    m.av <- rollmean(temp1.zoo,20,fill=list(NA,NULL,NA))
    temp1$mav = coredata(m.av)
    m.av <- rollmean(temp2.zoo,20,fill=list(NA,NULL,NA))
    temp2$mav = coredata(m.av)
    
    ggplotly(
    ggplot(gametime, aes_string("matchDuration", input$teamstats, color="winner")) + 
      geom_line(alpha=0.5) + 
      geom_line(data=temp1, aes(matchDuration, mav)) + geom_line(data=temp2, aes(matchDuration, mav)) +
      xlab("Match Duration (s)") + ylab("Team Stats") + 
      scale_color_manual(values = c("#BC403E", "#5285C4")) +
      theme(
        axis.title.x = element_text(),
        axis.title.y = element_text(),
        panel.background = element_blank(),
        panel.grid.major = element_line(colour='grey'),
        panel.border = element_rect(color = 'grey', fill=NA)
      )
    ) %>% layout(margin = list(l=-50, r=20, b=0, t=50, pad=0),
      xaxis = list(title = "Match Duration (s)", anchor="free"),
                 yaxis = list(title = "Team Stats", anchor="free"),
                 legend = list(title = "Winner", orientation = "h", xanchor = "center",
                               yanchor = "top", y = -0.13, x = 0.54)) %>%
      add_annotations( text="Winner", xref="paper", yref="paper",
                       x=0.43, xanchor="center",
                       y=-0.139, yanchor="top", legendtitle=TRUE, showarrow=FALSE)
  })
  
  ####### Parallel Coordinates Plot #######
  
  output$parcoordplot <- renderPlotly({
    
    if (input$parcoordInput == 'Winner'){
      scale_pcp <- c("#BC403E", "#5285C4")
    } 
    if (input$parcoordInput == 'Rank'){
      scale_pcp <- c('#543950','#cd7f32','#C0C0C0', '#FFD700','#cecfe2', '#c6dde2')
    } 
    if (input$parcoordInput == 'Role') {
      scale_pcp <- c('#db0000','#93004a','#0000db','#934a00','#00b75c','#002727')
    }
    
    match_subset2 <- match_subset[c(runif(length(match_subset),0,1)>.75),]
    ggplotly(
      ggparcoord(match_subset2, c(7,8,9,12,13,14), groupColumn = input$parcoordInput,
                 scale='globalminmax',
                 title = 'Player Differentiation by Style and Rank',
                 alpha= 0.25)+
        scale_x_discrete(labels=c('Baron Kills',
                                  'Dragon Kills',
                                  'Tower Kills',
                                  'Kills',
                                  'Deaths',
                                  'Assists'))+
        ylab("Count")+
        scale_color_manual(values=scale_pcp)+
        theme(
          axis.title.x = element_blank(),
          axis.title.y = element_text(),
          panel.background = element_blank(),
          panel.grid.major = element_line(colour='grey'),
          panel.border = element_rect(color = 'grey', fill=NA)
        ),tooltip = c("x",'y')) 
  
    
  })
  
  ####### Tree Map #######

  x <- matchdf[c("championName", "Role", "Kills", "Assists", "Deaths", "Winner")]
  
  output$treemap <- renderD3tree2({
    
    x <- x[(x$Winner == input$champtree ),]
    
    x <- x %>%
      group_by(championName, Role) %>%
      summarise(Count = length(championName),
                Kcount = mean(Kills, na.rm = TRUE),
                Acount = mean(Assists, na.rm = TRUE),
                Dcount = mean(Deaths, na.rm = TRUE)
      ) %>%
      as.data.frame()
    
    x["Score"] <- (x$Kcount + x$Acount) / x$Dcount
    
    if(input$champtree == "Yes"){
      
      tm <- treemap(x,
                    index=c("Role", "championName"),
                    vSize="Count",
                    vColor="Score",
                    type="value",
                    palette = "Blues",
                    mapping=c(0, 4, 8),
                    format.legend = list(scientific = FALSE, big.mark = " ")) 
    } else {
      tm <- treemap(x,
                    index=c("Role", "championName"),
                    vSize="Count",
                    vColor="Score",
                    type="value",
                    palette = "Reds",
                    mapping=c(0, 2, 4),
                    format.legend = list(scientific = FALSE, big.mark = " ")) 
    }
    
    d3tree2(tm, rootname = "Champions Tree Map")
    })

})

