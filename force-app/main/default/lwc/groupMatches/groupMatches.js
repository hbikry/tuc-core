import { LightningElement, api } from "lwc";

export default class GroupMatches extends LightningElement {
  @api matches;

  get matchesByStage() {
    return this.matches.reduce((acc, match) => {
      const stage = match.stage;
      let stageGroup = acc.find((group) => group.stage === stage);
      if (!stageGroup) {
        stageGroup = { stage: stage, matches: [] };
        acc.push(stageGroup);
      }

      stageGroup.matches.push(match);

      return acc;
    }, []);
  }
}
