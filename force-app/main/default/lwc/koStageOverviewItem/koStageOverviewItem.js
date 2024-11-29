import { LightningElement, api } from "lwc";

export default class KoStageOverviewItem extends LightningElement {
  @api stage;
  @api matches;
}
