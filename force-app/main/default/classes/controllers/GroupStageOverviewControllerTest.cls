/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-11-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@isTest
private class GroupStageOverviewControllerTest {
  @isTest
  static void testGetGroupStageOverview() {
    // Create test data
    Tournament__c tournament = new Tournament__c(
      Name = 'Test Tournament',
      Code__c = 'TEST',
      Start_Date__c = Date.today()
    );
    insert tournament;
    List<Team__c> teams = new List<Team__c>();
    for (Integer i = 0; i < 8; i++) {
      teams.add(new Team__c(Name = 'Test Team ' + i, Code__c = 'T' + i));
    }
    insert teams;
    List<Tournament_Team__c> tournamentTeams = new List<Tournament_Team__c>();
    for (Integer i = 0; i < 8; i++) {
      tournamentTeams.add(
        new Tournament_Team__c(
          Tournament__c = tournament.Id,
          Team__c = teams[i].Id,
          Group__c = GroupUtility.GROUPS[i],
          Goals_For__c = 10,
          Goals_Against__c = 5,
          Wins__c = 3,
          Losses__c = 1,
          Draws__c = 1,
          Eliminated__c = false
        )
      );
    }
    TriggerHandler.bypass('TournamentTeamTriggerHandler');
    insert tournamentTeams;
    List<Match__c> matches = new List<Match__c>();
    for (Integer i = 0; i < 8; i++) {
      matches.add(
        new Match__c(
          Tournament__c = tournament.Id,
          Home_Team__c = teams[i].Id,
          Away_Team__c = teams[Math.mod((i + 1), 4)].Id,
          Home_Team_Goals__c = 2,
          Away_Team_Goals__c = 1,
          Winner_Team__c = teams[i].Id,
          Stage__c = StageUtility.ROUND_1_GROUP_STAGE,
          Date__c = Datetime.now().addDays(i)
        )
      );
    }
    TriggerHandler.bypass('MatchTriggerHandler');
    insert matches;
    // Invoke the getGroupStageOverview method
    Test.startTest();
    Map<String, GroupOverview> result = GroupStageOverviewController.getGroupStageOverview(
      tournament.Id
    );
    Test.stopTest();
    // Verify the results
    System.assertEquals(
      GroupUtility.GROUPS.size(),
      result.size(),
      'The number of groups should match the predefined groups'
    );
    for (String groupName : GroupUtility.GROUPS) {
      GroupOverview groupOverview = result.get(groupName);
      if (groupOverview != null) {
        System.assertEquals(
          groupName,
          groupOverview.groupName,
          'Group name should match'
        );
        System.assertNotEquals(
          0,
          groupOverview.teamsStats.size(),
          'Teams stats should not be empty'
        );
        System.assertNotEquals(
          0,
          groupOverview.matches.size(),
          'Matches should not be empty'
        );
      }
    }
  }
}
