/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class MatchApiResourceTest {
  @isTest
  static void testHandleGetRequestsForTournamentMatches() {
    String tournamentCode = 'TEST';
    String homeTeamCode = 'HME';
    String awayTeamCode = 'AWY';
    // Create test data
    Tournament__c tournament = new Tournament__c(
      Name = 'Test Tournament',
      Code__c = tournamentCode,
      Start_Date__c = Date.today()
    );
    insert tournament;
    Team__c homeTeam = new Team__c(Name = 'Home Team', Code__c = homeTeamCode);
    Team__c awayTeam = new Team__c(Name = 'Away Team', Code__c = awayTeamCode);
    insert new List<Team__c>{ homeTeam, awayTeam };
    TriggerHandler.bypass('MatchTriggerHandler');
    Match__c match = new Match__c(
      Tournament__c = tournament.Id,
      Stage__c = StageUtility.ROUND_1_GROUP_STAGE,
      Date__c = Datetime.now(),
      Home_Team__c = homeTeam.Id,
      Home_Team_Goals__c = 2,
      Away_Team__c = awayTeam.Id,
      Away_Team_Goals__c = 1,
      Winner_Team__c = homeTeam.Id,
      Draw__c = false
    );
    insert match;
    // Set up the mock HTTP request
    RestRequest req = new RestRequest();
    req.requestURI = '/v1/tournaments/' + tournamentCode + '/matches';
    req.httpMethod = 'GET';
    RestContext.request = req;
    // Call the method
    List<TournamentDTO.Match> result = MatchApiResource.handleGetRequests();
    // Verify the result
    System.debug(result);
    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(1, result.size(), 'Result size should be 1');
    System.assertEquals(
      StageUtility.ROUND_1_GROUP_STAGE,
      result[0].stage,
      'Unexpected stage'
    );
    System.assertEquals(
      homeTeamCode,
      result[0].homeTeam,
      'Unexpected home team code'
    );
    System.assertEquals(
      2,
      result[0].homeTeamGoals,
      'Unexpected home team goals'
    );
    System.assertEquals(
      awayTeamCode,
      result[0].awayTeam,
      'Unexpected away team code'
    );
    System.assertEquals(
      1,
      result[0].awayTeamGoals,
      'Unexpected away team goals'
    );
  }

  @isTest
  static void testHandleGetRequestsForTeamMatches() {
    String tournamentCode = 'TEST';
    String homeTeamCode = 'HME';
    String awayTeamCode = 'AWY';
    // Create test data
    Tournament__c tournament = new Tournament__c(
      Name = 'Test Tournament',
      Code__c = tournamentCode,
      Start_Date__c = Date.today()
    );
    insert tournament;
    Team__c homeTeam = new Team__c(Name = 'Home Team', Code__c = homeTeamCode);
    Team__c awayTeam = new Team__c(Name = 'Away Team', Code__c = awayTeamCode);
    insert new List<Team__c>{ homeTeam, awayTeam };
    TriggerHandler.bypass('MatchTriggerHandler');
    Match__c match = new Match__c(
      Tournament__c = tournament.Id,
      Stage__c = StageUtility.ROUND_1_GROUP_STAGE,
      Date__c = Datetime.now(),
      Home_Team__c = homeTeam.Id,
      Home_Team_Goals__c = 2,
      Away_Team__c = awayTeam.Id,
      Away_Team_Goals__c = 1,
      Winner_Team__c = homeTeam.Id,
      Draw__c = false
    );
    insert match;
    // Set up the mock HTTP request
    RestRequest req = new RestRequest();
    req.requestURI =
      '/v1/tournaments/' +
      tournamentCode +
      '/matches/' +
      homeTeamCode;
    req.httpMethod = 'GET';
    RestContext.request = req;
    // Call the method
    List<TournamentDTO.Match> result = MatchApiResource.handleGetRequests();
    // Verify the result
    System.debug(result);
    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(1, result.size(), 'Result size should be 1');
    System.assertEquals(
      StageUtility.ROUND_1_GROUP_STAGE,
      result[0].stage,
      'Unexpected stage'
    );
    System.assertEquals(
      homeTeamCode,
      result[0].homeTeam,
      'Unexpected home team code'
    );
    System.assertEquals(
      2,
      result[0].homeTeamGoals,
      'Unexpected home team goals'
    );
    System.assertEquals(
      awayTeamCode,
      result[0].awayTeam,
      'Unexpected away team code'
    );
    System.assertEquals(
      1,
      result[0].awayTeamGoals,
      'Unexpected away team goals'
    );
  }
}
