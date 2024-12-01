/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 11-30-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class GroupUtility {
  // NOTE: these values are part of the global picklist Tournament Group
  // so they must be kept in sync with the picklist values
  public final static String GROUP_A = 'Group A';
  public final static String GROUP_B = 'Group B';
  public final static String GROUP_C = 'Group C';
  public final static String GROUP_D = 'Group D';
  public final static String GROUP_E = 'Group E';
  public final static String GROUP_F = 'Group F';
  public final static String GROUP_G = 'Group G';
  public final static String GROUP_H = 'Group H';
  public final static Set<String> GROUPS = new Set<String>{
    GROUP_A,
    GROUP_B,
    GROUP_C,
    GROUP_D,
    GROUP_E,
    GROUP_F,
    GROUP_G,
    GROUP_H
  };
  public final static Set<String> FIRST_BRACKET_GROUPS = new Set<String>{
    GROUP_A,
    GROUP_B,
    GROUP_C,
    GROUP_D
  };
  public final static Set<String> SECOND_BRACKETS_GROUPS = new Set<String>{
    GROUP_E,
    GROUP_F,
    GROUP_G,
    GROUP_H
  };
}
