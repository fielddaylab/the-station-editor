# The Station Editor

A [Field Day](http://fielddaylab.org) experiment.

Some icons designed by [Freepik](http://www.flaticon.com/authors/freepik) ([free license](http://file005.flaticon.com/downloads/license/license.pdf))
and [Tina Mailhot-Roberge](http://vervex.ca/) ([CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/)).

## Instructions

1. Checkout https://github.com/fielddaylab/SiftrNative next to folder

2. `npm install`

3. `make` inside the `web` folder to build

4. `make deploy` to deploy over rsync


## Configuration

By default it is assumed that the `web` folder will be deployed next to the `server`. If you need to have this editor point to a different serbver location, modify `web/includes/nav.php` and `web/shared/aris.js` and change from reletive to absolute links. 
 

