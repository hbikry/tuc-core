/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-09-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@RestResource(urlMapping='/v1/tournaments/*')
global with sharing class TournamentApiResource {
  @HttpGet
  global static List<Tournament__c> handleGetRequests() {
    RestRequest req = RestContext.request;
    String[] uriParts = req.requestURI.split('/');

    if (uriParts.size() < 4) {
      // Handle /v1/tournaments (collection)
      return getTournaments();
    } else {
      // Handle /v1/tournaments/{code} (item)
      String tournamentCode = uriParts[3];

      return getTournament(tournamentCode);
    }
  }

  private static List<Tournament__c> getTournaments() {
    RestResponse res = RestContext.response;

    try {
      List<Tournament__c> tournaments = [
        SELECT Code__c, Name, Start_Date__c
        FROM Tournament__c
        WITH USER_MODE
      ];

      Logger.info('Returning response for /v1/tournaments', tournaments);

      return tournaments;
    } catch (Exception e) {
      res.statusCode = 500;
      res.responseBody = Blob.valueOf(
        JSON.serialize(new Map<String, String>{ 'error' => e.getMessage() })
      );

      Logger.error('Error occurred in /v1/tournaments', e);

      return null;
    } finally {
      Logger.saveLog();
    }
  }

  private static List<Tournament__c> getTournament(String tournamentCode) {
    RestResponse res = RestContext.response;

    try {
      List<Tournament__c> tournaments = [
        SELECT
          Id,
          Name,
          Code__c,
          Start_Date__c,
          (
            SELECT
              Team__c,
              Team__r.Name,
              Team__r.Code__c,
              Goals_For__c,
              Goals_Against__c,
              Goal_Difference__c,
              Wins__c,
              Losses__c,
              Draws__c,
              Matches_Played__c,
              Points__c,
              Eliminated__c
            FROM Tournament_Teams__r
          ),
          (
            SELECT
              Id,
              Stage__c,
              Date__c,
              Home_Team__r.Id,
              Home_Team__r.Name,
              Home_Team__r.Code__c,
              Home_Team__r.Flag_Code__c,
              Home_Team_Goals__c,
              Away_Team__r.Id,
              Away_Team__r.Name,
              Away_Team__r.Code__c,
              Away_Team__r.Flag_Code__c,
              Away_Team_Goals__c,
              Winner_Team__c,
              Draw__c
            FROM Matches__r
          )
        FROM Tournament__c
        WHERE Code__c = :tournamentCode
        WITH USER_MODE
        LIMIT 1
      ];

      if (tournaments.isEmpty()) {
        res.statusCode = 404;

        return null;
      }

      Logger.info(
        'Returning response for /v1/tournaments/' + tournamentCode,
        tournaments
      );

      return tournaments;
    } catch (Exception e) {
      res.statusCode = 500;
      res.responseBody = Blob.valueOf(
        JSON.serialize(new Map<String, String>{ 'error' => e.getMessage() })
      );

      Logger.error('Error occurred in /v1/tournaments/' + tournamentCode, e);

      return null;
    } finally {
      Logger.saveLog();
    }
  }
}
