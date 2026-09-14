public class FulfillmentSyncService {
    public static string sendFulfillmentOrder(Opportunity opp){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        //JSONPlaceholder's /posts endpoint is standing in for
        //the warehouse system's "create order" endpoint
        request.setEndpoint('callout:Fulfillment_Warehouse_System/posts');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json; charset=UTF-8');
        
        //Build the payload - this is the "fulfillment order" data
        //the warehouse system would need to start shipping
        Map<String, Object> payload = new Map<String, Object>{
            'title' => 'Fulfillment Order for: ' + opp.Name,
            'body' => 'Opportunity' + opp.Id + ' closed won. Amount: ' + opp.Amount,
            'userId' => 1,
            'shippingPriority' => opp.Shipping_Priority__c
        };
        request.setBody(JSON.serialize(payload));
        
        HttpResponse response = http.send(request);
        
        // Log what happened - in a real integration you'd likely
        // write this to a custom object or field for visibility
        if (response.getStatusCode() == 201 || response.getStatusCode() == 200){
            System.debug('Fulfillment sync succeeded: ' + response.getBody());
            
            // Parse the response and pull out the external system's id
            Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Object externalId = responseBody.get('id');
            return externalId != null ? String.valueOf(externalId) : null;
        } else {
            System.debug('Fulfillment sync failed. Status: ' + response.getStatusCode() + ' Body: ' + response.getBody());
            return null;
        }
    }
}