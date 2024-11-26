/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 11-26-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class MatchUtility {
  public static Boolean isKnockoutStageMatch(Match__c match) {
    return StageUtility.KO_STAGES.contains(match.Stage__c);
  }

  public static Boolean isGroupStageMatch(Match__c match) {
    return StageUtility.GROUP_STAGES.contains(match.Stage__c);
  }

  public static Boolean isGroupStageRoundThreeMatch(Match__c match) {
    return match.Stage__c == StageUtility.ROUND_3_GROUP_STAGE;
  }

  public static Boolean isDuplicateMatch(
    Match__c match,
    Set<String> uniqueMatches
  ) {
    return uniqueMatches.contains(MatchUtility.uniqueKey(match, true)) ||
      uniqueMatches.contains(MatchUtility.uniqueKey(match, false));
  }

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

  public static Set<Id> getRelatedTournamentIds(List<Match__c> matches) {
    Set<Id> tournamentIds = new Set<Id>();

    for (Match__c match : matches) {
      tournamentIds.add(match.Tournament__c);
    }

    return tournamentIds;
  }

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
}
