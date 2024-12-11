import { LightningElement, api, track } from "lwc";
import getMatchesOverview from "@salesforce/apex/KnockoutStageOverviewController.getMatchesOverview";

export default class KoStageOverview extends LightningElement {
  @track _tournamentId = undefined;
  @track matchesByStage;
  @track error;
  @api recordId;

  connectedCallback() {
    if (this.recordId != null) {
      this._tournamentId = this.recordId;
      this.fetchMatches();
    }
  }

  fetchMatches() {
    getMatchesOverview({ tournamentId: this._tournamentId })
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

  @api
  get tournamentId() {
    return this._tournamentId;
  }

  set tournamentId(tournamentId) {
    this._tournamentId = tournamentId;

    if (this._tournamentId !== undefined) {
      this.fetchMatches();
    }
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
