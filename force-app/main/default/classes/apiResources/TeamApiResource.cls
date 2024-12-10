/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-11-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@RestResource(urlMapping='/v1/tournaments/*/teams/*')
global with sharing class TeamApiResource {
  @HttpGet
  global static List<TournamentDTO.Team> handleGetRequests() {
    RestRequest req = RestContext.request;
    Logger.info('Request for api: ' + req.requestURI);
    String[] uriParts = req.requestURI.split('/');

    try {
      String tournamentCode = uriParts[3];

      if (uriParts.size() < 6) {
        // Handle /v1/tournaments/{code}/teams (collection)
        return getTeams(tournamentCode);
      } else {
        // Handle /v1/tournaments/{code}/teams/{teamCode} (item)
        String teamCode = uriParts[5];

        return getTeam(tournamentCode, teamCode);
      }
    } catch (Exception e) {
      RestContext.response.statusCode = 500;

      Logger.error('Error occurred in api: ' + req.requestURI, e);

      return null;
    } finally {
      Logger.saveLog();
    }
  }

  private static List<TournamentDTO.Team> getTeams(String tournamentCode) {
    List<Tournament_Team__c> tournamentTeams = [
      SELECT Team__r.Code__c, Team__r.Name
      FROM Tournament_Team__c
      WHERE Tournament__r.Code__c = :tournamentCode
      WITH USER_MODE
    ];

    List<TournamentDTO.Team> dtoList = new List<TournamentDTO.Team>();

    for (Tournament_Team__c tournamentTeam : tournamentTeams) {
      dtoList.add(
        new TournamentDTO.Team(
          tournamentTeam.Team__r.Code__c,
          tournamentTeam.Team__r.Name
        )
      );
    }

    return dtoList;
  }

  private static List<TournamentDTO.Team> getTeam(
    String tournamentCode,
    String teamCode
  ) {
    List<Tournament_Team__c> tournamentTeams = [
      SELECT
        Group__c,
        Team__r.Code__c,
        Team__r.Name,
        Goals_For__c,
        Goals_Against__c,
        Goal_Difference__c,
        Wins__c,
        Losses__c,
        Draws__c,
        Matches_Played__c,
        Points__c,
        Eliminated__c
      FROM Tournament_Team__c
      WHERE
        Tournament__r.Code__c = :tournamentCode
        AND Team__r.Code__c = :teamCode
      WITH USER_MODE
      LIMIT 1
    ];

    if (tournamentTeams.isEmpty()) {
      RestContext.response.statusCode = 404;

      Logger.info(
        'Team ' + teamCode + ' in tournament ' + tournamentCode + ' not found'
      );

      return null;
    }

    return new List<TournamentDTO.Team>{
      new TournamentDTO.Team(tournamentTeams[0])
    };
  }
}
