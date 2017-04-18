// Install instructions:
//  - Install phantomjs 1.5+
//    - brew install phantomjs (or similar)
//    - http://phantomjs.org/download.html
//   - Install casperjs
//     - http://docs.casperjs.org/en/latest/installation.html
//   - Run it!
//     - casperjs browser.js http://localhost:4567
//
// Will exit(0) if success, exit(other) if failure
// Profit!

var casper = require('casper').create();
var system = require('system');
var utils = require('utils');
var fs = require('fs');

if (!casper.cli.has(0)) {
  console.log('Usage: browser.js <url to visit>');
  casper.exit(1);
}

var password = fs.open('password.txt', 'r').read().trim();

var page_address = casper.cli.get(0);
console.log('Page address is: ' + page_address);

casper.start(page_address, function() {
  // Fill and submit the login form
  console.log('Filling the login form...');
  this.fill('form', {username: 'karma_fountain', password: password}, true);
});

casper.then(function() {
  // Log the page title.
  console.log('On the main page')

  var page_title = this.getTitle();
  var page_url = this.getCurrentUrl();
  console.log('Page title is: ' + page_title + '(url: ' + page_url + ')');

  var credits = this.evaluate(function() {
    return document.querySelectorAll('p')[1].innerHTML;
  });

  var credits_left = credits.match(/-?\d+/);
  console.log('Guard Llama has ' + credits_left + ' credits left');
});

casper.run(function() {
  console.log('Running!');
  casper.exit(0);
});

