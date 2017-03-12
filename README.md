# HVRTTIUtils

Continuation of the 2006 era RTTI utilities by Hallvard Vassbotn

Original at CodeCentral [ID: 24074, HVRTTIUtils - Extended RTTI access code](http://cc.embarcadero.com/Item/24074)

That code was the result of his [RTTI related blog articles](https://hallvards.blogspot.com/search/label/RTTI):

- 2006-03 [Hack #8: Explicit VMT calls](https://hallvards.blogspot.com/2006/03/hack-8-explicit-vmt-calls.html)
- 2006-04 [Hack #9: Dynamic method table structure](https://hallvards.blogspot.com/2006/04/hack-9-dynamic-method-table-structure.html)
- 2006-04 [Getting a list of implemented interfaces](https://hallvards.blogspot.com/2006/04/getting-list-of-implemented-interfaces.html)
- 2006-04 [Published methods](https://hallvards.blogspot.com/2006/04/published-methods_27.html)
- 2006-05 [Under the hood of published methods](https://hallvards.blogspot.com/2006/05/under-hood-of-published-methods.html)
- 2006-05 [Hack #10: Getting the parameters of published methods](https://hallvards.blogspot.com/2006/05/hack-10-getting-parameters-of.html)
- 2006-05 [Published fields details](https://hallvards.blogspot.com/2006/05/published-fields-details.html)
- 2006-05 [David Glassborow on extended RTTI](https://hallvards.blogspot.com/2006/05/david-glassborow-on-extended-rtti.html)
- 2006-06 [Simple Interface RTTI](https://hallvards.blogspot.com/2006/06/simple-interface-rtti.html)
- 2006-06 [Digging into SOAP and WebSnap](https://hallvards.blogspot.com/2006/06/digging-into-soap-and-websnap.html)
- 2006-08 [Extended Interface RTTI](https://hallvards.blogspot.com/2006/08/extended-interface-rtti.html)
- 2006-09 [Extended Class RTTI](https://hallvards.blogspot.com/2006/09/extended-class-rtti.html)
- 2006-09 [Hack#11: Get the GUID of an interface reference
](https://hallvards.blogspot.com/2006/09/hack11-get-guid-of-interface-reference.html)

(note there are more parts in those series, but the above parts contain parts of the code that is now in the repository)

The code contains more tests than the articles.

Goal is to make the code compatible with Unicode versions >= 2009 of Delphi.

Since there is no clear copyright in the original source files, there is no license file either.

## TODO

1. Fix `RTTI for the published method "Test1" of class "TMyClass" has 38 extra bytes of unknown data!` in project `TestPublishedMethodParams` and `TestMorePubMethodParams` when using Delphi 2007
2. Convert to non-Unicode Delphi versions
3. Add missing pieces from:
   - 2005-01 [David Glassborow on extended RTTI](https://hallvards.blogspot.com/2006_05_01_archive.html) pointing indirectly to:
     - [Class Helpers: Good or Bad ?](https://blogs.conceptfirst.com/blog/2006/05/08/class-helpers-good-or-bad/) via [old](https://davidglassborow.blogspot.nl/2006/05/class-helpers-good-or-bad.html)
     - [Interface RTTI](https://blogs.conceptfirst.com/blog/2006/05/11/Interface-RTTI/) via [old](https://davidglassborow.blogspot.nl/2006/05/interface-rtti.html)
     - [Class RTTI](https://blogs.conceptfirst.com/blog/2006/05/22/Class-RTTI/) via [old](https://davidglassborow.blogspot.nl/2006/05/class-rtti.html)
     -  [DetailedRTTI.pas](https://blogs.conceptfirst.com/images/dave/DetailedRTTI.pas) via [old](https://web.archive.org/web/20101125042819/http://blogs.conceptfirst.com/Media/DetailedRTTI.pas)
   - 2006-09 [Hack#11: Get the GUID of an interface reference
](https://hallvards.blogspot.com/2006/09/hack11-get-guid-of-interface-reference.html)
   - 2007-03 [Hack#14: Changing the class of an object at run-time](https://hallvards.blogspot.com/2007/03/hack14-changing-class-of-object-at-run.html)
   - 2007-04 [Hack#16: Published field RTTI replacement trick](https://hallvards.blogspot.com/2007/04/hack16-published-field-rtti-replacement.html)
   - 2007-05 [Hack#17: Virtual class variables, Part I](https://hallvards.blogspot.com/2007/05/hack17-virtual-class-variables-part-i.html)
   - 2007-05 [Hack#17: Virtual class variables, Part II](https://hallvards.blogspot.com/2007/05/hack17-virtual-class-variables-part-ii.html)
