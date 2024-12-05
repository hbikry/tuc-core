/**
 * @description       : Utility class for Tournament Team object
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-05-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class TournamentTeamUtility {
  /**
   * @description : Retrieves tournament ids from a list of tournament teams
   * @author hbikry@salesforce.com | 11-26-2024
   * @param records
   * @return Set<Id>
   **/
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

  /**
   * @description : Retrieves records of tournament teams by tournament ids
   * @author hbikry@salesforce.com | 11-26-2024
   * @param tournamentIds
   * @return List<Tournament_Team__c>
   **/
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

  /**
   * @description : Increments the team count for a group by tournament
   *                 && Checks if the group exceeds the max teams configured
   * @author hbikry@salesforce.com | 11-26-2024
   * @param tournamentTeam
   * @param countMap
   **/
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

  /**
   * @description : Decrements the team count for a group by tournament
   * @author hbikry@salesforce.com | 11-26-2024
   * @param tournamentTeam
   * @param countMap
   **/
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

  /**
   * @description : Returns the unique key for a given tournament team
   * @author hbikry@salesforce.com | 11-26-2024
   * @param record
   * @return String
   **/
  public static String uniqueKey(Tournament_Team__c record) {
    return record.Tournament__c + '-' + record.Team__c;
  }

  /**
   * @description : Adds a team to its group by tournament
   * @author hbikry@salesforce.com | 11-26-2024
   * @param tournamentTeam
   * @param groupsByTeamMap
   **/
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

  /**
   * @description : Mark team elimination by tournament
   * @author hbikry@salesforce.com | 11-26-2024
   * @param tournamentTeam
   * @param eliminationByTeamMap
   **/
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

  /**
   * @description : Increment the elimination count by tournament
   * @author hbikry@salesforce.com | 11-26-2024
   * @param tournamentTeam
   * @param eliminationCountMap
   **/
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

  public static List<Tournament_Team__c> getOverviewTournamentTeams(
    Set<Id> tournamentIds
  ) {
    return [
      SELECT
        Id,
        Group__c,
        Team__c,
        Tournament__c,
        Team__r.Name,
        Team__r.Code__c,
        Team__r.Flag_Code__c,
        Goals_For__c,
        Goals_Against__c,
        Goal_Difference__c,
        Wins__c,
        Losses__c,
        Draws__c,
        Matches_Played__c,
        Points__c,
        Qualification_Points__c
      FROM Tournament_Team__c
      WHERE Tournament__c IN :tournamentIds
      WITH USER_MODE
      ORDER BY Qualification_Points__c DESC
    ];
  }

  public static void updateMatchTeamsStats(
    Match__c match,
    Tournament_Team__c homeTeam,
    Tournament_Team__c awayTeam
  ) {
    homeTeam.Goals_For__c += match.Home_Team_Goals__c;
    homeTeam.Goals_Against__c += match.Away_Team_Goals__c;

    awayTeam.Goals_For__c += match.Away_Team_Goals__c;
    awayTeam.Goals_Against__c += match.Home_Team_Goals__c;

    if (match.Draw__c) {
      homeTeam.Draws__c += 1;
      awayTeam.Draws__c += 1;
    }

    if (match.Winner_Team__c == homeTeam.Team__c) {
      homeTeam.Wins__c += 1;
      awayTeam.Losses__c += 1;
    }

    if (match.Winner_Team__c == awayTeam.Team__c) {
      homeTeam.Losses__c += 1;
      awayTeam.Wins__c += 1;
    }
  }

  public static List<Tournament_Team__c> getUpdatedTournamentTeamStats(
    Match__c match,
    Tournament_Team__c homeTeam,
    Tournament_Team__c awayTeam
  ) {
    updateMatchTeamsStats(match, homeTeam, awayTeam);

    return new List<Tournament_Team__c>{
      new Tournament_Team__c(
        Id = homeTeam.Id,
        Goals_For__c = homeTeam.Goals_For__c,
        Goals_Against__c = homeTeam.Goals_Against__c,
        Wins__c = homeTeam.Wins__c,
        Losses__c = homeTeam.Losses__c,
        Draws__c = homeTeam.Draws__c
      ),
      new Tournament_Team__c(
        Id = awayTeam.Id,
        Goals_For__c = awayTeam.Goals_For__c,
        Goals_Against__c = awayTeam.Goals_Against__c,
        Wins__c = awayTeam.Wins__c,
        Losses__c = awayTeam.Losses__c,
        Draws__c = awayTeam.Draws__c
      )
    };
  }
}
