/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 11-30-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class TeamStats {
  @AuraEnabled
  public Id teamId;
  @AuraEnabled
  public String teamName;
  @AuraEnabled
  public String teamCode;
  @AuraEnabled
  public String teamFlagCode;
  @AuraEnabled
  public Integer goalsFor;
  @AuraEnabled
  public Integer goalsAgainst;
  @AuraEnabled
  public Integer goalsDifference;
  @AuraEnabled
  public Integer matchesPlayed;
  @AuraEnabled
  public Integer wins;
  @AuraEnabled
  public Integer losses;
  @AuraEnabled
  public Integer draws;
  @AuraEnabled
  public Integer points;

  public TeamStats(Tournament_Team__c tournamentTeam) {
    this.teamId = tournamentTeam.Team__c;
    this.teamName = tournamentTeam.Team__r.Name;
    this.teamCode = tournamentTeam.Team__r.Code__c;
    this.teamFlagCode = tournamentTeam.Team__r.Flag_Code__c;
    this.goalsFor = (Integer) tournamentTeam.Goals_For__c;
    this.goalsAgainst = (Integer) tournamentTeam.Goals_Against__c;
    this.goalsDifference = (Integer) tournamentTeam.Goal_Difference__c;
    this.matchesPlayed = (Integer) tournamentTeam.Matches_Played__c;
    this.wins = (Integer) tournamentTeam.Wins__c;
    this.losses = (Integer) tournamentTeam.Losses__c;
    this.draws = (Integer) tournamentTeam.Draws__c;
    this.points = (Integer) tournamentTeam.Points__c;
  }
}
