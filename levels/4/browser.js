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
  this.fill('form', {username: 'level07-password-holder', password: password}, true);
});

casper.then(function() {
  // Log the page title.
  console.log('On the main page')

  var page_title = this.getTitle();
  var page_url = this.getCurrentUrl();
  console.log('Before posting title is: ' + page_title + '(url: ' + page_url + ')');

  // TODO: maybe make a post sometimes?
  var h3 = this.evaluate(function() {
    return document.querySelectorAll('h3')[0].innerHTML;
  });

  console.log('First h3 has contents ' + h3);

  titles = ['Important update', 'Very important update', 'An update', 'An FYI',
            'FYI', 'Did you know...', 'Possibly of interest', 'Definitely of interest',
            "You probably don't care but...", 'Because I feel like posting', 'Note',
            "You probably don't know", 'Guess what?', 'Might want to take note', 'A really cool update'];

  bodies = ['I am hungry', 'Anyone want to play tennis?', 'Up for some racquetball?',
            'Hey!', "I'm bored. Anyone want to play a game?", 'Ooh, I think I found something',
            'Why is it so hard to find good juice restaurants?', 'You should all invite your friends to join Streamer!',
            'Why is everyone trying to exploit Streamer?', 'Streamer is *soo* secure',
            'Welcome!', 'Glad to have you here!', "I know what you're doing right now. You are reading this message."];

  // Post infrequently
  if (Math.random() < 0.05) {
    console.log('Decided to post');
    title = titles[Math.floor(Math.random() * titles.length)];
    body = bodies[Math.floor(Math.random() * bodies.length)];
    this.fill('form#new_post', {title: title, body: body}, true);
  } else {
    console.log('Decided not to post');
  }
});

casper.then(function() {
  var page_title = this.getTitle();
  var page_url = this.getCurrentUrl();
  console.log('Before posting title is: ' + page_title + '(url: ' + page_url + ')');
});

casper.run(function() {
  console.log('Running!');
  casper.exit(0);
});

