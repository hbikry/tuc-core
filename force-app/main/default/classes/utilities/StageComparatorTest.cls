/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-11-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@isTest
private class StageComparatorTest {
  @isTest
  static void testCompare() {
    // Create an instance of the comparator
    StageComparator comparator = new StageComparator();
    // Test cases
    // Compare Round 1 with Round 2
    Integer result1 = comparator.compare(
      StageUtility.ROUND_1_GROUP_STAGE,
      StageUtility.ROUND_2_GROUP_STAGE
    );
    System.assertEquals(-1, result1, 'Round 1 should come before Round 2');
    // Compare Round 2 with Round 1
    Integer result2 = comparator.compare(
      StageUtility.ROUND_2_GROUP_STAGE,
      StageUtility.ROUND_1_GROUP_STAGE
    );
    System.assertEquals(1, result2, 'Round 2 should come after Round 1');
    // Compare Round 1 with Round 1
    Integer result3 = comparator.compare(
      StageUtility.ROUND_1_GROUP_STAGE,
      StageUtility.ROUND_1_GROUP_STAGE
    );
    System.assertEquals(0, result3, 'Round 1 should be equal to Round 1');
    // Compare Quarter-finals with Semi-finals
    Integer result4 = comparator.compare(
      StageUtility.QUARTERFINAL_KO_STAGE,
      StageUtility.SEMIFINAL_KO_STAGE
    );
    System.assertEquals(
      -1,
      result4,
      'Quarter-finals should come before Semi-finals'
    );
    // Compare Final with Semi-finals
    Integer result5 = comparator.compare(
      StageUtility.FINAL_KO_STAGE,
      StageUtility.SEMIFINAL_KO_STAGE
    );
    System.assertEquals(1, result5, 'Final should come after Semi-finals');
    // Compare invalid stage names
    try {
      comparator.compare('Invalid Stage', StageUtility.ROUND_1_GROUP_STAGE);
      System.assert(
        false,
        'An exception should have been thrown for an invalid stage name'
      );
    } catch (IllegalArgumentException e) {
      System.assertEquals(
        'Invalid group1 name',
        e.getMessage(),
        'The exception message should be "Invalid group1 name"'
      );
    }
    try {
      comparator.compare(StageUtility.ROUND_1_GROUP_STAGE, 'Invalid Stage');
      System.assert(
        false,
        'An exception should have been thrown for an invalid stage name'
      );
    } catch (IllegalArgumentException e) {
      System.assertEquals(
        'Invalid group2 name',
        e.getMessage(),
        'The exception message should be "Invalid group2 name"'
      );
    }
  }
}
