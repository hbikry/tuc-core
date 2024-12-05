/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-05-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class TournamentGeneratorBatch implements Database.Batchable<SObject>, Database.Stateful {
  private String loggerTransactionId;

  public List<SObject> start(Database.BatchableContext bc) {
    // Query to get the teams for the tournament
    List<Team__c> teams = [
      SELECT Id, Name
      FROM Team__c
      LIMIT :TournamentConfigurationUtility.getDefaultMaxTeamsPerTournament()
    ];

    this.loggerTransactionId = Logger.getTransactionId();
    Logger.info('Started tournament generator batch', teams);
    Logger.saveLog();

    return teams;
  }

  public void execute(Database.BatchableContext bc, List<SObject> scope) {
    Logger.setParentLogTransactionId(this.loggerTransactionId);
    Logger.info('Executing tournament batch generator', scope);
    Savepoint savePoint = Database.setSavepoint();
    try {
      // Cast list
      List<Team__c> teams = (List<Team__c>) scope;

      // Add additional teams if necessary
      addAdditionalTeams(teams);

      // Create the tournament
      Tournament__c tournament = createTournament();
      Logger.info('Tournament created');

      // Shuffle teams list
      ListUtils.shuffle(teams);

      // Generate tournament teams
      List<Tournament_Team__c> tournamentTeams = generateTournamentTeams(
        tournament.Id,
        teams
      );
      Logger.info('Tournament teams generated');

      // Generate group stage matches
      generateGroupStageMatches(tournament.Id, tournamentTeams);
      Logger.info('Group stage matches generated');

      // Generate knockout stage matches
      //generateKnockoutStageMatches(tournament.Id, tournamentTeams);
      Logger.info('Knockout stage matches generated');
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
    Logger.setParentLogTransactionId(this.loggerTransactionId);
    Logger.info('Tournament generator batch finished', job);
    Logger.saveLog();
  }

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

  private void generateGroupStageMatches(
    Id tournamentId,
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

    // Define the matchups for each round
    Integer[][] roundMatchups = new List<Integer[]>{
      new List<Integer>{ 0, 1 },
      new List<Integer>{ 2, 3 }, // Round 1
      new List<Integer>{ 0, 2 },
      new List<Integer>{ 1, 3 }, // Round 2
      new List<Integer>{ 0, 3 },
      new List<Integer>{ 1, 2 } // Round 3
    };

    // Divide the teams into groups
    for (Integer groupIndex = 0; groupIndex < numberOfGroups; groupIndex++) {
      List<Tournament_Team__c> groupTeams = new List<Tournament_Team__c>();
      for (Integer i = 0; i < groupSize; i++) {
        groupTeams.add(tournamentTeams[groupIndex * groupSize + i]);
      }

      // Generate dates for each round
      Datetime round1Date = Datetime.now().addDays(1);
      Datetime round2Date = round1Date.addDays(5);
      Datetime round3Date = round2Date.addDays(5);

      // Define the dates for each round
      Datetime[] roundDates = new List<Datetime>{
        round1Date,
        round2Date,
        round3Date
      };
      // Generate matches for each round
      for (Integer matchup = 0; matchup < 6; matchup++) {
        Integer homeTeamIndex = roundMatchups[matchup][0];
        Integer awayTeamIndex = roundMatchups[matchup][1];
        Match__c match = new Match__c(
          Tournament__c = tournamentId,
          Home_Team__c = groupTeams[homeTeamIndex].Team__c,
          Away_Team__c = groupTeams[awayTeamIndex].Team__c,
          Date__c = roundDates[(Integer) matchup / 2],
          Stage__c = StageUtility.GROUP_STAGES[(Integer) matchup / 2]
        );
        MatchUtility.generateMatchResult(match);
        matches.add(match);
      }
    }

    insert matches;
  }
}
