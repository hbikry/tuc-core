import { LightningElement, track } from "lwc";
import getMatchesOverview from "@salesforce/apex/KnockoutStageOverviewController.getMatchesOverview";

export default class KoStageOverview extends LightningElement {
  tournamentId = undefined;
  @track matchesByStage;
  @track error;

  fetchMatches() {
    getMatchesOverview({ tournamentId: this.tournamentId })
      .then((result) => {
        this.matchesByStage = Object.entries(result).map(([stage, matches]) => {
          return { stage, matches };
        });
        this.error = undefined;
      })
      .catch((error) => {
        this.error = error;
        this.matchesByStage = undefined;
      });
  }

  get ready() {
    return this.matchesByStage !== undefined;
  }

  get hasError() {
    return this.error !== undefined;
  }

  handleTournamentChange(event) {
    const tournamentId = event.detail;

    if (tournamentId !== null) {
      this.tournamentId = tournamentId;
      this.fetchMatches();
    }
  }

  scrollLeft() {
    const container = this.template.querySelector(".scroll-container");
    const stageWidth =
      this.template.querySelector(".stage-container").offsetWidth;
    container.scrollBy({ left: -stageWidth, behavior: "smooth" });
  }

  scrollRight() {
    const container = this.template.querySelector(".scroll-container");
    const stageWidth =
      this.template.querySelector(".stage-container").offsetWidth;
    container.scrollBy({ left: stageWidth, behavior: "smooth" });
  }
}
