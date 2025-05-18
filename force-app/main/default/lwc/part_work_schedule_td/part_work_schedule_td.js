import { LightningElement, api, track } from 'lwc';

export default class Work_Schedule_td extends LightningElement {
  _customdata;
  _customdate;
  _dmasterid;
  _kyuukeiicon;
  _rennzokuicon;
  _jikannijyou;
  _teikyuucolor;
  _yuukyuucolor;

  @api
  set kyuukeiicon(value) {
    var hostname = window.location.hostname;
    this._kyuukeiicon = value.startsWith('https://') ? value : 'https://' + hostname + value;
  }

  get kyuukeiicon() {
    return this._kyuukeiicon;
  }

  @api
  set rennzokuicon(value) {
    var hostname = window.location.hostname;
    this._rennzokuicon = value.startsWith('https://') ? value : 'https://' + hostname + value;
  }

  get rennzokuicon() {
    return this._rennzokuicon;
  }

  @api
  set jikannijyou(value) {
    var hostname = window.location.hostname;
    this._jikannijyou = value.startsWith('https://') ? value : 'https://' + hostname + value;
  }

  get jikannijyou() {
    return this._jikannijyou;
  }

  @api
  get customdata() {
    return this._customdata;
  }

  set customdata(value) {
    this._customdata = value;
    this.resetvalue();
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
    this._yuukyuucolor = value;
    if (value != null && value != '' && value != undefined) {
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
    this._teikyuucolor = value;
    if (value != null && value != '' && value != undefined) {
      this.resetvalue();
    }
  }

  @track
  showvalue = '';
  @track
  overcss;
  @track
  overstyle;

  @track
  over15 = false;
  @track
  over7 = false;
  @track
  resterror = false;
  @track
  overCssStr15xx;

  resetvalue() {
    if (this._dmasterid != null && this._customdate != null && this._customdata != null) {
      let year = this._customdate.getFullYear();
      let month = String(this._customdate.getMonth() + 1).padStart(2, '0');
      let day = String(this._customdate.getDate()).padStart(2, '0');
      let key = this._dmasterid + year + '/' + month + '/' + day;
      this.overstyle = 'margin-top:15px;';
      if (this._customdata[key] != undefined) {
        let value = this._customdata[key];
        let driverScheduleStatus = value.driverSchedule == undefined ? '' : value.dispatchVehicleworkStatus;
        let dispatchVehicleName = value.dispatchVehicle == undefined ? '' : value.dispatchVehiclemastername;
        this.showvalue = '';
        if (driverScheduleStatus != '配車済み' && driverScheduleStatus != '勤務') {
          this.showvalue = "<p style='";
          if (driverScheduleStatus == '休み（有給）') {
            this.showvalue +=
              'opacity: 0.9;border-radius: 0.25rem;color:#ffffff; text-align: center;background-color:' + this.yuukyuucolor;
          } else if (driverScheduleStatus == '定休') {
            this.showvalue +=
              'opacity: 0.9;border-radius: 0.25rem;color:#ffffff; text-align: center;background-color:' + this.teikyuucolor;
          }
          this.showvalue += "'>" + driverScheduleStatus + '</p>';
        }
        // this.showvalue += dispatchVehicleName;
        console.log(value.dispatchAssignDriverList);
        if (value.dispatchAssignDriverList != undefined && value.dispatchAssignDriverList.length > 0) {
          for (let i = 0; i < value.dispatchAssignDriverList.length; i++) {
            let number = value.dispatchAssignDriverList[i].DispatchDetail__r.VehiclelNumber_F__c;
            if (number != null && number != '' && number != undefined) {
              if (this.showvalue != '' && this.showvalue != null && this.showvalue != undefined) {
                this.showvalue += '<br/>';
              }
              this.showvalue += number;
            }
            console.log(number);
          }
        }
        this.overcss = value.overCssStr;
        // if (driverScheduleStatus == '休み（有給）') {
        //     this.overstyle += 'opacity: 0.9;border-radius: 0.25rem;color:#ffffff; text-align: center;' + 'background-color:' + this.yuukyuucolor;
        // }
        // else if (driverScheduleStatus == '定休') {
        //     this.overstyle += 'opacity: 0.9;border-radius: 0.25rem;color:#ffffff; text-align: center;' + 'background-color:' + this.teikyuucolor ;
        // }
        if (value.overCssStr != null && value.overCssStr != '' && value.overCssStr != undefined) {
          this.over7 = true;
        }
        if (value.overCssStr15 != null && value.overCssStr15 != '' && value.overCssStr15 != undefined) {
          this.over15 = true;
          this.overCssStr15xx = value.overCssStr15;
        }
        if (value.overCssStr2 != null && value.overCssStr2 != '' && value.overCssStr2 != undefined) {
          this.resterror = true;
        }
      }
    }
  }
}