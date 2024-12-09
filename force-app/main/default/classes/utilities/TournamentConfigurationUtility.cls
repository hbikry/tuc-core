/**
 * @description       : Utility class for Tournament Configuration Custom Setting
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-09-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class TournamentConfigurationUtility {
  /**
   * @description : Get maximum number of teams per group (4)
   * @author hbikry@salesforce.com | 11-26-2024
   * @return Integer
   **/
  public static Integer getDefaultMaxTeamsPerGroup() {
    return (Integer) Tournament_Configuration__c.getOrgDefaults()
      .Max_Teams_Per_Group__c;
  }

  /**
   * @description : Get maximum number of group matches per team (3)
   * @author hbikry@salesforce.com | 11-26-2024
   * @return Integer
   **/
  public static Integer getDefaultMaxGroupMatchesPerTeam() {
    return (Integer) Tournament_Configuration__c.getOrgDefaults()
      .Max_Group_Matches_Per_Team__c;
  }

  /**
   * @description : Get maximum number of groups per tournament (8)
   * @author hbikry@salesforce.com | 11-26-2024
   * @return Integer
   **/
  public static Integer getDefaultMaxGroups() {
    return (Integer) Tournament_Configuration__c.getOrgDefaults().Max_Groups__c;
  }

  /**
   * @description Calculate max teams per tournament (8 * 4 = 32)
   * @author hbikry@salesforce.com | 12-07-2024
   * @return Integer
   **/
  public static Integer getDefaultMaxTeamsPerTournament() {
    return (Integer) getDefaultMaxGroups() * getDefaultMaxTeamsPerGroup();
  }

  /**
   * @description Calculate max matches by group (3 * 4 / 2 = 6)
   * @author hbikry@salesforce.com | 12-07-2024
   * @return Integer
   **/
  public static Integer getDefaultMaxMatchesPerGroup() {
    return (Integer) getDefaultMaxGroupMatchesPerTeam() *
      getDefaultMaxTeamsPerGroup() /
      2;
  }

  /**
   * @description Calculate max matches by group stage round ( 4 / 2 * 8 = 16)
   * @author hbikry@salesforce.com | 12-07-2024
   * @return Integer
   **/
  public static Integer getDefaultMaxMatchesPerRound() {
    return (Integer) getDefaultMaxMatchesPerGroup() /
      StageUtility.GROUP_STAGES.size() *
      getDefaultMaxGroups();
  }

  /**
   * @description : Calculate max matches in group stage (8 * 6 = 48)
   * @author hbikry@salesforce.com | 12-09-2024
   * @return Integer
   **/
  public static Integer getMaxMatchesInGroupStage() {
    return (Integer) getDefaultMaxGroups() * getDefaultMaxMatchesPerGroup();
  }
}
