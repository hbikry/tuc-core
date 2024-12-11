/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-11-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@isTest
private class MatchStageComparatorTest {
  @isTest
  static void testCompare() {
    Tournament__c tournament = new Tournament__c(
      Name = 'Test Tournament',
      Code__c = 'TEST',
      Start_Date__c = Date.today()
    );
    insert tournament;
    Team__c team = new Team__c(Name = 'Test Team', Code__c = 'T');
    insert team;
    // Create test data
    Match__c match1 = new Match__c(
      Tournament__c = tournament.Id,
      Home_Team__c = team.Id,
      Away_Team__c = team.Id,
      Stage__c = StageUtility.ROUND_1_GROUP_STAGE,
      Date__c = Datetime.now()
    );
    Match__c match2 = new Match__c(
      Tournament__c = tournament.Id,
      Home_Team__c = team.Id,
      Away_Team__c = team.Id,
      Stage__c = StageUtility.ROUND_2_GROUP_STAGE,
      Date__c = Datetime.now()
    );
    Match__c match3 = new Match__c(
      Tournament__c = tournament.Id,
      Home_Team__c = team.Id,
      Away_Team__c = team.Id,
      Stage__c = StageUtility.FINAL_KO_STAGE,
      Date__c = Datetime.now()
    );
    Match__c match4 = new Match__c(
      Tournament__c = tournament.Id,
      Home_Team__c = team.Id,
      Away_Team__c = team.Id,
      Stage__c = StageUtility.ROUND_1_GROUP_STAGE,
      Date__c = Datetime.now()
    );
    TriggerHandler.bypass('MatchTriggerHandler');
    // Insert the test data
    insert new List<Match__c>{ match1, match2, match3, match4 };
    // Create an instance of the comparator
    MatchStageComparator comparator = new MatchStageComparator();
    // Test cases
    // Compare match1 (Round 1) with match2 (Round 2)
    Integer result1 = comparator.compare(match1, match2);
    System.assertEquals(-1, result1, 'Round 1 should come before Round 2');
    // Compare match2 (Round 2) with match1 (Round 1)
    Integer result2 = comparator.compare(match2, match1);
    System.assertEquals(1, result2, 'Round 2 should come after Round 1');
    // Compare match1 (Round 1) with match4 (Round 1)
    Integer result3 = comparator.compare(match1, match4);
    System.assertEquals(0, result3, 'Round 1 should be equal to Round 1');
    // Compare match2 (Round 2) with match3 (Final)
    Integer result4 = comparator.compare(match2, match3);
    System.assertEquals(-1, result4, 'Round 2 should come before Final');
    // Compare match3 (Final) with match2 (Round 2)
    Integer result5 = comparator.compare(match3, match2);
    System.assertEquals(1, result5, 'Final should come after Round 2');
  }
}
