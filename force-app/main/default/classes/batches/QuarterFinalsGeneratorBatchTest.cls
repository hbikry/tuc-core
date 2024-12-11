/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-11-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@isTest
private class QuarterFinalsGeneratorBatchTest {
  @isTest
  static void testQuarterFinalsGeneratorBatch() {
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
    List<Match__c> roundOf16Matches = new List<Match__c>();
    for (Integer i = 0; i < 8; i++) {
      roundOf16Matches.add(
        new Match__c(
          Tournament__c = tournament.Id,
          Home_Team__c = teams[i].Id,
          Away_Team__c = teams[Math.mod((i + 1), 8)].Id,
          Winner_Team__c = teams[i].Id,
          Stage__c = StageUtility.ROUND_OF_16_KO_STAGE,
          Date__c = Datetime.now().addDays(i)
        )
      );
    }
    TriggerHandler.bypass('MatchTriggerHandler');
    insert roundOf16Matches;
    // Execute the batch
    Test.startTest();
    QuarterFinalsGeneratorBatch batch = new QuarterFinalsGeneratorBatch(
      tournament.Id,
      'testTransactionId'
    );
    Database.executeBatch(batch);
    Test.stopTest();
    // Verify the results
    List<Match__c> matches = [
      SELECT Id, Home_Team__c, Away_Team__c, Stage__c
      FROM Match__c
      WHERE Stage__c = :StageUtility.QUARTERFINAL_KO_STAGE
    ];
    System.assertEquals(
      4,
      matches.size(),
      'Four matches should be created for the Quarter-Finals'
    );
    // Verify that matches are created correctly
    for (Match__c match : matches) {
      System.assertEquals(
        StageUtility.QUARTERFINAL_KO_STAGE,
        match.Stage__c,
        'Match stage should be Quarter-Finals'
      );
    }
  }
}
