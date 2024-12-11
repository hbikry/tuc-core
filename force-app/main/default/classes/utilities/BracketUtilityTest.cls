/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-11-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@isTest
private class BracketUtilityTest {
  @isTest
  static void testCalculateBracket() {
    // Test cases
    // Group A (index 0, even) and first place
    System.assertEquals(
      BracketUtility.BRACKET_1,
      BracketUtility.calculateBracket(GroupUtility.GROUP_A, true),
      'Group A, first place should be in Bracket 1'
    );
    // Group A (index 0, even) and not first place
    System.assertEquals(
      BracketUtility.BRACKET_2,
      BracketUtility.calculateBracket(GroupUtility.GROUP_A, false),
      'Group A, not first place should be in Bracket 2'
    );
    // Group B (index 1, odd) and first place
    System.assertEquals(
      BracketUtility.BRACKET_2,
      BracketUtility.calculateBracket(GroupUtility.GROUP_B, true),
      'Group B, first place should be in Bracket 2'
    );
    // Group B (index 1, odd) and not first place
    System.assertEquals(
      BracketUtility.BRACKET_1,
      BracketUtility.calculateBracket(GroupUtility.GROUP_B, false),
      'Group B, not first place should be in Bracket 1'
    );
    // Group C (index 2, even) and first place
    System.assertEquals(
      BracketUtility.BRACKET_1,
      BracketUtility.calculateBracket(GroupUtility.GROUP_C, true),
      'Group C, first place should be in Bracket 1'
    );
    // Group C (index 2, even) and not first place
    System.assertEquals(
      BracketUtility.BRACKET_2,
      BracketUtility.calculateBracket(GroupUtility.GROUP_C, false),
      'Group C, not first place should be in Bracket 2'
    );
    // Group D (index 3, odd) and first place
    System.assertEquals(
      BracketUtility.BRACKET_2,
      BracketUtility.calculateBracket(GroupUtility.GROUP_D, true),
      'Group D, first place should be in Bracket 2'
    );
    // Group D (index 3, odd) and not first place
    System.assertEquals(
      BracketUtility.BRACKET_1,
      BracketUtility.calculateBracket(GroupUtility.GROUP_D, false),
      'Group D, not first place should be in Bracket 1'
    );
  }
}
