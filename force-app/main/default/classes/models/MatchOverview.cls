/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 11-30-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class MatchOverview {
  @AuraEnabled
  public Id id;
  @AuraEnabled
  public String stage;
  @AuraEnabled
  public Datetime matchDate;
  @AuraEnabled
  public Id homeTeamId;
  @AuraEnabled
  public String homeTeamName;
  @AuraEnabled
  public String homeTeamCode;
  @AuraEnabled
  public String homeTeamFlagCode;
  @AuraEnabled
  public Integer homeTeamGoals;
  @AuraEnabled
  public Id awayTeamId;
  @AuraEnabled
  public String awayTeamName;
  @AuraEnabled
  public String awayTeamCode;
  @AuraEnabled
  public String awayTeamFlagCode;
  @AuraEnabled
  public Integer awayTeamGoals;
  @AuraEnabled
  public Id winnerTeamId;
  @AuraEnabled
  public Boolean draw;

  public MatchOverview(Match__c match) {
    this.Id = match.Id;
    this.stage = match.Stage__c;
    this.matchDate = match.Date__c;
    this.homeTeamId = match.Home_Team__r.Id;
    this.homeTeamName = match.Home_Team__r.Name;
    this.homeTeamCode = match.Home_Team__r.Code__c;
    this.homeTeamFlagCode = match.Home_Team__r.Flag_Code__c;
    this.homeTeamGoals = (Integer) match.Home_Team_Goals__c;
    this.awayTeamId = match.Away_Team__r.Id;
    this.awayTeamName = match.Away_Team__r.Name;
    this.awayTeamCode = match.Away_Team__r.Code__c;
    this.awayTeamFlagCode = match.Away_Team__r.Flag_Code__c;
    this.awayTeamGoals = (Integer) match.Away_Team_Goals__c;
    this.winnerTeamId = match.Winner_Team__c;
    this.draw = match.Draw__c;
  }
}
