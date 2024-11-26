/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 11-26-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class TournamentTeamUtility {
  public static Set<Id> getRelatedTournamendIds(
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

  public static List<Tournament_Team__c> getRecordsByTournamentIds(
    Set<Id> tournamentIds
  ) {
    return [
      SELECT Tournament__c, Group__c, Team__c, Eliminated__c
      FROM Tournament_Team__c
      WHERE Tournament__c IN :tournamentIds
      WITH USER_MODE
    ];
  }

  public static void addRecordToCountMap(
    Tournament_Team__c tournamentTeam,
    Map<Id, Map<String, Integer>> countMap
  ) {
    Id tournamentId = tournamentTeam.Tournament__c;
    String groupName = tournamentTeam.Group__c;

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

  public static void removeRecordFromCountMap(
    Tournament_Team__c tournamentTeam,
    Map<Id, Map<String, Integer>> countMap
  ) {
    Id tournamentId = tournamentTeam.Tournament__c;
    String groupName = tournamentTeam.Group__c;

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

  public static String uniqueKey(Tournament_Team__c record) {
    return record.Tournament__c + '-' + record.Team__c;
  }

  public static void addRecordToGroupsByTeamMap(
    Tournament_Team__c tournamentTeam,
    Map<Id, Map<Id, String>> groupsByTeamMap
  ) {
    Id tournamentId = tournamentTeam.Tournament__c;
    Id teamId = tournamentTeam.Team__c;
    String groupName = tournamentTeam.Group__c;

    if (!groupsByTeamMap.containsKey(tournamentId)) {
      groupsByTeamMap.put(tournamentId, new Map<Id, String>());
    }

    if (!groupsByTeamMap.get(tournamentId).containsKey(teamId)) {
      groupsByTeamMap.get(tournamentId).put(teamId, groupName);
    }
  }

  public static void addRecordToEliminationsByTeamMap(
    Tournament_Team__c tournamentTeam,
    Map<Id, Map<Id, Boolean>> eliminationByTeamMap
  ) {
    Id tournamentId = tournamentTeam.Tournament__c;
    Id teamId = tournamentTeam.Team__c;
    Boolean eliminated = tournamentTeam.Eliminated__c;

    if (!eliminationByTeamMap.containsKey(tournamentId)) {
      eliminationByTeamMap.put(tournamentId, new Map<Id, Boolean>());
    }

    if (!eliminationByTeamMap.get(tournamentId).containsKey(teamId)) {
      eliminationByTeamMap.get(tournamentId).put(teamId, eliminated);
    }
  }

  public static void incrementEliminationsByTeamMap(
    Tournament_Team__c tournamentTeam,
    Map<Id, Integer> eliminationCountMap
  ) {
    Id tournamentId = tournamentTeam.Tournament__c;

    if (!eliminationCountMap.containsKey(tournamentId)) {
      eliminationCountMap.put(tournamentId, 0);
    }

    if (tournamentTeam.Eliminated__c == true) {
      eliminationCountMap.put(
        tournamentId,
        eliminationCountMap.get(tournamentId) + 1
      );
    }
  }
}
