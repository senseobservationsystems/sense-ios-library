\mainpage
Sense iOS Platform Library
=================
Sense library for sensing and using Common Sense. For more information and a tutorial visit the [Sense developers page](http://developer.sense-os.nl/Libraries/iOS/).

## Installing Sqlcipher

This project require sqlcipher library to do encryption for the local storage.
in the `library` there is 2 extra project (as a git submodule) that will help compiling the sqlcipher.

### Checking out submodule

after cloning this repository, checkout the submodule using.

```
$ git submodule init
$ git submodule update
```

more information on using git submodule can be found at http://git-scm.com/docs/git-submodule

### Add openssl source tree

To be able to compile, sqlcipher needs also openssl source.

donwload openssl 1.0.x, currently (http://www.openssl.org/source/openssl-1.0.1l.tar.gz) to a path. example /Users/johndoe/development/openssl-1.0.1l

Choose the XCode Menu, Preferences, Locations tab, and Source Trees screen. Add a variable named OPENSSL_SRC that references the path to the extracted OpenSSL source code.

more information on
https://www.zetetic.net/sqlcipher/ios-tutorial/
