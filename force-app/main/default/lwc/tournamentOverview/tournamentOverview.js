import { LightningElement, track } from "lwc";

export default class TournamentOverview extends LightningElement {
  @track tournamentId = undefined;

  handleTournamentChange(event) {
    const tournamentId = event.detail;

    if (tournamentId !== null) {
      this.tournamentId = tournamentId;
    }
  }
}
