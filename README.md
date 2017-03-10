# HVRTTIUtils

Continuation of the 2006 era RTTI utilities by Hallvard Vassbotn

Original at CodeCentral [ID: 24074, HVRTTIUtils - Extended RTTI access code](http://cc.embarcadero.com/Item/24074)

That code was the result of his two RTTI blog articles:

- [Published methods](https://hallvards.blogspot.nl/2006/04/published-methods_27.html)
- [Hack #10: Getting the parameters of published methods](https://hallvards.blogspot.nl/2006/05/hack-10-getting-parameters-of.html)

The code contains more tests than the articles.

Goal is to make the code compatible with Unicode versions >= 2009 of Delphi.

Since there is no clear copyright in the original source files, there is no license file either.

## TODO

1. Fix `RTTI for the published method "Test1" of class "TMyClass" has 38 extra bytes of unknown data!` in project `TestPublishedMethodParams` and `TestMorePubMethodParams` when using Delphi 2007
2. Convert to non-Unicode Delphi versions
