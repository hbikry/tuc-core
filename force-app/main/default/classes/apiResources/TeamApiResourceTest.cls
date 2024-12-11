/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-11-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@isTest
private class TeamApiResourceTest {
  @isTest
  static void testHandleGetRequestsCollection() {
    // Create test data
    String tournamentCode = 'TEST';
    Tournament__c tournament = new Tournament__c(
      Name = 'Test Tournament',
      Code__c = tournamentCode,
      Start_Date__c = Date.today()
    );
    insert tournament;
    List<Team__c> teams = new List<Team__c>();
    for (Integer i = 0; i < 3; i++) {
      teams.add(new Team__c(Name = 'Test Team ' + i, Code__c = 'T' + i));
    }
    insert teams;
    List<Tournament_Team__c> tournamentTeams = new List<Tournament_Team__c>();
    for (Team__c team : teams) {
      tournamentTeams.add(
        new Tournament_Team__c(
          Tournament__c = tournament.Id,
          Team__c = team.Id,
          Group__c = GroupUtility.GROUP_A
        )
      );
    }
    TriggerHandler.bypass('TournamentTeamTriggerHandler');
    insert tournamentTeams;
    // Simulate HTTP GET request for collection
    RestRequest req = new RestRequest();
    req.requestURI = '/v1/tournaments/' + tournamentCode + '/teams';
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestResponse res = new RestResponse();
    RestContext.response = res;
    List<TournamentDTO.Team> result = TeamApiResource.handleGetRequests();
    // Verify the results
    System.assertEquals(3, result.size(), 'Three teams should be returned');
    for (Integer i = 0; i < 3; i++) {
      System.assertEquals('T' + i, result[i].code, 'Team code should match');
      System.assertEquals(
        'Test Team ' + i,
        result[i].name,
        'Team name should match'
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
    String teamCode = 'TM';
    String teamName = 'Test Team';
    Team__c team = new Team__c(Name = teamName, Code__c = teamCode);
    insert team;
    Tournament_Team__c tournamentTeam = new Tournament_Team__c(
      Tournament__c = tournament.Id,
      Team__c = team.Id,
      Group__c = GroupUtility.GROUP_A,
      Goals_For__c = 10,
      Goals_Against__c = 5,
      Wins__c = 1,
      Losses__c = 1,
      Draws__c = 1,
      Eliminated__c = false
    );
    TriggerHandler.bypass('TournamentTeamTriggerHandler');
    insert tournamentTeam;
    // Simulate HTTP GET request for item
    RestRequest req = new RestRequest();
    req.requestURI = '/v1/tournaments/' + tournamentCode + '/teams/' + teamCode;
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestResponse res = new RestResponse();
    RestContext.response = res;
    List<TournamentDTO.Team> result = TeamApiResource.handleGetRequests();
    // Verify the results
    System.assertEquals(1, result.size(), 'One team should be returned');
    TournamentDTO.Team returnedTeam = result[0];
    System.assertEquals(teamCode, returnedTeam.code, 'Team code should match');
    System.assertEquals(teamName, returnedTeam.name, 'Team name should match');
    System.assertEquals(
      GroupUtility.GROUP_A,
      returnedTeam.stats.groupName,
      'Group should match'
    );
    System.assertEquals(
      10,
      returnedTeam.stats.goalsFor,
      'Goals For should match'
    );
    System.assertEquals(
      5,
      returnedTeam.stats.goalsAgainst,
      'Goals Against should match'
    );
    System.assertEquals(
      5,
      returnedTeam.stats.goalsDifference,
      'Goal Difference should match'
    );
    System.assertEquals(1, returnedTeam.stats.wins, 'Wins should match');
    System.assertEquals(1, returnedTeam.stats.losses, 'Losses should match');
    System.assertEquals(1, returnedTeam.stats.draws, 'Draws should match');
    System.assertEquals(
      3,
      returnedTeam.stats.matchesPlayed,
      'Matches Played should match'
    );
    System.assertEquals(4, returnedTeam.stats.points, 'Points should match');
    System.assertEquals(
      false,
      returnedTeam.stats.eliminated,
      'Eliminated should match'
    );
  }

  @isTest
  static void testHandleGetRequestsItemNotFound() {
    // Create test data
    String tournamentCode = 'TEST';
    Tournament__c tournament = new Tournament__c(
      Name = 'Test Tournament',
      Code__c = tournamentCode,
      Start_Date__c = Date.today()
    );
    insert tournament;
    // Simulate HTTP GET request for a non-existent team
    RestRequest req = new RestRequest();
    req.requestURI =
      '/v1/tournaments/' +
      tournamentCode +
      '/teams/NON_EXISTENT_TEAM';
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestResponse res = new RestResponse();
    RestContext.response = res;
    List<TournamentDTO.Team> result = TeamApiResource.handleGetRequests();
    // Verify the results
    System.assertEquals(null, result, 'No team should be returned');
    System.assertEquals(
      404,
      RestContext.response.statusCode,
      'Status code should be 404'
    );
  }
}
