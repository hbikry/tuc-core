public without sharing class TournamentTeamTriggerHandler extends TriggerHandler {
  private Map<Id, Tournament_Team__c> oldMap;
  private List<Tournament_Team__c> newList;
  private TournamentConfigurationUtility configUtility;

  public TournamentTeamTriggerHandler() {
    newList = (List<Tournament_Team__c>) Trigger.new;
    oldMap = (Map<Id, Tournament_Team__c>) Trigger.oldMap;
    configUtility = new TournamentConfigurationUtility();
  }

  public override void beforeInsert() {
    validate();
  }

  public override void beforeUpdate() {
    validate();
  }

  private static Set<Id> getRelatedTournamendIds(
    List<Tournament_Team__c> records
  ) {
    Set<Id> tournamentIds = new Set<Id>();

    for (
      Tournament_Team__c tournamentTeam : (List<Tournament_Team__c>) records
    ) {
      tournamentIds.add(tournamentTeam.Tournament__c);
    }

    return tournamentIds;
  }

  private void validate() {
    // Set to related store tournament ids
    Set<Id> tournamentIds = getRelatedTournamendIds(this.newList);

    // Retrieve existing tournament-team records of related tournaments
    List<Tournament_Team__c> existingRecords = [
      SELECT Tournament__c, Group__c, Team__c
      FROM Tournament_Team__c
      WHERE Tournament__c IN :tournamentIds
      WITH USER_MODE
    ];

    // If no record exists do nothing
    if (existingRecords.isEmpty()) {
      return;
    }

    // Map to store the count of teams per tournament group
    Map<Id, Map<String, Integer>> tournamentGroupCountMap = new Map<Id, Map<String, Integer>>();

    // Set to store unique team-tournament combinations
    Set<String> tournamentTeamSet = new Set<String>();

    for (Tournament_Team__c record : existingRecords) {
      // Add existing record to the group count map
      addRecordToMap(record, tournamentGroupCountMap);
      // Add existing record to tournament-team set
      tournamentTeamSet.add(uniqueKey(record));
    }

    for (Tournament_Team__c record : (List<Tournament_Team__c>) this.newList) {
      // If updating
      if (this.oldMap != null && this.oldMap.containsKey(record.Id)) {
        // remove the old record from the group count map
        removeRecordFromMap(
          this.oldMap.get(record.Id),
          tournamentGroupCountMap
        );
        // remove the unique key from set
        tournamentTeamSet.remove(uniqueKey(this.oldMap.get(record.Id)));
      }

      // Add the new record to the group count map
      addRecordToMap(record, tournamentGroupCountMap);

      // Check if the group has more than configured max number
      if (
        tournamentGroupCountMap.get(record.Tournament__c).get(record.Group__c) >
        configUtility.getDefaultMaxTeamsPerGroup()
      ) {
        record.addError(
          'Each tournament group can only have up to ' +
            configUtility.getDefaultMaxTeamsPerGroup() +
            ' teams.'
        );
      }

      // Check for duplicate teams
      if (tournamentTeamSet.contains(uniqueKey(record))) {
        record.addError(
          'Duplicate teams are not allowed within the same tournament.'
        );
      }
    }
  }

  private static void addRecordToMap(
    Tournament_Team__c record,
    Map<Id, Map<String, Integer>> countMap
  ) {
    Id tournamentId = record.Tournament__c;
    String groupName = record.Group__c;

    // Initialize the inner map if it doesn't exist
    if (!countMap.containsKey(tournamentId)) {
      countMap.put(tournamentId, new Map<String, Integer>());
    }

    // Initialize the group count if it doesn't exist
    if (!countMap.get(tournamentId).containsKey(groupName)) {
      countMap.get(tournamentId).put(groupName, 0);
    }

    // Get the group count
    Integer count = countMap.get(tournamentId).get(groupName);

    // Increment the count for the group
    countMap.get(tournamentId).put(groupName, count + 1);
  }

  private static void removeRecordFromMap(
    Tournament_Team__c record,
    Map<Id, Map<String, Integer>> countMap
  ) {
    Id tournamentId = record.Tournament__c;
    String groupName = record.Group__c;

    // Get the group count
    Integer count = countMap.get(tournamentId).get(groupName);

    // Decrement the count for the group
    if (
      countMap.containsKey(tournamentId) &&
      countMap.get(tournamentId).containsKey(groupName)
    ) {
      countMap.get(tournamentId).put(groupName, count - 1);
    }
  }

  private static String uniqueKey(Tournament_Team__c record) {
    return record.Tournament__c + '-' + record.Team__c;
  }
}
