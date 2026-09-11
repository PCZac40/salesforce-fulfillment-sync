@isTest
global class FulfillmentMockFailureResponse implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"error": "Internal Server Error"}');
		response.setStatusCode(500);
        return response;
    }

}