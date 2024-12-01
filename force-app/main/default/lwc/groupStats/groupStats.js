import { LightningElement, api } from "lwc";
import TEAM_FLAGS from "@salesforce/resourceUrl/TeamFlags";

const columns = [
  {
    label: "#",
    type: "teamFlagType",
    typeAttributes: {
      flagUrl: { fieldName: "flagUrl" },
      initialWidth: 10
    },
    cellAttributes: { alignment: "center" },
    initialWidth: 10
  },
  { label: "Team", fieldName: "teamName", type: "text" },
  { label: "MP", fieldName: "matchesPlayed", type: "number" },
  { label: "W", fieldName: "wins", type: "number" },
  { label: "L", fieldName: "losses", type: "number" },
  { label: "D", fieldName: "draws", type: "number" },
  { label: "GF", fieldName: "goalsFor", type: "number" },
  { label: "GA", fieldName: "goalsAgainst", type: "number" },
  { label: "GD", fieldName: "goalsDifference", type: "number" },
  { label: "Pts", fieldName: "points", type: "number" }
];

export default class GroupStats extends LightningElement {
  columns = columns;
  @api teamsStats;

  get data() {
    return this.teamsStats.map((item) => {
      return {
        ...item,
        flagUrl: this.flagUrl(item.teamFlagCode)
      };
    });
  }

  flagUrl(teamFlagCode) {
    return TEAM_FLAGS + "/flags/" + teamFlagCode + ".png";
  }
}
