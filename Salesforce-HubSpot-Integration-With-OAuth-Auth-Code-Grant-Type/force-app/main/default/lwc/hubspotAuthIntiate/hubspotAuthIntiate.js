import { LightningElement } from 'lwc';
import getAuthStatus from '@salesforce/apex/HubspotAuthController.getAuthStatus';

export default class HubspotAuthIntiate extends LightningElement {
    
    connectedCallback(){
        const url = window.location.href; //to get the URL after redirect
        const code = new URL(url).searchParams.get('c__code');//get the code from URL
        console.log('code:'+code);
        //call the getAuthStatus method in apex
        getAuthStatus({code:code})
        .then((response) => {
            console.log('response:'+response);
        })
        .catch((error) => {
            console.log('error: ' + error);
        });
       
    }
    handleAuth(){
        //Redirect URI in Hubspot Dev Console
        window.location.href = 'https://app-na2.hubspot.com/oauth/authorize?client_id=577cee98-d847-41bf-8be5-1b1975298517&redirect_uri=https://varma6-dev-ed--c.develop.vf.force.com/apex/HubSpotRedirectPage&scope=oauth%20crm.objects.companies.read'
    }
   
}