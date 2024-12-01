import { LightningElement, track } from "lwc";
import getGroupStageOverview from "@salesforce/apex/GroupStageOverviewController.getGroupStageOverview";

export default class GroupStageOverview extends LightningElement {
  tournamentId = undefined;
  @track overviewByGroup;
  @track error;

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

  handleTournamentChange(event) {
    const tournamentId = event.detail;

    if (tournamentId !== null) {
      this.tournamentId = tournamentId;
      this.fetchOverview();
    }
  }
}
