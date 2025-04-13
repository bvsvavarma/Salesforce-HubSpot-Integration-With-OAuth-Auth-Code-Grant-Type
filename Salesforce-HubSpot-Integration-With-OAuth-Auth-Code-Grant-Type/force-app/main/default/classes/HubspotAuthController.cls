public with sharing class HubspotAuthController {

    @AuraEnabled
    public static string getAuthStatus(String code){
        String endPoint = 'https://api.hubapi.com/oauth/v1/token';
        //Step 1: Instantiate the Http class
        Http http = new Http();
        //Step 2: Craft or crete a Http Request
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(endPoint);
        request.setHeader('content-type', 'application/x-www-form-urlencoded');
        /*String requestBody = '&grant_type=authorization_code'+
        '&code='+code+
        '&redirect_uri=https://varma6-dev-ed--c.develop.vf.force.com/apex/HubSpotRedirectPage'+
        '&client_id=577cee98-d847-41bf-8be5-1b1975298517'+
        '&client_secret=4df72505-4a2e-4774-9415-3224f1536f28';*/
        //Custom MetaData
        Hubspot_App_Credential__mdt credentials = Hubspot_App_Credential__mdt.getInstance('Salesforce_Hubspot_Integration_V1');
        String clientId = credentials.Client_Id__c;
        String clientSecret = credentials.Client_Secret__c;
        String redirectURI = credentials.Redirect_URI__c;
        
        String requestBody = '&grant_type=authorization_code'+
        '&code='+code+
        '&redirect_uri='+EncodingUtil.urlEncode(redirectURI, 'UTF-8')+
        '&client_id='+clientId+
        '&client_secret='+clientSecret;
        request.setBody(requestBody);

        //Step 3: Send the request and handle the response
        HttpResponse response = http.send(request);
        if(response.getStatusCode() == 200){
            Map<String, Object> responseBody = (Map<String,Object>)JSON.deserializeUntyped(response.getBody());
            String accessToken = (String)responseBody.get('access_token');
            String refreshToken = (String)responseBody.get('refresh_token');
            Integer expireIn = (Integer)responseBody.get('expires_in');

            Hubspot_Tokens__c tokens = new Hubspot_Tokens__c(
                Access_Token__c = accessToken,
                Refresh_Token__c = refreshToken,
                Expires_In__c = expireIn,
                setUpOwnerId = UserInfo.getUserId());
            
            insert tokens;

            //String companyInfo = getCompaniesFromHubspot(token);
            //return companyInfo;
            return 'User is Successfully Authenticated';
        }
        return 'callout Failed';
    }

    @AuraEnabled
    public static String getAccountFromHubspot(String accessToken){
        String endPoint = 'https://api.hubapi.com/crm/v3/objects/companies/47453206222?properties=name&properties=Industry&propertiesWithHistory=name&archived=false';
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(endPoint);
        req.setHeader('content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer '+accessToken);
        HttpResponse res = http.send(req);
        System.debug('Company Method Response: '+res);
        return res.getBody();
    }

    @AuraEnabled
    public static String getCompaniesFromHubspot(String accessToken){
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('https://api.hubapi.com/crm/v3/objects/companies/batch/read?archived=false');
        req.setHeader('Authorization', 'Bearer '+accessToken);
        req.setHeader('content-type', 'application/json');
        //req.setBody('{ "propertiesWithHistory": [ "name" ], "idProperty": "string", "inputs": [ { "id": "47453206222" } ], "properties": [ "name", "industry" ] }');
        
        BatchReadRequestBody requestBody = new BatchReadRequestBody();
        requestBody.propertiesWithHistory = new List<String> {'name'};
        requestBody.inputs = new List<Map<String, String>> {new Map<String, String>{'id' => '47453206222'}};
        requestBody.properties = new List<String> {'name', 'industry'};
        
        req.setBody(JSON.serialize(requestBody));

        HttpResponse res= http.send(req);
        String name;
        String industry;
        if(res.getStatusCode() == 200){
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            System.debug('responseMap '+ responseMap);
            List<Object> results = (List<Object>) responseMap.get('results');
            System.debug('results '+ results);
            for(Object result : results){
                Map<String, Object> companyMap = (Map<String, Object>)result;
                System.debug('companyMap '+ companyMap);
                Map<String, Object> properties = (Map<String, Object>) companyMap.get('properties');
                System.debug('properties '+ properties);
                name = (String)properties.get('name');
                industry = (String)properties.get('industry');
            }
            return name + '--' + industry;

        }else{
            System.debug(res.getBody());
            return 'Something went wrong. Callout Failed.';
        }
    }
    private class BatchReadRequestBody{
        public List<String> propertiesWithHistory;
        public List<Map<String, String>> inputs;
        public List<String> properties;
    }
}