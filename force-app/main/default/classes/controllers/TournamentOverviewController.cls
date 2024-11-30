/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 11-29-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class TournamentOverviewController {
  /**
   * @description
   * @author hbikry@salesforce.com | 11-29-2024
   * @param tournamentId
   * @return Map<String, List<MatchOverview>>
   **/
  @AuraEnabled
  public static Map<String, List<MatchOverview>> getKnockoutStageOverview(
    Id tournamentId
  ) {
    Map<String, List<MatchOverview>> matchOverviewByStage = new Map<String, List<MatchOverview>>();

    for (Match__c match : getMatches(tournamentId, StageUtility.KO_STAGES)) {
      if (!matchOverviewByStage.containsKey(match.Stage__c)) {
        matchOverviewByStage.put(match.Stage__c, new List<MatchOverview>());
      }

      matchOverviewByStage.get(match.Stage__c).add(new MatchOverview(match));
    }

    return matchOverviewByStage;
  }

  /**
   * @description
   * @author hbikry@salesforce.com | 11-29-2024
   * @param tournamentId
   * @param stages
   * @return List<Match__c>
   **/
  public static List<Match__c> getMatches(
    Id tournamentId,
    List<String> stages
  ) {
    return [
      SELECT
        Id,
        Stage__c,
        Date__c,
        Home_Team__r.Id,
        Home_Team__r.Name,
        Home_Team__r.Code__c,
        Home_Team__r.Flag_Code__c,
        Home_Team_Goals__c,
        Away_Team__r.Id,
        Away_Team__r.Name,
        Away_Team__r.Code__c,
        Away_Team__r.Flag_Code__c,
        Away_Team_Goals__c,
        Winner_Team__c,
        Draw__c
      FROM Match__c
      WHERE Tournament__c = :tournamentId AND Stage__c IN :stages
      WITH USER_MODE
      ORDER BY Date__c ASC
    ];
  }

  public class MatchOverview {
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
}
