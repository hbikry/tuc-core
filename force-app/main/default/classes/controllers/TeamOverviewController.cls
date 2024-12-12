/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-12-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class TeamOverviewController {
  @AuraEnabled
  public static Map<String, Map<String, List<MatchOverview>>> getTeamMatchesOverview(
    Id teamId
  ) {
    Map<String, Map<String, List<MatchOverview>>> overviewMap = new Map<String, Map<String, List<MatchOverview>>>();

    List<Match__c> matches = [
      SELECT
        Id,
        Stage__c,
        Date__c,
        Tournament__r.Code__c,
        Tournament__r.Name,
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
      WHERE Home_Team__c = :teamId OR Away_Team__c = :teamId
      WITH USER_MODE
      ORDER BY Date__c ASC
    ];

    for (Match__c match : matches) {
      String tournamentKey = match.Tournament__r.Name;
      if (!overviewMap.containsKey(tournamentKey)) {
        overviewMap.put(tournamentKey, new Map<String, List<MatchOverview>>());
      }

      if (!overviewMap.get(tournamentKey).containsKey(match.Stage__c)) {
        overviewMap.get(tournamentKey)
          .put(match.Stage__c, new List<MatchOverview>());
      }

      overviewMap.get(tournamentKey)
        .get(match.Stage__c)
        .add(new MatchOverview(match));
    }

    return overviewMap;
  }
}
