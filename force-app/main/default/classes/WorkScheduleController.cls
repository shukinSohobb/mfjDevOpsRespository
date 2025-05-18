public with sharing class WorkScheduleController {
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
            Date startDate = Date.valueOf(startDatestr).adddays(-7);
            Date endDate = Date.valueOf(endDatestr);

            String soql = 'SELECT Id, Name FROM DriverMaster__c';
            if (String.isNotBlank(deliveryDestinationTeam)) {
                soql += ' WHERE DeliveryDestinationTeam__c includes (\'' + deliveryDestinationTeam + '\')';
            }
            List<DriverMaster__c> dmList = Database.query(soql);

            List<DispatchAssignDriver__c> deaList = [
                SELECT
                    Id,
                    Name,
                    DriverSchedule__c,
                    DriverSchedule__r.Driver__c,
                    DriverSchedule__r.IsOvertime15Hours__c,
                    DriverSchedule__r.TotalTime_F__c,
                    DriverSchedule__r.AttendanceDateTime_F__c,
                    DriverSchedule__r.DepartureDateTime_F__c,
                    DriverSchedule__r.Date__c,
                    DriverSchedule__r.AttendanceTime__c,
                    DriverSchedule__r.DepartureTime__c,
                    DispatchVehicle__c,
                    DispatchDetail__r.Id,
                    DispatchVehicle__r.Date__c,
                    DispatchVehicle__r.VehicleMaster__r.Name,
                    DispatchVehicle__r.Subcontractor__c,
                    DispatchVehicle__r.Subcontractor__r.Name,
                    DispatchVehicle__r.CharteredVehicleNumber__c,
                    CourseName_F__c,
                    DispatchDetail__r.VehiclelNumber_F__c,
                    DispatchDetail__r.VehicleMaster_Name_F__c
                FROM DispatchAssignDriver__c
                WHERE
                    DriverSchedule__r.Driver__c = :dmList
                    OR (DispatchVehicle__r.Subcontractor__c != NULL
                    AND DriverSchedule__r.Driver__c = NULL)
                // AND DispatchVehicle__r.Date__c >= :startDate
                // AND DispatchVehicle__r.Date__c <= :endDate
                ORDER BY DriverSchedule__r.Driver__c, DispatchVehicle__r.Subcontractor__c, DriverSchedule__r.Date__c ASC
            ];

            List<DriverSchedule__c> dsList = [
                SELECT Id, Date__c, Driver__c, Name, WorkStatus__c
                FROM DriverSchedule__c
                WHERE Date__c >= :startDate AND Date__c <= :endDate AND Driver__c = :dmList
            ];
            System.debug(dsList.size());
            Map<Id, List<DispatchAssignDriver__c>> deaMap = new Map<Id, List<DispatchAssignDriver__c>>();
            for (DispatchAssignDriver__c dea : deaList) {
                if (deaMap.containskey(dea.DriverSchedule__r.Id) == false) {
                    deaMap.put(dea.DriverSchedule__r.Id, new List<DispatchAssignDriver__c>());
                }
                deaMap.get(dea.DriverSchedule__r.Id).add(dea);
            }

            // ドライバーもしくは下請け業者をキーとした、配車車両のMapを作成

            Map<String, List<DispatchAssignDriver__c>> driverDeaMap = new Map<String, List<DispatchAssignDriver__c>>();
            Map<String, List<DispatchAssignDriver__c>> subcontractorDeaMap = new Map<String, List<DispatchAssignDriver__c>>();

            for (DispatchAssignDriver__c dea : deaList) {
                /*
                    配車アサインをループし、ドライバーもしくは下請け業者をキーにした配車アサインのリストを作成していく。
                    ドライバーをキーとする場合はdriverDeaMapに、下請け業者をキーとする場合はsubcontractorDeaMapに追加。
                    ※ドライバーは社内、下請け業者は社外による配送になるため、この二つの項目はどちらか片方のみ入力された状態になります。

                    ループ中：
                        driverDeaMapもしくはsubcontractorDeaMapに存在しないドライバー・下請け業者が入ってきた場合、新しい行を生成。
                        既に追加されていた場合、中のリストにレコードを追加する。
                */

                if (String.isNotBlank(dea.DriverSchedule__c)) {
                    if (driverDeaMap.containskey(dea.DriverSchedule__r.Driver__c) == false) {
                        driverDeaMap.put(dea.DriverSchedule__r.Driver__c, new List<DispatchAssignDriver__c>());
                    }
                    driverDeaMap.get(dea.DriverSchedule__r.Driver__c).add(dea);
                } else if (String.isBlank(deliveryDestinationTeam)) {
                    String key =
                        getStringCheckBlank(dea.DispatchVehicle__r.Subcontractor__c) +
                        getStringCheckBlank(dea.DispatchVehicle__r.CharteredVehicleNumber__c);
                    if (subcontractorDeaMap.containskey(key) == false) {
                        subcontractorDeaMap.put(key, new List<DispatchAssignDriver__c>());
                    }
                    subcontractorDeaMap.get(key).add(dea);
                }
            }
            Map<Id, List<DriverSchedule__c>> dsMap = new Map<Id, List<DriverSchedule__c>>();
            for (DriverSchedule__c ds : dsList) {
                if (dsMap.containskey(ds.Driver__c) == false) {
                    dsMap.put(ds.Driver__c, new List<DriverSchedule__c>());
                }
                dsMap.get(ds.Driver__c).add(ds);
            }

            // ドライバーの行を作成

            for (DriverMaster__c dm : dmList) {
                driveBean db = new driveBean();
                db.driverMaster = dm;
                db.masterId = dm.Id;
                db.masterName = dm.Name;
                db.cssstr = '';
                Map<String, worksceduleBean> dmDateMap = new Map<String, worksceduleBean>();
                db.worksceduleMap = dmDateMap;
                if (driverDeaMap.containskey(dm.Id)) {
                    Date d;
                    Integer i = 0;
                    DispatchAssignDriver__c olddr;
                    for (DispatchAssignDriver__c driverDea : driverDeaMap.get(dm.Id)) {
                        String keystr = dm.Id + driverDea.DriverSchedule__r.Date__c.format();
                        if (dmDateMap.containsKey(keystr) == false) {
                            dmDateMap.put(keystr, new worksceduleBean());
                        }
                        worksceduleBean wcb = dmDateMap.get(keystr);
                        if (d == null) {
                            d = driverDea.DriverSchedule__r.Date__c;
                        }
                        System.debug(driverDea.DriverSchedule__r.Date__c + '  ' + d);
                        System.debug(d.daysBetween(driverDea.DriverSchedule__r.Date__c));
                        System.debug(i);
                        if (d.daysBetween(driverDea.DriverSchedule__r.Date__c) > i) {
                            d = driverDea.DriverSchedule__r.Date__c;
                            i = 0;
                        }
                        i++;
                        if (i > consecutiveWorkingDays) {
                            wcb.overCssStr = 'overCssStr';
                        }
                        System.debug(wcb.overCssStr + consecutiveWorkingDays);
                        if (
                            olddr != null &&
                            driverDea.DriverSchedule__c != null &&
                            driverDea.DriverSchedule__r.Date__c != null &&
                            driverDea.DriverSchedule__r.Date__c.daysBetween(olddr.DriverSchedule__r.Date__c) == 1
                        ) {
                            if (
                                driverDea.DriverSchedule__r.AttendanceDateTime_F__c.getTime() -
                                olddr.DriverSchedule__r.DepartureDateTime_F__c.getTime() < 777600000
                            ) {
                                wcb.overCssStr2 = 'over9h';
                            }
                        }
                        if (
                            driverDea.DriverSchedule__r.AttendanceTime__c != null &&
                            driverDea.DriverSchedule__r.DepartureTime__c != null
                        ) {
                            Integer len = driverDea.DriverSchedule__r.TotalTime_F__c.split(':')[0].length();
                            wcb.overCssStr15 = len > 1 && driverDea.DriverSchedule__r.TotalTime_F__c > '15' ? 'over15' : '';
                        }
                        if (driverDea.DriverSchedule__c != null && driverDea.DriverSchedule__r.Date__c != null) {
                            olddr = driverDea;
                        }
                        wcb.dispatchVehicle = driverDea.DispatchVehicle__r;
                        wcb.dispatchVehiclemastername = driverDea.DispatchDetail__r.VehiclelNumber_F__c;

                        Set<Id> existingDeaIds = new Set<Id>();
                        for (DispatchAssignDriver__c existingDea : wcb.dispatchAssignDriverList) {
                            existingDeaIds.add(existingDea.Id);
                        }
                        if (deaMap.containsKey(driverDea.DriverSchedule__r.Id)) {
                            for (DispatchAssignDriver__c dea : deaMap.get(driverDea.DriverSchedule__r.Id)) {
                                if (!existingDeaIds.contains(dea.Id)) {
                                    wcb.dispatchAssignDriverList.add(dea);
                                    existingDeaIds.add(dea.Id);
                                }
                            }
                        }
                    }
                    // for (DriverSchedule__c ds : dsMap.get(dm.Id)) {
                    //     String keystr = dm.Id + ds.Date__c.format();
                    //     if (dmDateMap.containsKey(keystr) == false) {
                    //         dmDateMap.put(keystr, new worksceduleBean());
                    //     }
                    //     worksceduleBean wcb = dmDateMap.get(keystr);
                    //     wcb.driverSchedule = ds;
                    //     if (String.isNotBlank(ds.WorkStatus__c)) {
                    //         wcb.dispatchVehicleworkStatus = plickvalueMap.get(ds.WorkStatus__c);
                    //     }
                    // }
                }
                if (dsMap.containsKey(dm.Id) && dsMap.get(dm.Id).size() > 0) {
                    for (DriverSchedule__c ds : dsMap.get(dm.Id)) {
                        String keystr = dm.Id + ds.Date__c.format();
                        if (dmDateMap.containsKey(keystr) == false) {
                            dmDateMap.put(keystr, new worksceduleBean());
                        }
                        worksceduleBean wcb = dmDateMap.get(keystr);
                        wcb.driverSchedule = ds;
                        if (String.isNotBlank(ds.WorkStatus__c)) {
                            wcb.dispatchVehicleworkStatus = plickvalueMap.get(ds.WorkStatus__c);
                        }
                    }
                }
                resb.drives.add(db);
            }

            // 下請け業者の行を作成

            for (String SubcontractorId : subcontractorDeaMap.keySet()) {
                driveBean db = new driveBean();
                db.driverMaster = null;
                db.cssstr = 'nothavedmaster';
                Map<String, worksceduleBean> dmDateMap = new Map<String, worksceduleBean>();
                db.worksceduleMap = dmDateMap;
                if (subcontractorDeaMap.containskey(SubcontractorId)) {
                    for (DispatchAssignDriver__c subcontractorDea : subcontractorDeaMap.get(SubcontractorId)) {
                        db.masterId = SubcontractorId;
                        db.masterName =
                            subcontractorDea.DispatchVehicle__r.Subcontractor__r.Name +
                            '(' +
                            getStringCheckBlank(subcontractorDea.DispatchVehicle__r.CharteredVehicleNumber__c) +
                            ')';
                        String keystr = SubcontractorId + subcontractorDea.DispatchVehicle__r.Date__c.format();
                        if (dmDateMap.containsKey(keystr) == false) {
                            dmDateMap.put(keystr, new worksceduleBean());
                        }
                        worksceduleBean wcb = dmDateMap.get(keystr);
                        wcb.dispatchVehicle = subcontractorDea.DispatchVehicle__r;
                        wcb.dispatchVehiclemastername = getStringCheckBlank(
                            subcontractorDea.DispatchDetail__r.VehiclelNumber_F__c
                        );
                        if (deaMap.containsKey(subcontractorDea.DispatchDetail__r.Id)) {
                            for (DispatchAssignDriver__c dea : deaMap.get(subcontractorDea.DispatchDetail__r.Id)) {
                                wcb.dispatchAssignDriverList.add(dea);
                            }
                        }
                    }
                }
                resb.drives.add(db);
            }

            resb.issuccess = true;
            return resb;
        } catch (Exception e) {
            resb.issuccess = false;
            resb.errormessage = e.getMessage() + e.getStackTraceString();
        }
        return resb;
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
        public String overCssStr;
        @AuraEnabled
        public String overCssStr2;
        @AuraEnabled
        public String overCssStr15;
        @AuraEnabled
        public Date de;
        @AuraEnabled
        public List<DispatchAssignDriver__c> dispatchAssignDriverList;
        worksceduleBean() {
            this.dispatchAssignDriverList = new List<DispatchAssignDriver__c>();
            this.dispatchVehicleworkStatus = '';
            this.dispatchVehiclemastername = '';
        }
    }
}