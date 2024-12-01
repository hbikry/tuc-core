import { LightningElement, api } from "lwc";

export default class KoMatchResult extends LightningElement {
  @api match;

  get formattedDate() {
    if (this.match && this.match.matchDate) {
      const date = new Date(this.match.matchDate);
      const options = { year: "numeric", month: "short", day: "numeric" };

      return new Intl.DateTimeFormat("en-US", options).format(date);
    }

    return "";
  }

  get isHomeTeamWinner() {
    return this.match.homeTeamId === this.match.winnerTeamId;
  }

  get isAwayTeamWinner() {
    return this.match.awayTeamId === this.match.winnerTeamId;
  }
}
