/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-08-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class TournamentGeneratorBatch implements Database.Batchable<SObject>, Database.Stateful {
  private Id tournamentId;
  private String originalTransactionId;

  public List<SObject> start(Database.BatchableContext bc) {
    // Query to get the teams for the tournament
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

  public void execute(Database.BatchableContext bc, List<SObject> scope) {
    Logger.setParentLogTransactionId(this.originalTransactionId);
    Logger.info('Executing tournament batch generator', scope);
    Savepoint savePoint = Database.setSavepoint();
    try {
      // Cast list
      List<Team__c> teams = (List<Team__c>) scope;

      // Add additional teams if necessary
      addAdditionalTeams(teams);

      // Create the tournament
      Tournament__c tournament = createTournament();
      this.tournamentId = tournament.Id;
      Logger.info('Tournament created');

      // Shuffle teams list
      ListUtils.shuffle(teams);

      // Generate tournament teams
      List<Tournament_Team__c> tournamentTeams = generateTournamentTeams(
        tournament.Id,
        teams
      );
      Logger.info('Tournament teams generated', tournamentTeams);

      // Generate group stage matches
      // List<Match__c> groupStageMatches = generateGroupStageMatches(tournament.Id, tournamentTeams);
      // Logger.info('Group stage matches generated', groupStageMatches);

      // Generate knockout stage matches
      // List<Match__c> koStageMatches = generateKnockoutStageMatches(tournament.Id, tournamentTeams);
      // Logger.info('Knockout stage matches generated', koStageMatches);
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
    Logger.setParentLogTransactionId(this.originalTransactionId);
    Logger.info('Tournament generator batch finished', job);
    Logger.info('Queuing group stage generator batch');
    GroupStageGeneratorBatch nextBatch = new GroupStageGeneratorBatch(
      this.tournamentId,
      this.originalTransactionId
    );
    Database.executeBatch(nextBatch);
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

  // private List<Match__c> generateGroupStageMatches(
  //   Id tournamentId,
  //   List<Tournament_Team__c> tournamentTeams
  // ) {
  //   Integer maxTeams = TournamentConfigurationUtility.getDefaultMaxTeamsPerTournament();
  //   if (tournamentTeams.size() != maxTeams) {
  //     throw new IllegalArgumentException(
  //       'The list must contain exactly ' + maxTeams + ' teams.'
  //     );
  //   }

  //   List<Match__c> matches = new List<Match__c>();
  //   Integer groupSize = TournamentConfigurationUtility.getDefaultMaxTeamsPerGroup(); // Number of teams per group
  //   Integer numberOfGroups = TournamentConfigurationUtility.getDefaultMaxGroups(); // Total number of groups

  //   // Define the matchups for each round
  //   Integer[][] roundMatchups = new List<Integer[]>{
  //     new List<Integer>{ 0, 1 },
  //     new List<Integer>{ 2, 3 }, // Round 1
  //     new List<Integer>{ 0, 2 },
  //     new List<Integer>{ 1, 3 }, // Round 2
  //     new List<Integer>{ 0, 3 },
  //     new List<Integer>{ 1, 2 } // Round 3
  //   };

  //   // Divide the teams into groups
  //   for (Integer groupIndex = 0; groupIndex < numberOfGroups; groupIndex++) {
  //     List<Tournament_Team__c> groupTeams = new List<Tournament_Team__c>();
  //     for (Integer i = 0; i < groupSize; i++) {
  //       groupTeams.add(tournamentTeams[groupIndex * groupSize + i]);
  //     }

  //     // Generate dates for each round
  //     Datetime round1Date = Datetime.now().addDays(1);
  //     Datetime round2Date = round1Date.addDays(5);
  //     Datetime round3Date = round2Date.addDays(5);

  //     // Define the dates for each round
  //     Datetime[] roundDates = new List<Datetime>{
  //       round1Date,
  //       round2Date,
  //       round3Date
  //     };
  //     // Generate matches for each round
  //     for (Integer matchup = 0; matchup < 6; matchup++) {
  //       Integer homeTeamIndex = roundMatchups[matchup][0];
  //       Integer awayTeamIndex = roundMatchups[matchup][1];
  //       Match__c match = new Match__c(
  //         Tournament__c = tournamentId,
  //         Home_Team__c = groupTeams[homeTeamIndex].Team__c,
  //         Away_Team__c = groupTeams[awayTeamIndex].Team__c,
  //         Date__c = roundDates[(Integer) matchup / 2],
  //         Stage__c = StageUtility.GROUP_STAGES[(Integer) matchup / 2]
  //       );
  //       MatchUtility.generateMatchResult(match);
  //       matches.add(match);
  //     }
  //   }

  //   insert as user matches;

  //   return matches;
  // }

  // private List<Match__c> generateKnockoutStageMatches(
  //   Id tournamentId,
  //   List<Tournament_Team__c> tournamentTeams
  // ) {
  //   List<Match__c> matches = new List<Match__c>();

  //   List<Match__c> roundOf16Matches = generateRoundOf16Matches(tournamentId);
  //   matches.addAll(roundOf16Matches);

  //   List<Match__c> quarterFinalsMatches = generateQuarteFinalsMatches(roundOf16Matches);
  //   matches.addAll(quarterFinalsMatches);

  //   List<Match__c> semiFinalsMatches = generateSemiFinalsMatches(quarterFinalsMatches);
  //   matches.addAll(semiFinalsMatches);

  //   Match__c thirdPlaceMatch = generateThirdPlaceMatch(semiFinalsMatches);
  //   matches.add(thirdPlaceMatch);

  //   Match__c finalMatch = generateFinalMatch(semiFinalsMatches);
  //   matches.add(finalMatch);

  //   insert as user matches;

  //   return matches;
  // }

  // private List<Match__c> generateRoundOf16Matches(Id tournamentId) {
  //   List<Tournament_Team__c> tournamentTeams = [
  //     SELECT Team__c, Group__c
  //     FROM Tournament_Team__c
  //     WHERE Tournament__c = :tournamentId
  //     WITH USER_MODE
  //     ORDER BY Group__c ASC, Points__c DESC, Qualification_Points__c DESC
  //   ];

  //   // Map to hold the top two teams from each group
  //   Map<String, List<Tournament_Team__c>> topTeamsByGroup = new Map<String, List<Tournament_Team__c>>();
  //   // Loop over the records to determine the top two teams from each group
  //   for (Tournament_Team__c tt : tournamentTeams) {
  //     if (!topTeamsByGroup.containsKey(tt.Group__c)) {
  //       topTeamsByGroup.put(tt.Group__c, new List<Tournament_Team__c>());
  //     }

  //     if (topTeamsByGroup.get(tt.Group__c).size() < 2) {
  //       topTeamsByGroup.get(tt.Group__c).add(tt);
  //     }
  //   }

  //   // List to hold the Round of 16 matches
  //   List<Match__c> roundOf16Matches = new List<Match__c>();

  //   // Generate dates
  //   Datetime date1 = Datetime.now().addDays(15);
  //   Datetime date2 = date1.addDays(1);
  //   Datetime date3 = date2.addDays(1);
  //   Datetime date4 = date3.addDays(1);
  //   Datetime[] dates = new List<Datetime>{date1, date2, date3, date4};
  //   Integer groupsSize = GroupUtility.GROUPS.size();

  //   for (Integer groupIndex = 0; groupIndex < groupsSize / 2; groupIndex++) {
  //     String groupName = GroupUtility.GROUPS[groupIndex];
  //     String nextGroupName = GroupUtility.nextGroup(groupName);

  //     List<Tournament_Team__c> groupTeams = topTeamsByGroup.get(groupName);
  //     List<Tournament_Team__c> nextGroupTeams = topTeamsByGroup.get(nextGroupName);

  //     Match__c match1 = new Match__c(
  //       Tournament__c = tournamentId,
  //       Home_Team__c = groupTeams[0].Team__c,
  //       Away_Team__c = nextGroupTeams[1].Team__c,
  //       Date__c = dates[(Integer) groupIndex / 2],
  //       Stage__c = StageUtility.ROUND_OF_16_KO_STAGE
  //     );
  //     MatchUtility.generateMatchResult(match1);
  //     roundOf16Matches.add(match1);

  //     Match__c match2 = new Match__c(
  //       Tournament__c = tournamentId,
  //       Home_Team__c = nextGroupTeams[0].Team__c,
  //       Away_Team__c = groupTeams[1].Team__c,
  //       Date__c = dates[(Integer) (groupIndex + groupsSize / 2) / 2],
  //       Stage__c = StageUtility.ROUND_OF_16_KO_STAGE
  //     );
  //     MatchUtility.generateMatchResult(match2);
  //     roundOf16Matches.add(match2);
  //   }

  //   //insert as user roundOf16Matches;

  //   return roundOf16Matches;
  // }

  // private List<Match__c> generateQuarteFinalsMatches(List<Match__c> roundOf16Matches) {
  //   List<Match__c> quarterFinalsMatches = new List<Match__c>();

  //   // Generate dates
  //   Datetime date1 = Datetime.now().addDays(20);
  //   Datetime date2 = date1.addDays(1);
  //   Datetime[] dates = new List<Datetime>{date1, date2};
  //   Integer matchesSize = roundOf16Matches.size();

  //   for (Integer matchIndex = 0; matchIndex < matchesSize / 2; matchIndex) {
  //     Match__c quarterFinalMatch = new Match__c(
  //       Tournament__c = roundOf16Matches[0].Tournament__c,
  //       Home_Team__c = roundOf16Matches[matchIndex * 2].Winner_Team__c,
  //       Away_Team__c = roundOf16Matches[matchIndex * 2 + 1].Winner_Team__c,
  //       Date__c = dates[(Integer) matchIndex / 2],
  //       Stage__c = StageUtility.QUARTERFINAL_KO_STAGE
  //     );
  //     MatchUtility.generateMatchResult(quarterFinalMatch);
  //     quarterFinalsMatches.add(quarterFinalMatch);
  //   }

  //   //insert as user quarterFinalsMatches;

  //   return quarterFinalsMatches;
  // }

  // private List<Match__c> generateSemiFinalsMatches(List<Match__c> quarterFinalsMatches) {
  //   List<Match__c> semiFinalsMatches = new List<Match__c>();

  //   // Generate dates
  //   Datetime date1 = Datetime.now().addDays(24);
  //   Datetime date2 = date1.addDays(1);
  //   Datetime[] dates = new List<Datetime>{date1, date2};
  //   Integer matchesSize = quarterFinalsMatches.size();

  //   for (Integer matchIndex = 0; matchIndex < matchesSize / 2; matchIndex) {
  //     Match__c semiFinalMatch = new Match__c(
  //       Tournament__c = quarterFinalsMatches[0].Tournament__c,
  //       Home_Team__c = quarterFinalsMatches[matchIndex * 2].Winner_Team__c,
  //       Away_Team__c = quarterFinalsMatches[matchIndex * 2 + 1].Winner_Team__c,
  //       Date__c = dates[matchIndex],
  //       Stage__c = StageUtility.SEMIFINAL_KO_STAGE
  //     );
  //     MatchUtility.generateMatchResult(semiFinalMatch);
  //     semiFinalsMatches.add(semiFinalMatch);
  //   }

  //   //insert as user semiFinalsMatches;

  //   return semiFinalsMatches;
  // }

  // private Match__c generateThirdPlaceMatch(List<Match__c> semiFinalsMatches) {
  //   List<Id> loserTeamIds = new List<Id>();
  //   for (Match__c semiFinalMatch : semiFinalsMatches) {
  //     if (semiFinalMatch.Home_Team__c == semiFinalMatch.Winner_Team__c) {
  //       loserTeamIds.add(semiFinalMatch.Away_Team__c);
  //     } else {
  //       loserTeamIds.add(semiFinalMatch.Home_Team__c);
  //     }
  //   }

  //   Match__c thirdPlaceMatch = new Match__c(
  //     Tournament__c = semiFinalsMatches[0].Tournament__c,
  //     Home_Team__c = loserTeamIds[0],
  //     Away_Team__c = loserTeamIds[1],
  //     Date__c = Datetime.now().addDays(28),
  //     Stage__c = StageUtility.THIRD_PLACE_KO_STAGE
  //   );
  //   MatchUtility.generateMatchResult(thirdPlaceMatch);

  //   //insert as user thirdPlaceMatch;

  //   return thirdPlaceMatch;
  // }

  // private Match__c generateFinalMatch(List<Match__c> semiFinalsMatches) {
  //   Match__c finalMatch = new Match__c(
  //     Tournament__c = semiFinalsMatches[0].Tournament__c,
  //     Home_Team__c = semiFinalsMatches[0].Winner_Team__c,
  //     Away_Team__c = semiFinalsMatches[1].Winner_Team__c,
  //     Date__c = Datetime.now().addDays(29),
  //     Stage__c = StageUtility.FINAL_KO_STAGE
  //   );
  //   MatchUtility.generateMatchResult(finalMatch);

  //   //insert as user finalMatch;

  //   return finalMatch;
  // }
}
