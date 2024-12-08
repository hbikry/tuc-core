/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-08-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class SemiFinalsGeneratorBatch implements Database.Batchable<SObject>, Database.Stateful {
  private Id tournamentId;
  private String originalTransactionId;

  public SemiFinalsGeneratorBatch(Id tournamentId, String loggerTransactionId) {
    this.tournamentId = tournamentId;
    this.originalTransactionId = loggerTransactionId;
  }

  public List<SObject> start(Database.BatchableContext bc) {
    List<Match__c> quarterFinalsMatches = [
      SELECT Id, Home_Team__c, Away_Team__c, Winner_Team__c
      FROM Match__c
      WHERE
        Tournament__c = :this.tournamentId
        AND Stage__c = :StageUtility.QUARTERFINAL_KO_STAGE
      WITH USER_MODE
    ];

    Logger.setParentLogTransactionId(this.originalTransactionId);
    Logger.info('Started semi-finals generator batch', quarterFinalsMatches);
    Logger.saveLog();

    return quarterFinalsMatches;
  }

  public void execute(Database.BatchableContext bc, List<SObject> scope) {
    Logger.setParentLogTransactionId(this.originalTransactionId);
    Logger.info('Executing semi-finals batch generator', scope);
    Savepoint savePoint = Database.setSavepoint();
    try {
      List<Match__c> quarterFinalsMatches = (List<Match__c>) scope;
      List<Match__c> semiFinalsMatches = generateSemiFinalsMatches(
        quarterFinalsMatches
      );
      Logger.info('semi-finals matches generated', semiFinalsMatches);
    } catch (Exception e) {
      Database.rollback(savePoint);
      Logger.error(
        'Error occurred while executing semi-finals generator batch. Rollbacking database changes',
        e
      );
    } finally {
      Logger.saveLog();
    }
  }

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
    Logger.info('Semi-finals generator batch finished', job);
    Logger.info('Queuing finals generator batch');
    FinalsGeneratorBatch nextBatch = new FinalsGeneratorBatch(
      this.tournamentId,
      this.originalTransactionId
    );
    Database.executeBatch(nextBatch);
    Logger.saveLog();
  }

  private List<Match__c> generateSemiFinalsMatches(
    List<Match__c> quarterFinalsMatches
  ) {
    List<Match__c> semiFinalsMatches = new List<Match__c>();

    // Generate dates
    Datetime date1 = Datetime.now().addDays(24);
    Datetime date2 = date1.addDays(1);
    Datetime[] dates = new List<Datetime>{ date1, date2 };
    Integer matchesSize = quarterFinalsMatches.size();

    for (Integer matchIndex = 0; matchIndex < matchesSize / 2; matchIndex++) {
      Match__c semiFinalMatch = new Match__c(
        Tournament__c = this.tournamentId,
        Home_Team__c = quarterFinalsMatches[matchIndex * 2].Winner_Team__c,
        Away_Team__c = quarterFinalsMatches[matchIndex * 2 + 1].Winner_Team__c,
        Date__c = dates[matchIndex],
        Stage__c = StageUtility.SEMIFINAL_KO_STAGE
      );
      MatchUtility.generateMatchResult(semiFinalMatch);
      semiFinalsMatches.add(semiFinalMatch);
    }

    insert as user semiFinalsMatches;

    return semiFinalsMatches;
  }
}
