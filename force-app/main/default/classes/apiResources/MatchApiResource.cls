/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-11-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@RestResource(urlMapping='/v1/tournaments/*/matches/*')
global with sharing class MatchApiResource {
  @HttpGet
  global static List<TournamentDTO.Match> handleGetRequests() {
    RestRequest req = RestContext.request;
    String[] uriParts = req.requestURI.split('/');

    try {
      String tournamentCode = uriParts[3];

      if (uriParts.size() < 6) {
        // Handle /v1/tournaments/{code}/matches (collection)
        return getTournamentMatches(tournamentCode);
      } else {
        // Handle /v1/tournaments/{code}/matches/{teamCode} (item)
        String teamCode = uriParts[5];

        return getTeamMatches(tournamentCode, teamCode);
      }
    } catch (Exception e) {
      RestContext.response.statusCode = 500;

      Logger.error('Error occurred in api: ' + req.requestURI, e);

      return null;
    } finally {
      Logger.saveLog();
    }
  }

  private static List<TournamentDTO.Match> getTournamentMatches(
    String tournamentCode
  ) {
    List<Match__c> matches = [
      SELECT
        Stage__c,
        Date__c,
        Home_Team__r.Code__c,
        Home_Team_Goals__c,
        Away_Team__r.Code__c,
        Away_Team_Goals__c,
        Winner_Team__r.Code__c,
        Draw__c
      FROM Match__c
      WHERE Tournament__r.Code__c = :tournamentCode
      WITH USER_MODE
    ];

    List<TournamentDTO.Match> dtoList = new List<TournamentDTO.Match>();

    for (Match__c match : matches) {
      dtoList.add(new TournamentDTO.Match(match));
    }

    return dtoList;
  }

  private static List<TournamentDTO.Match> getTeamMatches(
    String tournamentCode,
    String teamCode
  ) {
    List<Match__c> matches = [
      SELECT
        Stage__c,
        Date__c,
        Home_Team__r.Code__c,
        Home_Team_Goals__c,
        Away_Team__r.Code__c,
        Away_Team_Goals__c,
        Winner_Team__r.Code__c,
        Draw__c
      FROM Match__c
      WHERE
        Tournament__r.Code__c = :tournamentCode
        AND (Home_Team__r.Code__c = :teamCode
        OR Away_Team__r.Code__c = :teamCode)
      WITH USER_MODE
    ];

    List<TournamentDTO.Match> dtoList = new List<TournamentDTO.Match>();

    for (Match__c match : matches) {
      dtoList.add(new TournamentDTO.Match(match));
    }

    return dtoList;
  }
}
