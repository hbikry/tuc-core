/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-06-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class DeleteTournamentDataController {
  @InvocableMethod
  public static void deleteAllTournamentData() {
    delete [SELECT Id FROM Tournament__c];
  }
}
