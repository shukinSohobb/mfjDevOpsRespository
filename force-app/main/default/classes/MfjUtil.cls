public with sharing class MfjUtil {
    /**
     * SaveResultからエラー情報を戻す (UpsertResult対応してないです)
     * @param srList insert または update DML操作の結果
     * @param objType オブジェクトのタイプ
     * @param dataList insert または updateの数据
     * @param isFirstOnly 1件目だけ、default true
     * @return エラー情報のList
     */
    public static List<String> setSaveError(
        String classAndMethod,
        List<Database.SaveResult> srList,
        Schema.sObjectType objType,
        List<sObject> dataList,
        Boolean isFirstOnly
    ) {
        List<String> messageList = new List<String>();
        String objectName = objType.getDescribe().getName();
        String objectLabel = objType.getDescribe().getLabel();
        for (Integer i = 0; i < srList.size(); i++) {
            sObject eObj = dataList[i];
            Database.SaveResult sr = srList[i];
            if (false == sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    String message = objectLabel + ':' + objectName + ' Data:' + eObj.get('Id');
                    Schema.SObjectType eObjType = eObj.getSObjectType();
                    // if (eObjType == Knowledge__kav.sObjectType) {
                    //     if (eObj.get('UrlName') != null) {
                    //         message += ', ' + eObj.get('UrlName');
                    //     }
                    // } else
                    if (eObjType == Case.sObjectType) {
                        if (eObj.get('CaseNumber') != null) {
                            message += ', ' + eObj.get('CaseNumber');
                        }
                    } else {
                        Map<String, Schema.sObjectField> eObjFldMap = eObjType.getDescribe().fields.getMap();
                        if (eObjFldMap.containsKey('Name') && eObj.get('Name') != null) {
                            message += ', ' + eObj.get('Name');
                        }
                    }
                    message += '\nerror:' + err.getStatusCode() + ' caused by:' + err.getMessage();
                    message += ((err.getFields() != null && !err.getFields().isEmpty())
                        ? ', 項目:' + String.valueOf(err.getFields())
                        : '');
                    messageList.add(message);
                    if (isFirstOnly && false == messageList.isEmpty()) {
                        break;
                    }
                }
            }
            if (isFirstOnly && false == messageList.isEmpty()) {
                break;
            }
        }
        return messageList;
    }

    /**
     * UpsertResultからエラー情報を戻す (Upsert専用)
     * @param srList upsert DML操作の結果
     * @param objType オブジェクトのタイプ
     * @param dataList upsertの数据
     * @param isFirstOnly 1件目だけ、default true
     * @return エラー情報のList
     */
    public static List<String> setSaveError(
        String classAndMethod,
        List<Database.UpsertResult> srList,
        Schema.sObjectType objType,
        List<sObject> dataList,
        Boolean isFirstOnly
    ) {
        List<String> messageList = new List<String>();
        String objectName = objType.getDescribe().getName();
        String objectLabel = objType.getDescribe().getLabel();
        for (Integer i = 0; i < srList.size(); i++) {
            sObject eObj = dataList[i];
            Database.UpsertResult sr = srList[i];
            if (false == sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    String message = objectLabel + ':' + objectName + ' Data:' + eObj.get('Id');
                    Schema.SObjectType eObjType = eObj.getSObjectType();
                    // if (eObjType == Knowledge__kav.sObjectType) {
                    //     if (eObj.get('UrlName') != null) {
                    //         message += ', ' + eObj.get('UrlName');
                    //     }
                    // } else
                    if (eObjType == Case.sObjectType) {
                        if (eObj.get('CaseNumber') != null) {
                            message += ', ' + eObj.get('CaseNumber');
                        }
                    } else {
                        Map<String, Schema.sObjectField> eObjFldMap = eObjType.getDescribe().fields.getMap();
                        if (eObjFldMap.containsKey('Name') && eObj.get('Name') != null) {
                            message += ', ' + eObj.get('Name');
                        }
                    }
                    message += '\nerror:' + err.getStatusCode() + ' caused by:' + err.getMessage();
                    message += ((err.getFields() != null && !err.getFields().isEmpty())
                        ? ', 項目:' + String.valueOf(err.getFields())
                        : '');
                    messageList.add(message);
                    if (isFirstOnly && false == messageList.isEmpty()) {
                        break;
                    }
                }
            }
            if (isFirstOnly && false == messageList.isEmpty()) {
                break;
            }
        }
        return messageList;
    }

    /**
     * DeleteResultからエラー情報を戻す (Upsert専用)
     * @param srList delete DML操作の結果
     * @param objType オブジェクトのタイプ
     * @param dataList deleteの数据
     * @param isFirstOnly 1件目だけ、default true
     * @return エラー情報のList
     */
    public static List<String> setDeleteError(
        String classAndMethod,
        List<Database.DeleteResult> srList,
        Schema.sObjectType objType,
        List<sObject> dataList,
        Boolean isFirstOnly
    ) {
        List<String> messageList = new List<String>();
        String objectName = objType.getDescribe().getName();
        String objectLabel = objType.getDescribe().getLabel();
        for (Integer i = 0; i < srList.size(); i++) {
            sObject eObj = dataList[i];
            Database.DeleteResult sr = srList[i];
            if (false == sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    String message = objectLabel + ':' + objectName + ' Data:' + eObj.get('Id');
                    Schema.SObjectType eObjType = eObj.getSObjectType();
                    // if (eObjType == Knowledge__kav.sObjectType) {
                    //     if (eObj.get('UrlName') != null) {
                    //         message += ', ' + eObj.get('UrlName');
                    //     }
                    // } else
                    if (eObjType == Case.sObjectType) {
                        if (eObj.get('CaseNumber') != null) {
                            message += ', ' + eObj.get('CaseNumber');
                        }
                    } else {
                        Map<String, Schema.sObjectField> eObjFldMap = eObjType.getDescribe().fields.getMap();
                        if (eObjFldMap.containsKey('Name') && eObj.get('Name') != null) {
                            message += ', ' + eObj.get('Name');
                        }
                    }
                    message += '\nerror:' + err.getStatusCode() + ' caused by:' + err.getMessage();
                    message += ((err.getFields() != null && !err.getFields().isEmpty())
                        ? ', 項目:' + String.valueOf(err.getFields())
                        : '');
                    messageList.add(message);
                    if (isFirstOnly && false == messageList.isEmpty()) {
                        break;
                    }
                }
            }
            if (isFirstOnly && false == messageList.isEmpty()) {
                break;
            }
        }
        return messageList;
    }

    public static List<String> setSaveError(
        String classAndMethod,
        List<Database.SaveResult> srList,
        Schema.sObjectType obj,
        List<sObject> dataList
    ) {
        return setSaveError(classAndMethod, srList, obj, dataList, true);
    }

    public static List<String> setSaveError(
        String classAndMethod,
        List<Database.UpsertResult> srList,
        Schema.sObjectType obj,
        List<sObject> dataList
    ) {
        return setSaveError(classAndMethod, srList, obj, dataList, true);
    }

    public static List<String> setDeleteError(
        String classAndMethod,
        List<Database.DeleteResult> srList,
        Schema.sObjectType obj,
        List<sObject> dataList
    ) {
        return setDeleteError(classAndMethod, srList, obj, dataList, true);
    }

    public static date getEndOfMonth(Date targetDate) {
        Date NewTargetDate = targetDate.addMonths(1).toStartOfMonth();
        Date result = NewTargetDate - 1;
        return result;
    }

    // 日付の期制の開始日を取得
    public static Date getTargetTermCycleStartDate(Date targetDate, String closingDate) {
        Date targetTermCycleStartDate = null;
        if (closingDate.contains('15')) {
            targetTermCycleStartDate = Date.newInstance(targetDate.year(), targetDate.month(), 16);
        } else if (closingDate.contains('20')) {
            targetTermCycleStartDate = Date.newInstance(targetDate.year(), targetDate.month(), 21);
        } else {
            targetTermCycleStartDate = Date.newInstance(targetDate.year(), targetDate.month(), 1);
        }
        if (targetTermCycleStartDate != null && targetTermCycleStartDate > targetDate) {
            targetTermCycleStartDate = targetTermCycleStartDate.addMonths(-1);
        }
        return targetTermCycleStartDate;
    }

    // 日付の期制の終了日を取得
    public static Date getTargetTermCycleEndDate(Date targetDate, String closingDate) {
        Date targetTermCycleEndDate = null;
        if (closingDate.contains('15')) {
            targetTermCycleEndDate = Date.newInstance(targetDate.year(), targetDate.month(), 15);
        } else if (closingDate.contains('20')) {
            targetTermCycleEndDate = Date.newInstance(targetDate.year(), targetDate.month(), 20);
        } else {
            targetTermCycleEndDate = Date.newInstance(
                targetDate.year(),
                targetDate.month(),
                Date.daysInMonth(targetDate.year(), targetDate.month())
            );
        }
        if (targetTermCycleEndDate != null && targetTermCycleEndDate < targetDate) {
            targetTermCycleEndDate = targetTermCycleEndDate.addMonths(1);
        }
        return targetTermCycleEndDate;
    }

    // 日付の期の開始日を取得
    public static Date getTargetTermStartDate(Date targetDate, String closingDate) {
        Date targetTermStartDate = null;
        List<Integer> startDateList = new List<Integer>();
        if (closingDate.contains('15')) {
            startDateList = new List<Integer>{ 16, 26, 6 };
        } else if (closingDate.contains('20')) {
            startDateList = new List<Integer>{ 21, 1, 11 };
        } else {
            startDateList = new List<Integer>{ 1, 11, 21 };
        }

        // Integer targetTerm = 1;
        for (Integer i = 0; i < startDateList.size(); i++) {
            Date d = Date.newInstance(targetDate.year(), targetDate.month(), startDateList[i]);
            if (d > targetDate) {
                d = d.addMonths(-1);
            }
            if (d <= targetDate) {
                if (targetTermStartDate == null || targetTermStartDate < d) {
                    targetTermStartDate = d;
                    //targetTerm = i+1;
                }
            }
        }
        return targetTermStartDate;
    }

    // 日付の期の終了日を取得
    public static Date getTargetTermEndDate(Date targetDate, String closingDate) {
        Date targetTermEndDate = null;
        List<Integer> endDateList = new List<Integer>();
        if (closingDate.contains('15')) {
            endDateList = new List<Integer>{ 25, 5, 15 };
        } else if (closingDate.contains('20')) {
            endDateList = new List<Integer>{ Date.daysInMonth(targetDate.year(), targetDate.month()), 10, 20 };
        } else {
            endDateList = new List<Integer>{ 10, 20, Date.daysInMonth(targetDate.year(), targetDate.month()) };
        }

        // Integer targetTerm = 1;
        for (Integer i = 0; i < endDateList.size(); i++) {
            Date d = Date.newInstance(targetDate.year(), targetDate.month(), endDateList[i]);
            if (d < targetDate) {
                d = d.addMonths(1);
            }
            if (d >= targetDate) {
                if (targetTermEndDate == null || targetTermEndDate > d) {
                    targetTermEndDate = d;
                    //targetTerm = i+1;
                }
            }
        }
        return targetTermEndDate;
    }
}