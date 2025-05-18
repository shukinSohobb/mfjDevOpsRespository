import { LightningElement, api, track } from 'lwc';
import saveDs from '@salesforce/apex/DriverScheduleController.saveDs';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class Work_Schedule_td extends LightningElement {
  _customdata;
  _customdate;
  _dmasterid;
  _workstatusoptions;
  datestr;
  _teikyuucolor;
  _yuukyuucolor;
  key;

  basecss = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ';
  valuemap;

  @track loading = false;
  @track openselect = false;
  @track openselectcss = this.basecss;
  @track bkcolor = 'border-width: 0px;';
  @api
  get customdata() {
    return this._customdata;
  }

  set customdata(value) {
    this._customdata = value;
    this.resetvalue();
  }

  @api
  set nowkey(value) {
    if (value != this.key && this.openselect == true) {
      this.openselect = !this.openselect;
      this.openselectcss = this.openselect ? this.basecss + ' slds-is-open' : this.basecss;
    }
  }

  get nowkey() {
    return null;
  }

  @api
  get workstatusoptions() {
    return this._workstatusoptions;
  }

  set workstatusoptions(value) {
    if (value != null && value != undefined && this._workstatusoptions == undefined) {
      this._workstatusoptions = [];
      this.valuemap = {};
      value.forEach((element) => {
        this.valuemap[element.value] = element.label;
        this._workstatusoptions.push({ ...element, stylestr: element.value == 'WorkDay' ? 'color:#ffffff00;' : '' });
        // element['stylestr'] = element.value == 'WorkDay' ? 'color:#ffffff00;' : '';
      });
      this.resetvalue();
    }
  }

  @api
  get customdate() {
    return this._customdate;
  }

  set customdate(value) {
    this._customdate = value;
    this.resetvalue();
  }

  @api
  get masterid() {
    return this._dmasterid;
  }

  set masterid(value) {
    this._dmasterid = value;
    this.resetvalue();
  }

  @api
  get yuukyuucolor() {
    if (this._yuukyuucolor == null || this._yuukyuucolor == '' || this._yuukyuucolor == undefined) {
      return '#E52D34;';
    }
    return this._yuukyuucolor;
  }

  set yuukyuucolor(value) {
    if (value != null && value != '' && value != undefined) {
      this._yuukyuucolor = value;
      this.resetvalue();
    }
  }

  @api
  get teikyuucolor() {
    if (this._teikyuucolor == null || this._teikyuucolor == '' || this._teikyuucolor == undefined) {
      return '#CA7CCE;';
    }
    return this._teikyuucolor;
  }

  set teikyuucolor(value) {
    if (value != null && value != '' && value != undefined) {
      this._teikyuucolor = value;
      this.resetvalue();
    }
  }

  @track
  showvalue;
  @track
  showvalueList;
  @track
  overcss;

  resetvalue() {
    if (this._dmasterid != null && this._customdate != null && this._customdata != null) {
      let year = this._customdate.getFullYear();
      let month = String(this._customdate.getMonth() + 1).padStart(2, '0');
      let day = String(this._customdate.getDate()).padStart(2, '0');
      this.key = this._dmasterid + year + '/' + month + '/' + day;
      this.datestr = year + '-' + month + '-' + day;
      if (this._customdata[this.key] != undefined) {
        let value = this._customdata[this.key];
        let driverScheduleStatus = value.driverSchedule == undefined ? '' : value.driverSchedule.WorkStatus__c;
        let driverScheduleDispatchedCnt = value.driverSchedule == undefined ? '' : value.driverSchedule.Dispatched_Cnt__c;
        this.showvalue = '';
        if (this.valuemap != undefined && driverScheduleStatus != 'WorkDay' && !(driverScheduleDispatchedCnt > 0)) {
          this.showvalue = this.valuemap[driverScheduleStatus];
        }
        if (driverScheduleStatus == 'DayOff') {
          this.bkcolor = 'border-width: 0px;background-color:' + this.yuukyuucolor;
        } else if (driverScheduleStatus == 'WeeklyOff') {
          this.bkcolor = 'border-width: 0px;background-color:' + this.teikyuucolor;
        }
        this.showvalueList = '';
        value.dadList.forEach((element) => {
          if (this.showvalueList != '') {
            this.showvalueList += '<br/>';
          }
          this.showvalueList += element.DispatchDetail__r.VehicleMaster_Name_F__c;
        });
      }
    }
  }

  clickbotton(event) {
    this.openselect = !this.openselect;
    this.openselectcss = this.openselect ? this.basecss + ' slds-is-open' : this.basecss;
    this.dispatchEvent(
      new CustomEvent('haveopen', {
        detail: {
          key: this.key
        }
      })
    );
  }

  handleChange(event) {
    this.loading = true;
    let valuestr = event.currentTarget.dataset.value;
    saveDs({ masterid: this._dmasterid, datestr: this.datestr, status: valuestr })
      .then((res) => {
        if (res.issuccess == false) {
          const evt = new ShowToastEvent({
            title: 'ERROR',
            message: res.errormessage,
            variant: 'error'
          });
          this.dispatchEvent(evt);
        } else {
          this.showvalue = '';
          if (this.valuemap != undefined && valuestr != 'WorkDay' && valuestr != 'Dispatched') {
            this.showvalue = this.valuemap[valuestr];
          }
          this.bkcolor = 'border-width: 0px;';
          if (valuestr == 'DayOff') {
            this.bkcolor = 'border-width: 0px;background-color:' + this.yuukyuucolor;
          } else if (valuestr == 'WeeklyOff') {
            this.bkcolor = 'border-width: 0px;background-color:' + this.teikyuucolor;
          }
          // alert(JSON.stringify(res.drives));
        }
        this.loading = false;
      })
      .catch((error) => {
        const evt = new ShowToastEvent({
          title: 'ERROR',
          message: error.message,
          variant: 'error'
        });
        this.dispatchEvent(evt);
        this.loading = false;
      });
    this.dispatchEvent(
      new CustomEvent('haveopen', {
        detail: {
          key: this.key
        }
      })
    );
  }
}