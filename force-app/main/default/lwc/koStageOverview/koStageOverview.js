import { LightningElement, api, track } from "lwc";
import getMatchesOverview from "@salesforce/apex/KnockoutStageOverviewController.getMatchesOverview";
import TEAM_FLAGS from "@salesforce/resourceUrl/TeamFlags";

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
        this.matchesByStage.forEach((item) => {
          item.matches.forEach((match) => {
            match.homeTeamFlagUrl = this.getFlagUrl(match.homeTeamFlagCode);
            match.awayTeamFlagUrl = this.getFlagUrl(match.awayTeamFlagCode);
            match.isHomeTeamWinner = match.homeTeamId === match.winnerTeamId;
            match.isAwayTeamWinner = match.awayTeamId === match.winnerTeamId;
            match.homeTeamClass = `game game-top${match.isHomeTeamWinner ? " winner" : ""}`;
            match.awayTeamClass = `game game-bottom${match.isAwayTeamWinner ? " winner" : ""}`;
          });
        });
        console.log(JSON.stringify(this.matchesByStage));
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

  getFlagUrl(flagCode) {
    return TEAM_FLAGS + "/flags/" + flagCode + ".png";
  }
}
