import { LightningElement, api } from "lwc";

export default class TeamMatches extends LightningElement {
  @api matches;

  get matchesByStage() {
    return Object.entries(this.matches).map(([stage, matches]) => {
      return { stage, matches };
    });
  }
}
