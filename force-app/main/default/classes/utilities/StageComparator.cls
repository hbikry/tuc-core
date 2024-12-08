/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-05-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class StageComparator implements Comparator<String> {
  public Integer compare(String stage1, String stage2) {
    List<String> stages = StageUtility.ORDERED_STAGES;

    if (!stages.contains(stage1)) {
      throw new IllegalArgumentException('Invalid group1 name');
    }

    if (!stages.contains(stage2)) {
      throw new IllegalArgumentException('Invalid group2 name');
    }

    Integer stage1Index = stages.indexOf(stage1);
    Integer stage2Index = stages.indexOf(stage2);

    if (stage1Index < stage2Index) {
      return -1;
    } else if (stage1Index > stage2Index) {
      return 1;
    } else {
      return 0;
    }
  }
}
