/*! @file CBTBrowserTab.m
    @brief Browser tab plugin for Cordova
    @copyright
        Copyright 2016 Google Inc. All Rights Reserved.
    @copydetails
        Licensed under the Apache License, Version 2.0 (the "License");
        you may not use this file except in compliance with the License.
        You may obtain a copy of the License at
        http://www.apache.org/licenses/LICENSE-2.0
        Unless required by applicable law or agreed to in writing, software
        distributed under the License is distributed on an "AS IS" BASIS,
        WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
        See the License for the specific language governing permissions and
        limitations under the License.
 */

#import "CBTBrowserTab.h"

#import <SafariServices/SFAuthenticationSession.h>

@implementation CBTBrowserTab {
  SFSafariViewController *_safariViewController;
  SFAuthenticationSession *_authenticationVC;
  NSString *lastCallbackId;
  NSString *lastRedirectScheme;
}

- (void)isAvailable:(CDVInvokedUrlCommand *)command {
  BOOL available = ([SFSafariViewController class] != nil);
  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                messageAsBool:available];
  [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)openUrlInBrowser:(CDVInvokedUrlCommand *)command {
    NSString *urlString = command.arguments[0];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

-(void) sendCloseResult:(NSString*) callbackId{
    [self sendSuccessResult:callbackId withUrl:@""];
}

-(void) sendSuccessResult:(NSString*) callbackId withUrl:(NSString*) url {
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:url];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

-(void) sendOpenResult:(NSString*) callbackId{
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
       messageAsInt:1];;
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

- (void)openUrl:(CDVInvokedUrlCommand *)command {
  NSString *urlString = command.arguments[0];
  NSDictionary *options = command.arguments[1];
  lastCallbackId = command.callbackId;
  if (urlString == nil) {
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                messageAsString:@"url can't be empty"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    return;
  }

  NSURL *url = [NSURL URLWithString:urlString];
  if ([SFSafariViewController class] == nil) {
    NSString *errorMessage = @"in app browser tab not available";
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                messageAsString:errorMessage];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
  }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    BOOL isAuthSession = options != nil && [options isKindOfClass:[NSDictionary class]] && [options objectForKey:@"authSession"] != nil && [[options objectForKey:@"authSession"] boolValue];
    isAuthSession = isAuthSession && [UIDevice currentDevice].systemVersion.floatValue >= 11;
    
    if([options objectForKey:@"scheme"] != nil && [[options objectForKey:@"scheme"] length] != 0) {
        lastRedirectScheme = [options objectForKey:@"scheme"];
        if(!isAuthSession) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onHandleOpenUrl:) name:CDVPluginHandleOpenURLNotification object:nil];
        }
    }
    
    BOOL isOpenSafariVC = YES;
    
    if (@available(iOS 11.0, *)) {
        if (isAuthSession) {
            isOpenSafariVC = NO;
            
            SFAuthenticationSession* authenticationVC =
            [[SFAuthenticationSession alloc] initWithURL:url
                                       callbackURLScheme:lastRedirectScheme
                                       completionHandler:^(NSURL * _Nullable callbackURL,
                                                           NSError * _Nullable error) {
                self->_authenticationVC = nil;
                self->lastRedirectScheme = nil;
                self->lastCallbackId = nil;
                                           
                if (callbackURL) {
                    [self sendSuccessResult:command.callbackId withUrl:callbackURL.absoluteString];
                } else {
                    [self sendCloseResult:command.callbackId];
                }
            }];
            _authenticationVC = authenticationVC;
            BOOL isSessionStarted = [authenticationVC start];
            
            if(isSessionStarted) {
                [self sendOpenResult:command.callbackId];
            } else {
                CDVPluginResult *startResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"SFAuthenticationSession not started"];
                [self.commandDelegate sendPluginResult:startResult callbackId:command.callbackId];
            }
        }
    }
 
    if(isOpenSafariVC) {
        _safariViewController = [[SFSafariViewController alloc] initWithURL:url];
        _safariViewController.delegate = self;
        [self.viewController presentViewController:_safariViewController animated:YES completion:nil];
        [self sendOpenResult:command.callbackId];
    }

}

- (void)onHandleOpenUrl:(NSNotification*)notification {
    if(lastRedirectScheme!= nil && lastCallbackId != nil) {
        NSString *openUrl = [[notification object] absoluteString];
        if([openUrl hasPrefix:lastRedirectScheme]) {
            [self sendSuccessResult:lastCallbackId withUrl:openUrl];
        }
        lastRedirectScheme = nil;
        lastCallbackId = nil;
        [self close:nil];
    }
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    NSLog(@"Finished safariViewControllerDidFinish: %@", lastCallbackId);
    if(lastCallbackId != nil) {
        [self sendCloseResult:lastCallbackId];
    }
    
}

- (void)close:(CDVInvokedUrlCommand *)command {
    if (_safariViewController != nil) {
        [_safariViewController dismissViewControllerAnimated:YES completion:nil];
        _safariViewController = nil;
    }
    
//    if(!_authenticationVC) {
//        [_authenticationVC cancel];
//        _authenticationVC = nil;
//    }
}

@end
