/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 11-25-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class MatchUtility {
  // NOTE: these values are part of the picklist field Stage__c of the Match__c object
  // so they must be kept in sync with the picklist values
  public final static String ROUND_3_GROUP_STAGE = 'Group Stage - Round 3';
  public final static String GROUP_STAGE_PREFIX = 'Group Stage';
  public final static String KNOCKOUT_STAGE_PREFIX = 'Knockout Stage';

  public static Boolean isKnockoutStageMatch(Match__c match) {
    return match.Stage__c.contains(KNOCKOUT_STAGE_PREFIX);
  }

  public static Boolean isGroupStageMatch(Match__c match) {
    return match.Stage__c.contains(GROUP_STAGE_PREFIX);
  }

  public static Boolean isGroupStageRoundThreeMatch(Match__c match) {
    return match.Stage__c == ROUND_3_GROUP_STAGE;
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
    Map<Id, Map<Id, String>> groupsByTeamMap,
    Map<Id, Map<String, Datetime>> matchDateByGroup
  ) {
    if (!MatchUtility.isGroupStageRoundThreeMatch(match)) {
      return;
    }

    Id tournamentId = match.Tournament__c;
    Datetime matchDatetime = match.Date__c;
    String groupName = groupsByTeamMap.get(tournamentId)
      .get(match.Home_Team__c);

    if (!matchDateByGroup.containsKey(tournamentId)) {
      matchDateByGroup.put(tournamentId, new Map<String, Datetime>());
    }

    if (!matchDateByGroup.get(tournamentId).containsKey(groupName)) {
      matchDateByGroup.get(tournamentId).put(groupName, matchDatetime);
    }
  }
}
