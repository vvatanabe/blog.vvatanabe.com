+++
date = "2017-02-23T22:34:33+09:00"
title = "How to set up the hugo"
draft = false
categories = [ "Technology" ]
tags = [ "Blog", "Hugo" ]
+++

## What's Hugo?

It's a static site generator written in Golang. As a similar static site generator, Jekyll, Middleman, etc.
There are 3 major reasons for choosing Hugo:

- Easy installation.
- Page generation is fast.
- My colleague recommended it!

## Install the hugo.

```
$ brew install hugo
```

## Create a site.

```
$ hugo new site ${site_name}
```

## Install some theme.

```
$ mkdir themes
$ cd themes
$ git clone https://github.com/${user_id}/${repos_name}.git
```


## Post articles.

```
$ hugo new ${article_name.md}
```

## Preview site.

```
$ hugo server -t ${theme_name} -w
```

## Generate a page.

```
$ hugo -t ${theme_name}
```

## Configuration

```
theme = "${theme_name}"　# Apply theme.
canonifyurls = true # It's absolute path based on baseurl, not a relative path.
publishDir = "${dir_path}" # Directory path to publish
```

Thanks!


