/**
 * @description       :
 * @author            : hbikry@salesforce.com
 * @group             :
 * @last modified on  : 12-06-2024
 * @last modified by  : hbikry@salesforce.com
 **/
public with sharing class TournamentGeneratorController {
  @InvocableMethod
  public static void generateTournament() {
    TournamentGeneratorBatch myBatch = new TournamentGeneratorBatch();
    Id batchId = Database.executeBatch(myBatch);
  }
}
