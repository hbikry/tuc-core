public with sharing class TournamentConfigurationUtility {
  public static Integer getDefaultMaxTeamsPerGroup() {
    return (Integer) Tournament_Configuration__c.getOrgDefaults()
      .Max_Teams_Per_Group__c;
  }

  public static Integer getDefaultMaxGroupMatchesPerTeam() {
    return (Integer) Tournament_Configuration__c.getOrgDefaults()
      .Max_Group_Matches_Per_Team__c;
  }
}
