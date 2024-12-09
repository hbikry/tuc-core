/**
 * @description       : Utility class for Match object
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-10-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class MatchUtility {
  /**
   * @description : Checks if the match is a ko stage match
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   * @return Boolean
   **/
  public static Boolean isKnockoutStageMatch(Match__c match) {
    return StageUtility.KO_STAGES.contains(match.Stage__c);
  }

  /**
   * @description : Checks if the match is a group stage match
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   * @return Boolean
   **/
  public static Boolean isGroupStageMatch(Match__c match) {
    return StageUtility.GROUP_STAGES.contains(match.Stage__c);
  }

  /**
   * @description : Checks if the match is a group stage round 3 match
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   * @return Boolean
   **/
  public static Boolean isGroupStageRoundThreeMatch(Match__c match) {
    return match.Stage__c == StageUtility.ROUND_3_GROUP_STAGE;
  }

  /**
   * @description Checks if the match is the third place play off
   * @author hbikry@salesforce.com | 12-07-2024
   * @param match
   * @return Boolean
   **/
  public static Boolean isThirdPlayPlayOffMatch(Match__c match) {
    return match.Stage__c == StageUtility.THIRD_PLACE_KO_STAGE;
  }

  /**
   * @description : Checks if the match is duplicated in the tournament
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   * @param uniqueMatches
   * @return Boolean
   **/
  public static Boolean isDuplicateMatch(
    Match__c match,
    Set<String> uniqueMatches
  ) {
    return uniqueMatches.contains(MatchUtility.uniqueKey(match, true)) ||
      uniqueMatches.contains(MatchUtility.uniqueKey(match, false));
  }

  /**
   * @description : Generates unique key for the match in a tournament
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   * @param homeTeamFirst
   * @return String
   **/
  public static String uniqueKey(Match__c match, Boolean homeTeamFirst) {
    if (homeTeamFirst == null) {
      homeTeamFirst = true;
    }

    String stage = MatchUtility.isGroupStageMatch(match) ? 'group' : 'ko';

    if (homeTeamFirst) {
      return match.Tournament__c +
        '-' +
        stage +
        '-' +
        match.Home_Team__c +
        '-' +
        match.Away_Team__c;
    }

    return match.Tournament__c +
      '-' +
      stage +
      '-' +
      match.Away_Team__c +
      '-' +
      match.Home_Team__c;
  }

  /**
   * @description : Calculates the draw for the match
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   **/
  public static void calculateDraw(Match__c match) {
    // If is a knockout stage match set as draw as false
    // Else if home team and away team goals equal set draw as true
    // Else set draw as false
    match.Draw__c = MatchUtility.isKnockoutStageMatch(match)
      ? false
      : (match.Home_Team_Goals__c == match.Away_Team_Goals__c);
  }

  /**
   * @description : Calculate winner team for match
   * @author hbikry@salesforce.com | 12-09-2024
   * @param match
   **/
  public static void calculateWinnerTeam(Match__c match) {
    // If home teams goals gt away team goals -> set home team as winner
    if (match.Home_Team_Goals__c > match.Away_Team_Goals__c) {
      match.Winner_Team__c = match.Home_Team__c;
      return;
    }

    // If home team lt away team goals -> set away team as winner
    if (match.Home_Team_Goals__c < match.Away_Team_Goals__c) {
      match.Winner_Team__c = match.Away_Team__c;
      return;
    }

    // If score is equal and is group stage match
    if (MatchUtility.isGroupStageMatch(match)) {
      match.Winner_Team__c = null;
      return;
    }

    // Else: knockout stage matches require manual selection for winner
  }

  /**
   * @description : Retrieves related tournament ids from a list of matches
   * @author hbikry@salesforce.com | 11-26-2024
   * @param matches
   * @return Set<Id>
   **/
  public static Set<Id> getRelatedTournamentIds(List<Match__c> matches) {
    Set<Id> tournamentIds = new Set<Id>();

    for (Match__c match : matches) {
      tournamentIds.add(match.Tournament__c);
    }

    return tournamentIds;
  }

  /**
   * @description : Adds group stage round 3 match date by group and by tournament
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   * @param groupName
   * @param lastMatchDateByGroup
   **/
  public static void addRecordToLastMatchDateByGroupMap(
    Match__c match,
    String groupName,
    Map<Id, Map<String, Datetime>> lastMatchDateByGroup
  ) {
    if (!MatchUtility.isGroupStageRoundThreeMatch(match)) {
      return;
    }

    Id tournamentId = match.Tournament__c;
    Datetime matchDatetime = match.Date__c;

    if (!lastMatchDateByGroup.containsKey(tournamentId)) {
      lastMatchDateByGroup.put(tournamentId, new Map<String, Datetime>());
    }

    if (!lastMatchDateByGroup.get(tournamentId).containsKey(groupName)) {
      lastMatchDateByGroup.get(tournamentId).put(groupName, matchDatetime);
    }
  }

  /**
   * @description : Removes group stage round 3 match date from group for a tournament
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   * @param groupName
   * @param lastMatchDateByGroup
   **/
  public static void removeRecordFromLastMatchDateByGroupMap(
    Match__c match,
    String groupName,
    Map<Id, Map<String, Datetime>> lastMatchDateByGroup
  ) {
    if (!MatchUtility.isGroupStageRoundThreeMatch(match)) {
      return;
    }

    Id tournamentId = match.Tournament__c;

    if (!lastMatchDateByGroup.containsKey(tournamentId)) {
      return;
    }

    if (!lastMatchDateByGroup.get(tournamentId).containsKey(groupName)) {
      return;
    }

    lastMatchDateByGroup.get(tournamentId).remove(groupName);
  }

  /**
   * @description : Adds group stage round 3 match date by stage and by tournament
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   * @param lastMatchDateByStage
   **/
  public static void addRecordToLastMatchDateByStageMap(
    Match__c match,
    Map<Id, Map<String, Datetime>> lastMatchDateByStage
  ) {
    Id tournamentId = match.Tournament__c;
    Datetime matchDatetime = match.Date__c;
    String stage = match.Stage__c;

    if (!lastMatchDateByStage.containsKey(tournamentId)) {
      lastMatchDateByStage.put(tournamentId, new Map<String, Datetime>());
    }

    if (!lastMatchDateByStage.get(tournamentId).containsKey(stage)) {
      lastMatchDateByStage.get(tournamentId).put(stage, matchDatetime);

      return;
    }

    if (matchDatetime > lastMatchDateByStage.get(tournamentId).get(stage)) {
      lastMatchDateByStage.get(tournamentId).put(stage, matchDatetime);
    }
  }

  /**
   * @description : Removes group stage round 3 match date from stage for a tournament
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   * @param lastMatchDateByStage
   **/
  public static void removeRecordFromLastMatchDateByStageMap(
    Match__c match,
    Map<Id, Map<String, Datetime>> lastMatchDateByStage
  ) {
    Id tournamentId = match.Tournament__c;
    String stage = match.Stage__c;

    if (!lastMatchDateByStage.containsKey(tournamentId)) {
      return;
    }

    if (!lastMatchDateByStage.get(tournamentId).containsKey(stage)) {
      return;
    }

    lastMatchDateByStage.get(tournamentId).remove(stage);
  }

  public static List<Match__c> getOverviewMatches(
    Id tournamentId,
    List<String> stages
  ) {
    return [
      SELECT
        Id,
        Stage__c,
        Date__c,
        Home_Team__r.Id,
        Home_Team__r.Name,
        Home_Team__r.Code__c,
        Home_Team__r.Flag_Code__c,
        Home_Team_Goals__c,
        Away_Team__r.Id,
        Away_Team__r.Name,
        Away_Team__r.Code__c,
        Away_Team__r.Flag_Code__c,
        Away_Team_Goals__c,
        Winner_Team__c,
        Draw__c
      FROM Match__c
      WHERE Tournament__c = :tournamentId AND Stage__c IN :stages
      WITH USER_MODE
      ORDER BY Date__c ASC
    ];
  }

  public static void generateMatchResult(Match__c match) {
    match.Home_Team_Goals__c = Math.floor(Math.random() * 7).intValue();
    match.Away_Team_Goals__c = Math.floor(Math.random() * 7).intValue();

    if (isGroupStageMatch(match)) {
      return;
    }

    if (match.Home_Team_Goals__c != match.Away_Team_Goals__c) {
      return;
    }

    // Return the record at the random index
    match.Winner_Team__c = (Id) ListUtils.pickRandomObject(
      new List<Id>{ match.Home_Team__c, match.Away_Team__c }
    );
  }

  public static Map<Id, Integer> getCountByTournamentsMap(
    Set<Id> tournamentIds,
    List<String> stages
  ) {
    List<AggregateResult> aggResList = [
      SELECT Tournament__c, count(Id) recordCount
      FROM Match__c
      WHERE Tournament__c IN :tournamentIds AND Stage__c IN :stages
      WITH USER_MODE
      GROUP BY Tournament__c
    ];

    Map<Id, Integer> countByTournaments = new Map<Id, Integer>();

    for (AggregateResult aggRes : aggResList) {
      countByTournaments.put(
        (Id) aggRes.get('Tournament__c'),
        (Integer) aggRes.get('recordCount')
      );
    }

    return countByTournaments;
  }
}
