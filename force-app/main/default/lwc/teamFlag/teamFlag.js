import { LightningElement, api } from "lwc";
import TEAM_FLAGS from "@salesforce/resourceUrl/TeamFlags";

export default class TeamFlag extends LightningElement {
  @api flagCode;

  get flagUrl() {
    return TEAM_FLAGS + "/flags/" + this.flagCode + ".png";
  }
}
