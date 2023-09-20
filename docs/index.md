---
layout: default
title: mruby - docs
---

# Documentation

At the moment the source code ([`mruby/doc/`][mruby-doc]) includes further
documentation about compiling, configuring (`mrbconf`), debugging (`mrdb`),
and extending (`mrbgems`) mruby.

[mruby-doc]: https://github.com/mruby/mruby/tree/master/doc

## Articles

<div>
{% for page in site.pages %}
  {% if page.categories contains 'articles' %}
    {% capture article %} - [{{ page.title }}]({{ page.url }}) {% endcapture %}
    {{ article | markdownify }}
  {% endif %}
{% endfor %}
</div>

## Components

- [API docs](api)
- [mruby, mruby/c Common I/O API Guideline and Community-developed Libraries](https://github.com/mruby/microcontroller-peripheral-interface-guide)
