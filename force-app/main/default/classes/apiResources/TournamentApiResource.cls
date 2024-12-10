/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-11-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@RestResource(urlMapping='/v1/tournaments/*')
global with sharing class TournamentApiResource {
  @HttpGet
  global static List<TournamentDTO.Tournament> handleGetRequests() {
    RestRequest req = RestContext.request;
    Logger.info('Request for api: ' + req.requestURI);
    String[] uriParts = req.requestURI.split('/');

    try {
      if (uriParts.size() < 4) {
        // Handle /v1/tournaments (collection)
        return getTournaments();
      } else {
        // Handle /v1/tournaments/{code} (item)
        String tournamentCode = uriParts[3];

        return getTournament(tournamentCode);
      }
    } catch (Exception e) {
      RestContext.response.statusCode = 500;

      Logger.error('Error occurred in api: ' + req.requestURI, e);

      return null;
    } finally {
      Logger.saveLog();
    }
  }

  private static List<TournamentDTO.Tournament> getTournaments() {
    List<Tournament__c> tournaments = [
      SELECT Code__c, Name, Start_Date__c, Champion__r.Code__c
      FROM Tournament__c
      WITH USER_MODE
    ];

    Logger.info('retrieved tournaments', tournaments);

    List<TournamentDTO.Tournament> dtoList = new List<TournamentDTO.Tournament>();

    for (Tournament__c tournament : tournaments) {
      dtoList.add(new TournamentDTO.Tournament(tournament));
    }

    return dtoList;
  }

  private static List<TournamentDTO.Tournament> getTournament(
    String tournamentCode
  ) {
    List<Tournament__c> tournaments = [
      SELECT
        Id,
        Name,
        Code__c,
        Start_Date__c,
        Champion__r.Code__c,
        (
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
          FROM Tournament_Teams__r
        ),
        (
          SELECT
            Stage__c,
            Date__c,
            Home_Team__r.Code__c,
            Home_Team_Goals__c,
            Away_Team__r.Code__c,
            Away_Team_Goals__c,
            Winner_Team__r.Code__c,
            Draw__c
          FROM Matches__r
        )
      FROM Tournament__c
      WHERE Code__c = :tournamentCode
      WITH USER_MODE
      LIMIT 1
    ];

    if (tournaments.isEmpty()) {
      RestContext.response.statusCode = 404;

      Logger.info('Tournament with code' + tournamentCode + 'not found');

      return null;
    }

    Tournament__c tournament = tournaments[0];
    TournamentDTO.Tournament dto = new TournamentDTO.Tournament(tournament);

    for (Tournament_Team__c tournamentTeam : tournament.Tournament_Teams__r) {
      dto.teams.add(new TournamentDTO.Team(tournamentTeam));
    }

    for (Match__c match : tournament.Matches__r) {
      dto.matches.add(new TournamentDTO.Match(match));
    }

    return new List<TournamentDTO.Tournament>{ dto };
  }
}
