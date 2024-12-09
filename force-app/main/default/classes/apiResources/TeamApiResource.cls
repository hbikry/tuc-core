/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-09-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@RestResource(urlMapping='/v1/tournaments/*/teams/*')
global with sharing class TeamApiResource {
  @HttpGet
  global static List<Tournament_Team__c> handleGetRequests() {
    RestRequest req = RestContext.request;
    String[] uriParts = req.requestURI.split('/');

    String tournamentCode = uriParts[3];

    if (uriParts.size() < 6) {
      // Handle /v1/tournaments/{code}/teams (collection)
      return getTeams(tournamentCode);
    } else {
      // Handle /v1/tournaments/{code}/teams/{teamCode} (item)
      String teamCode = uriParts[5];

      return getTeam(tournamentCode, teamCode);
    }
  }

  private static List<Tournament_Team__c> getTeams(String tournamentCode) {
    RestResponse res = RestContext.response;

    try {
      List<Tournament_Team__c> tournamentTeams = [
        SELECT Team__r.Code__c, Team__r.Name, Group__c
        FROM Tournament_Team__c
        WHERE Tournament__r.Code__c = :tournamentCode
        WITH USER_MODE
      ];

      Logger.info(
        'Returning response for /v1/tournament/' + tournamentCode + '/teams',
        tournamentTeams
      );

      return tournamentTeams;
    } catch (Exception e) {
      res.statusCode = 500;
      res.responseBody = Blob.valueOf(
        JSON.serialize(new Map<String, String>{ 'error' => e.getMessage() })
      );

      Logger.error(
        'Error occurred /v1/tournament/' + tournamentCode + '/teams',
        e
      );

      return null;
    } finally {
      Logger.saveLog();
    }
  }

  private static List<Tournament_Team__c> getTeam(
    String tournamentCode,
    String teamCode
  ) {
    RestResponse res = RestContext.response;

    try {
      List<Tournament_Team__c> tournamentTeams = [
        SELECT
          Team__r.Code__c,
          Team__r.Name,
          Group__c,
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
        res.statusCode = 404;

        return null;
      }

      Logger.info(
        'Returning response for /v1/tournament/' +
          tournamentCode +
          '/teams/' +
          teamCode,
        tournamentTeams
      );

      return tournamentTeams;
    } catch (Exception e) {
      res.statusCode = 500;
      res.responseBody = Blob.valueOf(
        JSON.serialize(new Map<String, String>{ 'error' => e.getMessage() })
      );

      Logger.error(
        'Error occurred /v1/tournament/' +
          tournamentCode +
          '/teams/' +
          teamCode,
        e
      );

      return null;
    } finally {
      Logger.saveLog();
    }
  }
}
