/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-10-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class RoundOf16GeneratorBatch implements Database.Batchable<SObject>, Database.Stateful {
  private Id tournamentId;
  private String originalTransactionId;

  public RoundOf16GeneratorBatch(Id tournamentId, String loggerTransactionId) {
    this.tournamentId = tournamentId;
    this.originalTransactionId = loggerTransactionId;
  }

  /**
   * @description : Batch start -> Retrieve tournament teams ordered by group and points
   * @author hbikry@salesforce.com | 12-09-2024
   * @param bc
   * @return List<SObject>
   **/
  public List<SObject> start(Database.BatchableContext bc) {
    List<Tournament_Team__c> tournamentTeams = TournamentTeamUtility.getRankedTeams(
      new Set<Id>{ this.tournamentId }
    );

    Logger.setParentLogTransactionId(this.originalTransactionId);
    Logger.info('Started round of 16 generator batch', tournamentTeams);
    Logger.saveLog();

    return tournamentTeams;
  }

  /**
   * @description : Batch execute -> generate round of 16 matches
   * @author hbikry@salesforce.com | 12-09-2024
   * @param bc
   * @param scope
   **/
  public void execute(Database.BatchableContext bc, List<SObject> scope) {
    Logger.setParentLogTransactionId(this.originalTransactionId);
    Savepoint savePoint = Database.setSavepoint();
    try {
      // Generate round of 16 stage matches
      List<Match__c> roundOf16Matches = generateRoundOf16Matches(
        (List<Tournament_Team__c>) scope
      );
      Logger.info('Round of 16 matches generated', roundOf16Matches);
    } catch (Exception e) {
      Database.rollback(savePoint);
      Logger.error(
        'Error occurred while executing round of 16 generator batch. Rollbacking database changes',
        e
      );
    } finally {
      Logger.saveLog();
    }
  }

  /**
   * @description : Batch finish -> log job record & queue quarter-finals generator batch
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
    Logger.info('Round of 16 generator batch finished', job);
    Logger.info('Queuing quarter-finals generator batch');
    QuarterFinalsGeneratorBatch nextBatch = new QuarterFinalsGeneratorBatch(
      this.tournamentId,
      this.originalTransactionId
    );
    Database.executeBatch(nextBatch);
    Logger.saveLog();
  }

  /**
   * @description : Generate & insert round of 16 matches
   * @author hbikry@salesforce.com | 12-09-2024
   * @param tournamentTeams
   * @return List<Match__c>
   **/
  private List<Match__c> generateRoundOf16Matches(
    List<Tournament_Team__c> tournamentTeams
  ) {
    // Map to hold the top two teams from each group
    Map<String, List<Tournament_Team__c>> topTeamsByGroup = new Map<String, List<Tournament_Team__c>>();
    //Loop over the records to determine the top two teams from each group
    for (Tournament_Team__c tt : tournamentTeams) {
      if (!topTeamsByGroup.containsKey(tt.Group__c)) {
        topTeamsByGroup.put(tt.Group__c, new List<Tournament_Team__c>());
      }

      if (topTeamsByGroup.get(tt.Group__c).size() < 2) {
        topTeamsByGroup.get(tt.Group__c).add(tt);
      }
    }

    // List to hold the Round of 16 matches
    List<Match__c> roundOf16Matches = new List<Match__c>();

    // Generate dates
    Datetime date1 = Datetime.now().addDays(15);
    Datetime date2 = date1.addDays(2);
    Datetime date3 = date1.addDays(1);
    Datetime date4 = date2.addDays(1);
    Datetime[] dates = new List<Datetime>{ date1, date2, date3, date4 };
    Integer groupsSize = GroupUtility.GROUPS.size();

    for (Integer groupIndex = 0; groupIndex < groupsSize / 2; groupIndex++) {
      String groupName = GroupUtility.GROUPS[groupIndex * 2];
      String nextGroupName = GroupUtility.nextGroup(groupName);

      List<Tournament_Team__c> groupTeams = topTeamsByGroup.get(groupName);
      List<Tournament_Team__c> nextGroupTeams = topTeamsByGroup.get(
        nextGroupName
      );

      Match__c match1 = new Match__c(
        Tournament__c = this.tournamentId,
        Home_Team__c = groupTeams[0].Team__c,
        Away_Team__c = nextGroupTeams[1].Team__c,
        Date__c = dates[(Integer) groupIndex / 2],
        Stage__c = StageUtility.ROUND_OF_16_KO_STAGE
      );
      MatchUtility.generateMatchResult(match1);
      roundOf16Matches.add(match1);

      Match__c match2 = new Match__c(
        Tournament__c = this.tournamentId,
        Home_Team__c = nextGroupTeams[0].Team__c,
        Away_Team__c = groupTeams[1].Team__c,
        Date__c = dates[(Integer) (groupIndex + groupsSize / 2) / 2],
        Stage__c = StageUtility.ROUND_OF_16_KO_STAGE
      );
      MatchUtility.generateMatchResult(match2);
      roundOf16Matches.add(match2);
    }

    insert as user roundOf16Matches;

    return roundOf16Matches;
  }
}
