/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-01-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class KnockoutStageOverviewController {
  /**
   * @description
   * @author hbikry@salesforce.com | 11-29-2024
   * @param tournamentId
   * @return Map<String, List<MatchOverview>>
   **/
  @AuraEnabled
  public static Map<String, List<MatchOverview>> getMatchesOverview(
    Id tournamentId
  ) {
    Map<String, List<MatchOverview>> matchOverviewByStage = new Map<String, List<MatchOverview>>();

    for (
      Match__c match : MatchUtility.getOverviewMatches(
        tournamentId,
        StageUtility.KO_STAGES
      )
    ) {
      if (!matchOverviewByStage.containsKey(match.Stage__c)) {
        matchOverviewByStage.put(match.Stage__c, new List<MatchOverview>());
      }

      matchOverviewByStage.get(match.Stage__c).add(new MatchOverview(match));
    }

    return matchOverviewByStage;
  }
}
