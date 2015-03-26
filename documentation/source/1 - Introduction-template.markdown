Introduction
=============

The Sense iOS library is an open source library that provides easy access to sensor information coming from sensors in the phone, and creates an easy interface to the CommonSense backend (to learn more about CommonSense visit developer.sense-os.nl). It reads most of the available sensor and state information that iOS provides and stores this in a local database. This sensor information is regularly uploaded to CommonSense if a user is logged in. The library can not only be used to collect phone data, developers can also create custom sensors and store and upload data to those sensors. 

Currently, the library has been extensively tested with iOS 8. It also works with earlier versions, but some features are not available in earlier iOS versions (notably Visits). It is SWIFT compatible, but is completely written in objective-c. 

The source code is available at https://github.com/senseobservationsystems/sense-ios-library

Documentation is available online at [http://senseobservationsystems.github.io/sense-ios-library/](http://senseobservationsystems.github.io/sense-ios-library/). also available offline in form of html and appledoc.
For apple doc you could copy the contents of `documentation/output/docset` to the shared documentation library to `/Users/USERNAME/Library/Developer/Shared/Documentation/DocSets/nl.sense-os.SensePlatform.docset`. The documentation will 
then be available on Xcode. If you go to Help > Documentation and API Reference. It will be listed on Navigator


The library is actively maintained and extended. If you have specific feature request you can reach out to the Product Owner of the Sense iOS library at [freek@sense-labs.com](freek@sense-labs.com). He loves to hear your thoughts and opinions, and will cherish your feedback.