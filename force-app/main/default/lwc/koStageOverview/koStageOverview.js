import { LightningElement } from "lwc";
import getKnockoutStageOverview from "@salesforce/apex/TournamentOverviewController.getKnockoutStageOverview";

export default class KoStageOverview extends LightningElement {
  tournamentId = "a01d200000BneXcAAJ";
  matchesByStage;
  error;

  connectedCallback() {
    this.fetchMatches();
  }

  fetchMatches() {
    getKnockoutStageOverview({ tournamentId: this.tournamentId })
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
