+++
date = "2017-03-16T01:38:48+09:00"
title = "Notify travis build to Typetalk"
draft = false
categories = [ "technology" ]
tags = [ "typetalk", "travis-ci", "google-apps-script" ]
eyecatch = "/images/travis-typetalk-flow.png"
+++

This site's build and deploy is done automatically by Travis CI. I wanted to notify that build result to my topic on Typetalk. Recently I realized it in a cheap and easy way, so I will explain how to it.

Please refer below for Typetalk details. Its a simply fun chat app for teams!  
https://www.typetalk.in/

It receive Travis CI notifications using Webhook and use Google Apps Script as the receiving endpoint. Google Apps Script is free, fast and easy to use, so just right. The bot built on "Google Apps Script" parses the message from TravisCI and posts it to Typetalk.

The following diagram that shows its flow. Its describe in detail.
![travis-typetalk-flow](/images/travis-typetalk-flow.png "travis-typetalk-flow")

## 1. Create a bot to get Typetalk Token.

You can get `TOPIC_ID` and `TYPETALK_TOKEN` for bot for each topic. Please refer [Official Documents](http://developer.nulab-inc.com/docs/typetalk#tttoken).
```
https://typetalk.in/topics/XXXXXX <= is TOPIC_ID.
```

## 2. Set up a bot in Google Apps Script.

Goole Apps Script is similar to JavaScript. It's very simple.  
https://script.google.com/

1. First add the following code to Goole Apps Script and put `TOPIC_ID` and `TYPETALK_TOKEN` obtained from Typetalk.
2. Next please click on the publish tab and select "deploy as web app".
3. And "Who has access to the app" should select "Anyone, even anonymous".
4. At last click update button and copy "Current web app URL".

`main.gs`

```
var TOPIC_ID = "YOUR_TOPIC_ID";
var TYPETALK_TOKEN = "YOUR_TYPETALK_TOKEN";

function doGet(e) {
  return makeContent(makeResponse("None", "GET"));
}

function doPost(e) {
  var payload = JSON.parse(e.parameter.payload);
  var message = fillTemplate(payload);
  postToTypetalk(message);
  return makeContent(makeResponse("OK", "POST"));
}

function postToTypetalk(message) {
  var options = {
    "method": "POST",
    "payload": { "message": message }
  };
  UrlFetchApp.fetch(
    "https://typetalk.in/api/v1/topics/" + TOPIC_ID + "?typetalkToken=" + TYPETALK_TOKEN,
    options
  );
}

function makeResponse(e, type) {
  var s = JSON.stringify({ type: type, params: e });
  return {
    mime: ContentService.MimeType.JSON,
    content: s
  };
}

function makeContent(content) {
  return ContentService.createTextOutput(content.content)
    .setMimeType(content.mime);
}

function fillTemplate(payload) {
  var id = payload.id,
      repository = payload.repository,
      branch = payload.branch,
      number = payload.number,
      state = payload.state,
      result = payload.result,
      duration = payload.duration,
      committer_name = payload.committer_name,
      commit = payload.commit,
      matrix = payload.matrix,
      message = payload.message;
  var name = repository.name,
      owner_name = repository.owner_name;
  var compare_url = matrix[0].compare_url;

  return (result == 0 ? ":smile:" : ":astonished:") + " Build [#" + number + "](https://travis-ci.org/" + owner_name + "/" + name + "/builds/" + id + ") ([" + commit.substr(0, 7) + "](" + compare_url + ")) of " + owner_name + "/" + name + " @ " + branch + " by " + committer_name + " " + state + " in " + duration + " sec.";
}

// Using Babel Repl: https://babeljs.io/repl/
// function fillTemplate(payload) {
//   var {
//     id,
//     repository,
//     branch,
//     number,
//     state,
//     committer_name,
//     commit,
//     matrix,
//     message
//   } = payload;
//   var { name, owner_name } = repository;
//   var { compare_url } = matrix[0];
//   return `Build [#${number}](https://travis-ci.org/${owner_name}/${name}/builds/${id}) ${state} ([${commit.substr(0, 7)}](${compare_url})) of ${owner_name}/${name} @ ${branch} by ${committer_name}.
//   ${message}`
// }
```

## 3. Set up .travis.yml

Add the URL of Bot on Google Apps Script to `.travis.yml`. We must take care here. We should not display that plain URL in the .travis.yml. Anyone can call the Bot API when it's published. But can't use "Environment Variables" in notification configuration. Please see [issue](https://github.com/travis-ci/travis-yaml/issues/92).

So, in order to prevent these,  proprietary encryption of Travis CI should be used.

It can be encrypted using the Travis Command Line Tool. Let's install using gem.

```
# Install
$ gem install travis

$ cd your/repository

# Encrypt
$ travis encrypt "https://script.google.com/${YOUR_BOT_URI}" --add notifications.webhooks.urls
```

It will add to your .travis.yml like a following format.


`.travis.yml `

```
notifications:
  webhooks:
    urls:
      secure: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX...
```

And I added `on_success` and `on_failure` and always receive results.

```
notifications:
  webhooks:
    urls:
      secure: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX...
    on_success: always
    on_failure: always
```

It completed those preparations all!

Please push .travis.yml to your repository on Github. After a little while The following message will arrive on your topic.

![travis-notify-typetalk.](/images/travis-notify-typetalk.png "travis-notify-typetalk.")

Let's have a comfortable dev-life with Typetalk and Travis CI and Google Apps Script!

Thanks!


