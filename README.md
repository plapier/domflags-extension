DomFlags
========

A chrome extension to create keyboard shortcuts to DOM elements.

Closed source for now.

#### [Issues](https://github.com/plapier/domflags-extension/issues) can be viewed in the public repo –  [DomFlags-extension](https://github.com/plapier/domflags-extension/)

Development
-----------

The coffeescript files are the development versions. The \*.js files are
created with [coffeebar][], which you can install with:

``` sh
$ npm install -g coffeebar
```

With coffeebar installed, you can use the following to have coffeebar watch,
compile, and minify the coffeescript files:

``` sh
$ coffeebar -w -m src
```


Compile sass for the Inject CSS
```sh
$ sass --watch --style compressed src/inject/sass/:src/inject
```

Compile sass for the Options CSS
```sh
$ sass --watch --style compressed src/options/sass/:src/options
```

[coffeebar]: https://www.npmjs.org/package/coffeebar
