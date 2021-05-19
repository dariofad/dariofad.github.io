---
layout: page
title: Posts
---

{%- assign date_format = site.minima.date_format | default: "%b %-d, %Y" -%}	
<ul>
  {% for post in site.posts %}
    <time class="dt-published" datetime="{{ page.date | date_to_xmlschema }}" itemprop="datePublished">
        {{ post.date | date: date_format }}
    </time>
	<br>
    <h4 style="margin: 1px; padding: 1px;">
      <a href="{{ post.url }}">{{ post.title }}</a>
    </h4>
	{{ post.excerpt | markdownify}}
  	{% for tag in post.tags %}
 	  <a href="/tag/{{ tag }}"><code><nobr>{{ tag }}</nobr></code>&nbsp;</a>
    {% endfor %}
	<br><br>
  {% endfor %}
</ul>
