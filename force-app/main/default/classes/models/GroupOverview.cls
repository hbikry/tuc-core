/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 11-30-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class GroupOverview {
  @AuraEnabled
  public String groupName;
  @AuraEnabled
  public List<MatchOverview> matches;
  @AuraEnabled
  public List<TeamStats> teamsStats;

  public GroupOverview(String groupName) {
    this.groupName = groupName;
    this.matches = new List<MatchOverview>();
    this.teamsStats = new List<teamStats>();
  }

  public void addMatchOverview(MatchOverview matchOverview) {
    this.matches.add(matchOverview);
  }

  public void addTeamStats(TeamStats teamStats) {
    this.teamsStats.add(teamStats);
  }
}
