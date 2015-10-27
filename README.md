Sense iOS Platform Library
=================

Welcome to the Sense iOS library documentation. This documentation provides an overview of the behavior of the library and explains how it can be used. The goal is to provide an easy starting point for developers to get up to speed with the basics when first starting to use the library, and a comprehensive reference when needing specific information.

This document is also available online at [http://senseobservationsystems.github.io/sense-ios-library/](http://senseobservationsystems.github.io/sense-ios-library/) and also `appledoc`. More information are available on Introduction section below.

If there is information that you believe is incorrect, or if you are missing information, please do not hesitate to contact us. You can reach the authors at

* [joris@sense-os.nl](joris@sense-os.nl)
* [tatsuya@sense-os.nl](tatsuya@sense-os.nl)

The rest of this documentation is organized as follows. First we explain the goal and requirements of the library in the introduction. We than have a getting started section to setup the library and get started using it. After that, we have a set of specific articles elaborating on different aspects of using the library for more detailed information.

## Getting started
##### 1.Install Carthage
Sense iOS Library makes use of third party libraries and the libraries are managed using [Carthage](https://github.com/Carthage/Carthage). `carthage` is a simple dependency manager for iOS and OSX development enviroment. You can install `carthage` from their [release page](https://github.com/Carthage/Carthage/releases).

....Why not via homebrew? Well, because we need to install Realm with carthage and it is possible only with carthage v9.2 or higher, which is not yet indexed on homebrew.... too bad indeed. - 27th October 2015

	
##### 2.Install libraries into your enviroment
	
To install the libraries that you need in your enviroment, you can simply do:
    
    cd <YOUR_PATH>/sense-ios-library
    carthage bootstrap

Done!

## Adding new libraries

When you want to add a new library or modify the dependency, you can edit Cartfile. When you updated Cartfile then you can run the following command in your project directory.

    carthage update --configuration Debug --platform iOS

For more details about carthage, you can refer to the instruction at [Carthage repository](https://github.com/Carthage/Carthage).
###### Note: 
At this moment, Cartage can not handle Realm. So Realm Framework has to be added manually when Realm releases a new version.

## Test code coverage  

Test code coverage can be automatically generated through the target in the xcode project. It has two dependencies (lcov and groovy) which can be installed through: 

    brew install groovy
    brew install lcov

Before running the test code coverage target you have to run the tests themselves. Once they have finished running, you run the test code coverage target to generate test code coverage results. These results can be found by opening 

    build/reports/coverage/index.html

