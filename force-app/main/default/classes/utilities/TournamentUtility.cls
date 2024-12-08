/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-07-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class TournamentUtility {
  public static List<Tournament__c> getTournaments(Set<Id> ids) {
    return [
      SELECT Id, Name, Code__c, Stage__c, Champion__c
      FROM Tournament__c
      WHERE Id IN :ids
      WITH USER_MODE
    ];
  }
}
