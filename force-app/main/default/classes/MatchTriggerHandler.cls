public without sharing class MatchTriggerHandler extends TriggerHandler {
  public override void beforeInsert() {
    validate();
  }

  public override void beforeUpdate() {
    validate();
  }

  private static void validate() {
  }
}
