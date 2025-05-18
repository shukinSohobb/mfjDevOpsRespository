public class MapAPIHandler implements Queueable, Database.AllowsCallouts {
    // APIキー
    private static final String apiKey = MFJSetting__mdt.getInstance('MapApiKey').Value__c;
    private OriginDestination__c originDestination;

    @InvocableMethod(label='座標設定' description='緯度と経度を取得')
    public static void setCoordinatesInvocable(List<OriginDestination__c> records) {
        if (records.isEmpty())
            return;

        for (OriginDestination__c record : records) {
            System.enqueueJob(new MapAPIHandler(record));
        }
    }

    // コンストラクタ：対象の発着地レコードを受け取り、インスタンスに保持する
    public MapAPIHandler(OriginDestination__c originDestination) {
        this.originDestination = originDestination;
    }

    // Queueableジョブ実行時に呼ばれるメソッド。非同期で座標設定を実行する
    // Google Maps APIを使って住所から緯度・経度を取得し、レコードに設定・更新する
    public void execute(QueueableContext context) {
        // 発着地レコードがない場合、または住所の項目に値がない場合、処理しない
        if (this.originDestination == null)
            return;

        // 住所＝{都道府県}、{市区郡}、{町村（町名）}
        String address =
            '日本、' +
            this.originDestination.PrefectureLabel_F__c +
            '、' +
            this.originDestination.City__c +
            '、' +
            this.originDestination.Street__c;

        HttpRequest req = new HttpRequest();
        // APIのエンドポイント
        String endpoint =
            'https://maps.googleapis.com/maps/api/geocode/' +
            // 結果の形
            'json' +
            '?' +
            // 住所
            'address=' +
            address +
            // 言語＝日本語
            '&language=ja' +
            // APIキー
            '&key=' +
            apiKey;
        req.setEndpoint(endpoint);
        req.setMethod('GET');

        try {
            Http http = new Http();
            // APIリクエストを送って、レスポンスを取得する
            HttpResponse res = http.send(req);
            Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            // レスポンスの状態が成功の場合、レコードの緯度と経度が設定される
            if (res.getStatusCode() == 200 && resMap.get('status') == 'OK') {
                List<Object> results = (List<Object>) resMap.get('results');
                if (!results.isEmpty()) {
                    Map<String, Object> location = (Map<String, Object>) ((Map<String, Object>) ((Map<String, Object>) results[0])
                            .get('geometry'))
                        .get('location');

                    this.originDestination.Latitude__c = (Decimal) location.get('lat');
                    this.originDestination.Longitude__c = (Decimal) location.get('lng');

                    // レコードの更新
                    update this.originDestination;
                } else {
                    throw new CommonTriggerHandler.MyException('経度緯度取得できません: ' + address);
                }
            } else {
                throw new CommonTriggerHandler.MyException('Google Maps APIエラー: ' + resMap.get('error_message'));
            }
        } catch (Exception e) {
            System.debug('緯度と経度を取得するAPI: ' + e.getMessage() + '\n' + e.getStackTraceString());
            BulkProcessLog__c processLog = new BulkProcessLog__c();
            processLog.ProcessSubject__c = '緯度と経度を取得するAPIにおいてエラーが発生しました';
            processLog.ProcessStatus__c = 'Error';
            processLog.ProcessLog__c = e.getMessage() + '\n' + e.getStackTraceString();
            Database.insert(processLog);
        }
    }
}