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
        String requestBody = '&grant_type=authorization_code'+
        '&code='+code+
        '&redirect_uri=https://varma6-dev-ed--c.develop.vf.force.com/apex/HubSpotRedirectPage'+
        '&client_id=577cee98-d847-41bf-8be5-1b1975298517'+
        '&client_secret=4df72505-4a2e-4774-9415-3224f1536f28';
        request.setBody(requestBody);

        //Step 3: Send the request and handle the response
        HttpResponse response = http.send(request);
        if(response.getStatusCode() == 200){
            Map<String, Object> responseBody = (Map<String,Object>)JSON.deserializeUntyped(response.getBody());
            String token = (String)responseBody.get('access_token');
            String companyInfo = getAccountFromHubspot(token);
            return companyInfo;
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
}