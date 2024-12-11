import { LightningElement, api, track } from "lwc";
import getGroupStageOverview from "@salesforce/apex/GroupStageOverviewController.getGroupStageOverview";

export default class GroupStageOverview extends LightningElement {
  @track _tournamentId = undefined;
  @track overviewByGroup;
  @track error;
  @api recordId;

  connectedCallback() {
    if (this.recordId != null) {
      this._tournamentId = this.recordId;
      this.fetchOverview();
    }
  }

  fetchOverview() {
    getGroupStageOverview({ tournamentId: this._tournamentId })
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

  @api
  get tournamentId() {
    return this._tournamentId;
  }

  set tournamentId(tournamentId) {
    this._tournamentId = tournamentId;

    if (this._tournamentId !== undefined) {
      this.fetchOverview();
    }
  }

  get ready() {
    return this.overviewByGroup !== undefined;
  }

  get hasError() {
    return this.error !== undefined;
  }
}
