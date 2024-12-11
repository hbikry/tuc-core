/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-11-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@isTest
private class TournamentStageUtilityTest {
  @isTest
  static void testTournamentInGroupStage() {
    // Create test data
    Tournament__c groupStageTournament = new Tournament__c(
      Name = 'Test Tournament Group',
      Code__c = 'TESTGRP',
      Start_Date__c = Date.today(),
      Stage__c = TournamentStageUtility.GROUP_STAGE
    );
    Tournament__c knockoutStageTournament = new Tournament__c(
      Name = 'Test Tournament KO',
      Code__c = 'TESTKO',
      Start_Date__c = Date.today(),
      Stage__c = TournamentStageUtility.KNOCKOUT_STAGE
    );
    // Insert the test data
    insert new List<Tournament__c>{
      groupStageTournament,
      knockoutStageTournament
    };
    // Test cases
    // Verify that the tournament is in the group stage
    System.assert(
      TournamentStageUtility.tournamentInGroupStage(groupStageTournament),
      'The tournament should be in the group stage'
    );
    System.assert(
      !TournamentStageUtility.tournamentInGroupStage(knockoutStageTournament),
      'The tournament should not be in the group stage'
    );
  }
  @isTest
  static void testTournamentInKnockoutStage() {
    // Create test data
    Tournament__c groupStageTournament = new Tournament__c(
      Name = 'Test Tournament Group',
      Code__c = 'TESTGRP',
      Start_Date__c = Date.today(),
      Stage__c = TournamentStageUtility.GROUP_STAGE
    );
    Tournament__c knockoutStageTournament = new Tournament__c(
      Name = 'Test Tournament KO',
      Code__c = 'TESTKO',
      Start_Date__c = Date.today(),
      Stage__c = TournamentStageUtility.KNOCKOUT_STAGE
    );
    // Insert the test data
    insert new List<Tournament__c>{
      groupStageTournament,
      knockoutStageTournament
    };
    // Test cases
    // Verify that the tournament is in the knockout stage
    System.assert(
      TournamentStageUtility.tournamentInKnockoutStage(knockoutStageTournament),
      'The tournament should be in the knockout stage'
    );
    System.assert(
      !TournamentStageUtility.tournamentInKnockoutStage(groupStageTournament),
      'The tournament should not be in the knockout stage'
    );
  }
}
