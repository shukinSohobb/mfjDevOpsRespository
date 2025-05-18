import { LightningElement, api, track } from 'lwc';

export default class CustomHomeButtonLwc extends LightningElement {
  _imageList;
  _urlList;
  _buttonwidthsize;
  _buttonheight;
  _innerstyle;

  @api
  set innerstyle(value) {
    this._innerstyle = value;
  }

  get innerstyle() {
    if (this._innerstyle == undefined || this._innerstyle == null || this._innerstyle == '') {
      return '';
    }
    return this._innerstyle;
  }

  @api
  set buttonwidthsize(value) {
    this._buttonwidthsize = value;
  }

  get buttonwidthsize() {
    if (this._buttonwidthsize == undefined || this._buttonwidthsize == null || this._buttonwidthsize == '') {
      return 2;
    }
    return this._buttonwidthsize;
  }

  @api
  set buttonheight(value) {
    this.buttonCss = 'height:' + value + 'px;';
    this._buttonheight = value;
  }
  get buttonheight() {
    return this._buttonheight;
  }

  @api
  set buttonList(value) {
    this._buttonList = value;
  }
  get buttonList() {
    return this._buttonList;
  }

  @api
  set imageList(value) {
    this._imageList = value;
  }

  get imageList() {
    return this._imageList;
  }

  @api
  set urlList(value) {
    this._urlList = value;
  }

  get urlList() {
    return this._urlList;
  }

  @track
  buttonList = [];

  @track
  buttonCss = '';

  connectedCallback() {
    var hostname = window.location.hostname;
    if (this.imageList != null && this.imageList != undefined && this.urlList != null && this.urlList != undefined) {
      let imagelist2 = this.imageList.split(';');
      let urlList = this.urlList.split(';');
      if (imagelist2.length == urlList.length) {
        for (let i = 0; i < imagelist2.length; i++) {
          let urlstr = urlList[i];
          let imgstr = imagelist2[i];
          urlstr = urlstr.startsWith('https://') ? urlstr : 'https://' + hostname + urlstr;
          imgstr = imgstr.startsWith('https://') ? imgstr : 'https://' + hostname + imgstr;
          this.buttonList.push({ image: imgstr, src: urlstr, class: 'slds-size_1-of-' + this.buttonwidthsize });
        }
      }
    }
  }

  clickbutton(event) {
    window.open(event.currentTarget.dataset.url, '_blank');
  }
}