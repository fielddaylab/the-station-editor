<!DOCTYPE html>
<html lang="en">
<head>
<title>Siftr Editor</title>
<link rel="apple-touch-icon" sizes="180x180" href="/assets/favicon/apple-touch-icon.png">
<link rel="icon" type="image/png" sizes="32x32" href="/assets/favicon/favicon-32x32.png">
<link rel="icon" type="image/png" sizes="16x16" href="/assets/favicon/favicon-16x16.png">
<link rel="manifest" href="/assets/favicon/manifest.json">
<link rel="mask-icon" href="/assets/favicon/safari-pinned-tab.svg" color="#5bbad5">
<meta name="theme-color" content="#ffffff">
<meta name="msapplication-TileColor" content="#da532c">
<meta name="msapplication-TileImage" content="/assets/favicon/mstile-150x150.png">
<meta name="theme-color" content="#ffffff">
<meta charset="UTF-8">
<meta content="True" name="HandheldFriendly">
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
<link href="https://fonts.googleapis.com/css?family=Open+Sans:400,700|Varela+Round|Lato:400,400i" rel="stylesheet">
<script>
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

  ga('create', 'UA-72694027-1', 'auto');
  ga('send', 'pageview');
  ga('linker:autoLink', ['arisgames.org','fielddaylab.org','siftr.org'], false, true);
</script>
<!-- <link rel="stylesheet" href="/assets/css/styles.css"> -->
<script src="webpack_out.js?cb=20181211"></script>
<link href="main.css?cb=20181211" rel="stylesheet" type="text/css">
<style type="text/css">

@font-face {
    font-family: 'league_spartanregular';
    src: url('/assets/fonts/leaguespartan-bold.ttf') format('ttf'),
         url('/assets/fonts/leaguespartan-bold-webfont.woff') format('woff');
    font-weight: normal;
    font-style: normal;
}

.main-nav {
  width: 100%;
  display: flex;
  background: #fff;
  align-items: center;
  padding: 10px;
  z-index: 1000;
  box-shadow: 0 9px 10px 0 rgba(18, 129, 155, 0.06); }
  .main-nav .logo {
    height: 100%;
    width: 40px; }
  .main-nav .nav-contents {
    position: absolute;
    width: 85vw;
    height: 100vh;
    z-index: 1000;
    top: 0;
    display: flex;
    right: 0;
    transform: translateX(80vw);
    align-items: center;
    transition: all 0.2s ease-in-out;
    text-align: center;
    justify-content: center;
    flex-direction: column;
    background: #fff;
    box-shadow: -10px 9px 10px 0 rgba(18, 129, 155, 0.06);
    opacity: 0; }
    .main-nav .nav-contents .smily-pin {
      width: 30px;
      display: block;
      margin-top: 20vh; }
    .main-nav .nav-contents.nav-open {
      transform: translateX(0vw);
      opacity: 1; }
    .main-nav .nav-contents .nav-items {
      margin: 0;
      padding-left: 0; }
      .main-nav .nav-contents .nav-items li {
        font-family: 'league_spartanregular';
        display: block;
        margin: 30px 10px;
        vertical-align: middle; }
        .main-nav .nav-contents .nav-items li a {
          text-transform: uppercase;
          font-size: 14px;
          letter-spacing: 3px;
          color: #1C2B61; }
        .main-nav .nav-contents .nav-items li:last-child a, .main-nav .nav-contents .nav-items li:nth-last-child(2) a {
          border-right: none; }
        .main-nav .nav-contents .nav-items li.nav-hide {
          display: none; }
        .main-nav .nav-contents .nav-items li .nav-profile-img {
          vertical-align: bottom;
          background-color: white;
          width: 20px;
          height: 20px;
          border-radius: 10px;
          margin-left: 5px; }
  .main-nav .mobile-nav-open {
    background: url(/assets/icons/navicon.png);
    width: 20px;
    position: absolute;
    right: 15px;
    background-size: 20px 20px;
    height: 20px;
    cursor: pointer;
    z-index: 1001; }
    .main-nav .mobile-nav-open:hover {
      opacity: .7; }
  @media (min-width: 576px) {
    .main-nav .mobile-nav-open {
      display: none; }
    .main-nav .nav-contents {
      position: relative;
      height: initial;
      width: initial;
      transform: translateX(0vw);
      background: none;
      box-shadow: none;
      opacity: 1; }
      .main-nav .nav-contents .nav-items {
        margin-left: 10px; }
        .main-nav .nav-contents .nav-items li {
          display: inline; }
          .main-nav .nav-contents .nav-items li a {
            color: #1C2B61;
            border-right: 2px solid #FFD9D9;
            padding-right: 15px;
            font-size: 10px; }
      .main-nav .nav-contents .smily-pin {
        display: none; } }

.nav-open .mobile-nav-open {
  background: url(/assets/icons/close-icon-pink.png);
  width: 20px;
  position: absolute;
  right: 15px;
  background-size: 20px 20px;
  height: 20px;
  cursor: pointer;
  z-index: 1001; }
  .nav-open .mobile-nav-open:hover {
    opacity: .7; }

#top-level-container {
  position: fixed;
  top: 0;
  left: 0;
  bottom: 0;
  right: 0;
  display: flex;
  flex-direction: column;
  align-items: stretch;
}

</style>

<body>

<div id="top-level-container">

<?php $path = $_SERVER['DOCUMENT_ROOT']; $path .= "/includes/nav.php";  include_once($path); ?>

<div id="the-container">
</div>

</div>

<?php $path = $_SERVER['DOCUMENT_ROOT']; $path .= "/includes/footer.php";  include_once($path); ?>
