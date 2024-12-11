/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-11-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@isTest
private class SemiFinalsGeneratorBatchTest {
  @isTest
  static void testSemiFinalsGeneratorBatch() {
    // Create test data
    Tournament__c tournament = new Tournament__c(
      Name = 'Test Tournament',
      Code__c = 'TEST',
      Start_Date__c = Date.today()
    );
    insert tournament;
    List<Team__c> teams = new List<Team__c>();
    for (Integer i = 0; i < 4; i++) {
      teams.add(new Team__c(Name = 'Test Team ' + i));
    }
    insert teams;
    List<Match__c> quarterFinalsMatches = new List<Match__c>();
    for (Integer i = 0; i < 4; i++) {
      quarterFinalsMatches.add(
        new Match__c(
          Tournament__c = tournament.Id,
          Home_Team__c = teams[i].Id,
          Away_Team__c = teams[Math.mod((i + 1), 4)].Id,
          Winner_Team__c = teams[i].Id,
          Stage__c = StageUtility.QUARTERFINAL_KO_STAGE,
          Date__c = Datetime.now().addDays(i)
        )
      );
    }
    TriggerHandler.bypass('MatchTriggerHandler');
    insert quarterFinalsMatches;
    // Execute the batch
    Test.startTest();
    SemiFinalsGeneratorBatch batch = new SemiFinalsGeneratorBatch(
      tournament.Id,
      'testTransactionId'
    );
    Database.executeBatch(batch);
    Test.stopTest();
    // Verify the results
    List<Match__c> matches = [
      SELECT Id, Home_Team__c, Away_Team__c, Stage__c
      FROM Match__c
      WHERE Stage__c = :StageUtility.SEMIFINAL_KO_STAGE
    ];
    System.assertEquals(
      2,
      matches.size(),
      'Two matches should be created for the Semi-Finals'
    );
    // Verify that matches are created correctly
    for (Match__c match : matches) {
      System.assertEquals(
        StageUtility.SEMIFINAL_KO_STAGE,
        match.Stage__c,
        'Match stage should be Semi-Finals'
      );
    }
  }
}
