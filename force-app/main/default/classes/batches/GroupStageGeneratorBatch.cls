/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-10-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class GroupStageGeneratorBatch implements Database.Batchable<SObject>, Database.Stateful {
  private Id tournamentId;
  private String originalTransactionId;

  public GroupStageGeneratorBatch(
    Id tournamentId,
    String originalTransactionId
  ) {
    this.tournamentId = tournamentId;
    this.originalTransactionId = originalTransactionId;
  }

  /**
   * @description : Batch start -> Retrieve tournament teams
   * @author hbikry@salesforce.com | 12-09-2024
   * @param bc
   * @return List<SObject>
   **/
  public List<SObject> start(Database.BatchableContext bc) {
    List<Tournament_Team__c> tournamentTeams = [
      SELECT Id, Team__c
      FROM Tournament_Team__c
      WHERE Tournament__c = :this.tournamentId
      WITH USER_MODE
    ];

    Logger.setParentLogTransactionId(this.originalTransactionId);
    Logger.info('Started group stage generator batch', tournamentTeams);
    Logger.saveLog();

    return tournamentTeams;
  }

  /**
   * @description : Batch execute -> Generate group stage matches
   * @author hbikry@salesforce.com | 12-09-2024
   * @param bc
   * @param scope
   **/
  public void execute(Database.BatchableContext bc, List<SObject> scope) {
    Logger.setParentLogTransactionId(this.originalTransactionId);
    Savepoint savePoint = Database.setSavepoint();
    try {
      // Generate group stage matches
      List<Match__c> groupStageMatches = generateGroupStageMatches(
        (List<Tournament_Team__c>) scope
      );
      Logger.info('Group stage matches generated', groupStageMatches);
    } catch (Exception e) {
      Database.rollback(savePoint);
      Logger.error(
        'Error occurred while executing group stage generator batch. Rollbacking database changes',
        e
      );
    } finally {
      Logger.saveLog();
    }
  }

  /**
   * @description : Batch finish -> Log job record & queue round of 16 generator batch
   * @author hbikry@salesforce.com | 12-09-2024
   * @param bc
   **/
  public void finish(Database.BatchableContext bc) {
    AsyncApexJob job = [
      SELECT
        Id,
        Status,
        NumberOfErrors,
        JobItemsProcessed,
        TotalJobItems,
        CreatedBy.Email
      FROM AsyncApexJob
      WHERE Id = :bc.getJobId()
      WITH USER_MODE
    ];

    Logger.setParentLogTransactionId(this.originalTransactionId);
    Logger.info('Group stage generator batch finished', job);

    RoundOf16GeneratorBatch nextBatch = new RoundOf16GeneratorBatch(
      this.tournamentId,
      this.originalTransactionId
    );
    Database.executeBatch(nextBatch);

    Logger.saveLog();
  }

  private List<Match__c> generateGroupStageMatches(
    List<Tournament_Team__c> tournamentTeams
  ) {
    Integer maxTeams = TournamentConfigurationUtility.getDefaultMaxTeamsPerTournament();
    if (tournamentTeams.size() != maxTeams) {
      throw new IllegalArgumentException(
        'The list must contain exactly ' + maxTeams + ' teams.'
      );
    }

    List<Match__c> matches = new List<Match__c>();
    Integer groupSize = TournamentConfigurationUtility.getDefaultMaxTeamsPerGroup(); // Number of teams per group
    Integer numberOfGroups = TournamentConfigurationUtility.getDefaultMaxGroups(); // Total number of groups

    // Matchups for each round
    Integer[][] groupMatchups = new List<Integer[]>{
      new List<Integer>{ 0, 1 },
      new List<Integer>{ 2, 3 }, // Round 1
      new List<Integer>{ 0, 2 },
      new List<Integer>{ 1, 3 }, // Round 2
      new List<Integer>{ 0, 3 },
      new List<Integer>{ 1, 2 } // Round 3
    };

    // Divide the teams into groups
    for (Integer groupIndex = 0; groupIndex < numberOfGroups; groupIndex++) {
      // Chunk of teams for a group
      List<Tournament_Team__c> groupTeams = new List<Tournament_Team__c>();
      for (Integer i = 0; i < groupSize; i++) {
        groupTeams.add(tournamentTeams[groupIndex * groupSize + i]);
      }

      // Generate dates for each round
      Datetime round1Date = Datetime.now().addDays(1);
      Datetime round2Date = round1Date.addDays(5);
      Datetime round3Date = round2Date.addDays(5);
      Datetime[] roundDates = new List<Datetime>{
        round1Date,
        round2Date,
        round3Date
      };

      // Generate matches for each round
      for (Integer matchup = 0; matchup < 6; matchup++) {
        Integer homeTeamIndex = groupMatchups[matchup][0];
        Integer awayTeamIndex = groupMatchups[matchup][1];
        Match__c match = new Match__c(
          Tournament__c = this.tournamentId,
          Home_Team__c = groupTeams[homeTeamIndex].Team__c,
          Away_Team__c = groupTeams[awayTeamIndex].Team__c,
          Date__c = roundDates[(Integer) matchup / 2],
          Stage__c = StageUtility.GROUP_STAGES[(Integer) matchup / 2]
        );
        MatchUtility.generateMatchResult(match);
        matches.add(match);
      }
    }

    insert as user matches;

    return matches;
  }
}
