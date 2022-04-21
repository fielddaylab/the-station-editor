# Station Editor
Compatible with Chrome. 
Image upload does NOT work with Safari.

A [Field Day](http://fielddaylab.org) experiment.

Some icons designed by [Freepik](http://www.flaticon.com/authors/freepik) ([free license](http://file005.flaticon.com/downloads/license/license.pdf))
and [Tina Mailhot-Roberge](http://vervex.ca/) ([CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/)).

## Instructions

1. Checkout https://github.com/fielddaylab/SiftrNative next to folder
2. `npm install`
3. Set the server URL in web/shared/aris.js
4. `make` inside the `web` folder to build
5. `make deploy` to deploy over rsync

Defualt values will assume that the server code exists in the parrent folder of where the editor is deployed.
Modify `Web/includes/nav.php` and `Web/shared/aris.js` and change the relitive link to `../server` to an absolute link to change this.
