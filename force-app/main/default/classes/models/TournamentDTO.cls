/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-11-2024
 * @last modified by  : hbikry@salesforce.com
 **/
global with sharing class TournamentDTO {
  global class Tournament {
    public String code;
    public String name;
    public Date startDate;
    public String champion;
    public List<Team> teams = new List<Team>();
    public List<Match> matches = new List<Match>();

    public Tournament(Tournament__c tournament) {
      this.code = tournament.Code__c;
      this.name = tournament.Name;
      this.startDate = tournament.Start_Date__c;
      this.champion = tournament.Champion__r.Code__c;
    }
  }

  global class Team {
    public String code;
    public String name;
    public TeamStats stats;

    public Team(String code, String name) {
      this.code = code;
      this.name = name;
    }

    public Team(Tournament_Team__c tournamentTeam) {
      this.code = tournamentTeam.Team__r.Code__c;
      this.name = tournamentTeam.Team__r.Name;
      this.stats = new TeamStats(tournamentTeam);
    }
  }

  global class TeamStats {
    public String groupName;
    public Integer matchesPlayed;
    public Integer wins;
    public Integer losses;
    public Integer draws;
    public Integer goalsFor;
    public Integer goalsAgainst;
    public Integer goalsDifference;
    public Integer points;
    public Boolean eliminated;

    public TeamStats(Tournament_Team__c tournamentTeam) {
      this.groupName = tournamentTeam.Group__c;
      this.matchesPlayed = (Integer) tournamentTeam.Matches_Played__c;
      this.wins = (Integer) tournamentTeam.Wins__c;
      this.losses = (Integer) tournamentTeam.Losses__c;
      this.draws = (Integer) tournamentTeam.Draws__c;
      this.goalsFor = (Integer) tournamentTeam.Goals_For__c;
      this.goalsAgainst = (Integer) tournamentTeam.Goals_Against__c;
      this.goalsDifference = (Integer) tournamentTeam.Goal_Difference__c;
      this.points = (Integer) tournamentTeam.Points__c;
      this.eliminated = tournamentTeam.Eliminated__c;
    }
  }

  global class Match {
    public String homeTeam;
    public String awayTeam;
    public String stage;
    public Datetime matchDate;
    public Integer homeTeamGoals;
    public Integer awayTeamGoals;
    public Boolean draw;
    public String winner;

    public Match(Match__c match) {
      this.homeTeam = match.Home_Team__r.Code__c;
      this.awayTeam = match.Away_Team__r.Code__c;
      this.stage = match.Stage__c;
      this.matchDate = match.Date__c;
      this.homeTeamGoals = (Integer) match.Home_Team_Goals__c;
      this.awayTeamGoals = (Integer) match.Away_Team_Goals__c;
      this.draw = match.Draw__c;
      this.winner = match.Winner_Team__r.Code__c;
    }
  }
}
