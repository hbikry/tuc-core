/**
 * @description       : Utility class for Stage picklist field
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 11-29-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class StageUtility {
  // NOTE: these values are part of the picklist field Stage__c of the Match__c object
  // so they must be kept in sync with the picklist values
  public final static String ROUND_1_GROUP_STAGE = 'Round 1';
  public final static String ROUND_2_GROUP_STAGE = 'Round 2';
  public final static String ROUND_3_GROUP_STAGE = 'Round 3';
  public final static String ROUND_OF_16_KO_STAGE = 'Round of 16';
  public final static String QUARTERFINAL_KO_STAGE = 'Quarter-finals';
  public final static String SEMIFINAL_KO_STAGE = 'Semi-finals';
  public final static String THIRD_PLACE_KO_STAGE = 'Third place play-off';
  public final static String FINAL_KO_STAGE = 'Final';
  public final static List<String> GROUP_STAGES = new List<String>{
    ROUND_1_GROUP_STAGE,
    ROUND_2_GROUP_STAGE,
    ROUND_3_GROUP_STAGE
  };
  public final static List<String> KO_STAGES = new List<String>{
    ROUND_OF_16_KO_STAGE,
    QUARTERFINAL_KO_STAGE,
    SEMIFINAL_KO_STAGE,
    THIRD_PLACE_KO_STAGE,
    FINAL_KO_STAGE
  };
  public final static List<String> ORDERED_STAGES = new List<String>{
    ROUND_1_GROUP_STAGE,
    ROUND_2_GROUP_STAGE,
    ROUND_3_GROUP_STAGE,
    ROUND_OF_16_KO_STAGE,
    QUARTERFINAL_KO_STAGE,
    SEMIFINAL_KO_STAGE,
    THIRD_PLACE_KO_STAGE,
    FINAL_KO_STAGE
  };

  /**
   * @description : Returns the next stage for a given stage
   * @author hbikry@salesforce.com | 11-26-2024
   * @param stage
   * @return String
   **/
  public static String nextStage(String stage) {
    try {
      return ORDERED_STAGES[ORDERED_STAGES.indexOf(stage) + 1];
    } catch (ListException e) {
      return null;
    }
  }

  /**
   * @description : Returns the previous stage for a given stage
   * @author hbikry@salesforce.com | 11-26-2024
   * @param stage
   * @return String
   **/
  public static String previousStage(String stage) {
    try {
      return ORDERED_STAGES[ORDERED_STAGES.indexOf(stage) - 1];
    } catch (ListException e) {
      return null;
    }
  }
}
