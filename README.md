Sense iOS Platform Library
=================

Welcome to the Sense iOS library documentation. This documentation provides an overview of the behavior of the library and explains how it can be used. The goal is to provide an easy starting point for developers to get up to speed with the basics when first starting to use the library, and a comprehensive reference when needing specific information.

This document is also available online at [http://senseobservationsystems.github.io/sense-ios-library/](http://senseobservationsystems.github.io/sense-ios-library/) and also `appledoc`. More information are available on Introduction section below.

If there is information that you believe is incorrect, or if you are missing information, please do not hesitate to contact us. You can reach the authors at

* [ahmy@sense-os.nl](ahmy@sense-os.nl)
* [joris@sense-os.nl](ahmy@sense-os.nl)

The rest of this documentation is organized as follows. First we explain the goal and requirements of the library in the introduction. We than have a getting started section to setup the library and get started using it. After that, we have a set of specific articles elaborating on different aspects of using the library for more detailed information.

### Dependencies
Sense iOS Library make use of third party libraries. Libraries are fetched and built using [Carthage](https://github.com/Carthage/Carthage).
To install the libraries in your xcode project, you can simply do:
    
    carthage update --configuration Debug


When you want to add/modify a new library in the dependency, you can edit Cartfile. For details, you can refer to the instruction at [Carthage](https://github.com/Carthage/Carthage)

[Note] At this moment, Cartage can not handle Realm and PromiseKit. So those libraries have to be installed manually. It should be fixed as soon as the issue is resolved. 

### Test code coverage  

Test code coverage can be automatically generated through the target in the xcode project. It has two dependencies (lcov and groovy) which can be installed through: 

    brew install groovy
    brew install lcov

Before running the test code coverage target you have to run the tests themselves. Once they have finished running, you run the test code coverage target to generate test code coverage results. These results can be found by opening 

    build/reports/coverage/index.html
