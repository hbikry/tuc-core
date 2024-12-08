/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-05-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class MatchStageComparator implements Comparator<Match__c> {
  public Integer compare(Match__c match1, Match__c match2) {
    return new StageComparator().compare(match1.Stage__c, match2.Stage__c);
  }
}
