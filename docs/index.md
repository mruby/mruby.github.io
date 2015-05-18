---
layout: default
title: mruby - docs
---

# Documentation

At the moment the source code ([`mruby/doc/`](https://github.com/mruby/mruby/tree/master/doc)) includes further documentation about compiling, configurating (`mrbconf`), debugging (`mrdb`), and extending (`mrbgems`) mruby.

## Articles

<div>
{% for page in site.pages %}
  {% if page.categories contains 'articles' %}
    {% capture article %} - [{{ page.title }}]({{ page.url }}) {% endcapture %}
    {{ article  | markdownify }}
  {% endif %}
{% endfor %}
</div>

## Components

- [Core](Core.html)
