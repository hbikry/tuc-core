import { LightningElement } from "lwc";

export default class TournamentSelector extends LightningElement {
  handleChange(event) {
    const selectedEvent = new CustomEvent("tournamentchange", {
      detail: event.detail.recordId
    });

    this.dispatchEvent(selectedEvent);
  }
}
