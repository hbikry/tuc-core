/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-09-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class TournamentGeneratorBatch implements Database.Batchable<SObject>, Database.Stateful {
  private Id tournamentId;
  private String originalTransactionId;

  /**
   * @description : Batch start -> Retrieve teams
   * @author hbikry@salesforce.com | 12-09-2024
   * @param bc
   * @return List<SObject>
   **/
  public List<SObject> start(Database.BatchableContext bc) {
    List<Team__c> teams = [
      SELECT Id, Name
      FROM Team__c
      WITH USER_MODE
      LIMIT :TournamentConfigurationUtility.getDefaultMaxTeamsPerTournament()
    ];

    this.originalTransactionId = Logger.getTransactionId();
    Logger.info('Started tournament generator batch', teams);
    Logger.saveLog();

    return teams;
  }

  /**
   * @description : Batch execute -> Generate tournament & tournament teams
   * @author hbikry@salesforce.com | 12-09-2024
   * @param bc
   * @param scope
   **/
  public void execute(Database.BatchableContext bc, List<SObject> scope) {
    Logger.setParentLogTransactionId(this.originalTransactionId);
    Savepoint savePoint = Database.setSavepoint();
    try {
      // Cast list
      List<Team__c> teams = (List<Team__c>) scope;

      // Add additional teams if necessary
      addAdditionalTeams(teams);

      // Create the tournament
      Tournament__c tournament = createTournament();
      this.tournamentId = tournament.Id;
      Logger.info('Tournament generated', tournament);

      // Shuffle teams list
      ListUtils.shuffle(teams);

      // Generate tournament teams
      List<Tournament_Team__c> tournamentTeams = generateTournamentTeams(
        tournament.Id,
        teams
      );
      Logger.info('Tournament teams generated', tournamentTeams);
    } catch (Exception e) {
      Database.rollback(savePoint);
      Logger.error(
        'Error occurred while executing tournament generator batch. Rollbacking database changes',
        e
      );
    } finally {
      Logger.saveLog();
    }
  }

  /**
   * @description : Batch finish -> Log job record & queue group stage generator batch
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
    ];

    Logger.setParentLogTransactionId(this.originalTransactionId);
    Logger.info('Tournament generator batch finished', job);

    GroupStageGeneratorBatch nextBatch = new GroupStageGeneratorBatch(
      this.tournamentId,
      this.originalTransactionId
    );
    Database.executeBatch(nextBatch);

    Logger.saveLog();
  }

  /**
   * @description : Generate & insert a tournament
   * @author hbikry@salesforce.com | 12-09-2024
   * @return Tournament__c
   **/
  private Tournament__c createTournament() {
    Datetime now = Datetime.now();
    Tournament__c tournament = new Tournament__c(
      Name = 'Generated Tournament ' + now.format('yyMMdHms'),
      Code__c = 'GT' + now.format('yyMMdHms'),
      Start_Date__c = Date.today()
    );
    insert tournament;

    return tournament;
  }

  /**
   * @description : Add & insert additional teams if necessary
   * @author hbikry@salesforce.com | 12-09-2024
   * @param teams
   **/
  private void addAdditionalTeams(List<Team__c> teams) {
    Datetime now = Datetime.now();
    // If the number of queried teams is less than 32, generate additional teams
    Integer additionalTeamsNeeded =
      TournamentConfigurationUtility.getDefaultMaxTeamsPerTournament() -
      teams.size();

    if (additionalTeamsNeeded <= 0) {
      return;
    }

    List<Team__c> generatedTeams = new List<Team__c>();
    for (Integer i = 0; i < additionalTeamsNeeded; i++) {
      generatedTeams.add(
        new Team__c(Name = 'Generated Team ' + now.format() + '-' + i)
      );
    }

    insert generatedTeams;

    teams.addAll(generatedTeams);
  }

  /**
   * @description : Generate & insert tournament teams
   * @author hbikry@salesforce.com | 12-09-2024
   * @param tournamentId
   * @param teams
   * @return List<Tournament_Team__c>
   **/
  private List<Tournament_Team__c> generateTournamentTeams(
    Id tournamentId,
    List<Team__c> teams
  ) {
    List<Tournament_Team__c> tournamentTeams = new List<Tournament_Team__c>();
    Integer groupSize = TournamentConfigurationUtility.getDefaultMaxTeamsPerGroup();
    Integer groupIndex = 0;
    for (String groupName : GroupUtility.GROUPS) {
      for (Integer i = groupIndex; i < groupSize + groupIndex; i++) {
        tournamentTeams.add(
          new Tournament_Team__c(
            Tournament__c = tournamentId,
            Team__c = teams[i].Id,
            Name = teams[i].Name,
            Group__c = groupName
          )
        );
      }

      groupIndex += groupSize;
    }

    insert tournamentTeams;

    return tournamentTeams;
  }
}
