/**
 * @description       : Match trigger handler (beforeInsert, beforeUpdate)
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-01-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public without sharing class MatchTriggerHandler extends TriggerHandler {
  private Map<Id, Match__c> oldMap;
  private List<Match__c> newList;

  public MatchTriggerHandler() {
    newList = (List<Match__c>) Trigger.new;
    oldMap = (Map<Id, Match__c>) Trigger.oldMap;
  }

  public override void beforeInsert() {
    validate();
  }

  public override void beforeUpdate() {
    validate();
  }

  /**
   * @description : Validate matches before insert and update
   * @author hbikry@salesforce.com | 11-26-2024
   **/
  private void validate() {
    Set<Id> tournamentIds = MatchUtility.getRelatedTournamentIds(this.newList);

    List<Tournament_Team__c> tournamentTeams = TournamentTeamUtility.getRecordsByTournamentIds(
      tournamentIds
    );

    if (tournamentTeams.isEmpty()) {
      throw new RuntimeException('No team registered to the tournament');
    }

    Map<Id, Map<Id, String>> groupsByTeamMap = new Map<Id, Map<Id, String>>();
    Map<Id, Map<Id, Boolean>> eliminationByTeamMap = new Map<Id, Map<Id, Boolean>>();
    Map<Id, Integer> eliminationCountMap = new Map<Id, Integer>();

    for (Tournament_Team__c tournamentTeam : tournamentTeams) {
      TournamentTeamUtility.addRecordToGroupsByTeamMap(
        tournamentTeam,
        groupsByTeamMap
      );
      TournamentTeamUtility.addRecordToEliminationsByTeamMap(
        tournamentTeam,
        eliminationByTeamMap
      );
      TournamentTeamUtility.incrementEliminationsByTeamMap(
        tournamentTeam,
        eliminationCountMap
      );
    }

    List<Match__c> existingRecords = [
      SELECT Tournament__c, Home_Team__c, Away_Team__c, Date__c, Stage__c
      FROM Match__c
      WHERE Tournament__c IN :tournamentIds
      WITH USER_MODE
    ];

    Map<Id, Map<String, Datetime>> lastMatchDateByGroupMap = new Map<Id, Map<String, Datetime>>();
    Map<Id, Map<String, Datetime>> lastMatchDateByStageMap = new Map<Id, Map<String, Datetime>>();
    Set<String> uniqueMatchesSet = new Set<String>();

    for (Match__c match : existingRecords) {
      MatchUtility.addRecordToLastMatchDateByGroupMap(
        match,
        groupsByTeamMap.get(match.Tournament__c).get(match.Home_Team__c),
        lastMatchDateByGroupMap
      );
      MatchUtility.addRecordToLastMatchDateByStageMap(
        match,
        lastMatchDateByStageMap
      );
      uniqueMatchesSet.add(MatchUtility.uniqueKey(match, true));
    }

    for (Match__c match : this.newList) {
      // If updating
      if (this.oldMap != null && this.oldMap.containsKey(match.Id)) {
        Match__c oldRecord = this.oldMap.get(match.Id);
        // remove the old record from the group count map
        MatchUtility.removeRecordFromLastMatchDateByGroupMap(
          oldRecord,
          groupsByTeamMap.get(oldRecord.Tournament__c)
            .get(oldRecord.Home_Team__c),
          lastMatchDateByGroupMap
        );
        MatchUtility.removeRecordFromLastMatchDateByStageMap(
          oldRecord,
          lastMatchDateByStageMap
        );
        // remove the unique key from set
        uniqueMatchesSet.remove(MatchUtility.uniqueKey(oldRecord, true));
      }

      MatchUtility.addRecordToLastMatchDateByGroupMap(
        match,
        groupsByTeamMap.get(match.Tournament__c).get(match.Home_Team__c),
        lastMatchDateByGroupMap
      );
      MatchUtility.addRecordToLastMatchDateByStageMap(
        match,
        lastMatchDateByStageMap
      );

      // Check for duplicate match
      handleDuplicateMatch(match, uniqueMatchesSet);

      // Check if home team and away team are registered to the tournament
      handleUnregisteredTeams(match, groupsByTeamMap);

      // Check if home team or away team are eliminated for knockout stage matches
      handleEliminatedTeams(match, eliminationByTeamMap);

      // Check for duplicate home and away teams
      handleDuplicateTeams(match);

      // Check if home and away team belong to the same group for group stage matches
      handleGroupConformityOnGroupStage(match, groupsByTeamMap);

      handleMatchDate(match, lastMatchDateByStageMap);

      // Check match date on round 3 group stage
      handleLastMatchOnGroupStage(
        match,
        lastMatchDateByGroupMap,
        groupsByTeamMap.get(match.Tournament__c).get(match.Home_Team__c)
      );

      // Check on winner team and handle it
      handleWinnerTeam(match);

      // Calculate draw based on goals and stage
      calculateDraw(match);
    }
  }

  /**
   * @description : Checks if the match already exists for the given tournament.
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   * @param uniqueMatchesSet
   **/
  private void handleDuplicateMatch(
    Match__c match,
    Set<String> uniqueMatchesSet
  ) {
    if (MatchUtility.isDuplicateMatch(match, uniqueMatchesSet)) {
      match.addError('Match between the two teams already exists');
    }

    uniqueMatchesSet.add(MatchUtility.uniqueKey(match, true));
  }

  /**
   * @description : Checks if the home and away teams are registered to the tournament.
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   * @param groupsByTeamMap
   **/
  private void handleUnregisteredTeams(
    Match__c match,
    Map<Id, Map<Id, String>> groupsByTeamMap
  ) {
    if (
      groupsByTeamMap.get(match.Tournament__c).get(match.Home_Team__c) == null
    ) {
      match.Home_Team__c.addError('Home team not registered to the tournament');
    }

    if (
      groupsByTeamMap.get(match.Tournament__c).get(match.Away_Team__c) == null
    ) {
      match.Away_Team__c.addError('Away team not registered to the tournament');
    }
  }

  /**
   * @description : Checks if the home and away team are eliminated for knockout stage matches.
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   * @param eliminationByTeamMap
   **/
  private void handleEliminatedTeams(
    Match__c match,
    Map<Id, Map<Id, Boolean>> eliminationByTeamMap
  ) {
    if (!MatchUtility.isKnockoutStageMatch(match)) {
      return;
    }

    if (eliminationByTeamMap.get(match.Tournament__c).get(match.Home_Team__c)) {
      match.addError(
        'Home team is eliminated and cannot proceed to knockout stage matches'
      );
    }

    if (eliminationByTeamMap.get(match.Tournament__c).get(match.Away_Team__c)) {
      match.addError(
        'Away team is eliminated and cannot proceed to knockout stage matches'
      );
    }
  }

  /**
   * @description : Checks if the home and away team are the same
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   **/
  private void handleDuplicateTeams(Match__c match) {
    if (match.Home_Team__c == match.Away_Team__c) {
      match.addError('A match between the same two teams is not allowed');
    }
  }

  /**
   * @description : Checks if the home and away team belong to the same group for group stage matches.
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   * @param groupsByTeamMap
   **/
  private void handleGroupConformityOnGroupStage(
    Match__c match,
    Map<Id, Map<Id, String>> groupsByTeamMap
  ) {
    if (
      MatchUtility.isGroupStageMatch(match) &&
      (groupsByTeamMap.get(match.Tournament__c).get(match.Home_Team__c) !=
      groupsByTeamMap.get(match.Tournament__c).get(match.Away_Team__c))
    ) {
      match.addError(
        'Home and Away Teams should be on the same group for group stage matches'
      );
    }
  }

  /**
   * @description : Checks if the match date is greater than the previous stage matches
   *                 and if the match date is lesser than the later stage matches
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   * @param lastMatchDateByStageMap
   **/
  public static void handleMatchDate(
    Match__c match,
    Map<Id, Map<String, Datetime>> lastMatchDateByStageMap
  ) {
    String nextStage = StageUtility.nextStage(match.Stage__c);
    String previousStage = StageUtility.previousStage(match.Stage__c);
    Id tournamentId = match.Tournament__c;
    Datetime matchDate = match.Date__c;

    if (
      nextStage != null &&
      lastMatchDateByStageMap.get(tournamentId) != null &&
      lastMatchDateByStageMap.get(tournamentId).get(nextStage) != null &&
      matchDate >= lastMatchDateByStageMap.get(tournamentId).get(nextStage)
    ) {
      match.Date__c.addError(
        'Match date cannot be greater than or equal to any of the next stage dates'
      );
    }

    if (
      previousStage != null &&
      lastMatchDateByStageMap.get(tournamentId) != null &&
      lastMatchDateByStageMap.get(tournamentId).get(previousStage) != null &&
      matchDate <= lastMatchDateByStageMap.get(tournamentId).get(previousStage)
    ) {
      match.Date__c.addError(
        'Match date cannot be lesser than or equal to any of the previous stage dates'
      );
    }
  }

  /**
   * @description : Checks if the round 3 group match date is identical to the other round 3 matches for the same group
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   * @param lastMatchDateByGroupMap
   * @param matchGroup
   **/
  private void handleLastMatchOnGroupStage(
    Match__c match,
    Map<Id, Map<String, Datetime>> lastMatchDateByGroupMap,
    String matchGroup
  ) {
    if (
      MatchUtility.isGroupStageRoundThreeMatch(match) &&
      lastMatchDateByGroupMap.get(match.Tournament__c) != null &&
      lastMatchDateByGroupMap.get(match.Tournament__c).get(matchGroup) !=
      null &&
      lastMatchDateByGroupMap.get(match.Tournament__c).get(matchGroup) !=
      match.Date__c
    ) {
      match.Date__c.addError(
        'Round 3 group stage matches should be at the same time for each group'
      );
    }
  }

  /**
   * @description : Checks if the winner team is selected for ko stage matches concluded with draw
   *                 && set the winner team for other cases
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   **/
  private void handleWinnerTeam(Match__c match) {
    Boolean isKnockoutStageMatch = MatchUtility.isKnockoutStageMatch(match);
    // If is a knockout stage match and draw
    if (
      isKnockoutStageMatch &&
      (match.Home_Team_Goals__c == match.Away_Team_Goals__c)
    ) {
      // If winner team is null
      if (match.Winner_Team__c == null) {
        match.Winner_Team__c.addError('Winner team is required');

        return;
      }

      // If winner is selected it should be either home team or away team
      if (
        (match.Winner_Team__c != match.Home_Team__c) &&
        (match.Winner_Team__c != match.Away_Team__c)
      ) {
        match.Winner_Team__c.addError(
          'Winner team should be either the home team or away team'
        );

        return;
      }
    }

    // If home teams goals gt away team goals -> set home team as winner
    if (match.Home_Team_Goals__c > match.Away_Team_Goals__c) {
      match.Winner_Team__c = match.Home_Team__c;
    }
    // If home team lt away team goals -> set away team as winner
    else if (match.Home_Team_Goals__c < match.Away_Team_Goals__c) {
      match.Winner_Team__c = match.Away_Team__c;
    }
    // Else -> set winner team as null
    else {
      match.Winner_Team__c = isKnockoutStageMatch ? match.Winner_Team__c : null;
    }
  }

  /**
   * @description : Calculates the draw for the match
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   **/
  private void calculateDraw(Match__c match) {
    // If is a knockout stage match set as draw as false
    // Else if home team and away team goals equal set draw as true
    // Else set draw as false
    match.Draw__c = MatchUtility.isKnockoutStageMatch(match)
      ? false
      : (match.Home_Team_Goals__c == match.Away_Team_Goals__c);
  }
}
