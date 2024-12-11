/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-11-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@isTest
private class GroupUtilityTest {
  @isTest
  static void testNextGroup() {
    // Test cases for nextGroup method
    System.assertEquals(
      GroupUtility.GROUP_B,
      GroupUtility.nextGroup(GroupUtility.GROUP_A),
      'The next group after Group A should be Group B'
    );
    System.assertEquals(
      GroupUtility.GROUP_C,
      GroupUtility.nextGroup(GroupUtility.GROUP_B),
      'The next group after Group B should be Group C'
    );
    System.assertEquals(
      GroupUtility.GROUP_D,
      GroupUtility.nextGroup(GroupUtility.GROUP_C),
      'The next group after Group C should be Group D'
    );
    System.assertEquals(
      GroupUtility.GROUP_E,
      GroupUtility.nextGroup(GroupUtility.GROUP_D),
      'The next group after Group D should be Group E'
    );
    System.assertEquals(
      GroupUtility.GROUP_F,
      GroupUtility.nextGroup(GroupUtility.GROUP_E),
      'The next group after Group E should be Group F'
    );
    System.assertEquals(
      GroupUtility.GROUP_G,
      GroupUtility.nextGroup(GroupUtility.GROUP_F),
      'The next group after Group F should be Group G'
    );
    System.assertEquals(
      GroupUtility.GROUP_H,
      GroupUtility.nextGroup(GroupUtility.GROUP_G),
      'The next group after Group G should be Group H'
    );
    System.assertEquals(
      null,
      GroupUtility.nextGroup(GroupUtility.GROUP_H),
      'There should be no next group after Group H'
    );
  }
  @isTest
  static void testPreviousGroup() {
    // Test cases for previousGroup method
    System.assertEquals(
      GroupUtility.GROUP_G,
      GroupUtility.previousGroup(GroupUtility.GROUP_H),
      'The previous group before Group H should be Group G'
    );
    System.assertEquals(
      GroupUtility.GROUP_F,
      GroupUtility.previousGroup(GroupUtility.GROUP_G),
      'The previous group before Group G should be Group F'
    );
    System.assertEquals(
      GroupUtility.GROUP_E,
      GroupUtility.previousGroup(GroupUtility.GROUP_F),
      'The previous group before Group F should be Group E'
    );
    System.assertEquals(
      GroupUtility.GROUP_D,
      GroupUtility.previousGroup(GroupUtility.GROUP_E),
      'The previous group before Group E should be Group D'
    );
    System.assertEquals(
      GroupUtility.GROUP_C,
      GroupUtility.previousGroup(GroupUtility.GROUP_D),
      'The previous group before Group D should be Group C'
    );
    System.assertEquals(
      GroupUtility.GROUP_B,
      GroupUtility.previousGroup(GroupUtility.GROUP_C),
      'The previous group before Group C should be Group B'
    );
    System.assertEquals(
      GroupUtility.GROUP_A,
      GroupUtility.previousGroup(GroupUtility.GROUP_B),
      'The previous group before Group B should be Group A'
    );
    System.assertEquals(
      null,
      GroupUtility.previousGroup(GroupUtility.GROUP_A),
      'There should be no previous group before Group A'
    );
  }
}
