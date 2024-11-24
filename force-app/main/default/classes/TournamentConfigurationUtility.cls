public with sharing class TournamentConfigurationUtility {
  private Tournament_Configuration__c orgDefaults;

  public TournamentConfigurationUtility() {
    orgDefaults = Tournament_Configuration__c.getOrgDefaults();
  }

  public Integer getDefaultMaxTeamsPerGroup() {
    return (Integer) orgDefaults.Max_Teams_Per_Group__c;
  }

  public Integer getDefaultMaxGroupMatchesPerTeam() {
    return (Integer) orgDefaults.Max_Group_Matches_Per_Team__c;
  }

  public String getDefaultKnockoutStagePrefix() {
    return (String) orgDefaults.Knockout_Stage_Prefix__c;
  }

  public String getDefaultGroupStagePrefix() {
    return (String) orgDefaults.Group_Stage_Prefix__c;
  }
}
