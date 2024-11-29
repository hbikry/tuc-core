/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 11-29-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class TournamentOverviewController {
  private final static Map<String, String> STAGES = new Map<String, String>{
    StageUtility.ROUND_1_GROUP_STAGE => 'Round 1',
    StageUtility.ROUND_2_GROUP_STAGE => 'Round 2',
    StageUtility.ROUND_3_GROUP_STAGE => 'Round 3',
    StageUtility.ROUND_OF_16_KO_STAGE => 'Round of 16',
    StageUtility.QUARTERFINAL_KO_STAGE => 'Quarter-finals',
    StageUtility.SEMIFINAL_KO_STAGE => 'Semi-finals',
    StageUtility.THIRD_PLACE_KO_STAGE => 'Third place',
    StageUtility.FINAL_KO_STAGE => 'Final'
  };

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
      String stage = TournamentOverviewController.STAGES.get(match.Stage__c);

      if (!matchOverviewByStage.containsKey(stage)) {
        matchOverviewByStage.put(stage, new List<MatchOverview>());
      }

      matchOverviewByStage.get(stage).add(new MatchOverview(match));
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
        Home_Team_Goals__c,
        Away_Team__r.Id,
        Away_Team__r.Name,
        Away_Team__r.Code__c,
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
    public Integer homeTeamGoals;
    @AuraEnabled
    public Id awayTeamId;
    @AuraEnabled
    public String awayTeamName;
    @AuraEnabled
    public String awayTeamCode;
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
      this.homeTeamGoals = (Integer) match.Home_Team_Goals__c;
      this.awayTeamId = match.Away_Team__r.Id;
      this.awayTeamName = match.Away_Team__r.Name;
      this.awayTeamCode = match.Away_Team__r.Code__c;
      this.awayTeamGoals = (Integer) match.Away_Team_Goals__c;
      this.winnerTeamId = match.Winner_Team__c;
      this.draw = match.Draw__c;
    }
  }
}
