/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-10-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class QuarterFinalsGeneratorBatch implements Database.Batchable<SObject>, Database.Stateful {
  private Id tournamentId;
  private String originalTransactionId;

  public QuarterFinalsGeneratorBatch(
    Id tournamentId,
    String loggerTransactionId
  ) {
    this.tournamentId = tournamentId;
    this.originalTransactionId = loggerTransactionId;
  }

  /**
   * @description : Batch start -> Retrieve round of 16 matches
   * @author hbikry@salesforce.com | 12-09-2024
   * @param bc
   * @return List<SObject>
   **/
  public List<SObject> start(Database.BatchableContext bc) {
    List<Match__c> roundOf16Matches = [
      SELECT Id, Home_Team__c, Away_Team__c, Winner_Team__c
      FROM Match__c
      WHERE
        Tournament__c = :this.tournamentId
        AND Stage__c = :StageUtility.ROUND_OF_16_KO_STAGE
      WITH USER_MODE
      ORDER BY Bracket__c ASC NULLS LAST, Date__c ASC
    ];

    Logger.setParentLogTransactionId(this.originalTransactionId);
    Logger.info('Started quarter-finals generator batch', roundOf16Matches);
    Logger.saveLog();

    return roundOf16Matches;
  }

  /**
   * @description : Batch execute -> generate quarter-finals matches
   * @author hbikry@salesforce.com | 12-09-2024
   * @param bc
   * @param scope
   **/
  public void execute(Database.BatchableContext bc, List<SObject> scope) {
    Logger.setParentLogTransactionId(this.originalTransactionId);
    Savepoint savePoint = Database.setSavepoint();
    try {
      // Generate quarter-finals stage matches
      List<Match__c> quarterFinalsMatches = generateQuarteFinalsMatches(
        (List<Match__c>) scope
      );
      Logger.info('Quarter-finals matches generated', quarterFinalsMatches);
    } catch (Exception e) {
      Database.rollback(savePoint);
      Logger.error(
        'Error occurred while executing quarter-finals generator batch. Rollbacking database changes',
        e
      );
    } finally {
      Logger.saveLog();
    }
  }

  /**
   * @description : Batch finish -> Log job record & queue semi-finals generator batch
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
    Logger.info('Quarter-finals generator batch finished', job);

    SemiFinalsGeneratorBatch nextBatch = new SemiFinalsGeneratorBatch(
      this.tournamentId,
      this.originalTransactionId
    );
    Database.executeBatch(nextBatch);

    Logger.saveLog();
  }

  private List<Match__c> generateQuarteFinalsMatches(
    List<Match__c> roundOf16Matches
  ) {
    List<Match__c> quarterFinalsMatches = new List<Match__c>();

    // Generate dates
    Datetime date1 = Datetime.now().addDays(20);
    Datetime date2 = date1.addDays(1);
    Datetime[] dates = new List<Datetime>{ date1, date2 };

    for (
      Integer matchIndex = 0;
      matchIndex < roundOf16Matches.size() / 2;
      matchIndex++
    ) {
      Match__c match = new Match__c(
        Tournament__c = this.tournamentId,
        Home_Team__c = roundOf16Matches[matchIndex * 2].Winner_Team__c,
        Away_Team__c = roundOf16Matches[matchIndex * 2 + 1].Winner_Team__c,
        Date__c = dates[(Integer) matchIndex / 2],
        Stage__c = StageUtility.QUARTERFINAL_KO_STAGE
      );
      MatchUtility.generateMatchResult(match);
      quarterFinalsMatches.add(match);
    }

    insert as user quarterFinalsMatches;

    return quarterFinalsMatches;
  }
}
