import { LightningElement, api, track } from "lwc";
import getTeamMatchesOverview from "@salesforce/apex/TeamOverviewController.getTeamMatchesOverview";

export default class TeamOverview extends LightningElement {
  @api recordId;
  @track teamId = undefined;
  @track overviewByTournament = undefined;
  @track error;

  connectedCallback() {
    if (this.recordId != null) {
      this.teamId = this.recordId;
      this.fetchOverview();
    }
  }

  fetchOverview() {
    getTeamMatchesOverview({ teamId: this.teamId })
      .then((result) => {
        this.overviewByTournament = Object.entries(result).map(
          ([tournament, overviewByTournament]) => {
            return { tournament, overviewByTournament };
          }
        );
        this.error = undefined;
        console.log("controller result: " + JSON.stringify(result));
        console.log(
          "transformed: " + JSON.stringify(this.overviewByTournament)
        );
      })
      .catch((error) => {
        this.error = error;
        this.overviewByTournament = undefined;
      });
  }

  get ready() {
    return this.overviewByTournament !== undefined;
  }

  get hasError() {
    return this.error !== undefined;
  }
}
