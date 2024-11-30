import { LightningElement } from "lwc";
import getGroupStageOverview from "@salesforce/apex/GroupStageOverviewController.getGroupStageOverview";

export default class GroupStageOverview extends LightningElement {
  tournamentId = "a01d200000BneXcAAJ";
  overviewByGroup;
  error;

  connectedCallback() {
    this.fetchOverview();
  }

  fetchOverview() {
    getGroupStageOverview({ tournamentId: this.tournamentId })
      .then((result) => {
        this.overviewByGroup = Object.entries(result).map(
          ([group, overview]) => {
            return { group, overview };
          }
        );
        this.error = undefined;
      })
      .catch((error) => {
        this.error = error;
        this.overviewByGroup = undefined;
      });
  }

  get ready() {
    return this.overviewByGroup !== undefined;
  }

  get hasError() {
    return this.error !== undefined;
  }
}
