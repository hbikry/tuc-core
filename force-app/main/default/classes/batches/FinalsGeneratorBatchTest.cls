/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-11-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@isTest
private class FinalsGeneratorBatchTest {
  @isTest
  static void testFinalsGeneratorBatch() {
    // Create test data
    Tournament__c tournament = new Tournament__c(
      Name = 'Test Tournament',
      Code__c = 'TEST',
      Start_Date__c = Date.today()
    );
    insert tournament;
    List<Team__c> teams = new List<Team__c>();
    for (Integer i = 0; i < 4; i++) {
      teams.add(new Team__c(Name = 'Test Team ' + i, Code__c = 'T' + i));
    }
    insert teams;
    List<Match__c> semiFinalsMatches = new List<Match__c>();
    for (Integer i = 0; i < 2; i++) {
      semiFinalsMatches.add(
        new Match__c(
          Tournament__c = tournament.Id,
          Home_Team__c = teams[i * 2].Id,
          Away_Team__c = teams[i * 2 + 1].Id,
          Winner_Team__c = teams[i * 2].Id,
          Stage__c = StageUtility.SEMIFINAL_KO_STAGE,
          Date__c = Datetime.now().addDays(i)
        )
      );
    }

    TriggerHandler.bypass('MatchTriggerHandler');
    insert semiFinalsMatches;
    // Execute the batch
    Test.startTest();
    FinalsGeneratorBatch batch = new FinalsGeneratorBatch(
      tournament.Id,
      'testTransactionId'
    );
    Database.executeBatch(batch);
    Test.stopTest();
    // Verify the results
    List<Match__c> matches = [
      SELECT Id, Home_Team__c, Away_Team__c, Stage__c
      FROM Match__c
      WHERE
        Stage__c IN (
          :StageUtility.THIRD_PLACE_KO_STAGE,
          :StageUtility.FINAL_KO_STAGE
        )
    ];
    System.assertEquals(
      2,
      matches.size(),
      'Two matches should be created: one for third place and one for the final'
    );
    // Verify that matches are created correctly
    for (Match__c match : matches) {
      System.assert(
        match.Stage__c == StageUtility.THIRD_PLACE_KO_STAGE ||
          match.Stage__c == StageUtility.FINAL_KO_STAGE,
        'Match stage should be either Third Place or Final'
      );
    }
  }
}
