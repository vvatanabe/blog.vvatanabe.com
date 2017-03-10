+++
date = "2017-03-10T21:29:24+09:00"
title = "How the static site can improve its performance on"
draft = false
categories = [ "technology" ]
tags = [ "hugo", "aws", "travis-ci", "teraform" ]
eyecatch = "/images/test-my-site-result.png"
+++

The following site was talked about in my company recently. So I tried measured my blog site immediately.

[testmysite.withgoogle.com](https://testmysite.thinkwithgoogle.com/)

As a result, I got some points to improve. So I will introduce that problem and how to fix.

By the way, please read [this article](https://blog.vvatanabe.com/post/2017/03/02/quickly-publishing-blogs-with-hugo-to-aws/) on the environment of this blog.

---

## 1. Enable compression
GZIP compression wasn't enabled in my site. Mmm...

The setting of the CloudFront as CDN which I use was missing. The Value of `Compress Objects Automatically` was `No`. Ooops! Change it up.

If you are usnig Terraform, be careful below.

```
resource "aws_cloudfront_distribution" "cdn" {
  default_cache_behavior {
    compress = true # This value is true.
  }
}
```

To request it again, but `content-encoding:gzip` is not listed in response header. Just in case, `Invalidated` the edge cache of the CloudFront and I went right.

---

## 2. Minify HTML
HTML isn't minified. This was solved by enabling GZIP of CloudFront. It wonder that practicing both GZIP compression and minify HTML lead to better performance?

---

## 3. Leverage browser caching
There were some files which can not leverage browser's cache.

It should set `Cache-Control max-age, s-max-age` to metadata of the S3 object used as CloudFront Origin.

`max-age` is the browser caching time.  
`s-max-age` is the cache server caching time.

There is a problem that the cache remains even if update blog, however It can avoid by deleting the edge cache of all at the time of
deploying.

Of course I will give this work to Mr.Travis.

```
branches:
  only:
    - master
language: go
install:
- go get -v github.com/spf13/hugo
- sudo pip install s3cmd
- sudo pip install awscli
script:
- hugo
- s3cmd --acl-public \
        --delete-removed \
        --add-header=Cache-Control max-age=${MAX_AGE_SEC},s-max-age=${S_MAX_AGE_SEC} \
        --no-progress sync public/ s3://${YOUR_BUCKET_NAME} \
- aws configure set preview.cloudfront true
- aws cloudfront create-invalidation --distribution-id ${DISTRIBUTION_ID} --paths '/*'
notifications:
  email:
    on_failure: always
```

---

## 4. Eliminate render-blocking JavaScript and CSS in above-the-fold content
JavaScript and CSS is blocking the first view rendering.
The cause is the following external CSS, These were blocking the first view.

```
https://fonts.googleapis.com/css?family=Open+Sans:400|Old+Standard+TT:400
https://maxcdn.bootstrapcdn.com/font-awesome/4.6.3/css/font-awesome.min.css
```

It solved by asynchronously reading CSS with reference to the following page.

[OptimizeCSSDelivery](https://developers.google.com/speed/docs/insights/OptimizeCSSDelivery)

`footer.html`
```
<noscript id="deferred-styles">
  <link rel="stylesheet" type="text/css" href="https://fonts.googleapis.com/css?family=Open+Sans:400|Old+Standard+TT:400" />
  <link rel="stylesheet" type="text/css" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.6.3/css/font-awesome.min.css" />
</noscript>
{{ partial "deferred_styles.html" . }}
</body>
</html>
```

`deferred_styles.html`
```
<script>
  var loadDeferredStyles = function() {
    var addStylesNode = document.getElementById("deferred-styles");
    var replacement = document.createElement("div");
    replacement.innerHTML = addStylesNode.textContent;
    document.body.appendChild(replacement)
    addStylesNode.parentElement.removeChild(addStylesNode);
  };
  var raf = requestAnimationFrame || mozRequestAnimationFrame ||
      webkitRequestAnimationFrame || msRequestAnimationFrame;
  if (raf) raf(function() { window.setTimeout(loadDeferredStyles, 0); });
  else window.addEventListener('load', loadDeferredStyles);
</script>
```

---

That's all.

The score below is the difference before and after the fix of these problems. It seems that mobile display speed has improved.

Before
![test-my-site-before](/images/test-my-site-before.png "test-my-site-before")

After
![test-my-site-after](/images/test-my-site-after.png "test-my-site-after")

Thanks!














