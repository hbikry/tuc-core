trigger MatchTrigger on Match__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new MatchTriggerHandler().run();
}
