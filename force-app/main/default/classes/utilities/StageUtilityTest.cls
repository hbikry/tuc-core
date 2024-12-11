/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-11-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@isTest
private class StageUtilityTest {
  @isTest
  static void testNextStage() {
    // Test cases for nextStage method
    System.assertEquals(
      StageUtility.ROUND_2_GROUP_STAGE,
      StageUtility.nextStage(StageUtility.ROUND_1_GROUP_STAGE),
      'The next stage after Round 1 should be Round 2'
    );
    System.assertEquals(
      StageUtility.ROUND_3_GROUP_STAGE,
      StageUtility.nextStage(StageUtility.ROUND_2_GROUP_STAGE),
      'The next stage after Round 2 should be Round 3'
    );
    System.assertEquals(
      StageUtility.ROUND_OF_16_KO_STAGE,
      StageUtility.nextStage(StageUtility.ROUND_3_GROUP_STAGE),
      'The next stage after Round 3 should be Round of 16'
    );
    System.assertEquals(
      StageUtility.QUARTERFINAL_KO_STAGE,
      StageUtility.nextStage(StageUtility.ROUND_OF_16_KO_STAGE),
      'The next stage after Round of 16 should be Quarter-finals'
    );
    System.assertEquals(
      StageUtility.SEMIFINAL_KO_STAGE,
      StageUtility.nextStage(StageUtility.QUARTERFINAL_KO_STAGE),
      'The next stage after Quarter-finals should be Semi-finals'
    );
    System.assertEquals(
      StageUtility.THIRD_PLACE_KO_STAGE,
      StageUtility.nextStage(StageUtility.SEMIFINAL_KO_STAGE),
      'The next stage after Semi-finals should be Third place play-off'
    );
    System.assertEquals(
      StageUtility.FINAL_KO_STAGE,
      StageUtility.nextStage(StageUtility.THIRD_PLACE_KO_STAGE),
      'The next stage after Third place play-off should be Final'
    );
    System.assertEquals(
      null,
      StageUtility.nextStage(StageUtility.FINAL_KO_STAGE),
      'There should be no next stage after Final'
    );
  }
  @isTest
  static void testPreviousStage() {
    // Test cases for previousStage method
    System.assertEquals(
      StageUtility.THIRD_PLACE_KO_STAGE,
      StageUtility.previousStage(StageUtility.FINAL_KO_STAGE),
      'The previous stage before Final should be Third place play-off'
    );
    System.assertEquals(
      StageUtility.SEMIFINAL_KO_STAGE,
      StageUtility.previousStage(StageUtility.THIRD_PLACE_KO_STAGE),
      'The previous stage before Third place play-off should be Semi-finals'
    );
    System.assertEquals(
      StageUtility.QUARTERFINAL_KO_STAGE,
      StageUtility.previousStage(StageUtility.SEMIFINAL_KO_STAGE),
      'The previous stage before Semi-finals should be Quarter-finals'
    );
    System.assertEquals(
      StageUtility.ROUND_OF_16_KO_STAGE,
      StageUtility.previousStage(StageUtility.QUARTERFINAL_KO_STAGE),
      'The previous stage before Quarter-finals should be Round of 16'
    );
    System.assertEquals(
      StageUtility.ROUND_3_GROUP_STAGE,
      StageUtility.previousStage(StageUtility.ROUND_OF_16_KO_STAGE),
      'The previous stage before Round of 16 should be Round 3'
    );
    System.assertEquals(
      StageUtility.ROUND_2_GROUP_STAGE,
      StageUtility.previousStage(StageUtility.ROUND_3_GROUP_STAGE),
      'The previous stage before Round 3 should be Round 2'
    );
    System.assertEquals(
      StageUtility.ROUND_1_GROUP_STAGE,
      StageUtility.previousStage(StageUtility.ROUND_2_GROUP_STAGE),
      'The previous stage before Round 2 should be Round 1'
    );
    System.assertEquals(
      null,
      StageUtility.previousStage(StageUtility.ROUND_1_GROUP_STAGE),
      'There should be no previous stage before Round 1'
    );
  }
}
