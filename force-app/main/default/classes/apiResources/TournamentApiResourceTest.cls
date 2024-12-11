/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-11-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@isTest
private class TournamentApiResourceTest {
  @isTest
  static void testHandleGetRequestsCollection() {
    // Create test data
    List<Tournament__c> tournaments = new List<Tournament__c>();
    for (Integer i = 0; i < 3; i++) {
      tournaments.add(
        new Tournament__c(
          Name = 'Test Tournament ' + i,
          Code__c = 'TEST' + i,
          Start_Date__c = Date.today()
        )
      );
    }
    insert tournaments;
    // Simulate HTTP GET request for collection
    RestRequest req = new RestRequest();
    req.requestURI = '/v1/tournaments';
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestResponse res = new RestResponse();
    RestContext.response = res;
    List<TournamentDTO.Tournament> result = TournamentApiResource.handleGetRequests();
    // Verify the results
    System.assertEquals(
      3,
      result.size(),
      'Three tournaments should be returned'
    );
    for (Integer i = 0; i < 3; i++) {
      System.assertEquals(
        'TEST' + i,
        result[i].code,
        'Tournament code should match'
      );
      System.assertEquals(
        'Test Tournament ' + i,
        result[i].name,
        'Tournament name should match'
      );
    }
  }
  @isTest
  static void testHandleGetRequestsItem() {
    // Create test data
    String tournamentCode = 'TEST';
    Tournament__c tournament = new Tournament__c(
      Name = 'Test Tournament',
      Code__c = tournamentCode,
      Start_Date__c = Date.today()
    );
    insert tournament;
    List<Team__c> teams = new List<Team__c>();
    for (Integer i = 0; i < 2; i++) {
      teams.add(new Team__c(Name = 'Test Team ' + i, Code__c = 'T' + i));
    }
    insert teams;
    List<Tournament_Team__c> tournamentTeams = new List<Tournament_Team__c>();
    for (Team__c team : teams) {
      tournamentTeams.add(
        new Tournament_Team__c(
          Tournament__c = tournament.Id,
          Team__c = team.Id,
          Group__c = GroupUtility.GROUP_A,
          Goals_For__c = 10,
          Goals_Against__c = 5,
          Wins__c = 3,
          Losses__c = 1,
          Draws__c = 1,
          Eliminated__c = false
        )
      );
    }
    TriggerHandler.bypass('TournamentTeamTriggerHandler');
    insert tournamentTeams;
    List<Match__c> matches = new List<Match__c>();
    for (Integer i = 0; i < 2; i++) {
      matches.add(
        new Match__c(
          Tournament__c = tournament.Id,
          Home_Team__c = teams[i].Id,
          Away_Team__c = teams[Math.mod((i + 1), 2)].Id,
          Home_Team_Goals__c = 2,
          Away_Team_Goals__c = 1,
          Winner_Team__c = teams[i].Id,
          Stage__c = StageUtility.ROUND_1_GROUP_STAGE,
          Date__c = Date.today().addDays(i)
        )
      );
    }
    TriggerHandler.bypass('MatchTriggerHandler');
    insert matches;
    // Simulate HTTP GET request for item
    RestRequest req = new RestRequest();
    req.requestURI = '/v1/tournaments/' + tournamentCode;
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestResponse res = new RestResponse();
    RestContext.response = res;
    List<TournamentDTO.Tournament> result = TournamentApiResource.handleGetRequests();
    // Verify the results
    System.assertEquals(1, result.size(), 'One tournament should be returned');
    TournamentDTO.Tournament returnedTournament = result[0];
    System.assertEquals(
      tournamentCode,
      returnedTournament.code,
      'Tournament code should match'
    );
    System.assertEquals(
      'Test Tournament',
      returnedTournament.name,
      'Tournament name should match'
    );
    System.assertEquals(
      2,
      returnedTournament.teams.size(),
      'Two teams should be returned'
    );
    System.assertEquals(
      2,
      returnedTournament.matches.size(),
      'Two matches should be returned'
    );
  }

  @isTest
  static void testHandleGetRequestsItemNotFound() {
    // Simulate HTTP GET request for a non-existent tournament
    RestRequest req = new RestRequest();
    req.requestURI = '/v1/tournaments/NON_EXISTENT_TOURNAMENT';
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestResponse res = new RestResponse();
    RestContext.response = res;
    List<TournamentDTO.Tournament> result = TournamentApiResource.handleGetRequests();
    // Verify the results
    System.assertEquals(null, result, 'No tournament should be returned');
    System.assertEquals(
      404,
      RestContext.response.statusCode,
      'Status code should be 404'
    );
  }
}
