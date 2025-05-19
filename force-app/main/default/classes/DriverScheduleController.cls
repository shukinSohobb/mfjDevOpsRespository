public with sharing class DriverScheduleController {
    @AuraEnabled
    public static resBean getDrive(String startDatestr, String endDatestr, String deliveryDestinationTeam) {
        resBean resb = new resBean();
        try {
            Map<String, String> plickvalueMap = new Map<String, String>();
            for (Schema.PicklistEntry entry : DriverSchedule__c.WorkStatus__c.getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    plickvalueMap.put(entry.getValue(), entry.getLabel());
                }
            }

            MFJSetting__mdt mc = MFJSetting__mdt.getInstance('ConsecutiveWorkingDays');
            Integer consecutiveWorkingDays = Integer.valueOf(mc.Value__c);
            Date startDate = Date.valueOf(startDatestr);
            Date endDate = Date.valueOf(endDatestr);

            String soql = 'SELECT Id, Name FROM DriverMaster__c';
            if (String.isNotBlank(deliveryDestinationTeam)) {
                soql += ' WHERE DeliveryDestinationTeam__c includes (\'' + deliveryDestinationTeam + '\')';
            }
            List<DriverMaster__c> dmList = Database.query(soql);
            List<DriverSchedule__c> dsList = [
                SELECT Id, Date__c, Driver__c, Name, WorkStatus__c
                FROM DriverSchedule__c
                WHERE Date__c >= :startDate AND Date__c <= :endDate AND Driver__c = :dmList
            ];
            Map<Id, List<DriverSchedule__c>> dsMap = new Map<Id, List<DriverSchedule__c>>();
            for (DriverSchedule__c ds : dsList) {
                if (dsMap.containskey(ds.Driver__c) == false) {
                    dsMap.put(ds.Driver__c, new List<DriverSchedule__c>());
                }
                dsMap.get(ds.Driver__c).add(ds);
            }
            Map<Id, List<DispatchAssignDriver__c>> dadMap = new  Map<Id, List<DispatchAssignDriver__c>>();
            if (dsList.size() > 0) {
                List<DispatchAssignDriver__c> dadList = [SELECT Id, DispatchDetail__r.VehicleMaster__c, DriverSchedule__c,DispatchDetail__r.VehicleMaster_Name_F__c
                    FROM DispatchAssignDriver__c WHERE DriverSchedule__c = :dsList];
                for (DispatchAssignDriver__c ds :dadList) {
                    if (dadMap.containsKey(ds.DriverSchedule__c) == false) {
                        dadMap.put(ds.DriverSchedule__c, new List<DispatchAssignDriver__c>());
                    }
                    if (String.isNotBlank(ds.DispatchDetail__c) && String.isNotBlank(ds.DispatchDetail__r.VehicleMaster__c)) {
                        dadMap.get(ds.DriverSchedule__c).add(ds);
                    }
                }
            }
            

            for (DriverMaster__c dm : dmList) {
                driveBean db = new driveBean();
                db.driverMaster = dm;
                db.masterId = dm.Id;
                db.masterName = dm.Name;
                db.cssstr = '';
                Map<String, worksceduleBean> dmDateMap = new Map<String, worksceduleBean>();
                db.worksceduleMap = dmDateMap;
                if (dsMap.containskey(dm.Id)) {
                    Date d;
                    Integer i = 0;
                    for (DriverSchedule__c ds : dsMap.get(dm.Id)) {
                        String keystr = dm.Id + ds.Date__c.format();
                        if (dmDateMap.containsKey(keystr) == false) {
                            dmDateMap.put(keystr, new worksceduleBean());
                        }
                        worksceduleBean wcb = dmDateMap.get(keystr);
                        wcb.driverSchedule = ds;
                        if (dadMap.containsKey(ds.Id)) {
                            wcb.dadList = dadMap.get(ds.Id);
                        }
                        if (String.isNotBlank(ds.WorkStatus__c)) {
                            wcb.dispatchVehicleworkStatus = plickvalueMap.get(ds.WorkStatus__c);
                        }
                    }
                }
                resb.drives.add(db);
            }
            resb.issuccess = true;
            return resb;
        } catch (Exception e) {
            resb.issuccess = false;
            resb.errormessage = e.getMessage();
        }
        return resb;
    }

    @AuraEnabled
    public static resBean saveDs(String masterid, String datestr, String status) {
        resBean rs = new resBean();
        try {
            DriverSchedule__c ds = new DriverSchedule__c();
            ds.UniqueKey__c = masterid + datestr.remove('-');
            ds.WorkStatus__c = status;
            ds.Driver__c = masterid;
            ds.Date__c = Date.valueOf(datestr);
            upsert ds UniqueKey__c;
            rs.issuccess = true;
        } catch (Exception e) {
            rs.issuccess = false;
            rs.errormessage = e.getMessage();
        }
        return rs;
    }

    public static String getStringCheckBlank(String str) {
        return String.isBlank(str) ? '' : str;
    }

    public class resBean {
        @AuraEnabled
        public Boolean issuccess;
        @AuraEnabled
        public String errormessage;
        @AuraEnabled
        public List<driveBean> drives;

        resBean() {
            this.drives = new List<driveBean>();
        }
    }

    public class driveBean {
        @AuraEnabled
        public DriverMaster__c driverMaster;
        @AuraEnabled
        public String masterId;
        @AuraEnabled
        public String masterName;
        @AuraEnabled
        public String cssstr;
        @AuraEnabled
        public Map<String, worksceduleBean> worksceduleMap;
        driveBean() {
            this.worksceduleMap = new Map<String, worksceduleBean>();
        }
    }
    public class worksceduleBean {
        @AuraEnabled
        public DriverSchedule__c driverSchedule;
        @AuraEnabled
        public DispatchVehicle__c dispatchVehicle;
        @AuraEnabled
        public String dispatchVehiclemastername;
        @AuraEnabled
        public String dispatchVehicleworkStatus;
        @AuraEnabled
        public String destr;
        @AuraEnabled
        public List<DispatchAssignDriver__c> dadList;
        worksceduleBean() {
            this.dadList = new List<DispatchAssignDriver__c>();
            this.dispatchVehicleworkStatus = '';
            this.dispatchVehiclemastername = '';
        }
    }
}