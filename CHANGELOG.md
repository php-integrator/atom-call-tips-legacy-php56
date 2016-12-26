## 1.2.1
* Add a workaround to prevent call tips from displaying over autocompletion (thanks to [@Talv](https://github.com/Talv)).

## 1.2.0 (base 2.0.0)
* Call tips should now always display above linter errors.
* A single parameter signature should no longer break over multiple lines.
* Call tips will no longer trigger inside comments, which should improve responsiveness whilst typing them.
* The visual appearance of call tips has been improved. There is now a much clearer distinction between its various components (i.e. types, names and default values).

## 1.1.1
* Rename the package and repository.

## 1.1.0 (base 1.2.0)
* Fix no call tips being shown after the new keyword for classes that have an implicit constructor.

## 1.0.1
* Fix the version specifier not being compatible with newer versions of the base service.

## 1.0.0 (base 1.0.0)
* Call tips will now display the default value for parameters.
* The ellipsis for variadic parameters is now shown up front instead of at the back, consistent with PHP's syntax.

## 0.2.4 (base 0.9.0)
* Updated to use the most recent version of the base service.

## 0.2.3 (base 0.8.0)
* Call tips became a bit more asynchronous, improving responsiveness.

## 0.2.2 (base 0.7.0)
* Updated to work with the most recent service from the base package.

## 0.2.1 (base 0.6.0)
* Updated to work with the most recent service from the base package.
* Call tips for very long parameter lists will no longer become very wide.
* Gracefully handle promise rejections so no errors show up in the console.

## 0.2.0 (base 0.5.0)
* Initial release.
