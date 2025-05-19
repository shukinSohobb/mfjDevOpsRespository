import { LightningElement, track, wire, api } from 'lwc';
import DriverMaster_OBJECT from '@salesforce/schema/DriverMaster__c';
import DriverMaster_DeliveryDestinationTeam_FIELD from '@salesforce/schema/DriverMaster__c.DeliveryDestinationTeam__c';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDrive from '@salesforce/apex/WorkScheduleController.getDrive';

export default class Work_Schedule extends LightningElement {
  @wire(getObjectInfo, { objectApiName: DriverMaster_OBJECT })
  driverMasterObjectInfo;
  @wire(getPicklistValues, {
    recordTypeId: '$driverMasterObjectInfo.data.defaultRecordTypeId',
    fieldApiName: DriverMaster_DeliveryDestinationTeam_FIELD
  })
  industryOptions;

  @api
  widthpx;
  @api
  heightpx;
  @api
  heightpx2;
  @api
  kyuukeiicon;
  @api
  rennzokuicon;
  @api
  jikannijyou;
  @api
  yuukyuucolor;
  @api
  teikyuucolor;


  @track
  tableaucss;
  @track
  thcss = 'text-align: center; ';
  @track
  thcss2;

  get _industryOptions() {
    return [{ label: '--なし--', value: '' }, ...this.industryOptions.data.values];
  }

  @track tabletr = [];
  @track tablebody = [];
  @track inputdate = new Date();

  inputDeliveryDestinationTeam = '';

  daymap = {0:'日',
    1:'月',
    2:'火',
    3:'水',
    4:'木',
    5:'金',
    6:'土'
  }

  connectedCallback() {
    this.resetDate(new Date());
    if (this.widthpx != null && this.widthpx != '' && this.widthpx != undefined) {
        this.tableaucss = 'table-layout: fixed;';
        this.thcss = this.thcss + 'width:' + this.widthpx + 'px;';
    }
    if (this.heightpx != null && this.heightpx != '' && this.heightpx != undefined) {
        this.thcss = this.thcss + 'height:' + this.heightpx + 'px;';
    }

    if (this.heightpx2 != null && this.heightpx2 != '' && this.heightpx2 != undefined) {
      this.thcss2 = 'height:' + this.heightpx2 + 'px;';
    }
  }

  resetDate(today) {
    let today2 = new Date();
    today2.setDate(today2.getDate() + 31);
    this.tabletr = [];
    this.tabletr.push({ label: '', value: null });
    for (let i = 0; i < 31; i++) {
      let dd = this.addDays(today, i);
      let day = dd.getDay();
      let cssstr = '';
      if (day == 6) {
        cssstr = 'saturday';
      } else if (day == 0) {
        cssstr = 'sunday';
      }
      this.tabletr.push({ label: dd.getMonth() + 1 + '/' + dd.getDate(), value: dd, cssstr: cssstr , dd:  this.daymap[day]});
    }
    let year = today.getFullYear();
    let month = String(today.getMonth() + 1).padStart(2, '0');
    let day = String(today.getDate()).padStart(2, '0');
    let startdatestr = year + '-' + month + '-' + day;
    year = today2.getFullYear();
    month = String(today2.getMonth() + 1).padStart(2, '0');
    day = String(today2.getDate()).padStart(2, '0');
    let endDatestr = year + '-' + month + '-' + day;
    getDrive({
      startDatestr: startdatestr,
      endDatestr: endDatestr,
      deliveryDestinationTeam: this.inputDeliveryDestinationTeam
    })
      .then((res) => {
        if (res.issuccess == false) {
          const evt = new ShowToastEvent({
            title: 'ERROR',
            message: res.errormessage,
            variant: 'error'
          });
          this.dispatchEvent(evt);
        } else {
          this.tablebody = res.drives;
          // alert(JSON.stringify(res.drives));
        }
      })
      .catch((error) => {
        const evt = new ShowToastEvent({
          title: 'ERROR',
          message: error.message,
          variant: 'error'
        });
        this.dispatchEvent(evt);
      });
  }

  addDays(date, days) {
    const newDate = new Date(date);
    newDate.setDate(date.getDate() + days);
    return newDate;
  }

  changedate(event) {
    this.inputdate = new Date(event.detail.value);
  }

  torecord(event) {
    window.open('/' + event.currentTarget.dataset.masterid);
  }

  search() {
    console.log(this.inputDeliveryDestinationTeam);
    this.resetDate(this.inputdate);
  }

  handleChange(event) {
    this.inputDeliveryDestinationTeam = event.detail.value;
  }
}