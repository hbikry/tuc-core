import { LightningElement, api } from "lwc";
import TEAM_FLAGS from "@salesforce/resourceUrl/TeamFlags";

export default class KoMatchTeamResult extends LightningElement {
  @api teamName;
  @api teamScore;
  @api teamCode;
  @api teamFlagCode;
  @api isWinner;

  get flagUrl() {
    return TEAM_FLAGS + "/flags/" + this.teamFlagCode + ".png";
  }

  get textClass() {
    return this.isWinner ? "slds-text-title_bold" : "slds-text-title_regular";
  }
}
