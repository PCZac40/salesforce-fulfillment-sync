@isTest
global class FulfillmentMockResponse implements HttpCalloutMock {
    global static String lastRequestBody; // NEW: capture what was actually sent

    global HTTPResponse respond(HTTPRequest request) {
        System.assertEquals('callout:Fulfillment_Warehouse_System/posts', request.getEndpoint());
        System.assertEquals('POST', request.getMethod());

        lastRequestBody = request.getBody(); // NEW

        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"id": 101, "title": "fake title", "body": "fake body", "userId": 1}');
        response.setStatusCode(201);
        return response;
    }
}