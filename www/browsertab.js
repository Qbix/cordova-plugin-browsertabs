/*
 * Copyright 2017 Qbix Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the
 * License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing permissions and
 * limitations under the License.
 */

var exec = require('cordova/exec');

var isAvailable = function(success, error) {
  exec(success, error, 'BrowserTab', 'isAvailable', []);
};

var openUrl = function(url, opt_error) {
  var doNothing = function() {};
  var error = (!opt_error) ? doNothing : opt_error;
  exec(doNothing, error, 'BrowserTab', 'openUrl', [url]);
};

var close = function(opt_error) {
  var doNothing = function() {};
  var error = (!opt_error) ? doNothing : opt_error;
  exec(doNothing, error, 'BrowserTab', 'close', []);
};

/**
 * Opens a url inside an application tab.
 * Note that on iOS 11 and up, this uses SFAuthenticationSession
 * @param {String} url The url to open
 * @param {Object} [options={}]
 * @param {String} options.scheme The scheme to switch back to your app in iOS 11
 * @param {Function} success
 * @param {Function} error
 */
exports.openUrl = function (url, options, success, error) {
   if(options == undefined) { options = {} }
   exports.isAvailable(function (result) {
       if (result) {
           exports.openUrlInTab(url, options, success, error);
       } else {
           exports.openUrlInBrowser(url, success, error);
       }
   }, function () {
       exports.openUrlInBrowser(url, success, error);
   });
};

/**
 * Opens a url inside an application tab.
 * Note that on iOS 11 and up, this uses SFAuthenticationSession
 * @param {String} url The url to open
 * @param {Object} [options={}]
 * @param {String} options.scheme The scheme to switch back to your app in iOS 11
 * @param {Function} success
 * @param {Function} error
 */
exports.openUrlInTab = function(url, options, success, error) {
   if(options == undefined) { options = {} }
   exec(success, error, 'BrowserTab', 'openUrl', [url, options]);
};

/**
 * Opens a url in the system browser
 * @paran {String} url The url to open
 * @param {Function} success
 * @param {Function} error
 */
exports.openUrlInBrowser = function(url, success, error) {
   exec(success, error, 'BrowserTab', 'openUrlInBrowser', [url]);
};

/**
 * Closes a previously opened browser tab
 * @param {Function} success
 * @param {Function} error
 */
exports.close = function(success, error) {
   exec(success, error, 'BrowserTab', 'close', []);
};

/**
 * Checks whether openUrlInTab is available to be used
 * @param {Function} success
 * @param {Function} error
 */
exports.isAvailable = function(success, error) {
   exec(success, error, 'BrowserTab', 'isAvailable', []);
};
