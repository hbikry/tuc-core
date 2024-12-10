/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-10-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class FinalsGeneratorBatch implements Database.Batchable<SObject>, Database.Stateful {
  private Id tournamentId;
  private String originalTransactionId;

  public FinalsGeneratorBatch(Id tournamentId, String loggerTransactionId) {
    this.tournamentId = tournamentId;
    this.originalTransactionId = loggerTransactionId;
  }

  /**
   * @description : Batch start -> retrieve semi-finals matches
   * @author hbikry@salesforce.com | 12-09-2024
   * @param bc
   * @return List<SObject>
   **/
  public List<SObject> start(Database.BatchableContext bc) {
    List<Match__c> semiFinalsMatches = [
      SELECT Id, Home_Team__c, Away_Team__c, Winner_Team__c
      FROM Match__c
      WHERE
        Tournament__c = :this.tournamentId
        AND Stage__c = :StageUtility.SEMIFINAL_KO_STAGE
      WITH USER_MODE
      ORDER BY Date__c ASC
    ];

    Logger.setParentLogTransactionId(this.originalTransactionId);
    Logger.info('Started finals generator batch', semiFinalsMatches);
    Logger.saveLog();

    return semiFinalsMatches;
  }

  /**
   * @description : Batch execute -> Generate third-place and final matches
   * @author hbikry@salesforce.com | 12-09-2024
   * @param bc
   * @param scope
   **/
  public void execute(Database.BatchableContext bc, List<SObject> scope) {
    Logger.setParentLogTransactionId(this.originalTransactionId);
    Savepoint savePoint = Database.setSavepoint();
    try {
      List<Match__c> semiFinalsMatches = (List<Match__c>) scope;
      Match__c thirdPlaceMatch = generateThirdPlaceMatch(semiFinalsMatches);
      Logger.info('Third place play-off match generated', thirdPlaceMatch);
      Match__c finalMatch = generateFinalMatch(semiFinalsMatches);
      Logger.info('Final match generated', finalMatch);
    } catch (Exception e) {
      Database.rollback(savePoint);
      Logger.error(
        'Error occurred while executing finals generator batch. Rollbacking database changes',
        e
      );
    } finally {
      Logger.saveLog();
    }
  }

  /**
   * @description : Batch finish -> Log job record
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
    Logger.info('Finals generator batch finished', job);
    Logger.saveLog();
  }

  /**
   * @description : Generate & insert third place match
   * @author hbikry@salesforce.com | 12-09-2024
   * @param semiFinalsMatches
   * @return Match__c
   **/
  private Match__c generateThirdPlaceMatch(List<Match__c> semiFinalsMatches) {
    List<Id> loserTeamIds = new List<Id>();
    for (Match__c semiFinalMatch : semiFinalsMatches) {
      if (semiFinalMatch.Home_Team__c == semiFinalMatch.Winner_Team__c) {
        loserTeamIds.add(semiFinalMatch.Away_Team__c);
      } else {
        loserTeamIds.add(semiFinalMatch.Home_Team__c);
      }
    }

    Match__c thirdPlaceMatch = new Match__c(
      Tournament__c = this.tournamentId,
      Home_Team__c = loserTeamIds[0],
      Away_Team__c = loserTeamIds[1],
      Date__c = Datetime.now().addDays(28),
      Stage__c = StageUtility.THIRD_PLACE_KO_STAGE
    );
    MatchUtility.generateMatchResult(thirdPlaceMatch);

    insert as user thirdPlaceMatch;

    return thirdPlaceMatch;
  }

  /**
   * @description : Generate & insert final match
   * @author hbikry@salesforce.com | 12-09-2024
   * @param semiFinalsMatches
   * @return Match__c
   **/
  private Match__c generateFinalMatch(List<Match__c> semiFinalsMatches) {
    Match__c finalMatch = new Match__c(
      Tournament__c = this.tournamentId,
      Home_Team__c = semiFinalsMatches[0].Winner_Team__c,
      Away_Team__c = semiFinalsMatches[1].Winner_Team__c,
      Date__c = Datetime.now().addDays(29),
      Stage__c = StageUtility.FINAL_KO_STAGE
    );
    MatchUtility.generateMatchResult(finalMatch);

    insert as user finalMatch;

    return finalMatch;
  }
}
