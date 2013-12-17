lookup_table
============

Database fed lookup table.

This gem allows to quickly set up a look up table with content stored in the
database. The library supports two modes of operation: preload the whole table
into a lookup hash or lookup (and cache) values on demand.

The gem is useful for implementing data processing algorithms where some
functions are given as table based mappings, such as implementing statistical
models. The main purpose of the gem is making the code using such database
backed lookup more readable.


