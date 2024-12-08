/**
 * @description       : Match trigger handler (beforeInsert, beforeUpdate)
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-08-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public without sharing class MatchTriggerHandler extends TriggerHandler {
  private Map<Id, Match__c> oldMap;
  private List<Match__c> newList;
  private Map<Id, Match__c> newMap;
  Boolean isBeforeInsert = false;
  Boolean isBeforeUpdate = false;

  public MatchTriggerHandler() {
    newList = (List<Match__c>) Trigger.new;
    oldMap = (Map<Id, Match__c>) Trigger.oldMap;
    newMap = (Map<Id, Match__c>) Trigger.newMap;
    isBeforeInsert = Trigger.isBefore && Trigger.isInsert;
    isBeforeUpdate = Trigger.isBefore && Trigger.isUpdate;
  }

  public override void beforeInsert() {
    Logger.info('Before insert match trigger started', this.newList);
    validate();
    Logger.info('Before insert match trigger finished');
  }

  public override void beforeUpdate() {
    Logger.info('Before update match trigger started', this.newList);
    validate();
    Logger.info('Before update match trigger finished');
  }

  public override void afterInsert() {
    Logger.info('After insert match trigger started', this.newList);
    updateRelatedRecords();
    Logger.info('After insert match trigger finished');
  }

  public override void afterUpdate() {
    Logger.info('After update match trigger started', this.newList);
    updateRelatedRecords();
    Logger.info('After update match trigger finished');
  }

  /**
   * @description : Validate matches before insert and update
   * @author hbikry@salesforce.com | 11-26-2024
   **/
  private void validate() {
    try {
      Set<Id> tournamentIds = MatchUtility.getRelatedTournamentIds(
        this.newList
      );

      List<Tournament__c> tournaments = TournamentUtility.getTournaments(
        tournamentIds
      );

      if (tournaments.isEmpty()) {
        throw new RuntimeException(
          'No tournaments found to which the matches are being added/updated'
        );
      }

      List<Tournament_Team__c> tournamentTeams = TournamentTeamUtility.getRecordsByTournamentIds(
        tournamentIds
      );

      if (tournamentTeams.isEmpty()) {
        throw new RuntimeException('No team registered to the tournament');
      }

      Map<Id, Map<Id, String>> groupsByTeamMap = new Map<Id, Map<Id, String>>();
      Map<Id, Map<Id, Boolean>> eliminationByTeamMap = new Map<Id, Map<Id, Boolean>>();

      for (Tournament_Team__c tournamentTeam : tournamentTeams) {
        TournamentTeamUtility.addRecordToGroupsByTeamMap(
          tournamentTeam,
          groupsByTeamMap
        );
        TournamentTeamUtility.addRecordToEliminationsByTeamMap(
          tournamentTeam,
          eliminationByTeamMap
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

      // populate utility maps from existing match records
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

      // Sort match list by stage
      List<Match__c> matches = this.newList.clone();
      matches.sort(new MatchStageComparator());
      for (Match__c match : matches) {
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

        // Check winner team on draw ko stage match, Else set it
        checkAndSetWinnerTeam(match);

        // Calculate draw based on goals and stage
        calculateDraw(match);
      }

      Logger.info(
        'Match validation completed for ' + this.newList.size() + ' records'
      );
    } catch (Exception e) {
      Logger.error('Error occurred on match validation : ', e);

      throw e;
    } finally {
      Logger.saveLog();
    }
  }

  /**
   * @description update related records
   * @author hbikry@salesforce.com | 12-05-2024
   **/
  private void updateRelatedRecords() {
    try {
      // Retrieve related tournament ids
      Set<Id> tournamentIds = MatchUtility.getRelatedTournamentIds(
        this.newList
      );
      // Retrieve related tournaments
      //Map<Id, Tournament__c> tournaments = TournamentUtility.getTournaments(tournamentIds);
      // Retrieve related tournament team records
      List<Tournament_Team__c> tournamentTeams = TournamentTeamUtility.getOverviewTournamentTeams(
        tournamentIds
      );
      // Init tournament teams by team map
      Map<Id, Map<Id, Tournament_Team__c>> tournamentTeamsByTeamMap = new Map<Id, Map<Id, Tournament_Team__c>>();
      // populate tournament teams by team map
      for (Tournament_Team__c tournamentTeam : tournamentTeams) {
        Id tournamentId = tournamentTeam.Tournament__c;
        if (!tournamentTeamsByTeamMap.containsKey(tournamentId)) {
          tournamentTeamsByTeamMap.put(
            tournamentId,
            new Map<Id, Tournament_Team__c>()
          );
        }

        tournamentTeamsByTeamMap.get(tournamentId)
          .put(tournamentTeam.Team__c, tournamentTeam);
      }

      // Init tournament teams to update map
      Map<Id, Tournament_Team__c> tournamentTeamsToUpdateMap = new Map<Id, Tournament_Team__c>();
      List<Tournament__c> tournamentsToUpdate = new List<Tournament__c>();

      // Sort match list by stage
      List<Match__c> matches = this.newList.clone();
      matches.sort(new MatchStageComparator());
      for (Match__c match : matches) {
        Id tournamentId = match.Tournament__c;
        // Related tournament team for match home team
        Tournament_Team__c homeTournamentTeam = tournamentTeamsByTeamMap
          .get(tournamentId)
          .get(match.Home_Team__c);
        // Related tournament team for match away team
        Tournament_Team__c awayTournamentTeam = tournamentTeamsByTeamMap
          .get(tournamentId)
          .get(match.Away_Team__c);

        // Update tournament teams from group stage matches & add records to update map
        updateStats(
          match,
          homeTournamentTeam,
          awayTournamentTeam,
          tournamentTeamsToUpdateMap
        );

        // Mark loser team on knockout stage matches as eliminated
        handleKnockoutEliminations(
          match,
          homeTournamentTeam,
          awayTournamentTeam,
          tournamentTeamsToUpdateMap
        );

        // Set champion team on final stage match
        setChampion(match, tournamentsToUpdate);
      }

      // Update tournament teams
      update as user tournamentTeamsToUpdateMap.values();
      // Update tournaments
      update as user tournamentsToUpdate;
    } catch (Exception e) {
      Logger.error(
        'Error occurred on updating teams stats from matches : ' +
        e.getMessage(),
        e
      );

      throw e;
    } finally {
      Logger.saveLog();
    }
  }

  /**
   * @description
   * @author hbikry@salesforce.com | 12-07-2024
   * @param match
   * @param homeTournamentTeam
   * @param awayTournamentTeam
   * @param tournamentTeamsToUpdateMap
   **/
  private void updateStats(
    Match__c match,
    Tournament_Team__c homeTournamentTeam,
    Tournament_Team__c awayTournamentTeam,
    Map<Id, Tournament_Team__c> tournamentTeamsToUpdateMap
  ) {
    if (!MatchUtility.isGroupStageMatch(match)) {
      return;
    }

    // Get updated tournament teams (calculate stats from match)
    List<Tournament_Team__c> updatedTournamentTeams = TournamentTeamUtility.getUpdatedTournamentTeamStats(
      match,
      homeTournamentTeam,
      awayTournamentTeam
    );

    // Add updated tournament teams to update map
    tournamentTeamsToUpdateMap.put(
      match.Home_Team__c,
      updatedTournamentTeams[0] // [0] Home team
    );
    tournamentTeamsToUpdateMap.put(
      match.Away_Team__c,
      updatedTournamentTeams[1] // [1] Away team
    );
  }

  private void handleKnockoutEliminations(
    Match__c match,
    Tournament_Team__c homeTournamentTeam,
    Tournament_Team__c awayTournamentTeam,
    Map<Id, Tournament_Team__c> tournamentTeamsToUpdateMap
  ) {
    if (!MatchUtility.isKnockoutStageMatch(match)) {
      return;
    }

    if (match.Winner_Team__c == homeTournamentTeam.Id) {
      awayTournamentTeam.Eliminated__c = true;
      tournamentTeamsToUpdateMap.put(match.Away_Team__c, awayTournamentTeam);
    }

    if (match.Winner_Team__c == awayTournamentTeam.Id) {
      homeTournamentTeam.Eliminated__c = true;
      tournamentTeamsToUpdateMap.put(match.Home_Team__c, homeTournamentTeam);
    }
  }

  private void setChampion(
    Match__c match,
    List<Tournament__c> tournamentsToUpdate
  ) {
    if (match.Stage__c != StageUtility.FINAL_KO_STAGE) {
      return;
    }

    Tournament__c tournament = new Tournament__c(
      Id = match.Tournament__c,
      Champion__c = match.Winner_Team__c
    );

    tournamentsToUpdate.add(tournament);
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

    if (MatchUtility.isThirdPlayPlayOffMatch(match)) {
      return;
    }

    if (eliminationByTeamMap.get(match.Tournament__c).get(match.Home_Team__c)) {
      match.addError(
        'Home team is eliminated and cannot be part of any matches'
      );
    }

    if (eliminationByTeamMap.get(match.Tournament__c).get(match.Away_Team__c)) {
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
  private void checkAndSetWinnerTeam(Match__c match) {
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
    // Else -> set winner team as null for group stage matches
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
