/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-02-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class GroupStageOverviewController {
  @AuraEnabled
  public static Map<String, GroupOverview> getGroupStageOverview(
    Id tournamentId
  ) {
    Map<String, GroupOverview> overviewByGroup = new Map<String, GroupOverview>();

    List<Match__c> groupMatches = MatchUtility.getOverviewMatches(
      tournamentId,
      StageUtility.GROUP_STAGES
    );
    List<Tournament_Team__c> tournamentTeams = TournamentTeamUtility.getOverviewTournamentTeams(
      new Set<Id>{ tournamentId }
    );

    Map<Id, String> groupsByTeam = new Map<Id, String>();

    for (String groupName : GroupUtility.GROUPS) {
      GroupOverview groupOverview = new GroupOverview(groupName);

      for (Tournament_Team__c tournamentTeam : tournamentTeams) {
        GroupStageOverviewController.addTeamStats(
          groupOverview,
          tournamentTeam,
          groupsByTeam
        );
      }

      for (Match__c match : groupMatches) {
        if (groupsByTeam.get(match.Home_Team__c) == groupName) {
          groupOverview.addMatchOverview(new MatchOverview(match));
        }
      }

      if (!overviewByGroup.containsKey(groupName)) {
        overviewByGroup.put(groupName, groupOverview);
      }
    }

    return overviewByGroup;
  }

  private static void addTeamStats(
    GroupOverview groupOverview,
    Tournament_Team__c tournamentTeam,
    Map<Id, String> groupsByTeam
  ) {
    if (!groupsByTeam.containsKey(tournamentTeam.Team__c)) {
      groupsByTeam.put(tournamentTeam.Team__c, tournamentTeam.Group__c);
    }

    if (tournamentTeam.Group__c == groupOverview.groupName) {
      groupOverview.addTeamStats(new TeamStats(tournamentTeam));
    }
  }
}
