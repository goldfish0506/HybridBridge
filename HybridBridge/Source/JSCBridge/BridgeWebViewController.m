//
//  BridgeWebViewController.m
//  WebTest
//
//  Created by liaojinxing on 14-3-25.
//  Copyright (c) 2014年 Douban. All rights reserved.
//

#import "BridgeWebViewController.h"
#import "JSCBridgeExport.h"
#import "UIWebView+JavaScriptContext.h"
#import "WebBridgeAPI.h"

@interface BridgeWebViewController ()<JSCBridgeExport, JSCWebViewDelegate>

@end

@implementation BridgeWebViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.webView = [[UIWebView alloc] initWithFrame:self.view.frame];
  self.webView.delegate = self;
  [self.view addSubview:self.webView];
}

- (void)webView:(UIWebView *)webView bridgeDidCreateJavaScriptContext:(JSContext *)ctx
{
  ctx[@"bridge"] = self;
}

// Javascript call objc
- (void)getJsonWithURL:(NSString *)URL
              callback:(JSValue *)callback
{
  AFHTTPRequestOperationManager *manager = [WebBridgeAPI sharedManager];
  [manager GET:URL
    parameters:nil
       success:^(AFHTTPRequestOperation *operation, id responseObject) {
         NSString *json = [operation responseString];
         if (![callback isNull] && json) {
           [callback callWithArguments:@[json]];
         }
       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"%@", error);
       }];
}

- (void)sendDataWithEventType:(NSString *)eventType
                      message:(NSString *)message
                     callback:(JSValue *)callback
{
  id response = [self responseForEventType:eventType message:message];
  if (![callback isNull]) {
    [callback callWithArguments:@[response]];
  }
}

- (void)postWithEventType:(NSString *)eventType message:(NSString *)message
{
  JSContext *context = [_webView javaScriptContext];

  id response = [self responseForEventType:eventType message:message];
  NSString *responseID = [self responseIDForEventType:eventType];
  context[responseID] = response;
  
  [self sendMessageToJS:@"hello world" callback:^(id responseData) {
    NSLog(@"%@", responseData);
  }];
}

- (void)receiveWithEventType:(NSString *)eventType callback:(JSValue *)callback
{
  JSContext *context = [_webView javaScriptContext];
  NSString *responseID = [self responseIDForEventType:eventType];
  JSValue *response = context[responseID];
  if (![callback isNull] && ![response isUndefined]) {
    [callback callWithArguments:@[response]];
  }
}

- (NSString *)responseIDForEventType:(NSString *)eventType
{
  return [NSString stringWithFormat:@"response_%@", eventType];
}

- (id)responseForEventType:(NSString *)eventType message:(NSString *)message
{
  if (self.responseDelegate) {
    return [self.responseDelegate responseForEventType:eventType message:message];
  }
  return @"response from objc to js";
}

// objc call javascript
- (void)sendMessageToJS:(NSString *)message callback:(void (^)(id responseData))callback
{
  JSContext *context = [_webView javaScriptContext];
  JSValue *responseFunction = context[@"responseDataToObjc"];
  JSValue *response = [responseFunction callWithArguments:@[message]];
  if (callback && ![response isNull] && ![response isUndefined]) {
    callback(response);
  }
}

@end