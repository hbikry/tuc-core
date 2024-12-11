/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-11-2024
 * @last modified by  : hbikry@salesforce.com
 **/
@isTest
private class ListUtilsTest {
  @isTest
  static void testShuffle() {
    // Create a list of integers
    List<Object> originalList = new List<Object>{ 1, 2, 3, 4, 5 };
    List<Object> listToShuffle = new List<Object>(originalList);
    // Shuffle the list
    ListUtils.shuffle(listToShuffle);
    // Verify that the shuffled list has the same size as the original list
    System.assertEquals(
      originalList.size(),
      listToShuffle.size(),
      'The shuffled list should have the same size as the original list'
    );
    // Verify that the shuffled list contains the same elements as the original list
    for (Object item : originalList) {
      System.assert(
        listToShuffle.contains(item),
        'The shuffled list should contain the same elements as the original list'
      );
    }
    // Verify that the shuffled list is not in the same order as the original list
    Boolean isDifferentOrder = false;
    for (Integer i = 0; i < originalList.size(); i++) {
      if (originalList[i] != listToShuffle[i]) {
        isDifferentOrder = true;
        break;
      }
    }
    System.assert(
      isDifferentOrder,
      'The shuffled list should be in a different order than the original list'
    );
  }

  @isTest
  static void testPickRandomObject() {
    // Create a list of integers
    List<Object> objects = new List<Object>{ 1, 2, 3, 4, 5 };
    // Pick a random object from the list
    Object randomObject = ListUtils.pickRandomObject(objects);
    // Verify that the random object is not null
    System.assertNotEquals(
      null,
      randomObject,
      'The random object should not be null'
    );
    // Verify that the random object is one of the elements in the list
    System.assert(
      objects.contains(randomObject),
      'The random object should be one of the elements in the list'
    );
    // Test with an empty list
    List<Object> emptyList = new List<Object>();
    Object randomObjectFromEmptyList = ListUtils.pickRandomObject(emptyList);
    // Verify that the random object from an empty list is null
    System.assertEquals(
      null,
      randomObjectFromEmptyList,
      'The random object from an empty list should be null'
    );
  }
}
