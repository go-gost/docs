---
authors:
  - ginuerzh
categories:
  - Selector
readtime: 15
date: 2022-09-09
comments: true
draft: true
---

# Selector

A [Selector](/concepts/selector/), as the name suggests, is used for making selections. It works by filtering through a set of objects to ultimately pick the desired result.

When a hop (or chain level) uses multiple nodes, only one can be used per request, so a selection must be made.

<!-- more -->

!!! tip "Internal Implementation"

    A selector consists of a selection strategy plus several filters. When a selection is performed, filters are applied first, then the strategy selects the final object. If no objects are available after filtering, the selector returns empty.

The selector currently supports two types of objects: nodes and chains.
