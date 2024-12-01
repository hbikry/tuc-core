import { LightningElement, api } from "lwc";

export default class ErrorAlert extends LightningElement {
  @api errorMessage;
}
