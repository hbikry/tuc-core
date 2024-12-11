/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-11-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@isTest
private class DeleteTournamentDataControllerTest {
  @isTest
  static void testDeleteAllTournamentData() {
    // Create test data
    List<Tournament__c> tournaments = new List<Tournament__c>();
    for (Integer i = 0; i < 3; i++) {
      tournaments.add(
        new Tournament__c(
          Name = 'Test Tournament ' + i,
          Code__c = 'TEST' + i,
          Start_Date__c = Date.today()
        )
      );
    }
    insert tournaments;
    // Verify that the tournaments were inserted
    Integer initialCount = [SELECT COUNT() FROM Tournament__c];
    System.assertEquals(
      3,
      initialCount,
      'Three tournaments should be inserted'
    );
    // Invoke the deleteAllTournamentData method
    Test.startTest();
    DeleteTournamentDataController.deleteAllTournamentData();
    Test.stopTest();
    // Verify that all tournaments were deleted
    Integer finalCount = [SELECT COUNT() FROM Tournament__c];
    System.assertEquals(0, finalCount, 'All tournaments should be deleted');
  }
}
