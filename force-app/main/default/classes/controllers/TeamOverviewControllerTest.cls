/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-11-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@isTest
private class TeamOverviewControllerTest {
  @isTest
  static void testGetTeamMatchesOverview() {
    // Create test data
    Tournament__c tournament1 = new Tournament__c(
      Name = 'Test Tournament 1',
      Code__c = 'TOUR1',
      Start_Date__c = Date.today()
    );
    Tournament__c tournament2 = new Tournament__c(
      Name = 'Test Tournament 2',
      Code__c = 'TOUR2',
      Start_Date__c = Date.today()
    );
    insert new List<Tournament__c>{ tournament1, tournament2 };
    Team__c team = new Team__c(Name = 'Test Team', Code__c = 'T1');
    insert team;
    List<Team__c> otherTeams = new List<Team__c>();
    for (Integer i = 0; i < 3; i++) {
      otherTeams.add(new Team__c(Name = 'Other Team ' + i, Code__c = 'O' + i));
    }
    insert otherTeams;
    List<Match__c> matches = new List<Match__c>();
    for (Integer i = 0; i < 3; i++) {
      matches.add(
        new Match__c(
          Tournament__c = (Math.mod(i, 2) == 0)
            ? tournament1.Id
            : tournament2.Id,
          Home_Team__c = (Math.mod(i, 2) == 0) ? team.Id : otherTeams[i].Id,
          Away_Team__c = (Math.mod(i, 2) == 0) ? otherTeams[i].Id : team.Id,
          Home_Team_Goals__c = 2,
          Away_Team_Goals__c = 1,
          Winner_Team__c = (Math.mod(i, 2) == 0) ? team.Id : otherTeams[i].Id,
          Stage__c = (Math.mod(i, 2) == 0)
            ? StageUtility.ROUND_1_GROUP_STAGE
            : StageUtility.ROUND_OF_16_KO_STAGE,
          Date__c = Date.today().addDays(i)
        )
      );
    }
    TriggerHandler.bypass('MatchTriggerHandler');
    insert matches;
    // Invoke the getTeamMatchesOverview method
    Test.startTest();
    Map<String, Map<String, List<MatchOverview>>> result = TeamOverviewController.getTeamMatchesOverview(
      team.Id
    );
    Test.stopTest();
    // Verify the results
    System.assertEquals(
      2,
      result.size(),
      'The number of tournaments should be 2'
    );
    for (String tournamentCode : result.keySet()) {
      Map<String, List<MatchOverview>> stageMap = result.get(tournamentCode);
      System.assertNotEquals(
        null,
        stageMap,
        'Stage map should not be null for tournament: ' + tournamentCode
      );
      System.assertNotEquals(
        0,
        stageMap.size(),
        'Stage map should not be empty for tournament: ' + tournamentCode
      );
      for (String stage : stageMap.keySet()) {
        List<MatchOverview> matchOverviews = stageMap.get(stage);
        System.assertNotEquals(
          null,
          matchOverviews,
          'Match overviews should not be null for stage: ' + stage
        );
        System.assertNotEquals(
          0,
          matchOverviews.size(),
          'Match overviews should not be empty for stage: ' + stage
        );
      }
    }
  }
}
