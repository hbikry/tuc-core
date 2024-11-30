import { LightningElement, api } from "lwc";
import teamFlag from "./teamFlag.html";

export default class CustomDataTypes extends LightningElement {
  @api
  getDataTypes() {
    return {
      teamFlagType: {
        template: teamFlag,
        standardCellLayout: true,
        typeAttributes: ["flagUrl"]
      }
      // Other Custom Types
    };
  }
}
