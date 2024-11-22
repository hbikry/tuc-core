trigger TournamentTeamTrigger on Tournament_Team__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new TournamentTeamTriggerHandler().run();
}
