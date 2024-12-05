/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-05-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class ListUtils {
  public static void shuffle(List<Object> listToShuffle) {
    Integer n = listToShuffle.size();
    for (Integer i = n - 1; i > 0; i--) {
      Integer j = Math.floor(Math.random() * (i + 1)).intValue();
      // Swap elements at indices i and j
      Object temp = listToShuffle[i];
      listToShuffle[i] = listToShuffle[j];
      listToShuffle[j] = temp;
    }
  }

  public static Object pickRandomObject(List<Object> objects) {
    if (objects.isEmpty()) {
      return null;
    }

    // Generate a random index (0 or 1)
    Integer randomIndex = Math.floor(Math.random() * objects.size()).intValue();

    // Return the record at the random index
    return objects[randomIndex];
  }
}
