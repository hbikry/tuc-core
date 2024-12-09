/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-09-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class TournamentUtility {
  public static Map<Id, Tournament__c> getTournaments(Set<Id> ids) {
    return new Map<Id, Tournament__c>(
      [
        SELECT Id, Name, Code__c, Stage__c, Champion__c
        FROM Tournament__c
        WHERE Id IN :ids
        WITH USER_MODE
      ]
    );
  }
}
