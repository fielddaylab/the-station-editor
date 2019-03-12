<?php $path = $_SERVER['DOCUMENT_ROOT']; $path .= "/includes/header.php";  include_once($path); ?>
<?php $path = $_SERVER['DOCUMENT_ROOT']; $path .= "/includes/nav.php";  include_once($path); ?>

<script type="text/javascript" src="webpack_out.js?cb=20180831"></script>

<style>
body {
  -webkit-touch-callout: none;
  -webkit-user-select: none;
  -khtml-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

div,span,body,img,input
{
  font-family:'Open Sans', sans-serif, Helvetica;
  letter-spacing:1px;
  margin:0px;
  padding:0px;
  font-weight:lighter;
  color:#29333F;
}
.white_bg
{
  background-color:#FFFFFF;
}
.light_bg
{
  background-color:#F7F7F7;
}
body, .dark_bg
{
  background-color:#323232;
  color:#FFFFFF;
}
.yellow_bg
{
  background-color:#E9C32A;
  color:#FFFFFF;
}

/* Top Bar */
.top_bar_logo
{
  float:left;
}
.top_bar_link
{
  margin: 7px 13px;
  color:#FFFFFF;
  float:right;
}
.signup_button
{
  border: 1px solid white;
  border-radius: 999px;
  padding: 8px 14px;
  margin-top: -1px;
}

.search_bar {
  width: 100%;
  font-size: 20px;
  padding: 12px 20px;
  border-radius: 25px;
}

.results_arrow {
  cursor: pointer;
  font-size: 25px;
  vertical-align: middle;
}

/* lists */
@media (min-width: 801px) {
  .list_entry_faded {
    height: 325px;
    overflow: hidden;
    position: relative;
  }
}
.list_entry {
  width: 100%;
  box-sizing: border-box;
  padding: 0 10px;
  overflow-x: hidden;
}
@media (min-width: 801px) {
  .list_entry {
    width: 25%;
    float: left;
  }
}
@media (max-width: 800px) {
  .list_entry {
    padding: 0 10px;
  }
}
.list_image {
  margin-right: 15px;
  margin-bottom: 15px;
  display: block;
  width: 100px;
  height: 100px;
}
.list_link {
  color: black;
  text-decoration: none;
}
.list_name {}
.list_description {}
.list_fadeout {
  pointer-events: none;
}
@media (max-width: 800px) {
  .list_fadeout {
    display: none;
  }
}
@media (min-width: 801px) {
  .list_fadeout {
    position: absolute;
    width: 100%;
    height: 100%;
    top: 0;
    left: 0;
    background-image: linear-gradient(to top, white 0px, rgba(255, 255, 255, 0) 40px);
    /* above used to be rgba(0,0,0,0) but that behaves differently in Safari */
  }
}

.owner_picture {
  width: 40px;
  height: 40px;
  border-radius: 20px;
  float: left;
  margin-top: -10px;
  margin-right: 10px;
  background-color: #E9C32A;
  text-align: center;
  line-height: 40px;
  overflow: hidden;
  color: white;
}

.section {
  padding: 1px; /* hack, to avoid some gap under search section??? */
}

#banner {
  position: relative;
  min-height: 300px;
  background-image: url('../assets/photos/siftr-header.jpg');
  background-size: cover;
}

#slogan {
  width: 100%;
  height: 30px;
  margin: 0px auto;
  text-align: center;
  font-size: 20px;
  letter-spacing: 5px;
  font-weight: light;
  color: #FFFFFF;
}

</style>

<div id="the-container" class="dark_bg"></div>

<?php $path = $_SERVER['DOCUMENT_ROOT']; $path .= "/includes/footer.php";  include_once($path); ?>
