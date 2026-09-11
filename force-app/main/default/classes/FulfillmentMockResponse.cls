@isTest
global class FulfillmentMockResponse implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        //verify the request looks like what we expect
        System.assertEquals('callout:Fulfillment_Warehouse_System/posts', request.getEndpoint());
        System.assertEquals('POST', request.getMethod());
        
        // Build a fake response, mimicking what JSONPlaceholder actually returns
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"id": 101, "title": "fake title", "body": "fake body", "userId": 1}');
        response.setStatusCode(201);
        return response;
    }

}