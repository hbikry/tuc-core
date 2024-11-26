/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 11-26-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public without sharing class TournamentTeamTriggerHandler extends TriggerHandler {
  private Map<Id, Tournament_Team__c> oldMap;
  private List<Tournament_Team__c> newList;

  public TournamentTeamTriggerHandler() {
    newList = (List<Tournament_Team__c>) Trigger.new;
    oldMap = (Map<Id, Tournament_Team__c>) Trigger.oldMap;
  }

  public override void beforeInsert() {
    validate();
  }

  public override void beforeUpdate() {
    validate();
  }

  private void validate() {
    // Set to related store tournament ids
    Set<Id> tournamentIds = TournamentTeamUtility.getRelatedTournamendIds(
      this.newList
    );

    // Retrieve existing tournament-team records of related tournaments
    List<Tournament_Team__c> existingRecords = TournamentTeamUtility.getRecordsByTournamentIds(
      tournamentIds
    );

    // Map to store the count of teams per tournament group
    Map<Id, Map<String, Integer>> tournamentGroupCountMap = new Map<Id, Map<String, Integer>>();

    // Set to store unique team-tournament combinations
    Set<String> uniqueTeamSet = new Set<String>();

    for (Tournament_Team__c record : existingRecords) {
      // Add existing record to the group count map
      TournamentTeamUtility.addRecordToCountMap(
        record,
        tournamentGroupCountMap
      );
      // Add existing record to tournament-team set
      uniqueTeamSet.add(TournamentTeamUtility.uniqueKey(record));
    }

    for (Tournament_Team__c record : (List<Tournament_Team__c>) this.newList) {
      // If updating
      if (this.oldMap != null && this.oldMap.containsKey(record.Id)) {
        Tournament_Team__c oldRecord = this.oldMap.get(record.Id);
        // remove the old record from the group count map
        TournamentTeamUtility.removeRecordFromCountMap(
          oldRecord,
          tournamentGroupCountMap
        );
        // remove the unique key from set
        uniqueTeamSet.remove(TournamentTeamUtility.uniqueKey(oldRecord));
      }

      // Check for max teams per group
      handleMaxTeamsPerGroup(record, tournamentGroupCountMap);

      // Check for duplicate teams
      handleDuplicateTeam(record, uniqueTeamSet);
    }
  }

  private static void handleMaxTeamsPerGroup(
    Tournament_Team__c record,
    Map<Id, Map<String, Integer>> tournamentGroupCountMap
  ) {
    // Add the new record to the group count map
    TournamentTeamUtility.addRecordToCountMap(record, tournamentGroupCountMap);

    // Check if the group has more than configured max number
    if (
      tournamentGroupCountMap.get(record.Tournament__c).get(record.Group__c) >
      TournamentConfigurationUtility.getDefaultMaxTeamsPerGroup()
    ) {
      record.addError(
        'Each tournament group can only have up to ' +
          TournamentConfigurationUtility.getDefaultMaxTeamsPerGroup() +
          ' teams.'
      );
    }
  }

  private static void handleDuplicateTeam(
    Tournament_Team__c record,
    Set<String> uniqueTeamSet
  ) {
    String uniqueKey = TournamentTeamUtility.uniqueKey(record);
    // Check for duplicate teams
    if (uniqueTeamSet.contains(uniqueKey)) {
      record.addError(
        'Duplicate teams are not allowed within the same tournament.'
      );
    }

    // after check add the tournament team unique key to the set
    uniqueTeamSet.add(uniqueKey);
  }
}
