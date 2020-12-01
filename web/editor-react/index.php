<!DOCTYPE html>
<html lang="en">
<head>
<title>STEMports Editor</title>
<link rel="apple-touch-icon" sizes="180x180" href="../assets/favicon/apple-touch-icon.png">
<link rel="icon" type="image/png" sizes="32x32" href="../assets/favicon/favicon-32x32.png">
<link rel="icon" type="image/png" sizes="16x16" href="../assets/favicon/favicon-16x16.png">
<link rel="manifest" href="../assets/favicon/site.webmanifest">
<meta charset="UTF-8">
<meta content="True" name="HandheldFriendly">
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
<link href="https://fonts.googleapis.com/css?family=Open+Sans:400,700|Varela+Round|Lato:400,400i" rel="stylesheet">
<!-- <link rel="stylesheet" href="../assets/css/styles.css"> -->
<script src="webpack_out.js?cb=20201001"></script>
<link href="main.css?cb=20201001" rel="stylesheet" type="text/css">
<style type="text/css">

.main-nav { box-sizing: border-box; }
.main-nav * { box-sizing: border-box; }
.main-nav {
  width: 100%;
  display: flex;
  background: #fff;
  align-items: center;
  padding: 10px;
  z-index: 1000;
  box-shadow: 0 9px 10px 0 rgba(18, 129, 155, 0.06);
  font-family: Lato, sans-serif;
  line-height: 1.5;
  letter-spacing: 0; }
  .main-nav .logo {
    width: 40px;
    margin-right: 10px; }
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
        display: block;
        margin: 30px 10px;
        vertical-align: middle;
        line-height: 2;
        font-weight: 500; }
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
          width: 30px;
          height: 30px;
          border-radius: 20px;
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
      width: 100%;
      transform: translateX(0vw);
      background: none;
      box-shadow: none;
      opacity: 1;
      display: flex;
      flex-direction: row;
      justify-content: space-between; }
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

.img-fluid {
  max-width: 100%;
  height: auto;
  vertical-align: middle; }

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

#stemports-breadcrumbs a {
  color: rgb(101,88,245);
}

</style>

<body>

<div id="top-level-container">

<?php $path .= "../includes/nav.php";  include_once($path); ?>

<div id="the-container">
</div>

</div>

<script src="../assets/js/vendor/jquery-3.0.0.min.js"></script>
<script src="https://netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"></script>
<script src="../assets/js/vendor/gridder.js"></script>
<script src="../assets/js/scripts.js"></script>
<script async src="https://www.googletagmanager.com/gtag/js?id=G-ME1ZLZ8KRF"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-ME1ZLZ8KRF');
</script>
</script>
</body>
</html>