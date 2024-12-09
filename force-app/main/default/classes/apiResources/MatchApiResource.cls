/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-09-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@RestResource(urlMapping='/v1/tournaments/*/matches/*')
global with sharing class MatchApiResource {
  @HttpGet
  global static List<Match__c> handleGetRequests() {
    RestRequest req = RestContext.request;
    String[] uriParts = req.requestURI.split('/');

    String tournamentCode = uriParts[3];

    if (uriParts.size() < 6) {
      // Handle /v1/tournaments/{code}/matches (collection)
      return getTournamentMatches(tournamentCode);
    } else {
      // Handle /v1/tournaments/{code}/matches/{teamCode} (item)
      String teamCode = uriParts[5];

      return getTeamMatches(tournamentCode, teamCode);
    }
  }

  private static List<Match__c> getTournamentMatches(String tournamentCode) {
    RestResponse res = RestContext.response;

    try {
      List<Match__c> matches = [
        SELECT
          Home_Team__r.Code__c,
          Home_Team__r.Name,
          Away_Team__r.Code__c,
          Away_Team__r.Name,
          Date__c,
          Stage__c,
          Home_Team_Goals__c,
          Away_Team_Goals__c,
          Winner_Team__c,
          Draw__c
        FROM Match__c
        WHERE Tournament__r.Code__c = :tournamentCode
        WITH USER_MODE
      ];

      Logger.info(
        'Returning response for /v1/tournament/' + tournamentCode + '/matches',
        matches
      );

      return matches;
    } catch (Exception e) {
      res.statusCode = 500;
      res.responseBody = Blob.valueOf(
        JSON.serialize(new Map<String, String>{ 'error' => e.getMessage() })
      );

      Logger.error(
        'Error occurred /v1/tournament/' + tournamentCode + '/matches',
        e
      );

      return null;
    } finally {
      Logger.saveLog();
    }
  }

  private static List<Match__c> getTeamMatches(
    String tournamentCode,
    String teamCode
  ) {
    RestResponse res = RestContext.response;

    try {
      List<Match__c> matches = [
        SELECT
          Home_Team__r.Code__c,
          Home_Team__r.Name,
          Away_Team__r.Code__c,
          Away_Team__r.Name,
          Date__c,
          Stage__c,
          Home_Team_Goals__c,
          Away_Team_Goals__c,
          Winner_Team__c,
          Draw__c
        FROM Match__c
        WHERE
          Tournament__r.Code__c = :tournamentCode
          AND (Home_Team__r.Code__c = :teamCode
          OR Away_Team__r.Code__c = :teamCode)
        WITH USER_MODE
      ];

      if (matches.isEmpty()) {
        res.statusCode = 404;

        return null;
      }

      Logger.info(
        'Returning response for /v1/tournament/' +
          tournamentCode +
          '/matches/' +
          teamCode,
        matches
      );

      return matches;
    } catch (Exception e) {
      res.statusCode = 500;
      res.responseBody = Blob.valueOf(
        JSON.serialize(new Map<String, String>{ 'error' => e.getMessage() })
      );

      Logger.error(
        'Error occurred /v1/tournament/' +
          tournamentCode +
          '/matches/' +
          teamCode,
        e
      );

      return null;
    } finally {
      Logger.saveLog();
    }
  }
}
