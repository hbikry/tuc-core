import { LightningElement, api } from "lwc";
import TEAM_FLAGS from "@salesforce/resourceUrl/TeamFlags";

export default class KoMatchTeamResult extends LightningElement {
  @api teamName;
  @api teamScore;
  @api isWinner;

  get flagUrl() {
    //return TEAM_FLAGS + '/flags/' + this.teamCode + '.png';

    return TEAM_FLAGS + "/flags/MAR.png";
  }
}
