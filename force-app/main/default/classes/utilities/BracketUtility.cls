/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-10-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class BracketUtility {
  // NOTE: these values are part of the Bracket__c picklist from Tournament_Team__c object
  // so they must be kept in sync with the picklist values
  public final static String BRACKET_1 = '1';
  public final static String BRACKET_2 = '2';

  /**
   * @description : Calculates the bracket for a team based on group and whether its first or second
   * @author hbikry@salesforce.com | 12-10-2024
   * @param groupName
   * @param isFirstPlace
   * @return String
   **/
  public static String calculateBracket(
    String groupName,
    Boolean isFirstPlace
  ) {
    Integer groupIndex = GroupUtility.GROUPS.indexOf(groupName);
    Boolean isGroupIndexEven = Math.mod(groupIndex, 2) == 0;

    if (isGroupIndexEven && isFirstPlace) {
      return BRACKET_1;
    }

    if (!isGroupIndexEven && !isFirstPlace) {
      return BRACKET_1;
    }

    return BRACKET_2;
  }
}
