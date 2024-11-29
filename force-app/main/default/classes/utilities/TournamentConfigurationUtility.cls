/**
 * @description       : Utility class for Tournament Configuration Custom Setting
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 11-26-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class TournamentConfigurationUtility {
  /**
   * @description : Get maximum number of teams per group
   * @author hbikry@salesforce.com | 11-26-2024
   * @return Integer
   **/
  public static Integer getDefaultMaxTeamsPerGroup() {
    return (Integer) Tournament_Configuration__c.getOrgDefaults()
      .Max_Teams_Per_Group__c;
  }

  /**
   * @description : Get maximum number of group matches per team
   * @author hbikry@salesforce.com | 11-26-2024
   * @return Integer
   **/
  public static Integer getDefaultMaxGroupMatchesPerTeam() {
    return (Integer) Tournament_Configuration__c.getOrgDefaults()
      .Max_Group_Matches_Per_Team__c;
  }

  /**
   * @description : Get maximum number of groups per tournament
   * @author hbikry@salesforce.com | 11-26-2024
   * @return Integer
   **/
  public static Integer getDefaultMaxGroups() {
    return (Integer) Tournament_Configuration__c.getOrgDefaults().Max_Groups__c;
  }
}
