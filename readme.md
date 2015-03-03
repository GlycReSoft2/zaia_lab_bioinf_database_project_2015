# README

This is a project template for the 2015 Database Project Group for the Zaia Lab

## Setting up your environment

### Initialize your repository.
After cloning this repository, you will need to set up the submodules:

```bash
    git config http.postBuffer 524288000
    git clone https://github.com/GlycReSoft2/zaia_lab_bioinf_database_project_2015.git
    git submodule init
```
### Installing Libraries
To read the data files (stored in ./data) you will need to install our python library.

*Warning* - The following command will install several Python and native libraries on your system. If you cannot install libraries globally on your system (e.g. you cannot sudo), add ` --user` to the end of the last call.

```bash
    cd embed_tandem_ms_classifier
    python setup.py develop
```

This will install the library for you 'in-place', meaning you will be able to modify the library's files and see these changes reflected immediately on library reload without needing to re-install it.

### Building the Web Front-End Code

The web front-end is written using several tools and a JS server-side-scripting engine called Node.js. You will need to install it if you want to build this code from source. You can download Node.js's source or pre-compiled binaries from <http://nodejs.org/>. Once you have installed Node.js and `npm`, the Node Package Manager, execute the following:

```bash
    cd web
    npm install
    npm install grunt-cli
    grunt
```

This will install the dependencies for compiling `coffeescript` to `javascript`, `less` to `css`, and some hacky-work-arounds for desktop-based AngularJS template imports.

#### Third Party Libraries in the Front-End
I use at least a dozen libraries for the front-end. Chief among them are AngularJS and jQuery. AngularJS is a powerful framework for binding UI state to data bi-directionally, so that the application responds more fluidly to user interaction. I wrote this library to learn how to use Angular, and it is prolific in the codebase. That said, when I upgraded to the next version, lots of things broke. If you don't want to learn to use it, by all means throw it away and replace it with something else, I will probably have to move away from it in any case as the main results page needs a better virtual table implementation

Other libraries
 1. HighCharts - The hands-down best charting library available for JS when building standard charts
 2. BioJS - A collection of bioinformatics-focused visualization tools. I've heavily modded the parts used in this project.
 3. LoDash - The functional programmer's swiss army knife
 4. d3 - The data scientist's swiss army knife of data parsing and data-driven visualization
 5. Twitter Bootstrap 3 - CSS and JS library for building common UI widgets (tabs, containers, modal windows) and slick basic stylesheet
