/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-11-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@isTest
private class KnockoutStageOverviewControllerTest {
  @isTest
  static void testGetMatchesOverview() {
    // Create test data
    Tournament__c tournament = new Tournament__c(
      Name = 'Test Tournament',
      Code__c = 'TEST',
      Start_Date__c = Date.today()
    );
    insert tournament;
    List<Team__c> teams = new List<Team__c>();
    for (Integer i = 0; i < 5; i++) {
      teams.add(new Team__c(Name = 'Test Team ' + i, Code__c = 'T' + i));
    }
    insert teams;
    List<Match__c> matches = new List<Match__c>();
    for (String stage : StageUtility.KO_STAGES) {
      Integer teamIndex = StageUtility.KO_STAGES.indexOf(stage);
      matches.add(
        new Match__c(
          Tournament__c = tournament.Id,
          Home_Team__c = teams[teamIndex].Id,
          Away_Team__c = teams[Math.mod((teamIndex + 1), 4)].Id,
          Home_Team_Goals__c = 2,
          Away_Team_Goals__c = 1,
          Winner_Team__c = teams[teamIndex].Id,
          Stage__c = stage,
          Date__c = Date.today().addDays(teamIndex)
        )
      );
    }
    TriggerHandler.bypass('MatchTriggerHandler');
    insert matches;
    // Invoke the getMatchesOverview method
    Test.startTest();
    Map<String, List<MatchOverview>> result = KnockoutStageOverviewController.getMatchesOverview(
      tournament.Id
    );
    Test.stopTest();
    // Verify the results
    System.assertEquals(
      StageUtility.KO_STAGES.size(),
      result.size(),
      'The number of stages should match the predefined knockout stages'
    );
    for (String stage : StageUtility.KO_STAGES) {
      List<MatchOverview> matchOverviews = result.get(stage);
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
