/**
 * @description       : After trigger handler for Match__c records
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-10-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class AfterMatchTriggerHandler {
  // Inserted/updated match record list
  private List<Match__c> newList;
  // Set for related tournament ids
  private Set<Id> tournamentIds = new Set<Id>();
  // List of related tournaments
  private Map<Id, Tournament__c> tournaments = new Map<Id, Tournament__c>();
  // List of related tournament teams
  private List<Tournament_Team__c> tournamentTeams = new List<Tournament_Team__c>();
  // For each related tournament, map tournament team by team Map<tournamentId, Map<teamId, Tournament_Team__c>>
  Map<Id, Map<Id, Tournament_Team__c>> tournamentTeamsByTeamMap = new Map<Id, Map<Id, Tournament_Team__c>>();
  // Map for tournament teams to update Map<tournamentId, Tournament_Team__c
  Map<Id, Tournament_Team__c> tournamentTeamsToUpdateMap = new Map<Id, Tournament_Team__c>();
  // List of tournaments to update
  List<Tournament__c> tournamentsToUpdate = new List<Tournament__c>();

  public AfterMatchTriggerHandler() {
    newList = (List<Match__c>) Trigger.new;
  }

  public void afterInsert() {
    handleRecords();
  }

  public void afterUpdate() {
    handleRecords();
  }

  /**
   * @description : Handle records after insert/update (update related records)
   * @author hbikry@salesforce.com | 12-09-2024
   **/
  public void handleRecords() {
    initUtils();

    // Sort match list by stage
    List<Match__c> matches = this.newList.clone();
    matches.sort(new MatchStageComparator());

    for (Match__c match : matches) {
      updateGroupStats(match);
      eliminateKnockedOutTeam(match);
      setChampion(match);
    }

    updateTournamentStage();

    update as user this.tournamentTeamsToUpdateMap.values();
    update as user this.tournamentsToUpdate;
  }

  /**
   * @description : Update tournament teams stats after a group stage match
   * @author hbikry@salesforce.com | 12-09-2024
   * @param match
   **/
  private void updateGroupStats(Match__c match) {
    if (!MatchUtility.isGroupStageMatch(match)) {
      return;
    }

    // Get updated tournament teams (calculate stats from match)
    List<Tournament_Team__c> updatedTournamentTeams = TournamentTeamUtility.getUpdatedTournamentTeamStats(
      match,
      this.tournamentTeamsByTeamMap
        .get(match.Tournament__c)
        .get(match.Home_Team__c), // Related tournament team for match home team
      this.tournamentTeamsByTeamMap
        .get(match.Tournament__c)
        .get(match.Away_Team__c) // Related tournament team for match away team
    );

    // Add updated tournament teams to update map
    this.tournamentTeamsToUpdateMap.put(
      match.Home_Team__c,
      updatedTournamentTeams[0] // [0] Home team
    );
    this.tournamentTeamsToUpdateMap.put(
      match.Away_Team__c,
      updatedTournamentTeams[1] // [1] Away team
    );
  }

  /**
   * @description : Mark loser team as eliminated after knockout stage match
   * @author hbikry@salesforce.com | 12-09-2024
   * @param match
   **/
  private void eliminateKnockedOutTeam(Match__c match) {
    if (!MatchUtility.isKnockoutStageMatch(match)) {
      return;
    }

    Tournament_Team__c homeTournamentTeam = this.tournamentTeamsByTeamMap
      .get(match.Tournament__c)
      .get(match.Home_Team__c);

    Tournament_Team__c awayTournamentTeam = this.tournamentTeamsByTeamMap
      .get(match.Tournament__c)
      .get(match.Away_Team__c);

    if (match.Winner_Team__c == match.Home_Team__c) {
      this.tournamentTeamsToUpdateMap.put(
        match.Away_Team__c,
        new Tournament_Team__c(Id = awayTournamentTeam.Id, Eliminated__c = true)
      );
    }

    if (match.Winner_Team__c == match.Away_Team__c) {
      this.tournamentTeamsToUpdateMap.put(
        match.Home_Team__c,
        new Tournament_Team__c(Id = homeTournamentTeam.Id, Eliminated__c = true)
      );
    }
  }

  /**
   * @description : Set champion team on tournament after final match
   * @author hbikry@salesforce.com | 12-09-2024
   * @param match
   **/
  private void setChampion(Match__c match) {
    if (match.Stage__c != StageUtility.FINAL_KO_STAGE) {
      return;
    }

    Tournament__c tournament = new Tournament__c(
      Id = match.Tournament__c,
      Champion__c = match.Winner_Team__c
    );

    this.tournamentsToUpdate.add(tournament);
  }

  private void updateTournamentStage() {
    Map<Id, Integer> getCountByTournamentsMap = MatchUtility.getCountByTournamentsMap(
      this.tournamentIds,
      StageUtility.GROUP_STAGES
    );

    for (Id tournamentId : this.tournamentIds) {
      // If already on knockout stage, skip
      if (
        TournamentStageUtility.tournamentInKnockoutStage(
          this.tournaments.get(tournamentId)
        )
      ) {
        continue;
      }

      Integer groupMatchesCount = getCountByTournamentsMap.get(tournamentId);

      // If group stage not yet finished, skip
      if (
        groupMatchesCount !=
        TournamentConfigurationUtility.getMaxMatchesInGroupStage()
      ) {
        continue;
      }

      // group stage finished -> update tournament stage to knockout stage

      this.tournamentsToUpdate.add(
        new Tournament__c(
          Id = tournamentId,
          Stage__c = TournamentStageUtility.KNOCKOUT_STAGE
        )
      );
    }
  }

  /**
   * @description : Populate utility maps and lists
   * @author hbikry@salesforce.com | 12-09-2024
   **/
  private void initUtils() {
    // Retrieve related tournament ids
    this.tournamentIds = MatchUtility.getRelatedTournamentIds(this.newList);

    // Retrieve related tournaments
    this.tournaments = TournamentUtility.getTournaments(tournamentIds);

    // Retrieve related tournament team records
    this.tournamentTeams = TournamentTeamUtility.getOverviewTournamentTeams(
      this.tournamentIds
    );

    // populate tournament teams by team map
    for (Tournament_Team__c tournamentTeam : this.tournamentTeams) {
      Id tournamentId = tournamentTeam.Tournament__c;
      if (!tournamentTeamsByTeamMap.containsKey(tournamentId)) {
        this.tournamentTeamsByTeamMap.put(
          tournamentId,
          new Map<Id, Tournament_Team__c>()
        );
      }

      this.tournamentTeamsByTeamMap.get(tournamentId)
        .put(tournamentTeam.Team__c, tournamentTeam);
    }
  }
}
