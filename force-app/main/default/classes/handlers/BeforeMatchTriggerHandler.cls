/**
 * @description       : Before trigger handler for Match__c records
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-09-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class BeforeMatchTriggerHandler {
  // Match record list to be inserted/updated
  private List<Match__c> newList;
  // Old match record map to be updated
  private Map<Id, Match__c> oldMap;
  // Set for related tournament ids
  private Set<Id> tournamentIds = new Set<Id>();
  // List of related tournaments
  private Map<Id, Tournament__c> tournaments = new Map<Id, Tournament__c>();
  // List of related tournament teams
  private List<Tournament_Team__c> tournamentTeams = new List<Tournament_Team__c>();
  // For each related tournament, map group by team Map<tournamentId, Map<teamId, groupName>>
  private Map<Id, Map<Id, String>> groupsByTeamMap = new Map<Id, Map<Id, String>>();
  // For each related tournament, map elimination by team Map<tournamentId, Map<teamId, true|false>>
  private Map<Id, Map<Id, Boolean>> eliminationByTeamMap = new Map<Id, Map<Id, Boolean>>();
  // For each related tournament, map last match date by group Map<tournamentId, Map<groupName, lastMatchDate>>
  private Map<Id, Map<String, Datetime>> lastMatchDateByGroupMap = new Map<Id, Map<String, Datetime>>();
  // For each related tournament, map last match date by stage Map<tournamentId, Map<stage, lastMatchDate>>
  private Map<Id, Map<String, Datetime>> lastMatchDateByStageMap = new Map<Id, Map<String, Datetime>>();
  // Set for unique match keys
  private Set<String> uniqueMatchesSet = new Set<String>();

  public BeforeMatchTriggerHandler() {
    newList = (List<Match__c>) Trigger.new;
    oldMap = (Map<Id, Match__c>) Trigger.oldMap;
  }

  public void beforeInsert() {
    handleRecords();
  }

  public void beforeUpdate() {
    handleRecords();
  }

  /**
   * @description : Handle records before insert/update (validate & populate records)
   * @author hbikry@salesforce.com | 12-09-2024
   **/
  public void handleRecords() {
    preValidation();
    initUtils();

    // Sort new match records by stage
    List<Match__c> matches = this.newList.clone();
    matches.sort(new MatchStageComparator());

    for (Match__c match : matches) {
      // If update, remove old matched records from utils
      if (this.oldMap != null && this.oldMap.containsKey(match.Id)) {
        Match__c oldRecord = this.oldMap.get(match.Id);
        // remove the old record from the util maps -> new one is taken into consideration
        removeMatchRecordFromUtilMaps(oldRecord);
        // remove the unique key from set
        uniqueMatchesSet.remove(MatchUtility.uniqueKey(oldRecord, true));
      }

      // Add new record to utils -> take it into consideration for validation
      addMatchRecordToUtilMaps(match);

      try {
        validateRecord(match);
      } catch (Exception e) {
        match.addError(e.getMessage());
      }

      // Post record validation -> populate fields
      MatchUtility.calculateWinnerTeam(match);
      MatchUtility.calculateDraw(match);
    }
  }

  /**
   * @description : Apply validation checks on match record
   * @author hbikry@salesforce.com | 12-09-2024
   * @param match
   **/
  public void validateRecord(Match__c match) {
    // Check knockout stage match
    checkTournamentStage(match);

    // Check for duplicate match
    checkDuplicateMatch(match);
    // add new match record to unique set
    this.uniqueMatchesSet.add(MatchUtility.uniqueKey(match, true));

    // Check if home team and away team are registered to the tournament
    checkUnregisteredTeams(match);

    // Check if home team or away team are eliminated for knockout stage matches
    checkEliminatedTeams(match);

    // Check for duplicate home and away teams
    checkDuplicateTeams(match);

    // Check if home and away team belong to the same group for group stage matches
    checkGroupConformityOnGroupStage(match);

    // Check match date with previous and later stage matches
    checkMatchDate(match);

    // Check match date on round 3 group stage
    checkLastMatchOnGroupStage(match);

    // Check winner team on draw ko stage match
    checkWinnerTeam(match);
  }

  private void checkTournamentStage(Match__c match) {
    if (
      MatchUtility.isGroupStageMatch(match) &&
      TournamentStageUtility.tournamentInKnockoutStage(
        this.tournaments.get(match.Tournament__c)
      )
    ) {
      match.addError(
        'Cannot add/update group stage match while tournament in knockout stage'
      );
    }

    if (
      MatchUtility.isKnockoutStageMatch(match) &&
      TournamentStageUtility.tournamentInGroupStage(
        this.tournaments.get(match.Tournament__c)
      )
    ) {
      match.addError(
        'Cannot add/update knockout stage match while tournament in group stage'
      );
    }
  }

  /**
   * @description : Checks if the match already exists for the given tournament.
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   * @param uniqueMatchesSet
   **/
  private void checkDuplicateMatch(Match__c match) {
    if (MatchUtility.isDuplicateMatch(match, this.uniqueMatchesSet)) {
      match.addError('Match between the two teams already exists');
    }
  }

  /**
   * @description : Checks if the home and away teams are registered to the tournament.
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   **/
  private void checkUnregisteredTeams(Match__c match) {
    if (
      this.groupsByTeamMap.get(match.Tournament__c).get(match.Home_Team__c) ==
      null
    ) {
      match.Home_Team__c.addError('Home team not registered to the tournament');
    }

    if (
      this.groupsByTeamMap.get(match.Tournament__c).get(match.Away_Team__c) ==
      null
    ) {
      match.Away_Team__c.addError('Away team not registered to the tournament');
    }
  }

  /**
   * @description : Checks if the home and away team are eliminated for knockout stage matches.
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   **/
  private void checkEliminatedTeams(Match__c match) {
    if (!MatchUtility.isKnockoutStageMatch(match)) {
      return;
    }

    if (MatchUtility.isThirdPlayPlayOffMatch(match)) {
      return;
    }

    if (
      this.eliminationByTeamMap.get(match.Tournament__c).get(match.Home_Team__c)
    ) {
      match.addError(
        'Home team is eliminated and cannot be part of any matches'
      );
    }

    if (
      this.eliminationByTeamMap.get(match.Tournament__c).get(match.Away_Team__c)
    ) {
      match.addError(
        'Away team is eliminated and cannot be part of any matches'
      );
    }
  }

  /**
   * @description : Checks if the home and away team are the same
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   **/
  private void checkDuplicateTeams(Match__c match) {
    if (match.Home_Team__c == match.Away_Team__c) {
      match.addError('A match between the same two teams is not allowed');
    }
  }

  /**
   * @description : Checks if the home and away team belong to the same group for group stage matches.
   * @author hbikry@salesforce.com | 11-26-2024
   * @param match
   **/
  private void checkGroupConformityOnGroupStage(Match__c match) {
    if (
      MatchUtility.isGroupStageMatch(match) &&
      (this.groupsByTeamMap.get(match.Tournament__c).get(match.Home_Team__c) !=
      this.groupsByTeamMap.get(match.Tournament__c).get(match.Away_Team__c))
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
   **/
  public void checkMatchDate(Match__c match) {
    String nextStage = StageUtility.nextStage(match.Stage__c);
    String previousStage = StageUtility.previousStage(match.Stage__c);
    Id tournamentId = match.Tournament__c;
    Datetime matchDate = match.Date__c;

    if (
      nextStage != null &&
      this.lastMatchDateByStageMap.get(tournamentId) != null &&
      this.lastMatchDateByStageMap.get(tournamentId).get(nextStage) != null &&
      matchDate >= this.lastMatchDateByStageMap.get(tournamentId).get(nextStage)
    ) {
      match.Date__c.addError(
        'Match date cannot be greater than or equal to any of the next stage dates'
      );
    }

    if (
      previousStage != null &&
      this.lastMatchDateByStageMap.get(tournamentId) != null &&
      this.lastMatchDateByStageMap.get(tournamentId).get(previousStage) !=
      null &&
      matchDate <=
      this.lastMatchDateByStageMap.get(tournamentId).get(previousStage)
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
   * @param matchGroup
   **/
  private void checkLastMatchOnGroupStage(Match__c match) {
    // If not round 3 match
    if (!MatchUtility.isGroupStageRoundThreeMatch(match)) {
      return;
    }

    // If no round 3 match in tournament
    if (this.lastMatchDateByGroupMap.get(match.Tournament__c) == null) {
      return;
    }

    String groupName = this.groupsByTeamMap.get(match.Tournament__c)
      .get(match.Home_Team__c);

    if (groupName == null) {
      throw new IllegalArgumentException(
        'Match team expected to be in a group'
      );
    }

    Datetime round3MatchDate = lastMatchDateByGroupMap.get(match.Tournament__c)
      .get(groupName);

    // If no round 3 match in group
    if (round3MatchDate == null) {
      return;
    }

    if (round3MatchDate != match.Date__c) {
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
  private void checkWinnerTeam(Match__c match) {
    // If not knockout stage match
    if (!MatchUtility.isKnockoutStageMatch(match)) {
      return;
    }

    // If score is not draw
    if (match.Home_Team_Goals__c != match.Away_Team_Goals__c) {
      return;
    }

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
    }
  }

  /**
   * @description : Retrieve and check related tournaments & tournament teams not empty
   * @author hbikry@salesforce.com | 12-09-2024
   **/
  private void preValidation() {
    this.tournamentIds = MatchUtility.getRelatedTournamentIds(this.newList);

    this.tournaments = TournamentUtility.getTournaments(this.tournamentIds);

    if (this.tournaments.isEmpty()) {
      throw new RuntimeException(
        'No tournaments found to which the matches are being added/updated'
      );
    }

    this.tournamentTeams = TournamentTeamUtility.getRecordsByTournamentIds(
      this.tournamentIds
    );

    if (this.tournamentTeams.isEmpty()) {
      throw new RuntimeException('No team registered to the tournament');
    }
  }

  /**
   * @description : Populate utility maps & sets from tournament teams & existing match records
   * @author hbikry@salesforce.com | 12-09-2024
   **/
  private void initUtils() {
    for (Tournament_Team__c tournamentTeam : this.tournamentTeams) {
      TournamentTeamUtility.addRecordToGroupsByTeamMap(
        tournamentTeam,
        groupsByTeamMap
      );
      TournamentTeamUtility.addRecordToEliminationsByTeamMap(
        tournamentTeam,
        eliminationByTeamMap
      );
    }

    List<Match__c> existingMatches = [
      SELECT Tournament__c, Home_Team__c, Away_Team__c, Date__c, Stage__c
      FROM Match__c
      WHERE Tournament__c IN :tournamentIds
      WITH USER_MODE
    ];

    // populate utility maps from existing match records
    for (Match__c match : existingMatches) {
      addMatchRecordToUtilMaps(match);
      uniqueMatchesSet.add(MatchUtility.uniqueKey(match, true));
    }
  }

  /**
   * @description : Add match record to utility maps
   * @author hbikry@salesforce.com | 12-09-2024
   * @param match
   **/
  private void addMatchRecordToUtilMaps(Match__c match) {
    MatchUtility.addRecordToLastMatchDateByGroupMap(
      match,
      this.groupsByTeamMap.get(match.Tournament__c).get(match.Home_Team__c),
      this.lastMatchDateByGroupMap
    );
    MatchUtility.addRecordToLastMatchDateByStageMap(
      match,
      this.lastMatchDateByStageMap
    );
  }

  /**
   * @description : Remove match record from utility maps
   * @author hbikry@salesforce.com | 12-09-2024
   * @param match
   **/
  private void removeMatchRecordFromUtilMaps(Match__c match) {
    MatchUtility.removeRecordFromLastMatchDateByGroupMap(
      match,
      this.groupsByTeamMap.get(match.Tournament__c).get(match.Home_Team__c),
      this.lastMatchDateByGroupMap
    );
    MatchUtility.removeRecordFromLastMatchDateByStageMap(
      match,
      this.lastMatchDateByStageMap
    );
  }
}
