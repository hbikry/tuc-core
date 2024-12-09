/**
 * @description       : Match trigger handler (beforeInsert, beforeUpdate)
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-09-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public without sharing class MatchTriggerHandler extends TriggerHandler {
  public override void beforeInsert() {
    Logger.info('Match__c before insert trigger started', Trigger.new);
    try {
      BeforeMatchTriggerHandler beforeHandler = new BeforeMatchTriggerHandler();
      beforeHandler.beforeInsert();
    } catch (Exception e) {
      Logger.error('Match__c before insert trigger error', e);
    } finally {
      Logger.saveLog();
    }
  }

  public override void beforeUpdate() {
    Logger.info('Match__c before update trigger started', Trigger.new);
    try {
      BeforeMatchTriggerHandler beforeHandler = new BeforeMatchTriggerHandler();
      beforeHandler.beforeUpdate();
    } catch (Exception e) {
      Logger.error('Match__c before update trigger error', e);
    } finally {
      Logger.saveLog();
    }
  }

  public override void afterInsert() {
    Logger.info('Match__c after insert trigger started', Trigger.new);
    try {
      AfterMatchTriggerHandler afterHandler = new AfterMatchTriggerHandler();
      afterHandler.afterInsert();
    } catch (Exception e) {
      Logger.error('Match__c after insert trigger error', e);
    } finally {
      Logger.saveLog();
    }
  }

  public override void afterUpdate() {
    Logger.info('Match__c after update trigger started', Trigger.new);
    try {
      AfterMatchTriggerHandler afterHandler = new AfterMatchTriggerHandler();
      afterHandler.afterUpdate();
    } catch (Exception e) {
      Logger.error('Match__c after update trigger error', e);
    } finally {
      Logger.saveLog();
    }
  }
}
