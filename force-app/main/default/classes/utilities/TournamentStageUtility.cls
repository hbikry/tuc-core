/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-08-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class TournamentStageUtility {
  // NOTE: these values are part of the picklist field Stage__c of the Tournament__c object
  // so they must be kept in sync with the picklist values
  public final static String GROUP_STAGE = 'Group Stage';
  public final static String KNOCKOUT_STAGE = 'Knockout Stage';

  public static Boolean tournamentInGroupStage(Tournament__c tournament) {
    return tournament.Stage__c == GROUP_STAGE;
  }

  public static Boolean tournamentInKnockoutStage(Tournament__c tournament) {
    return tournament.Stage__c == KNOCKOUT_STAGE;
  }
}
